USE JsonImport;
GO


-- JSON_VALUE on a staged document is a scan every time. Persist the lookup key as a computed
-- column and index it.
ALTER TABLE stg.JsonDoc
    ADD FirstId AS CAST(JSON_VALUE(Body, '$[0].id') AS INT);
GO

CREATE NONCLUSTERED INDEX IX_JsonDoc_FirstId ON stg.JsonDoc (FirstId);
GO

-- The optimizer only uses the index when the query repeats the same expression or filters on the column:
SELECT DocId FROM stg.JsonDoc WHERE FirstId = 1;
SELECT DocId FROM stg.JsonDoc WHERE CAST(JSON_VALUE(Body, '$[0].id') AS INT) = 1;
