--exec  sp_configure 'external scripts enabled', 1
--RECONFIGURE  
DECLARE @estimation INT = 0
DECLARE @hll varbinary(max) 
declare @distinct int = 2103130



--SELECT @distinct = COUNT(DISTINCT ID) FROM [dbo].[sample]

print '------------------------------------------------------------------------'
print 'Dataset (after):'
DECLARE @RowsPerRead INT = 100000

execute sp_execute_external_script 
@language = N'Python',
@script = N'
import sys
import os
#print("*******************************")
#print(sys.version)
#print("Hello World")
#print(os.getcwd())
#print("*******************************")
import numpy as np
from datasketch import HyperLogLogPlusPlus
hll = HyperLogLogPlusPlus(p=12) # max p=16
if digest and len(digest)> 0:
	print(type(digest))
	print(digest)
	array=bytearray(digest)
	#_arr= np.fromstring(digest, dtype=int, sep=" ")
	#hll = HyperLogLogPlusPlus(reg= _arr) 
	hll = hll.deserialize(array)

for i in InputDataSet["id"]:
	hll.update(str(i).encode(''utf8''))
#print(hll.count())
estimation = int(hll.count())
#__digest = hll.digest([])
#print(__digest)
#_digest = " ".join(map(str, __digest))
#digest = _digest
buf = bytearray(hll.bytesize())
hll.serialize(buf)
digest =  bytes(buf)
#print(digest)
', 
@input_data_1 = N'select [IssueId] as[id] FROM [test_ag].[dbo].[sample_data] ', 
@params = N'@r_rowsPerRead INT, @estimation INT OUTPUT, @digest varbinary(max) OUTPUT',
@r_rowsPerRead = @RowsPerRead,
@estimation = @estimation OUTPUT,
@digest = @hll OUTPUT
--with result sets (("DayOfWeek" int null, "Amount" float null))

print 'Output parameters (after):'
print FORMATMESSAGE('EstimationT=%d', @estimation)
--print @hll
--print len(@hll)
GO