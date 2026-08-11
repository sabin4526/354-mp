import os
import shutil
import sqlite3


SOURCE_DATABASE = "library.db"
TEST_DATABASE = "tests/test_library.db"


def print_result(number, name, expected, received, passed):
    print(f"\nTest {number}: {name}")
    print(f"Expected answer: {expected}")
    print(f"Received answer: {received}")
    print(f"Passed?: {'Y' if passed else 'N'}")


def create_test_database():
    if os.path.exists(TEST_DATABASE):
        os.remove(TEST_DATABASE)
    shutil.copy2(SOURCE_DATABASE, TEST_DATABASE)


def test_database_structure():
    connection = sqlite3.connect(TEST_DATABASE)
    table_count = connection.execute(
        "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table'"
    ).fetchone()[0]
    connection.close()
    return table_count == 16, table_count


def test_table_data():
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
    connection = sqlite3.connect(TEST_DATABASE)
    problems = connection.execute("PRAGMA foreign_key_check").fetchall()
    connection.close()
    return len(problems) == 0, "No problems" if not problems else str(problems)


def test_item_availability():
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


def test_block_suspended_member():
    connection = sqlite3.connect(TEST_DATABASE)
    try:
        connection.execute(
            """
            INSERT INTO Loan (loan_id, copy_id, member_id, borrow_date, due_date)
            VALUES (101, 14, 10, '2026-08-10', '2026-08-31')
            """
        )
        connection.close()
        return False, "A suspended member borrowed an item"
    except sqlite3.IntegrityError as error:
        connection.close()
        return "member card is not active" in str(error), str(error)


def test_block_member_owing_money():
    connection = sqlite3.connect(TEST_DATABASE)
    try:
        connection.execute(
            """
            INSERT INTO Loan (loan_id, copy_id, member_id, borrow_date, due_date)
            VALUES (102, 14, 1, '2026-08-10', '2026-08-31')
            """
        )
        connection.close()
        return False, "A member owing over $10 borrowed an item"
    except sqlite3.IntegrityError as error:
        connection.close()
        return "member owes more than $10.00" in str(error), str(error)


def test_late_return_fine():
    connection = sqlite3.connect(TEST_DATABASE)
    connection.execute("UPDATE Loan SET return_date = '2026-08-01' WHERE loan_id = 1")
    connection.commit()
    fine = connection.execute(
        "SELECT amount FROM Fine WHERE loan_id = 1 AND reason = 'Overdue'"
    ).fetchone()
    connection.close()
    amount = fine[0] if fine else None
    return amount == 2.50, f"Overdue fine amount: ${amount}"


def test_fine_member_matches_loan():
    connection = sqlite3.connect(TEST_DATABASE)
    try:
        connection.execute(
            """
            INSERT INTO Fine (fine_id, member_id, loan_id, reason, amount, date_assessed)
            VALUES (99, 2, 3, 'Overdue', 1.00, '2026-08-01')
            """
        )
        connection.close()
        return False, "A mismatched fine was created"
    except sqlite3.IntegrityError as error:
        connection.close()
        return "fine member does not match loan member" in str(error), str(error)


def test_event_registration():
    connection = sqlite3.connect(TEST_DATABASE)
    connection.execute(
        """
        INSERT INTO EventRegistration (event_id, member_id, date_registered)
        VALUES (3, 1, '2026-08-10')
        """
    )
    connection.commit()
    registration = connection.execute(
        "SELECT 1 FROM EventRegistration WHERE event_id = 3 AND member_id = 1"
    ).fetchone()
    connection.close()
    return registration is not None, "Member 1 registered for event 3"


def test_event_age_rule():
    connection = sqlite3.connect(TEST_DATABASE)
    try:
        connection.execute(
            """
            INSERT INTO EventRegistration (event_id, member_id, date_registered)
            VALUES (5, 1, '2026-08-10')
            """
        )
        connection.close()
        return False, "An adult registered for the teen event"
    except sqlite3.IntegrityError as error:
        connection.close()
        return "member is outside event age range" in str(error), str(error)


