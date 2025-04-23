import sqlite3
import os
from contextlib import contextmanager
from typing import Generator

# Database file path from environment variable or default
DB_PATH = os.environ.get("DB_PATH", "inbox.db")

# Ensure database directory exists
db_dir = os.path.dirname(DB_PATH)
if db_dir:
    os.makedirs(db_dir, exist_ok=True)

def init_db():
    """Initialize the database with the required schema."""
    with get_db_connection() as conn:
        conn.execute("""
        CREATE TABLE IF NOT EXISTS inbox (
            id TEXT PRIMARY KEY,
            text TEXT NOT NULL,
            audio_url TEXT,
            tag TEXT,
            pending INTEGER NOT NULL DEFAULT 1,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
        """)
        conn.commit()

@contextmanager
def get_db_connection() -> Generator[sqlite3.Connection, None, None]:
    """Get a database connection with row factory set to Row."""
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()

def get_all_items():
    """Get all items from the inbox table."""
    with get_db_connection() as conn:
        items = conn.execute(
            "SELECT * FROM inbox ORDER BY created_at DESC"
        ).fetchall()
        # Convert SQLite Row objects to dictionaries
        return [dict(item) for item in items]

def get_item_by_id(item_id: str):
    """Get a single item by ID."""
    with get_db_connection() as conn:
        item = conn.execute(
            "SELECT * FROM inbox WHERE id = ?", (item_id,)
        ).fetchone()
        return dict(item) if item else None

def insert_item(item_id: str, text: str, audio_url: str = None):
    """Insert a new item into the inbox."""
    with get_db_connection() as conn:
        conn.execute(
            "INSERT INTO inbox (id, text, audio_url, pending) VALUES (?, ?, ?, 1)",
            (item_id, text, audio_url)
        )
        conn.commit()
        return {"id": item_id}

def update_item(item_id: str, tag: str = None, pending: int = None):
    """Update an existing item."""
    with get_db_connection() as conn:
        # Only update the specified fields
        updates = []
        params = []
        
        if tag is not None:
            updates.append("tag = ?")
            params.append(tag)
        
        if pending is not None:
            updates.append("pending = ?")
            params.append(pending)
        
        if not updates:
            return None
        
        query = f"UPDATE inbox SET {', '.join(updates)} WHERE id = ?"
        params.append(item_id)
        
        conn.execute(query, params)
        conn.commit()
        return get_item_by_id(item_id)

# Initialize the database on import
init_db() 