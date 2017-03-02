USE [msdb]
GO
/****** Object:  Job [APP DMS ARCHIVE CLIENTS]    Script Date: 08/29/2013 10:23:16 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 08/29/2013 10:23:16 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'APP DMS ARCHIVE CLIENTS', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'SUMMARY
Archives client data from DMS to DMSArchive (18 months after client dropped) and subsequently purges (6 years after client dropped).

INTERFACES
DMS: CRUD
DMSArchive: CRD

SUPPORT NOTES
Run out of hours only, one off runs can be scheduled mid-week', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Create Archive Batch]    Script Date: 08/29/2013 10:23:16 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Create Archive Batch', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--Script to Create the Archive Batch
--Recording Date, BatchNo and Client ID List
--Created by: Jef Morris 24-Jan-2011

USE DMSArchive
GO

EXEC Archive.CreateArchiveBatch 18, 72, 0
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Archive DMS Clients]    Script Date: 08/29/2013 10:23:16 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Archive DMS Clients', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--Script to insert data in DMSArchiving
--And then delete from DMS leaving a stub record
--Ref sections 2.6.2 & 2.6.3 of DMS Solutions Archiving
--Created by: Jef Morris 04-Jan-2011

USE DMSArchive
GO

exec ArchiveDMSClients', 
		@database_name=N'master', 
		@output_file_name=N'C:\ArchiveOutput\ArchiveDMSClients.txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Purge DMS Clients]    Script Date: 08/29/2013 10:23:16 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Purge DMS Clients', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--Script to PURGE clients inactive more than 6 years from DMSArchive & DMS Stub Record
--And then delete the remaining STUB from DMS
--Ref sections 2.7.2 of DMS Solutions Archiving
--Created by: Jef Morris 19-Jan-2011

USE DMSArchive
GO

--exec PurgeDMSClients
', 
		@database_name=N'master', 
		@output_file_name=N'C:\ArchiveOutput\PurgeDMSClients.txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Set Success Flag]    Script Date: 08/29/2013 10:23:17 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Set Success Flag', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--End of Archive Process
--Last Job Step sets the success flag for the DMS Batch
--Created by: Jef Morris 28-Jan-2011

USE DMSArchive
GO

DECLARE @CurrentBatchNo INT
DECLARE @ArchivedCount INT
DECLARE @PurgedCount INT

SET @ArchivedCount = 0
SET @PurgedCount = 0

SELECT @CurrentBatchNo = BatchNo
FROM [Archive].[ArchiveBatch]
WHERE IsCurrent = 1

--UPDATE success flag for DMS batch to = 1
--ONLY IF ALL CLIENTS HAVE BEEN PROCESSED BY ARCHIVE AND PURGE...

SELECT @ArchivedCount = COUNT(*)
FROM Archive.ClientsToArchive
WHERE BatchNo = @CurrentBatchNo
AND ArchivedByDMS = 0

SELECT @PurgedCount = COUNT(*)
FROM Archive.ClientsToPurge
WHERE BatchNo = @CurrentBatchNo
AND PurgedByDMS = 0

IF @ArchivedCount = 0 AND @PurgedCount = 0
BEGIN
	UPDATE Archive.ArchiveBatch
	SET DMSSuccess = 1, IsCurrent = 0
	WHERE BatchNo = @CurrentBatchNo
END
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'APP DMS ARCHIVE CLIENTS', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=64, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20110223, 
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
