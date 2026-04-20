from __future__ import annotations

import argparse
import math
import sys
from dataclasses import dataclass
from typing import Any, Iterable

import pyodbc
from supabase import Client, create_client

import import_config as cfg


@dataclass
class ImportStats:
    artists_read: int = 0
    artists_sent: int = 0
    albums_read: int = 0
    albums_sent: int = 0


def log(message: str) -> None:
    print(message)


def debug(message: str) -> None:
    if getattr(cfg, "VERBOSE", False):
        print(f"[debug] {message}")


def chunked(items: list[dict[str, Any]], size: int) -> Iterable[list[dict[str, Any]]]:
    for i in range(0, len(items), size):
        yield items[i : i + size]


def clean_str(value: Any) -> str | None:
    if value is None:
        return None
    text = str(value).strip()
    return text if text else None


def clean_int(value: Any) -> int | None:
    if value is None:
        return None
    if isinstance(value, int):
        return value
    text = str(value).strip()
    if not text:
        return None
    try:
        return int(float(text))
    except ValueError:
        return None


def build_access_connection() -> pyodbc.Connection:
    conn_str = (
        f"Driver={{{cfg.ACCESS_ODBC_DRIVER}}};"
        f"Dbq={cfg.ACCESS_DB_PATH};"
    )
    debug(f"A abrir Access em: {cfg.ACCESS_DB_PATH}")
    return pyodbc.connect(conn_str)


def build_supabase_client() -> Client:
    return create_client(cfg.SUPABASE_URL, cfg.SUPABASE_SERVICE_ROLE_KEY)


def list_tables(conn: pyodbc.Connection) -> list[str]:
    cursor = conn.cursor()
    tables = []
    for row in cursor.tables(tableType="TABLE"):
        tables.append(row.table_name)
    return sorted(set(tables))


def validate_access_objects(conn: pyodbc.Connection) -> None:
    tables = list_tables(conn)
    required = [cfg.ARTISTS_TABLE, cfg.ALBUMS_TABLE]
    missing = [name for name in required if name not in tables]
    if missing:
        raise RuntimeError(
            f"Tabelas em falta no Access: {missing}. "
            f"Tabelas encontradas: {tables}"
        )


def quote_ident(name: str) -> str:
    # Access usa colchetes
    return f"[{name}]"


def fetch_artists(conn: pyodbc.Connection, used_artist_ids: set[int]) -> list[dict[str, Any]]:
    cursor = conn.cursor()

    cols = [
        cfg.ARTIST_ID_COL,
        cfg.ARTIST_NAME_COL,
    ]
    if cfg.ARTIST_GENRE_COL:
        cols.append(cfg.ARTIST_GENRE_COL)

    select_cols = ", ".join(quote_ident(c) for c in cols)
    sql = f"SELECT {select_cols} FROM {quote_ident(cfg.ARTISTS_TABLE)}"

    debug(f"SQL artists: {sql}")
    rows = cursor.execute(sql).fetchall()
    artists: list[dict[str, Any]] = []

    for row in rows:
        artist_id = clean_int(getattr(row, cfg.ARTIST_ID_COL))
        if artist_id is None or artist_id not in used_artist_ids:
            continue

        artist_name = clean_str(getattr(row, cfg.ARTIST_NAME_COL))
        if not artist_name:
            debug(f"Artista ignorado sem nome: id={artist_id}")
            continue

        record = {
            "id": artist_id,
            "name": artist_name,
            "genre_text": clean_str(getattr(row, cfg.ARTIST_GENRE_COL)) if cfg.ARTIST_GENRE_COL else None,
        }
        artists.append(record)

    artists.sort(key=lambda x: x["id"])
    return artists


def fetch_cd_albums(conn: pyodbc.Connection) -> list[dict[str, Any]]:
    cursor = conn.cursor()

    sql = f"""
        SELECT
            {quote_ident(cfg.ALBUM_ID_COL)},
            {quote_ident(cfg.ALBUM_TITLE_COL)},
            {quote_ident(cfg.ALBUM_ARTIST_ID_COL)}
        FROM {quote_ident(cfg.ALBUMS_TABLE)}
        WHERE {quote_ident(cfg.ALBUM_ID_COL)} <= ?
        ORDER BY {quote_ident(cfg.ALBUM_ID_COL)} ASC
    """

    debug(f"SQL albums: {sql}")
    rows = cursor.execute(sql, cfg.MAX_CD_ID).fetchall()
    albums: list[dict[str, Any]] = []

    for row in rows:
        album_id = clean_int(getattr(row, cfg.ALBUM_ID_COL))
        title = clean_str(getattr(row, cfg.ALBUM_TITLE_COL))
        artist_id = clean_int(getattr(row, cfg.ALBUM_ARTIST_ID_COL))

        if album_id is None or title is None or artist_id is None:
            debug(
                "CD ignorado por campos em falta: "
                f"id={album_id}, title={title}, artist_id={artist_id}"
            )
            continue

        record = {
            "id": album_id,
            "title": title,
            "artist_id": artist_id,
            "on_shelf": True,
            "cover_url": None,
            "format_edition": getattr(cfg, "DEFAULT_CD_FORMAT_EDITION", None),
            "admin_notes": None,
            "is_archived": False,
        }
        albums.append(record)

    return albums


