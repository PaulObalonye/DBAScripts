
/* --- 

Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -v Environment="'SYSTEST'" -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 2 - Data Scrambling.sql"

--- */
:on error exit
SET NOCOUNT ON
GO
SET ANSI_NULLS ON
GO
SET ANSI_WARNINGS ON
GO
PRINT 'Step 2 - Scramble Data - VisionBlue'

-- Script Provided bu VisionBlue
USE [VisionBlue_Training]

/*---------------------*/
--StepChange Scrambling Routine
/*---------------------*/

DECLARE @ClientEmail VARCHAR(255)
		, @HomeTelNo VARCHAR(16)
		, @WorkTelNo VARCHAR(16)
		, @MobTelNo VARCHAR(16)
		, @DataScramble BIT
		, @HouseNumber INT
		, @HouseName VARCHAR(50)
		, @AddressLine1 VARCHAR(255)
		, @AddressLine2 VARCHAR(255)
		, @AddressLine3 VARCHAR(255)
		, @AddressLine4 VARCHAR(255)
		, @PostCode VARCHAR(10)
		, @Environment VARCHAR(30)
		, @InsertLocation VARCHAR(200)
		, @DataRowCount INT
		, @DataScrambleName INT -- 1 = Yes Scramble Name
		, @DataScrambleAddress INT -- 1 = Yes Scramble Address

--SET DEFAULTS...

SET @ClientEmail = 'thisisadummyemail@notstepchange.co.na' --'no-reply@stepchange.org'
SET @HomeTelNo = '09999999999'
SET @WorkTelNo = '09999999999'
SET @MobTelNo = '09999999999'
SET @DataScramble = 1
SET @HouseNumber = ''
SET @HouseName = 'StepChange - Systems Department'
SET @AddressLine1 = 'Wade House'
SET @AddressLine2 = 'Merrion Centre'
SET @AddressLine3 = ''
SET @AddressLine4 = 'Leeds'
SET @PostCode = 'LS2 8NG'
SET @Environment = 'DEV'
SET @DataRowCount = 0
SET @DataScrambleName = 1
SET @DataScrambleAddress = 1

--Read the specific settings if available...
SELECT	@ClientEmail = EDV.ClientEmail
		, @HomeTelNo = EDV.TelNo
		, @WorkTelNo = EDV.TelNo
		, @MobTelNo = EDV.MobileNo
		, @DataScramble = EDV.DataScramble
		, @HouseNumber = EDV.HouseNo
		, @HouseName = EDV.HouseName
		, @AddressLine1 = EDV.AddressLine1
		, @AddressLine2 = EDV.AddressLine2
		, @AddressLine3 = EDV.PostTown
		, @AddressLine4 = EDV.Region
		, @PostCode = EDV.PostCode
		, @DataScrambleName = EDV.DataScrambleName
		, @DataScrambleAddress = EDV.DataScrambleAddress

FROM EnviroDataLinkedServer.DataScramble.dbo.EnviroDataValues EDV
WHERE Environment = @Environment

SET @DataRowCount = @@Rowcount


ALTER TABLE TBL_COMPANY DISABLE TRIGGER ALL
ALTER TABLE TBL_PERSONAL DISABLE TRIGGER ALL
ALTER TABLE TBL_PERSONAL_PROPERTY DISABLE TRIGGER ALL


