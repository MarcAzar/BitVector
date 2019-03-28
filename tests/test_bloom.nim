import bloom
import os, times
from random import rand

type
  H = uint64

when isMainModule:
  echo "Quick working Bloom filter example."
  let nTests = int(1e7)
  var falsePositiveRate = 0.001
  var bf = newBloomFilter[H](nTests, falsePositiveRate, 0, true)
  echo bf
  bf.insert("Here we go!")
  assert bf.lookup("Here we go!")
  assert (not bf.lookup("I'm not here"))

  let testStringLen = 7
  let sampleChars =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  var kTestElements = newSeq[string](nTests)
  for i in 0..(nTests - 1):
    var newString = ""
    for j in 0..testStringLen:
      newString.add(sampleChars[rand(51)])
    kTestElements[i] = newString
  
  echo("Takes in seconds to insert ", nTests, " items:")
  var startTime, endtime: float 
  startTime = cpuTime()
  for i in 0..(nTests - 1):
    bf.insert(kTestElements[i])
  endTime = cpuTime()
  echo(endTime - startTime)

  echo("Takes in seconds to lookup ", nTests, " items:")
  startTime = cpuTime()
  for i in 0..(nTests - 1):
    doAssert bf.lookup(kTestElements[i])
  endTime = cpuTime()
  echo(endTime - startTime)

  var falsePositives: int = 0
  for i in 0..(nTests - 1):
    var newString = ""
    for j in 0..(testStringLen + 1): # By def not in bf as 9 chars not 8
      newString.add(sampleChars[rand(51)])
    if bf.lookup(newString):
      falsePositives += 1
  echo("N false positives (of ", nTests, " lookups): ", falsePositives)
  echo("False positive rate ", falsePositives / nTests)

  var lookupErrors = 0
  for i in 0..(nTests - 1):
    if not bf.lookup(kTestElements[i]):
      lookupErrors += 1
  echo("N lookup errors (should be 0): ", lookupErrors)

