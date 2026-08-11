"""SQLite connection helper for the library application."""

import sqlite3


def get_connection():
    """Connect to the project database."""
    connection = sqlite3.connect("library.db")
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA foreign_keys = ON")
    return connection