def upsert_rows(
    supabase: Client,
    table_name: str,
    rows: list[dict[str, Any]],
    on_conflict: str,
    batch_size: int,
    dry_run: bool,
) -> int:
    if not rows:
        return 0

    if dry_run:
        log(f"[dry-run] {len(rows)} rows seriam enviadas para '{table_name}'")
        return len(rows)

    sent = 0
    total_batches = math.ceil(len(rows) / batch_size)

    for idx, batch in enumerate(chunked(rows, batch_size), start=1):
        debug(
            f"Upsert batch {idx}/{total_batches} "
            f"na tabela '{table_name}' com {len(batch)} rows"
        )
        (
            supabase.table(table_name)
            .upsert(batch, on_conflict=on_conflict)
            .execute()
        )
        sent += len(batch)

    return sent


def preview_rows(label: str, rows: list[dict[str, Any]], limit: int = 5) -> None:
    log(f"\n--- Preview {label} ({min(limit, len(rows))}/{len(rows)}) ---")
    for row in rows[:limit]:
        log(str(row))


def run_import(dry_run: bool) -> ImportStats:
    stats = ImportStats()

    conn = build_access_connection()
    supabase = build_supabase_client()

    try:
        validate_access_objects(conn)

        # 1) CDs
        cd_albums = fetch_cd_albums(conn)
        stats.albums_read = len(cd_albums)

        used_artist_ids = {row["artist_id"] for row in cd_albums}

        # 2) Artistas usados pelos CDs
        artists = fetch_artists(conn, used_artist_ids)
        stats.artists_read = len(artists)

        preview_rows("artists", artists)
        preview_rows("cd_albums", cd_albums)
        
        analyze_artists_genre(artists)

        # 3) Upsert artists
        stats.artists_sent = upsert_rows(
            supabase=supabase,
            table_name=cfg.SUPABASE_ARTISTS_TABLE,
            rows=artists,
            on_conflict="id",
            batch_size=cfg.BATCH_SIZE,
            dry_run=dry_run,
        )

        # 4) Upsert cd_albums
        stats.albums_sent = upsert_rows(
            supabase=supabase,
            table_name=cfg.SUPABASE_CD_ALBUMS_TABLE,
            rows=cd_albums,
            on_conflict="id",
            batch_size=cfg.BATCH_SIZE,
            dry_run=dry_run,
        )

        return stats

    finally:
        conn.close()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Importa CDs do Access para o Supabase."
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Executa a importação de verdade. Sem isto, corre em dry-run.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    dry_run = not args.apply

    if dry_run:
        log("A correr em DRY-RUN. Nada será gravado no Supabase.")
    else:
        log("A correr em APPLY. Os dados serão gravados no Supabase.")

    try:
        stats = run_import(dry_run=dry_run)
    except Exception as exc:
        log(f"\nERRO: {exc}")
        return 1

    log("\n=== RESUMO ===")
    log(f"Artists lidos:   {stats.artists_read}")
    log(f"Artists enviados:{stats.artists_sent}")
    log(f"CDs lidos:       {stats.albums_read}")
    log(f"CDs enviados:    {stats.albums_sent}")

    return 0

def analyze_artists_genre(artists: list[dict]):
    total = len(artists)
    with_genre = [a for a in artists if a.get("genre_text")]
    without_genre = [a for a in artists if not a.get("genre_text")]

    print("\n=== ANÁLISE DE GÉNEROS ===")
    print(f"Total de artistas: {total}")
    print(f"Com género:        {len(with_genre)}")
    print(f"Sem género:        {len(without_genre)}")

    print("\n--- Exemplos COM género ---")
    for a in with_genre[:5]:
        print(f"{a['id']} - {a['name']} → {a['genre_text']}")

    print("\n--- Exemplos SEM género ---")
    for a in without_genre[:5]:
        print(f"{a['id']} - {a['name']}")


if __name__ == "__main__":
    raise SystemExit(main())