UPDATE TBL_PERSONAL
SET 
			    EMAIL = @ClientEmail,
                MIDDLE_NAME = CASE WHEN MIDDLE_NAME IS NOT NULL OR MIDDLE_NAME <> '' THEN SystemsHelpDesk.dbo.[FN_ScrambleName](MIDDLE_NAME,0) END,
                SURNAME = CASE WHEN SURNAME IS NOT NULL OR SURNAME <> '' THEN SystemsHelpDesk.dbo.[FN_ScrambleName](SURNAME,0) END,
				MAIDEN_NAME = CASE WHEN MAIDEN_NAME IS NOT NULL OR MAIDEN_NAME <> '' THEN SystemsHelpDesk.dbo.[FN_ScrambleName](MAIDEN_NAME,0) END, 
				[ALIASES] = NULL,
                ADDRESS_LINE_1 = CASE WHEN ADDRESS_LINE_1 IS NOT NULL OR ADDRESS_LINE_1 <> '' THEN @HouseNumber END,
                ADDRESS_LINE_2 = CASE WHEN ADDRESS_LINE_2 IS NOT NULL OR ADDRESS_LINE_2 <> '' THEN @AddressLine1 END,
                ADDRESS_CITY = CASE WHEN ADDRESS_CITY IS NOT NULL OR ADDRESS_CITY <> '' THEN @AddressLine2 END,
                ADDRESS_COUNTY = CASE WHEN ADDRESS_CITY IS NOT NULL OR ADDRESS_CITY <> '' THEN @AddressLine3 END,
                ADDRESS_COUNTRY = CASE WHEN ADDRESS_COUNTRY IS NOT NULL OR ADDRESS_COUNTRY <> '' THEN @AddressLine4 END ,
                PARTNER_FIRST_NAME = PARTNER_FIRST_NAME,
                PARTNER_MIDDLE_NAME = CASE WHEN PARTNER_MIDDLE_NAME IS NOT NULL OR PARTNER_MIDDLE_NAME <> '' THEN SystemsHelpDesk.dbo.[FN_ScrambleName](PARTNER_MIDDLE_NAME,0) END,
                PARTNER_MAIDEN_NAME = CASE WHEN PARTNER_MAIDEN_NAME IS NOT NULL OR PARTNER_MAIDEN_NAME <> '' THEN SystemsHelpDesk.dbo.[FN_ScrambleName](PARTNER_MAIDEN_NAME,0) END,
                PARTNER_SURNAME = CASE WHEN PARTNER_SURNAME IS NOT NULL OR PARTNER_SURNAME <> '' THEN SystemsHelpDesk.dbo.[FN_ScrambleName](PARTNER_SURNAME,0) END,
                PARTNER_ADDRESS_LINE_1 = CASE WHEN PARTNER_ADDRESS_LINE_1 IS NOT NULL OR PARTNER_ADDRESS_LINE_1 <> '' THEN @HouseNumber END,
                PARTNER_ADDRESS_LINE_2 = CASE WHEN PARTNER_ADDRESS_LINE_2 IS NOT NULL OR PARTNER_ADDRESS_LINE_2 <> '' THEN @AddressLine1 END,
                PARTNER_ADDRESS_CITY = CASE WHEN PARTNER_ADDRESS_CITY IS NOT NULL OR PARTNER_ADDRESS_CITY <> '' THEN @AddressLine2 END,
                PARTNER_ADDRESS_COUNTY = CASE WHEN PARTNER_ADDRESS_COUNTY IS NOT NULL OR PARTNER_ADDRESS_COUNTY <> '' THEN @AddressLine3 END,
                PARTNER_ADDRESS_COUNTRY = CASE WHEN PARTNER_ADDRESS_COUNTRY IS NOT NULL OR PARTNER_ADDRESS_COUNTRY <> '' THEN @AddressLine4 END,
                PARTNER_EMAIL = @ClientEmail


UPDATE TBP
SET  WORK_TELEPHONE = 	CASE  
		WHEN PATINDEX('%[^0-9]%',WORK_TELEPHONE) =1 THEN SUBSTRING(WORK_TELEPHONE,1,(PATINDEX('%[^0-9]%',WORK_TELEPHONE))) + '0'
		+ SUBSTRING((SystemsHelpDesk.dbo.fn_Replace0to8(WORK_TELEPHONE)),(PATINDEX('%[^0-9]%',WORK_TELEPHONE))+2,(LEN(WORK_TELEPHONE))) COLLATE SQL_Latin1_General_CP1_CI_AS 
		ELSE '0' + SUBSTRING((SystemsHelpDesk.dbo.fn_Replace0to8(WORK_TELEPHONE)),2,LEN(WORK_TELEPHONE)-1) COLLATE SQL_Latin1_General_CP1_CI_AS 
		END
		from TBL_PERSONAL TBP
		WHERE WORK_TELEPHONE IS NOT NULL AND REPLACE(WORK_TELEPHONE,' ','') <> ''


