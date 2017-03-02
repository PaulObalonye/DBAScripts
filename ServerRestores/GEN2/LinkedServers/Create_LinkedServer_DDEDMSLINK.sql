--SCRIPT IS GOOD ONLY FOR ENVIRONMENTS
--BEGINNING VMxx

DECLARE @ENVNAME VARCHAR(15)
SET @ENVNAME = LEFT(@@SERVERNAME, 4) + 'DMSPRODBA01'

/****** Object:  LinkedServer [DDEDMSLINK]    Script Date: 03/27/2009 15:59:34 ******/
--EXEC master.dbo.sp_addlinkedserver @server = N'DDEDMSLINK', @srvproduct=N'<Server to link to e.g. VM01DMSPRODBA01, varchar(15), VMxxDMSPRODBA01>', @provider=N'SQLNCLI', @datasrc=N'<Server to link to e.g. VM01DMSPRODBA01, varchar(15), VMxxDMSPRODBA01>'
EXEC master.dbo.sp_addlinkedserver @server = N'DDEDMSLINK', @srvproduct=@ENVNAME, @provider=N'SQLNCLI', @datasrc=@ENVNAME
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'DDEDMSLINK',@useself=N'False',@locallogin=NULL,@rmtuser=N'PDDUser',@rmtpassword='PDDUser'

EXEC master.dbo.sp_serveroption @server=N'DDEDMSLINK', @optname=N'collation compatible', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'DDEDMSLINK', @optname=N'data access', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=N'DDEDMSLINK', @optname=N'dist', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'DDEDMSLINK', @optname=N'pub', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'DDEDMSLINK', @optname=N'rpc', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=N'DDEDMSLINK', @optname=N'rpc out', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=N'DDEDMSLINK', @optname=N'sub', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'DDEDMSLINK', @optname=N'connect timeout', @optvalue=N'0'
EXEC master.dbo.sp_serveroption @server=N'DDEDMSLINK', @optname=N'collation name', @optvalue=null
EXEC master.dbo.sp_serveroption @server=N'DDEDMSLINK', @optname=N'lazy schema validation', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'DDEDMSLINK', @optname=N'query timeout', @optvalue=N'0'
EXEC master.dbo.sp_serveroption @server=N'DDEDMSLINK', @optname=N'use remote collation', @optvalue=N'true'