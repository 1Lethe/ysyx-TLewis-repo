#include <fs.h>
#include "proc.h"

typedef size_t (*ReadFn) (void *buf, size_t offset, size_t len);
typedef size_t (*WriteFn) (const void *buf, size_t offset, size_t len);

typedef struct {
  char *name;
  size_t size;
  size_t disk_offset;
  size_t open_offset;
  ReadFn read;
  WriteFn write;
} Finfo;

enum {FD_STDIN, FD_STDOUT, FD_STDERR, FD_FB};

size_t invalid_read(void *buf, size_t offset, size_t len) {
  panic("should not reach here");
  return 0;
}

size_t invalid_write(const void *buf, size_t offset, size_t len) {
  panic("should not reach here");
  return 0;
}

/* This is the information about all files in disk. */
static Finfo file_table[] __attribute__((used)) = {
  [FD_STDIN]  = {"stdin", 0, 0, 0, invalid_read, invalid_write},
  [FD_STDOUT] = {"stdout", 0, 0, 0, invalid_read, invalid_write},
  [FD_STDERR] = {"stderr", 0, 0, 0, invalid_read, invalid_write},
#include "files.h"
};

static int file_num = 0;

void init_fs() {
  file_num = sizeof(file_table) / sizeof(Finfo);
  // TODO: initialize the size of /dev/fb
}

bool fd_is_valid(int fd) {
  return (fd >= 0 && fd <= file_num);
}

char *find_fd2name(int fd) {
  assert(fd_is_valid(fd) == true);
  return file_table[fd].name;
}

int fs_open(const char *pathname, int flags, int mode) {
  for(int i = 0; i < file_num; i++){
    if(strcmp(file_table[i].name, pathname) == 0) {
      // open file
      return i;
    }
  }
  // fail to find correct file
  assert(0);
}

size_t fs_read(int fd, void *buf, size_t len) {
  assert(fd_is_valid(fd) == true);
  assert(buf != NULL);

  if (file_table[fd].open_offset >= file_table[fd].size) {
    return 0;
  }

  size_t rd_len = (file_table[fd].open_offset + len < file_table[fd].size) ? len : 
                  file_table[fd].size - file_table[fd].open_offset;

  ramdisk_read(buf, file_table[fd].disk_offset + file_table[fd].open_offset, rd_len);
  file_table[fd].open_offset += rd_len;

  return rd_len;
} 

size_t fs_write(int fd, const void *buf, size_t len) {
  assert(fd_is_valid(fd) == true);
  assert(buf != NULL);

  if (file_table[fd].open_offset >= file_table[fd].size) {
    return 0;
  }

  size_t wr_len = (file_table[fd].open_offset + len < file_table[fd].size) ? len : 
                  file_table[fd].size - file_table[fd].open_offset;

  ramdisk_write(buf, file_table[fd].disk_offset + file_table[fd].open_offset, wr_len);
  file_table[fd].open_offset += wr_len;

  return wr_len;
}

size_t fs_lseek(int fd, size_t offset, int whence) {
  assert(fd_is_valid(fd) == true);

  switch (whence) {
    case SEEK_SET : file_table[fd].open_offset = offset; break;
    case SEEK_CUR : file_table[fd].open_offset += offset; break;
    case SEEK_END : file_table[fd].open_offset = file_table[fd].size + offset; break;
    default: panic("Wrong fs_lseek arg whence %d", whence);
  }

  return file_table[fd].open_offset;
}

int fs_close(int fd) {
  assert(fd_is_valid(fd) == true);
  // always succeed to close fs
  return 0;
}