USE [master]
GO
CREATE LOGIN [CallRoutingUser] WITH PASSWORD=N'CallRoutingUser', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

CREATE LOGIN [CCCSVALink] WITH PASSWORD=N'CCCSVALink', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
--CREATE LOGIN [CWSRefreshUser] WITH PASSWORD=N'CWSRefreshUser', DEFAULT_DATABASE=[SSIS_PDS], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
CREATE LOGIN [CWSRefreshUser] WITH PASSWORD=N'CWSRefreshUser', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
CREATE LOGIN [DCS_BMI_DWExtract] WITH PASSWORD=N'DCS_BMI_DWExtract', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
CREATE LOGIN [DMSSQLServerLink] WITH PASSWORD=N'DMSSQLServerLink', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
--CREATE LOGIN [DRWriteback] WITH PASSWORD=N'DRWriteback', DEFAULT_DATABASE=[DCSLive], CHECK_EXPIRATION=OFF, CHECK_POLICY=ON
CREATE LOGIN [DRWriteback] WITH PASSWORD=N'DRWriteback', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
CREATE LOGIN [iFACE_DCSUser] WITH PASSWORD=N'iFACE_DCSUser', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
--ReportingServices
CREATE LOGIN [ReportingServices] WITH PASSWORD=N'ReportingServices', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
CREATE LOGIN [sqlserverlink] WITH PASSWORD=N'sqlserverlink', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
CREATE LOGIN [tcs_user] WITH PASSWORD=N'tcs_user', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
CREATE LOGIN [wsDCSUser] WITH PASSWORD=N'wsDCSUser', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

--BackupUser for reading msdb
--USE [master]
--GO
--CREATE LOGIN [BackupUser] WITH PASSWORD=N'B@ckupU$3r', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
--GO
--USE [msdb]
--GO
--CREATE USER [BackupUser] FOR LOGIN [BackupUser]
--GO
--EXEC sp_addrolemember N'db_datareader', N'BackupUser'
--GO

--NO LONGER REQUIRED
--Local login for LDSDMSPRO1DBA01 linked server
--USE [master]
--GO
--CREATE LOGIN [LinkedServerLogin] WITH PASSWORD=N'LinkedServerLogin', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
--GO

--DCSReader is a SUPPORT SQL Login ONLY
--It allows DMPCentralisation to read DCSLive via the DCSSERVER Linked Server on VMxxGENPRODBA01
USE [master]
GO
CREATE LOGIN [DCSReader] WITH PASSWORD=N'DCSReader', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

--DCSPrinting
USE [master]
GO
CREATE LOGIN [CCCSNT\dcsprinting] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
GO

--Create the login for the iFACE proxy account
CREATE LOGIN [CCCSNT\VMDCSiFACE_SSISProxy] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]

--User is rematched in restore script from DCSiFACE_SSISProxy to VMDCSiFACE_SSISProxy
--ALTER  USER [DCSiFACE_SSISProxy]
--WITH LOGIN = [CCCSNT\VMDCSiFACE_SSISProxy];

--Add the user to the MSDB database...
USE [msdb]
GO
CREATE USER [CCCSNT\VMDCSiFACE_SSISProxy] FOR LOGIN [CCCSNT\VMDCSiFACE_SSISProxy]
GO
USE [msdb]
GO
EXEC sp_addrolemember N'db_dtsoperator', N'CCCSNT\VMDCSiFACE_SSISProxy'
GO

--Create the Credential...
USE [master]
GO
CREATE CREDENTIAL [DCSiFACETransfer] WITH IDENTITY = N'CCCSNT\VMDCSiFACE_SSISProxy', SECRET = N'VMDCSiFACE_SSISProxy'
GO

--Create the Proxy Account...
USE [msdb]
GO
/****** Object:  ProxyAccount [DCSiFACEProxy]    Script Date: 10/20/2011 14:15:20 ******/
EXEC msdb.dbo.sp_add_proxy @proxy_name=N'DCSiFACEProxy',@credential_name=N'DCSiFACETransfer', 
		@enabled=1

USE [msdb]
GO
EXEC msdb.dbo.sp_update_proxy @proxy_name=N'DCSiFACEProxy',@credential_name=N'DCSiFACETransfer', 
		@description=N''
GO
EXEC msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name=N'DCSiFACEProxy', @subsystem_id=11
GO

--DROFS Logins
USE [master]
GO
CREATE LOGIN [CommsWebServiceUser] WITH PASSWORD=N'CommsWebServiceUser', DEFAULT_DATABASE=[DCSLive], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
CREATE LOGIN [DROUser] WITH PASSWORD=N'DROUser', DEFAULT_DATABASE=[DCSLive], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
