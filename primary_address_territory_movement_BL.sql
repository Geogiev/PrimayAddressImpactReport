USE [Data_Quality_Reporting]
GO

/****** Object:  View [dbo].[primary_address_territory_movement]    Script Date: 12/16/2019 12:52:15 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create view [dbo].[primary_address_territory_movement] as
select a1.*, b1.*, v2.*, c.*,
case 
when isnull(a1.ACCOUNT_VOD__C_old, b1.ACCOUNT_VOD__C_new) is null then 'Record missing'
else 'Record Exist' end Record_status,
case
when isnull(a1.ACCOUNT_VOD__C_old, b1.ACCOUNT_VOD__C_new) is null then 'Primary Flag Removed'
when isnull(a1.ACCOUNT_VOD__C_old, b1.ACCOUNT_VOD__C_new) is not null and c.ACCOUNT_VOD__C is null then 'Not Aligned'
when isnull(a1.ACCOUNT_VOD__C_old, b1.ACCOUNT_VOD__C_new) is not null and c.ACCOUNT_VOD__C is not null then 'Aligned'
else '' end Alinement_status,
case
when isnull(a1.ACCOUNT_VOD__C_old, b1.ACCOUNT_VOD__C_new) is null then 'Primary Flag Removed'
--when isnull(a1.ACCOUNT_VOD__C_old, b1.ACCOUNT_VOD__C_new) is not null and c.ACCOUNT_VOD__C is null then 'Not Aligned'
when isnull(a1.ACCOUNT_VOD__C_old, b1.ACCOUNT_VOD__C_new) is not null and a1.[Territory_ID_old] = b1.Territory_ID_new and (a1.[Territory_ID_old] is not null and b1.Territory_ID_new is not null) then 'No change in the Territory'
when isnull(a1.ACCOUNT_VOD__C_old, b1.ACCOUNT_VOD__C_new) is not null and a1.[Territory_ID_old] <> b1.Territory_ID_new and (a1.[Territory_ID_old] is not null and b1.Territory_ID_new is not null) then 'Territory Change'
when isnull(a1.ACCOUNT_VOD__C_old, b1.ACCOUNT_VOD__C_new) is not null and (a1.[Territory_ID_old] is null or b1.Territory_ID_new is null) then 'Primary Flag Removed'
else '' end Territory_status
from (select b.Name user_profile_old, b.createddate createddate_old, b.parentid parentid_old, a.PRIMARY_VOD__C PRIMARY_VOD__C_old, a.ACCOUNT_VOD__C ACCOUNT_VOD__C_old, upper(a.name) street_1_Old, upper(a.[ADDRESS_LINE_2_VOD__C]) street_2_Old, upper(a.[CITY_VOD__C]) city_old, upper(a.[STATE_VOD__C]) State_Old,
a.[ZIP_VOD__C] Zip_old,a.INACTIVE_VOD__C INACTIVE_VOD__C_old,d.Territory_ID Territory_ID_old, d.Team TEAM_Old from 
(select a.*, c.name from [Veeva_Replication].[V2_rep].[SF_ADDRESS_VOD__HISTORY] a
join [Veeva_Replication].[V2_rep].[SF_USER]  b
on (a.[CREATEDBYID]= b.id)
join [Veeva_Replication].[V2_rep].[SF_PROFILE] c
on (c.id = b.PROFILEID)
--c.name = 'B+L US Sales Rep' --Chnaged BY GV 06/11/2019 
Where A.FIELD = 'Primary_vod__c' and a.oldvalue = 'true' and 
a.[CREATEDDATE] >= '2018-09-24 00:00:00.000'
) b
left outer join [Veeva_Replication].[V2_rep].[SF_ADDRESS_VOD__C] a
on (b.parentid = a.id) and a.INACTIVE_VOD__C=0
left outer join  [Data_Quality_Reporting].[dbo].[ZipTerr_V2] d
on d.Zipcode = a.ZIP_VOD__C and  Quarter = (select max(quarter) from 
 [Data_Quality_Reporting].[dbo].[ZipTerr_V2] ) 
) a1
full outer join (select b.name user_profile_new, b.createddate createddate_new, b.parentid parentid_new, a.PRIMARY_VOD__C PRIMARY_VOD__C_new, a.ACCOUNT_VOD__C ACCOUNT_VOD__C_new, upper(a.name) street_1_new, upper(a.[ADDRESS_LINE_2_VOD__C]) street_2_new, upper(a.[CITY_VOD__C]) city_new, upper(a.[STATE_VOD__C]) State_new,
a.[ZIP_VOD__C] Zip_new,a.INACTIVE_VOD__C INACTIVE_VOD__C_new, d.Territory_ID Territory_ID_new, d.Team Team_new from 
(select a.*, c.name from [Veeva_Replication].[V2_rep].[SF_ADDRESS_VOD__HISTORY] a
join [Veeva_Replication].[V2_rep].[SF_USER]  b
on (a.[CREATEDBYID]= b.id)
join [Veeva_Replication].[V2_rep].[SF_PROFILE] c
on (c.id = b.PROFILEID)
--c.name = 'B+L US Sales Rep'  --Chnaged BY GV 06/11/2019
Where A.FIELD = 'Primary_vod__c' and a.newvalue = 'true' and 
a.[CREATEDDATE] >= '2018-09-24 00:00:00.000'
) b
left outer join [Veeva_Replication].[V2_rep].[SF_ADDRESS_VOD__C] a
on (b.parentid = a.id)  and INACTIVE_VOD__C=0
left outer join  [Data_Quality_Reporting].[dbo].[ZipTerr_V2] d
on d.Zipcode = a.ZIP_VOD__C and  Quarter =
(select max(quarter) from  [Data_Quality_Reporting].[dbo].[ZipTerr_V2] )
) b1
on(a1.ACCOUNT_VOD__C_old = b1.ACCOUNT_VOD__C_new
and a1.TEAM_Old = b1.Team_new)
left outer join (select b.IMS_ID__C IMS_ID_V2, 
b.REL_ID__C HCE_ID_V2,
b.npi_vod__c NPI_ID_V2,
b.Id BL_SFID_V2,
b.ACCOUNT_STATUS__C STATUS_V2,
b.lastname last_name_V2, 
b.firstname first_name_V2,
b.credentials_vod__c DegreeDesc_V2,
b.PDRP_OPT_OUT_VOD__C PDRP_V2, b.[SPECIALTY_1_VOD__C] PrimarySpecialtyDesc_V2
from [Veeva_Replication].[V2_rep].[SF_ACCOUNT] b
where b.ispersonaccount=1) v2
  on (isnull(a1.ACCOUNT_VOD__C_old, b1.ACCOUNT_VOD__C_new) = v2.BL_SFID_V2)
left outer join (select *, case
when [Territory_vod__c] like '%T1%'  then 'Team 1'
when [Territory_vod__c] like '%T2%'  then 'Team 2'
else '' end SALES_TEAM__C from (SELECT account_vod__c, replace(Split.a.value('.', 'VARCHAR(100)'),'#','&') AS Territory_vod__c  
 FROM (SELECT account_vod__c, CAST ('<M>' + REplace(REPLACE(Territory_vod__c, ';', '</M><M>'),'&', '#')+ '</M>' AS XML) AS String 
 FROM [Veeva_Replication].[v2_rep].[SF_ACCOUNT_TERRITORY_LOADER_VOD__C]) AS A CROSS APPLY String.nodes ('/M') AS Split(a)
WHERE Split.a.value('.', 'VARCHAR(100)') !='') t) c
on (isnull(a1.ACCOUNT_VOD__C_old, b1.ACCOUNT_VOD__C_new) = c.ACCOUNT_VOD__C
and isnull(a1.team_old, b1.team_new) = c.SALES_TEAM__C)


GO


