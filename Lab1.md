# Lab 1: Booting a PC

## Part 1: PC Bootstrap

- 一开始测试make qemu，没有好说的

### 物理地址空间

> 补充一下物理地址空间的知识

```ascii
+------------------+  <- 0xFFFFFFFF (4GB)
|      32-bit      |
|  memory mapped   |
|     devices      |
|                  |
/\/\/\/\/\/\/\/\/\/\

/\/\/\/\/\/\/\/\/\/\
|                  |
|      Unused      |
|                  |
+------------------+  <- depends on amount of RAM
|                  |
|                  |
| Extended Memory  |
|                  |
|                  |
+------------------+  <- 0x00100000 (1MB)
|     BIOS ROM     |
+------------------+  <- 0x000F0000 (960KB)
|  16-bit devices, |
|  expansion ROMs  |
+------------------+  <- 0x000C0000 (768KB)
|   VGA Display    |
+------------------+  <- 0x000A0000 (640KB)
|                  |
|    Low Memory    |
|                  |
+------------------+  <- 0x00000000
```

- 16位8088处理器仅支持1MB的物理内存，早期的PC以0x00000000为内存起始地址，以0x0000ffff为终止地址（而不是0xffffffff）。被标注为low memory的640KB是早期PC唯一能使用的RAM空间。事实上最早的PC仅能被配置使用16KB/32KB/64KB的RAM空间。

## Part 2: The Boot Loader

- 没啥可记的，系统boot这部分做过好几次实验了

## Part 3: The Kernel

- 处理器的内存管理硬件将虚拟地址0xf0100000（内核代码运行的link address）映射到物理地址0x00100000（bootloader加载内核到内存的地址）。这样，尽管内核的虚拟地址的高度足够给用户进程留出充足的地址空间，内核还是会加载到物理内存RAM的1MB处，就在BIOS ROM之上。因此在对照/obj/kern/kernal.asm（该文件给出的是分页机制下的虚拟地址）时需要注意：在利用该文件调试分页机制启动前的代码时，要将虚拟地址转换为物理地址。
- 练习7
  - 在`movl %eax, %cr0`处下断，检查0x00100000和0xf0100000处内存，然后si，再次检查两处内存：改变CR0_PG位后，这两个地址指向了同一个物理地址。
  - 出现上述情况的原因：CR0_PG是分页标志位。在分页机制开启前，线性地址等价于物理地址，启动后0x00100000和0xf0100000作为分页机制下的虚拟地址对应着同一块物理地址空间，该映射的具体内容在/kern/entrypgdir处手动写出。
  - 如果将`movl %eax, %cr0`注释掉，第一条因为映射而出现问题的指令应当是：`jmp *%eax`，因为分页机制未启动，eip实际会指向物理地址，上个问题中查看了两处内存，在分页启动前两个地址指向的内存空间不同，从而导致控制流离开内核代码。
- 练习8
  - 阅读`kern/printf.c`,`lib/printfmt.c`,`kern/console.c`，理解其间的关系。在代码中，省略了八进制的pattern"%o"，手动补齐。
  - 对于八进制的补充实现，网上找了一些代码都是直接复制了十进制的实现，而计算机八进制前需要加数字0，不知道为什么大多数人都没有加这个'0'。我的实现如下：

    ```c
    case 'o':
        putch('0',putdat);
        num=getint(&ap, lflag);
        base=8;
        goto number;
    ```

    > 破案了，JOS的make grade没有要求八进制加0，否则影响判断。

  - 解释printf.c和console.c间的接口关系，特别是指出console.c导出的函数以及该函数是怎样被printf.c使用的：console里打印调用了printf.c的函数cprintf，而cprintf的具体实现是借助printfmt.c中的vcprintf方法实现的。vcprintf实现了对pattern字符串的解析，使用回调函数putch打印输出，putch的实现借助cputchar实现，cputchar则是调用了console.c中的cons_putc方法，cons_putc是以console.c中的其他方法实现的。看着关系挺复杂的，实际在阅读时通过几步查找就可以理清关系。
  - 解释console.c中的下列代码：

    ```c
    // What is the purpose of this?
    if (crt_pos >= CRT_SIZE) {
        int i;
        memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
            crt_buf[i] = 0x0700 | ' ';
        crt_pos -= CRT_COLS;
    }
    ```

    该部分代码对输出内容占满显示器而需要继续输出的情况`crt_pos >= CRT_SIZE`做了处理。具体方法为将已输出的内容向上移动一行，再向空出来的最下面一行输出。
  - 其余问题为基础的函数调用跟踪、数据打印类型、格式化字符串、函数调用栈问题，不进行实验。
