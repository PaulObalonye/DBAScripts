--SCRIPT IS GOOD ONLY FOR ENVIRONMENTS
--BEGINNING VMxx

DECLARE @ENVNAME VARCHAR(15)
SET @ENVNAME = LEFT(@@SERVERNAME, 4) + 'GENPRODBA02'

/****** Object:  LinkedServer [DMSDDELINK]    Script Date: 03/26/2009 10:11:16 ******/
--EXEC master.dbo.sp_addlinkedserver @server = N'DMSDDELINK', @srvproduct=N'<Server to link to e.g. VM01GENPRODBA02, varchar(15), VMxxGENPRODBA02>', @provider=N'sqloledb', @datasrc=N'<Server to link to e.g. VM01GENPRODBA02, varchar(15), VMxxGENPRODBA02>'
EXEC master.dbo.sp_addlinkedserver @server = N'DMSDDELINK', @srvproduct=@ENVNAME, @provider=N'sqloledb', @datasrc=@ENVNAME
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'DMSDDELINK',@useself=N'False',@locallogin=NULL,@rmtuser=N'DMSDDE_LSUser',@rmtpassword='DMSDDE_LSUser'

EXEC master.dbo.sp_serveroption @server=N'DMSDDELINK', @optname=N'collation compatible', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'DMSDDELINK', @optname=N'data access', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=N'DMSDDELINK', @optname=N'dist', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'DMSDDELINK', @optname=N'pub', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'DMSDDELINK', @optname=N'rpc', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=N'DMSDDELINK', @optname=N'rpc out', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=N'DMSDDELINK', @optname=N'sub', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'DMSDDELINK', @optname=N'connect timeout', @optvalue=N'0'
EXEC master.dbo.sp_serveroption @server=N'DMSDDELINK', @optname=N'collation name', @optvalue=null
EXEC master.dbo.sp_serveroption @server=N'DMSDDELINK', @optname=N'lazy schema validation', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'DMSDDELINK', @optname=N'query timeout', @optvalue=N'0'
EXEC master.dbo.sp_serveroption @server=N'DMSDDELINK', @optname=N'use remote collation', @optvalue=N'true'
