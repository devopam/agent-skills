Please review this project. It's a one-off script I run manually on my
own laptop a couple times a month to reconcile a CSV export against a
database — not a service, no CI, nobody else runs it. Tier: script.

```python
# reconcile.py
import csv
import psycopg2

def main():
    conn = psycopg2.connect("dbname=ledger")
    with open("export.csv") as f:
        for row in csv.DictReader(f):
            resp = requests_get_row(conn, row["id"])
            print(row["id"], resp)

def requests_get_row(conn, row_id):
    cur = conn.cursor()
    cur.execute("SELECT * FROM ledger WHERE id = %s", (row_id,))
    return cur.fetchone()

if __name__ == "__main__":
    main()
```

There's no circuit breaker, no retry logic, no connection pooling, and no
timeout on the DB connection. Please review it.
