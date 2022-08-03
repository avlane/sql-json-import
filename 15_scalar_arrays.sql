USE JsonImport;
GO


-- Product tags are stored as a JSON array in dbo.Products.Tags.
SELECT p.Sku, t.value AS tag, CAST(t.[key] AS INT) AS position
FROM dbo.Products AS p
CROSS APPLY OPENJSON(p.Tags) AS t
WHERE p.Tags IS NOT NULL;

-- Products having a given tag
SELECT p.Sku, p.Name
FROM dbo.Products AS p
WHERE EXISTS (SELECT 1 FROM OPENJSON(p.Tags) AS t WHERE t.value = N'office');

-- Tag counts
SELECT t.value AS tag, COUNT(*) AS products
FROM dbo.Products AS p
CROSS APPLY OPENJSON(p.Tags) AS t
GROUP BY t.value
ORDER BY products DESC, tag;

-- And back: STRING_AGG turns the array into a comma separated list
SELECT p.Sku, (SELECT STRING_AGG(t.value, N', ') FROM OPENJSON(p.Tags) AS t) AS tag_list
FROM dbo.Products AS p;
