--SCRIPT IS GOOD ONLY FOR ENVIRONMENTS
--BEGINNING VMxx

DECLARE @ENVNAME VARCHAR(15)
SET @ENVNAME = LEFT(@@SERVERNAME, 4) + 'GENPRODBA03'

/****** Object:  LinkedServer [LDSGENPRO1DBA03]    Script Date: 03/10/2011 09:34:42 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'LDSGENPRO1DBA03', @srvproduct=@ENVNAME, @provider=N'SQLNCLI', @datasrc=@ENVNAME
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'LDSGENPRO1DBA03',@useself=N'False',@locallogin=NULL,@rmtuser=N'DMSSQLServerLink',@rmtpassword='DMSSQLServerLink'


EXEC master.dbo.sp_serveroption @server=N'LDSGENPRO1DBA03', @optname=N'collation compatible', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'LDSGENPRO1DBA03', @optname=N'data access', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=N'LDSGENPRO1DBA03', @optname=N'dist', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'LDSGENPRO1DBA03', @optname=N'pub', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'LDSGENPRO1DBA03', @optname=N'rpc', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=N'LDSGENPRO1DBA03', @optname=N'rpc out', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=N'LDSGENPRO1DBA03', @optname=N'sub', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'LDSGENPRO1DBA03', @optname=N'connect timeout', @optvalue=N'0'
EXEC master.dbo.sp_serveroption @server=N'LDSGENPRO1DBA03', @optname=N'collation name', @optvalue=null
EXEC master.dbo.sp_serveroption @server=N'LDSGENPRO1DBA03', @optname=N'lazy schema validation', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'LDSGENPRO1DBA03', @optname=N'query timeout', @optvalue=N'0'
EXEC master.dbo.sp_serveroption @server=N'LDSGENPRO1DBA03', @optname=N'use remote collation', @optvalue=N'true'

