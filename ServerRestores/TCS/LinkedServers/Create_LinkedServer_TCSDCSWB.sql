--SCRIPT IS GOOD ONLY FOR ENVIRONMENTS
--BEGINNING VMxx

DECLARE @ENVNAME VARCHAR(15)
--SET @ENVNAME = LEFT(@@SERVERNAME, 4) + 'DCSSERVER'
SET @ENVNAME = LEFT(@@SERVERNAME, 4) + 'DCSPRODBA01'

/****** Object:  LinkedServer [TCSDCSWB]    Script Date: 03/31/2009 09:58:08 ******/
--EXEC master.dbo.sp_addlinkedserver @server = N'TCSDCSWB', @srvproduct=N'<Server to link to e.g. VM01DCSSERVER, varchar(15), VMxxDCSSERVER>', @provider=N'SQLNCLI', @datasrc=N'<Server to link to e.g. VM01DCSSERVER, varchar(15), VMxxDCSSERVER>'
EXEC master.dbo.sp_addlinkedserver @server = N'TCSDCSWB', @srvproduct=@ENVNAME, @provider=N'SQLNCLI', @datasrc=@ENVNAME
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'TCSDCSWB',@useself=N'False',@locallogin=NULL,@rmtuser=N'tcs_user',@rmtpassword='tcs_user'

EXEC master.dbo.sp_serveroption @server=N'TCSDCSWB', @optname=N'collation compatible', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'TCSDCSWB', @optname=N'data access', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=N'TCSDCSWB', @optname=N'dist', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'TCSDCSWB', @optname=N'pub', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'TCSDCSWB', @optname=N'rpc', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=N'TCSDCSWB', @optname=N'rpc out', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=N'TCSDCSWB', @optname=N'sub', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'TCSDCSWB', @optname=N'connect timeout', @optvalue=N'0'
EXEC master.dbo.sp_serveroption @server=N'TCSDCSWB', @optname=N'collation name', @optvalue=null
EXEC master.dbo.sp_serveroption @server=N'TCSDCSWB', @optname=N'lazy schema validation', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'TCSDCSWB', @optname=N'query timeout', @optvalue=N'0'
EXEC master.dbo.sp_serveroption @server=N'TCSDCSWB', @optname=N'use remote collation', @optvalue=N'true'