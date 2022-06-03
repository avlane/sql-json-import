USE JsonImport;
GO


CREATE TABLE dbo.Customer
(
    CustomerId INT NOT NULL CONSTRAINT PK_Customer PRIMARY KEY,
    Name       NVARCHAR(100) NOT NULL,
    Email      NVARCHAR(200) NULL
);

CREATE TABLE dbo.CustomerOrder
(
    OrderNo    NVARCHAR(20) NOT NULL CONSTRAINT PK_CustomerOrder PRIMARY KEY,
    CustomerId INT NOT NULL CONSTRAINT FK_CustomerOrder_Customer REFERENCES dbo.Customer (CustomerId),
    PlacedAt   DATETIME2(0) NOT NULL
);

CREATE TABLE dbo.OrderLine
(
    OrderNo   NVARCHAR(20) NOT NULL CONSTRAINT FK_OrderLine_Order REFERENCES dbo.CustomerOrder (OrderNo),
    LineNo    INT NOT NULL,
    Sku       NVARCHAR(30) NOT NULL,
    Qty       INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_OrderLine PRIMARY KEY (OrderNo, LineNo)
);
GO

CREATE OR ALTER PROCEDURE dbo.usp_ImportOrders
    @DocId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @json NVARCHAR(MAX) = (SELECT Body FROM stg.JsonDoc WHERE DocId = @DocId);
    IF @json IS NULL OR ISJSON(@json) <> 1
        THROW 52000, N'Document missing or not valid JSON.', 1;

    BEGIN TRANSACTION;

    -- customers: take the newest name/email we see for each id in the file
    ;WITH c AS (
        SELECT j.id, j.name, j.email, ROW_NUMBER() OVER (PARTITION BY j.id ORDER BY j.placed DESC) AS rn
        FROM OPENJSON(@json)
        WITH (id INT '$.customer.id', name NVARCHAR(100) '$.customer.name', email NVARCHAR(200) '$.customer.email', placed DATETIME2(0) '$.placed') AS j
    )
    SELECT id, name, email INTO #cust FROM c WHERE rn = 1;

    UPDATE d SET d.Name = s.name, d.Email = s.email
    FROM dbo.Customer AS d JOIN #cust AS s ON s.id = d.CustomerId;

    INSERT INTO dbo.Customer (CustomerId, Name, Email)
    SELECT id, name, email FROM #cust AS s WHERE NOT EXISTS (SELECT 1 FROM dbo.Customer AS d WHERE d.CustomerId = s.id);

    -- orders that are not already loaded
    INSERT INTO dbo.CustomerOrder (OrderNo, CustomerId, PlacedAt)
    SELECT j.orderId, j.customerId, j.placed
    FROM OPENJSON(@json)
    WITH (orderId NVARCHAR(20) '$.orderId', customerId INT '$.customer.id', placed DATETIME2(0) '$.placed') AS j
    WHERE NOT EXISTS (SELECT 1 FROM dbo.CustomerOrder AS o WHERE o.OrderNo = j.orderId);

    -- lines for the orders just inserted; array position becomes the line number
    INSERT INTO dbo.OrderLine (OrderNo, LineNo, Sku, Qty, UnitPrice)
    SELECT JSON_VALUE(ord.value, '$.orderId'), CAST(l.[key] AS INT) + 1, JSON_VALUE(l.value, '$.sku'),
           CAST(JSON_VALUE(l.value, '$.qty') AS INT), CAST(JSON_VALUE(l.value, '$.unitPrice') AS DECIMAL(10,2))
    FROM OPENJSON(@json) AS ord
    CROSS APPLY OPENJSON(ord.value, '$.lines') AS l
    WHERE NOT EXISTS (SELECT 1 FROM dbo.OrderLine AS x WHERE x.OrderNo = JSON_VALUE(ord.value, '$.orderId'));

    COMMIT TRANSACTION;
END
GO
