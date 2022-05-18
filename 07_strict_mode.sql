USE JsonImport;
GO


DECLARE @json NVARCHAR(MAX) = N'[{"id":1,"sku":"A"},{"id":2,"skuu":"B"}]';

-- lax (default): the typo in the second element yields NULL
SELECT * FROM OPENJSON(@json) WITH (id INT '$.id', sku NVARCHAR(10) '$.sku');

-- strict: the same query fails with error 13608 on the misspelled key.
-- Paths are also CASE SENSITIVE: '$.SKU' would not match "sku".
BEGIN TRY
    SELECT * FROM OPENJSON(@json) WITH (id INT 'strict $.id', sku NVARCHAR(10) 'strict $.sku');
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS err, ERROR_MESSAGE() AS msg;
END CATCH
