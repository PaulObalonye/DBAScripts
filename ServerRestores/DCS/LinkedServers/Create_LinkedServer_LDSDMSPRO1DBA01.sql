--SCRIPT IS GOOD ONLY FOR ENVIRONMENTS
--BEGINNING VMxx

USE [master]
GO
DECLARE @ENVNAME VARCHAR(15)
SET @ENVNAME = LEFT(@@SERVERNAME, 4) + 'DMSPRODBA01'

--EXEC master.dbo.sp_addlinkedserver @server = N'LDSDMSPRO1DBA01', @srvproduct=N'LDSDMSPRO1DBA01', @provider=N'SQLOLEDB', @datasrc=N'<Server to link to e.g. VM01DMSPRODBA01, varchar(15), VMxxDMSPRODBA01>'
EXEC master.dbo.sp_addlinkedserver @server = N'LDSDMSPRO1DBA01', @srvproduct=N'LDSDMSPRO1DBA01', @provider=N'SQLOLEDB', @datasrc=@ENVNAME

EXEC master.dbo.sp_serveroption @server=N'LDSDMSPRO1DBA01', @optname=N'collation compatible', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'LDSDMSPRO1DBA01', @optname=N'data access', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=N'LDSDMSPRO1DBA01', @optname=N'rpc', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=N'LDSDMSPRO1DBA01', @optname=N'rpc out', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=N'LDSDMSPRO1DBA01', @optname=N'connect timeout', @optvalue=N'0'
EXEC master.dbo.sp_serveroption @server=N'LDSDMSPRO1DBA01', @optname=N'collation name', @optvalue=null
EXEC master.dbo.sp_serveroption @server=N'LDSDMSPRO1DBA01', @optname=N'query timeout', @optvalue=N'0'
EXEC master.dbo.sp_serveroption @server=N'LDSDMSPRO1DBA01', @optname=N'use remote collation', @optvalue=N'false'
--USE [master]
--GO
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname = N'LDSDMSPRO1DBA01', @locallogin = NULL , @useself = N'False', @rmtuser = N'LinkedServerLogin', @rmtpassword = N'LinkedServerLogin'
--GO
