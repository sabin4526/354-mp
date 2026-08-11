# CMPT 354 Library Database Project

This project models a public-library system in SQLite. The database separates library titles (`Item`) from their physical copies (`Copy`) and specialises items into books, serials, and records. It also models people as members and staff, circulation (`Loan` and `Fine`), rooms and events, help requests, and staff-curated wishlist items. A serial-series relation removes the publisher dependency from individual serial issues.

Availability is derived from open loans rather than stored. The schema includes foreign keys, checks, and triggers for active cards, outstanding balances, duplicate loans, late-return fines, event age/capacity rules, matching fine/loan members, and volunteer salaries.

The seeded `library.db` powers a terminal application with eight actions: search items, borrow and return copies, catalogue donations, find and register for events, register volunteers, and queue librarian help requests. Borrowing assigns a three-week loan period to books and serials and one week to records; returns create applicable fines.

## Run

From the repository root, use Python 3:

```powershell
python src/app.py
python tests/run_tests.py
```

`sql/schema.sql` defines the database and `sql/seed.sql` provides the sample data. The included `library.db` is already built and seeded.
