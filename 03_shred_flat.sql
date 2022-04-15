USE JsonImport;
GO


DECLARE @json NVARCHAR(MAX) = (SELECT TOP (1) Body FROM stg.JsonDoc WHERE SourceFile LIKE N'%products.json' ORDER BY DocId DESC);

SELECT *
FROM OPENJSON(@json)
WITH (
    id      INT            '$.id',
    sku     NVARCHAR(30)   '$.sku',
    name    NVARCHAR(100)  '$.name',
    price   DECIMAL(10,2)  '$.price',
    active  BIT            '$.active',
    updated NVARCHAR(30)   '$.updated'
);

-- Without WITH you get key / value / type for each array element:
SELECT [key], [type], LEFT(value, 60) AS value_preview FROM OPENJSON(@json);
