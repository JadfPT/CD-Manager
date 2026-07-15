from __future__ import annotations

import argparse
import mimetypes
import re
import time
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import requests
from slugify import slugify
from supabase import Client, create_client

import cover_config as cfg


MB_BASE = "https://musicbrainz.org/ws/2"
CAA_BASE = "https://coverartarchive.org"


@dataclass
class CollectionItem:
    item_type: str
    item_id: int
    title: str
    artist_id: int
    artist_name: str
    genre_text: str | None
    cover_url: str | None


@dataclass
class MetadataCandidate:
    source: str
    source_id: str
    source_url: str
    release_title: str
    artist_name: str
    image_url: str | None
    confidence: float
    tracks: list[dict[str, Any]]


class RateLimiter:
    def __init__(self, min_interval_seconds: float = 1.1):
        self.min_interval_seconds = min_interval_seconds
        self._last_call = 0.0

    def wait(self):
        now = time.time()
        elapsed = now - self._last_call
        if elapsed < self.min_interval_seconds:
            time.sleep(self.min_interval_seconds - elapsed)
        self._last_call = time.time()


def log(msg: str) -> None:
    print(msg)


def normalize_text(value: str | None) -> str:
    if not value:
        return ""
    value = unicodedata.normalize("NFKD", value)
    value = "".join(c for c in value if not unicodedata.combining(c))
    value = value.lower()
    value = re.sub(r"[\[\]{}]", " ", value)
    value = re.sub(r"[^a-z0-9]+", " ", value)
    return re.sub(r"\s+", " ", value).strip()


def clean_album_title(title: str) -> str:
    t = title.strip()

    # remove ano final: "Album (1998)" -> "Album"
    t = re.sub(r"\s*\((19|20)\d{2}\)\s*$", "", t).strip()

    # remove coisas comuns que atrapalham um pouco
    t = re.sub(r"\s*-\s*remaster(ed)?\s*$", "", t, flags=re.I).strip()

    return t


def similarity(a: str, b: str) -> float:
    from difflib import SequenceMatcher

    na = normalize_text(a)
    nb = normalize_text(b)
    if not na or not nb:
        return 0.0
    return SequenceMatcher(None, na, nb).ratio()


def is_low_confidence_item(item: CollectionItem) -> bool:
    artist = normalize_text(item.artist_name)
    genre = normalize_text(item.genre_text)
    title = normalize_text(item.title)

    if artist in cfg.LOW_CONFIDENCE_ARTIST_NAMES:
        return True

    if "compilacao" in genre or "compilation" in genre:
        return True

    if "varios" in artist:
        return True

    # séries/compilações costumam ser mais arriscadas
    suspicious_fragments = [
        "melhores temas",
        "best of",
        "greatest hits",
        "varios",
        "compilacao",
        "soundtrack",
        "ost",
    ]
    return any(fragment in title for fragment in suspicious_fragments)


def supabase_client() -> Client:
    return create_client(cfg.SUPABASE_URL, cfg.SUPABASE_SERVICE_ROLE_KEY)


def fetch_items_without_cover(sb: Client, limit: int | None) -> list[CollectionItem]:
    items: list[CollectionItem] = []

    if cfg.PROCESS_CDS:
        query = (
            sb.table("cd_albums")
            .select("id,title,artist_id,cover_url,artists(name,genre_text)")
            .is_("cover_url", "null")
            .eq("is_archived", False)
            .order("id")
        )
        if limit:
            query = query.limit(limit)

        rows = query.execute().data or []
        for r in rows:
            artist = r.get("artists") or {}
            items.append(
                CollectionItem(
                    item_type="cd",
                    item_id=int(r["id"]),
                    title=r["title"],
                    artist_id=int(r["artist_id"]),
                    artist_name=artist.get("name") or "",
                    genre_text=artist.get("genre_text"),
                    cover_url=r.get("cover_url"),
                )
            )

    if cfg.PROCESS_VINYL:
        query = (
            sb.table("vinyl_albums")
            .select("id,title,artist_id,cover_url,artists(name,genre_text)")
            .is_("cover_url", "null")
            .eq("is_archived", False)
            .order("id")
        )
        if limit:
            query = query.limit(limit)

        rows = query.execute().data or []
        for r in rows:
            artist = r.get("artists") or {}
            items.append(
                CollectionItem(
                    item_type="vinyl",
                    item_id=int(r["id"]),
                    title=r["title"],
                    artist_id=int(r["artist_id"]),
                    artist_name=artist.get("name") or "",
                    genre_text=artist.get("genre_text"),
                    cover_url=r.get("cover_url"),
                )
            )

    return items


