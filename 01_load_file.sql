USE JsonImport;
GO


-- OPENROWSET(BULK ...) only accepts a literal path, so the statement is built dynamically.
-- The file is read by the SQL Server service account, from the SERVER's file system.
-- SINGLE_CLOB reads the bytes as ANSI. For UTF-16 files use SINGLE_NCLOB (@Unicode = 1).
CREATE OR ALTER PROCEDURE stg.usp_LoadJsonFile
    @Path    NVARCHAR(400),
    @Unicode BIT = 0,
    @DocId   INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX) =
        N'INSERT INTO stg.JsonDoc (SourceFile, Body) '
        + N'SELECT @path, BulkColumn FROM OPENROWSET(BULK ' + QUOTENAME(@Path, '''') + N', '
        + CASE WHEN @Unicode = 1 THEN N'SINGLE_NCLOB' ELSE N'SINGLE_CLOB' END + N') AS f;';

    EXEC sys.sp_executesql @sql, N'@path NVARCHAR(400)', @path = @Path;
    SET @DocId = SCOPE_IDENTITY();
END
GO

-- DECLARE @id INT;
-- EXEC stg.usp_LoadJsonFile @Path = N'C:\data\json\products.json', @DocId = @id OUTPUT;
-- SELECT DocId, SourceFile, LEN(Body) AS chars FROM stg.JsonDoc WHERE DocId = @id;
