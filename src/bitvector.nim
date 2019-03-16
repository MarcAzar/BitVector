# Copyright (C) Marc Azar. All rights reserved.
# MIT License. Look at LICENSE.txt for more info
#
## A high performance Nim implementation of BitVector with base 
## SomeUnsignedInt(i.e: uint8-64) with support for slices, and 
## `seq` supported operations. BitVector format order is little endian, 
## where Least Significant Byte has the lowest address.
## BitVector is an in-memory bit vector, no mmap option is available at 
## the moment.
##
type 
  Bit = range[0..1]
  BitVector*[T: SomeUnsignedInt] = object
    Base: seq[T]

# Forward declarations
proc `len`*[T](b: BitVector[T]): int {.inline.}
proc cap*[T](b: BitVector[T]): int {.inline.}

proc newBitVector*[T](size: int): BitVector[T] {.inline.} =
  ## Create new in-memory BitVector of type T and number of elements is
  ## `size` rounded up to the nearest byte. 
  assert(size >= T.sizeof * 8, "Min vector size is " & $(T.sizeof * 8))
  let numberOfElements = size div (T.sizeof * 8)
  result.Base = newSeqOfCap[T](numberOfElements)
  result.Base.setlen(numberOfElements)

proc `[]`*[T](b: BitVector[T], i: int): Bit {.inline.} =
  assert(i < b.cap and i >= 0, "Index out of range")
  b.Base[i div (T.sizeof * 8)] shr (i and (T.sizeof * 8 - 1)) and 1

proc `[]=`*[T](b: var BitVector[T], i: int, value: Bit) {.inline.} =
  assert(i < b.cap and i >= 0, "Index out of range")
  var w = addr b.Base[i div (T.sizeof * 8)]
  if value == 0:
    w[] = w[] and not (1.T shl (i and (T.sizeof * 8 - 1)))
  else:
    w[] = w[] or (1.T shl (i and (T.sizeof * 8 - 1)))

proc `[]`*[T](b: BitVector[T], i: Slice[int]): T {.inline.} =
  if i.a < i.b:
    assert(i.b < b.cap and i.a >= 0, "Index out of range")
    assert((i.b - i.a) <= (T.sizeof * 8),
      "Only slices up to " & $(T.sizeof * 8) & " bits are supported")
    let elA = i.a div (T.sizeof * 8)
    let elB = i.b div (T.sizeof * 8)
    let offsetA = i.a and (T.sizeof * 8 - 1)
    let offsetB = (T.sizeof * 8) - offsetA
    echo offsetA
    echo offsetB
    echo "elA ", elA
    echo "elB ", elB
    result = b.Base[elA] shr offsetA
    echo "result ", result
    if elA != elB:
      let slice = b.Base[elB] shl offsetB
      echo "slice ", slice
      result = result or slice
    elif i.a != i.b and i.b < (T.sizeof * 8 - 1):
      let innerOffset = i.b and (T.sizeof * 8 - 1)
      echo "inner ", innerOffset
      result =
        (((1.T shl innerOffset) - 1) or (1.T shl innerOffset)) and result
      echo "resultinner ", result
  else:
    assert(i.a < b.cap and i.b >= 0, "Index out of range")
    assert((i.a - i.b) <= (T.sizeof * 8),
      "Only slices up to " & $(T.sizeof * 8) & " bits are supported")
    let elA = i.b div (T.sizeof * 8)
    let elB = i.a div (T.sizeof * 8)
    let offsetA = i.b and (T.sizeof * 8 - 1)
    let offsetB = (T.sizeof * 8) - offsetA
    result = b.Base[elA] shr offsetA
    if elA != elB:
      let slice = b.Base[elB] shl offsetB
      result = result or slice
    elif i.a != i.b and i.a < (T.sizeof * 8 - 1):
      let innerOffset = i.a and (T.sizeof * 8 - 1)
      result =
        (((1.T shl innerOffset) - 1) or (1.T shl innerOffset)) and result

proc `[]=`*[T](b: var BitVector[T], i: Slice[int], value: T) {.inline.} =
  ## Note that this uses bitwise-or, therefore it will NOT overwrite
  ## previously set bits 
  if i.a < i.b:
    assert(i.b < b.cap and i.a >= 0, "Index out of range")
    assert((i.b - i.a) <= (T.sizeof * 8),
      "Only slices up to " & $(T.sizeof * 8) & " bits are supported")
    let elA = i.a div (T.sizeof * 8)
    let elB = i.b div (T.sizeof * 8)
    let offsetA = i.a and (T.sizeof * 8 - 1)
    let offsetB = (T.sizeof * 8) - offsetA

    let insertA = value shl offsetA
    b.Base[elA] = b.Base[elA] or insertA
    if elA != elB:
      let insertB = value shr offsetB
      b.Base[elB] = b.Base[elB] or insertB
  else:
    assert(i.a < b.cap and i.b >= 0, "Index out of range")
    assert((i.a - i.b) <= (T.sizeof * 8),
      "Only slices up to " & $(T.sizeof * 8) & " bits are supported")
    let elA = i.b div (T.sizeof * 8)
    let elB = i.a div (T.sizeof * 8)
    let offsetA = i.b and (T.sizeof * 8 - 1)
    let offsetB = (T.sizeof * 8) - offsetA

    let insertA = value shl offsetA
    b.Base[elA] = b.Base[elA] or insertA
    if elA != elB:
      let insertB = value shr offsetB
      b.Base[elB] = b.Base[elB] or insertB

proc cap*[T](b: BitVector[T]): int {.inline.} =
  ## Returns capacity, i.e number of bits
  b.len * (T.sizeof * 8)

proc `len`*[T](b: BitVector[T]): int {.inline.} =
  ## Returns length, i.e number of elements
  b.Base.len

proc `$`*(b: BitVector): string {.inline.} =
  ## Prints number of bits and elements the BitVector is capable of handling.
  ## It also prints out a slice if specified in little endian format.
  result =
    "BitVector with capacity of " & $b.cap & " bits and " & $b.len &
      " unique elements"
