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

    INSERT INTO stg.JsonLine (SourceFile, Body)
    SELECT @Path, Body FROM #raw WHERE Body IS NOT NULL AND LEN(Body) > 0;

    RETURN @@ROWCOUNT;
END
GO