def mb_get(path: str, params: dict[str, Any], limiter: RateLimiter) -> dict[str, Any] | None:
    headers = {
        "User-Agent": cfg.MUSICBRAINZ_USER_AGENT,
        "Accept": "application/json",
    }
    url = f"{MB_BASE}{path}"

    for attempt in range(1, 4):
        limiter.wait()
        try:
            res = requests.get(url, params=params, headers=headers, timeout=30)

            if res.status_code == 404:
                return None

            if res.status_code in (429, 500, 502, 503, 504):
                wait_time = 3 * attempt
                log(f"  MusicBrainz temporário {res.status_code}; retry em {wait_time}s...")
                time.sleep(wait_time)
                continue

            res.raise_for_status()
            return res.json()

        except requests.exceptions.RequestException as exc:
            wait_time = 3 * attempt
            log(f"  MusicBrainz erro tentativa {attempt}/3: {exc}")
            time.sleep(wait_time)

    return None


def search_musicbrainz_release(item: CollectionItem, limiter: RateLimiter) -> list[dict[str, Any]]:
    title = clean_album_title(item.title)
    artist = item.artist_name

    query = f'release:"{title}" AND artist:"{artist}"'
    data = mb_get(
        "/release/",
        {
            "query": query,
            "fmt": "json",
            "limit": 5,
        },
        limiter,
    )
    if not data:
        return []
    return data.get("releases", []) or []


def get_release_details(release_id: str, limiter: RateLimiter) -> dict[str, Any] | None:
    return mb_get(
        f"/release/{release_id}",
        {
            "fmt": "json",
            "inc": "recordings+media+artist-credits+release-groups",
        },
        limiter,
    )


def extract_artist_credit_name(release: dict[str, Any]) -> str:
    credits = release.get("artist-credit") or []
    parts = []
    for c in credits:
        if isinstance(c, dict):
            artist = c.get("artist") or {}
            parts.append(artist.get("name") or c.get("name") or "")
        elif isinstance(c, str):
            parts.append(c)
    return "".join(parts).strip()


def get_cover_art_url(release_id: str) -> str | None:
    # Front direto; se não existir, tenta JSON
    front_url = f"{CAA_BASE}/release/{release_id}/front"
    try:
        res = requests.get(front_url, timeout=20, allow_redirects=True)
        if res.status_code == 200 and res.content:
            return front_url
    except Exception:
        pass

    try:
        res = requests.get(f"{CAA_BASE}/release/{release_id}", timeout=20)
        if res.status_code == 404:
            return None
        res.raise_for_status()
        data = res.json()
        images = data.get("images") or []
        for img in images:
            if img.get("front") and img.get("image"):
                return img["image"]
        if images and images[0].get("image"):
            return images[0]["image"]
    except Exception:
        return None

    return None


def extract_tracks(release_details: dict[str, Any], source_id: str) -> list[dict[str, Any]]:
    tracks: list[dict[str, Any]] = []
    media = release_details.get("media") or []

    for disc_index, medium in enumerate(media, start=1):
        for track in medium.get("tracks") or []:
            position_raw = track.get("position")
            try:
                position = int(position_raw)
            except Exception:
                position = len(tracks) + 1

            recording = track.get("recording") or {}
            title = track.get("title") or recording.get("title")
            if not title:
                continue

            length = track.get("length") or recording.get("length")
            duration_ms = int(length) if length is not None else None

            tracks.append(
                {
                    "disc_number": disc_index,
                    "position": position,
                    "title": title,
                    "duration_ms": duration_ms,
                    "source": "musicbrainz",
                    "source_id": source_id,
                }
            )

    return tracks


def score_candidate(item: CollectionItem, release: dict[str, Any]) -> float:
    title_clean = clean_album_title(item.title)
    release_title = release.get("title") or ""
    release_artist = extract_artist_credit_name(release)

    title_score = similarity(title_clean, release_title)
    artist_score = similarity(item.artist_name, release_artist)

    score = (title_score * 0.65) + (artist_score * 0.35)

    # penaliza compilações ou vários
    if is_low_confidence_item(item):
        score -= 0.18

    # se MusicBrainz tiver score textual, usa como pequeno reforço
    try:
        mb_score = float(release.get("score", 0)) / 100.0
        score = (score * 0.85) + (mb_score * 0.15)
    except Exception:
        pass

    return max(0.0, min(1.0, score))


