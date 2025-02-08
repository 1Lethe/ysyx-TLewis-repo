#include "monitor.h"
#include "debug.h"

char *log_file = NULL;
char *diff_so_file = NULL;
char *img_file = NULL;
int difftest_port = 1234;
bool is_batch_mode = false;

static void set_batch_mode(void){
    is_batch_mode = true;
}

static int parse_args(int argc, char *argv[]) {
    const struct option table[] = {
        {"log"      , required_argument, NULL, 'l'},
        {"diff"     , required_argument, NULL, 'd'},
        {"port"     , required_argument, NULL, 'p'},
        {"help"     , no_argument      , NULL, 'h'},
        {0          , 0                , NULL,  0 },
    };
    int o;
    while ( (o = getopt_long(argc, argv, "-bhl:d:p:", table, NULL)) != -1) {
    switch (o) {
        case 'b': set_batch_mode(); break;
        case 'p': sscanf(optarg, "%d", &difftest_port); break;
        case 'l': log_file = optarg; break;
        case 'd': diff_so_file = optarg; break;
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
    Assert(0==1,"test");

    return size;
}

void monitor_init(int argc, char *argv[]){
    parse_args(argc, argv);
    load_img();
}