- 练习9
  - 确定内核栈初始化时机、内核栈位置、内核如何保留栈空间、栈指针指向栈空间的哪个位置。

  ```asm
  relocated:
    # Clear the frame pointer register (EBP)
    # so that once we get into debugging C code,
    # stack backtraces will be terminated properly.
    movl  $0x0,%ebp
    # nuke frame pointer  
    # Set the stack pointer
    movl  $(bootstacktop),%esp
    # now to C code
    call  i386_init
  ==================================================
  .data
    .p2align  PGSHIFT    # force page alignment
    .globl    bootstack
  bootstack:
    .space    KSTKSIZE
    .globl    bootstacktop
  bootstacktop:
  ```

  - 由上述代码（entry.S），可以看出esp初始化指向bootstacktop，即bootstack末尾处（栈空间由高到低生长）。栈空间的预留通过开辟空白区域（大小为8*4KB）来实现。内核入口的跳转（call i386_init）在栈段的上方，即内核栈位于更高的地址。（从memlayout.h中可以看到，KSTACKTOP和KERNBASE指向同一个位置，0xf0000000）

- 其他练习
  - 主要是栈回溯以及JOS下相关的调试方法的使用，下面仅贴出主要改动（补充函数）部分。

  ```c
  //计算所在源文件行数，这里只是大概了解了一下stab这个结构，没有太深入去看
  //这块的代码是按照https://github.com/clann24/jos/blob/master/lab1/code/kern/kdebug.c抄写的
  stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
  info->eip_line = stabs[lline].n_desc;
  //===========================================================================
  //栈回溯函数，主要是通过read_ebp得到ebp，再利用函数调用栈结构访问栈中内容。
  //这里有一个容易踩进去的坑，就是输出ebp的时候，不要把它和ebp[0]搞混看作等价。ebp[0]和*ebp才是等价的
  int mon_backtrace(int argc, char **argv, struct Trapframe *tf){
  // Your code here.
  uint32_t *ebp = (uint32_t *)read_ebp();
    int i;
    cprintf("Stack backtrace:\n");
    while(ebp){
      struct Eipdebuginfo info;
      debuginfo_eip(ebp[1],&info);
      cprintf("  ebp  %08x  eip  %08x  args  %08x  %08x  %08x  %08x  %08x\n",ebp,ebp[1],ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);
      cprintf("      %s:%d: %.*s+%d\n",
        info.eip_file,
        info.eip_line,
        info.eip_fn_namelen,info.eip_fn_name,
        ebp[1] - info.eip_fn_addr
      );
      ebp = (uint32_t *)ebp[0];
    }
    return 0;
  }
  ```

## challenge

- challenge任务为实现彩色文本输出，提示可以通过ANSI/VGA来实现。*待补充*

## 零碎知识

### 变长参数

- C语言的变长参数处理是由编译器实现的，lab1相关的printfmt等函数使用了GCC的__builtin_函数`#define va_start(ap, last) __builtin_va_start(ap, last)`来实现变长参数的输入。GCC提供了一系列__builtin_函数用来简化程序编写。
- printfmt相关的代码如下，根据代码可以大概理解va_list的用法。

```c
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...){
  va_list ap;
  va_start(ap, fmt);
    vprintfmt(putch, putdat, fmt, ap);
  va_end(ap);
}
```

### STAB

- STAB=Symbol TABle
- 一篇介绍STAB的文章被保存在tools里
