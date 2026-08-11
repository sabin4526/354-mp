import sqlite3
from datetime import date, timedelta

from database import get_connection


def ask_text(prompt, required=True):
    while True:
        value = input(prompt).strip()
        if value or not required:
            return value
        print("This value is required.")


def ask_int(prompt, required=True):
    while True:
        value = input(prompt).strip()
        if not value and not required:
            return None
        try:
            return int(value)
        except ValueError:
            print("Please enter a whole number.")


def ask_date(prompt, default=None):
    while True:
        suffix = f" [{default}]" if default else ""
        value = input(f"{prompt}{suffix}: ").strip() or default
        try:
            return date.fromisoformat(value).isoformat()
        except (TypeError, ValueError):
            print("Use YYYY-MM-DD.")


def next_id(connection, table, column):
    row = connection.execute(
        f"SELECT COALESCE(MAX({column}), 0) + 1 FROM {table}"
    ).fetchone()
    return row[0]


def find_item():
    keyword = ask_text("Search for an item (title, author, artist, ISBN, or ISSN): ")
    pattern = f"%{keyword}%"
    connection = get_connection()
    rows = connection.execute(
        """
        SELECT i.item_id,
               i.title,
               i.shelf_location,
               CASE
                   WHEN b.item_id IS NOT NULL THEN 'Book'
                   WHEN s.item_id IS NOT NULL THEN 'Serial'
                   WHEN r.item_id IS NOT NULL THEN 'Record'
               END AS item_type,
               COALESCE(b.author, r.artist, ss.publisher) AS creator,
               COUNT(c.copy_id) AS total_copies,
               COALESCE(SUM(CASE WHEN c.copy_id IS NOT NULL AND NOT EXISTS (
                   SELECT 1 FROM Loan l
                   WHERE l.copy_id = c.copy_id AND l.return_date IS NULL
               ) THEN 1 ELSE 0 END), 0) AS available_copies
        FROM Item i
        LEFT JOIN Book b ON b.item_id = i.item_id
        LEFT JOIN Serial s ON s.item_id = i.item_id
        LEFT JOIN SerialSeries ss ON ss.issn = s.issn
        LEFT JOIN Record r ON r.item_id = i.item_id
        LEFT JOIN Copy c ON c.item_id = i.item_id
        WHERE i.title LIKE ? COLLATE NOCASE
           OR b.author LIKE ? COLLATE NOCASE
           OR b.isbn LIKE ?
           OR s.issn LIKE ?
           OR r.artist LIKE ? COLLATE NOCASE
        GROUP BY i.item_id
        ORDER BY i.title
        """,
        (pattern, pattern, pattern, pattern, pattern),
    ).fetchall()
    connection.close()

    if not rows:
        print("No items found.")
        return

    print("\nItems found:")
    for row in rows:
        print(
            f"{row['item_id']}: {row['title']} ({row['item_type']}) - "
            f"{row['available_copies']}/{row['total_copies']} available"
        )
        print(f"   {row['creator'] or 'Unknown creator'} | {row['shelf_location'] or 'No shelf location'}")


def borrow_item():
    member_id = ask_int("Member ID: ")
    item_id = ask_int("Item ID: ")
    borrow_date = ask_date("Borrow date", date.today().isoformat())

    connection = get_connection()
    try:
        item = connection.execute(
            """
            SELECT i.title,
                   CASE WHEN r.item_id IS NOT NULL THEN 7 ELSE 21 END AS loan_days
            FROM Item i
            LEFT JOIN Record r ON r.item_id = i.item_id
            WHERE i.item_id = ?
            """,
            (item_id,),
        ).fetchone()
        if item is None:
            print("Item not found.")
            return

        copy = connection.execute(
            """
            SELECT c.copy_id, c.barcode
            FROM Copy c
            WHERE c.item_id = ?
              AND NOT EXISTS (
                  SELECT 1 FROM Loan l
                  WHERE l.copy_id = c.copy_id AND l.return_date IS NULL
              )
            ORDER BY c.copy_id
            LIMIT 1
            """,
            (item_id,),
        ).fetchone()
        if copy is None:
            print("No copies of this item are available.")
            return

        due_date = (
            date.fromisoformat(borrow_date) + timedelta(days=item["loan_days"])
        ).isoformat()
        loan_id = next_id(connection, "Loan", "loan_id")
        connection.execute(
            """
            INSERT INTO Loan (loan_id, copy_id, member_id, borrow_date, due_date)
            VALUES (?, ?, ?, ?, ?)
            """,
            (loan_id, copy["copy_id"], member_id, borrow_date, due_date),
        )
        connection.commit()
        print(
            f"Borrowed '{item['title']}' (barcode {copy['barcode']}). "
            f"Due date: {due_date}."
        )
    except sqlite3.IntegrityError as error:
        connection.rollback()
        print(f"Borrowing could not be completed: {error}")
    finally:
        connection.close()


