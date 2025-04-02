#include <stdio.h>
#include <sys/time.h>
#include <assert.h>

#include <NDL.h>

#define USE_NDL

struct timeval tv;

int main() {
    int sec = 0;
    int sec_prev = 0;
    gettimeofday(&tv, NULL);
    printf("Start test at sec %ld %ld\n", tv.tv_sec, tv.tv_usec);

    #ifdef USE_NDL
    NDL_Init(0);
    #endif

    while(1) {
        #ifdef USE_NDL
        uint32_t ms = NDL_GetTicks();
        sec_prev = sec;
        sec = ms / 1000;
        if(sec != sec_prev){
            printf("%d\n", sec);
        }
        #else
        int ret = gettimeofday(&tv, NULL);
        assert(ret == 0);

        sec_prev = sec;
        sec = tv.tv_sec;
        if(sec != sec_prev){
            printf("%ld\n", tv.tv_sec);
        }
        #endif
    }

    NDL_Quit();

    return 0;
}
