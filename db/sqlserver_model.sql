SET NOCOUNT ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'stg') EXEC('CREATE SCHEMA stg');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'dim') EXEC('CREATE SCHEMA dim');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'fact') EXEC('CREATE SCHEMA fact');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'rpt') EXEC('CREATE SCHEMA rpt');
GO

IF OBJECT_ID('dbo.SourceFile', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.SourceFile (
        SourceFileId     INT IDENTITY(1,1) PRIMARY KEY,
        FileName         NVARCHAR(260) NOT NULL,
        SourceSystem     NVARCHAR(100) NULL,
        LoadedBy         NVARCHAR(100) NULL,
        LoadedAtUtc      DATETIME2(0) NOT NULL CONSTRAINT DF_SourceFile_LoadedAtUtc DEFAULT SYSUTCDATETIME(),
        RowCountExpected INT NULL,
        CONSTRAINT UQ_SourceFile UNIQUE (FileName, LoadedAtUtc)
    );
END;
GO

IF OBJECT_ID('stg.ExcelRecord', 'U') IS NULL
BEGIN
    CREATE TABLE stg.ExcelRecord (
        StagingRecordId  BIGINT IDENTITY(1,1) PRIMARY KEY,
        SourceFileId     INT NOT NULL,
        RecordDate       DATE NOT NULL,
        BusinessKey      NVARCHAR(100) NOT NULL,
        Category         NVARCHAR(150) NULL,
        SubCategory      NVARCHAR(150) NULL,
        MetricName       NVARCHAR(150) NOT NULL,
        MetricValue      DECIMAL(18,4) NOT NULL,
        Notes            NVARCHAR(4000) NULL,
        LoadedAtUtc      DATETIME2(0) NOT NULL CONSTRAINT DF_ExcelRecord_LoadedAtUtc DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_ExcelRecord_SourceFile FOREIGN KEY (SourceFileId) REFERENCES dbo.SourceFile(SourceFileId)
    );
END;
GO

IF OBJECT_ID('dim.Date', 'U') IS NULL
BEGIN
    CREATE TABLE dim.[Date] (
        DateKey       INT NOT NULL PRIMARY KEY,
        FullDate      DATE NOT NULL,
        [Year]        SMALLINT NOT NULL,
        [Quarter]     TINYINT NOT NULL,
        [Month]       TINYINT NOT NULL,
        MonthName     NVARCHAR(15) NOT NULL,
        DayOfMonth    TINYINT NOT NULL,
        WeekOfYear    TINYINT NOT NULL,
        IsWeekend     BIT NOT NULL
    );
END;
GO

IF OBJECT_ID('dim.BusinessEntity', 'U') IS NULL
BEGIN
    CREATE TABLE dim.BusinessEntity (
        BusinessEntityKey INT IDENTITY(1,1) PRIMARY KEY,
        BusinessKey       NVARCHAR(100) NOT NULL,
        Category          NVARCHAR(150) NULL,
        SubCategory       NVARCHAR(150) NULL,
        CONSTRAINT UQ_BusinessEntity UNIQUE (BusinessKey, Category, SubCategory)
    );
END;
GO

IF OBJECT_ID('dim.Metric', 'U') IS NULL
BEGIN
    CREATE TABLE dim.Metric (
        MetricKey      INT IDENTITY(1,1) PRIMARY KEY,
        MetricName     NVARCHAR(150) NOT NULL,
        MetricGroup    NVARCHAR(100) NULL,
        UnitOfMeasure  NVARCHAR(50) NULL,
        CONSTRAINT UQ_Metric UNIQUE (MetricName)
    );
END;
GO

IF OBJECT_ID('fact.ExcelObservation', 'U') IS NULL
BEGIN
    CREATE TABLE fact.ExcelObservation (
        ExcelObservationId BIGINT IDENTITY(1,1) PRIMARY KEY,
        DateKey            INT NOT NULL,
        BusinessEntityKey  INT NOT NULL,
        MetricKey          INT NOT NULL,
        SourceFileId       INT NOT NULL,
        MetricValue        DECIMAL(18,4) NOT NULL,
        LoadedAtUtc        DATETIME2(0) NOT NULL CONSTRAINT DF_ExcelObservation_LoadedAtUtc DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_ExcelObservation_Date FOREIGN KEY (DateKey) REFERENCES dim.[Date](DateKey),
        CONSTRAINT FK_ExcelObservation_BusinessEntity FOREIGN KEY (BusinessEntityKey) REFERENCES dim.BusinessEntity(BusinessEntityKey),
        CONSTRAINT FK_ExcelObservation_Metric FOREIGN KEY (MetricKey) REFERENCES dim.Metric(MetricKey),
        CONSTRAINT FK_ExcelObservation_SourceFile FOREIGN KEY (SourceFileId) REFERENCES dbo.SourceFile(SourceFileId)
    );
END;
GO

IF OBJECT_ID('rpt.vw_ExcelObservation', 'V') IS NULL
EXEC('CREATE VIEW rpt.vw_ExcelObservation AS SELECT 1 AS Placeholder;');
GO

ALTER VIEW rpt.vw_ExcelObservation
AS
SELECT
    o.ExcelObservationId,
    d.FullDate,
    d.[Year],
    d.[Quarter],
    d.[Month],
    d.MonthName,
    be.BusinessKey,
    be.Category,
    be.SubCategory,
    m.MetricName,
    o.MetricValue,
    sf.FileName,
    sf.LoadedAtUtc AS SourceLoadedAtUtc
FROM fact.ExcelObservation o
JOIN dim.[Date] d ON d.DateKey = o.DateKey
JOIN dim.BusinessEntity be ON be.BusinessEntityKey = o.BusinessEntityKey
JOIN dim.Metric m ON m.MetricKey = o.MetricKey
JOIN dbo.SourceFile sf ON sf.SourceFileId = o.SourceFileId;
GO