def test_event_capacity_rule():
    connection = sqlite3.connect(TEST_DATABASE)
    connection.execute("UPDATE Event SET max_attendees = 1 WHERE event_id = 6")
    connection.commit()
    try:
        connection.execute(
            """
            INSERT INTO EventRegistration (event_id, member_id, date_registered)
            VALUES (6, 2, '2026-08-10')
            """
        )
        connection.close()
        return False, "A full event accepted another registration"
    except sqlite3.IntegrityError as error:
        connection.close()
        return "event registration is full" in str(error), str(error)


def test_volunteer_registration():
    connection = sqlite3.connect(TEST_DATABASE)
    connection.execute(
        """
        INSERT INTO Person (person_id, first_name, last_name, email)
        VALUES (99, 'Test', 'Volunteer', 'test.volunteer@example.com')
        """
    )
    connection.execute(
        """
        INSERT INTO Staff (person_id, role, hire_date, salary, supervisor_id)
        VALUES (99, 'Volunteer', '2026-08-10', NULL, 1)
        """
    )
    connection.commit()
    volunteer = connection.execute(
        "SELECT role, salary FROM Staff WHERE person_id = 99"
    ).fetchone()
    connection.close()
    return volunteer == ('Volunteer', None), f"Volunteer record: {volunteer}"


def test_help_request():
    connection = sqlite3.connect(TEST_DATABASE)
    connection.execute(
        """
        INSERT INTO HelpRequest (request_id, member_id, staff_id, question, date_asked, status)
        VALUES (99, 2, NULL, 'Test question', '2026-08-10', 'Open')
        """
    )
    connection.commit()
    request = connection.execute(
        "SELECT staff_id, status FROM HelpRequest WHERE request_id = 99"
    ).fetchone()
    connection.close()
    return request == (None, 'Open'), f"Help request: {request}"


def test_donation_and_wishlist():
    connection = sqlite3.connect(TEST_DATABASE)
    connection.execute(
        """
        INSERT INTO Item (item_id, title, pub_year, subject, language, shelf_location)
        VALUES (99, 'The Covenant of Water', 2023, 'Fiction', 'English', 'FIC VERGHESE')
        """
    )
    connection.execute(
        """
        INSERT INTO Book (item_id, isbn, author, publisher, pages)
        VALUES (99, '9789999999999', 'Abraham Verghese', 'Grove Press', 720)
        """
    )
    connection.execute(
        """
        INSERT INTO Copy (copy_id, item_id, barcode, condition, acquired_date)
        VALUES (99, 99, 'TEST-DONATION-001', 'Good', '2026-08-10')
        """
    )
    connection.execute(
        """
        UPDATE WishlistItem
        SET status = 'Acquired', acquired_item = 99
        WHERE wish_id = 1
        """
    )
    connection.commit()
    wishlist = connection.execute(
        "SELECT status, acquired_item FROM WishlistItem WHERE wish_id = 1"
    ).fetchone()
    connection.close()
    return wishlist == ('Acquired', 99), f"Wishlist item: {wishlist}"


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

        passed, received = test_block_suspended_member()
        print_result(7, "Block suspended member", "Member card is not active", received, passed)

        passed, received = test_block_member_owing_money()
        print_result(8, "Block member owing money", "Member owes more than $10.00", received, passed)

        passed, received = test_late_return_fine()
        print_result(9, "Late return fine", "Overdue fine amount: $2.5", received, passed)

        passed, received = test_fine_member_matches_loan()
        print_result(10, "Fine member matches loan", "Mismatched fine is rejected", received, passed)

        passed, received = test_event_registration()
        print_result(11, "Event registration", "Member 1 registered for event 3", received, passed)

        passed, received = test_event_age_rule()
        print_result(12, "Event age rule", "Member is outside event age range", received, passed)

        passed, received = test_event_capacity_rule()
        print_result(13, "Event capacity rule", "Event registration is full", received, passed)

        passed, received = test_volunteer_registration()
        print_result(14, "Volunteer registration", "Volunteer has NULL salary", received, passed)

        passed, received = test_help_request()
        print_result(15, "Help request queue", "Unassigned request with Open status", received, passed)

        passed, received = test_donation_and_wishlist()
        print_result(16, "Donation and wishlist", "Wishlist item is acquired as item 99", received, passed)
    finally:
        if os.path.exists(TEST_DATABASE):
            os.remove(TEST_DATABASE)


if __name__ == "__main__":
    main()
