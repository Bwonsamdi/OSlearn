// Boot loader.
//
// Part of the boot block, along with bootasm.S, which calls bootmain().
// bootasm.S has put the processor into protected 32-bit mode.
// bootmain() loads an ELF kernel image from the disk starting at
// sector 1 and then jumps to the kernel entry routine.

#include "types.h"
#include "elf.h"
#include "x86.h"
#include "memlayout.h"

#define SECTSIZE  512

void readseg(uchar*, uint, uint);

void bootmain(void){
  struct elfhdr *elf;
  struct proghdr *ph, *eph;
  void (*entry)(void);
  uchar* pa; //物理地址指针

  elf = (struct elfhdr*)0x10000;  // scratch space

  // Read 1st page off disk
  readseg((uchar*)elf, 4096, 0); //

  // ELF文件Magic number校验
  if(elf->magic != ELF_MAGIC)
    return;  // 此处返回会进入bootasm，从而陷入死循环

  // Load each program segment (ignores ph flags).
  ph = (struct proghdr*)((uchar*)elf + elf->phoff);
  eph = ph + elf->phnum;
  for(; ph < eph; ph++){
    pa = (uchar*)ph->paddr;
    readseg(pa, ph->filesz, ph->off);
    if(ph->memsz > ph->filesz)
      stosb(pa + ph->filesz, 0, ph->memsz - ph->filesz);
  }

  // Call the entry point from the ELF header.
  // Does not return!
  entry = (void(*)(void))(elf->entry);
  entry();//读取结束，函数指针调用入口函数(entry.S)
}

void waitdisk(void){
  // Wait for disk ready.
  while((inb(0x1F7) & 0xC0) != 0x40)
  // 1F7端口值 & 1100 0000，目的是0100 0000，即忙碌位为0，就绪位为1
    ;
}


/*
端口号     读还是写   具体含义
1F0H       读/写      用来传送读/写的数据(其内容是正在传输的一个字节的数据)
1F1H       读         用来读取错误码
1F2H       读/写      用来放入要读写的扇区数量
1F3H       读/写      用来放入要读写的扇区号码
1F4H       读/写      用来存放读写柱面的低8位字节
1F5H       读/写      用来存放读写柱面的高2位字节(其高6位恒为0)
1F6H       读/写      用来存放要读/写的磁盘号及磁头号
                     第7位     恒为1
                     第6位     恒为0
                     第5位     恒为1
                     第4位     为0代表第一块硬盘、为1代表第二块硬盘
                     第3~0位    用来存放要读/写的磁头号
1f7H       读         用来存放读操作后的状态
                     第7位     控制器忙碌
                     第6位     磁盘驱动器准备好了
                     第5位     写入错误
                     第4位     搜索完成
                     第3位     为1时扇区缓冲区没有准备好
                     第2位     是否正确读取磁盘数据
                     第1位     磁盘每转一周将此位设为1,
                     第0位     之前的命令因发生错误而结束
          写         该位端口为命令端口,用来发出指定命令
                     为50h     格式化磁道
                     为20h     尝试读取扇区
                     为21h     无须验证扇区是否准备好而直接读扇区
                     为22h     尝试读取长扇区(用于早期的硬盘,每扇可能不是512字节,而是128字节到1024之间的值)
                     为23h     无须验证扇区是否准备好而直接读长扇区
                     为30h     尝试写扇区
                     为31h     无须验证扇区是否准备好而直接写扇区
                     为32h     尝试写长扇区
                     为33h     无须验证扇区是否准备好而直接写长扇区
*/
// Read a single sector at offset into dst.
// 从offset处读取一个段到dst处
void readsect(void *dst, uint offset){
  // Issue command.
  waitdisk();
  outb(0x1F2, 1);   // 8位端口，设置读取扇区的数量
  outb(0x1F3, offset);
  outb(0x1F4, offset >> 8);
  outb(0x1F5, offset >> 16);
  outb(0x1F6, (offset >> 24) | 0xE0);//这里之前共同表示扇区号
  outb(0x1F7, 0x20);  // 0x20读取扇区

  // Read data.
  waitdisk();
  insl(0x1F0, dst, SECTSIZE/4);
}

// Read 'count' bytes at 'offset' from kernel into physical address 'pa'.
// Might copy more than asked.
// 从kernel的offset处读取count个字节到物理地址指针pa处
// 可能复制多于请求数目的字节
void readseg(uchar* pa, uint count, uint offset){
  uchar* epa; //读取结束地址

  epa = pa + count;

  // Round down to sector boundary.
  pa -= offset % SECTSIZE;

  // Translate from bytes to sectors; kernel starts at sector 1.
  offset = (offset / SECTSIZE) + 1;

  // If this is too slow, we could read lots of sectors at a time.
  // We'd write more to memory than asked, but it doesn't matter --
  // we load in increasing order.
  for(; pa < epa; pa += SECTSIZE, offset++)
    readsect(pa, offset);
}