UPDATE TBP
SET  [HOME_TELEPHONE] = 	CASE  
		WHEN PATINDEX('%[^0-9]%',[HOME_TELEPHONE]) =1 THEN SUBSTRING([HOME_TELEPHONE],1,(PATINDEX('%[^0-9]%',[HOME_TELEPHONE]))) + '0'
		+ SUBSTRING((SystemsHelpDesk.dbo.fn_Replace0to8([HOME_TELEPHONE])),(PATINDEX('%[^0-9]%',[HOME_TELEPHONE]))+2,(LEN([HOME_TELEPHONE]))) COLLATE SQL_Latin1_General_CP1_CI_AS 
		ELSE '0' + SUBSTRING((SystemsHelpDesk.dbo.fn_Replace0to8([HOME_TELEPHONE])),2,LEN([HOME_TELEPHONE])-1) COLLATE SQL_Latin1_General_CP1_CI_AS 
		END
		from TBL_PERSONAL TBP
		WHERE [HOME_TELEPHONE] IS NOT NULL AND REPLACE([HOME_TELEPHONE],' ','') <> ''


UPDATE TBP
SET  [MOBILE] = 	CASE  
		WHEN PATINDEX('%[^0-9]%',[MOBILE]) =1 THEN SUBSTRING([MOBILE],1,(PATINDEX('%[^0-9]%',[MOBILE]))) + '0'
		+ SUBSTRING((SystemsHelpDesk.dbo.fn_Replace0to8([MOBILE])),(PATINDEX('%[^0-9]%',[MOBILE]))+2,(LEN([MOBILE]))) COLLATE SQL_Latin1_General_CP1_CI_AS 
		ELSE '0' + SUBSTRING((SystemsHelpDesk.dbo.fn_Replace0to8([MOBILE])),2,LEN([MOBILE])-1) COLLATE SQL_Latin1_General_CP1_CI_AS 
		END
		from TBL_PERSONAL TBP
		WHERE [MOBILE] IS NOT NULL AND REPLACE([MOBILE],' ','') <> ''


UPDATE TBP
SET  [FAX] = 	CASE  
		WHEN PATINDEX('%[^0-9]%',[FAX]) =1 THEN SUBSTRING([FAX],1,(PATINDEX('%[^0-9]%',[FAX]))) + '0'
		+ SUBSTRING((SystemsHelpDesk.dbo.fn_Replace0to8([FAX])),(PATINDEX('%[^0-9]%',[FAX]))+2,(LEN([FAX]))) COLLATE SQL_Latin1_General_CP1_CI_AS 
		ELSE '0' + SUBSTRING((SystemsHelpDesk.dbo.fn_Replace0to8([FAX])),2,LEN([FAX])-1) COLLATE SQL_Latin1_General_CP1_CI_AS 
		END
		from TBL_PERSONAL TBP
		WHERE [FAX] IS NOT NULL AND REPLACE([FAX],' ','') <> ''


