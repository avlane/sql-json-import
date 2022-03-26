# sql-json-import

Importing JSON into SQL Server with T-SQL only: staging raw documents, validating them, shredding with `OPENJSON`, upserting into relational tables and writing JSON back out with `FOR JSON`.

Needs SQL Server 2016 or later for the JSON functions; developed on SQL Server 2019.

## Files

- `00_setup.sql` creates the `JsonImport` database and the staging table.
- `samples/` has the JSON files used in the examples.
