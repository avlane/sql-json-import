USE JsonImport;
GO


DECLARE @doc NVARCHAR(MAX) = N'{"orderId":"A-1001","status":"new","lines":[{"sku":"BK-100","qty":3}]}';

SET @doc = JSON_MODIFY(@doc, '$.status', 'paid');                       -- change a value
SET @doc = JSON_MODIFY(@doc, '$.paidAt', '2022-06-25T20:00:00');        -- add a property
SET @doc = JSON_MODIFY(@doc, '$.lines[0].qty', 4);                      -- change a nested number
SET @doc = JSON_MODIFY(@doc, 'append $.lines', JSON_QUERY(N'{"sku":"PN-010","qty":2}'));  -- append an element
SET @doc = JSON_MODIFY(@doc, '$.status', NULL);                         -- NULL removes the property in lax mode

SELECT @doc AS patched;

-- Wrap a fragment in JSON_QUERY or it is inserted as an escaped string.
SELECT JSON_MODIFY(N'{}', '$.tags', N'["a","b"]')             AS escaped_string,
       JSON_MODIFY(N'{}', '$.tags', JSON_QUERY(N'["a","b"]')) AS real_array;
