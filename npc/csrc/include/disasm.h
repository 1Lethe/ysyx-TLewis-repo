#ifndef __DISASM_H
#define __DISASM_H

void init_disasm();
void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);

#endif