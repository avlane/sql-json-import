# sql-json-import

Importing JSON into SQL Server with T-SQL only: staging raw documents, validating them, shredding with `OPENJSON`, upserting into relational tables and writing JSON back out with `FOR JSON`.

Needs SQL Server 2016 or later for the JSON functions; developed on SQL Server 2019. (`JSON_OBJECT`, `JSON_ARRAY` and the `json` type are newer than that and are not used.)

## Order to run

| Script | Topic |
|---|---|
| `00_setup.sql` | database and `stg.JsonDoc` |
| `01_load_file.sql` | `stg.usp_LoadJsonFile`, OPENROWSET BULK |
| `02_validate.sql` | ISJSON |
| `03_shred_flat.sql`, `04_shred_nested.sql` | OPENJSON with schema, CROSS/OUTER APPLY |
| `05_value_and_query.sql` | JSON_VALUE vs JSON_QUERY |
| `06_conversions.sql`, `07_strict_mode.sql` | dates, numbers, strict paths |
| `08_products.sql`, `09_import_log.sql` | upsert procedure and import log |
| `10_orders.sql` | customers, orders, lines from nested JSON |
| `11_rejects.sql` | reject table for bad elements |
| `12_json_modify.sql` | patching documents |
| `13_for_json.sql` | writing JSON out |
| `14_index_json.sql` | computed column index |
| `15_scalar_arrays.sql` | tags arrays |
| `16_ndjson.sql` | line-delimited feeds |

Load `samples/products.json` and `samples/orders.json` with `usp_LoadJsonFile`, then `EXEC dbo.usp_ImportProducts @DocId = 1;`.

## Notes

- The file path is read by the SQL Server service, from the server's disk, and `OPENROWSET(BULK ...)` needs a literal path, hence the dynamic SQL.
- `SINGLE_CLOB` reads ANSI. Save files as UTF-16 and pass `@Unicode = 1`, or use a database with a UTF-8 collation (SQL Server 2019+).
- JSON paths are case sensitive. Use `strict` when a missing property should fail.
- `COMMIT` of the import happens once per document, so one bad document never leaves half a file.

## Sample output

After importing `samples/products.json`:

```
ProductId  Sku     Name           Price  IsActive  UpdatedAt
---------  ------  -------------  -----  --------  -------------------------
1          BK-100  Notebook A5    4.50   1         2022-03-01 09:30:00 +00:00
2          BK-200  Notebook A4    6.25   1         2022-03-01 09:30:00 +00:00
3          PN-010  Gel pen black  1.20   1         2022-03-04 16:00:00 +00:00
4          PN-011  Gel pen blue   1.20   0         2022-03-04 16:00:00 +00:00
5          DS-900  Desk lamp      29.99  1         2022-03-10 08:15:00 +00:00
```

`imp.ImportLog` for that run:

```
BatchId  DocId  Target       RowsRead  RowsInserted  RowsUpdated  Status
-------  -----  -----------  --------  ------------  -----------  ------
1        1      dbo.Products  5         5             0            ok
```
