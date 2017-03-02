USE [msdb]
GO
/****** Object:  Job [APP DMS REPORT TYPE 3 RECORD LOCKS]    Script Date: 08/29/2013 10:52:48 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [APPLICATION]    Script Date: 08/29/2013 10:52:48 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'APPLICATION' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'APPLICATION'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'APP DMS REPORT TYPE 3 RECORD LOCKS', 
		@enabled=0, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'SUMMARY
Reports any record locks, unless in disbursement

INTERFACES
DMS: R
msdb

SUPPORT NOTES
Can be re-run anytime
Should be no locks as all locks unlocked in APP DMS DAILY PROCESS job step earlier 
', 
		@category_name=N'APPLICATION', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [report]    Script Date: 08/29/2013 10:52:48 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'report', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'IF EXISTS(SELECT bh.batchid FROM   batch_header bh WHERE  bh.type = 4 AND bh.status <> 11)
BEGIN
  SELECT ''Disbursement Currently Running.................''
END
ELSE
BEGIN
  SELECT * FROM record_locks WHERE process_lock_type = 3
END



', 
		@database_name=N'DMS', 
		@output_file_name=N'E:\SQLOutput\Type_3_DMS_Locks.txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [email]    Script Date: 08/29/2013 10:52:48 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'email', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'IF (EXISTS(SELECT bh.batchid FROM   batch_header bh WHERE  bh.type = 4 AND bh.status <> 11)) OR (EXISTS(SELECT * FROM record_locks WHERE process_lock_type = 3))
BEGIN
	EXEC msdb.dbo.sp_send_dbmail
			@profile_name  = N''SQLMail''			
			--,@recipients	= N''SystemsDBATeam@stepchange.org; SystemsApplicationSupport@stepchange.org''
			,@recipients	= N''john.myers@stepchange.org''
			,@importance = N''HIGH''
			,@subject		= N''Type 3 DMS Record Locks''		
			,@body_format	= N''TEXT''
			,@body		= N''The attached file contains all the Type 3 DMS records currently locked.''
			,@file_attachments	= N''E:\SQLOutput\Type_3_DMS_Locks.txt''
END
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'daily', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20070821, 
		@active_end_date=99991231, 
		@active_start_time=54500, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
