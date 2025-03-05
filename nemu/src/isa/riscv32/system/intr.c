/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>

#ifdef CONFIG_ETRACE
static char mcause_val[8][32] = {
  "Environment call from M-mode",
};
#endif

word_t isa_raise_intr(word_t NO, vaddr_t epc) {
  /* TODO: Trigger an interrupt/exception with ``NO''.
   * Then return the address of the interrupt/exception vector.
   */
  csr_write(CSR_MEPC, epc);
  csr_write(CSR_MCAUSE, NO);
  csr_write(CSR_MSTATUS, 0x1800);
  word_t e_entry = csr_read(CSR_MTVEC);

#ifdef CONFIG_ETRACE
  char cause_text[32];
  switch(NO){
    case 0xb : strncpy(cause_text, mcause_val[0], 32); break;
    default : panic("unsupported ecause NO %d", NO);
  }
  printf("ETRACE mcause 0x%x describe '%s' epc 0x%x\n", NO, cause_text, epc);
#endif

  return e_entry;
}

word_t isa_query_intr() {
  return INTR_EMPTY;
}
