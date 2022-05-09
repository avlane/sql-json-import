USE JsonImport;
GO


-- JSON has no date type. Dates arrive as strings; numbers sometimes arrive as strings too.
DECLARE @json NVARCHAR(MAX) = N'[{"t":"2022-03-01T09:30:00Z","n":"4.50"},{"t":"2022-03-04T16:00:00+02:00","n":"1,20"},{"t":"not a date","n":"7"}]';

SELECT t                                             AS raw_t,
       TRY_CONVERT(DATETIMEOFFSET(0), t)             AS as_offset,
       CAST(TRY_CONVERT(DATETIMEOFFSET(0), t) AT TIME ZONE 'UTC' AS DATETIME2(0)) AS as_utc,
       n                                             AS raw_n,
       TRY_CONVERT(DECIMAL(10,2), n)                 AS as_decimal
FROM OPENJSON(@json) WITH (t NVARCHAR(40) '$.t', n NVARCHAR(40) '$.n');

-- TRY_CONVERT returns NULL instead of failing the whole statement.
-- '1,20' (decimal comma) converts to NULL here; fix the source or REPLACE before converting.
