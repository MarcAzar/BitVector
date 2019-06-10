# Copyright (C) Marc Azar. All rights reserved.
# MIT License. Look at LICENSE.txt for more info
#
## A high performance Nim implementation of BitVector with base 
## (int, int64, uint32, uint16, or uint8), and with support for slices and other
## `seq` supported operations. BitVector format order is little endian, 
## where Least Significant Byte has the lowest address.
## BitVector is an in-memory bit vector, no mmap option is available at 
## the moment.
##
## Usage
## --------------
##  ::
##    import bitvector
##  
##    block:
##      var ba = newBitVector[uint](64) # Create a BitVector with uint64 base
##      echo ba # Prints capacity in bits = 64, and number of elements = 1
##      ba[0] = 1 # Assign `true` to bit index `0`
##      ba[2] = 1
##      ba[7] = 1 # ba[0..7] now is `10000101` == 133
##      assert(ba[0..7] == 133, "incorrect result: " & $ba[0..7]) 
##      assert(ba[0..4] == 5, "incorrect result: " & $ba[0..4])
##      assert(ba[1..4] == 2, "incorrect result: " & $ba[1..4])
##  
##    var bitvectorA = newBitVector[uint](2e9)
##    bitvectorA[0] = 1
##    bitvectorA[1] = 1
##    bitvectorA[2] = 1
##
##    # Test range lookups/inserts
##    bitvectorA[65] = 1
##    doAssert bitvectorA[65] == 1
##    bitvectorA[131] = 1
##    bitvectorA[194] = 1
##    assert bitvectorA[2..66] == bitvectorA[131..194]
##
##    let sliceValue = bitvectorA[131..194]
##    bitvectorA[270..333] = sliceValue
##    bitvectorA[400..463] = uint(-9223372036854775807)
##    assert bitvectorA[131..194] == bitvectorA[270..333]
##    assert bitvectorA[131..194] == bitvectorA[400..463]
##
type 
  Units* = SomeUnsignedInt
  Bit = range[0..1]
  BitVector*[T: Units] = object
    Base: seq[T]

# Forward declarations
func `len`*[T](b: BitVector[T]): int {.inline.}
func cap*[T](b: BitVector[T]): int {.inline.}

func newBitVector*[T](size: int): BitVector[T] {.inline.} =
  ## Create new in-memory BitVector of type T and number of elements is
  ## `size` rounded up to the nearest byte. 
  var blocks = size div (T.sizeof * 8)
  if blocks == 0: blocks = 1
  result.Base = newSeqOfCap[T](blocks)
  result.Base.setlen(blocks)

func `[]`*[T](b: BitVector[T], i: int): Bit {.inline.} =
  assert(i < b.cap and i >= 0, "Index out of range")
  b.Base[i div (T.sizeof * 8)] shr (i and (T.sizeof * 8 - 1)) and 1

proc `[]=`*[T](b: var BitVector[T], i: int, value: Bit) {.inline.} =
  assert(i < b.cap and i >= 0, "Index out of range")
  var w = addr b.Base[i div (T.sizeof * 8)]
  if value == 0:
    w[] = w[] and not (1.T shl (i and (T.sizeof * 8 - 1)))
  else:
    w[] = w[] or (1.T shl (i and (T.sizeof * 8 - 1)))

