USE [master]
GO

--WebsiteServices Users
CREATE LOGIN [webuser] WITH PASSWORD=N'webuser', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
--WSSReports (Reporting Services read access to WebsiteServices)
CREATE LOGIN [WSSReports] WITH PASSWORD=N'WSSReports', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
CREATE LOGIN [MIReportingAccess] WITH PASSWORD=N'MIReportingAccess', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

----DCSPrinting
--USE [master]
--GO
--CREATE LOGIN [CCCSNT\dcsprinting] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
--GO

--Docutrieve Users
CREATE LOGIN [DOC_BMI_DWExtract] WITH PASSWORD=N'DOC_BMI_DWExtract', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
CREATE LOGIN [kbAdmin] WITH PASSWORD=N'kbAdmin', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

--DROFS Users...
--Create TEST/UAT logins
USE [master]
GO
IF NOT EXISTS (SELECT name FROM master.sys.server_principals WHERE name =  N'CCCSNT\Non-Live DRO Follow Up System')
	CREATE LOGIN [CCCSNT\Non-Live DRO Follow Up System] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
IF NOT EXISTS (SELECT name FROM master.sys.server_principals WHERE name =  N'CCCSNT\Non-Live DRO Follow Up System Team Leaders')
	CREATE LOGIN [CCCSNT\Non-Live DRO Follow Up System Team Leaders] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
IF NOT EXISTS (SELECT name FROM master.sys.server_principals WHERE name =  N'CCCSNT\nonlivedroapppool')
	CREATE LOGIN [CCCSNT\nonlivedroapppool] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
IF NOT EXISTS (SELECT name FROM master.sys.server_principals WHERE name =  N'CCCSNT\nonlivedrorptservice')
	CREATE LOGIN [CCCSNT\nonlivedrorptservice] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
IF NOT EXISTS (SELECT name FROM master.sys.server_principals WHERE name =  N'CCCSNT\nonlivedroservice')
	CREATE LOGIN [CCCSNT\nonlivedroservice] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
GO
CREATE LOGIN [CallRoutingUser] WITH PASSWORD=N'CallRoutingUser', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

--CPF BACS Users
USE [master]
GO
CREATE LOGIN [cpfreportuser] WITH PASSWORD=N'cpfreportuser', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
CREATE LOGIN [CPFB_BMI_DWExtract] WITH PASSWORD=N'CPFB_BMI_DWExtract', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
CREATE LOGIN [ReportingServices] WITH PASSWORD=N'ReportingServices', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
CREATE LOGIN [CallTrackingUser] WITH PASSWORD=N'CallTrackingUser', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
CREATE LOGIN [DMSSQLServerLink] WITH PASSWORD=N'DMSSQLServerLink', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

--CallCredit Non-Live user...
IF NOT EXISTS (SELECT name FROM master.sys.server_principals WHERE name =  N'CCCSNT\nonliveCreditBureau')
	CREATE LOGIN [CCCSNT\nonliveCreditBureau] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
