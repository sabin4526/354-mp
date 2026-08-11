# Tests

`run_tests.py` verifies the seeded SQLite database and key library workflows. It checks the 16-table structure, seed-data minimums, foreign-key integrity, derived availability, borrowing restrictions, late fines, event registration rules, volunteer records, help-request queuing, and donation/wishlist updates.

Run it from the repository root:

```powershell
python tests/run_tests.py
```

The runner first copies `library.db` to `tests/test_library.db`, performs all inserts and updates against that disposable copy, reports each result, and deletes the copy afterward. The submission database is never modified.
