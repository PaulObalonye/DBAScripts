USE [msdb]
GO
/****** Object:  Job [APP DebtRemedy Archive]    Script Date: 09/03/2015 15:47:28 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 09/03/2015 15:47:29 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'APP DebtRemedy Archive', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'SUMMARY
Purges clients that haven''t logged in for over 6 months.

INTERFACES
DebtRemedy_Live: R/U/D

SUPPORT NOTES
Run in working hours? N
Small impact for failures in that client data will be present for longer than necessary, however this is small and the job can wait to be re-run the following day
The job will email the service desk and DBA team should the job not delete all the clients in one execution', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Clear down]    Script Date: 09/03/2015 15:47:29 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Clear down', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=1, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @NoOfClients INT
DECLARE @count INT;

SET @count = 1

select @NoOfClients = COUNT(1)
from DebtRemedy_Live.[dbo].[vw_ClientsToBeDeleted]
with (nolock) -- query hint will propagate to all base tables and nested views (https://msdn.microsoft.com/en-us/library/ms190237(v=sql.90).aspx)

WHILE	(@NoOfClients > 50
		AND @count < 4)
BEGIN

	PRINT ''Execution count equals'' + CAST(@count AS CHAR(1))

	EXEC [dbo].[ClearDownClients]

	select @NoOfClients = COUNT(1)
	from DebtRemedy_Live.[dbo].[vw_ClientsToBeDeleted]
	with (nolock) -- query hint will propagate to all base tables and nested views (https://msdn.microsoft.com/en-us/library/ms190237(v=sql.90).aspx)

	SET @count = @count + 1

END ;
GO', 
		@database_name=N'DebtRemedy_Live', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Email Alert]    Script Date: 09/03/2015 15:47:29 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Email Alert', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- Will email helpdesk and Systems DBA team if the archive job hasnt 
-- purged all the clients in one execution of the job

DECLARE @NoOfClients INT;

select @NoOfClients = COUNT(1)
from DebtRemedy_Live.[dbo].[vw_ClientsToBeDeleted]
with (nolock) -- query hint will propagate to all base tables and nested views (https://msdn.microsoft.com/en-us/library/ms190237(v=sql.90).aspx)

IF @NoOfClients > 50 
BEGIN 

	DECLARE @Msg NVARCHAR(4000);

	SET @Msg = ''The DebtRemedy_Live archive job still has '' + CAST(@NoOfClients as NVARCHAR(5)) + '' outstanding clients to purge.''
	
	--EXEC SystemsHelpDesk.dbo.job_fail_notification 
	--	  @System = ''Debt Remedy''
	--	, @Subsystem = ''Archive''
	--	, @Message = @Msg ;

END ;
GO', 
		@database_name=N'master', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily OOH', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=126, 
		@freq_subday_type=1, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20081230, 
		@active_end_date=99991231, 
		@active_start_time=4500, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
