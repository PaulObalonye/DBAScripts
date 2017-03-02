USE [msdb]
GO
/****** Object:  Job [APP TCS WeeklyArchiving]    Script Date: 08/29/2013 10:18:58 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 08/29/2013 10:18:58 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'APP TCS WeeklyArchiving', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'SUMMARY
Weekly archive and delete job to remove client data. It also includes a workaround for INC67857 to delete counsellor session comments

INTERFACES
TCS: C/U/D

SUPPORT NOTES
Run in working hours? N
Small impact for failures in that client data will be present for longer than necessary, however this is small and the job can wait to be re-run the following week
Step 2 - INC67857 was added as a workaround and should be removed once a permanent solution is in place', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Archive Client Details]    Script Date: 08/29/2013 10:18:58 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Archive Client Details', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec [Archive].[ArchiveClientDetails]', 
		@database_name=N'TCS', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [INC67857 - iFACE and DRO Notes Workaround]    Script Date: 08/29/2013 10:18:58 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'INC67857 - iFACE and DRO Notes Workaround', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'IF EXISTS ( SELECT TOP ( 1 )
                    *
            FROM    archive.Clients AS c
                    JOIN dbo.CounsellorClientSession AS ccs ON c.ClientID = ccs.ClientID ) 
    BEGIN

        UPDATE  C
        SET     c.LastLoginTime = ccs.SessionFinish
        FROM    dbo.Clients AS c
                JOIN archive.Clients AS ac ON c.ClientID = ac.ClientID
                JOIN dbo.CounsellorClientSession AS ccs ON ac.ClientID = ccs.ClientID
                JOIN dbo.CounsellorClientSessionComments AS ccsc ON ccs.CounsellorClientSessionID = ccsc.CounsellorClientSessionID
	
        DELETE  dbo.CounsellorClientSessionComments
        OUTPUT  DELETED.*
                INTO Archive.CounsellorClientSessionComments
        FROM    dbo.CounsellorClientSessionComments CCSC
                JOIN dbo.CounsellorClientSession CCS ON CCSC.CounsellorClientSessionId = CCS.CounsellorClientSessionId
                JOIN archive.Clients CTA ON CCS.ClientID = CTA.ClientID

        DELETE  dbo.CounsellorClientSession
        OUTPUT  DELETED.*
                INTO Archive.CounsellorClientSession
        FROM    dbo.CounsellorClientSession CCS
                JOIN archive.Clients CTA ON CCS.ClientID = CTA.ClientID

    END', 
		@database_name=N'TCS', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Delete Client Details]    Script Date: 08/29/2013 10:18:58 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Delete Client Details', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dbo.[DeleteClientDetails]', 
		@database_name=N'TCS', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Delete Disabled Client Details]    Script Date: 08/29/2013 10:18:59 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Delete Disabled Client Details', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dbo.[DeleteDisabledClients]', 
		@database_name=N'TCS', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'OneOff', 
		@enabled=0, 
		@freq_type=1, 
		@freq_interval=0, 
		@freq_subday_type=0, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130709, 
		@active_end_date=99991231, 
		@active_start_time=60000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Sunday Morning', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20080523, 
		@active_end_date=99991231, 
		@active_start_time=60000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
