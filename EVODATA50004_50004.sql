-- Create temp table for Opsgenie incident processing
USE [EVO_BACKOFFICE]
GO

IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'EZV_ADMIN' AND TABLE_NAME = 'E_OPSGENIE_INCIDENTS')) 
BEGIN 
DROP TABLE [EZV_ADMIN].[E_OPSGENIE_INCIDENTS]
END

Create table [EZV_ADMIN].[E_OPSGENIE_INCIDENTS]
(
poolGUID uniqueidentifier not null, -- group all the incidents returned in a call together
bProcessed bit,
incID nvarchar(255) primary key not null,
incTinyID nvarchar(100) ,
incCreatedDate nvarchar(50) ,
incMessage nvarchar(1000) ,
incPrio nvarchar(10) ,
incImpactStartDate nvarchar(50) ,
incLastUpdate nvarchar(50),
incStatus nvarchar(50) ,
incOwnerTeam nvarchar(100) ,
incWebForm nvarchar(1000) ,
incApiLink nvarchar(2000) ,
incResponders nvarchar(max),
incImpactedSrv nvarchar(max),
incTags nvarchar(max)
)

--Create temp table for responders
IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'EZV_ADMIN' AND TABLE_NAME = 'E_OPSGENIE_RESPONDERS')) 
BEGIN 
DROP TABLE [EZV_ADMIN].[E_OPSGENIE_RESPONDERS]
END
CREATE TABLE [EZV_ADMIN].[E_OPSGENIE_RESPONDERS](
	[incID] [nvarchar](255) NOT NULL,
	[respType] [nvarchar](30) NULL,
	[responderId] [nvarchar](100) NULL,
	[responderLabel] [nvarchar](255) NULL
	)

-- Create temp table for impacted services
IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'EZV_ADMIN' AND TABLE_NAME = 'E_OPSGENIE_IMPSRV')) 
BEGIN 
DROP TABLE [EZV_ADMIN].[E_OPSGENIE_IMPSRV]
END
CREATE TABLE [EZV_ADMIN].[E_OPSGENIE_IMPSRV](
	[incID] [nvarchar](255) NOT NULL,
	[serviceId] [nvarchar](100) NULL,
	[serviceLabel] [nvarchar](255) NULL
	)

