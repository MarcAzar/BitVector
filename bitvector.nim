# Copyright (C) Marc Azar. All rights reserved.
# MIT License. Look at LICENSE.txt for more info
#
## A simple Nim implementation of BitVector with base uint64, support for
## slices, and a Bloom filter for approximate memberships
##
type 
  Bit = range[0..1]
  Base = seq[BiggestUInt]
  BitVector* = distinct Base

proc `[]`*(b: BitVector, i: Slice[int]): Base {.inline.} =
  if i.a < i.b:
    b.Base[i]
  else:
    b.Base[i.b..i.a]

proc `[]=`*(b: var BitVector, i: Slice[int], value: BitVector) {.inline.} =
  if i.a < i.b:
    b.Base[i] = value.Base
  else:
    b.Base[i.b .. i.a] = value.Base

proc `[]`*(b: BitVector, i: int): Bit {.inline.} =
  b.Base[i div 64] shr (i and 63) and 1

proc `[]=`*(b: var BitVector, i: int, value: Bit) {.inline.} =
  var w = addr b.Base[i div 64]
  if value == 0:
    w[] = w[] and not (1'u64 shl (i and 63))
  else:
    w[] = w[] or (1'u64 shl (i and 63))

proc newBitVector*(size: int): BitVector {.inline.} =
  newSeq[BiggestUInt](size).BitVector

#[
proc binDigits(x: BiggestUInt, r: int): int =
  ## Calculates how many digits `x` has when each digit covers `r` bits.
  result = 1
  var y = x shr r
  while y > 0:
    y = y shr r
    inc(result)
]#

proc toBin(x: BiggestUInt, len: Natural = 64): string =
  ## converts `x` into its binary representation. The resulting string is
  ## always `len` characters long. No leading ``0b`` prefix is generated.
  var
    mask: BiggestUInt = 1
    shift: BiggestUInt = 0
#    len = if len == 0: binDigits(x, 1) else: len
  result = newString(len)
  for j in countdown(len-1, 0):
    result[j] = chr(int((x and mask) shr shift) + ord('0'))
    shift = shift + 1
    mask = mask shl 1

proc `$`*(b: BitVector): string {.inline.} =
  result = "{"
  for key in items(b.Base):
    if result.len > 1: result.add(", ")
    result.addQuoted(key.toBin)
  result.add("}")

when isMainModule:
  var bitVec = newBitVector(10)
  var temp = newBitVector(2)
  echo "bitVec: ", bitVec

  bitVec[0] = 1
  bitVec[1] = 1
  bitVec[2] = 1
  echo "bitVec[0]: ", bitVec[0]
  echo "bitVec[1]: ", bitVec[1]
  echo "bitVec[2]: ", bitVec[2]

  echo "bitVec[0..<3]: ", bitVec
  
  echo "temp: ", temp
  
  bitVec[0..<2] = temp
  echo "bitVec: ", bitVec

