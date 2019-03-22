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
  CyclicHash*[H: Units, C: char] = object
    hashValue*: H
    n: int
    wordSize: int
    hasher: CharacterHash[H, C]
    maskOne: H
    myR: int
    maskN: H

proc newCyclicHash*[H, C](myN: int, myWordSize: int) : CyclicHash[H, C] {.inline.} =
  ## Creates a new Cyclic Hash with a quasi-random[*]_ initial has value of
  ## size `myWordSize` in bits. 
  ## 
  ## Asserts that the bitsize of the required hash value is not smaller than
  ## the bitsize of `myWordSzie`
  ##
  ## .. [*] See Character Hash for more info
  assert(cast[uint](myWordSize) <= 8 * H.sizeof,
    "Can't create " & $myWordSize & " bit hash values")
  result = CyclicHash[H, C](
    hashValue: 0,
    n: myN,
    wordSize: myWordSize,
    hasher: hash[H, C](maskFnc[H](myWordSize)),
    maskOne: maskFnc[H](myWordSize - 1),
    myR: myN mod myWordSize,
    maskN: maskFnc[H](myWordSize - result.myR)
  )

proc newCyclicHash*[H, C](myN: int, seedOne, seedTwo: int, myWordSize: int) : CyclicHash[H, C] {.inline.} =
  ## Creates a new Cyclic Hash with a random[*]_ initial has value of size
  ## `myWordSize` in bits.
  ##
  ## Asserts that the bitsize of the required hash value is not smaller than
  ## the bitsize of `myWordSzie`
  ##
  ## .. [*] See Character Hash for more info
  assert(cast[uint](myWordSize) <= 8 * H.sizeof,
    "Can't create " & $myWordSize & " bit hash values")
  result = CyclicHash[H, C](
    hashValue: 0,
    n: myN,
    wordSize: myWordSize,
    hasher: hash[H, C](maskFnc[H](myWordSize), seedOne, seedTwo),
    maskOne: maskFnc[H](myWordSize - 1),
    myR: myN mod myWordSize,
    maskN: maskFnc[H](myWordSize - result.myR),
  )

template fastLeftShiftN[H, C](y: CyclicHash[H, C], x: var H) =
  x = ((x and y.maskN) shl y.myR) or (x shr (y.wordSize - y.myR))

template fastLeftShiftOne[H, C](y: CyclicHash[H, C], x: var H) =
  x = ((x and y.maskOne) shl 1) or (x shr (y.wordSize - 1))

template fastRightShiftOne[H, C](y: CyclicHash[H, C], x: var H) =
  x = (x shr 1) or ((x and 1) shl (y.wordSize - 1))

template getFastLeftShiftOne[H, C](y: CyclicHash[H, C], x: H): H =
  ((x and y.maskOne) shl 1) or (x shr (y.wordSize - 1))

template getFastRightShiftOne[H, C](y:CyclicHash[H, C], x: H): H =
  (x shr 1) or ((x and 1) shl (y.wordSize - 1))

proc trueHash*[H, C](y: CyclicHash[H, C], c: seq[char]): H {.inline.}=
  ## Hash complete sequence of char without the need to update. This is a
  ## helper proceedure to test whether the update proceedure below yeilds
  ## correct results in unit testing
  ##
  var answer: H = 0
  for k in 0 ..< c.len:
    y.fastLeftShiftOne(answer)
    answer = answer xor y.hasher.hashValues[cast[int](c[k])]
    result = answer

proc update*[H, C](y: var CyclicHash[H, C], outChar, inChar: char) {.inline.}=
  ## Updates the rolling hash after shifting left and xoring hash value of
  ## `outChar` add `inChar`
  ##
  var z = y.hasher.hashValues[cast[int](outChar)]
  y.fastLeftShiftN(z)
  y.hashValue = y.getFastLeftShiftOne(y.hashValue) xor z xor 
    y.hasher.hashValues[cast[int](inChar)]

proc reverseUpdate*[H, C](y: var CyclicHash[H, C], outChar, inChar: char) {.inline.}=
  # Cyclic Hash is reversible! We can undo a previous update by performing a
  # right shift. See `test_cyclichash` for an example.
  #
  var z = y.hasher.hashValues[cast[int](outChar)]
  y.fastLeftShiftN(z)
  y.hashValue = y.hashValue xor z xor y.hasher.hashValues[cast[int](inChar)]
  y.hashValue = y.getFastRightShiftOne(y.hashValue)

proc eat*[H, C](y: var CyclicHash[H, C], inChar: char) {.inline.} =
  ## Move rolling hash forward by shifting left and xoring the hash value of
  ## the new `inChar`
  ##
  y.fastLeftShiftOne(y.hashValue)
  y.hashValue = y.hashValue xor y.hasher.hashValues[cast[int](inChar)]

proc hashPrepend*[H, C](y: var CyclicHash[H, C], x: char): H {.inline.}=
  ## Prepends a rolling hash by adding a hashed `x` into the front of the
  ## rolling hash sequence
  ##
  var z = y.hasher.hashValues[cast[int](x)]
  y.fastLeftShiftN(z)
  result = z xor y.hashValue

proc hashExtend*[H, C](y: CyclicHash[H, C], x: char): H {.inline.}=
  ## Extends a rolling hash by adding a hashed `x` into the end of the rolling
  ## hash sequence
  ##
  result = y.getFastLeftShiftOne(y.hashValue) xor
    y.hasher.hashValues[cast[int](x)]

proc reset*[H, C](y: var CyclicHash[H, C]) {.inline.}=
  ## Reset the hash values of rolling hash to `0`
  y.hashValue = 0
