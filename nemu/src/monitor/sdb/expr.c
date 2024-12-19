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

enum {
  // TODO: Add more expression.
  // Pay attention to put different rules to correct places.

  /* non-operator put here. */
  TK_NOTYPE = 256, TK_LINEBREAK,
  TK_DEC_POS_NUM,TK_DEC_NEG_NUM,TK_HEX_NUM,
  TK_EQ,TK_NEQ,TK_AND,
  TK_REG_NAME,TK_POINTER,

  /* Operator put here. */
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
  {"\n", TK_LINEBREAK},          // linebreak
  {"\\(", TK_LEFT_PARE},         // left parenthesis
  {"\\)", TK_RIGHT_PARE},        // right parenthesis
  {"0x[0-9A-F]+", TK_HEX_NUM},
  {"[0-9]+", TK_DEC_POS_NUM},    // decimal digit
  {"\\*", TK_MUL},               // multiply
  {"\\/", TK_DIV},               // divide
  {"\\+", TK_PLUS},              // plus
  {"-", TK_SUB},                 // sub
  {"==", TK_EQ},                 // equal
  {"!=", TK_NEQ},
  {"&&", TK_AND},
  {"\\$[$raspgt0-9]+", TK_REG_NAME}
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

#define TOKEN_STR_LEN 32

typedef struct token {
  int type;
  char str[TOKEN_STR_LEN];
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
          case TK_LINEBREAK : break;
          case TK_HEX_NUM : 
            tokens[nr_token].type = TK_HEX_NUM;
            memset(tokens[nr_token].str, '\0', TOKEN_STR_LEN);
            if(substr_len > 32){
              printf("ERROR : Too long token at position %d with len %d: %.*s\n",\
              position, substr_len, substr_len, substr_start);
              return false;
            }
            strncpy(tokens[nr_token].str, substr_start,substr_len);
            nr_token += 1;
            break;
          case TK_DEC_POS_NUM :
            tokens[nr_token].type = TK_DEC_POS_NUM;
            memset(tokens[nr_token].str, '\0', TOKEN_STR_LEN);
            if(substr_len > 32) {
              printf("ERROR : Too long token at position %d with len %d: %.*s\n",\
              position, substr_len, substr_len, substr_start);
              return false;
            }
            strncpy(tokens[nr_token].str, substr_start,substr_len);
            nr_token += 1;
            break;
          case TK_PLUS: tokens[nr_token].type = '+';nr_token += 1;break;
          case TK_SUB: tokens[nr_token].type = '-';nr_token += 1;break;
          case TK_MUL: tokens[nr_token].type = '*';nr_token += 1;break;
          case TK_DIV: tokens[nr_token].type = '/';nr_token += 1;break;
          case TK_LEFT_PARE: tokens[nr_token].type = '(';nr_token += 1;break;
          case TK_RIGHT_PARE: tokens[nr_token].type = ')';nr_token += 1;break;
          case TK_EQ : tokens[nr_token].type = TK_EQ;nr_token += 1;break;
          case TK_NEQ : tokens[nr_token].type = TK_NEQ;nr_token += 1;break;
          case TK_AND : tokens[nr_token].type = TK_AND;nr_token += 1;break;
          case TK_REG_NAME : 
            tokens[nr_token].type = TK_REG_NAME;
            memset(tokens[nr_token].str, '\0', TOKEN_STR_LEN);
            bool success = true;
            char reg_str[5];
            memcpy(reg_str, substr_start + 1, substr_len - 1);
            snprintf(tokens[nr_token].str, substr_len, "%d", isa_reg_str2val(reg_str, &success));
            if(!success) return false;
            nr_token += 1;
            break;
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

  // TODO: Rematch token rules
  for(i = 0;i < nr_token;i++){
    if(tokens[i].type == '*' && (i == 0 || (tokens[i].type == '+' || tokens[i].type == '-' || \
    tokens[i].type == '*' || tokens[i].type == '/')))
    {
      tokens[i].type = TK_POINTER;
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
static int find_oper(int p, int q, bool *success){
  int main_oper_place = 0;
  int pare_inside_time = 0;
  int last_highlevel_place = 0;
  int last_lowlevel_place = 0;
  for(int i = p;i <= q;i++){
   /* Ignore not-oper types. */
    if(tokens[i].type >= TK_NOTYPE){
      continue;
    }
    /* Ignore every oper inside parentheses. */
    if(tokens[i].type == '('){
      pare_inside_time++;
      continue;
    }else if(tokens[i].type == ')'){
      pare_inside_time--;
      continue;
    }
    if(pare_inside_time > 0){
      continue;
    }
    /* Find the main operator. */
    if(tokens[i].type == TK_MUL || tokens[i].type == TK_DIV){
      if(i == 0){
        printf("The operator is at the beginning.\n");
        *success = false;
        return 0;
      }
      last_highlevel_place = i;
      continue;
    }else if(tokens[i].type == TK_PLUS || tokens[i].type == TK_SUB){
      if(i == 0){
        printf("The operator is at the beginning.\n");
        *success = false;
        return 0;
      }
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
    int op = find_oper(p, q, success);
    int val1 = eval(p, op - 1, success);
    int val2 = eval(op + 1, q, success);
    if(*success == false) return 0;

    switch(tokens[op].type){
      case TK_PLUS : return val1 + val2;
      case TK_SUB : return val1 - val2;
      case TK_MUL : return val1 * val2;
      case TK_DIV :
        if(val2 == 0){
          *success = false;
          printf("Expression try to divide by 0.\n");
          return 0;
        }else{
          return val1 / val2;
        }
      default : assert(0);
    }
  }
}

word_t expr(char *e, bool *success) {
  int val;

  *success = true;
  if (!make_token(e)) {
    *success = false;
    printf("Failed to match token.\n");
    return 0;
  }

  val = eval(0 ,nr_token-1, success);
  if(*success == false){
    printf("Invalid token \"%s\".\n", e);
    return 0;
  }else{
    printf("Expression %s val = 0x%08x.\n", e, val);
    return 0;
  }
}