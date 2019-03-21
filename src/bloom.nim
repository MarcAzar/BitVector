# Copyright (C) Marc Azar. All rights reserved.
# MIT License. Look at LICENSE.txt for more info
#
## A Bloom Filter implementation using Cyclic Polynomial Hash function. It can
## automatically calculate optimal number of hashes given a target bit size. 
## It can also automatically assign bit size given number of false positives.
## Bloom Filter base is a bitvector.
##
import bitvector
import private/cyclichash
import math

type
  HashType = int
  CharType = char
  BloomFilter*[T: SomeUnsignedInt] = object
    bitVector: BitVector[T]
    numberOfHashes: int
    numberOfBits: int
    hasher: CyclicHash

proc optimalNumOfHash(numOfBits, numOfEls: int): int {.inline.} =
  ## Calculate optimal number of hash functions based on bit size of Bloom
  ## Fliter. k = (m/n) * ln(2)
  ##
  max(int((numOfBits / numOfEls) * ln(2.0).ceil), 1)

proc recommendedBitSize(numOfEls: int, falsePositives: float): int{.inline.} =
  ## Estimate the bit size of the Bloom Filter based on required 
  ## false positive rate. m = - n*ln(p) / (ln(2))^2
  ##
  assert(numOfEls > 0)
  assert(0.0 < falsePositives and falsePositives < 1.0)
  int((numOfEls.float * ln(falsePositives)) / (-8.0 * log(2.0, 2)^2).ceil)

proc newBloomFilter*[T](numberOfElements: int, numberOfBits: int, numOfHashes: int = 0): BloomFilter[T] {.inline.} =
  ## Creat a new Bloom Filter. If number of hashes provided is zero, we
  ## calculate the optimal number of hashes automatically.
  ##
  let numberOfHashes = if numOfHashes == 0: optimalNumOfHash(numberOfBits, numberOfElements) else: numOfHashes
  result = BloomFilter[T](
    bitVector: newBitVector[T](numberOfBits),
    numberOfHashes: numberOfHashes,
    numberOfBits: numberOfBits,
    hasher: newCyclicHash(4, 19)
  )

proc newBloomFilter*[T](numberOfElements: int, falsePositives: float, numOfHashes: int = 0): BloomFilter[T] {.inline.} =
  ## Create a new Bloom Filter. If number of hashes provided is zero, we
  ## calculate the optimal number of hashes automatically. Using 
  ## false positive rate provided, we automatically calculate the bit size
  ## required to ensure requirement is met.
  ##
  let numberOfBits = recommendedBitSize(numberOfElements, falsePositives)
  let numberOfHashes = if numOfHashes == 0: optimalNumOfHash(numberOfBits, numberOfElements) else: numOfHashes
  result = BloomFilter[T](
    bitVector: newBitVector[T](numberOfBits),
    numberOfHashes: numberOfHashes,
    numberOfBits: numberOfBits,
    hasher: newCyclicHash(4, 19)
  )

{.push overflowChecks: off.}
proc hash(bf: var BloomFilter, item: string): seq[int] {.inline.}=
  ## Internal hashing function based on Cyclic Polynomial Hash, but used as a
  ## normal non-rolling hash function for demonstration purposes.
  ##
  bf.hasher.reset
  for j in 0..<4:
    bf.hasher.eat(item[j])
  for j in 4..<item.len:
    bf.hasher.update(item[j-4], item[j])
  newSeq(result, bf.numberOfHashes)
  for i in 0..<bf.numberOfHashes:
    result[i] = (bf.hasher.hashValue + bf.hasher.hashValue * i) mod 
      bf.numberOfBits
  return result
{.pop.}

proc insert*(bf: var BloomFilter, item: string) {.inline.} =
  ## Insert `item` into Bloom Filter
  let hashes = hash(bf, item)
  for h in hashes:
    bf.bitVector[h] = 1

proc lookup*(bf: var BloomFilter, item: string): bool {.inline.} =
  ## Check if `item` is in Bloom Filter
  let hashes = hash(bf, item)
  result = true
  for h in hashes:
    result = result and bool(bf.bitVector[h])
  return result
