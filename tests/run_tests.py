"""Simple terminal tests for the library database application."""

import shutil
import sqlite3
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent
SOURCE_DATABASE = PROJECT_ROOT / "library.db"
TEST_DATABASE = Path(__file__).resolve().parent / "test_library.db"


def print_result(number, name, expected, received, passed):
    """Print one test result in a readable format."""
    print(f"\nTest {number}: {name}")
    print(f"Expected answer: {expected}")
    print(f"Received answer: {received}")
    print(f"Passed?: {'Y' if passed else 'N'}")


def create_test_database():
    """Create a disposable copy so tests never modify library.db."""
    if TEST_DATABASE.exists():
        TEST_DATABASE.unlink()
    shutil.copy2(SOURCE_DATABASE, TEST_DATABASE)


def test_database_structure():
    """Check that the copied database contains the final 16 tables."""
    connection = sqlite3.connect(TEST_DATABASE)
    table_count = connection.execute(
        "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table'"
    ).fetchone()[0]
    connection.close()
    return table_count == 16, table_count


def main():
    print("Starting library application test script")
    create_test_database()

    try:
        passed, received = test_database_structure()
        print_result(1, "Database structure", "16 tables", f"{received} tables", passed)
    finally:
        if TEST_DATABASE.exists():
            TEST_DATABASE.unlink()


if __name__ == "__main__":
    main()

