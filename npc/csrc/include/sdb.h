#ifndef __SDB_H
#define __SDB_H

#include <readline/readline.h>
#include <readline/history.h>

#include "cpu-exec.h"
#include "reg.h"

void sdb_mainloop(void);

#endif