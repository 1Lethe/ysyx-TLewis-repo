#include <proc.h>
#include <elf.h>

#ifdef __LP64__
# define Elf_Ehdr Elf64_Ehdr
# define Elf_Phdr Elf64_Phdr
#else
# define Elf_Ehdr Elf32_Ehdr
# define Elf_Phdr Elf32_Phdr
#endif

#if defined(__ISA_AM_NATIVE__)
# define EXPECT_TYPE EM_X86_64
#elif defined(__riscv) && !defined(__riscv_e)
# define EXPECT_TYPE EM_RISCV
#else
# error unsupported ISA __ISA__
#endif

static uintptr_t loader(PCB *pcb, const char *filename) {
  Elf_Ehdr elf_ehdr;
  Elf_Phdr elf_phdr;

  ramdisk_read(&elf_ehdr, 0, sizeof(elf_ehdr));

  assert(*(uint32_t *)elf_ehdr.e_ident == 0x464c457f); // elf magic number
  assert(elf_ehdr.e_machine == EXPECT_TYPE);

  for(int i = 0; i < elf_ehdr.e_phnum; i++){
    // read elf program header (offset i) in ramdisk to struct elf_phdr
    ramdisk_read(&elf_phdr, elf_ehdr.e_phoff + i * elf_ehdr.e_phentsize, elf_ehdr.e_phentsize);
    if(elf_phdr.p_type == PT_LOAD){
      uint8_t *vaddr_ptr = (uint8_t *)elf_phdr.p_vaddr;

      // write segment to memory
      for(int j = 0; j < elf_phdr.p_memsz; j++){
        if(j < elf_phdr.p_filesz){
          uint8_t seg_data = 0;
          ramdisk_read(&seg_data, elf_phdr.p_offset + j, 1);
          *(vaddr_ptr + j) = seg_data;
        }else{
          *(vaddr_ptr + j) = 0;
        }
      }
    }
  }

  return elf_ehdr.e_entry;
}

void naive_uload(PCB *pcb, const char *filename) {
  uintptr_t entry = loader(pcb, filename);
  Log("Jump to entry = %p", entry);
  ((void(*)())entry) ();
}

