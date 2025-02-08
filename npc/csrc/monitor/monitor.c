#include "monitor.h"
#include "debug.h"
#include "trace.h"

char *log_file = NULL;
char *diff_so_file = NULL;
char *img_file = NULL;
char *elf_file = NULL;
int difftest_port = 1234;
bool is_batch_mode = false;

Elf32_Shdr shdr_strtab;
Elf32_Shdr shdr_symtab;

static void set_batch_mode(void){
    is_batch_mode = true;
}

static int parse_args(int argc, char *argv[]) {
    const struct option table[] = {
        {"log"      , required_argument, NULL, 'l'},
        {"diff"     , required_argument, NULL, 'd'},
        {"port"     , required_argument, NULL, 'p'},
        {"help"     , no_argument      , NULL, 'h'},
        {"elf"      , required_argument, NULL, 'e'},
        {0          , 0                , NULL,  0 },
    };
    int o;
    while ( (o = getopt_long(argc, argv, "-bhl:d:p:", table, NULL)) != -1) {
    switch (o) {
        case 'b': set_batch_mode(); break;
        case 'p': sscanf(optarg, "%d", &difftest_port); break;
        case 'l': log_file = optarg; break;
        case 'd': diff_so_file = optarg; break;
        case 'e': elf_file = optarg;break;
        case 1: img_file = optarg; return 0;
        default:
            printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
            printf("\t-l,--log=FILE           output log to FILE\n");
            printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
            printf("\t-p,--port=PORT          run DiffTest with port PORT\n");
            printf("\n");
            exit(0);
        }
    }
    return 0;
}

long load_img() {
    if(img_file == NULL){
        printf("No image is given.Use the default build-in image.\n");
        cpy_buildin_img();
        return 4096;
    }

    FILE *fp = fopen(img_file, "rb");
    assert(fp != NULL);

    fseek(fp, 0, SEEK_END);
    long size = ftell(fp);

    printf("The image is %s, size = %ld.\n", img_file, size);

    fseek(fp, 0, SEEK_SET);
    int ret = fread(guest_to_host(RESET_VECTOR), size, 1, fp);
    assert(ret == 1);

    fclose(fp);

    return size;
}

static void parse_elf(Elf32_Shdr *shdr_strtab_ret, Elf32_Shdr *shdr_symtab_ret){
  if(elf_file == NULL){
    printf("No elf file is given.\n");
    return ;
  }

  FILE *fp = fopen(elf_file, "r");
  Assert(fp, "Can not open '%s'",elf_file);

  /* Read ELF header */
  Elf32_Ehdr elf_ehdr;
  Assert(fread(&elf_ehdr, 1, sizeof(Elf32_Ehdr), fp) == sizeof(Elf32_Ehdr), \
    "Failed to read '%s' elf_ehd", elf_file);
  Assert(elf_ehdr.e_ident[0] == 0x7f || elf_ehdr.e_ident[1] == 'E' || \
    elf_ehdr.e_ident[2] != 'L' || elf_ehdr.e_ident[3] == 'F', "Wrong Elf file.");

  Assert(fseek(fp, elf_ehdr.e_shoff, SEEK_SET) != -1, \
    "Faided to read '%s'", elf_file);

  /* Read ELF Section header and extract symtab and strtab */
  Elf32_Shdr elf_shdr;
  Elf32_Shdr elf_shdr_symtab;
  Elf32_Shdr elf_shdr_strtab;
  for(int i = 0; i < elf_ehdr.e_shnum; i++){
    memset(&elf_shdr, 0, sizeof(Elf32_Shdr));
    Assert(fread(&elf_shdr, 1, elf_ehdr.e_shentsize, fp) != -1, \
      "Failed to read '%s' shdr[%d]", elf_file, i);
    if(elf_shdr.sh_type == SHT_SYMTAB){
      memcpy(&elf_shdr_symtab, &elf_shdr, elf_ehdr.e_shentsize);
    }else if(elf_shdr.sh_type == SHT_STRTAB && i != elf_ehdr.e_shstrndx){
      memcpy(&elf_shdr_strtab, &elf_shdr, elf_ehdr.e_shentsize);
    }
  }

  fclose(fp);
  *shdr_strtab_ret = elf_shdr_strtab;
  *shdr_symtab_ret = elf_shdr_symtab;
  return ;
}

void monitor_init(int argc, char *argv[]){
    parse_args(argc, argv);
    load_img();
    parse_elf(&shdr_strtab, &shdr_symtab);
    ftrace_init();
}