UPDATE TBP
SET  [PARTNER_HOME_TELEPHONE] = 	CASE  
		WHEN PATINDEX('%[^0-9]%',[PARTNER_HOME_TELEPHONE]) =1 THEN SUBSTRING([PARTNER_HOME_TELEPHONE],1,(PATINDEX('%[^0-9]%',[PARTNER_HOME_TELEPHONE]))) + '0'
		+ SUBSTRING((SystemsHelpDesk.dbo.fn_Replace0to8([PARTNER_HOME_TELEPHONE])),(PATINDEX('%[^0-9]%',[PARTNER_HOME_TELEPHONE]))+2,(LEN([PARTNER_HOME_TELEPHONE]))) COLLATE SQL_Latin1_General_CP1_CI_AS 
		ELSE '0' + SUBSTRING((SystemsHelpDesk.dbo.fn_Replace0to8([PARTNER_HOME_TELEPHONE])),2,LEN([PARTNER_HOME_TELEPHONE])-1) COLLATE SQL_Latin1_General_CP1_CI_AS 
		END
		from TBL_PERSONAL TBP
		WHERE [PARTNER_HOME_TELEPHONE] IS NOT NULL AND REPLACE([PARTNER_HOME_TELEPHONE],' ','') <> ''


UPDATE TBP
SET  [PARTNER_WORK_TELEPHONE] = 	CASE  
		WHEN PATINDEX('%[^0-9]%',[PARTNER_WORK_TELEPHONE]) =1 THEN SUBSTRING([PARTNER_WORK_TELEPHONE],1,(PATINDEX('%[^0-9]%',[PARTNER_WORK_TELEPHONE]))) + '0'
		+ SUBSTRING((SystemsHelpDesk.dbo.fn_Replace0to8([PARTNER_WORK_TELEPHONE])),(PATINDEX('%[^0-9]%',[PARTNER_WORK_TELEPHONE]))+2,(LEN([PARTNER_WORK_TELEPHONE]))) COLLATE SQL_Latin1_General_CP1_CI_AS 
		ELSE '0' + SUBSTRING((SystemsHelpDesk.dbo.fn_Replace0to8([PARTNER_WORK_TELEPHONE])),2,LEN([PARTNER_WORK_TELEPHONE])-1) COLLATE SQL_Latin1_General_CP1_CI_AS 
		END
		from TBL_PERSONAL TBP
		WHERE [PARTNER_WORK_TELEPHONE] IS NOT NULL AND REPLACE([PARTNER_WORK_TELEPHONE],' ','') <> ''


UPDATE TBP
SET  [PARTNER_MOBILE] = 	CASE  
		WHEN PATINDEX('%[^0-9]%',[PARTNER_MOBILE]) =1 THEN SUBSTRING([PARTNER_MOBILE],1,(PATINDEX('%[^0-9]%',[PARTNER_MOBILE]))) + '0'
		+ SUBSTRING((SystemsHelpDesk.dbo.fn_Replace0to8([PARTNER_MOBILE])),(PATINDEX('%[^0-9]%',[PARTNER_MOBILE]))+2,(LEN([PARTNER_MOBILE]))) COLLATE SQL_Latin1_General_CP1_CI_AS 
		ELSE '0' + SUBSTRING((SystemsHelpDesk.dbo.fn_Replace0to8([PARTNER_MOBILE])),2,LEN([PARTNER_MOBILE])-1) COLLATE SQL_Latin1_General_CP1_CI_AS 
		END
		from TBL_PERSONAL TBP
		WHERE [PARTNER_MOBILE] IS NOT NULL AND REPLACE([PARTNER_MOBILE],' ','') <> ''


UPDATE TBP
SET  [PARTNER_FAX] = 	CASE  
		WHEN PATINDEX('%[^0-9]%',[PARTNER_FAX]) =1 THEN SUBSTRING([PARTNER_FAX],1,(PATINDEX('%[^0-9]%',[PARTNER_FAX]))) + '0'
		+ SUBSTRING((SystemsHelpDesk.dbo.fn_Replace0to8([PARTNER_FAX])),(PATINDEX('%[^0-9]%',[PARTNER_FAX]))+2,(LEN([PARTNER_FAX]))) COLLATE SQL_Latin1_General_CP1_CI_AS 
		ELSE '0' + SUBSTRING((SystemsHelpDesk.dbo.fn_Replace0to8([PARTNER_FAX])),2,LEN([PARTNER_FAX])-1) COLLATE SQL_Latin1_General_CP1_CI_AS 
		END
		from TBL_PERSONAL TBP
		WHERE [PARTNER_FAX] IS NOT NULL AND REPLACE([PARTNER_FAX],' ','') <> ''

