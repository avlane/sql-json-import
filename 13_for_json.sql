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