def find_best_candidate(item: CollectionItem, limiter: RateLimiter) -> MetadataCandidate | None:
    releases = search_musicbrainz_release(item, limiter)
    candidates: list[MetadataCandidate] = []

    for release in releases:
        release_id = release.get("id")
        if not release_id:
            continue

        score = score_candidate(item, release)
        if score < cfg.SAVE_SUGGESTIONS_MIN_CONFIDENCE:
            continue

        details = get_release_details(release_id, limiter)
        if not details:
            continue

        image_url = get_cover_art_url(release_id)
        tracks = extract_tracks(details, release_id)

        candidates.append(
            MetadataCandidate(
                source="musicbrainz",
                source_id=release_id,
                source_url=f"https://musicbrainz.org/release/{release_id}",
                release_title=details.get("title") or release.get("title") or "",
                artist_name=extract_artist_credit_name(details) or extract_artist_credit_name(release),
                image_url=image_url,
                confidence=score,
                tracks=tracks,
            )
        )

    if not candidates:
        return None

    # prefere candidatos com imagem e score alto
    candidates.sort(key=lambda c: (c.image_url is not None, c.confidence, len(c.tracks)), reverse=True)
    return candidates[0]


def download_image(image_url: str) -> tuple[bytes, str]:
    res = requests.get(image_url, timeout=30, allow_redirects=True)
    res.raise_for_status()

    content_type = res.headers.get("content-type", "").split(";")[0].strip().lower()
    ext = mimetypes.guess_extension(content_type) or ".jpg"
    if ext == ".jpe":
        ext = ".jpg"

    return res.content, ext


def upload_cover_to_storage(sb: Client, item: CollectionItem, candidate: MetadataCandidate) -> tuple[str, str] | tuple[None, None]:
    if not candidate.image_url:
        return None, None

    data, ext = download_image(candidate.image_url)

    safe_title = slugify(clean_album_title(item.title))[:80] or "cover"
    path = f"{item.item_type}/{item.item_id}/{safe_title}{ext}"

    content_type = mimetypes.types_map.get(ext, "image/jpeg")

    sb.storage.from_(cfg.COVERS_BUCKET).upload(
        path,
        data,
        {
            "content-type": content_type,
            "upsert": "true",
        },
    )

    public_url = sb.storage.from_(cfg.COVERS_BUCKET).get_public_url(path)
    return path, public_url


def upsert_cover_suggestion(
    sb: Client,
    item: CollectionItem,
    candidate: MetadataCandidate,
    local_storage_path: str | None,
    local_public_url: str | None,
    status: str,
    dry_run: bool,
) -> None:
    payload = {
        "item_type": item.item_type,
        "item_id": item.item_id,
        "source": candidate.source,
        "source_id": candidate.source_id,
        "image_url": candidate.image_url or "",
        "confidence": candidate.confidence,
        "status": status,
        "local_storage_path": local_storage_path,
        "local_public_url": local_public_url,
        "release_title": candidate.release_title,
        "artist_name": candidate.artist_name,
        "matched_track_count": len(candidate.tracks),
        "source_url": candidate.source_url,
    }

    if dry_run:
        log(f"  [dry-run] cover_suggestions <- {payload}")
        return

    sb.table("cover_suggestions").insert(payload).execute()


def save_track_suggestion(
    sb: Client,
    item: CollectionItem,
    candidate: MetadataCandidate,
    status: str,
    dry_run: bool,
) -> None:
    if not candidate.tracks:
        return

    payload = {
        "item_type": item.item_type,
        "item_id": item.item_id,
        "source": candidate.source,
        "source_id": candidate.source_id,
        "confidence": candidate.confidence,
        "tracks": candidate.tracks,
        "status": status,
    }

    if dry_run:
        log(f"  [dry-run] track_suggestions <- {len(candidate.tracks)} tracks")
        return

    sb.table("track_suggestions").insert(payload).execute()


def apply_cover(
    sb: Client,
    item: CollectionItem,
    candidate: MetadataCandidate,
    local_public_url: str,
    dry_run: bool,
) -> None:
    table = "cd_albums" if item.item_type == "cd" else "vinyl_albums"
    payload = {
        "cover_url": local_public_url,
        "metadata_source": candidate.source,
        "metadata_source_id": candidate.source_id,
        "cover_source": "cover_art_archive",
        "cover_confidence": candidate.confidence,
    }

    if dry_run:
        log(f"  [dry-run] update {table}.{item.item_id} cover_url={local_public_url}")
        return

    sb.table(table).update(payload).eq("id", item.item_id).execute()


