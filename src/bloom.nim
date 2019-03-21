import bitvector
import cyclichash
from times import nil
from strutils import `%`, formatFloat, ffDecimal, toBin
from random import rand
import math

type
  BloomFilter*[T] = object
    bitVector: BitVector[T]
    numberOfHashes: int
    numberOfBits: int
    hasher: CyclicHash[T,char]

proc optimalNumOfHash(numOfBits, numOfEls: int): int {.inline.} =
  max(int((numOfBits / numOfEls) * ln(2.0).ceil), 1)

proc recommendedBitSize(numOfEls: int, falsePositives: float): int{.inline.} =
  assert(numOfEls > 0)
  assert(0.0 < falsePositives and falsePositives < 1.0)
  int((numOfEls.float * ln(falsePositives)) / (-8.0 * log(2.0, 2)^2).ceil)

proc newBloomFilter*[T](numberOfElements: int, numberOfBits: int, numOfHashes: int = 0): BloomFilter[T] =
  let numberOfHashes = if numOfHashes == 0: optimalNumOfHash(numberOfBits, numberOfElements) else: numOfHashes
  echo numberOfHashes
  result = BloomFilter[T](
    bitVector: newBitVector[T](numberOfBits),
    numberOfHashes: numberOfHashes,
    numberOfBits: numberOfBits,
    hasher: newCyclicHash[T, char](4, 19)
  )

proc newBloomFilter*[T](numberOfElements: int, falsePositives: float, numOfHashes: int = 0): BloomFilter[T] =
  let numberOfBits = recommendedBitSize(numberOfElements, falsePositives)
  let numberOfHashes = if numOfHashes == 0: optimalNumOfHash(numberOfBits, numberOfElements) else: numOfHashes
  result = BloomFilter[T](
    bitVector: newBitVector[T](numberOfBits),
    numberOfHashes: numberOfHashes,
    numberOfBits: numberOfBits,
    hasher: newCyclicHash[T, char](4, 19)
  )

{.push overflowChecks: off.}
proc hash(bf: var BloomFilter, item: string): seq[int] =
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

proc insert*(bf: var BloomFilter, item: string) =
  let hashes = hash(bf, item)
  for h in hashes:
    bf.bitVector[h] = 1

proc lookup*(bf: var BloomFilter, item: string): bool =
  let hashes = hash(bf, item)
  result = true
  for h in hashes:
    result = result and bool(bf.bitVector[h])
    return result

when isMainModule:
  echo "Quick working Bloom filter example."
  let nTests = int(2e7)
  var bf = newBloomFilter[int32](nTests, 0.01, 0)
  bf.insert("Here we go!")
  assert bf.lookup("Here we go!")
  assert (not bf.lookup("I'm not here"))

  let testStringLen = 50
  let sampleChars =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  var kTestElements = newSeq[string](nTests)
  for i in 0..(nTests - 1):
    var newString = ""
    for j in 0..(testStringLen):
      newString.add(sampleChars[rand(51)])
    kTestElements[i] = newString

  var startTime, endtime: float 
  startTime = times.cpuTime()
  for i in 0..(nTests - 1):
    bf.insert(kTestElements[i])
  endTime = times.cpuTime()
  echo("Took ", formatFloat(endTime - startTime, format = ffDecimal,
    precision = 4), " seconds to insert ", nTests, " items.")

  startTime = times.cpuTime()
  for i in 0..(nTests - 1):
    doAssert bf.lookup(kTestElements[i])
  endTime = times.cpuTime()
echo("Took ", formatFloat(endTime - startTime, format = ffDecimal,
  precision = 4), " seconds to lookup ", nTests, " items.")
