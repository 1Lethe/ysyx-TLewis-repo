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

typedef struct watchpoint {
  int NO;
  struct watchpoint *next;
  struct watchpoint *prev;

  /* TODO: Add more members if necessary */

} WP;

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;
static int wp_num = 0;

void init_wp_pool(void) {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
    wp_pool[i].prev = (i == 0 ? NULL : &wp_pool[i - 1]);
  }

  head = NULL;
  free_ = wp_pool;
  wp_num = 0;
}

/* TODO: Implement the functionality of watchpoint */
WP* new_wp(void){
  if(wp_num <= NR_WP){
    head = wp_pool + wp_num;
    free_ = wp_pool + wp_num + 1;
    wp_num++;
    return head;
  }else{
    panic("Max wp");
  }
}

void free_wp(WP *wp){
  if(wp_num == 0){
    panic("No wp");
  }
  if(wp->prev != NULL) wp->prev->next = wp->next;
  if(wp->next != NULL) wp->next->prev = wp->prev;
  wp_pool[NR_WP-1].next = wp;
  wp->next = NULL;

  wp_num--;
  head = wp_pool + wp_num;
  free_ = wp_pool + wp_num - 1;
}
