USE JsonImport;
GO


CREATE TABLE dbo.Products
(
    ProductId INT           NOT NULL CONSTRAINT PK_Product PRIMARY KEY,
    Sku       NVARCHAR(30)  NOT NULL CONSTRAINT UQ_Product_Sku UNIQUE,
    Name      NVARCHAR(100) NOT NULL,
    Price     DECIMAL(10,2) NOT NULL,
    IsActive  BIT           NOT NULL,
    Tags      NVARCHAR(MAX) NULL,
    UpdatedAt DATETIMEOFFSET(0) NOT NULL
);
GO

CREATE OR ALTER PROCEDURE dbo.usp_ImportProducts
    @DocId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @json NVARCHAR(MAX) = (SELECT Body FROM stg.JsonDoc WHERE DocId = @DocId);
    IF @json IS NULL OR ISJSON(@json) <> 1
        THROW 52000, N'Document missing or not valid JSON.', 1;

    SELECT p.id, p.sku, p.name, p.price, p.active, JSON_QUERY(e.value, '$.tags') AS tags, TRY_CONVERT(DATETIMEOFFSET(0), p.updated) AS updated
    INTO #src
    FROM OPENJSON(@json) AS e
    CROSS APPLY OPENJSON(e.value)
    WITH (id INT '$.id', sku NVARCHAR(30) '$.sku', name NVARCHAR(100) '$.name', price DECIMAL(10,2) '$.price',
          active BIT '$.active', updated NVARCHAR(40) '$.updated') AS p;

    BEGIN TRANSACTION;

    UPDATE d
    SET d.Sku = s.sku, d.Name = s.name, d.Price = s.price, d.IsActive = s.active, d.Tags = s.tags, d.UpdatedAt = s.updated
    FROM dbo.Products AS d
    JOIN #src AS s ON s.id = d.ProductId
    WHERE s.updated > d.UpdatedAt;          -- do not overwrite newer data with an older file

    INSERT INTO dbo.Products (ProductId, Sku, Name, Price, IsActive, Tags, UpdatedAt)
    SELECT s.id, s.sku, s.name, s.price, s.active, s.tags, s.updated
    FROM #src AS s
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Products AS d WHERE d.ProductId = s.id);

    COMMIT TRANSACTION;
END
GO
