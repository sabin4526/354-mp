# CMPT-354 Mini Project — Handoff Brief for Steps 4, 5 and 6

**Team:** Nguyen Thanh Vinh (301634356), Sabin Adhikari (301623104)
**Domain:** Public library system, modelled on Vancouver Public Library
**Status:** Steps 1, 2 and 3 are complete and submitted as `mp.pdf`.
This document covers everything you need to build Steps 4–6.

> **How to use this file with an LLM:** paste this whole document in first,
> then attach `mp_step2_ER_final.pdf` for the diagrams. Everything below is
> already decided — please do not redesign it. Section 8 lists the specific
> things that must not change and why.

---

## 1. What is left to do

| Step | Points | Deliverable |
|---|---|---|
| 4. SQL schema | 5 | `library.db` — tables, constraints, triggers, in SQLite |
| 5. Populate tables | 3 | ≥10 realistic rows in **every** table |
| 6. Application | 15 | Python + `sqlite3`, 8 user operations |

Submit as a zip: `mp.pdf` (done), `library.db`, and the Python files.

---

## 2. Design summary

The schema has **16 relations**. Structure:

- **Item** is a supertype specialised by content type into **Book**, **Serial**
  and **Record** (an isa hierarchy). Each subtype shares `item_id` with `Item`.
- **Copy** is a separate strong entity: one row per physical object. An item
  with 5 copies has 1 `Item` row and 5 `Copy` rows. **Availability is never
  stored** — it is derived by checking for a `Loan` with `return_date IS NULL`.
- **SerialSeries** exists because Step 3 found a BCNF violation (see §7).
- **Person** is specialised into **Member** and **Staff**. The specialisation is
  *overlapping*: a staff member may also hold a library card, in which case they
  have a row in all three tables.
- **Volunteers are Staff** with `role = 'Volunteer'` and `salary` NULL. There is
  no Volunteer table — this was a deliberate scope decision.
- **Loan** is an entity, not a link table, because the same member may borrow the
  same copy on separate occasions.
- **Fine** is separate from Loan because one loan can produce several fines, and
  some fines (damage, loss) have no loan at all.

**Out of scope, declared in Step 1:** online/digital items (handled by a
separate consortium system), library finances beyond fines, departments,
and donor records.

---

## 3. Full schema for Step 4

Types are SQLite. `PRAGMA foreign_keys = ON;` is required — SQLite does not
enforce foreign keys by default and the whole design depends on them.

### Items

```sql
Item(
  item_id        INTEGER PRIMARY KEY,
  title          TEXT NOT NULL,
  pub_year       INTEGER,
  subject        TEXT,
  language       TEXT,
  shelf_location TEXT              -- call number; per title, not per copy
)

Book(
  item_id   INTEGER PRIMARY KEY REFERENCES Item(item_id),
  isbn      TEXT UNIQUE NOT NULL,  -- candidate key
  author    TEXT NOT NULL,
  publisher TEXT,
  pages     INTEGER
)

SerialSeries(
  issn      TEXT PRIMARY KEY,      -- one row per magazine/journal title
  publisher TEXT
)

Serial(
  item_id  INTEGER PRIMARY KEY REFERENCES Item(item_id),
  issn     TEXT NOT NULL REFERENCES SerialSeries(issn),
  volume   INTEGER,
  issue_no INTEGER,
  UNIQUE (issn, volume, issue_no)  -- second candidate key
)

Record(
  item_id     INTEGER PRIMARY KEY REFERENCES Item(item_id),
  artist      TEXT,
  label       TEXT,
  runtime_min INTEGER,
  genre       TEXT
)

Copy(
  copy_id       INTEGER PRIMARY KEY,
  item_id       INTEGER NOT NULL REFERENCES Item(item_id),
  barcode       TEXT UNIQUE NOT NULL,   -- candidate key
  condition     TEXT CHECK (condition IN
                  ('New','Good','Fair','Poor','Damaged')),
  acquired_date DATE
)
```

### People

