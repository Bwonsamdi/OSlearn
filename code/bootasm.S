#include "asm.h"
#include "memlayout.h"
#include "mmu.h"

# 切换至32位保护模式，跳转到C代码
# BIOS从硬盘第一个分区加载这部分代码到内存的物理地址0x7c00处，然后在实模式下以初始状态%cs=0 %ip=7c00开始执行

.code16                       # 编译为16位机器码
.globl start
start:
  cli                         # 关闭BIOS使能中断

  # 数据段寄存器置零（DS, ES, SS）
  xorw    %ax,%ax             # Set %ax to zero
  movw    %ax,%ds             # -> Data Segment
  movw    %ax,%es             # -> Extra Segment
  movw    %ax,%ss             # -> Stack Segment

  # 操作物理地址线A20
seta20.1:
  inb     $0x64,%al               # Wait for not busy
  testb   $0x2,%al
  jnz     seta20.1

  movb    $0xd1,%al               # 0xd1 -> port 0x64
  outb    %al,$0x64

seta20.2:
  inb     $0x64,%al               # Wait for not busy
  testb   $0x2,%al
  jnz     seta20.2

  movb    $0xdf,%al               # 0xdf -> port 0x60
  outb    %al,$0x60

  # 切换至保护模式
  lgdt    gdtdesc
  movl    %cr0, %eax
  orl     $CR0_PE, %eax
  movl    %eax, %cr0

//PAGEBREAK!
  # 使用远跳重新加载cs和eip以完成32位保护模式的切换
  ljmp    $(SEG_KCODE<<3), $start32

.code32  # 从此处开始执行32位指令
start32:
  # 设置保护模式下的数据段寄存器
  movw    $(SEG_KDATA<<3), %ax    # 数据段选择子
  movw    %ax, %ds                # -> DS: Data Segment
  movw    %ax, %es                # -> ES: Extra Segment
  movw    %ax, %ss                # -> SS: Stack Segment
  movw    $0, %ax                 # Zero segments not ready for use
  movw    %ax, %fs                # -> FS
  movw    %ax, %gs                # -> GS

  # 设置栈指针，然后进入C代码调用
  movl    $start, %esp
  call    bootmain

  # 一旦bootmain返回（即上行代码执行结束。正常情况下这是不应当发生的），触发bochs的断点，并进入死循环。由于实验环境使用qemu，因此注释掉此处代码避免引起误解
  # movw    $0x8a00, %ax            # 0x8a00 -> port 0x8a00
  # movw    %ax, %dx
  # outw    %ax, %dx
  # movw    $0x8ae0, %ax            # 0x8ae0 -> port 0x8a00
  # outw    %ax, %dx
spin:
  jmp     spin

# Bootstrap GDT
.p2align 2                                # force 4 byte alignment
gdt:
  SEG_NULLASM                             # null seg
  SEG_ASM(STA_X|STA_R, 0x0, 0xffffffff)   # code seg
  SEG_ASM(STA_W, 0x0, 0xffffffff)         # data seg

gdtdesc:
  .word   (gdtdesc - gdt - 1)             # sizeof(gdt) - 1
  .long   gdt                             # address gdt

