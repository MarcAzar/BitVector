# Copyright (C) Marc Azar, All rights reserved.
# MIT License. Look at LICENSE.txt for more info
#
## Character Hashing based on given value type and input type. Uses Nim's
## `random` Module to generate initial randomized hash value, and has an option
## to be given seeds. For more info regarding the `random` please refer to 
## xoroshiro128+(xor/rotate/shift/rotate) library_
##
## .. _library:http://xoroshiro.di.unimi.it/
##
from random import rand, initRand

type
  HashType* = int
  CharType* = char
  Hashes* = seq[HashType]

proc maskFnc*(bits: int): HashType {.inline.} =
  ## Return a mask of ones equal to `bits` (eg: 4 bit mask = 0b1111)
  ##
  ## Asserts that 0 < `bits` <=  `sizeof(type) in bits` 
  doAssert bits > 0
  doAssert bits <= HashType.sizeof * 8
  let x = cast[HashType](1) shl (bits - 1)
  result = x xor (x - 1)

proc hasher*(maxVal: HashType): Hashes {.raises: [IOError], inline.} =
  ## Based on bitsize of required hash, will return a quasi-random (sequence
  ## always the same since randomize is not called) range between `0..maxVal`
  ##
  let numberOfChars = 1 shl (CharType.sizeof * 8)
  result = newSeqOfCap[HashType](numberOfChars)
  result.setlen(numberOfChars)

  if  HashType.sizeof <= 4:
    for k in 0 ..< numberOfChars:
      result[k] = cast[HashType](rand(maxVal))

  elif HashType.sizeof == 8:
    let maxOne = maxVal shr 32
    let maxTwo = if (maxVal shr 32) == 0: maxVal else: high(HashType)
    for k in 0 ..< numberOfChars:
      result[k] = cast[HashType](rand(maxTwo)) or
        (cast[HashType](rand(maxOne)) shl 32)
  
  else:
    raise newException(IOError, "unsupported hash value type")

proc hasher*(maxVal: HashType, seedOne, seedTwo: int): Hashes {.raises: [IOError], inline.} =
  ## Based on bitsize of required hash, will return a random number
  ## between the range of `0..maxVal`. Randomization is based upon the seeds
  ## given.
  ##
  let numberOfChars = 1 shl (CharType.sizeof * 8)
  result = newSeqOfCap[HashType](numberOfChars)
  result.setlen(numberOfChars)
  
  if HashType.sizeof <= 4:
    var randomGenerator = initRand(seedOne)
    for k in 0 ..< numberOfChars:
      result[k] = cast[HashType](rand(randomGenerator, maxVal))

  elif HashType.sizeof == 8:
    var randomGenerator = initRand(seedOne)
    var randomGeneratorBase = initRand(seedTwo)
    let maxOne = maxVal shr 32
    let maxTwo = if (maxVal shr 32) == 0: maxVal else: high(HashType)
    for k in 0 ..< numberOfChars:
      result[k] = cast[HashType](rand(randomGeneratorBase, maxTwo)) or
        (cast[HashType](rand(randomGenerator, maxOne)) shl 32)
    
  else:
    raise newException(IOError, "unsupported hash value type")