def return_item():
    loan_id = ask_int("Open loan ID to return: ")
    return_date = ask_date("Return date", date.today().isoformat())

    connection = get_connection()
    try:
        loan = connection.execute(
            """
            SELECT loan_id, member_id, due_date, return_date
            FROM Loan
            WHERE loan_id = ?
            """,
            (loan_id,),
        ).fetchone()
        if loan is None or loan["return_date"] is not None:
            print("That is not an open loan.")
            return

        connection.execute(
            "UPDATE Loan SET return_date = ? WHERE loan_id = ?",
            (return_date, loan_id),
        )

        days_late = (date.fromisoformat(return_date) - date.fromisoformat(loan["due_date"])).days
        if days_late > 30:
            fine_id = next_id(connection, "Fine", "fine_id")
            connection.execute(
                """
                INSERT INTO Fine (fine_id, member_id, loan_id, reason, amount, date_assessed)
                VALUES (?, ?, ?, 'Lost', 30.00, ?)
                """,
                (fine_id, loan["member_id"], loan_id, return_date),
            )
            print("This item was more than 30 days overdue; a $30.00 lost-item fine was added.")

        connection.commit()
        print("Item returned. Any overdue fine was added automatically.")
    except sqlite3.IntegrityError as error:
        connection.rollback()
        print(f"Return could not be completed: {error}")
    finally:
        connection.close()


def donate_item():
    print("\nDonate an item")
    item_type = ask_text("Type (Book, Serial, or Record): ").title()
    if item_type not in ("Book", "Serial", "Record"):
        print("Please choose Book, Serial, or Record.")
        return

    title = ask_text("Title: ")
    pub_year = ask_int("Publication year (blank if unknown): ", required=False)
    subject = ask_text("Subject (blank if unknown): ", required=False) or None
    language = ask_text("Language (blank if unknown): ", required=False) or None
    shelf_location = ask_text("Shelf location/call number (blank if unknown): ", required=False) or None
    barcode = ask_text("Barcode: ")
    condition = ask_text("Condition [Good]: ", required=False) or "Good"
    acquired_date = ask_date("Acquired date", date.today().isoformat())

    connection = get_connection()
    try:
        item_id = next_id(connection, "Item", "item_id")
        copy_id = next_id(connection, "Copy", "copy_id")
        connection.execute(
            """
            INSERT INTO Item (item_id, title, pub_year, subject, language, shelf_location)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (item_id, title, pub_year, subject, language, shelf_location),
        )

        if item_type == "Book":
            isbn = ask_text("ISBN: ")
            author = ask_text("Author: ")
            publisher = ask_text("Publisher (blank if unknown): ", required=False) or None
            pages = ask_int("Pages (blank if unknown): ", required=False)
            connection.execute(
                "INSERT INTO Book VALUES (?, ?, ?, ?, ?)",
                (item_id, isbn, author, publisher, pages),
            )
        elif item_type == "Serial":
            issn = ask_text("ISSN: ")
            publisher = ask_text("Series publisher (blank if unknown): ", required=False) or None
            volume = ask_int("Volume (blank if unknown): ", required=False)
            issue_number = ask_int("Issue number (blank if unknown): ", required=False)
            series = connection.execute(
                "SELECT issn FROM SerialSeries WHERE issn = ?", (issn,)
            ).fetchone()
            if series is None:
                connection.execute(
                    "INSERT INTO SerialSeries (issn, publisher) VALUES (?, ?)",
                    (issn, publisher),
                )
            connection.execute(
                "INSERT INTO Serial VALUES (?, ?, ?, ?)",
                (item_id, issn, volume, issue_number),
            )
        else:
            artist = ask_text("Artist (blank if unknown): ", required=False) or None
            label = ask_text("Label (blank if unknown): ", required=False) or None
            runtime = ask_int("Runtime in minutes (blank if unknown): ", required=False)
            genre = ask_text("Genre (blank if unknown): ", required=False) or None
            connection.execute(
                "INSERT INTO Record VALUES (?, ?, ?, ?, ?)",
                (item_id, artist, label, runtime, genre),
            )

        connection.execute(
            """
            INSERT INTO Copy (copy_id, item_id, barcode, condition, acquired_date)
            VALUES (?, ?, ?, ?, ?)
            """,
            (copy_id, item_id, barcode, condition.title(), acquired_date),
        )
        updated = connection.execute(
            """
            UPDATE WishlistItem
            SET status = 'Acquired', acquired_item = ?
            WHERE title = ? COLLATE NOCASE
              AND status <> 'Acquired'
            """,
            (item_id, title),
        ).rowcount
        connection.commit()
        print(f"Donation catalogued as item {item_id}, copy {copy_id}.")
        if updated:
            print("Matching wishlist item marked as acquired.")
    except sqlite3.IntegrityError as error:
        connection.rollback()
        print(f"Donation could not be completed: {error}")
    finally:
        connection.close()


def find_event():
    keyword = ask_text("Search events (leave blank to list all): ", required=False)
    pattern = f"%{keyword}%"
    connection = get_connection()
    rows = connection.execute(
        """
        SELECT e.event_id, e.title, e.event_type, e.event_date, e.start_time, e.end_time,
               e.min_age, e.max_age, e.max_attendees, r.name AS room_name,
               COUNT(er.member_id) AS registrations
        FROM Event e
        JOIN Room r ON r.room_id = e.room_id
        LEFT JOIN EventRegistration er ON er.event_id = e.event_id
        WHERE e.title LIKE ? COLLATE NOCASE OR e.event_type LIKE ? COLLATE NOCASE
        GROUP BY e.event_id
        ORDER BY e.event_date, e.start_time
        """,
        (pattern, pattern),
    ).fetchall()
    connection.close()

    if not rows:
        print("No events found.")
        return

    print("\nEvents:")
    for row in rows:
        age = "All ages"
        if row["min_age"] is not None and row["max_age"] is not None:
            age = f"Ages {row['min_age']}-{row['max_age']}"
        elif row["min_age"] is not None:
            age = f"Ages {row['min_age']}+"
        elif row["max_age"] is not None:
            age = f"Up to age {row['max_age']}"
        capacity = "No registration cap" if row["max_attendees"] is None else f"{row['registrations']}/{row['max_attendees']} registered"
        print(
            f"{row['event_id']}: {row['title']} - {row['event_date']} "
            f"{row['start_time']}-{row['end_time']}\n"
            f"   {row['event_type']} | {row['room_name']} | {age} | {capacity}"
        )


def register_for_event():
    event_id = ask_int("Event ID: ")
    member_id = ask_int("Member ID: ")
    registered_date = ask_date("Registration date", date.today().isoformat())

    connection = get_connection()
    try:
        connection.execute(
            """
            INSERT INTO EventRegistration (event_id, member_id, date_registered)
            VALUES (?, ?, ?)
            """,
            (event_id, member_id, registered_date),
        )
        connection.commit()
        print("Event registration complete.")
    except sqlite3.IntegrityError as error:
        connection.rollback()
        print(f"Registration could not be completed: {error}")
    finally:
        connection.close()


def volunteer():
    print("\nVolunteer registration")
    first_name = ask_text("First name: ")
    last_name = ask_text("Last name: ")
    email = ask_text("Email (blank if unknown): ", required=False) or None
    phone = ask_text("Phone (blank if unknown): ", required=False) or None
    birth_date = ask_text("Date of birth YYYY-MM-DD (blank if unknown): ", required=False) or None
    address = ask_text("Address (blank if unknown): ", required=False) or None
    supervisor_id = ask_int("Supervisor staff ID (blank if none): ", required=False)

    connection = get_connection()
    try:
        person_id = next_id(connection, "Person", "person_id")
        connection.execute(
            """
            INSERT INTO Person (person_id, first_name, last_name, email, phone, date_of_birth, address)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (person_id, first_name, last_name, email, phone, birth_date, address),
        )
        connection.execute(
            """
            INSERT INTO Staff (person_id, role, hire_date, salary, supervisor_id)
            VALUES (?, 'Volunteer', ?, NULL, ?)
            """,
            (person_id, date.today().isoformat(), supervisor_id),
        )
        connection.commit()
        print(f"Volunteer registered with staff ID {person_id}.")
    except sqlite3.IntegrityError as error:
        connection.rollback()
        print(f"Volunteer registration could not be completed: {error}")
    finally:
        connection.close()


