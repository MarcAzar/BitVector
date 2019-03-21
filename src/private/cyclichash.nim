# Copyright (C) Marc Azar. All rights reserved.
# MIT License. Look at LICNESE.txt for more info
#
## A Nim implementation of Cyclic Polynomial Hash, aka BuzHash
##
## A Cyclic Polynomial hash is a type of Rolling hash which avoids
## multiplication by using circular shifts and xoring. For more information
## regarding Cyclic Polynomial hasing please refer to wiki's article on
## `Rolling Hash`_
##
## .. _Rolling Hash:https://en.wikipedia.org/wiki/Rolling_hash#Cyclic_polynomial
##
import characterhash

type
  CyclicHash* = object
    hashValue*: HashType
    n: int
    wordSize: int
    hashes: Hashes
    maskOne: HashType
    myR: int
    maskN: HashType

proc newCyclicHash*(myN: int, myWordSize: int) : CyclicHash {.inline.} =
  ## Creates a new Cyclic Hash with a quasi-random[*]_ initial has value of
  ## size `myWordSize` in bits. 
  ## 
  ## Asserts that the bitsize of the required hash value is not smaller than
  ## the bitsize of `myWordSzie`
  ##
  ## .. [*] See Character Hash for more info
  assert(myWordSize < 8 * HashType.sizeof,
    "Can't create " & $myWordSize & " bit hash values")
  result = CyclicHash(
    hashValue: 0,
    n: myN,
    wordSize: myWordSize,
    hashes: hasher(maskFnc(myWordSize)),
    maskOne: maskFnc(myWordSize - 1),
    myR: myN mod myWordSize,
    maskN: maskFnc(myWordSize - result.myR)
  )

proc newCyclicHash*(myN: int, seedOne, seedTwo: int, myWordSize: int) : CyclicHash {.inline.} =
  ## Creates a new Cyclic Hash with a random[*]_ initial has value of size
  ## `myWordSize` in bits.
  ##
  ## Asserts that the bitsize of the required hash value is not smaller than
  ## the bitsize of `myWordSzie`
  ##
  ## .. [*] See Character Hash for more info
  assert(myWordSize < 8 * HashType.sizeof,
    "Can't create " & $myWordSize & " bit hash values")
  result = CyclicHash(
    hashValue: 0,
    n: myN,
    wordSize: myWordSize,
    hashes: hasher(maskFnc(myWordSize), seedOne, seedTwo),
    maskOne: maskFnc(myWordSize - 1),
    myR: myN mod myWordSize,
    maskN: maskFnc(myWordSize - result.myR),
  )

template fastLeftShiftN(y: CyclicHash, x: var HashType) =
  x = ((x and y.maskN) shl y.myR) or (x shr (y.wordSize - y.myR))

template fastLeftShiftOne(y: CyclicHash, x: var HashType) =
  x = ((x and y.maskOne) shl 1) or (x shr (y.wordSize - 1))

template fastRightShiftOne(y: CyclicHash, x: var HashType) =
  x = (x shr 1) or ((x and 1) shl (y.wordSize - 1))

template getFastLeftShiftOne(y: CyclicHash, x: HashType): HashType =
  ((x and y.maskOne) shl 1) or (x shr (y.wordSize - 1))

template getFastRightShiftOne(y:CyclicHash, x: HashType): HashType =
  (x shr 1) or ((x and 1) shl (y.wordSize - 1))

proc hash*(y: var CyclicHash, c: seq[char]): HashType {.inline.}=
  ## Hash complete sequence of char without the need to update. This is a
  ## helper proceedure to test whether the update proceedure below yeilds
  ## correct results in unit testing
  ##
  var answer: HashType = 0
  for k in 0 ..< c.len:
    y.fastLeftShiftOne(answer)
    answer = answer xor y.hashes[ord(c[k])]
    result = answer

proc update*(y: var CyclicHash, outChar: CharType, inChar: CharType) {.inline.}=
  ## Updates the rolling hash after shifting left and xoring hash value of
  ## `outChar` add `inChar`
  ##
  var z = y.hashes[ord(outChar)]
  y.fastLeftShiftN(z)
  y.hashValue = y.getFastLeftShiftOne(y.hashValue) xor z xor 
    y.hashes[ord(inChar)]

proc reverseUpdate*(y: var CyclicHash, outChar: CharType, inChar: CharType) {.inline.}=
  # Cyclic Hash is reversible! We can undo a previous update by performing a
  # right shift. See `test_cyclichash` for an example.
  #
  var z = y.hashes[ord(outChar)]
  y.fastLeftShiftN(z)
  y.hashValue = y.hashValue xor z xor y.hashes[ord(inChar)]
  y.hashValue = y.getFastRightShiftOne(y.hashValue)

proc eat*(y: var CyclicHash, inChar: CharType) {.inline.} =
  ## Move rolling hash forward by shifting left and xoring the hash value of
  ## the new `inChar`
  ##
  y.fastLeftShiftOne(y.hashValue)
  y.hashValue = y.hashValue xor y.hashes[ord(inChar)]

proc hashPrepend*(y: var CyclicHash, x: CharType): HashType {.inline.}=
  ## Prepends a rolling hash by adding a hashed `x` into the front of the
  ## rolling hash sequence
  ##
  var z = y.hashes[ord(x)]
  y.fastLeftShiftN(z)
  result = z xor y.hashValue

proc hashExtend*(y: CyclicHash, x: CharType): HashType {.inline.}=
  ## Extends a rolling hash by adding a hashed `x` into the end of the rolling
  ## hash sequence
  ##
  result = y.getFastLeftShiftOne(y.hashValue) xor y.hashes[ord(x)]

proc reset*(y: var CyclicHash) {.inline.}=
  ## Reset the hash values of rolling hash to `0`
  y.hashValue = 0
