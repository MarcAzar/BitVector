# BitVector
A high performance Nim implementation of BitVector with base (uint64, uint32, uint16, or uint8), and with support for slices and other `seq` supported operations. BitVector format order is little endian, where Least Significant Byte has the lowest address. BitVector is an in-memory bit vector. A <a class="external reference" href="https://en.wikipedia.org/wiki/Bloom_filter">Bloom Fliter</a> is also provided to demonstrate BitVector usage along with Murmur Hashing. If looking for a mmap type BitVector consider using <a class="external reference" href="https://github.com/onecodex/nim-bitarray">nim-bitarray</a>.
## Example Usage                                                        
```
import bitvector
   
  block:
    var ba = newBitVector[uint](64) # Create a BitVector with uint64 base
    echo ba # Prints capacity in bits = 64, and number of elements = 1
    ba[0] = 1 # Assign `true` to bit index `0`
    ba[2] = 1
    ba[7] = 1 # ba[0..7] now is `10000101` == 13
    assert(ba[0..7] == 133, "incorrect result: " & $ba[0..7]) 
    assert(ba[0..4] == 5, "incorrect result: " & $ba[0..4])
    assert(ba[1..4] == 2, "incorrect result: " & $ba[1..4])
 
  var bitvectorA = newBitVector[uint](2e9)
  bitvectorA[0] = 1
  bitvectorA[1] = 1
  bitvectorA[2] = 1
  
  # Test range lookups/inserts
  bitvectorA[65] = 1
  doAssert bitvectorA[65] == 1
  bitvectorA[131] = 1
  bitvectorA[194] = 1
  assert bitvectorA[2..66] == bitvectorA[131..194]

  let sliceValue = bitvectorA[131..194]
  bitvectorA[270..333] = sliceValue
  bitvectorA[400..463] = uint(-9223372036854775807)
  assert bitvectorA[131..194] == bitvectorA[270..333]
  assert bitvectorA[131..194] == bitvectorA[400..463]
```
## Bloom Filter Performance
A Bloom Filter speed test is included in `test_bloom.nim`. A test case of 10M insertions executes in ~3.2 seconds and 10M lookups in ~3.1 seconds for a Bloom filter with a 1 in 1000 target error rate (0.001) and actual error rate of 0.0007. This was performed on asingle thread by passing the -d:release flag to the Nim compiler on a Dell XP3 13 laptop (i7 with 16GB Ram). `k` was computed to its optimal 10 hash functions, while the Bloom filter size was 18.75MB in size.

## Installation
Install <a class="external reference" href="https://nim-lang.org/install.html">Nim</a> for Windows or Unix by following the instructions in , or preferably by installing <a class="reference external" href="https://github.com/dom96/choosenim">choosenim</a>

Once ```choosenim``` is installed you can ```nimble install bitvector``` to pull the latest bipbuffer release and all its dependencies

## Documentation
Documentation can be found <a class="external reference" href="https://marcazar.github.io/BitVector/docs/bitvector.html">BitVector</a> and <a class="external reference" href="https://marcazar.github.io/BitVector/docs/bloom.html">Bloom Filter</a>