```sql
Person(
  person_id     INTEGER PRIMARY KEY,
  first_name    TEXT NOT NULL,
  last_name     TEXT NOT NULL,
  email         TEXT UNIQUE,            -- candidate key
  phone         TEXT,
  date_of_birth DATE,
  address       TEXT
)

Member(
  person_id    INTEGER PRIMARY KEY REFERENCES Person(person_id),
  card_number  TEXT UNIQUE NOT NULL,    -- candidate key
  member_since DATE,
  card_status  TEXT CHECK (card_status IN ('Active','Suspended','Expired'))
)

Staff(
  person_id     INTEGER PRIMARY KEY REFERENCES Person(person_id),
  role          TEXT NOT NULL,          -- 'Librarian','Assistant','Manager','Volunteer'
  hire_date     DATE,
  salary        REAL,                   -- NULL for volunteers
  supervisor_id INTEGER REFERENCES Staff(person_id)   -- NULL at top of chain
)
```

### Circulation

```sql
Loan(
  loan_id       INTEGER PRIMARY KEY,
  copy_id       INTEGER NOT NULL REFERENCES Copy(copy_id),
  member_id     INTEGER NOT NULL REFERENCES Member(person_id),
  borrow_date   DATE NOT NULL,
  due_date      DATE NOT NULL,
  renewal_count INTEGER NOT NULL DEFAULT 0,
  return_date   DATE,                   -- NULL means still on loan
  CHECK (due_date > borrow_date),
  CHECK (return_date IS NULL OR return_date >= borrow_date)
)

Fine(
  fine_id       INTEGER PRIMARY KEY,
  member_id     INTEGER NOT NULL REFERENCES Member(person_id),
  loan_id       INTEGER REFERENCES Loan(loan_id),   -- NULL for damage/loss
  reason        TEXT CHECK (reason IN
                  ('Overdue','Damaged','Lost','Card replacement')),
  amount        REAL NOT NULL CHECK (amount >= 0),
  date_assessed DATE NOT NULL,
  amount_paid   REAL NOT NULL DEFAULT 0 CHECK (amount_paid >= 0),
  date_paid     DATE,
  CHECK (amount_paid <= amount)
)
```

### Events

```sql
Room(
  room_id   INTEGER PRIMARY KEY,
  name      TEXT UNIQUE NOT NULL,       -- candidate key
  room_type TEXT,                       -- 'Meeting Room','Auditorium','Gallery',...
  floor     INTEGER,
  capacity  INTEGER CHECK (capacity > 0)   -- physical seating limit
)

Event(
  event_id      INTEGER PRIMARY KEY,
  title         TEXT NOT NULL,
  description   TEXT,
  event_type    TEXT,                   -- 'Book Club','Art Show','Film Screening',...
  event_date    DATE NOT NULL,
  start_time    TEXT NOT NULL,          -- 'HH:MM'
  end_time      TEXT NOT NULL,
  min_age       INTEGER,                -- NULL = no lower bound
  max_age       INTEGER,                -- NULL = no upper bound
  max_attendees INTEGER,                -- registration cap, NOT the room capacity
  room_id       INTEGER NOT NULL REFERENCES Room(room_id),
  organizer_id  INTEGER NOT NULL REFERENCES Staff(person_id),
  CHECK (start_time < end_time),
  CHECK (min_age IS NULL OR max_age IS NULL OR min_age <= max_age),
  UNIQUE (room_id, event_date, start_time)   -- second candidate key: no double-booking
)

EventRegistration(
  event_id        INTEGER REFERENCES Event(event_id),
  member_id       INTEGER REFERENCES Member(person_id),
  date_registered DATE,
  attended        INTEGER DEFAULT 0 CHECK (attended IN (0,1)),
  PRIMARY KEY (event_id, member_id)
)
```

### Services and acquisitions

```sql
HelpRequest(
  request_id    INTEGER PRIMARY KEY,
  member_id     INTEGER NOT NULL REFERENCES Member(person_id),
  staff_id      INTEGER REFERENCES Staff(person_id),   -- NULL until assigned
  question      TEXT NOT NULL,
  date_asked    DATE NOT NULL,
  response      TEXT,
  date_answered DATE,
  status        TEXT CHECK (status IN ('Open','Answered','Closed'))
)

WishlistItem(
  wish_id        INTEGER PRIMARY KEY,
  title          TEXT NOT NULL,
  creator        TEXT,
  item_type      TEXT CHECK (item_type IN ('Book','Serial','Record')),
  isbn_issn      TEXT UNIQUE,           -- candidate key; NULL if not yet confirmed
  est_cost       REAL,
  priority       TEXT CHECK (priority IN ('High','Medium','Low')),
  date_requested DATE,
  status         TEXT CHECK (status IN
                   ('Requested','Approved','Acquired','Rejected')),
  acquired_item  INTEGER REFERENCES Item(item_id)      -- NULL until acquired
)
```