-- Additional SD_REQUEST fields for Opsgenie data
IF NOT EXISTS ( SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[50004].[SD_REQUEST]') AND name = 'E_OPSG_RESPTEAMS')
  BEGIN
alter table [EVO_DATA50004].[50004].[SD_REQUEST] add  
  E_OPSG_RESPTEAMS nvarchar(max)
  END
  IF NOT EXISTS ( SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[50004].[SD_REQUEST]') AND name = 'E_OPSG_RESPUSERS')
  BEGIN
alter table [EVO_DATA50004].[50004].[SD_REQUEST] add  
  E_OPSG_RESPUSERS nvarchar(max)
  END
  IF NOT EXISTS ( SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[50004].[SD_REQUEST]') AND name = 'E_OPSG_IMPACTEDSRV')
  BEGIN
alter table [EVO_DATA50004].[50004].[SD_REQUEST] add  
  E_OPSG_IMPACTEDSRV nvarchar(max)
  END
  IF NOT EXISTS ( SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[50004].[SD_REQUEST]') AND name = 'E_OPSG_INCWEBFORM')
  BEGIN
alter table [EVO_DATA50004].[50004].[SD_REQUEST] add  
  E_OPSG_INCWEBFORM nvarchar(1000)
  END
  IF NOT EXISTS ( SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[50004].[SD_REQUEST]') AND name = 'E_OPSG_INCAPILINK')
  BEGIN
alter table [EVO_DATA50004].[50004].[SD_REQUEST] add  
  E_OPSG_INCAPILINK nvarchar(2000)
  END
   IF NOT EXISTS ( SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[50004].[SD_REQUEST]') AND name = 'E_OPSG_INCTINYID')
  BEGIN
alter table [EVO_DATA50004].[50004].[SD_REQUEST] add  
  E_OPSG_INCTINYID nvarchar(10)
  END
   IF NOT EXISTS ( SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[50004].[SD_REQUEST]') AND name = 'E_OPSG_INCCREATEDT_UT')
  BEGIN
alter table [EVO_DATA50004].[50004].[SD_REQUEST] add  
  E_OPSG_INCCREATEDT_UT datetime
  END
   IF NOT EXISTS ( SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[50004].[SD_REQUEST]') AND name = 'E_OPSG_INCLASUPDDT_UT')
  BEGIN
alter table [EVO_DATA50004].[50004].[SD_REQUEST] add  
  E_OPSG_INCLASUPDDT_UT datetime
  END
   IF NOT EXISTS ( SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[50004].[SD_REQUEST]') AND name = 'E_OPSG_INCIMPACTSTARTDT_UT')
  BEGIN
alter table [EVO_DATA50004].[50004].[SD_REQUEST] add  
  E_OPSG_INCIMPACTSTARTDT_UT datetime
  END
  IF NOT EXISTS ( SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[50004].[SD_REQUEST]') AND name = 'E_OPSG_TAGS')
  BEGIN
alter table [EVO_DATA50004].[50004].[SD_REQUEST] add  
  E_OPSG_TAGS nvarchar(max)
  END

-- Sproc to truncate temp incident table
  use [EVO_DATA50004] 
go 

IF EXISTS( SELECT 1 FROM sys.Objects WHERE object_ID = OBJECT_ID(N'[50004].[E_OPSG_TRUNC_TEMPDATA]' ) AND Type IN (N'P', N'PC'))
BEGIN
DROP PROCEDURE [50004].[E_OPSG_TRUNC_TEMPDATA]
END
GO

CREATE PROCEDURE [50004].[E_OPSG_TRUNC_TEMPDATA]  
AS 
begin 
set nocount on 
truncate table [EVO_BACKOFFICE].[EZV_ADMIN].[E_OPSGENIE_INCIDENTS]
END

-- SProc to Parse main Json
use [EVO_DATA50004] 

go 

IF EXISTS( SELECT 1 FROM sys.Objects WHERE object_ID = OBJECT_ID(N'[50004].[E_OPSG_JSON_PARSE]' ) AND Type IN (N'P', N'PC'))

BEGIN

DROP PROCEDURE [50004].[E_OPSG_JSON_PARSE]

END
GO

CREATE PROCEDURE [50004].[E_OPSG_JSON_PARSE] (@jsonData nvarchar(max), @guid uniqueidentifier) 

AS 

begin 

set nocount on 


insert into [EVO_BACKOFFICE].[EZV_ADMIN].[E_OPSGENIE_INCIDENTS] 
( poolGUID,
bProcessed,
incID ,
incTinyID  ,
incCreatedDate  ,
incMessage  ,
incPrio  ,
incImpactStartDate  ,
incLastUpdate ,
incStatus  ,
incOwnerTeam  ,
incWebForm ,
incApiLink  ,
incResponders ,
incImpactedSrv ,
incTags
) 
select @guid, 0, IncidentData.* from openjson(@jsonData) 

 with( 

 IncidentArray nvarchar(max) '$.data' as JSON 

 ) as m 

 cross apply openjson(m.IncidentArray) 

 with 

( 

incID nvarchar(255) '$.id',
incTinyID nvarchar(100) '$.tinyId',
incCreatedDate nvarchar(50) '$.createdAt',
incMessage nvarchar(1000) '$.message',
incPrio nvarchar(10) '$.priority',
incImpactStartDate nvarchar(50) '$.impactStartDate',
incLastUpdate nvarchar(50) '$.updatedAt',
incStatus nvarchar(50) '$.status',
incOwnerTeam nvarchar(100) '$.ownerTeam',
incWebForm nvarchar(1000) '$.links.web',
incApiLink nvarchar(2000) '$.links.api',
incResponders nvarchar(max) '$.responders' as json,
incImpactedSrv nvarchar(max) '$.impactedServices' as json,
incTags nvarchar(max) '$.tags' as json

) as incidentData

END
GO
-- note : call with EXEC [50004].[E_OPSG_JSON_PARSE] @jsonData , @guid

-- SProc to parse Service Array into Temp Service table
use [EVO_DATA50004] 
go 
IF EXISTS( SELECT 1 FROM sys.Objects WHERE object_ID = OBJECT_ID(N'[50004].[E_OPSG_SERVICES_PARSE]' ) AND Type IN (N'P', N'PC'))
BEGIN
DROP PROCEDURE [50004].[E_OPSG_SERVICES_PARSE]
END
GO
CREATE PROCEDURE [50004].[E_OPSG_SERVICES_PARSE] (@incID nvarchar(255), @jsonData nvarchar(max))
AS 
begin 
set nocount on 
insert into [EVO_BACKOFFICE].[EZV_ADMIN].[E_OPSGENIE_IMPSRV](
	[incID],
	[serviceId]	
	) 
select  @incID, value from openjson(@jsonData) 
end
go
-- note : call with EXEC [50004].[E_OPSG_SERVICES_PARSE] <incID>, <impacted service table as json>

-- SProc to parse Responders array into Temp Responders Table
use [EVO_DATA50004] 
go 
IF EXISTS( SELECT 1 FROM sys.Objects WHERE object_ID = OBJECT_ID(N'[50004].[E_OPSG_RESPONDERS_PARSE]' ) AND Type IN (N'P', N'PC'))
BEGIN
DROP PROCEDURE [50004].[E_OPSG_RESPONDERS_PARSE]
END
GO
CREATE PROCEDURE [50004].[E_OPSG_RESPONDERS_PARSE] (@incID nvarchar(255), @jsonData nvarchar(max))
AS 
begin 
set nocount on 
insert into [EVO_BACKOFFICE].[EZV_ADMIN].[E_OPSGENIE_RESPONDERS](
	[incID],
	[respType],
	[responderId]
	) 
select @incID, respData.respType, respData.respId  from OpenJson(@jsonData)
	with(RespArray nvarchar(max) '$' as json) 
	  as m
	cross apply  openjson (m.RespArray)
	with (
		respType nvarchar(30) '$.type'
		,respId nvarchar(100) '$.id') as RespData
end
go
-- note : call with EXEC [50004].[E_OPSG_RESPONDERS_PARSE] <incID>, <responders table as json>

-- Function to parse Service Name from Service Get Json
USE [EVO_DATA50004]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF EXISTS( SELECT 1 FROM sys.Objects WHERE object_ID = OBJECT_ID(N'[50004].[E_OPSG_SRV_PARSE]' ) AND Type IN (N'FN', N'IF', N'TF', N'FS', N'FT'  ) )
BEGIN
DROP FUNCTION [50004].[E_OPSG_SRV_PARSE]
END
GO

CREATE FUNCTION [50004].[E_OPSG_SRV_PARSE] (@json nvarchar(max))
RETURNS TABLE 
AS
RETURN
select top 1 left(srvName,255) as servicename from OpenJson(@json)
	with(ServiceData nvarchar(max) '$.data' as json) 
	  as m
	cross apply  openjson (m.ServiceData)
	with (srvName nvarchar(max) '$.name' )
GO
-- note : Call with SELECT top 1 serviceName from [50004].[E_OPSG_SRV_PARSE] (jsonstring)

-- Function to parse TeamName from Team Get Json
USE [EVO_DATA50004]
GO

IF EXISTS( SELECT 1 FROM sys.Objects WHERE object_ID = OBJECT_ID(N'[50004].[E_OPSG_TEAM_PARSE]' ) AND Type IN (N'FN', N'IF', N'TF', N'FS', N'FT'  ) )
BEGIN
DROP FUNCTION [50004].[E_OPSG_TEAM_PARSE]
END 
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [50004].[E_OPSG_TEAM_PARSE] (@json nvarchar(max))
RETURNS TABLE 
AS
RETURN
select top 1 name from OpenJson(@json)
	with(respData nvarchar(max) '$.data' as json) 
	  as m
	cross apply  openjson (m.respData)
	with (name nvarchar(255) '$.name' )
GO
-- note : call with SELECT top 1 name from [50004].[E_OPSG_TEAM_PARSE] (@json)

-- Function to parse userName from User Get Json
USE [EVO_DATA50004]
GO
IF EXISTS( SELECT 1 FROM sys.Objects WHERE object_ID = OBJECT_ID(N'[50004].[E_OPSG_USER_PARSE]' ) AND Type IN (N'FN', N'IF', N'TF', N'FS', N'FT'  ) )
BEGIN
DROP FUNCTION [50004].[E_OPSG_USER_PARSE]
END 
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [50004].[E_OPSG_USER_PARSE] (@json nvarchar(max))
RETURNS TABLE 
AS
RETURN
select top 1 ( isnull(fullname, '') + ' (' + isnull(e_mail,'') + ')' ) as userName from OpenJson(@json)
	with(respData nvarchar(max) '$.data' as json) 
	  as m
	cross apply  openjson (m.respData)
	with (e_mail nvarchar(255) '$.username',fullname nvarchar(255) '$.fullName'  )
GO
-- note : call with SELECT top 1 userName from [50004].[E_OPSG_USER_PARSE] (@json)

-- Function to concat impacted services
USE [EVO_DATA50004]
GO

IF EXISTS( SELECT 1 FROM sys.Objects WHERE object_ID = OBJECT_ID(N'[50004].[E_OPSG_SRVTABLE]' ) AND Type IN (N'FN', N'IF', N'TF', N'FS', N'FT'  ) )
BEGIN
DROP FUNCTION [50004].[E_OPSG_SRVTABLE]
END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [50004].[E_OPSG_SRVTABLE] (@requestID int) 
RETURNS NVarchar(4000) 
as
BEGIN
	declare @table nvarchar(4000)
	declare @srvName nvarchar(255)
	set @table = ''

    DECLARE srvCursor CURSOR FOR SELECT serviceLabel  from 
	  [EVO_DATA50004].[50004].sd_request sdr
	  inner join [EVO_BACKOFFICE].[EZV_ADMIN].[E_OPSGENIE_IMPSRV] impsrv
	  on impsrv.incID = sdr.EXTERNAL_REFERENCE
	  where sdr.request_id in (@requestID)
  OPEN  srvCursor
  FETCH NEXT FROM srvCursor INTO @srvName  
  set @table = isnull(@table, '') + isnull(@srvName,'')

  WHILE @@FETCH_STATUS = 0  
	BEGIN  
	FETCH NEXT FROM srvCursor INTO @srvName  
	    if (@@FETCH_STATUS = 0  ) begin set @table = @table + ' | ' + isnull(@srvName, '')  end
    END

	CLOSE srvCursor
	DEALLOCATE srvCursor
	return @table

END
GO
-- note : call with select [50004].[E_OPSG_SRVTABLE] (requestID)

-- Function to concat users and teams
USE [EVO_DATA50004]
GO
IF EXISTS( SELECT 1 FROM sys.Objects WHERE object_ID = OBJECT_ID(N'[50004].[E_OPSG_RESPTABLE]' ) AND Type IN (N'FN', N'IF', N'TF', N'FS', N'FT'  ) )
BEGIN
DROP FUNCTION [50004].[E_OPSG_RESPTABLE]
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [50004].[E_OPSG_RESPTABLE] (@requestID int, @respType nvarchar(30)) 
RETURNS NVarchar(4000) 
as
BEGIN
	declare @table nvarchar(4000)
	declare @itemName nvarchar(255)
	set @table = ''

    DECLARE responderCursor CURSOR FOR SELECT responderLabel  from 
	  [EVO_DATA50004].[50004].sd_request sdr
	  inner join [EVO_BACKOFFICE].[EZV_ADMIN].[E_OPSGENIE_RESPONDERS] responders
	  on responders.incID = sdr.EXTERNAL_REFERENCE
	  where sdr.request_id in (@requestID)
	  and respType = @respType
  OPEN  responderCursor
  FETCH NEXT FROM responderCursor INTO @itemName  
  set @table = isnull(@table, '') + isnull(@itemName,'')

  WHILE @@FETCH_STATUS = 0  
	BEGIN  
	FETCH NEXT FROM responderCursor INTO @itemName  
	    if (@@FETCH_STATUS = 0  ) begin set @table = @table + ' | ' + isnull(@itemName, '')  end
    END

	CLOSE responderCursor
	DEALLOCATE responderCursor
	return @table

END
GO
-- note : call with select [50004].[E_OPSG_RESPTABLE] (requestID, respType)

-- Function to concat tags
USE [EVO_DATA50004]
GO

IF EXISTS( SELECT 1 FROM sys.Objects WHERE object_ID = OBJECT_ID(N'[50004].[E_OPSG_TAGTABLE]' ) AND Type IN (N'FN', N'IF', N'TF', N'FS', N'FT'  ) )
BEGIN
DROP FUNCTION [50004].[E_OPSG_TAGTABLE]
END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [50004].[E_OPSG_TAGTABLE] (@requestID int) 
RETURNS NVarchar(max) 
as
BEGIN
	declare @table nvarchar(max)
	declare @srvName nvarchar(1000)
	declare @tmp nvarchar(max)
	set @table = ''

    set @tmp = 
	(
	  select eoi.incTags from 
	  [EVO_DATA50004].[50004].sd_request sdr 
	  inner join [EVO_BACKOFFICE].[EZV_ADMIN].[E_OPSGENIE_INCIDENTS] eoi 
	  on eoi.incID = sdr.external_reference 
	  where sdr.request_id = @requestID 
	)

  DECLARE srvCursor CURSOR FOR SELECT value  from openjson(@tmp)
	 
  OPEN  srvCursor
  FETCH NEXT FROM srvCursor INTO @srvName  
  set @table = isnull(@table, '') + isnull(@srvName,'')

  WHILE @@FETCH_STATUS = 0  
	BEGIN  
	FETCH NEXT FROM srvCursor INTO @srvName  
	    if (@@FETCH_STATUS = 0  ) begin set @table = @table + ' | ' + isnull(@srvName, '')  end
	END
	CLOSE srvCursor
	DEALLOCATE srvCursor
	return @table

END
GO
-- notes : call with select [50004].[E_OPSG_TAGTABLE] (requestID)






