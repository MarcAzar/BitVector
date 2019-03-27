# Copyright (C) Marc Azar. All rights reserved.
# MIT License. Look at LICENSE.txt for more info
#
## A Bloom Filter implementation using Cyclic Polynomial Hash function. It can
## automatically calculate optimal number of hashes given a target bit size. 
## It can also automatically assign bit size given number of false positives.
## Bloom Filter base is a bitvector.
##
import bitvector
import math
import hashes

{.compile: "murmur3.c".}

type
  TMurmurHashes = array[0..1, int]
  BloomFilter*[H: Units] = object
    bitVector: BitVector[H]
    numberOfHashes: int
    numberOfBits: int
    numberOfElements: int
    useMurmurHash: bool 

proc rawMurmurHash(key: cstring, length: int, seed: uint32): TMurmurHashes {.importc: "MurmurHash3_x64_128".}

proc murmurHash(key: string, seed: uint32): TMurmurHashes =
  result = [0,0]
  result = rawMurmurHash(key = key, length = key.len, seed = seed)

proc hashA(item: string, maxValue: int): int =
  result = hash(item) mod maxValue

proc hashB(item: string, maxValue: int): int =
  result = hash(item & " b") mod maxValue

proc hashN(item: string, n: int, maxValue: int): int =
  ## Get the nth hash of a string using the formula hash_a + n * hash_b
  ## which uses 2 hash functions vs. k and has comparable properties
  ## See Kirsch and Mitzenmacher, 2008: 
  ## http://www.eecs.harvard.edu/~kirsch/pubs/bbbf/rsa.pdf
  result = abs((hashA(item, maxValue) + n * hashB(item, maxValue))) mod
    maxValue

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

proc newBloomFilter*[H](numberOfElements: int, numberOfBits: int, numOfHashes: int = 0, useMurmurHash: bool = true): BloomFilter[H] {.inline.} =
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
    useMurmurHash: useMurmurHash
  )

proc newBloomFilter*[H](numberOfElements: int, falsePositiveRate: float, numOfHashes: int = 0, useMurmurHash: bool = true): BloomFilter[H] {.inline.} =
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
    useMurmurHash: useMurmurHash
  )

{.push overflowChecks: off.}

proc hashMurmur[H](bf: BloomFilter[H], item: string): seq[int] {.inline.}=
  result = newSeq[int](bf.numberOfHashes)
  let murmurHashes = murmurHash(key = item, seed = 0'u32)
  for i in 0..(bf.numberOfHashes - 1):
    result[i] = abs(murmurHashes[0] + i * murmurHashes[1]) mod bf.numberOfBits
  return result

{.pop.}

proc hashNim[H](bf: BloomFilter[H], item: string): seq[int] {.inline.} =
  newSeq(result, bf.numberOfHashes)
  for i in 0..(bf.numberOfHashes - 1):
    result[i] = hashN(item, i, bf.numberOfBits)
  return result

proc hasher[H](bf: BloomFilter[H], item: string): seq[int] {.inline.}=
  if bf.useMurmurHash:
    result = bf.hashMurmur(item = item)
  else:
    result = bf.hashNim(item = item)
  return result

proc insert*[H](bf: var BloomFilter[H], item: string) {.inline.} =
  ## Insert `item` into Bloom Filter
  var hashes = hasher[H](bf, item)
  for h in hashes:
    bf.bitVector[h] = 1

proc lookup*[H](bf: var BloomFilter[H], item: string): bool {.inline.} =
  ## Check if `item` is in Bloom Filter
  var hashes = hasher[H](bf, item)
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
