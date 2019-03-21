import bloom
import os, times
from random import rand

when isMainModule:
  echo "Quick working Bloom filter example."
  let nTests = int(2e7)
  let falsePositives = 0.01
  var bf = newBloomFilter[uint](nTests, falsePositives, 0)
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

  echo("Takes in seconds to insert ", nTests, " items:")
  var startTime, endtime: float 
  startTime = times.cpuTime()
  for i in 0..(nTests - 1):
    bf.insert(kTestElements[i])
  endTime = times.cpuTime()
  echo(endTime - startTime)

  echo("Takes in seconds to lookup ", nTests, " items:")
  startTime = times.cpuTime()
  for i in 0..(nTests - 1):
    doAssert bf.lookup(kTestElements[i])
  endTime = times.cpuTime()
  echo(endTime - startTime)
