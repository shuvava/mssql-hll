using System;
using System.Data.SqlTypes;
using System.IO;

using Microsoft.SqlServer.Server;

namespace HyperLogLog
{
    [Serializable]
    [SqlUserDefinedAggregate(Format.UserDefined,
        MaxByteSize = -1,
        IsInvariantToNulls = true,
        IsInvariantToDuplicates = true,
        IsInvariantToOrder = true,
        IsNullIfEmpty = true)]
    public class hhl_merge : IBinarySerialize
    {
        private const int HasheLen = 4096;
        private byte[] _hash;


        public void Init()
        {
            _hash = new byte[HasheLen];
        }


        public void Accumulate(SqlBinary value)
        {
            if (value.IsNull)
            {
                return;
            }

            var hash = value.Value;
            MergeHash(hash);
            // Put your code here
        }


        public void Merge(hhl_merge group)
        {
            MergeHash(group._hash);
        }


        public SqlBinary Terminate()
        {
            return new SqlBinary(_hash);
        }


        private void MergeHash(byte[] val)
        {
            if (val.Length == 0)
            {
                return;
            }

            for (var i = 0; i < HasheLen; i++)
            {
                if (val[i] > _hash[i])
                {
                    _hash[i] = val[i];
                }
            }
        }


        public void Read(BinaryReader r)
        {
            _hash = r.ReadBytes((int) r.BaseStream.Length);
        }


        public void Write(BinaryWriter w)
        {
            w.Write(_hash);
        }
    }
}
