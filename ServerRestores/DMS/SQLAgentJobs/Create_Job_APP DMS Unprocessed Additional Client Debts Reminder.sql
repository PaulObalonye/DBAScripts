USE [msdb]
GO
/****** Object:  Job [APP DMS Unprocessed Additional Client Debts Reminder]    Script Date: 08/29/2013 11:03:31 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 08/29/2013 11:03:31 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'APP DMS Unprocessed Additional Client Debts Reminder', 
		@enabled=0, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'SUMMARY
Emails Unprocessed additional client debts to CorrespondenceTeamLeaders@cccs.co.uk

INTERFACES
DMS: R
msdb

SUPPORT NOTES
Can be run anytime, scheduled once a month
', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Step 1]    Script Date: 08/29/2013 11:03:32 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Step 1', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE	@Now DATETIME
		,@Month TINYINT
		,@Year SMALLINT
		,@NumUnprocessed INT
		,@MailSubject VARCHAR(255)
		,@MailBody VARCHAR(255)
		,@MailImportance VARCHAR(6)
SET		@Now = GETDATE()
SET		@Month = DATEPART(mm, @Now)
SET		@Year = DATEPART(yyyy, @Now)
SELECT	@NumUnprocessed = COUNT(id)
FROM	dbo.add_debts
WHERE	DATEPART(yyyy, start_date) = @Year
		AND DATEPART(mm, start_date) = @Month
		AND date_processed IS NULL
SET		@MailSubject = ''Unprocessed additional client debts starting '' +
		DATENAME(mm, @Now) + '' '' + DATENAME(yyyy, @Now)
SET		@MailBody = ''There '' + CASE @NumUnprocessed WHEN 1 THEN ''is '' ELSE ''are '' END +
		CAST(@NumUnprocessed AS VARCHAR) + '' unprocessed additional client debt'' +
		CASE @NumUnprocessed WHEN 1 THEN '''' ELSE ''s'' END +
		'' starting '' + DATENAME(mm, @Now) + '' '' + DATENAME(yyyy, @Now)
SET		@MailImportance = CASE @NumUnprocessed WHEN 0 THEN ''Normal'' ELSE ''High'' END

--EXEC	msdb.dbo.sp_send_dbmail
--		@profile_name = ''SQLMail''
--		,@recipients = ''andrews@stepchange.org''
--		,@subject = @MailSubject
--		,@body = @MailBody
--		,@body_format = ''TEXT''
--		,@importance = @MailImportance
', 
		@database_name=N'DMS', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Schedule 1', 
		@enabled=0, 
		@freq_type=16, 
		@freq_interval=8, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20050101, 
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
