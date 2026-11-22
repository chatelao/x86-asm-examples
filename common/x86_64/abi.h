/* ============================================================================
 * Cross-OS x86-64 Assembly Macros (Windows x64 PE/COFF <-> Linux SysV ELF)
 *
 * Preprocessed via `gcc -x assembler-with-cpp`:
 *   - Windows (MinGW-w64) defines _WIN32
 *   - Linux (GCC) defines __linux__
 * ============================================================================ */
#ifndef X86_64_ABI_H
#define X86_64_ABI_H

#ifdef _WIN32
  #define DEF_FUNC(name)    .def name; .scl 2; .type 32; .endef
  #define RODATA_SECTION    .section .rdata,"dr"
  #define GNU_STACK_NOTE
#else
  #define DEF_FUNC(name)    .type name, @function
  #define RODATA_SECTION    .section .rodata
  #define GNU_STACK_NOTE    .section .note.GNU-stack,"",@progbits
#endif

#endif /* X86_64_ABI_H */
