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
  }

  head = NULL;
  free_ = wp_pool;
}

/* TODO: Implement the functionality of watchpoint */
WP* new_wp(void) {
  if (wp_num >= NR_WP) {
    panic("Max WP number reached");
    return NULL;
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

void free_wp(WP *wp) {
  if (wp_num <= 0 || wp == NULL) {
    panic("No WP to free");
    return;
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
  wp->isfree = true;
  wp_num--;
}