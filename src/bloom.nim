import bitvector
import cyclichash
from times import nil
from strutils import `%`, formatFloat, ffDecimal, toBin
from random import rand

type
  BloomFilter = object
    bitVector: BitVector[uint]
    numberOfHashes: int
    numberOfBitsPerItem: int
    numberOfBits: int

proc newBloomFilter*(numberOfElements: int, numberOfBitsPerItem: int, numberOfHashes: int): BloomFilter =
  let numberOfBits = numberOfElements * numberOfBitsPerItem
  result = BloomFilter(
    bitVector: newBitVector[uint](numberOfBits),
    numberOfHashes: numberOfHashes,
    numberOfBitsPerItem: numberOfBitsPerItem,
    numberOfBits: numberOfBits
  )

{.push overflowChecks: off.}
proc hash(bf: BloomFilter, hashFunc: var CyclicHash, item: string): seq[int] =
  for j in 0..<5:
    hashFunc.eat(item[j])
  for j in 5..<item.len:
    hashFunc.update(item[j-5], item[j])
  newSeq(result, bf.numberOfHashes)
  for i in 0..<bf.numberOfHashes:
    result[i] = (hashFunc.hashValue + hashFunc.hashValue * i) mod 
      bf.numberOfBits
  hashFunc.reset
  return result
{.pop.}

proc insert*(bf: var BloomFilter, hashes: seq[int]) =
  for h in hashes:
    bf.bitVector[h] = 1

proc lookup*(bf: var BloomFilter, hashes: seq[int]): bool =
  result = true
  for h in hashes:
    result = result and bool(bf.bitVector[h])
    return result

when isMainModule:
  echo "Quick working Bloom filter example."
  let nTests = int(2e7)
  var bf = newBloomFilter(numberOfElements = nTests,
      numberOfBitsPerItem = 12, numberOfHashes = 7)
  var hashFn = newCyclicHash[int32, char](5, bf.numberOfBitsPerItem)
  var hashes: seq[int] = bf.hash(hashFn, "Here we go!")
  bf.insert(hashes)
  assert bf.lookup(hashes)
  hashes = bf.hash(hashFn, "I'm not here.")
  assert (not bf.lookup(hashes))

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
    hashes = bf.hash(hashFn, kTestElements[i])
    bf.insert(hashes)
  endTime = times.cpuTime()
  echo("Took ", formatFloat(endTime - startTime, format = ffDecimal,
    precision = 4), " seconds to insert ", nTests, " items.")

  startTime = times.cpuTime()
  for i in 0..(nTests - 1):
    hashes = bf.hash(hashFn, kTestElements[i])
    doAssert bf.lookup(hashes)
  endTime = times.cpuTime()
echo("Took ", formatFloat(endTime - startTime, format = ffDecimal,
  precision = 4), " seconds to lookup ", nTests, " items.")
