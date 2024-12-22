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

#include "sdb.h"

#define NR_WP 32

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;
static int wp_num = 0;

void init_wp_pool(void) {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
    wp_pool[i].isfree = true;
    memset(wp_pool[i].expr, '\0', TOKEN_STR_LEN);
    wp_pool[i].prev_value = 0;
    wp_pool[i].curr_value = 0;
  }

  head = NULL;
  free_ = wp_pool;
}

/* Create a new watchpoint */
WP* new_wp(void) {
  if (wp_num >= NR_WP) {
    panic("Max WP number reached");
  }

  assert(free_ != NULL);

  /* Move up free_ pointer and select free node*/
  WP *wp = free_;
  free_ = free_->next;
  /* add mp to head linked list and move head pointer */
  wp->next = head;
  head = wp;

  wp->isfree = false;
  wp_num++;
  return wp;
}

/* Free a watchpoint */
void free_wp(WP *wp) {
  if (wp_num <= 0 || wp == NULL) {
    panic("No WP to free");
  }

  assert(!wp->isfree);
  if(wp == head){
    head = wp->next;
    wp->next = free_;
    free_ = wp;
  }else{
    WP *current = head;
    WP *prev = NULL;
    while (current->next != NULL && current != wp){
      prev = current;
      current = current->next;
    }
    Assert(current == wp, "failed to find wp.");
    prev->next = wp->next;
    wp->next = free_;
    free_ = wp;
  }

  memset(wp->expr, '\0', TOKEN_STR_LEN);
  wp->prev_value = 0;
  wp->curr_value = 0;
  wp->isfree = true;
  wp_num--;
}

void create_wp(char *e, bool *success){
  WP *wp = new_wp();

  expr(e, success);
  if(!success){
    return;
  }
  strncpy(wp->expr, e, TOKEN_STR_LEN);
  printf("Create watchpoint %d.", wp->NO);
}

bool trace_wp(void){
  WP *wp = head;
  bool isStop = false;
  while(wp != NULL){
    bool success = true;
    wp->prev_value = wp->curr_value;
    wp->curr_value = expr(wp->expr, &success);
    if(wp->prev_value != wp->curr_value){ 
      printf("Watchpoint %d expr %s value change.\nOld : DEC: %d HEX: 0x%x\nNew : DEC %d HEX: 0x%x\n",\
      wp->NO, wp->expr, wp->prev_value, wp->prev_value, wp->curr_value, wp->curr_value);
      isStop = true;
    }
    if(!success) assert(0);

    wp = wp->next;
  }
  return isStop;
}

int count_wp(void){
  return wp_num;
}

void info_wp(void){
  int wp_place = 0;
  if(wp_num == 0){
    printf("there is no watchpoint used.\n");
    return;
  }

  for(int i = 0;i < wp_num; i++){
    for(int j = 0;j < NR_WP;j++){
      if(wp_pool[j].isfree == false && wp_pool[j].NO == wp_place){
        printf("WP %d expr: %s value DEC: %d HEX: 0x%x\n", \
        wp_pool[j].NO, wp_pool[j].expr, wp_pool[j].curr_value, wp_pool[j].curr_value);
        wp_place++;
        break;
      }
    }
  }
}

void delete_wp(int x){
  WP *wp = head;
  while(wp != NULL){
    if(wp->NO == x){
      printf("Remove watchpoint %d.\n", wp->NO);
      free_wp(wp);
      return;
    }
    wp = wp->next;
  }
  printf("Not find watchpoint.\n");
}