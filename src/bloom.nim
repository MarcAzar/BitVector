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
  BloomFilter*[H: Units] = object
    bitVector: BitVector[H]
    numberOfHashes: int
    numberOfBits: int
    numberOfElements: int
    hasher: CyclicHash[H, char]

proc optimalNumOfHash(numOfBits, numOfEls: int): int {.inline.} =
  ## Calculate optimal number of hash functions based on bit size of Bloom
  ## Fliter. k = (m/n) * ln(2)
  ##
  int(((numOfBits / numOfEls) * ln(2.0)).round)

proc recommendedBitSize(numOfEls: int, falsePositiveRate: float): int {.inline.} =
  ## Estimate the bit size of the Bloom Filter based on required 
  ## false positive rate. m = - n*ln(p) / (ln(2))^2
  ##
  assert(numOfEls > 0)
  assert(0.0 < falsePositiveRate and falsePositiveRate < 1.0)
  numOfEls * int(ceil(-1.0 * ln(falsePositiveRate) / ln(2.0)^2 ))

proc newBloomFilter*[H](numberOfElements: int, numberOfBits: int, numOfHashes: int = 0): BloomFilter[H] {.inline.} =
  ## Creat a new Bloom Filter. If number of hashes provided is zero, we
  ## calculate the optimal number of hashes automatically.
  ##
  let numberOfHashes = if numOfHashes == 0:
    optimalNumOfHash(numberOfBits, numberOfElements) else: numOfHashes
  result = BloomFilter[H](
    bitVector: newBitVector[H](numberOfBits),
    numberOfHashes: numberOfHashes,
    numberOfBits: numberOfBits,
    numberOfElements: numberOfElements,
    hasher: newCyclicHash[H, char](1, 20)
  )

proc newBloomFilter*[H](numberOfElements: int, falsePositiveRate: float, numOfHashes: int = 0): BloomFilter[H] {.inline.} =
  ## Create a new Bloom Filter. If number of hashes provided is zero, we
  ## calculate the optimal number of hashes automatically. Using 
  ## false positive rate provided, we automatically calculate the bit size
  ## required to ensure requirement is met.
  ##
  let numberOfBits = recommendedBitSize(numberOfElements, falsePositiveRate)
  let numberOfHashes = if numOfHashes == 0:
    optimalNumOfHash(numberOfBits, numberOfElements) else: numOfHashes
  result = BloomFilter[H](
    bitVector: newBitVector[H](numberOfBits),
    numberOfHashes: numberOfHashes,
    numberOfBits: numberOfBits,
    numberOfElements: numberOfElements,
    hasher: newCyclicHash[H, char](1, 20)
  )

{.push overflowChecks: off.}
proc hash[H](bf: var BloomFilter[H], item: string): seq[int] {.inline.}=
  ## Internal hashing function based on Cyclic Polynomial Hash, but used as a
  ## normal non-rolling hash function for demonstration purposes.
  ##
  bf.hasher.reset
  var slide = item.len - bf.numberOfHashes
  if slide < 0:
      slide = 1
  elif slide > bf.numberOfHashes:
      slide = bf.numberOfHashes - 1
  newSeq(result, bf.numberOfHashes)
  for j in 0..<slide:
    bf.hasher.eat(item[j])
    result[j] = abs(cast[int](bf.hasher.hashValue))
  if (item.len - bf.numberOfHashes) > 0:
    for j in slide..<bf.numberOfHashes:
      bf.hasher.update(item[j-slide], item[j])
      result[j] = abs(cast[int](bf.hasher.hashValue))
  else:
    for j in slide..<item.len:
      bf.hasher.update(item[j-slide], item[j])
      result[j] = abs(cast[int](bf.hasher.hashValue))
    for i in item.len..<bf.numberOfHashes:
      result[i] = abs(cast[int](result[i-1] + result[i-2] * i)) mod 
        bf.numberOfBits
  return result
{.pop.}

proc insert*[H](bf: var BloomFilter[H], item: string) {.inline.} =
  ## Insert `item` into Bloom Filter
  let hashes = hash[H](bf, item)
  for h in hashes:
    bf.bitVector[h] = 1

proc lookup*[H](bf: var BloomFilter[H], item: string): bool {.inline.} =
  ## Check if `item` is in Bloom Filter
  let hashes = hash[H](bf, item)
  result = true
  for h in hashes:
    result = result and bool(bf.bitVector[h])
  return result

proc `$`*[H](bf: BloomFilter[H]): string {.inline.} =
  let bitsPerItem: float = bf.numberOfBits / bf.numberOfElements
  let errorRate: float = exp(-1.0 * bitsPerItem * ln(2.0)^2)
  let size: float = bf.numberOfBits.float * 125e-9
  result = "Bloom filter with " & $bf.numberOfElements & " capacity, " &
    $bf.numberOfHashes & " hash functions, and with a target error rate of " &
    $errorRate & " and occupying size(MB) " & $size
