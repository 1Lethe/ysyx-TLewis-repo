// Powered by TLewis.

#include "sdb.h"
#include <cpu/decode.h>

#define NR_BP 32

static BP bp_pool[NR_BP] = {};
static BP *head = NULL, *free_ = NULL;
static int bp_num = 0;

void init_bp_pool(void) {
    int i;
    for(i = 0; i < NR_BP; i++){
        bp_pool[i].NO = i;
        bp_pool[i].next = (i == NR_BP - 1 ? NULL : &bp_pool[i + 1]);
        bp_pool[i].isfree = true;
        bp_pool[i].pc_break = -1;
    }

    head = NULL;
    free_ = bp_pool;
}

BP* new_bp(void){
    if(bp_num >= NR_BP){
        panic("No more breakpoint available");
    }

    assert(free_ != NULL);

    BP* bp = free_;
    free_ = free_->next;
    bp->next = head;
    head = bp;

    bp->isfree = false;
    bp_num++;
    return bp;
}

void free_bp(BP* bp){
    if(bp_num <= 0 || bp == NULL){
        panic("Invalid breakpoint");
    }

    assert(!bp->isfree);
    if(bp == head){
        head = bp->next;
        bp->next = free_;
        free_ = bp;
    }else{
        BP *current = head;
        BP *prev = NULL;
        while(current->next != NULL && current != bp){
            prev = current;
            current = current->next;
        }
        Assert(current == bp, "failed to find breakpoint.");
        prev->next = bp->next;
        bp->next = free_;
        free_ = bp;
    }

    bp->pc_break = -1;
    bp->isfree = true;
    bp_num--;
}

void create_bp(vaddr_t pc_break, bool *success){
    BP *bp = new_bp();
    if(bp == NULL){
        *success = false;
        return;
    }
    bp->pc_break = pc_break;
    *success = true;
}

bool trace_bp(Decode *s){
    BP *bp = head;
    bool isStop = false;
    vaddr_t pc_guest = isa_pc_step(s);
    vaddr_t pc = s->pc;

    while(bp != NULL){
        if(bp->pc_break == pc){
            printf("Breakpoint %d hit at PC: 0x%x Step: %d\n", bp->NO, s->pc, pc_guest);
            isStop = true;
        }
        bp = bp->next;
    }
    return isStop;
}

void info_bp(void){
    if(bp_num == 0){
        printf("No breakpoint set.\n");
        return;
    }
    BP *bp = head;
    while(bp != NULL){
        printf("Breakpoint %d: Step: %d\n", bp->NO, bp->pc_break);
        bp = bp->next;
    }
}

void delete_bp(int x){
    BP *bp = head;
    while(bp != NULL){
        if(bp->NO == x){
            printf("Remove breakpoint %d.\n", x);
            free_bp(bp);
            return;
        }
        bp = bp->next;
    }
    printf("Breakpoint %d not found.\n", x);
}