"""CRUD examples for the notes table.

Run after applying schema.sql. Uses IAM auth via connect.py.

Note: psycopg 3 Connection auto-commits on clean context-manager exit
and rolls back on exception, so explicit conn.commit() calls are not
strictly needed inside `with connect() as conn:` blocks. We include
them here so the commit point is visible for readers who expect it.
"""

from __future__ import annotations

from connect import connect


def create_note(title: str, body: str) -> int:
    with connect() as conn, conn.cursor() as cur:
        cur.execute(
            "INSERT INTO notes (title, body) VALUES (%s, %s) RETURNING id",
            (title, body),
        )
        (note_id,) = cur.fetchone()
        conn.commit()
        return note_id


def get_note(note_id: int) -> dict | None:
    with connect() as conn, conn.cursor() as cur:
        cur.execute(
            "SELECT id, title, body, created_at, updated_at FROM notes WHERE id = %s",
            (note_id,),
        )
        row = cur.fetchone()
    if row is None:
        return None
    return {
        "id": row[0],
        "title": row[1],
        "body": row[2],
        "created_at": row[3].isoformat(),
        "updated_at": row[4].isoformat(),
    }


def list_notes(limit: int = 20) -> list[dict]:
    with connect() as conn, conn.cursor() as cur:
        cur.execute(
            "SELECT id, title, created_at FROM notes ORDER BY created_at DESC LIMIT %s",
            (limit,),
        )
        return [
            {"id": r[0], "title": r[1], "created_at": r[2].isoformat()}
            for r in cur.fetchall()
        ]


def update_note(note_id: int, title: str, body: str) -> bool:
    with connect() as conn, conn.cursor() as cur:
        cur.execute(
            """
            UPDATE notes
               SET title = %s, body = %s, updated_at = now()
             WHERE id = %s
            """,
            (title, body, note_id),
        )
        changed = cur.rowcount
        conn.commit()
    return changed == 1


def delete_note(note_id: int) -> bool:
    with connect() as conn, conn.cursor() as cur:
        cur.execute("DELETE FROM notes WHERE id = %s", (note_id,))
        changed = cur.rowcount
        conn.commit()
    return changed == 1


def main() -> None:
    note_id = create_note("First note", "Aurora Express took 30 seconds to spin up.")
    print("Created:", get_note(note_id))

    update_note(note_id, "First note", "Aurora Express took 30 seconds. IAM auth worked out of the box.")
    print("Updated:", get_note(note_id))

    print("Recent:", list_notes(5))

    delete_note(note_id)
    print("Remaining:", list_notes(5))


if __name__ == "__main__":
    main()
