USE [msdb]
GO
/****** Object:  Job [APP DCSLIVE Insert Missing Product Types]    Script Date: 08/29/2013 09:36:16 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 08/29/2013 09:36:16 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'APP DCSLIVE Insert Missing Product Types', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'SUMMARY
Ensures all active clients have a product identifier and product status in DCS.

INTERFACES
DCSLive: C/R
DMS: R

SUPPORT NOTES
Run in working hours? N
Leave the job to run on its next schedule in the event of failure.
', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Update Client Product Status]    Script Date: 08/29/2013 09:36:16 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Update Client Product Status', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'

BEGIN TRANSACTION
SELECT  COUNT(*)
FROM    dbo.tblCLIENT_PRODUCT;

CREATE TABLE ##NullProducts
    (
      Client_Identifier INT
    )

INSERT  INTO ##NullProducts
        SELECT  DMSClientRef
        FROM    dbo.tblClient
                INNER JOIN LDSDMSPRO1DBA01.DMS.dbo.client ON DMSClientRef = client_id
        WHERE   DMSClientRef NOT IN ( SELECT DISTINCT
                                                client_identifier
                                      FROM      dbo.tblCLIENT_PRODUCT )
                AND drop_date IS NULL
                AND status IN ( ''A'', ''AR'' )
    
INSERT  INTO dbo.tblCLIENT_PRODUCT
        SELECT  2 ,
                Client_Identifier
        FROM    ##NullProducts;
            
SELECT  COUNT(*)
FROM    ##nullproducts    
            
            
SELECT  COUNT(*)
FROM    dbo.tblCLIENT_PRODUCT

SELECT  COUNT(*)
FROM    dbo.tblCLIENT_PRODUCT_STATUS;

WITH    NoStatus
          AS ( SELECT DISTINCT
                        ##NullProducts.Client_Identifier ,
                        dbo.tblCLIENT_PRODUCT.Client_Product_Identifier
               FROM     ##NullProducts
                        INNER JOIN dbo.tblCLIENT_PRODUCT ON ##NullProducts.Client_Identifier = dbo.tblCLIENT_PRODUCT.Client_Identifier
                                                            AND Product_Type_Identifier = 2
               WHERE    Product_Type_Identifier = 2
             )
    INSERT  INTO dbo.tblCLIENT_PRODUCT_STATUS
            SELECT  DISTINCT
                    GETDATE() ,
                    2 ,
                    Client_Product_Identifier ,
                    1104808
            FROM    NoStatus
                   
SELECT  COUNT(*)
FROM    dbo.tblCLIENT_PRODUCT_STATUS

DROP TABLE ##NullProducts
--ROLLBACK	
COMMIT

', 
		@database_name=N'DCSLive', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130520, 
		@active_end_date=99991231, 
		@active_start_time=230000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
