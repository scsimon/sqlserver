USE [AdminTools]
GO

/**********************************************************************************************************
Script to get the backup date from the backup header file

https://dba.stackexchange.com/a/133939/95107
**********************************************************************************************************/

create procedure [dbo].[usp_GetBackupDateFromFile](@BackupFile as varchar(1000), @DT as datetime output) 
as 

--declare @BackupFile varchar(4000) = 'E:\LIVE\BU\Backup\paragon_dump.bak'
--declare @DT datetime 
declare @BackupDT datetime
declare @sql varchar(8000)
declare @ProductVersion NVARCHAR(128)
declare @ProductVersionNumber TINYINT

SET @ProductVersion = CONVERT(NVARCHAR(128),SERVERPROPERTY('ProductVersion'))
SET @ProductVersionNumber = SUBSTRING(@ProductVersion, 1, (CHARINDEX('.', @ProductVersion) - 1))

if object_id('AdminTools.dbo.tblBackupHeader') is not null drop table AdminTools.dbo.tblBackupHeader

set @sql = ''

-- THIS IS GENERIC FOR SQL SERVER 2008R2, 2012 and 2014
if @ProductVersionNumber in(10, 11, 12)
set @sql = @sql +'
create table AdminTools.dbo.tblBackupHeader
( 
    BackupName varchar(256),
    BackupDescription varchar(256),
    BackupType varchar(256),        
    ExpirationDate varchar(256),
    Compressed varchar(256),
    Position varchar(256),
    DeviceType varchar(256),        
    UserName varchar(256),
    ServerName varchar(256),
    DatabaseName varchar(256),
    DatabaseVersion varchar(256),        
    DatabaseCreationDate varchar(256),
    BackupSize varchar(256),
    FirstLSN varchar(256),
    LastLSN varchar(256),        
    CheckpointLSN varchar(256),
    DatabaseBackupLSN varchar(256),
    BackupStartDate varchar(256),
    BackupFinishDate varchar(256),        
    SortOrder varchar(256),
    CodePage varchar(256),
    UnicodeLocaleId varchar(256),
    UnicodeComparisonStyle varchar(256),        
    CompatibilityLevel varchar(256),
    SoftwareVendorId varchar(256),
    SoftwareVersionMajor varchar(256),        
    SoftwareVersionMinor varchar(256),
    SoftwareVersionBuild varchar(256),
    MachineName varchar(256),
    Flags varchar(256),        
    BindingID varchar(256),
    RecoveryForkID varchar(256),
    Collation varchar(256),
    FamilyGUID varchar(256),        
    HasBulkLoggedData varchar(256),
    IsSnapshot varchar(256),
    IsReadOnly varchar(256),
    IsSingleUser varchar(256),        
    HasBackupChecksums varchar(256),
    IsDamaged varchar(256),
    BeginsLogChain varchar(256),
    HasIncompleteMetaData varchar(256),        
    IsForceOffline varchar(256),
    IsCopyOnly varchar(256),
    FirstRecoveryForkID varchar(256),
    ForkPointLSN varchar(256),        
    RecoveryModel varchar(256),
    DifferentialBaseLSN varchar(256),
    DifferentialBaseGUID varchar(256),        
    BackupTypeDescription varchar(256),
    BackupSetGUID varchar(256),
    CompressedBackupSize varchar(256),'

-- THIS IS SPECIFIC TO SQL SERVER 2012
if @ProductVersionNumber in(11)
set @sql = @sql +'
    Containment varchar(256),'


-- THIS IS SPECIFIC TO SQL SERVER 2014
if @ProductVersionNumber in(12)
set @sql = @sql +'
    Containment tinyint, 
    KeyAlgorithm nvarchar(32), 
    EncryptorThumbprint varbinary(20), 
    EncryptorType nvarchar(32),'


--All versions (This field added to retain order by)
set @sql = @sql +'
    Seq int NOT NULL identity(1,1)
); 
'
exec (@sql)


set @sql = 'restore headeronly from disk = '''+ @BackupFile +'''' 

insert into AdminTools.dbo.tblBackupHeader 
exec(@sql)

select @DT = BackupStartDate from AdminTools.dbo.tblBackupHeader 

if object_id('AdminTools.dbo.tblBackupHeader') is not null drop table AdminTools.dbo.tblBackupHeader
GO


