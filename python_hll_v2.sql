ALTER PROCEDURE Test_Hash_Calc (
	@startDate datetime
)
AS 
BEGIN
	SET NOCOUNT ON;
	declare @tsql_input nvarchar(max)=''
	declare @python_script nvarchar(max) = N'
import pandas as pd
from datetime import datetime
import numpy as np
from datasketch import HyperLogLogPlusPlus
_cln_end_date = "EndDate"
_cln_host_id = "HostId"
_cln_sponsor_id = "SponsorId"
_cln_cid_id = "cid"
_cln_view_type_id = "ViewType"
_cln_value = "val"
_cln_hll = "hash"

hll_dict = {}
for index, row in InputDataSet.iterrows():
	key = "{}_{}_{}_{}_{}".format(row[_cln_end_date], row[_cln_host_id], row[_cln_sponsor_id], row[_cln_cid_id], row[_cln_view_type_id])
	if key in hll_dict:
        hll  = hll_dict[key][_cln_hll]
	else:
        hll = HyperLogLogPlusPlus(p=12) # max p=16
        # if row[_cln_hll]: # init from exist hash
        #     _arr= np.fromstring(digest, dtype=int, sep=" ")
        #     hll = HyperLogLogPlusPlus(reg= _arr)
        hll_dict[key] = {_cln_hll: hll, _cln_end_date: row[_cln_end_date], _cln_host_id: row[_cln_host_id], _cln_sponsor_id: row[_cln_sponsor_id], _cln_cid_id:row[_cln_cid_id], _cln_view_type_id:row[_cln_view_type_id] }
	hll.update(str(row[_cln_value]).encode("utf8"))

out = []
#prepare output 
for key, value in hll_dict.items():
    hll = value[_cln_hll]
    buf = bytearray(hll.bytesize())
    hll.serialize(buf)
	#, _cln_cid_id: value[_cln_cid_id]
	#, _cln_hll: bytes(buf)
    obj = { _cln_end_date: value[_cln_end_date], _cln_host_id: value[_cln_host_id], _cln_sponsor_id: value[_cln_sponsor_id], _cln_view_type_id:value[_cln_view_type_id], _cln_cid_id: value[_cln_cid_id],_cln_hll: bytes(buf)  }
    out.append(obj)

OutputDataSet = pd.DataFrame(out)
';
	SET @tsql_input = N'
SELECT
	CONVERT ( varchar(19) ,DATEADD(hour, DATEDIFF(hour, 0, [ReadingDate]), 0) , 126) as[EndDate]
	,[HostId], [SponsorId], [CID] as [cid], [ViewType]
    ,[IssueId] as [val]
FROM [dbo].[sample_data]
WHERE [ReadingDate] > = ''' + CONVERT(varchar(19) , @startDate , 126) +'''
and [ReadingDate]  < ''' + CONVERT(varchar(19) , DATEADD(hour, 1, @startDate) , 126) +''''
	execute sp_execute_external_script 
		@language = N'Python',
		@script = @python_script, 
		@input_data_1 =@tsql_input
		with result sets 
		--UNDEFINED 
		((EndDate varchar(19), HostId int, SponsorId int
		, ViewType smallint
		, cid varchar(5)
		, "hash" varbinary(max)
		))
END

DECLARE @startDate datetime = '2017-11-28T00:00:00'
DECLARE @endDate datetime = '2017-11-29T00:00:00';

WHILE @startDate< @endDate
BEGIN
	print 'start '+CONVERT ( varchar(19) , @startDate , 126)
	INSERT INTO [dbo].[stat_hourly_v2] ([EndDate], [HostId], [SponsorId],[ViewType],[CID],[hash])
	exec Test_Hash_Calc @startDate
	SET @startDate = DATEADD(hour, 1, @startDate)
END