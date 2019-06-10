import bitvector, os, times
from random import rand, randomize

type
  H = uint64

when isMainModule:
  echo "Testing bitvector library"
  when not defined(release):
    let nTests: int = int(1e6)
    let nBits: int = int(2e9)
  else:
    let nTests = int(1e8)
    let nBits = int(2e9)

  block:
    var ba = newBitVector[H](64)
    ba[0] = 1
    ba[2] = 1
    ba[7] = 1
    assert(ba[0..7] == 133, "incorrect result: " & $ba[0..7])
    assert(ba[0..4] == 5, "incorrect result: " & $ba[0..4])
    assert(ba[1..4] == 2, "incorrect result: " & $ba[1..4])
  
  var bitvectorA = newBitVector[H](nBits)
  bitvectorA[0] = 1
  bitvectorA[1] = 1
  bitvectorA[2] = 1

  # Test range lookups/inserts
  bitvectorA[65] = 1
  doAssert bitvectorA[65] == 1
  doAssert bitvectorA[2..66] == (-9223372036854775807).H # Lexer error prevents using 9223372036854775809'u64 directly

  bitvectorA[131] = 1
  bitvectorA[194] = 1
  assert bitvectorA[2..66] == bitvectorA[131..194]
  let sliceValue = bitvectorA[131..194]
  bitvectorA[270..333] = sliceValue
  bitvectorA[400..463] = (-9223372036854775807).H # Lexer error prevents using 9223372036854775809'u64 directly
  assert bitvectorA[131..194] == bitvectorA[270..333]
  assert bitvectorA[131..194] == bitvectorA[400..463]

  # Seed RNG
  randomize(2882)  # Seed the RNG
  var nTestPositions = newSeq[int](nTests)

  for i in 0..(nTests - 1):
    nTestPositions[i] = rand(nBits)

  # Timing tests
  echo("Time in seconds to insert ", nTests, " items (in-memory).")
  var startTime, endTime: float
  startTime = cpuTime()
  for i in 0..(nTests - 1):
    bitvectorA[nTestPositions[i]] = 1
  endTime = cpuTime()
  echo(endTime - startTime)

  echo("Time in seconds to lookup ", nTests, " items (in-memory).")
  startTime = cpuTime()
  for i in 0..(nTests - 1):
    doAssert bitvectorA[nTestPositions[i]] == 1
  endTime = cpuTime()
  echo(endTime - startTime)

  # Test that bit arrays < sizeof(BitArrayScalar) fail
  var bitvector64 = newBitVector[H](64)
  doAssert bitvector64.cap == 64
  doAssert bitvector64.len == 1

  # Test clearing bits
  var bitvectorE = newBitVector[H](64)
  bitvectorE[1] = 1
  bitvectorE[2] = 0
  doAssert bitvectorE[1] == 1

  echo("All tests successfully completed.")