def apply_tracks(
    sb: Client,
    item: CollectionItem,
    candidate: MetadataCandidate,
    dry_run: bool,
) -> None:
    if not candidate.tracks:
        return

    rows = []
    for t in candidate.tracks:
        rows.append(
            {
                "item_type": item.item_type,
                "item_id": item.item_id,
                "disc_number": t["disc_number"],
                "position": t["position"],
                "title": t["title"],
                "duration_ms": t.get("duration_ms"),
                "source": t.get("source"),
                "source_id": t.get("source_id"),
            }
        )

    if dry_run:
        log(f"  [dry-run] item_tracks <- {len(rows)} tracks")
        return

    # Limpa tracks antigas desse item antes de aplicar a sugestão de alta confiança
    sb.table("item_tracks").delete().eq("item_type", item.item_type).eq("item_id", item.item_id).execute()
    sb.table("item_tracks").insert(rows).execute()


def process_item(
    sb: Client,
    item: CollectionItem,
    limiter: RateLimiter,
    dry_run: bool,
    apply_high_confidence: bool,
) -> None:
    log(f"\n[{item.item_type.upper()} #{item.item_id}] {item.artist_name} - {item.title}")

    candidate = find_best_candidate(item, limiter)

    if not candidate:
        log("  Sem candidato aceitável.")
        return

    log(
        f"  Match: {candidate.artist_name} - {candidate.release_title} "
        f"score={candidate.confidence:.2f} tracks={len(candidate.tracks)} "
        f"cover={'sim' if candidate.image_url else 'não'}"
    )

    local_path = None
    local_url = None

    should_auto_apply = (
        apply_high_confidence
        and candidate.image_url is not None
        and candidate.confidence >= cfg.AUTO_APPLY_MIN_CONFIDENCE
        and not (
            cfg.SKIP_COMPILATIONS_FOR_AUTO_APPLY
            and is_low_confidence_item(item)
        )
    )

    if candidate.image_url and should_auto_apply:
        if dry_run:
            local_path = f"{item.item_type}/{item.item_id}/DRY_RUN.jpg"
            local_url = f"https://dry-run/{local_path}"
            log(f"  [dry-run] faria download/upload para covers/{local_path}")
        else:
            try:
                local_path, local_url = upload_cover_to_storage(sb, item, candidate)
                log(f"  Upload cover: {local_path}")
            except Exception as exc:
                log(f"  Erro upload cover: {exc}")

    if should_auto_apply and local_url:
        apply_cover(sb, item, candidate, local_url, dry_run=dry_run)
        apply_tracks(sb, item, candidate, dry_run=dry_run)
        upsert_cover_suggestion(
            sb, item, candidate, local_path, local_url, "applied", dry_run=dry_run
        )
        save_track_suggestion(sb, item, candidate, "applied", dry_run=dry_run)
        log("  Auto-aplicado.")
    else:
        upsert_cover_suggestion(
            sb, item, candidate, local_path, local_url, "pending", dry_run=dry_run
        )
        save_track_suggestion(sb, item, candidate, "pending", dry_run=dry_run)
        log("  Guardado como sugestão.")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Busca capas/faixas via MusicBrainz/CAA.")
    parser.add_argument("--apply", action="store_true", help="Grava sugestões/uploads no Supabase.")
    parser.add_argument(
        "--apply-high-confidence",
        action="store_true",
        help="Atualiza cover_url e item_tracks quando a confiança for alta.",
    )
    parser.add_argument("--limit", type=int, default=cfg.METADATA_LIMIT)
    parser.add_argument("--offset", type=int, default=0)
    return parser.parse_args()



def main() -> int:
    args = parse_args()
    dry_run = not args.apply

    log("Modo: " + ("APPLY" if args.apply else "DRY-RUN"))
    log("Auto-apply high confidence: " + ("SIM" if args.apply_high_confidence else "NÃO"))
    log(f"Limit: {args.limit}")

    sb = supabase_client()
    limiter = RateLimiter(min_interval_seconds=1.5)

    items = fetch_items_without_cover(sb, limit=args.limit + args.offset)
    items = items[args.offset:]
    log(f"Itens sem capa encontrados: {len(items)}")

    for item in items:
        try:
            process_item(
                sb=sb,
                item=item,
                limiter=limiter,
                dry_run=dry_run,
                apply_high_confidence=args.apply_high_confidence,
            )
        except KeyboardInterrupt:
            log("Interrompido.")
            return 1
        except Exception as exc:
            log(f"  ERRO no item {item.item_type} #{item.item_id}: {exc}")

    log("\nConcluído.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())