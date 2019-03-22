# Copyright (C) Marc Azar, All rights reserved.
# MIT License. Look at LICENSE.txt for more info
#
## Character Hashing based on given value type and input type. Uses Nim's
## random Module to generate initial randomized hash value, and has an option
## to be given seeds. For more info regarding the random please refer to
## xoroshiro128+(xor/rotate/shift/rotate) library_
## 
## ... _library:https://nim-lang.org/docs/random.html
##
import random

type
  Units* = int | uint8 | uint32 | int64
  CharacterHash*[H: Units, C: char] = object
    hashValues*: seq[H]

proc maskFnc*[H](bits: int): H {.inline.} =
  ## Return a mask of ones equal to `bits` (eg: 4 bit mask = 0b1111)
  ##
  ## Asserts that 0 < `bits` <=  `sizeof(type) in bits` 
  doAssert bits > 0
  doAssert bits <= H.sizeof * 8
  let x = cast[H](1) shl (bits - 1)
  result = x xor (x - 1)

proc hash*[H, C](maxVal: H): CharacterHash[H, C] {.raises: [IOError], inline.} =
  ## Based on bitsize of required hash, will return a quasi-random (sequence
  ## always the same since randomize is not called) range between `0..maxVal`
  ##
  let numberOfChars = 1 shl (C.sizeof * 8)
  result.hashValues = newSeqOfCap[H](numberOfChars)
  result.hashValues.setlen(numberOfChars)

  if  H.sizeof <= 4:
    for k in 0 ..< numberOfChars:
      result.hashValues[k] = cast[H](rand(maxVal.int))

  elif H.sizeof == 8:
    let maxTwo = if (maxVal shr 32) == 0: maxVal else: high(H)
    for k in 0 ..< numberOfChars:
      result.hashValues[k] = cast[H](rand(maxTwo.int)) or 
        cast[H](rand(maxVal.int shr 32) shl 32)
  
  else:
    raise newException(IOError, "unsupported hash value type")

proc hash*[H, C](maxVal: H, seedOne, seedTwo: int): CharacterHash[H, C] {.raises: [IOError], inline.} =
  ## Based on bitsize of required hash, will return a random number
  ## between the range of `0..maxVal`. Randomization is based upon the seeds
  ## given.
  ##
  let numberOfChars = 1 shl (C.sizeof * 8)
  result.hashValues = newSeqOfCap[H](numberOfChars)
  result.hashValues.setlen(numberOfChars)
  
  if H.sizeof <= 4:
    var randGen = initRand(seedOne)
    for k in 0 ..< numberOfChars:
      result.hashValues[k] = cast[H](rand(randGen, maxVal.int))

  elif H.sizeof == 8:
    let maxTwo = if (maxVal shr 32) == 0: maxVal else: high(H)
    var randGen = initRand(seedOne)
    var randBase = initRand(seedTwo)
    for k in 0 ..< numberOfChars:
      result.hashValues[k] = cast[H](rand(randBase, maxTwo.int)) or
        cast[H]((rand(randGen, maxVal.int shr 32) shl 32))
    
  else:
    raise newException(IOError, "unsupported hash value type")
