#ifndef __MONITOR
#define __MONITOR

#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <stdint.h>

#include "memory.h"

long load_img(void);
void monitor_init(int argc, char *argv[]);

#endif