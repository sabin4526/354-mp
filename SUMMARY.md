# CMPT 354 Library Database Project - Final Sanity-Check Handoff

## Current status

Steps 4, 5, and 6 are implemented locally.

- `sql/schema.sql` creates the final 16-table SQLite schema and 9 required integrity triggers.
- `sql/seed.sql` provides at least 10 realistic rows for every table.
- `library.db` was created from the schema and loaded with the seed data.
- `src/app.py` is a simple terminal menu application with all 8 required operations.
- `src/database.py` is intentionally minimal: it opens `library.db`, enables foreign keys, and returns named rows.
- `tests/run_tests.py` copies `library.db` to `tests/test_library.db`, runs 16 focused checks, then deletes the copy.

## Required application operations

1. Find an item
2. Borrow an item
3. Return a borrowed item
4. Donate an item
5. Find an event
6. Register for an event
7. Volunteer for the library
8. Ask a librarian for help

## Important design rules retained

- 16 final relations, including the `SerialSeries` BCNF decomposition.
- `Serial` does not contain `publisher`.
- Availability is derived from `Loan.return_date`; there is no availability or quantity column.
- `Fine.member_id` remains, with the required `fine_member_matches_loan` trigger.
- Volunteers are `Staff` rows with `role = 'Volunteer'` and `salary = NULL`.
- No Volunteer, Department, Donation, or OnlineAccess table was added.
- Books and serials receive a 3-week default loan period; records receive 1 week.
- A late return creates the automatic overdue fine. Returns over 30 days late also receive a flat $30 lost-item fine.

## Trigger set

The schema/database currently contain these 9 triggers:

- `auto_fine_on_late_return`
- `block_borrow_if_card_inactive`
- `block_borrow_if_on_loan`
- `block_borrow_if_owing`
- `check_event_age`
- `check_event_full`
- `fine_member_matches_loan`
- `staff_volunteer_salary`
- `staff_volunteer_salary_update`

The two unused renewal triggers and unused Fine-update trigger were deliberately removed to keep the mini-project simple.

## Verification already completed

- Schema source and `library.db` match: 16 tables and 9 triggers.
- Every table has at least 10 rows.
- `PRAGMA foreign_key_check` returns no problems.
- `src/app.py` and `src/database.py` compile.
- All 16 tests in `tests/run_tests.py` pass.
- The test runner uses only a temporary database copy and does not modify the submission database.

## Useful commands

Run from the project root:

```powershell
python src/app.py
python tests/run_tests.py
```

## Final sanity-check tasks for the next chat

1. Compare the assignment instructions, `HANDOFF.md`, submitted ER/BCNF PDFs, schema, seed data, app, and tests for any remaining mismatch.
2. Re-run the app compile check and the test runner.
3. Confirm `library.db` has 16 tables, 9 triggers, and no foreign-key violations.
4. Confirm the final zip includes the needed files.
5. Verify that the combined previous-work PDF is available as `mp.pdf`.

## Submission package

The final zip should include:

```text
mp.pdf                  <- confirm/create from completed Steps 1-3 work
library.db
src/app.py
src/database.py
sql/schema.sql
sql/seed.sql
tests/run_tests.py
```

`mp.pdf` is not currently visible in this workspace. The available prior-step files are `Step1.pdf`, `mp_step2_ER_final.pdf`, and `Step3.pdf`; confirm that the required combined `mp.pdf` is available before submitting.

