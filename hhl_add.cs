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
    public class hhl_add : IBinarySerialize
    {
        private const short p = 12;
        private const short _hash_range_bit = 64;
        private const byte max_rank = _hash_range_bit - p;
        private const int m = 4096;
        private byte[] _hash;

        public void Init()
        {
            _hash = new byte[m];
        }


        public void Accumulate(SqlBinary value)
        {
            if (value.IsNull)
            {
                return;
            }

            var hash = value.Value;
            var hv = BitConverter.ToUInt64(hash, 0);
            var reg_index = hv & (m -1);
            var bits = hv >> p;
            var rank = GetRank(bits);
            if (rank > _hash[reg_index])
            {
                _hash[reg_index] = rank;
            }
            // Put your code here
        }


        public void Merge(hhl_add group)
        {
            MergeHash(group._hash);
        }


        public SqlBinary Terminate()
        {
            return new SqlBinary(_hash);
        }

        public void Read(BinaryReader r)
        {
            _hash = r.ReadBytes((int)r.BaseStream.Length);
        }


        public void Write(BinaryWriter w)
        {
            w.Write(_hash);
        }


        private bool IsBitSet(ulong val, byte inx)
        {
            return ((ulong)(0x1 << inx) & val) != 0;
        }

        private byte GetRank(ulong bits)
        {
            if (bits == 0)
            {
                return 0;
            }
            byte inx = 0;
            for (byte i = 63; i >= 0; i--)
            {
                if ((((ulong) 0x1 << i) & bits) != 0)
                {
                    inx = (byte)(i+1);
                    break;
                }
            }
            return (byte)(max_rank - inx + 1);
        }
        private void MergeHash(byte[] val)
        {
            if (val.Length == 0)
            {
                return;
            }

            for (var i = 0; i < m; i++)
            {
                if (val[i] > _hash[i])
                {
                    _hash[i] = val[i];
                }
            }
        }
    }
}