---

## 4. Business rules to enforce (from Step 1)

These were declared in the specification, so the marker will expect to see them
enforced somewhere — as CHECK constraints, triggers, or application logic.

1. **Loan period varies by material type.** 3 weeks for books and serials,
   1 week for records and high-demand items. Staff may override.
2. **Renewals** extend `due_date` and increment `renewal_count`.
3. **Overdue fines** accrue at **$0.25 per item per day**, capped at **$5.00 per
   item**. The amount is frozen in `Fine.amount` at the moment it is assessed.
4. Items more than **30 days overdue** are marked lost and the member is billed
   replacement cost.
5. A member owing more than **$10.00** may not borrow.
6. Fines may also be assessed for damage or loss with no overdue loan.
7. **Partial payment** is allowed (`amount_paid < amount`).
8. Events have an age range; registration is capped by `max_attendees`. The room
   has its own separate physical `capacity`.
9. Members must be registered before borrowing or attending events.
10. The wishlist is **staff-curated**, one row per title.
11. Help requests are **queued unassigned** until a librarian picks them up.
12. Salary is set per individual, not by role band.

### Triggers worth writing for Step 4

The assignment explicitly asks for triggers. These are the ones that matter:

| Trigger | Rule |
|---|---|
| **`fine_member_matches_loan`** | **Required.** When `Fine.loan_id` is not NULL, `Fine.member_id` must equal the `Loan`'s `member_id`. See §7 — the Step 3 argument depends on this existing. |
| `block_borrow_if_owing` | Reject an insert into `Loan` if the member's unpaid fines exceed $10.00 |
| `block_borrow_if_on_loan` | Reject if the copy already has a `Loan` with `return_date IS NULL` |
| `block_borrow_if_card_inactive` | Reject if `Member.card_status <> 'Active'` |
| `check_event_age` | Reject an `EventRegistration` if the member's age falls outside `[min_age, max_age]` |
| `check_event_full` | Reject if registrations for the event already equal `max_attendees` |
| `auto_fine_on_late_return` | On `UPDATE Loan SET return_date`, if late, insert an `Overdue` fine of `MIN(0.25 * days_late, 5.00)` |

SQLite has no `RAISE` outside triggers, so use
`SELECT RAISE(ABORT, 'message')` inside a `BEFORE INSERT ... WHEN ...` trigger.

---

## 5. Step 5 — populating tables

≥10 rows per table, realistic. Notes:

- **Order matters** because of foreign keys. Insert in this order:
  `Person → Member, Staff → Item → Book/SerialSeries/Serial/Record → Copy →
  Loan → Fine → Room → Event → EventRegistration → HelpRequest → WishlistItem`
- `Staff.supervisor_id` is self-referential: insert the manager first with
  `supervisor_id` NULL, then everyone else.
- Make some loans **open** (`return_date` NULL) and some **returned**, so the
  availability query in Step 6 has something to find.
- Make at least one fine with `loan_id` NULL (damage or loss) — this exercises
  the design decision defended in Step 3.
- Give at least one `Item` several `Copy` rows, so "3 of 5 copies available"
  works.
- Real VPL branches and plausible Vancouver-area names make this look researched.

---

## 6. Step 6 — the eight required operations

| # | Operation | Tables touched |
|---|---|---|
| 1 | **Find an item** | `SELECT` from `Item` joined to `Book`/`Serial`/`Record`; count available copies via `Copy LEFT JOIN Loan` where `return_date IS NULL` |
| 2 | **Borrow an item** | `INSERT INTO Loan`; compute `due_date` from material type; triggers enforce the eligibility rules |
| 3 | **Return an item** | `UPDATE Loan SET return_date = ...`; if late, insert an `Overdue` fine |
| 4 | **Donate an item** | `INSERT INTO Item` + the matching subtype row + `INSERT INTO Copy`. If the title matches a `WishlistItem`, set its `status='Acquired'` and `acquired_item` |
| 5 | **Find an event** | `SELECT` from `Event JOIN Room`; optionally filter by the member's age against `min_age`/`max_age` |
| 6 | **Register for an event** | `INSERT INTO EventRegistration`; triggers check age and capacity |
| 7 | **Volunteer** | `INSERT INTO Person`, then `INSERT INTO Staff` with `role='Volunteer'`, `salary` NULL |
| 8 | **Ask a librarian** | `INSERT INTO HelpRequest` with `staff_id` NULL and `status='Open'` |

