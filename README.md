[![BYOND unit tests](https://github.com/spacestation13/dm-test-suite/actions/workflows/byond_tests.yml/badge.svg)](https://github.com/spacestation13/dm-test-suite/actions/workflows/byond_tests.yml)

## DM Test Suite
This is a suite of tests and the CI to run them against the latest BYOND engine.

The purpose of this repository is to ensure integrity of the latest BYOND release.

# Tests
Unit tests are composed of a single proc `/proc/RunTest` in a file. With no tags, it is expected that the file will compile and run without errors (or printing to `world.log`).

Some tags are available: 
- `// COMPILE ERROR` - this test is expected to fail to compile
- `// RUNTIME ERROR` - this test is expected to compile, but throw an error at runtime
- `// IGNORE` - do not process this file
