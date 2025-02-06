#ifndef __SDB_H
#define __SDB_H

#include <readline/readline.h>
#include <readline/history.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "macro.h"
#include "cpu-exec.h"

void sdb_mainloop(void);

#endif