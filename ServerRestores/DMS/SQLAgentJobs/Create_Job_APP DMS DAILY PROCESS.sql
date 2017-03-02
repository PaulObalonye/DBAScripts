USE [msdb]
GO
/****** Object:  Job [APP DMS DAILY PROCESS]    Script Date: 08/29/2013 10:39:25 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [APPLICATION]    Script Date: 08/29/2013 10:39:25 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'APPLICATION' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'APPLICATION'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'APP DMS DAILY PROCESS', 
		@enabled=0, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'SUMMARY
Create Creditor Payment notes, inform App Support on fail
Unlock Record Locks, deletes application locks
Export Xmit Control List
Auto post disbursement batch at end day 2
Set SuppressClientStatement flag based on DCS data
Daily Process, performs tidy up of DMS

INTERFACES
DMS: CRUD
DCSLive: R
msdb

SUPPORT NOTES
High priority if POST BATCH fails must fix that night
Can escalate to CPR (in hrs: 001-214-739-6151 / out: 001-214-385-1860) and App support
CPR may need DMS on CPRDBASERVER', 
		@category_name=N'APPLICATION', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [UK_Historical_Creditor_Payment_Notes]    Script Date: 08/29/2013 10:39:25 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'UK_Historical_Creditor_Payment_Notes', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'set nocount on

declare
    @batch_id varchar(10),
    @bank_acct_code char(1)

set rowcount 1
select
    @batch_id = bh.batchid
from batch_header bh
inner join disbursement_history dh on bh.batchid = dh.batchid
where bh.type = 4 
    and bh.status = 10
	and dh.scope = 0

-- must have a bank acct code to pass to the stored procedure
-- picking the first one in the table
select @bank_acct_code = id
from bank_acct_file
set rowcount 0


if @batch_id is not null and @bank_acct_code is not null
    begin

        exec dbo.UK_Historical_Creditor_Payment_Notes;

    end

', 
		@database_name=N'DMS', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Unlock Record Locks]    Script Date: 08/29/2013 10:39:25 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Unlock Record Locks', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SELECT * FROM record_locks WHERE process_lock_type NOT IN (3, 4)

UPDATE c
SET c.lock_maintenance_date = NULL
FROM client c
INNER JOIN record_locks rl ON c.client_id = rl.lock_record_id
WHERE rl.process_lock_type NOT IN (3, 4)

UPDATE c
SET c.lock_maintenance_date = NULL
FROM creditor c
INNER JOIN record_locks rl ON c.creditor_id = rl.lock_record_id
WHERE rl.process_lock_type NOT IN (3, 4)

DELETE FROM record_locks
WHERE process_lock_type NOT IN (3, 4)
', 
		@database_name=N'DMS', 
		@output_file_name=N'E:\SQLOutput\Unlocked_DMS_Locks.txt', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Email Unlocked Record Locks]    Script Date: 08/29/2013 10:39:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Email Unlocked Record Locks', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--EXEC msdb.dbo.sp_send_dbmail
		--@profile_name  = N''SQLMail''			
		--,@recipients	= ''SystemsDBATeam@stepchange.org''
		--,@importance = N''HIGH''
		--,@subject		= N''Unlocked DMS Record Locks''		
		--,@body_format	= N''TEXT''
		--,@body		= N''The attached file contains all the DMS records that were unlocked by the scheduled job.''
		--,@file_attachments	= N''E:\SQLOutput\Unlocked_DMS_Locks.txt''

', 
		@database_name=N'master', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Export Xmit Control List]    Script Date: 08/29/2013 10:39:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Export Xmit Control List', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'SSIS', 
		@command=N'/SQL "\ExportXmitControlList" /SERVER "VM01DMSPRODBA01" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E', 
		@database_name=N'master', 
		@output_file_name=N'E:\SQLOutput\Export_Xmit_Control_List.txt', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Auto Post DISB Batch]    Script Date: 08/29/2013 10:39:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Auto Post DISB Batch', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=8, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'set nocount on

declare
    @batch_id varchar(10),
    @bank_acct_code char(1)

set rowcount 1
select
    @batch_id = bh.batchid
from batch_header bh
inner join disbursement_history dh on bh.batchid = dh.batchid
where bh.type = 4 
    and bh.status = 10
	and dh.scope = 0

-- must have a bank acct code to pass to the stored procedure
-- picking the first one in the table
select @bank_acct_code = id
from bank_acct_file
set rowcount 0


if @batch_id is not null and @bank_acct_code is not null
    begin

        --  update process log with process status info
        INSERT INTO disbursement_process_log (batch_id, process_name, time_stamp, description)
        VALUES (@batch_id, ''Auto PostDisbursementBatch'', current_timestamp, ''Started'')
    
    
        exec DMS_DisbursementPostBatch @batch_id, @bank_acct_code
    
    
        --  update process log with process status info
        INSERT INTO disbursement_process_log (batch_id, process_name, time_stamp, description)
        VALUES (@batch_id, ''Auto PostDisbursementBatch'', current_timestamp, ''Finished'')

    end

', 
		@database_name=N'DMS', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [UK_DailyUpdateStatementFlag]    Script Date: 08/29/2013 10:39:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'UK_DailyUpdateStatementFlag', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=8, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE DMS
GO

exec UK_DailyUpdateStatementFlag
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Daily Process]    Script Date: 08/29/2013 10:39:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Daily Process', 
		@step_id=7, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=8, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @retVal int, @rc int
SET @retVal = 1
EXEC @retVal = DMS_DailyProcesses
--IF @retVal <> 0
--BEGIN
--EXEC @rc = master.dbo.xp_smtp_sendmail
    --@FROM       = N''LDSDMSPRO1DBA01.cccs.co.uk'',
    --@FROM_NAME  = N''SQL on LDSDMSPRO1DBA01'',
    --@TO         = N''SystemsDBATeam@stepchange.org; SystemsServiceDesk@stepchange.org'',
    --@priority   = N''HIGH'',
    --@subject    = N''The scheduled DMS_DailyProcesses job Failed on LDSDMSPRO1DBA01'',
    --@message    = N''Service Desk - Please raise an incident. DBAs - please investigate'',
    --@type       = N''text/plain'',
    --@server     = N''exchangeserver.cccs.co.uk''
--END




', 
		@database_name=N'DMS', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Fail Notification]    Script Date: 08/29/2013 10:39:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Fail Notification', 
		@step_id=8, 
		@cmdexec_success_code=0, 
		@on_success_action=2, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
--exec dbo.job_fail_notification @System=''DMS Solutions'',@Subsystem=''Daily Process'',@Message=''Production failed (reason unknown)''
', 
		@database_name=N'SystemsHelpDesk', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'8pm', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20061127, 
		@active_end_date=99991231, 
		@active_start_time=201500, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
