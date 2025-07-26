# ARMv7 Cache Simulator

## Overview
This project is a cache simulator written in ARMv7 assembly, designed to run on the [cpulator ARMv7 emulator](https://cpulator.01xz.net/?sys=armv7). It simulates the behavior of a two-level cache hierarchy (L1 and L2) for an array of memory block accesses, tracking cache hits and misses. The simulator supports configurable cache sizes, replacement policies, and cache mapping modes (Direct Mapped, 2-Way Set Associative, and Fully Associative).

## Features
- **Simulates L1 and L2 caches** with independent size and policy configuration
- **Supports multiple replacement policies**: FIFO, LRU, MRU, LFU, MFU, and Random
- **Configurable cache mapping**: Direct Mapped Cache (DMC), 2-Way Set Associative (2WSA), and Fully Associative Cache (FAC)
- **Tracks and records hit/miss statistics** for both cache levels
- **Customizable input array** of memory block numbers (0-255)
- **Designed for educational use and easy experimentation**

## Project Structure
- `DMC-2WSA.s`: Main ARMv7 assembly source file for DMC and 2WSA modes
- `fullyassociative.s`: ARMv7 assembly source file for Fully Associative Cache mode
- **Data Section**:
  - `inputarray`: Array of memory block numbers to access (modifiable)
  - `hitmissL1`, `hitmissL2`: Arrays to record hit/miss results for each access
  - `cacheL1`, `cacheL2`: Arrays representing the L1 and L2 cache contents
  - `mode`: 1 byte, 0 for DMC, 1 for 2WSA (in DMC-2WSA.s)
  - `countL1`, `countL2`: Arrays for usage/frequency counters (for LFU/MFU)
  - `rand_seed`, `rand_a`, `rand_c`: For random replacement policy
- **Text Section**:
  - `_start`: Entry point, main simulation loop
  - `replacementL1`, `replacementL2`: Handles cache replacement for L1/L2
  - `missL1`, `hitL1`, `missL2`, `hitL2`: Update hit/miss statistics
  - `mod_func`, `get_random`: Utility functions
  - `swapL1`, `swapL2`: Swap blocks for LRU/MRU in 2WSA

## How It Works
1. **Initialization**: Loads input array, cache sizes, policies, and mode.
2. **Simulation Loop**: For each memory access in `inputarray`:
   - Checks L1 cache for hit/miss
   - On L1 miss, checks L2 cache
   - On L2 miss, simulates memory access
   - Updates caches and statistics according to the selected replacement policy and mode
3. **Statistics**: Results are stored in `hitmissL1` and `hitmissL2` arrays for analysis

## Cache Modes

### Direct Mapped Cache (DMC)
- Each memory block maps to exactly one cache line (index = block % cache size)
- On miss, the cache line is replaced with the new block
- Simple and fast, but higher conflict misses

### 2-Way Set Associative (2WSA)
- Cache is divided into sets, each with 2 lines (ways)
- Each block maps to a set (index = block % (cache size / 2)), can be placed in either way
- On miss, replacement policy decides which way to evict
- Reduces conflict misses compared to DMC

### Fully Associative Cache (FAC)
- Any memory block can be placed in any cache line
- No mapping restrictions - maximum flexibility for block placement
- On miss, replacement policy decides which line to evict
- Lowest conflict misses but requires more complex search and replacement logic
- **File**: `fullyassociative.s`
- **Key Features**:
  - Sequential search through all cache lines for hits
  - All replacement policies supported (FIFO, LRU, MRU, LFU, MFU, Random)
  - Optimized for maximum cache utilization

## Replacement Policies
Each policy can be set independently for L1 and L2 (see configuration below):

- **FIFO (First-In, First-Out)**: Replaces the oldest block in the cache/set
- **LRU (Least Recently Used)**: Replaces the block that was least recently accessed
- **MRU (Most Recently Used)**: Replaces the block that was most recently accessed
- **LFU (Least Frequently Used)**: Replaces the block with the lowest access count
- **MFU (Most Frequently Used)**: Replaces the block with the highest access count
- **Random**: Randomly selects a block to replace

### Policy Implementation Details
- **FIFO**: Overwrites the first available or oldest block
- **LRU/MRU**: Uses block swapping to track recent usage (see `swapL1`/`swapL2` for 2WSA, direct manipulation for FAC)
- **LFU/MFU**: Uses `countL1`/`countL2` arrays to track access frequency
- **Random**: Uses a simple linear congruential generator for pseudo-random selection

## Configuration

### For DMC and 2WSA (`DMC-2WSA.s`)
You can modify the following parameters in the `.data` section:
- `inputarray`: Change the sequence of memory block accesses
- `mode`: Set to 0 for DMC, 1 for 2WSA
- `cacheL1`, `cacheL2`: Change the size by modifying `.fill` count (default 4)
- `policy for L1/L2`: Set in `_start` (R1/R2):
  - 0: FIFO
  - 1: LRU
  - 2: MRU
  - 3: LFU
  - 4: MFU
  - 5: Random

### For Fully Associative (`fullyassociative.s`)
You can modify the following parameters in the `.data` section:
- `inputarray`: Change the sequence of memory block accesses
- `cacheL1`, `cacheL2`: Change the size by modifying `.space` allocation (default 4 bytes each)
- `policy for L1/L2`: Set in `_start` (R1/R2):
  - 0: FIFO
  - 1: LRU
  - 2: MRU
  - 3: LFU
  - 4: MFU
  - 5: Random

## How to Run (on cpulator)

### For DMC and 2WSA:
1. Go to [cpulator ARMv7 emulator](https://cpulator.01xz.net/?sys=armv7)
2. Paste the contents of `DMC-2WSA.s` into the editor
3. Modify the `.data` section as needed for your experiment
4. Click **Assemble & Run**
5. Use the memory viewer to inspect `hitmissL1`, `hitmissL2`, `cacheL1`, and `cacheL2` after execution

### For Fully Associative:
1. Go to [cpulator ARMv7 emulator](https://cpulator.01xz.net/?sys=armv7)
2. Paste the contents of `fullyassociative.s` into the editor
3. Modify the `.data` section as needed for your experiment
4. Click **Assemble & Run**
5. Use the memory viewer to inspect `hitmissL1`, `hitmissL2`, `cacheL1`, and `cacheL2` after execution

## Example
Suppose `inputarray` is:
```
.byte 8, 5, 6, 6, 6, 6, 2, 7
```
With L1 and L2 both size 4:
- **DMC/2WSA**: With mode = 1 (2WSA), L1 policy = LRU, L2 policy = LRU
- **FAC**: With L1 policy = LRU, L2 policy = LRU

The simulator will process each access, update caches, and record hits/misses in `hitmissL1` and `hitmissL2`.

## Code Structure (Key Functions)

### DMC and 2WSA (`DMC-2WSA.s`)
- **_start**: Main loop, handles access, mode, and policy selection
- **replacementL1/replacementL2**: Handles block replacement per policy
- **missL1/hitL1/missL2/hitL2**: Update hit/miss arrays and counters
- **mod_func**: Computes modulo for cache indexing
- **get_random**: Generates pseudo-random numbers for random replacement
- **swapL1/swapL2**: Swaps blocks for LRU/MRU in 2WSA

### Fully Associative (`fullyassociative.s`)
- **_start**: Main loop with sequential search through all cache lines
- **replacementL1/replacementL2**: Handles block replacement per policy
- **missL1/hitL1/missL2/hitL2**: Update hit/miss arrays and counters
- **update_new_* functions**: Handle policy-specific updates for new blocks
- **update_hit_* functions**: Handle policy-specific updates for cache hits
- **get_random**: Generates pseudo-random numbers for random replacement
- **mod_func**: Computes modulo for random replacement selection

## Performance Comparison
- **Direct Mapped**: Fastest access time, highest conflict misses
- **2-Way Set Associative**: Good balance of performance and complexity
- **Fully Associative**: Lowest miss rate, highest search complexity

## Customization & Extension
- Change cache sizes by editing `.fill` in `cacheL1`/`cacheL2` (DMC/2WSA) or `.space` allocation (FAC)
- Add more policies or modify existing ones in `replacementL1`/`replacementL2`
- Adjust input patterns for different memory access scenarios
- Compare performance across different cache mapping modes

## Author
**Arian Kheirandish**

## License
This project is for educational purposes. Please credit the author if you use or modify this code.

## Acknowledgments
- ARMv7 architecture documentation
- [cpulator ARMv7 emulator](https://cpulator.01xz.net/?sys=armv7)
- Assembly programming resources and tutorials 