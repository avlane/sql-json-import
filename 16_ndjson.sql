USE JsonImport;
GO


-- One JSON object per line (NDJSON) avoids holding a huge array in a single NVARCHAR(MAX).
-- Each line becomes a row, so OPENJSON runs over small values.
CREATE TABLE stg.JsonLine
(
    LineId     BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_JsonLine PRIMARY KEY,
    SourceFile NVARCHAR(400) NOT NULL,
    Body       NVARCHAR(MAX) NOT NULL
);
GO

CREATE OR ALTER PROCEDURE stg.usp_LoadNdjson
    @Path NVARCHAR(400)
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #raw (Body NVARCHAR(MAX) NULL);

    -- BULK INSERT into a one-column table with a row terminator of line feed
    DECLARE @sql NVARCHAR(MAX) =
        N'BULK INSERT #raw FROM ' + QUOTENAME(@Path, '''') + N' WITH (ROWTERMINATOR = ''0x0a'', FIELDTERMINATOR = ''0x0b'', CODEPAGE = ''65001'', TABLOCK);';
    EXEC (@sql);

    -- Files saved with CRLF leave a trailing CHAR(13) on every line; ISJSON accepts it but the
    -- stored text then differs from what was sent. Strip it.
    INSERT INTO stg.JsonLine (SourceFile, Body)
    SELECT @Path, REPLACE(Body, CHAR(13), N'') FROM #raw WHERE Body IS NOT NULL AND LEN(REPLACE(Body, CHAR(13), N'')) > 0;

    RETURN @@ROWCOUNT;
END
GO

-- Shred the lines
SELECT l.SourceFile, e.event, e.[user], e.at
FROM stg.JsonLine AS l
CROSS APPLY OPENJSON(l.Body) WITH (event NVARCHAR(20) '$.event', [user] NVARCHAR(50) '$.user', at NVARCHAR(30) '$.at') AS e
WHERE ISJSON(l.Body) = 1;
