# Copyright (C) Marc Azar. All rights reserved.
# MIT License. Look at LICENSE.txt for more info
#
## A simple Nim implementation of BitVector with base SomeOrdinal (i.e: 
## int8-64, uint8-64, enum) with support for slices, and `seq`
## supported operations. BitVector format order is little endian, where 
## Least Significant Byte has the lowest address. BitVector is an in-memory
## bit vector, no mmap option is available at the moment.
##
type 
  Bit = range[0..1]
  BitVector*[T: SomeInteger | char] = object 
    Base: seq[T]

proc numberOfDigits(x: BiggestInt, r: int): int {.inline.} =
  ## Calculates how many digits `x` has when each digit covers `r` bits.
  result = 1
  var y = x shr r
  while y > 0:
    y = y shr r
    inc(result)

proc toString[T](x: T): string {.inline.} =
  ## converts `x` into its binary representation. The resulting string is
  ## always `len` characters long. No leading ``0b`` prefix is generated.
  var
    mask: T = 1
    shift: T = 0
    length = T.sizeof * 8
  result = newString(length)
  for j in countdown(length - 1, 0):
    result[j] = chr(int((x and mask) shr shift) + ord('0'))
    shift = shift + 1
    mask = mask shl 1

proc newBitVector*[T](size: int): BitVector[T] {.inline.} =
  result.Base = newSeq[T](size)

proc `[]`*[T](b: BitVector[T], i: int): Bit {.inline.} =
  b.Base[i div (T.sizeof * 8)] shr (i and (T.sizeof * 8 - 1)) and 1

proc `[]=`*[T](b: var BitVector[T], i: int, value: Bit) {.inline.} =
  var w = addr b.Base[i div (T.sizeof * 8)]
  if value == 0:
    w[] = w[] and not (1.T shl (i and (T.sizeof * 8 - 1)))
  else:
    w[] = w[] or (1.T shl (i and (T.sizeof * 8 - 1)))

proc toBinary[T](x: BiggestInt): seq[T] {.inline.} =
  ## converts `x` into its binary representation. Inserst the binary
  ## representaion into a Bit Vector with little endian formating.
  var
    mask: BiggestInt = 1
    shift: BiggestInt = 0
    length = numberOfDigits(x, 1)
  result = newSeq[T](length)
  for j in countdown(length - 1, 0):
    result[j] = cast[Bit]((x and mask) shr shift)
    shift = shift + 1
    mask = mask shl 1

proc `[]`*[T](b: BitVector[T], i: Slice[int]): seq[T] {.inline.} =
  if i.a < i.b:
    b.Base[i]
  else:
    b.Base[i.b..i.a]

proc `[]=`*[T](b: var BitVector[T], i: Slice[int], value: seq[T]) {.inline.} =
  if i.a < i.b:
    b[i] = value
  else:
    b[i.b..i.a] = value

proc `[]=`*[T](b: var BitVector[T], i: Slice[int], v: BiggestInt) {.inline.} =
  var value = toBinary[T](v)
  if i.a < i.b:
    b[i] = value
  else:
    b[i.b..i.a] = value

proc `==`*[T](b: seq[T], v: BiggestInt): bool {.inline.} =
  var value = toBinary[T](v)
  b == value

proc `len`*[T](b: BitVector[T]): int {.inline.} =
  len(b.Base)

iterator `items`*[T](a: BitVector[T]): T {.inline.} =
  ## iterates over each item of `a`.
  var i = 0
  let L = a.len
  while i < L:
    yield a[i]
    assert(a.len == L, "bit vector modified while iterating over it")

iterator `pairs`*[T](a: BitVector[T]): tuple[key: int, val: T] {.inline.} =
  ## iterates over each item of `a`. Yields ``(index, a[index])`` pairs.
  var i = 0
  while i < a.len:
    yield (i, a[i])
    i.inc

proc `$`*[T](b: BitVector[T]): string {.inline.} =
  result = "{"
  for key in b.items:
    if result.len > 1: result.add(", ")
    result.addQuoted(key.toString)
  result.add("}")
