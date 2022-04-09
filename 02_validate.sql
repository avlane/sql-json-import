USE JsonImport;
GO


-- ISJSON returns 1 for valid JSON, 0 for invalid, NULL for NULL input.
SELECT DocId, SourceFile, ISJSON(Body) AS is_valid
FROM stg.JsonDoc;

-- Typical guard at the top of an import procedure:
-- IF ISJSON(@json) <> 1 THROW 52000, N'Not valid JSON.', 1;

-- ISJSON also returns 1 for a bare object or array but 0 for a bare scalar:
SELECT ISJSON(N'{"a":1}') AS obj,
       ISJSON(N'[1,2]')   AS arr,
       ISJSON(N'42')      AS scalar_value,
       ISJSON(N'{a:1}')   AS bad_quotes;
