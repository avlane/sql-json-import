USE JsonImport;
GO


-- Orders with their lines as a nested array
SELECT o.OrderNo   AS orderId,
       o.PlacedAt  AS placed,
       c.CustomerId AS [customer.id],
       c.Name       AS [customer.name],
       (SELECT l.Sku AS sku, l.Qty AS qty, l.UnitPrice AS unitPrice
        FROM dbo.OrderLine AS l
        WHERE l.OrderNo = o.OrderNo
        ORDER BY l.[LineNo]
        FOR JSON PATH) AS lines
FROM dbo.CustomerOrder AS o
JOIN dbo.Customer AS c ON c.CustomerId = o.CustomerId
ORDER BY o.OrderNo
FOR JSON PATH;


-- Wrap the array in a named root property
SELECT ProductId AS id, Sku AS sku, Price AS price FROM dbo.Products FOR JSON PATH, ROOT('products');

-- Keep NULL properties instead of omitting them
SELECT CustomerId AS id, Email AS email FROM dbo.Customer FOR JSON PATH, INCLUDE_NULL_VALUES;

-- A single object instead of a one-element array
SELECT TOP (1) ProductId AS id, Sku AS sku FROM dbo.Products ORDER BY ProductId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;

-- Pitfall: a subquery that returns JSON is escaped as a string unless it is JSON_QUERY-wrapped
-- or comes from a FOR JSON subquery in the select list, as above.
