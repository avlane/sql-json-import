USE JsonImport;
GO


DECLARE @json NVARCHAR(MAX) = (SELECT TOP (1) Body FROM stg.JsonDoc WHERE SourceFile LIKE N'%orders.json' ORDER BY DocId DESC);

-- One row per order line, with the order header repeated
SELECT o.orderId,
       o.placed,
       o.customerId,
       o.customerName,
       l.sku,
       l.qty,
       l.unitPrice
FROM OPENJSON(@json) AS ord
CROSS APPLY OPENJSON(ord.value)
WITH (
    orderId      NVARCHAR(20)  '$.orderId',
    placed       DATETIME2(0)  '$.placed',
    customerId   INT           '$.customer.id',
    customerName NVARCHAR(100) '$.customer.name'
) AS o
CROSS APPLY OPENJSON(ord.value, '$.lines')
WITH (
    sku       NVARCHAR(30)  '$.sku',
    qty       INT           '$.qty',
    unitPrice DECIMAL(10,2) '$.unitPrice'
) AS l;

-- OPENJSON(expression, path) starts at a nested array, so no AS-JSON column is needed.
-- CROSS APPLY drops order A-1003 because its lines array is empty.
-- Use OUTER APPLY to keep orders without lines:
SELECT JSON_VALUE(ord.value, '$.orderId') AS orderId, l.sku, l.qty
FROM OPENJSON(@json) AS ord
OUTER APPLY OPENJSON(ord.value, '$.lines') WITH (sku NVARCHAR(30) '$.sku', qty INT '$.qty') AS l;
