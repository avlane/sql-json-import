USE JsonImport;
GO


CREATE SCHEMA imp;
GO

CREATE TABLE imp.ImportLog
(
    BatchId      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ImportLog PRIMARY KEY,
    DocId        INT          NOT NULL,
    Target       SYSNAME      NOT NULL,
    StartedAt    DATETIME2(0) NOT NULL CONSTRAINT DF_ImportLog_Start DEFAULT (SYSDATETIME()),
    FinishedAt   DATETIME2(0) NULL,
    RowsRead     INT          NULL,
    RowsInserted INT          NULL,
    RowsUpdated  INT          NULL,
    Status       VARCHAR(10)  NOT NULL CONSTRAINT DF_ImportLog_Status DEFAULT ('running'),
    ErrorMessage NVARCHAR(2000) NULL
);
GO
