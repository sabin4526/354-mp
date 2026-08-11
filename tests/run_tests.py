"""Simple terminal tests for the library database application."""

import os
import shutil
import sqlite3


SOURCE_DATABASE = "library.db"
TEST_DATABASE = "tests/test_library.db"


def print_result(number, name, expected, received, passed):
    """Print one test result in a readable format."""
    print(f"\nTest {number}: {name}")
    print(f"Expected answer: {expected}")
    print(f"Received answer: {received}")
    print(f"Passed?: {'Y' if passed else 'N'}")


def create_test_database():
    """Create a disposable copy so tests never modify library.db."""
    if os.path.exists(TEST_DATABASE):
        os.remove(TEST_DATABASE)
    shutil.copy2(SOURCE_DATABASE, TEST_DATABASE)


def test_database_structure():
    """Check that the copied database contains the final 16 tables."""
    connection = sqlite3.connect(TEST_DATABASE)
    table_count = connection.execute(
        "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table'"
    ).fetchone()[0]
    connection.close()
    return table_count == 16, table_count


def test_table_data():
    """Check that every table has at least 10 rows."""
    tables = [
        "Item", "Book", "SerialSeries", "Serial", "Record", "Copy",
        "Person", "Member", "Staff", "Loan", "Fine", "Room", "Event",
        "EventRegistration", "HelpRequest", "WishlistItem",
    ]
    connection = sqlite3.connect(TEST_DATABASE)
    counts = []
    passed = True
    for table in tables:
        count = connection.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        counts.append(f"{table}={count}")
        if count < 10:
            passed = False
    connection.close()
    return passed, ", ".join(counts)


def test_foreign_keys():
    """Check that every foreign key points to an existing row."""
    connection = sqlite3.connect(TEST_DATABASE)
    problems = connection.execute("PRAGMA foreign_key_check").fetchall()
    connection.close()
    return len(problems) == 0, "No problems" if not problems else str(problems)


def test_item_availability():
    """Check that open loans correctly reduce available copies."""
    connection = sqlite3.connect(TEST_DATABASE)
    total = connection.execute(
        "SELECT COUNT(*) FROM Copy WHERE item_id = 1"
    ).fetchone()[0]
    available = connection.execute(
        """
        SELECT COUNT(*)
        FROM Copy c
        WHERE c.item_id = 1
          AND NOT EXISTS (
              SELECT 1 FROM Loan l
              WHERE l.copy_id = c.copy_id AND l.return_date IS NULL
          )
        """
    ).fetchone()[0]
    connection.close()
    return (available, total) == (3, 5), f"{available} available out of {total} copies"


def test_borrow_available_copy():
    """Check that an active member can borrow an available copy."""
    connection = sqlite3.connect(TEST_DATABASE)
    connection.execute("PRAGMA foreign_keys = ON")
    try:
        connection.execute(
            """
            INSERT INTO Loan (loan_id, copy_id, member_id, borrow_date, due_date)
            VALUES (99, 6, 2, '2026-08-10', '2026-08-31')
            """
        )
        connection.commit()
        loan = connection.execute(
            "SELECT loan_id FROM Loan WHERE loan_id = 99"
        ).fetchone()
        connection.close()
        return loan is not None, "Loan 99 was created"
    except sqlite3.IntegrityError as error:
        connection.close()
        return False, str(error)


def test_borrow_unavailable_copy():
    """Check that a copy already on loan cannot be borrowed again."""
    connection = sqlite3.connect(TEST_DATABASE)
    try:
        connection.execute(
            """
            INSERT INTO Loan (loan_id, copy_id, member_id, borrow_date, due_date)
            VALUES (100, 6, 3, '2026-08-10', '2026-08-31')
            """
        )
        connection.close()
        return False, "A second loan was created"
    except sqlite3.IntegrityError as error:
        connection.close()
        return "copy is already on loan" in str(error), str(error)


def main():
    print("Starting library application test script")
    create_test_database()

    try:
        passed, received = test_database_structure()
        print_result(1, "Database structure", "16 tables", f"{received} tables", passed)

        passed, received = test_table_data()
        print_result(2, "Required seed data", "At least 10 rows in every table", received, passed)

        passed, received = test_foreign_keys()
        print_result(3, "Foreign-key integrity", "No foreign-key problems", received, passed)

        passed, received = test_item_availability()
        print_result(4, "Derived item availability", "3 available out of 5 copies", received, passed)

        passed, received = test_borrow_available_copy()
        print_result(5, "Borrow available copy", "Loan 99 is created", received, passed)

        passed, received = test_borrow_unavailable_copy()
        print_result(6, "Block unavailable copy", "Copy is already on loan", received, passed)
    finally:
        if os.path.exists(TEST_DATABASE):
            os.remove(TEST_DATABASE)


if __name__ == "__main__":
    main()
