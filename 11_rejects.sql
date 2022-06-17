USE JsonImport;
GO


CREATE TABLE imp.Reject
(
    RejectId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Reject PRIMARY KEY,
    DocId    INT NOT NULL,
    Target   SYSNAME NOT NULL,
    ElementNo INT NULL,
    Reason   NVARCHAR(200) NOT NULL,
    RawJson  NVARCHAR(MAX) NULL,
    RejectedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Reject_At DEFAULT (SYSDATETIME())
);
GO

-- Finds product elements that would fail conversion, one reason per row.
CREATE OR ALTER PROCEDURE dbo.usp_RejectBadProducts
    @DocId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @json NVARCHAR(MAX) = (SELECT Body FROM stg.JsonDoc WHERE DocId = @DocId);

    INSERT INTO imp.Reject (DocId, Target, ElementNo, Reason, RawJson)
    SELECT @DocId, N'dbo.Products', CAST(e.[key] AS INT),
           CASE WHEN JSON_VALUE(e.value, '$.sku') IS NULL                            THEN N'missing sku'
                WHEN TRY_CONVERT(DECIMAL(10,2), JSON_VALUE(e.value, '$.price')) IS NULL THEN N'price is not a number'
                WHEN TRY_CONVERT(DATETIMEOFFSET(0), JSON_VALUE(e.value, '$.updated')) IS NULL THEN N'bad updated timestamp'
           END,
           e.value
    FROM OPENJSON(@json) AS e
    WHERE JSON_VALUE(e.value, '$.sku') IS NULL
       OR TRY_CONVERT(DECIMAL(10,2), JSON_VALUE(e.value, '$.price')) IS NULL
       OR TRY_CONVERT(DATETIMEOFFSET(0), JSON_VALUE(e.value, '$.updated')) IS NULL;

    RETURN @@ROWCOUNT;
END
GO
