# BitVector
A high performance Nim implementation of BitVector with base SomeUnsignedInt(i.e: uint8-64) with support for slices, and `seq` supported operations. BitVector format order is little endian, where Least Significant Byte has the lowest address. BitVector is an in-memory bit vector, no mmap option is available at the moment.

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
 
  var bitarrayA = newBitVector[uint](2e9)
  bitarrayA[0] = 1
  bitarrayA[1] = 1
  bitarrayA[2] = 1
  
  # Test range lookups/inserts
  bitarrayA[65] = 1
  doAssert bitarrayA[65] == 1
  bitarrayA[131] = 1
  bitarrayA[194] = 1
  assert bitarrayA[2..66] == bitarrayA[131..194]

  let sliceValue = bitarrayA[131..194]
  bitarrayA[270..333] = sliceValue
  bitarrayA[400..463] = uint(-9223372036854775807)
  assert bitarrayA[131..194] == bitarrayA[270..333]
  assert bitarrayA[131..194] == bitarrayA[400..463]
```
## Installation
Install <a class="external reference" href="https://nim-lang.org/install.html">Nim</a> for Windows or Unix by following the instructions in , or preferably by installing <a class="reference external" href="https://github.com/dom96/choosenim">choosenim</a>

Once ```choosenim``` is installed you can ```nimble install bitvector``` to pull the latest bipbuffer release and all its dependencies

## Documentation
Documentation can be found <a class="external reference" href="https://marcazar.github.io/BitVector/docs/bitvector.html">here</a>