### Availability query — the one to get right

```sql
SELECT c.copy_id, c.barcode
FROM   Copy c
WHERE  c.item_id = ?
  AND  NOT EXISTS (
         SELECT 1 FROM Loan l
         WHERE l.copy_id = c.copy_id
           AND l.return_date IS NULL
       );
```

Availability is **derived, never stored**. Do not add an `is_available` column —
that would reintroduce the update anomaly the design avoids.

### Application notes

- Use parameterised queries (`?` placeholders), never string formatting.
- Wrap each operation in a transaction so a failed trigger rolls the whole thing
  back.
- Operations 2, 3 and 4 are multi-statement — they must be atomic.
- A simple text menu loop is enough; the marks are for correct database work,
  not the interface.

---

## 7. What Step 3 concluded (do not undo these)

Step 3 analysed every relation for functional dependencies and BCNF. Two
outcomes constrain the implementation:

### The Serial decomposition

The original design had `Serial(item_id, issn, volume, issue_no, publisher)`.
An ISSN identifies a *serial series*, not one issue, so many issues share one
ISSN and `issn → publisher` was a **bad FD** — `issn` is not a superkey there.

It was decomposed into `SerialSeries(issn, publisher)` and
`Serial(item_id, issn, volume, issue_no)`.

**Do not put `publisher` back into `Serial`.** That would undo the only
decomposition in the writeup and contradict the submitted `mp.pdf`.

### The Fine.member_id decision

`Fine` keeps `member_id` even though it is derivable from `loan_id` for
loan-linked fines. The Step 3 argument is that the dependency
`loan_id → member_id` is *not total*: `loan_id` is NULL on damage and loss
fines, so it is not a BCNF violation. The writeup states explicitly that
**consistency is enforced by a trigger instead**.

**That trigger must exist in Step 4**, or the Step 3 justification is unsupported.

### Other things Step 3 depends on

- `shelf_location` stays on **`Item`**, not `Copy`. All copies of a title are
  shelved together; putting it on `Copy` would create a bad FD.
- `due_date` stays on `Loan` because the period varies by material type and
  renewals extend it. If you hard-code a single fixed loan period for
  everything, `borrow_date → due_date` becomes a real bad FD.
- `Event.max_attendees` and `Room.capacity` are **different things** and must
  stay in different tables.
- `WishlistItem.isbn_issn` must be `UNIQUE` — Step 3 claims it as a candidate key.

---

## 8. Summary of things that must not change

1. No `is_available` / `quantity` column anywhere — availability is derived.
2. `publisher` stays out of `Serial`.
3. `shelf_location` stays on `Item`.
4. No Volunteer, Department, Donation or OnlineAccess tables — all cut
   deliberately and declared as scope in Step 1.
5. `Magazine` and `Journal` are merged into `Serial`. Do not split them.
6. `Fine.member_id` stays, with the trigger.
7. `UNIQUE` constraints on `Book.isbn`, `Copy.barcode`, `Member.card_number`,
   `Person.email`, `Room.name`, `WishlistItem.isbn_issn`, and
   `Event(room_id, event_date, start_time)` — each is a candidate key claimed in
   Step 3.

---

## 9. Open items to decide

Three small things were left to the implementation:

1. **How "high-demand" is flagged.** Rule 1 gives records and high-demand items
   a 1-week loan. Either add a boolean column to `Item`, or simply derive the
   period from whether the item has a `Record` subtype row. The second is
   simpler and needs no schema change.
2. **Replacement cost for lost items.** Rule 4 bills replacement cost but there
   is no `replacement_cost` column. Either add one to `Item`, or use a flat
   default (e.g. $30) in the application.
3. **Where the fine rate lives.** $0.25/day and the $5.00 cap can be constants
   in the Python code or a small `Policy` table. Constants are fine and simpler
   to defend.

None of these affect Step 3, so decide them however is easiest.

---

## 10. Reference files

- `mp_step2_ER_final.pdf` — E/R diagrams, one page per cluster, plus a notation
  legend and the pre-decomposition schema
- `mp-step3.pdf` — the full FD and BCNF analysis, including assumptions A1–A12
- Course notation follows Garcia-Molina / Ullman / Widom, *Database Systems: The
  Complete Book*, Ch. 4, as used in slide deck `03354ERM`
