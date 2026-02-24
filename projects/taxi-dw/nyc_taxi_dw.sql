CREATE DATABASE NYC_Taxi_DW;
GO

USE NYC_Taxi_DW;
GO

CREATE SCHEMA taxi;
GO

CREATE TABLE taxi.DimDate (
    DateID INT PRIMARY KEY,
    Date DATE NOT NULL,
    Year INT NOT NULL,
    Month INT NOT NULL,
    DayOfWeek INT NOT NULL,
    DayName VARCHAR(10) NOT NULL,
    Quarter INT NOT NULL,
    IsWeekend BIT NOT NULL
);

CREATE TABLE taxi.DimVendor (
    VendorID INT PRIMARY KEY,
    VendorName VARCHAR(100) NOT NULL,
    VendorCode VARCHAR(10) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1
);

CREATE TABLE taxi.DimLocation (
    LocationID INT PRIMARY KEY,
    Zone VARCHAR(100) NOT NULL,
    Borough VARCHAR(50) NOT NULL,
    ServiceZone VARCHAR(50) NOT NULL,
    IsAirport BIT NOT NULL DEFAULT 0,
    TrafficDensity VARCHAR(20) NOT NULL DEFAULT 'Medium'
);

INSERT INTO taxi.DimLocation (LocationID, Zone, Borough, ServiceZone, IsAirport, TrafficDensity)
VALUES (999, 'Unknown', 'Unknown', 'Unknown', 0, 'Unknown');

CREATE TABLE taxi.DimPaymentType (
    PaymentTypeID INT PRIMARY KEY,
    PaymentMethod VARCHAR(50) NOT NULL,
    PaymentCategory VARCHAR(30) NOT NULL,
    RequiresProcessing BIT NOT NULL DEFAULT 0
);

CREATE TABLE taxi.FactTaxiTrip (
    TripID BIGINT IDENTITY(1,1) PRIMARY KEY,
    DateID INT NOT NULL,
    VendorID INT NOT NULL,
    PickupLocationID INT NOT NULL,
    DropoffLocationID INT NOT NULL,
    PaymentTypeID INT NOT NULL,

    PickupDateTime DATETIME2 NOT NULL,
    DropoffDateTime DATETIME2 NOT NULL,
    PickupHour AS (DATEPART(HOUR, PickupDateTime)) PERSISTED,

    TripDistance DECIMAL(8,2),
    TipAmount DECIMAL(10,2),
    TotalAmount DECIMAL(10,2),

    CONSTRAINT FK_Fact_Date FOREIGN KEY (DateID) REFERENCES taxi.DimDate(DateID),
    CONSTRAINT FK_Fact_Vendor FOREIGN KEY (VendorID) REFERENCES taxi.DimVendor(VendorID),
    CONSTRAINT FK_Fact_PickupLocation FOREIGN KEY (PickupLocationID) REFERENCES taxi.DimLocation(LocationID),
    CONSTRAINT FK_Fact_DropoffLocation FOREIGN KEY (DropoffLocationID) REFERENCES taxi.DimLocation(LocationID),
    CONSTRAINT FK_Fact_Payment FOREIGN KEY (PaymentTypeID) REFERENCES taxi.DimPaymentType(PaymentTypeID)
);

-- Most important indexes for reporting
CREATE NONCLUSTERED INDEX IX_Fact_DateID 
ON taxi.FactTaxiTrip(DateID) 
INCLUDE (TotalAmount, TripDistance);

CREATE NONCLUSTERED INDEX IX_Fact_VendorID 
ON taxi.FactTaxiTrip(VendorID, DateID) 
INCLUDE (TotalAmount);

CREATE NONCLUSTERED INDEX IX_Fact_PickupHour 
ON taxi.FactTaxiTrip(PickupHour) 
INCLUDE (TotalAmount, TripDistance);

CREATE NONCLUSTERED INDEX IX_Fact_Locations 
ON taxi.FactTaxiTrip(PickupLocationID, DropoffLocationID) 
INCLUDE (TotalAmount, TripDistance);

UPDATE STATISTICS taxi.FactTaxiTrip WITH FULLSCAN;