-- CMPT-354 Library Database - Step 4 schema
-- Source design: HANDOFF.md and the submitted Step 3 BCNF analysis.

PRAGMA foreign_keys = ON;

BEGIN;

-- Catalog: Item is the supertype; each subtype reuses item_id as its key.
CREATE TABLE Item (
    item_id        INTEGER PRIMARY KEY,
    title          TEXT NOT NULL,
    pub_year       INTEGER,
    subject        TEXT,
    language       TEXT,
    shelf_location TEXT
);

CREATE TABLE Book (
    item_id   INTEGER PRIMARY KEY REFERENCES Item(item_id),
    isbn      TEXT UNIQUE NOT NULL,
    author    TEXT NOT NULL,
    publisher TEXT,
    pages     INTEGER CHECK (pages IS NULL OR pages > 0)
);

-- Publisher belongs to a serial series, not to each individual issue.
CREATE TABLE SerialSeries (
    issn      TEXT PRIMARY KEY,
    publisher TEXT
);

CREATE TABLE Serial (
    item_id  INTEGER PRIMARY KEY REFERENCES Item(item_id),
    issn     TEXT NOT NULL REFERENCES SerialSeries(issn),
    volume   INTEGER,
    issue_no INTEGER,
    UNIQUE (issn, volume, issue_no)
);

CREATE TABLE Record (
    item_id     INTEGER PRIMARY KEY REFERENCES Item(item_id),
    artist      TEXT,
    label       TEXT,
    runtime_min INTEGER CHECK (runtime_min IS NULL OR runtime_min > 0),
    genre       TEXT
);

CREATE TABLE Copy (
    copy_id       INTEGER PRIMARY KEY,
    item_id       INTEGER NOT NULL REFERENCES Item(item_id),
    barcode       TEXT UNIQUE NOT NULL,
    condition     TEXT CHECK (condition IN ('New', 'Good', 'Fair', 'Poor', 'Damaged')),
    acquired_date DATE
);

-- People: specialization is overlapping, so a person may be both Member and Staff.
CREATE TABLE Person (
    person_id     INTEGER PRIMARY KEY,
    first_name    TEXT NOT NULL,
    last_name     TEXT NOT NULL,
    email         TEXT UNIQUE,
    phone         TEXT,
    date_of_birth DATE,
    address       TEXT
);

CREATE TABLE Member (
    person_id    INTEGER PRIMARY KEY REFERENCES Person(person_id),
    card_number  TEXT UNIQUE NOT NULL,
    member_since DATE,
    card_status  TEXT CHECK (card_status IN ('Active', 'Suspended', 'Expired'))
);

CREATE TABLE Staff (
    person_id     INTEGER PRIMARY KEY REFERENCES Person(person_id),
    role          TEXT NOT NULL CHECK (role IN ('Librarian', 'Assistant', 'Manager', 'Volunteer')),
    hire_date     DATE,
    salary        REAL,
    supervisor_id INTEGER REFERENCES Staff(person_id)
);

-- Circulation. Availability is derived from Loan.return_date, never stored.
CREATE TABLE Loan (
    loan_id       INTEGER PRIMARY KEY,
    copy_id       INTEGER NOT NULL REFERENCES Copy(copy_id),
    member_id     INTEGER NOT NULL REFERENCES Member(person_id),
    borrow_date   DATE NOT NULL,
    due_date      DATE NOT NULL,
    renewal_count INTEGER NOT NULL DEFAULT 0 CHECK (renewal_count >= 0),
    return_date   DATE,
    CHECK (due_date > borrow_date),
    CHECK (return_date IS NULL OR return_date >= borrow_date)
);

CREATE TABLE Fine (
    fine_id       INTEGER PRIMARY KEY,
    member_id     INTEGER NOT NULL REFERENCES Member(person_id),
    loan_id       INTEGER REFERENCES Loan(loan_id),
    reason        TEXT CHECK (reason IN ('Overdue', 'Damaged', 'Lost', 'Card replacement')),
    amount        REAL NOT NULL CHECK (amount >= 0),
    date_assessed DATE NOT NULL,
    amount_paid   REAL NOT NULL DEFAULT 0 CHECK (amount_paid >= 0),
    date_paid     DATE,
    CHECK (amount_paid <= amount)
);

