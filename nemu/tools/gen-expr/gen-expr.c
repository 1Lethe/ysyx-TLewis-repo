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

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include <string.h>
#include <stdbool.h>

// this should be enough
static char buf[65536] = {};
static char code_buf[65536 + 128] = {}; // a little larger than `buf`
static char *code_format =
"#include <stdio.h>\n"
"int main() { "
"  unsigned result = %s; "
"  printf(\"%%u\", result); "
"  return 0; "
"}";

bool start_gen_flag = 0;
int depth = 0;

static uint32_t choose(uint32_t n){
  return (rand() % n);
}

static int gen_num(void){
  char num_buf[20];
  sprintf(num_buf, "%d", (uint32_t)choose(1000));
  strncat(buf, num_buf, 20);
  return 0;
}

static int gen(char x){
  strncat(buf, &x, 1);
  return 0;
}

static int gen_rand_op(void){
  char rand_op;
  switch (choose(4)){
    case 0 : rand_op = '+';break;
    case 1 : rand_op = '-';break;
    case 2 : rand_op = '*';break;
    case 3 : rand_op = '/';break;
    default : assert(0);
  }
  strncat(buf, &rand_op, 1);
  return 0;
}

static void gen_rand_expr() {
  if((strlen(buf) >= sizeof(buf)/sizeof(buf[0]) - 20) || depth >= 20){
    gen_num();
    return;
  }else{
    depth++;
    switch (choose(4))
    {
      case 0 : gen_num();start_gen_flag = true;break;
      case 1 : gen('('); gen_rand_expr(); gen(')');start_gen_flag = true; break;
      case 2 : gen_rand_expr(); gen_rand_op(); gen_rand_expr();start_gen_flag = true;break;
      case 3 : if(start_gen_flag) gen(' '); gen_rand_expr();break;
      default:
        break;
    }
  depth--;
  }
}

int main(int argc, char *argv[]) {
  int seed = time(0);
  srand(seed);
  int loop = 1;
  if (argc > 1) {
    sscanf(argv[1], "%d", &loop);
  }
  int i;
  for (i = 0; i < loop; i ++) {
    memset(buf,'\0',sizeof(buf)/sizeof(buf[0]));
    gen_rand_expr();
    start_gen_flag = false;

    sprintf(code_buf, code_format, buf);

    FILE *fp = fopen("/tmp/.code.c", "w");
    assert(fp != NULL);
    fputs(code_buf, fp);
    fclose(fp);

    int ret = system("gcc -w /tmp/.code.c -o /tmp/.expr");
    if (ret != 0) continue;

    fp = popen("/tmp/.expr", "r");
    assert(fp != NULL);

    int result;
    ret = fscanf(fp, "%d", &result);
    pclose(fp);

    printf("%u %s\n", result, buf);
  }
  return 0;
}