def ask_librarian():
    member_id = ask_int("Member ID: ")
    question = ask_text("Question for the librarian: ")

    connection = get_connection()
    try:
        request_id = next_id(connection, "HelpRequest", "request_id")
        connection.execute(
            """
            INSERT INTO HelpRequest (request_id, member_id, staff_id, question, date_asked, status)
            VALUES (?, ?, NULL, ?, ?, 'Open')
            """,
            (request_id, member_id, question, date.today().isoformat()),
        )
        connection.commit()
        print(f"Help request {request_id} has been added to the librarian queue.")
    except sqlite3.IntegrityError as error:
        connection.rollback()
        print(f"Help request could not be completed: {error}")
    finally:
        connection.close()


def main():
    actions = {
        "1": ("Find an item", find_item),
        "2": ("Borrow an item", borrow_item),
        "3": ("Return a borrowed item", return_item),
        "4": ("Donate an item", donate_item),
        "5": ("Find an event", find_event),
        "6": ("Register for an event", register_for_event),
        "7": ("Volunteer for the library", volunteer),
        "8": ("Ask a librarian for help", ask_librarian),
    }

    while True:
        print("\n--- Vancouver Library ---")
        for number, (label, _) in actions.items():
            print(f"{number}. {label}")
        print("0. Exit")

        choice = input("Choose an option: ").strip()
        if choice == "0":
            print("Thank you, come again!")
            break
        action = actions.get(choice)
        if action is None:
            print("Please choose a menu option.")
        else:
            action[1]()


if __name__ == "__main__":
    main()