-- Events and rooms.
CREATE TABLE Room (
    room_id   INTEGER PRIMARY KEY,
    name      TEXT UNIQUE NOT NULL,
    room_type TEXT,
    floor     INTEGER,
    capacity  INTEGER CHECK (capacity > 0)
);

CREATE TABLE Event (
    event_id      INTEGER PRIMARY KEY,
    title         TEXT NOT NULL,
    description   TEXT,
    event_type    TEXT,
    event_date    DATE NOT NULL,
    start_time    TEXT NOT NULL,
    end_time      TEXT NOT NULL,
    min_age       INTEGER CHECK (min_age IS NULL OR min_age >= 0),
    max_age       INTEGER CHECK (max_age IS NULL OR max_age >= 0),
    max_attendees INTEGER CHECK (max_attendees IS NULL OR max_attendees > 0),
    room_id       INTEGER NOT NULL REFERENCES Room(room_id),
    organizer_id  INTEGER NOT NULL REFERENCES Staff(person_id),
    CHECK (start_time < end_time),
    CHECK (min_age IS NULL OR max_age IS NULL OR min_age <= max_age),
    UNIQUE (room_id, event_date, start_time)
);

CREATE TABLE EventRegistration (
    event_id        INTEGER NOT NULL REFERENCES Event(event_id),
    member_id       INTEGER NOT NULL REFERENCES Member(person_id),
    date_registered DATE,
    attended         INTEGER NOT NULL DEFAULT 0 CHECK (attended IN (0, 1)),
    PRIMARY KEY (event_id, member_id)
);

-- Reference services and acquisitions.
CREATE TABLE HelpRequest (
    request_id    INTEGER PRIMARY KEY,
    member_id     INTEGER NOT NULL REFERENCES Member(person_id),
    staff_id      INTEGER REFERENCES Staff(person_id),
    question      TEXT NOT NULL,
    date_asked    DATE NOT NULL,
    response      TEXT,
    date_answered DATE,
    status        TEXT CHECK (status IN ('Open', 'Answered', 'Closed'))
);

CREATE TABLE WishlistItem (
    wish_id        INTEGER PRIMARY KEY,
    title          TEXT NOT NULL,
    creator        TEXT,
    item_type      TEXT CHECK (item_type IN ('Book', 'Serial', 'Record')),
    isbn_issn      TEXT UNIQUE,
    est_cost       REAL CHECK (est_cost IS NULL OR est_cost >= 0),
    priority       TEXT CHECK (priority IN ('High', 'Medium', 'Low')),
    date_requested DATE,
    status         TEXT CHECK (status IN ('Requested', 'Approved', 'Acquired', 'Rejected')),
    acquired_item  INTEGER REFERENCES Item(item_id)
);

-- Volunteers are Staff rows with a null salary.
CREATE TRIGGER staff_volunteer_salary
BEFORE INSERT ON Staff
WHEN NEW.role = 'Volunteer' AND NEW.salary IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'volunteers must have NULL salary');
END;

CREATE TRIGGER staff_volunteer_salary_update
BEFORE UPDATE OF role, salary ON Staff
WHEN NEW.role = 'Volunteer' AND NEW.salary IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'volunteers must have NULL salary');
END;

-- A loan-linked fine must belong to the same member as its loan.
CREATE TRIGGER fine_member_matches_loan
BEFORE INSERT ON Fine
WHEN NEW.loan_id IS NOT NULL
 AND NOT EXISTS (
     SELECT 1 FROM Loan
     WHERE Loan.loan_id = NEW.loan_id
       AND Loan.member_id = NEW.member_id
 )
BEGIN
    SELECT RAISE(ABORT, 'fine member does not match loan member');
END;

CREATE TRIGGER fine_member_matches_loan_update
BEFORE UPDATE OF loan_id, member_id ON Fine
WHEN NEW.loan_id IS NOT NULL
 AND NOT EXISTS (
     SELECT 1 FROM Loan
     WHERE Loan.loan_id = NEW.loan_id
       AND Loan.member_id = NEW.member_id
 )
BEGIN
    SELECT RAISE(ABORT, 'fine member does not match loan member');
