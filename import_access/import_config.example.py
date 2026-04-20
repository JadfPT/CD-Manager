# Copia este ficheiro para import_config.py e preenche os valores reais.

# =========================
# Supabase
# =========================
SUPABASE_URL = "https://SEU_PROJECT_REF.supabase.co"
SUPABASE_SERVICE_ROLE_KEY = "SUA_SERVICE_ROLE_KEY"

# =========================
# Access
# =========================
ACCESS_DB_PATH = r"C:\caminho\para\a\base_de_dados.accdb"

# Nome do driver ODBC para Access no Windows
ACCESS_ODBC_DRIVER = r"Microsoft Access Driver (*.mdb, *.accdb)"

# =========================
# Tabelas / colunas no Access
# Ajusta se os nomes diferirem
# =========================
ARTISTS_TABLE = "Artistas"
ARTIST_ID_COL = "CódigoDoArtista"
ARTIST_NAME_COL = "NomeDoArtista"
ARTIST_GENRE_COL = "Género"


# Se o género estiver noutra tabela ou não existir aqui, deixa None
ARTIST_GENRE_COL = None

ALBUMS_TABLE = "Gravações"
ALBUM_ID_COL = "CódigoDoÁlbum"
ALBUM_TITLE_COL = "TítuloDoÁlbum"
ALBUM_ARTIST_ID_COL = "CódigoDoArtista"

# Só importar os CDs da prateleira
MAX_CD_ID = 893

# =========================
# Destino no Supabase
# =========================
SUPABASE_ARTISTS_TABLE = "artists"
SUPABASE_CD_ALBUMS_TABLE = "cd_albums"

# =========================
# Import options
# =========================
BATCH_SIZE = 200
DRY_RUN_DEFAULT = True

# Se quiseres forçar format_edition em todos os CDs importados
DEFAULT_CD_FORMAT_EDITION = "CD"

# Se quiseres guardar logs mais detalhados
VERBOSE = True