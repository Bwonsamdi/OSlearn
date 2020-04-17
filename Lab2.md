# Lab 2: Memory Management

> 做lab1的时候没配git bash的代理，然后发现lab2需要1的部分代码，直接复制文件比较麻烦，于是配上代理重新整理了lab1，其间还遇到LF变成CRLF的坑，总算是搞好了
> 在lab2前有两个HW，一个是boot xv6，这个没啥东西，另一个是读xv6 shell的代码
> 实验要求至少完成一个挑战

## Part 1: Physical Page Management

### 练习1

> 实现物理内存分配器

#### 题目要求

- 实现kern/pmap.c的以下函数：
  - boot_alloc()
  - mem_init() (only up to the call to check_page_free_list(1))
  - page_init()
  - page_alloc()
  - page_free()

check_page_free_list()和check_page_alloc()用于测试物理内存分配器。可以向assert()添加自己的断言。

#### 准备

- 链接:[https://pdos.csail.mit.edu/6.828/2017/lec/l-josmem.html](https://pdos.csail.mit.edu/6.828/2017/lec/l-josmem.html)
- lecture 5介绍了JOS中的分页和分段机制

- UVPT(User read-only Virtual Page Table)
  - x86使用二级页表机制，将内存划分为许多个页表和一个页目录。通过页表对物理地址的映射，可以对进程的内存权限进行管理。
  - CR3寄存器从页目录索引到页表，再从页表索引到内存页。处理器没有页目录、页表的概念，而只是跟随于下列指针：`pd = lcr3(); pt = *(pd+4*PDX); page = *(pt+4*PTX);`。
  - 在mmu.h中，可以看到，JOS将32位地址划分为三部分：PDX(10)+PTX(10)+PGOFF(12)，PDX和PTX共同计算出PGNUM（页号），加上PGOFF得到la（线性地址）。构造一个分页机制下的线性地址借助PGADDR(PDX(la), PTX(la), PGOFF(la))来完成。后面是一些常数值的定义，包括计算时的移位位数、页表项、页目录项标记等，再后面定义了一些CR0、EFLAGS用于置位的值。
  - 在memlayout.h中，KERNBASE为内核栈的栈顶，内核使用关于UVPT的注释表明其权限是用户态只读的

#### boot_alloc

- 如果n>0,申请一块连续的n字节大小的物理内存，返回一个内核虚拟地址
- 如果n==0，返回下一个未被分配的页的地址
- 如果内存不够用，陷入恐慌
- 初始的nextfree指针为指向未分配内存的虚拟地址指针

```c
static void *boot_alloc(uint32_t n) {
  static char *nextfree;
  char *result;
  if (!nextfree) {
    extern char end[];
    nextfree = ROUNDUP((char *) end, PGSIZE);
  }
  //预分配，判断分配是否合理
  if(n==0){
    result = nextfree;
    return result;
  }
  char* __nextfree = ROUNDUP((char *)(nextfree + n), PGSIZE);
  if(n<0 || PADDR(__nextfree)>0x400000){
    panic("Out of memory or invalid allocated mem size");
  }
  //分配并更新nextfree
  result = nextfree;
  nextfree = __nextfree;
  return result;
}
```

#### mem_init

```c
pages = (struct PageInfo *)boot_alloc(npages*(sizeof(struct PageInfo)));
memset(pages, 0, npages * sizeof(struct PageInfo));
```

#### page_init

- 函数中已经给出标记物理页为free状态的代码，需要完成将其余物理页设置为free状态。

```c
size_t i;
for(i = 1; i < npages_basemem; i++){
  pages[i].pp_ref = 0;
  pages[i].pp_link = page_free_list;
  page_free_list = &pages[i];
}

size_t tmp = PADDR(boot_alloc(0)) / PGSIZE;
for(i=tmp;i<npages;i++){
  pages[i].pp_ref = 0;
  pages[i].pp_link = page_free_list;
  page_free_list = &pages[i];
}
```

#### page_alloc

```c
struct PageInfo * page_alloc(int alloc_flags){
  // Fill this function in
  if(page_free_list){
    //新建一个指针指向可用页链表头
    struct PageInfo* result = page_free_list;
    //可用页链表头指向后一个可用页
    page_free_list = page_free_list->pp_link;
    result->pp_link=NULL;
    if(alloc_flags & ALLOC_ZERO){
      memset(page2kva(result), 0, PGSIZE);
    }
    return result;
  }
  return NULL;
}
```

#### page_free

```c
void page_free(struct PageInfo *pp){
  if(pp->pp_ref){
    panic("pp->pp_ref is not zero");
  }else if (pp->pp_link){
    panic("pp is a freed page, double free detected");
  }else{
    pp->pp_link = page_free_list;
    page_free_list = pp;
  }
}
```

#### 遇到的错误

- page_alloc中，alloc的result指针忘记为其pp_link字段赋值为NULL。错误信息：kernel panic at kern/pmap.c:517: assertion failed: page2pa(pp) != 0
- page_init忘记修改已给出部分，需要将i的初值修改为1（0页存储实模式IDT和BIOS的结构），结束值改为npages_basemem。错误信息：触发page_free中的double free

## Part 2: Virtual Memory

### 练习2

- 阅读[Intel 80386 Reference Manual](https://pdos.csail.mit.edu/6.828/2017/readings/i386/toc.htm)的5.2和6.4节
- 5.2 页转换
  - 在地址转换的第二阶段，80386将一个线性地址转换为物理地址。本阶段的地址转换实现了面向页的虚拟内存系统以及页级别保护所需的基本功能。
  - 页翻译的步骤是可选的，仅当设置了CR0的PG位时页翻译才会生效。如果操作系统要实现多个虚拟8086任务、实现面向页的保护、或者实现面向页的虚拟内存则必须设置PG位。
  - 页表项（这里的页表包括两级页表）
    - 31-12位：页帧地址，索引页目录项和第二级页表项
    - 11-10位：AVAIL，供程序使用
    - 7位：D，脏页标志，置1表示该PTE被写过，在PDE中无意义
    - 6位：A，访问位，置1表示该PTE被访问过
    - A/D位由硬件设置
    - 2位、1位：U/S，R/W位，用于页保护机制，不用于地址转换
    - 0位：存在位，表示页表项是否可以在地址转换中使用，置1表示可以使用。置0时，31-1位都视为AVAIL位可供程序使用，其余位不会被硬件检测。当P=0，且页表项被试图用于地址转换时，处理器会抛出页异常（page-not-present）。在挂起相关任务时，页目录可能处于不存在状态，但是操作系统必须确保在分配任务之前，TSS中的CR3映像所指示的页目录存在于物理内存中。
  - 页缓存
    - 为了保证地址转换的最大效率，处理器将最近使用的页表数据存在片上缓存中。只有需要的页信息不在缓存上时才必须引用两级页表。
    - 页转换缓存的存在对应用开发人员是不可见的，但是对系统开发人员可见；当页表被更改时，系统程序员必须刷新缓存。刷新缓存可以通过以下两种方法实现：
      1. 使用MOV指令重新装载CR3，例如：`MOV CR3, EAX`
      2. 通过执行任务切换到*具有不同于当前TSS的CR3映像*的TSS
- 6.4 页保护
  - 页的保护机制有两种：可寻址域约束、类型检查
  - PDE和PTE的控制访问字段：U/S位和R/W位
  - 可寻址域约束
    - 页的特权级概念是通过为每个页分配两个级别中的一个来实现的
      1. 管理级（U/S=0）：为系统及系统程序、系统数据分配
      2. 用户级（U/S=1）：为应用程序及数据分配
    - 当前等级与CPL相关，如果CPL为0，1或2，处理器在管理级执行。如果CPL为3，则处理器在用户级执行。当处理器在管理级执行时，所有页都是可寻址的；在用户级执行时，仅用户级页是可寻址的。
  - 类型检查
    - 页寻址级别定义了两种类型：只读访问（R/W=0）和读写访问（R/W=1）
    - 当处理器在管理级运行时，所有的页都是可读、可写的。当处理器在用户级运行时，只有用户级且标记可读可写的页才是可读可写的，管理级的页既不可读也不可写
  - 对于一个页，其PDE的权限和PTE的权限可能不同，80386会通过位与操作计算页的属性组合
  - 在以下访问动作里，即使CPL=3，也视为特权级0级
    - 对LDT,GDT,TSS,IDT的引用
    - 在跨特权级的CALL/INT期间访问内部栈

- 在x86的术语中，*虚拟地址*由一个段选择子和段内偏移组成；*线性地址*是在段地址转换后、在页地址转换前的概念。*物理地址*是通过段地址转换、页地址转换后最终得到的地址，也是最终从硬件总线输出到RAM的内容
- lab2中，boot.S里的GDT内所有的段base为0、limit为0xffffffff，这样相当于禁用了选择子，线性地址等价于虚拟地址的偏移量
- 回想lab 1的第3部分，我们安装了一个简单的页表，这样内核就可以在它的链接地址0xf0100000处运行，即便它实际上装载在物理内存里，而且就位于ROM BIOS的上面0x00100000处。该页表仅映射了4MB的内存。后续的实验将扩展虚拟内存空间，以映射从虚拟地址0xf0000000开始的第一个256MB物理内存，并映射虚拟地址空间中的若干其他区域。

### 练习3

- Use the `xp` command in the QEMU monitor and the `x` command in GDB to inspect memory at corresponding physical and virtual addresses and make sure you see the same data.
- 一旦进入保护模式，线性地址和物理地址就不能被直接使用，所有内存的引用都被视为虚拟地址，并由MMU进行翻译。这意味着C代码中所有的指针都是虚拟地址。
- JOS经常需要直接引用地址，将其作为不透明的值或整数来使用，如在练习1中，有时地址是虚拟地址，有时是物理地址。为了在代码中标记出这点，JOS使用了uintptr_t和physaddr_t类型来区分，它们实际上只是uint32_t的同义表达。
- JOS内核可以先把uintptr_t转换为指针类型来解引用它。如果将physaddr_t转换为一个指针再间接引用它（类似`*((uint32_t *)p)`），硬件会将其解释为虚拟地址导致非预期访问。即，通过加星号解引用访问的都被视为虚拟地址。
- 提问：假设下列内核代码是正确的，变量x应当是什么类型，uintptr_t还是physaddr_t？

  ```c
  mystery_t x;
  char* value = return_a_pointer();
  *value = 10;
  x = (mystery_t) value;
  ```

  - value为虚拟地址指针；x由value类型转换得到，因此
  - 物理地址->虚拟地址：KADDR(pa)
  - 虚拟地址->物理地址：PADDR(va)

### 练习4

- 实现以下函数
  - pgdir_walk()
  - boot_map_region()
  - page_lookup()
  - page_remove()
  - page_insert()

#### pgdir_walk

- 页表目录和页表中存的都是物理地址,但需要通过虚拟地址访问
- 该函数的目的是通过给定的页目录项和虚拟地址，返回va的二级页表项指针
- 思路
  - PDX宏计算得出va的页表索引，PTX宏计算得出va的页索引
  - 利用页目录索引在页目录中找到目标页目录项
  - 判断页表是否存在
    - 不存在：申请新页，并设置其存在位、U/S位、R/W位，之后存储到目标页表项
  - 使用PTE_ADDR宏，得到页表项中的页表物理地址
  - 使用KADDR宏，计算得到页表虚拟地址
  - 寻址得到页表项，返回其指针

```c
pte_t * pgdir_walk(pde_t *pgdir, const void *va, int create){
  uint32_t pde_index = PDX(va);
  uint32_t pte_index = PTX(va);
  pte_t *target_pde = pgdir[pde_index];
  if(!(*target_pde & PTE_P)){
    if(create){
      struct PageInfo* pp = page_alloc(ALLOC_ZERO);
      if(!pp) return NULL;
      pp->pp_ref++;
      pgdir[pde_index] = page2pa(pp) | PTE_P | PTE_U | PTE_W;
    }else{
      return NULL;
    }
    pte_t *target_pt = KADDR(PTE_ADDR(pgdir[pde_index]));
    return &target_pt[pte_index];
  }
  return NULL;
}
```

#### boot_map_region

> 把一个范围内的va与pa建立映射

```c
static void boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm){
  uint32_t i;
  for(i = 0; i < size / PGSIZE; i++){
    pte_t* p = pgdir_walk(pgdir, va, 1);
    if(!p){
      panic("pgdir_walk failed! memory is full");
    }
    *p = (pa | (PTE_P | perm));// 向页表项存入设置了flag的物理地址
    va += PGSIZE; // va用于获取页表项
    pa += PGSIZE; // pa是向页表项中写入的内容
  }
}
```

#### page_lookup

```c
struct PageInfo *page_lookup(pde_t *pgdir, void *va, pte_t **pte_store){
  pte_t *pp = pgdir_walk(pgdir, va, 0); // 试图获取va对应的页表项，没有找到时不创建新页
  if(!pp || !(*pp & PTE_P))return NULL; // 有对应页表且存在
  if(pte_store){
    *pte_store = pp; //存储pp
  }
  return pa2page(PTE_ADDR(*pp));
}
```

#### page_remove

```c
void page_remove(pde_t *pgdir, void *va){
  // Fill this function in
  pte_t *pg = NULL;
  struct PageInfo *pinfo = page_lookup(pgdir,va,&pg);
  if(!pinfo || !(*pg & PTE_P)) return;
  page_decref(pinfo);
  *pg = 0; //页表项内容删除
  tlb_invalidate(pgdir, va); // 对应的MMU内部TLB无效化
}
```

#### page_insert

```c
int page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm){
  //首先获得虚拟地址对应的二级页表项
  pte_t *pte = pgdir_walk(pgdir, va, 1);
  if(!pte){
    return -E_NO_MEM;
  }
  //页信息的引用计数加一
  pp->pp_ref ++;
  //判断获取的页表项对应的页是否存在
  if(*pte & PTE_P){
    //存在则移除这个物理页
    page_remove(pgdir, va);
  }
  //把传入的参数pp设置为新的物理页，存入二级页表项
  *pte = page2pa(pp) | perm | PTE_P;
  return 0;
}
```

函数目的是建立虚拟地址和物理地址的映射关系，主要操作是将物理地址存放到虚拟地址对应的页表项中，因此考虑以下情况：

1. 虚拟地址对应的二级页表项没有存放物理页。此时函数需要将物理页填入
2. 二级页表项已经存放了物理页，要插入的物理页不同于事先存放的页。此时将原来的页卸载再插入新的地址
3. 二级页表已经存放了物理页，要插入的物理页就是已经存放的页。此时重复插入的目的是修改权限

## Part 3: Kernel Address Space

### 练习5

- Fill in the missing code in mem_init() after the call to check_page().

```c
boot_map_region(
  kern_pgdir,
  UPAGES,
  PTSIZE,
  PADDR(pages),
  PTE_U | PTE_P
);

boot_map_region(
  kern_pgdir,
  KSTACKTOP - KSTKSIZE,
  KSTKSIZE,
  PADDR(bootstack),
  PTE_P | PTE_W
);

boot_map_region(
  kern_pgdir,
  KERNBASE,
  -KERNBASE,
  0,
  PTE_W | PTE_P
);
```

### challenge

> 有时间再研究

## 总结

- 感觉到了前所未有的困难。这部分编程需要对物理地址和逻辑地址的概念非常深入，需要阅读大量的基础知识、翻阅JOS的大量代码以及说明。为了尽快完成实验，省略了自己从代码中慢慢摸索、学习代码结构的过程，遇到写不下去的地方直接阅读了别人验证过的代码，再结合基础来理解。掌握了基础知识，但是代码部分还是有欠缺。
- 等实验完成后除了加大考研复习力度还有很多其他工作要做（linux kernel实验、xv6源码阅读、linux pwn的练习等），chellenge和一些代码上没有熟练掌握的内容就先扔到这里。

## 复习&后记

> 由于学校课程的关系，实验被搁置了半个月，重新捡起来做Lab3的时候发现有的概念十分模糊，所以回来复习一下。这部分记录会比较零碎。

- 内核逻辑地址-KERNBASE=物理地址
- 内核页目录和表最先由boot_alloc分配，`kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;`是将内核页目录所在页插入内核页目录里
- 每个PageInfo结构体都与一个内存页一一对应，但结构体本身只记录了对应页的一些信息，而非页内容。
- 页目录表里存放的页表项是物理地址
- page2kva():将PageInfo结构体转换为对应的页物理地址，再将物理地址转换为内核虚拟地址，实现从PageInfo到对应内核虚拟地址的转换
- 
