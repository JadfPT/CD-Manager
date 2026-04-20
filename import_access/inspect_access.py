import pyodbc
import import_config as cfg

def quote_ident(name: str) -> str:
    return f"[{name}]"

def main():
    conn_str = (
        f"Driver={{{cfg.ACCESS_ODBC_DRIVER}}};"
        f"Dbq={cfg.ACCESS_DB_PATH};"
    )
    conn = pyodbc.connect(conn_str)
    cur = conn.cursor()

    print("=== TABELAS / QUERIES ===")
    for row in cur.tables():
        print(f"{row.table_type:10} | {row.table_name}")

    print("\n=== COLUNAS DA TABELA CONFIGURADA ===")
    for row in cur.columns(table=cfg.ALBUMS_TABLE):
        print(f"{row.column_name}")

    print("\n=== TESTE SELECT TOP 1 * ===")
    sql = f"SELECT TOP 1 * FROM {quote_ident(cfg.ALBUMS_TABLE)}"
    print(sql)
    rows = cur.execute(sql).fetchall()
    print("Número de rows:", len(rows))
    print("Colunas devolvidas:")
    for col in cur.description:
        print(col[0])
        
    print("\n=== COLUNAS DA TABELA ARTISTAS ===")
    for row in cur.columns(table=cfg.ARTISTS_TABLE):
        print(f"{row.column_name}")

    print("\n=== TESTE SELECT TOP 1 * FROM ARTISTAS ===")
    sql = f"SELECT TOP 1 * FROM {quote_ident(cfg.ARTISTS_TABLE)}"
    print(sql)
    rows = cur.execute(sql).fetchall()
    print("Número de rows:", len(rows))
    print("Colunas devolvidas:")
    for col in cur.description:
        print(col[0])

    conn.close()

if __name__ == "__main__":
    main()