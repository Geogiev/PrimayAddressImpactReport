USE [Data_Quality_Reporting]
GO

/****** Object:  View [dbo].[primary_address_territory_movement_Derm]    Script Date: 12/16/2019 11:56:51 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE    view [dbo].[primary_address_territory_movement_Derm] as
 select
	a1.*,
	b1.*,
	v2.*,
	c.*,
	case
		when isnull(a1.ACCOUNT_VOD__C_old,
		b1.ACCOUNT_VOD__C_new) is null then 'Record missing'
		else 'Record Exist'
	end Record_status,
	case
		when isnull(a1.ACCOUNT_VOD__C_old,
		b1.ACCOUNT_VOD__C_new) is null then 'Record not Updated'
		when isnull(a1.ACCOUNT_VOD__C_old,
		b1.ACCOUNT_VOD__C_new) is not null
		and c.ACCOUNT_VOD__C is null then 'Not Aligned'
		when isnull(a1.ACCOUNT_VOD__C_old,
		b1.ACCOUNT_VOD__C_new) is not null
		and c.ACCOUNT_VOD__C is not null then 'Aligned'
		else ''
	end Alinement_status,
	case
		when isnull(a1.ACCOUNT_VOD__C_old,
		b1.ACCOUNT_VOD__C_new) is null then 'Record not Updated'
		--when isnull(a1.ACCOUNT_VOD__C_old, b1.ACCOUNT_VOD__C_new) is not null and c.ACCOUNT_VOD__C is null then 'Not Aligned'
		when isnull(a1.ACCOUNT_VOD__C_old,
		b1.ACCOUNT_VOD__C_new) is not null
		and a1.[Territory_ID_old] = b1.Territory_ID_new
		and (a1.[Territory_ID_old] is not null
		and b1.Territory_ID_new is not null) then 'No change in the Territory'
		when isnull(a1.ACCOUNT_VOD__C_old,
		b1.ACCOUNT_VOD__C_new) is not null
		and a1.[Territory_ID_old] <> b1.Territory_ID_new
		and (a1.[Territory_ID_old] is not null
		and b1.Territory_ID_new is not null) then 'Territory Change'
		when a1.ACCOUNT_VOD__C_old is null
		and b1.ACCOUNT_VOD__C_new is not null then 'Primary Flag Added'
		when a1.ACCOUNT_VOD__C_old is not null
		and b1.ACCOUNT_VOD__C_new is null then 'Primary Flag Removed'
		else ''
	end Territory_status
from
	(
		select b.Name user_profile_old,
		b.createddate createddate_old,
		b.parentid parentid_old,
		a.Primary_Address_Derm__c PRIMARY_VOD__C_old,
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
			select a.*,
			c.name
		from
			Veeva_Replication.[db_owner].[SF_ADDRESS_VOD__HISTORY] a
		join [Veeva_Replication].[db_owner].[SF_USER] b on
			(a.[CREATEDBYID] = b.id)
		join [Veeva_Replication].db_owner.[SF_PROFILE] c on
			(c.id = b.PROFILEID)
		where
			c.name not in ('Bauschhealth - DataSteward',
			'Bauschhealth - DCR',
			'System Administrator',
			'Bauschhealth - Sales Operations')
			and a.field in ('Primary_Address_Derm__c')
			and a.oldvalue = 'true'
			and a.[CREATEDDATE] >= '2018-10-01 00:00:00.000') b
	left outer join [Veeva_Replication].[db_owner].[SF_ADDRESS_VOD__C] a on
		(b.parentid = a.id)
		and a.INACTIVE_VOD__C = 0
	left outer join [Data_Quality_Reporting].[dbo].[ZipTerr_V1] d on
		cast(d.Zipcode as int) = cast(a.ZIP_VOD__C as int)
		and Quarter = (
			Select max(Quarter)
		from
			ZipTerr_V1)
		and team in ('Alpha',
			'Phantom',
			'Falcon',
			'SILIQ',
			'Dermatology.com')) a1
full outer join (
		select b.name user_profile_new,
		b.createddate createddate_new,
		b.parentid parentid_new,
		a.Primary_Address_Derm__c PRIMARY_VOD__C_new,
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
			select a.*,
			c.name
		from
			Veeva_Replication.[db_owner].[SF_ADDRESS_VOD__HISTORY] a
		join [Veeva_Replication].[db_owner].[SF_USER] b on
			(a.[CREATEDBYID] = b.id)
		join [Veeva_Replication].db_owner.[SF_PROFILE] c on
			(c.id = b.PROFILEID)
		where
			c.name not in ('Bauschhealth - DataSteward',
			'Bauschhealth - DCR',
			'System Administrator',
			'Bauschhealth - Sales Operations')
			and a.field in ('Primary_Address_Derm__c')
			and a.[CREATEDDATE] >= '2018-10-01 00:00:00.000'
			and a.newvalue = 'true') b
	left outer join [Veeva_Replication].[db_owner].[SF_ADDRESS_VOD__C] a on
		(b.parentid = a.id)
		and a.INACTIVE_VOD__C = 0
	left outer join [Data_Quality_Reporting].[dbo].[ZipTerr_V1] d on
		cast(d.Zipcode as int) = cast(a.ZIP_VOD__C as int)
		and Quarter = (
			Select max(Quarter)
		from
			ZipTerr_V1)
		and team in ('Alpha',
		'Phantom',
		'Falcon',
		'SILIQ',
		'Dermatology.com') ) b1 on
	(a1.ACCOUNT_VOD__C_old = b1.ACCOUNT_VOD__C_new
	and a1.TEAM_Old = b1.Team_new)
left outer join (
		select b.ims_id__c IMS_ID_V1,
		b.SYMPHONY_ID__C HCE_ID_V1,
		b.npi_vod__c NPI_ID_V1,
		b.Id DS_SFID_V1,
		b.account_status_med__c STATUS_V1,
		b.lastname last_name_V1,
		b.firstname first_name_V1,
		b.credentials_vod__c DegreeDesc_V1,
		b.pdrp_med__c PDRP_V1,
		b.practicing_specialty__c PrimarySpecialtyDesc_V1
	from
		Veeva_Replication.[db_owner].[SF_ACCOUNT] b
	where
		b.ispersonaccount = 1) v2 on
	(isnull(a1.ACCOUNT_VOD__C_old,
	b1.ACCOUNT_VOD__C_new) = v2.DS_SFID_V1)
left outer join (
		select *,
		case
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'G1' then 'Willow'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'G2' then 'Futura'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'G3' then 'Integra'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'G4' then 'Polaris'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'G5' then 'Integra 2'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'P1' then 'Pain'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'M3' then 'Magnifica'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'L2' then 'Lucida'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'KM' then 'IAM'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'T5' then 'Arctica'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'T1' then 'Targretin'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'G7' then 'Excelse'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'P1' then 'Cordata'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'A1' then 'Alpha'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'S1' then 'Phantom'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'A2' then 'Falcon'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'SQ' then 'SILIQ'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'D3' then 'Dermatology.com'
			
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'N2' then 'McKinley'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'N5' then 'Everest'
			else ''
		end SALES_TEAM__C,
		case
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'G1' then 'SALIX'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'G2' then 'SALIX'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'G3' then 'SALIX'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'G4' then 'SALIX'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'G5' then 'SALIX'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'P1' then 'SALIX'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'M3' then 'SALIX'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'L2' then 'SALIX'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'KM' then 'SALIX'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'T5' then 'SALIX'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'T1' then 'SALIX'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'G7' then 'SALIX'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'P1' then 'SALIX'
			
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'A1' then 'DERM-ORTHO'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'S1' then 'DERM-ORTHO'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'A2' then 'DERM-ORTHO'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'SQ' then 'DERM-ORTHO'
			
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'N2' then 'NEURO'
			when SUBSTRING(territory_vod__c, len(territory_vod__c) -1, 2) = 'N5' then 'NEURO'
			else ''
		end SALESFORCE_MED__C
	from
		(
			SELECT account_vod__c,
			replace(Split.a.value('.', 'VARCHAR(100)'), '#', '&') AS Territory_vod__c
		FROM
			(
				SELECT account_vod__c,
				CAST ('<M>' + REplace(REPLACE(Territory_vod__c, ';', '</M><M>'), '&', '#')+ '</M>' AS XML) AS String
			FROM
				[Veeva_Replication].[db_owner].[SF_ACCOUNT_TERRITORY_LOADER_VOD__C]) AS A CROSS APPLY String.nodes ('/M') AS Split(a)
		WHERE
			Split.a.value('.',
			'VARCHAR(100)') != '') t2 ) c on
	(isnull(a1.ACCOUNT_VOD__C_old,
	b1.ACCOUNT_VOD__C_new) = c.ACCOUNT_VOD__C
	and isnull(a1.team_old,
	b1.team_new) = c.SALES_TEAM__C)
GO


