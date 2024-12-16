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

/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>

#define USE_DEBUG
enum {
  TK_NOTYPE = 256, TK_POSTIVE_NUM,TK_EQ,

  /* TODO: Add more token types */
  TK_PLUS = '+',
  TK_SUB = '-',
  TK_MUL = '*',
  TK_DIV = '/',
  TK_LEFT_PARE = '(',
  TK_RIGHT_PARE = ')',

};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

  /* TODO: Add more rules.
   * Pay attention to the precedence level of different rules.
   * TODO: Add negative num.
   */

  {" +", TK_NOTYPE},             // spaces
  {"[0-9]+", TK_POSTIVE_NUM},    // decimal digit
  {"\\+", TK_PLUS},              // plus
  {"-", TK_SUB},                 // sub
  {"\\*", TK_MUL},               // multiply
  {"\\/", TK_DIV},               // divide
  {"\\(", TK_LEFT_PARE},         // left parenthesis
  {"\\)", TK_RIGHT_PARE},        // right parenthesis
  {"==", TK_EQ},                 // equal
};

#define NR_REGEX ARRLEN(rules)

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex() {
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i ++) {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0) {
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}

typedef struct token {
  int type;
  char str[32];
} Token;

static Token tokens[32] __attribute__((used)) = {};
static int nr_token __attribute__((used))  = 0;

static bool make_token(char *e) {
  int position = 0;
  int i;
  regmatch_t pmatch;

  nr_token = 0;

  while (e[position] != '\0') {
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i ++) {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;

        Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
            i, rules[i].regex, position, substr_len, substr_len, substr_start);

        position += substr_len;

        /* TODO: Now a new token is recognized with rules[i]. Add codes
         * to record the token in the array `tokens'. For certain types
         * of tokens, some extra actions should be performed.
         */

        switch (rules[i].token_type) {
          case TK_NOTYPE : break;
          case TK_POSTIVE_NUM :
            tokens[nr_token].type = TK_POSTIVE_NUM;
            memset(tokens[nr_token].str, '\0', 32);
            Assert(substr_len <= 32,"ERROR : Too long expression at position %d with len %d: %.*s",\
            position, substr_len, substr_len, substr_start);
            strncpy(tokens[nr_token].str, substr_start,substr_len);
            nr_token += 1;
            break;
          case TK_PLUS: tokens[nr_token].type = '+';nr_token += 1;break;
          case TK_SUB: tokens[nr_token].type = '-';nr_token += 1;break;
          case TK_MUL: tokens[nr_token].type = '*';nr_token += 1;break;
          case TK_DIV: tokens[nr_token].type = '/';nr_token += 1;break;
          case TK_LEFT_PARE: tokens[nr_token].type = '(';nr_token += 1;break;
          case TK_RIGHT_PARE: tokens[nr_token].type = ')';nr_token += 1;break;
          default: break;
        }

        break;
      }
    }

    if (i == NR_REGEX) {
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }

  return true;
}

static bool check_parentheses(int p, int q, bool *success){
  int left_pare_num = 0;int right_pare_num = 0;
  int pare_match_time = 0;
  
  for(int i = p;i <= q;i++){
    if(tokens[i].type == TK_LEFT_PARE) { left_pare_num += 1; }
    if(tokens[i].type == TK_RIGHT_PARE) { right_pare_num += 1; }
  }
  if(left_pare_num != right_pare_num){
    printf("The num of parentheses in expression is wrong.\n");
    *success = false;
    return false;
  }
  if(tokens[p].type != '(' || tokens[q].type != ')'){
    /* The expression must not be surrounded by parentheses. */
    return false;
  }else{
    for(int i = p + 1;i <= q - 1;i++){
      if(tokens[i].type == '(') pare_match_time++;
      if(tokens[i].type == ')') pare_match_time--;
      if(pare_match_time < 0) return false;
    }
  }
  /* If pass all tests above ,It's surrounded. */
  return true;
}

/* Find the main operator */
static int find_oper(int p, int q){
  int main_oper_place = 0;
  bool pare_inside_flag = false;
  int last_highlevel_place = 0;
  int last_lowlevel_place = 0;
  for(int i = p;i <= q;i++){
   /* Ignore not-oper types. */
    if(tokens[i].type >= TK_NOTYPE){
      continue;
    }
    /* Ignore every oper inside parentheses. */
    if(tokens[i].type == '(' || pare_inside_flag == true){
      if(tokens[i].type == ')'){
        pare_inside_flag = false;
      }else{
        pare_inside_flag = true;
      }
      continue;
    }
    if(tokens[i].type == TK_MUL || tokens[i].type == TK_DIV){
      last_highlevel_place = i;
      continue;
    }else if(tokens[i].type == TK_PLUS || tokens[i].type == TK_SUB){
      last_lowlevel_place = i;
      continue;
    }
  }
  if(last_lowlevel_place != 0){
    /* exist + or - */
    main_oper_place = last_lowlevel_place;
  }else{
    /* only exist * or / */
    main_oper_place = last_highlevel_place;
  }
  return main_oper_place;
}

/* BNF algorithm */
static int eval(int p, int q, bool *success){
  bool is_pare_matched;
  if(p > q){
    return -1;
  }else if(p == q){
    /* Now the value has beed calculated, which should be a number. Just return it.*/
    return atoi(tokens[p].str);
  }
  is_pare_matched = check_parentheses(p, q, success);
  if(*success == false){
    return 0;
  }else if(is_pare_matched == true){
    /* Check the parentheses and remove a matched pair of it. */
    return eval(p + 1, q - 1, success);
  }else{
    /* Split the expression to smaller */
    int op = find_oper(p, q);
    int val1 = eval(p, op - 1, success);
    int val2 = eval(op + 1, q, success);
    #ifdef USE_DEBUG
    printf("%d %c %d %d\n",op,tokens[op].type,val1,val2);
    #endif

    switch(tokens[op].type){
      case TK_PLUS : return val1 + val2;
      case TK_SUB : return val1 - val2;
      case TK_MUL : return val1 * val2;
      case TK_DIV : return val1 / val2;
      default : assert(0);
    }
  }
}




word_t expr(char *e, bool *success) {
  int val;
  if (!make_token(e)) {
    *success = false;
    return 0;
  }

  val = eval(0 ,nr_token-1, success);
  if(*success == false){
    printf("Invalid token \"%s\".\n", e);
    return 0;
  }else{
    printf("%s val = %d.\n", e, val);
    return 0;
  }
}