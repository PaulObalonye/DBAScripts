USE [msdb]
GO
/****** Object:  Job [APP DMS CREDITOR MERGE]    Script Date: 08/29/2013 10:29:00 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [APPLICATION]    Script Date: 08/29/2013 10:29:00 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'APPLICATION' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'APPLICATION'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'APP DMS CREDITOR MERGE', 
		@enabled=0, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'SUMMARY
Executes the DMS_merge sp that merges one or more creditors after the details of the merging creditors have been entered by the users.

INTERFACES
DMS: CRUD
msdb

SUPPORT NOTES
Enabled when incident is raised to run creditor merge, job automatically disables at success or failure steps
Do not run over disbursement period or in hours
', 
		@category_name=N'APPLICATION', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [merge]    Script Date: 08/29/2013 10:29:01 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'merge', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=3, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @Diditwork int

EXEC @Diditwork = DMS_Merge

if @Diditwork <> 0
	begin
		raiserror(''Creditor Merge Failed'', 16, 1)
	end
', 
		@database_name=N'DMS', 
		@output_file_name=N'E:\SQLOutput\APP_DMS_CREDITOR_MERGE.txt', 
		@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [email]    Script Date: 08/29/2013 10:29:01 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'email', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
DECLARE @msg varchar(255)
SET @msg        = ''The DMS Creditor Merge Process Completed at: '' + CONVERT(varchar, GETDATE()) 

--EXEC msdb.dbo.sp_send_dbmail
--				@profile_name  = N''SQLMail''			
--				,@recipients	= N''CreditorLiaison@stepchange.org; systemsservicedesk@stepchange.org; BIDevelopmentTeam@stepchange.org''
--				,@importance = N''HIGH''
--				,@subject		= N''DMS Creditor Merge Process''		
--				,@body_format	= N''TEXT''
--				,@body		= @msg

GO
EXEC [dbo].[UK_SSRS_DisableDMSCreditorMerge]
GO', 
		@database_name=N'DMS', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [fail email]    Script Date: 08/29/2013 10:29:01 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'fail email', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=2, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
DECLARE @msg varchar(255)
SET @msg        = ''The DMS Creditor Merge Process Failed at: '' + CONVERT(varchar, GETDATE()) + ''The Systems team are aware and will report asap''

--EXEC msdb.dbo.sp_send_dbmail
--				@profile_name  = N''SQLMail''			
--				,@recipients	= N''CreditorLiaison@stepchange.org; systemsservicedesk@stepchange.org; systemsdbateam@stepchange.org; BIDevelopmentTeam@stepchange.org''
--				,@importance = N''HIGH''
--				,@subject		= N''FAILED - DMS Creditor Merge Process''		
--				,@body_format	= N''TEXT''
--				,@body		= @msg

GO

EXEC [dbo].[UK_SSRS_DisableDMSCreditorMerge]
GO', 
		@database_name=N'DMS', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'One Off', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20080805, 
		@active_end_date=99991231, 
		@active_start_time=20200, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