END;

-- Borrowing eligibility and physical-copy exclusivity.
CREATE TRIGGER block_borrow_if_owing
BEFORE INSERT ON Loan
WHEN COALESCE((
    SELECT SUM(amount - amount_paid)
    FROM Fine
    WHERE member_id = NEW.member_id
), 0) > 10.00
BEGIN
    SELECT RAISE(ABORT, 'member owes more than $10.00');
END;

CREATE TRIGGER block_borrow_if_on_loan
BEFORE INSERT ON Loan
WHEN EXISTS (
    SELECT 1 FROM Loan
    WHERE copy_id = NEW.copy_id
      AND return_date IS NULL
)
BEGIN
    SELECT RAISE(ABORT, 'copy is already on loan');
END;

CREATE TRIGGER block_borrow_if_card_inactive
BEFORE INSERT ON Loan
WHEN EXISTS (
    SELECT 1 FROM Member
    WHERE person_id = NEW.member_id
      AND card_status <> 'Active'
)
BEGIN
    SELECT RAISE(ABORT, 'member card is not active');
END;

-- A renewal must increase both the due date and renewal counter.
CREATE TRIGGER validate_loan_renewal
BEFORE UPDATE OF due_date, renewal_count ON Loan
WHEN NEW.renewal_count > OLD.renewal_count
 AND NEW.due_date <= OLD.due_date
BEGIN
    SELECT RAISE(ABORT, 'renewal must extend the due date');
END;

CREATE TRIGGER validate_loan_renewal_count
BEFORE UPDATE OF due_date, renewal_count ON Loan
WHEN NEW.renewal_count < OLD.renewal_count
BEGIN
    SELECT RAISE(ABORT, 'renewal count cannot decrease');
END;

-- Late returns create one frozen overdue fine at 25 cents per day, capped at $5.
CREATE TRIGGER auto_fine_on_late_return
AFTER UPDATE OF return_date ON Loan
WHEN OLD.return_date IS NULL
 AND NEW.return_date IS NOT NULL
 AND NEW.return_date > NEW.due_date
BEGIN
    INSERT INTO Fine (
        member_id, loan_id, reason, amount, date_assessed, amount_paid
    )
    VALUES (
        NEW.member_id,
        NEW.loan_id,
        'Overdue',
        MIN(0.25 * CAST(julianday(NEW.return_date) - julianday(NEW.due_date) AS INTEGER), 5.00),
        NEW.return_date,
        0
    );
END;

-- Event registration must satisfy the event's age range and registration cap.
CREATE TRIGGER check_event_age
BEFORE INSERT ON EventRegistration
WHEN EXISTS (
    SELECT 1
    FROM Event e
    JOIN Member m ON m.person_id = NEW.member_id
    JOIN Person p ON p.person_id = m.person_id
    WHERE e.event_id = NEW.event_id
      AND (
          (e.min_age IS NOT NULL AND (
              p.date_of_birth IS NULL OR
              CAST(strftime('%Y', e.event_date) AS INTEGER)
              - CAST(strftime('%Y', p.date_of_birth) AS INTEGER)
              - (strftime('%m-%d', e.event_date) < strftime('%m-%d', p.date_of_birth)) < e.min_age
          ))
          OR
          (e.max_age IS NOT NULL AND (
              p.date_of_birth IS NULL OR
              CAST(strftime('%Y', e.event_date) AS INTEGER)
              - CAST(strftime('%Y', p.date_of_birth) AS INTEGER)
              - (strftime('%m-%d', e.event_date) < strftime('%m-%d', p.date_of_birth)) > e.max_age
          ))
      )
)
BEGIN
    SELECT RAISE(ABORT, 'member is outside event age range');
END;

CREATE TRIGGER check_event_full
BEFORE INSERT ON EventRegistration
WHEN EXISTS (
    SELECT 1
    FROM Event e
    WHERE e.event_id = NEW.event_id
      AND e.max_attendees IS NOT NULL
      AND (
          SELECT COUNT(*) FROM EventRegistration er
          WHERE er.event_id = e.event_id
      ) >= e.max_attendees
)
BEGIN
    SELECT RAISE(ABORT, 'event registration is full');
END;

COMMIT;

