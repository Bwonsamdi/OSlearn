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