UPDATE TBP
SET  [NUMBER] = 	CASE  
		WHEN PATINDEX('%[^0-9]%',[NUMBER]) =1 THEN SUBSTRING([NUMBER],1,(PATINDEX('%[^0-9]%',[NUMBER]))) + '0'
		+ SUBSTRING((SystemsHelpDesk.dbo.fn_Replace0to8([NUMBER])),(PATINDEX('%[^0-9]%',[NUMBER]))+2,(LEN([NUMBER]))) COLLATE SQL_Latin1_General_CP1_CI_AS 
		ELSE '0' + SUBSTRING((SystemsHelpDesk.dbo.fn_Replace0to8([NUMBER])),2,LEN([NUMBER])-1) COLLATE SQL_Latin1_General_CP1_CI_AS 
		END
		from TBL_TELEPHONY_NUMBERS TBP
		WHERE [NUMBER] IS NOT NULL AND REPLACE([NUMBER],' ','') <> ''



UPDATE TBL_PERSONAL_PROPERTY
SET ADDRESS_LINE_1 = CASE WHEN ADDRESS_LINE_1 IS NOT NULL OR ADDRESS_LINE_1 <> '' THEN @HouseNumber END,
                ADDRESS_LINE_2 = CASE WHEN ADDRESS_LINE_2 IS NOT NULL OR ADDRESS_LINE_2 <> '' THEN @AddressLine1 END,
                ADDRESS_CITY = CASE WHEN ADDRESS_CITY IS NOT NULL OR ADDRESS_CITY <> '' THEN @AddressLine2 END,
                ADDRESS_COUNTY = CASE WHEN ADDRESS_CITY IS NOT NULL OR ADDRESS_CITY <> '' THEN @AddressLine3 END,
                ADDRESS_COUNTRY = CASE WHEN ADDRESS_COUNTRY IS NOT NULL OR ADDRESS_COUNTRY <> '' THEN @AddressLine4 END


ALTER TABLE TBL_PERSONAL ENABLE TRIGGER TRG_UPDATE_PERSONAL_COMPANY_NAME

UPDATE TBL_PERSONAL
SET FIRST_NAME = FIRST_NAME

ALTER TABLE TBL_COMPANY ENABLE TRIGGER ALL
ALTER TABLE TBL_PERSONAL ENABLE TRIGGER ALL
ALTER TABLE TBL_PERSONAL_PROPERTY ENABLE TRIGGER ALL

     
DECLARE @VAEmailAddress VARCHAR(50)
SET @VAEmailAddress = 'VAHelpdesk@stepchange.org'
 
UPDATE [dbo].[TBL_CREDITOR_HEADER]
SET [EMAIL_ADDRESS] =  CASE WHEN [EMAIL_ADDRESS] IS NOT NULL OR [EMAIL_ADDRESS] <> '' THEN @VAEmailAddress END
            ,[REMITTANCE_EMAIL_ADDRESS] =  CASE WHEN [REMITTANCE_EMAIL_ADDRESS] IS NOT NULL OR [REMITTANCE_EMAIL_ADDRESS] <> '' THEN @VAEmailAddress END

		
UPDATE [dbo].[TBL_COMMON_CREDITORS]
SET [REMITTANCE_EMAIL_ADDRESS] =  CASE WHEN [REMITTANCE_EMAIL_ADDRESS] IS NOT NULL OR [REMITTANCE_EMAIL_ADDRESS] <> '' THEN @VAEmailAddress END