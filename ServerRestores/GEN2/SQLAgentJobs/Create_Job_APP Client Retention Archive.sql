USE [msdb]
GO
/****** Object:  Job [APP Client Retention Archive]    Script Date: 08/28/2013 15:32:57 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 08/28/2013 15:32:57 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'APP Client Retention Archive', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'SUMMARY
Purges client data older than 3 months from the Client Retention database and error data older than 1 month from the ELMAH table.

INTERFACES
ClientRetention: D

SUPPORT NOTES
Run in working hours? N
', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Archive Client Retention]    Script Date: 08/28/2013 15:32:57 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Archive Client Retention', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [ClientRetention]
GO
EXEC [dbo].[ArchiveClientRetention]
GO
', 
		@database_name=N'ClientRetention', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Purge Errors older than a month]    Script Date: 08/28/2013 15:32:57 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Purge Errors older than a month', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [ClientRetention]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DECLARE @ERRORNO INT
DECLARE @ERRORMSG VARCHAR (100)

BEGIN TRY

	BEGIN TRANSACTION ArchiveErrors

		DELETE FROM dbo.ELMAH_Error
		WHERE TimeUtc < DATEADD(m, -1, CURRENT_TIMESTAMP)

	COMMIT TRANSACTION ArchiveErrors
END TRY

BEGIN CATCH
	SELECT	@ERRORNO = ERROR_NUMBER() 
			,@ERRORMSG = ERROR_MESSAGE() 

	PRINT ''Archiving of dbo.ELMAH_Error failed: '' + CONVERT (VARCHAR, @ERRORNO) + '' '' + @ERRORMSG

	IF @@TRANCOUNT > 0
		BEGIN 
			ROLLBACK TRANSACTION ArchiveErrors
		END 
	
	raiserror(''Archiving of dbo.ELMAH_Error failed'', 16, 1)

END CATCH
', 
		@database_name=N'ClientRetention', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Monthly', 
		@enabled=1, 
		@freq_type=16, 
		@freq_interval=28, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20100514, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
