USE JsonImport;
GO


DECLARE @doc NVARCHAR(MAX) = N'{"orderId":"A-1001","customer":{"id":7,"name":"Rosa Alvarez"},"lines":[{"sku":"BK-100","qty":3},{"sku":"PN-010","qty":10}]}';

SELECT JSON_VALUE(@doc, '$.orderId')            AS order_id,        -- scalar only
       JSON_VALUE(@doc, '$.customer.name')      AS customer_name,
       JSON_VALUE(@doc, '$.lines[1].sku')       AS second_sku,      -- arrays are zero-based
       JSON_QUERY(@doc, '$.customer')           AS customer_object, -- objects and arrays need JSON_QUERY
       JSON_VALUE(@doc, '$.customer')           AS not_a_scalar;    -- NULL in lax mode

-- JSON_VALUE returns NVARCHAR(4000) and silently truncates nothing: longer values give NULL
-- in lax mode and an error in strict mode.
SELECT JSON_VALUE(@doc, 'strict $.orderId') AS strict_ok;
-- SELECT JSON_VALUE(@doc, 'strict $.nope');   -- error 13608: property cannot be found
