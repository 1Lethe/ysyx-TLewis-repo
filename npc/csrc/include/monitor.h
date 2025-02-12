#ifndef __MONITOR
#define __MONITOR

#include <getopt.h>

#include "memory.h"
#include "trace.h"

long load_img(void);
void monitor_init(int argc, char *argv[]);

#endif