--SCRIPT IS GOOD ONLY FOR ENVIRONMENTS
--BEGINNING VMxx

USE [master]
GO
DECLARE @ENVNAME VARCHAR(15)
SET @ENVNAME = LEFT(@@SERVERNAME, 4) + 'GENPRODBA02'

EXEC master.dbo.sp_addlinkedserver @server = N'DCSCRLINK', @srvproduct=@ENVNAME, @provider=N'SQLNCLI', @datasrc=@ENVNAME
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'DCSCRLINK',@useself=N'False',@locallogin=NULL,@rmtuser=N'DCSSQLServerLink',@rmtpassword='DCSSQLServerLink'

EXEC master.dbo.sp_serveroption @server=N'DCSCRLINK', @optname=N'collation compatible', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'DCSCRLINK', @optname=N'data access', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=N'DCSCRLINK', @optname=N'dist', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'DCSCRLINK', @optname=N'pub', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'DCSCRLINK', @optname=N'rpc', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=N'DCSCRLINK', @optname=N'rpc out', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=N'DCSCRLINK', @optname=N'sub', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'DCSCRLINK', @optname=N'connect timeout', @optvalue=N'0'
EXEC master.dbo.sp_serveroption @server=N'DCSCRLINK', @optname=N'collation name', @optvalue=null
EXEC master.dbo.sp_serveroption @server=N'DCSCRLINK', @optname=N'lazy schema validation', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'DCSCRLINK', @optname=N'query timeout', @optvalue=N'0'
EXEC master.dbo.sp_serveroption @server=N'DCSCRLINK', @optname=N'use remote collation', @optvalue=N'true'