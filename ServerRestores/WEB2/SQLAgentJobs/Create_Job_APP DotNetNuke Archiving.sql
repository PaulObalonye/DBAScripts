USE [msdb]
GO

IF EXISTS (SELECT 1 FROM sysjobs WHERE name = N'APP DotNetNuke EventLogPurge')
	EXEC sp_delete_job @job_name = N'APP DotNetNuke EventLogPurge';
IF EXISTS (SELECT 1 FROM sysjobs WHERE name = N'APP DotNetNuke Archiving')
	EXEC sp_delete_job @job_name = N'APP DotNetNuke Archiving';

USE [msdb]
GO
/****** Object:  Job [APP DotNetNuke Archiving]    Script Date: 12/03/2013 11:49:33 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 12/03/2013 11:49:33 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'APP DotNetNuke Archiving', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'SUMMARY
Deletes event log entries older than 6 months on a nightly basis, and deletes expired job vacancies and associated tabs on a tri-monthly basis.

INTERFACES
DotNetNuke: D

SUPPORT NOTES
Run in working hours? N
Leave the job to run on its next schedule in the event of failure.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Delete old event log entries]    Script Date: 12/03/2013 11:49:34 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Delete old event log entries', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- Delete old event log entries

USE [DotNetNuke]
GO

BEGIN TRY
	BEGIN TRANSACTION

	DELETE FROM EventLog
	WHERE LogCreateDate < DATEADD(MONTH, -6, GETDATE())

	PRINT ''*** Old event log entries successfully deleted ***''
	COMMIT TRANSACTION

END TRY
BEGIN CATCH

	DECLARE @ErrorMessage NVARCHAR(2048), @ErrorSeverity INT, @ErrorState INT, @ErrorNumber INT
	SET @ErrorMessage = ERROR_MESSAGE()
	SET @ErrorSeverity = ERROR_SEVERITY()
	SET @ErrorState = ERROR_STATE()
	-- Not all errors generate an error state, so set to 1 if it''s zero...
	IF @ErrorState = 0
		SET @ErrorState = 1
	SET @ErrorNumber = ERROR_NUMBER()

	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION

	RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber)

END CATCH
', 
		@database_name=N'master', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Delete expired job vacancies and associated tabs]    Script Date: 12/03/2013 11:49:34 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Delete expired job vacancies and associated tabs', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- Delete expired job vacancies and associated tabs

USE [DotNetNuke]
GO

IF DATEPART(DAY, GETDATE()) = 1 AND DATEPART(MONTH, GETDATE()) IN (1, 4, 7, 10)
BEGIN TRY
	BEGIN TRANSACTION

	DELETE FROM Tabs
	WHERE TabID IN (
		SELECT	DetailsTabId AS ''TabID''
		FROM	CccsJobVacancies
		WHERE	ClosingDate <= GETDATE() - 1
		UNION
		SELECT	ApplyTabId
		FROM	CccsJobVacancies
		WHERE	ClosingDate <= GETDATE() - 1
	)

	DELETE FROM CccsJobVacancies
	WHERE ClosingDate <= GETDATE() - 1

	PRINT ''*** Expired job vacancies and associated tabs successfully deleted ***''
	COMMIT TRANSACTION

END TRY
BEGIN CATCH

	DECLARE @ErrorMessage NVARCHAR(2048), @ErrorSeverity INT, @ErrorState INT, @ErrorNumber INT
	SET @ErrorMessage = ERROR_MESSAGE()
	SET @ErrorSeverity = ERROR_SEVERITY()
	SET @ErrorState = ERROR_STATE()
	-- Not all errors generate an error state, so set to 1 if it''s zero...
	IF @ErrorState = 0
		SET @ErrorState = 1
	SET @ErrorNumber = ERROR_NUMBER()

	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION

	RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber)

END CATCH
', 
		@database_name=N'master', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Nightly', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20131203, 
		@active_end_date=99991231, 
		@active_start_time=3000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
