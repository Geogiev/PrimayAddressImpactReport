USE [Data_Quality_Reporting]
GO

/****** Object:  View [dbo].[primary_address_territory_movement]    Script Date: 12/16/2019 3:28:37 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



ALTER view [dbo].[primary_address_territory_movement] as
With old_addr as
(
	select
		b.Name user_profile_old,
		b.createddate createddate_old,
		b.parentid parentid_old,
		a.PRIMARY_VOD__C PRIMARY_VOD__C_old,
		a.ACCOUNT_VOD__C ACCOUNT_VOD__C_old,
		upper(a.name) street_1_Old,
		upper(a.[ADDRESS_LINE_2_VOD__C]) street_2_Old,
		upper(a.[CITY_VOD__C]) city_old,
		upper(a.[STATE_VOD__C]) State_Old,
		a.[ZIP_VOD__C] Zip_old,
		a.INACTIVE_VOD__C INACTIVE_VOD__C_old,
		d.Territory_ID Territory_ID_old,
		d.Team TEAM_Old
	from
		(
		select
			a.*,
			c.name
		from
			[Veeva_Replication].[V2_rep].[SF_ADDRESS_VOD__HISTORY] a
		join [Veeva_Replication].[V2_rep].[SF_USER] b on
			(a.[CREATEDBYID] = b.id)
		join [Veeva_Replication].[V2_rep].[SF_PROFILE] c on
			(c.id = b.PROFILEID)
			--c.name = 'B+L US Sales Rep' --Chnaged BY GV 06/11/2019
			Where A.FIELD = 'Primary_vod__c'
			and a.oldvalue = 'true'
			and a.[CREATEDDATE] >= '2018-09-24 00:00:00.000' ) b
	left outer join [Veeva_Replication].[V2_rep].[SF_ADDRESS_VOD__C] a on
		(b.parentid = a.id)
		and a.INACTIVE_VOD__C = 0
	left outer join [Data_Quality_Reporting].[dbo].[ZipTerr_V2] d on
		d.Zipcode = a.ZIP_VOD__C
		and Quarter = (
		select
			max(quarter)
		from
			[Data_Quality_Reporting].[dbo].[ZipTerr_V2] ) 
),
new_addr as
(
select
		b.name user_profile_new,
		b.createddate createddate_new,
		b.parentid parentid_new,
		a.PRIMARY_VOD__C PRIMARY_VOD__C_new,
		a.ACCOUNT_VOD__C ACCOUNT_VOD__C_new,
		upper(a.name) street_1_new,
		upper(a.[ADDRESS_LINE_2_VOD__C]) street_2_new,
		upper(a.[CITY_VOD__C]) city_new,
		upper(a.[STATE_VOD__C]) State_new,
		a.[ZIP_VOD__C] Zip_new,
		a.INACTIVE_VOD__C INACTIVE_VOD__C_new,
		d.Territory_ID Territory_ID_new,
		d.Team Team_new
	from
		(
		select
			a.*,
			c.name
		from
			[Veeva_Replication].[V2_rep].[SF_ADDRESS_VOD__HISTORY] a
		join [Veeva_Replication].[V2_rep].[SF_USER] b on
			(a.[CREATEDBYID] = b.id)
		join [Veeva_Replication].[V2_rep].[SF_PROFILE] c on
			(c.id = b.PROFILEID)
			--c.name = 'B+L US Sales Rep'  --Chnaged BY GV 06/11/2019
			Where A.FIELD = 'Primary_vod__c'
			and a.newvalue = 'true'
			and a.[CREATEDDATE] >= '2018-09-24 00:00:00.000' ) b
	left outer join [Veeva_Replication].[V2_rep].[SF_ADDRESS_VOD__C] a on
		(b.parentid = a.id)
		and INACTIVE_VOD__C = 0
	left outer join [Data_Quality_Reporting].[dbo].[ZipTerr_V2] d on
		d.Zipcode = a.ZIP_VOD__C
		and Quarter = (
		select
			max(quarter)
		from
			[Data_Quality_Reporting].[dbo].[ZipTerr_V2] )
),
Curr_addr as (
select
	null user_profile_curr,
	null createddate_curr,
	null parentid_curr,
	c.Primary_vod__c PRIMARY_VOD__C_curr,
	c.ACCOUNT_VOD__C ACCOUNT_VOD__C_curr,
	upper(c.name) street_1_curr,
	upper(c.[ADDRESS_LINE_2_VOD__C]) street_2_curr,
	upper(c.[CITY_VOD__C]) city_curr,
	upper(c.[STATE_VOD__C]) State_curr,
	c.[ZIP_VOD__C] Zip_curr,
	c.INACTIVE_VOD__C INACTIVE_VOD__C_curr,
	d.Territory_ID Territory_ID_curr,
	d.team Team_Curr
from
	[Veeva_Replication].V2_rep.[SF_ADDRESS_VOD__C] c
left outer join [Data_Quality_Reporting].[dbo].[ZipTerr_V2] d on
	cast(d.Zipcode as int) = cast(c.ZIP_VOD__C as int)
	and quarter = (
	select
		max(quarter)
	from
		ZipTerr_V1)
	and team in ('Team 1','Team 2')
where
	PRIMARY_Vod__C = 1 
),
New_addr2 as (
select
	*
from
	New_addr
union
select
	*
from
	Curr_addr
where
	not exists (
	select
		1
	from
		New_addr
	where
		new_addr.ACCOUNT_VOD__C_new = curr_addr.ACCOUNT_VOD__C_curr)
	and exists(
	select
		1
	from
		old_addr
	where
		old_addr.ACCOUNT_VOD__C_old = curr_addr.ACCOUNT_VOD__C_curr ) 
),
V2 as
(
select
		b.IMS_ID__C IMS_ID_V2,
		b.REL_ID__C HCE_ID_V2,
		b.npi_vod__c NPI_ID_V2,
		b.Id BL_SFID_V2,
		b.ACCOUNT_STATUS__C STATUS_V2,
		b.lastname last_name_V2,
		b.firstname first_name_V2,
		b.credentials_vod__c DegreeDesc_V2,
		b.PDRP_OPT_OUT_VOD__C PDRP_V2,
		b.[SPECIALTY_1_VOD__C] PrimarySpecialtyDesc_V2
	from
		[Veeva_Replication].[V2_rep].[SF_ACCOUNT] b
	where
		b.ispersonaccount = 1
),
terr_data as
(
select
		*,
		case
			when [Territory_vod__c] like '%T1%' then 'Team 1'
			when [Territory_vod__c] like '%T2%' then 'Team 2'
			else ''
		end SALES_TEAM__C
	from
		(
		SELECT
			ACCOUNTID account_vod__c,
			replace(Split.a.value('.', 'VARCHAR(100)'), '#', '&') AS Territory_vod__c
		FROM
			(
			SELECT
				ACCOUNTID,
				CAST ('<M>' + REplace(REPLACE(Territory, ';', '</M><M>'), '&', '#')+ '</M>' AS XML) AS String
			FROM
				 Data_Quality_Reporting.dbo.PBI_TERR_ALIGNMENT_V2) AS A CROSS APPLY String.nodes ('/M') AS Split(a)
		WHERE
			Split.a.value('.',
			'VARCHAR(100)') != ''
		) t
)
select
	distinct Old_addr.*,
	New_addr2.user_profile_new,
	New_addr2.createddate_new,
	New_addr2.parentid_new,
	New_addr2.PRIMARY_VOD__C_new,
	New_addr2.ACCOUNT_VOD__C_new,
	New_addr2.street_1_new,
	New_addr2.street_2_new,
	New_addr2.city_new,
	New_addr2.State_new,
	New_addr2.Zip_new,
	New_addr2.INACTIVE_VOD__C_new,
	New_addr2.Territory_ID_new,
	New_addr2.Team_new,
	v2.*,
	C.*,
	case
		when coalesce(Old_addr.ACCOUNT_VOD__C_old,
		New_addr2.ACCOUNT_VOD__C_new) is null then 'Record missing'
		else 'Record Exist'
	end Record_status,
	case
		when coalesce(Old_addr.ACCOUNT_VOD__C_old,
		New_addr2.ACCOUNT_VOD__C_new) is null then 'Record not Updated'
		when coalesce(Old_addr.ACCOUNT_VOD__C_old,
		New_addr2.ACCOUNT_VOD__C_new) is not null
		and c.ACCOUNT_VOD__C is null then 'Not Aligned'
		when coalesce(Old_addr.ACCOUNT_VOD__C_old,
		New_addr2.ACCOUNT_VOD__C_new) is not null
		and c.ACCOUNT_VOD__C is not null then 'Aligned'
		else ''
	end Alinement_status,
	case
		when coalesce(Old_addr.ACCOUNT_VOD__C_old,
		New_addr2.ACCOUNT_VOD__C_new) is null then 'Record not Updated'
		--when isnull(Old_addr.ACCOUNT_VOD__C_old, New_Addr.ACCOUNT_VOD__C_new) is not null and c.ACCOUNT_VOD__C is null then 'Not Aligned'
		when coalesce(Old_addr.ACCOUNT_VOD__C_old,
		New_addr2.ACCOUNT_VOD__C_new) is not null
		and Old_addr.[Territory_ID_old] = New_addr2.Territory_ID_new
		and (Old_addr.[Territory_ID_old] is not null
		and New_addr2.Territory_ID_new is not null) then 'No change in the Territory'
		when coalesce(Old_addr.ACCOUNT_VOD__C_old,
		New_addr2.ACCOUNT_VOD__C_new) is not null
		and Old_addr.[Territory_ID_old] <> New_addr2.Territory_ID_new
		and (Old_addr.[Territory_ID_old] is not null
		and New_addr2.Territory_ID_new is not null) then 'Territory Change'
		when Old_addr.ACCOUNT_VOD__C_old is null
		and New_addr2.ACCOUNT_VOD__C_new is not null then 'Primary Flag Added'
		when Old_addr.ACCOUNT_VOD__C_old is not null
		and New_addr2.ACCOUNT_VOD__C_new is null then 'Primary Flag Removed'
		else ''
	end Territory_status
from
	Old_addr
full outer join New_addr2 on
	old_addr.ACCOUNT_VOD__C_old = New_addr2.ACCOUNT_VOD__C_new
	--Left Join V2 on COALESCE(New_addr.ACCOUNT_VOD__C_new,Curr_addr.ACCOUNT_VOD__C_curr) = v2.DS_SFID_V1
left join V2 on
	New_addr2.ACCOUNT_VOD__C_new = v2.BL_SFID_V2
left join Terr_data c on
	(coalesce(old_addr.ACCOUNT_VOD__C_old,
	New_addr2.ACCOUNT_VOD__C_new) = c.ACCOUNT_VOD__C
	and coalesce(old_addr.team_old,
	New_addr2.team_new) = c.SALES_TEAM__C)
GO


