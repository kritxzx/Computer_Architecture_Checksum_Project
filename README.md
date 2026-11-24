# Checksum C & MIPS Assembly

An interactive 8-bit 1's complement checksum calculator implemented in both **C** and **MIPS Assembly**. The program reads a user-specified number of 8-bit binary strings, converts and accumulates them on the fly, folds overflow carries via wrap-around addition, and outputs the final 1's complement checksum in both **Binary** and **Hexadecimal** formats.

## Implementation Highlights
- **1:1 C-to-MIPS Structural Mapping:** Both implementations share identical control flow, variable lifetimes, and memory footprint for straightforward low-level comparison.
- **Zero-Array Streaming:** Processes each binary byte immediately upon input without storing an array of inputs in memory.
- **Custom Bitwise Parsing:** Converts ASCII `'0'`/`'1'` strings directly into integer values using pointer traversal and bit-shifting (`<< 1`), without relying on standard library parsing functions like `strtol`.
- **Wrap-Around Carry Folding:** Repeatedly folds bits overflowing beyond 8 bits (`sum >> 8`) back into the lower 8 bits (`sum & 0xFF`).
- **Hex Lookup Table:** Uses a 16-byte character lookup table (`"0123456789ABCDEF"`) with bit-masking and shifting to format hexadecimal output cleanly.

## Algorithm
1. **Input Validation:** Prompt for the number of bytes (`count`). Terminate with `"Invalid count."` if `count <= 0`.
2. **Accumulation:** Loop `count` times to read each 8-bit binary string, parse it bit-by-bit into an unsigned integer, and add it to `sum`.
3. **Wrap-Around Addition:** While `sum > 0xFF`, add the upper overflow bits (`sum >> 8`) to the lower 8 bits (`sum & 0xFF`).
4. **1's Complement:** Invert all bits of the folded sum (`~sum`) and mask with `0xFF`.
5. **Output Formatting:** Print the 8-bit result bit-by-bit from MSB to LSB, followed by its 2-digit uppercase hexadecimal representation.

## Variable and Register Mapping

| C Variable | MIPS Register | Role |
| :--- | :--- | :--- |
| `count` | `$s0` | Total number of 8-bit bytes to read |
| `sum` | `$s1` | Running total and folded 8-bit sum |
| `checksum` | `$s2` | Final 8-bit 1's complement checksum |
| `i` | `$t0` | Loop counter |
| `p` / `hex_chars` | `$t1` | String pointer for buffer / hex lookup table |
| `value` | `$t2` | Parsed integer value of the current byte |
| `bit` / temp | `$t3` | Current ASCII bit or intermediate bit-mask value |
