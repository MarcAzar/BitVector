import bitvector
from os import nil
from strutils import `%`, formatFloat, ffDecimal, toBin
from random import rand, randomize
from times import nil

when isMainModule:
  echo "Testing bitvector library"
  when not defined(release):
    let nTests: int = int(1e6)
    let nBits: int = int(2e9)
  else:
    let nTests = int(1e8)
    let nBits = int(2e9)

  block:
    var ba = newBitVector[uint](64)
    ba[0] = 1
    ba[2] = 1
    ba[7] = 1
    assert(ba[0..7] == 133, "incorrect result: " & $ba[0..7])
    assert(ba[0..4] == 5, "incorrect result: " & $ba[0..4])
    assert(ba[1..4] == 2, "incorrect result: " & $ba[1..4])
  
  var bitarrayA = newBitVector[uint](nBits)
  bitarrayA[0] = 1
  bitarrayA[1] = 1
  bitarrayA[2] = 1

  # Test range lookups/inserts
  bitarrayA[65] = 1
  doAssert bitarrayA[65] == 1
  doAssert bitarrayA[2..66] == uint(-9223372036854775807) # Lexer error prevents using 9223372036854775809'u64 directly

  bitarrayA[131] = 1
  bitarrayA[194] = 1
  assert bitarrayA[2..66] == bitarrayA[131..194]
  let sliceValue = bitarrayA[131..194]
  bitarrayA[270..333] = sliceValue
  bitarrayA[400..463] = uint(-9223372036854775807)
  assert bitarrayA[131..194] == bitarrayA[270..333]
  assert bitarrayA[131..194] == bitarrayA[400..463]

  # Seed RNG
  randomize(2882)  # Seed the RNG
  var nTestPositions = newSeq[int](nTests)

  for i in 0..(nTests - 1):
    nTestPositions[i] = rand(nBits)

  # Timing tests
  var startTime, endTime: float
  startTime = times.cpuTime()
  for i in 0..(nTests - 1):
    bitarrayA[nTestPositions[i]] = 1
  endTime = times.cpuTime()
  echo("Took ", formatFloat(endTime - startTime, format = ffDecimal,
  precision = 4), " seconds to insert ", nTests, " items (in-memory).")

  startTime = times.cpuTime()
  for i in 0..(nTests - 1):
    doAssert bitarrayA[nTestPositions[i]] == 1
  endTime = times.cpuTime()
  echo("Took ", formatFloat(endTime - startTime, format = ffDecimal,
  precision = 4), " seconds to lookup ", nTests, " items (in-memory).")

  # Test that bit arrays < sizeof(BitArrayScalar) fail
  try:
    var bitarray64 = newBitVector[uint](64)
    doAssert bitarray64.cap == 64
    doAssert bitarray64.len == 1
  except:
    echo "wrong capacity"

  # Test clearing bits
  var bitarrayE = newBitVector[uint](64)
  bitarrayE[1] = 1
  bitarrayE[2] = 0
  doAssert bitarrayE[1] == 1

  echo("All tests successfully completed.")
