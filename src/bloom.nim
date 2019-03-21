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
    hasher: CyclicHash[HashType, CharType]

proc optimalNumOfHash(numOfBits, numOfEls: int): int {.inline.} =
  max(int((numOfBits / numOfEls) * ln(2.0).ceil), 1)

proc recommendedBitSize(numOfEls: int, falsePositives: float): int{.inline.} =
  assert(numOfEls > 0)
  assert(0.0 < falsePositives and falsePositives < 1.0)
  int((numOfEls.float * ln(falsePositives)) / (-8.0 * log(2.0, 2)^2).ceil)

proc newBloomFilter*[T](numberOfElements: int, numberOfBits: int, numOfHashes: int = 0): BloomFilter[T] {.inline.} =
  let numberOfHashes = if numOfHashes == 0: optimalNumOfHash(numberOfBits, numberOfElements) else: numOfHashes
  result = BloomFilter[T](
    bitVector: newBitVector[T](numberOfBits),
    numberOfHashes: numberOfHashes,
    numberOfBits: numberOfBits,
    hasher: newCyclicHash(4, 19)
  )

proc newBloomFilter*[T](numberOfElements: int, falsePositives: float, numOfHashes: int = 0): BloomFilter[T] {.inline.} =
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
  let hashes = hash(bf, item)
  for h in hashes:
    bf.bitVector[h] = 1

proc lookup*(bf: var BloomFilter, item: string): bool {.inline.} =
  let hashes = hash(bf, item)
  result = true
  for h in hashes:
    result = result and bool(bf.bitVector[h])
  return result
