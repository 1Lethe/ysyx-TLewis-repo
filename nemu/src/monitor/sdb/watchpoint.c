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

#define NR_WP 4
#if 0
typedef struct watchpoint {
  int NO;
  struct watchpoint *next;
  struct watchpoint *prev;
  /* TODO: Add more members if necessary */

} WP;
#endif
static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;
static int wp_num = 0;

void init_wp_pool(void) {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
    wp_pool[i].prev = (i == 0 ? NULL : &wp_pool[i - 1]);
    wp_pool[i].isfree = true;
  }

  head = NULL;
  free_ = wp_pool;
}

/* TODO: Implement the functionality of watchpoint */
WP* new_wp(void){
  if(wp_num >= NR_WP){
    panic("max wp num");
  }else{
    WP *wp = free_;
    if(wp->next != NULL) free_ = wp->next;
    else free_ = NULL;
    head = wp;
    head->isfree = false;
    wp_num++;
    return wp;
  }
}

void free_wp(WP *wp){
  if(wp_num <= 0){
    panic("No wp");
  }else{
    if(head == wp){
      while(head->prev != NULL){
        head = head->prev;
      }
      free_ = head->next;
    }else{
      if(wp->next != NULL) wp->next->prev = wp->prev;
      if(wp->prev != NULL) wp->prev->next = wp->next;
      int i;
      for(i = 0;i < NR_WP;i++){
        if(wp_pool[i].next == NULL){
          wp->prev = &wp_pool[i];
          wp->next = NULL;
          wp_pool[i].next = wp;
          break;
        }
      }
      wp->next = NULL;
    }
    free_->isfree = true;
    wp_num--;
  }
}