func `[]`*[T](x: BitVector[T], i: Slice[int]): T {.inline.} =
  if i.a < i.b:
    assert(i.b < x.cap and i.a >= 0, "Index out of range")
    assert((i.b - i.a) <= (T.sizeof * 8),
       "Only slices up to " & $(T.sizeof * 8) & " bits are supported")
    let elA = i.a div (T.sizeof * 8)
    let elB = i.b div (T.sizeof * 8)
    let offsetA = i.a and (T.sizeof * 8 - 1)
    let offsetB = (T.sizeof * 8) - offsetA
    result = x.Base[elA] shr offsetA
    if elA != elB:
      let slice = x.Base[elB] shl offsetB
      result = result or slice
    elif i.a != i.b and i.b < (T.sizeof * 8 - 1):
      let innerOffset = i.b and (T.sizeof * 8 - 1)
      result =
        (((((1.T shl innerOffset) - 1) or (1.T shl innerOffset)) and
        x.Base[elA]) shr offsetA)
  else:
    assert(i.a < x.cap and i.b >= 0, "Index out of range")
    assert((i.a - i.b) <= (T.sizeof * 8),
       "Only slices up to " & $(T.sizeof * 8) & " bits are supported")
    let elA = i.b div (T.sizeof * 8)
    let elB = i.a div (T.sizeof * 8)
    let offsetA = i.b and (T.sizeof * 8 - 1)
    let offsetB = (T.sizeof * 8) - offsetA
    result = x.Base[elA] shr offsetA
    if elA != elB:
      let slice = x.Base[elB] shl offsetB
      result = result or slice
    elif i.a != i.b and i.a < (T.sizeof * 8 - 1):
      let innerOffset = i.a and (T.sizeof * 8 - 1)
      result =
        (((((1.T shl innerOffset) - 1) or (1.T shl innerOffset)) and
        x.Base[elA]) shr offsetA)

proc `[]=`*[T](x: var BitVector[T], i: Slice[int], value: T) {.inline.} =
  ## Note that this uses bitwise-or, therefore it will NOT overwrite
  ## previously set bits 
  if i.a < i.b:
    assert(i.b < x.cap and i.a >= 0, "Index out of range")
    assert((i.b - i.a) <= (T.sizeof * 8),
       "Only slices up to " & $(T.sizeof * 8) & " bits are supported")
    let elA = i.a div (T.sizeof * 8)
    let elB = i.b div (T.sizeof * 8)
    let offsetA = i.a and (T.sizeof * 8 - 1)
    let offsetB = (T.sizeof * 8) - offsetA

    let insertA = value shl offsetA
    x.Base[elA] = x.Base[elA] or insertA
    if elA != elB:
      let insertB = value shr offsetB
      x.Base[elB] = x.Base[elB] or insertB
  else:
    assert(i.a < x.cap and i.b >= 0, "Index out of range")
    assert((i.a - i.b) <= (T.sizeof * 8),
       "Only slices up to " & $(T.sizeof * 8) & " bits are supported")
    let elA = i.b div (T.sizeof * 8)
    let elB = i.a div (T.sizeof * 8)
    let offsetA = i.b and (T.sizeof * 8 - 1)
    let offsetB = (T.sizeof * 8) - offsetA

    let insertA = value shl offsetA
    x.Base[elA] = x.Base[elA] or insertA
    if elA != elB:
      let insertB = value shr offsetB
      x.Base[elB] = x.Base[elB] or insertB

func cap*[T](b: BitVector[T]): int {.inline.} =
  ## Returns capacity, i.e number of bits
  b.len * (T.sizeof * 8)

func `len`*[T](b: BitVector[T]): int {.inline.} =
  ## Returns length, i.e number of elements
  b.Base.len()

func toBitVector*[T](x: openArray[int]): BitVector[T] =
  result = newBitVector[T](x.len)
  for i in 0 ..< x.len:
    if x[x.len - 1 - i] != 0: result[i] = 1

func builtin_clz(x: culong): cint {.importc: "__builtin_clzl", cdecl.}
func fastLog2(x: uint32): int {.inline, noSideEffect.} =
  (63 - builtin_clz(x))

func toBitVector*[T](x: int): BitVector[T] =
  var tmp = x.uint32
  var shift = fastLog2(tmp)
  result = newBitVector[T](shift)
  while tmp != 0:
    result[shift] = 1
    tmp = tmp - (1 shl shift).uint32
    shift = fastLog2(tmp)

func `$`*[T](b: BitVector[T]): string {.inline.} =
  ## Prints number of bits and elements the BitVector is capable of handling.
  ## It also prints out a slice if specified in little endian format.
  result =
    "BitVector with capacity of " & $b.cap & " bits and " & $b.len &
      " unique elements"
