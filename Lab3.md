# Lab 3: User Environments

## Part A: User Environments and Exception Handling

- 本实验中的“环境”一词与“进程”的概念一致。JOS使用“环境”目的是区分其与UNIX的“进程”提供了不同的接口。
- JOS的envs指针指向一个Env数据结构数组来表示系统中所有的环境。JOS内核最大支持NENV个环境并发
- JOS将所有处于闲置状态的Env结构保存在env_free_list中，这种设计使得分配和释放环境变得容易（只需要从释放表中添加或移除）。
- 内核使用curenv符号追踪当前执行的环境。在启动期间，在第一个环境运行前，curenv被初始化为NULL。

### Environment State

```c
struct Env {
  struct Trapframe env_tf;  // Saved registers
  struct Env *env_link;    // Next free Env
  envid_t env_id;      // Unique environment identifier
  envid_t env_parent_id;    // env_id of this env's parent
  enum EnvType env_type;    // Indicates special system environments
  unsigned env_status;    // Status of the environment
  uint32_t env_runs;    // Number of times environment has run

  // Address space
  pde_t *env_pgdir;    // Kernel virtual address of page dir
};
```

- env_tf
  - 此结构保存环境在非运行状态下的寄存器值。如，当内核或其他环境处于运行状态，内核会在用户态切换至内核态时保存这些值，以便恢复停止时的状态。
- env_link
  - 链接到env_free_list的下一个Env。env_free_list指向列表中第一个释放的环境
- env_id
  - 内核在此存储一个值，该值唯一标识了使用该Env结构的环境。在一个用户态环境终止后，内核可能会重新分配同一个Env到一个不同的环境，但是新环境将拥有一个与原来的环境不同的env_id（即便新环境重新使用了envs数组中的同一个槽）。
- env_parent_id
  - 内核在此存储了创建了此环境的环境env_id，以此各个环境将组成一棵树，这对于“谁做什么事”的安全决策非常有用。
- env_type
  - 这个值用于区分特殊的环境。对于大多数环境，这个值为ENV_TYPE_USER。
- env_status
    该变量保存下列值之一：
  - ENV_FREE：指出Env结构处于非活跃状态，因此位于env_free_list上。
  - ENV_RUNNABLE：指出Env结构表示了一个等待被处理器运行的环境。
  - ENV_RUNNING：指出Env结构表示了正在运行的环境
  - ENV_NOT_RUNNABLE：指出Env结构表示了一个当前处于活跃状态的环境，但其并没有准备好运行。例如其正在等待另一个环境间的IPC。
  - ENV_DYING：指出Env结构表示了一个僵尸环境。一个僵尸环境将会在其下一次陷入内核时被释放。
- env_pgdir
  - 该变量保存了此环境的页目录的内核虚拟地址。

与UNIX的进程概念一致，JOS中的"环境"将线程和地址空间的概念结合起来。线程主要由保存的寄存器(env_tf字段)定义，地址空间由env_pgdir指向的页目录和页表定义。要运行一个环境，内核必须使用保存的寄存器和适当的地址空间来设置CPU。

JOS的Env与UNIX的proc类似。两者都使用了Trapframe结构保存环境在用户模式下的寄存器状态。JOS的环境与xv6中的进程不同，各个环境没有自己的内核堆栈。一次在内核中只能有一个活动的JOS环境，因此JOS只需要一个内核堆栈。

### Allocating the Environments Array

- 练习1
  - 修改kern/pmap.c下的mem_init()，为envs数组分配并映射内存。此数组由NENV个Env结构实例组成，与申请pages数组的方式非常相似。与pages数组一样，存储envs的内存也应该映射为用户态只读的UENVS，用户态进程因此得以从此数组中读取内容。

    ```c
    /*
    上两个实验此处memset未报错，lab 3中需要注释掉memset。原因待研究
    */
    kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
    //memset(kern_pgdir, 0, PGSIZE);
    ```

    ```c
    envs = (struct Env*)boot_alloc(NENV * sizeof(struct Env));
    ...
    boot_map_region(
        kern_pgdir,
        UENVS,
        PTSIZE,
        PADDR(envs),
        PTE_U | PTE_P
    );
    ```

  - 练习1没有难度，倒是发现了以前的一个代码错误。错误信息`Physical memory: 131072K available, base = 640K, extended = 130432K`、`kernel panic at kern/pmap.c:146: PADDR called with invalid kva 00000000`

### Creating and Running Environments

- 练习2：完成下列函数
  - env_init()：初始化envs数组中所有Env结构，将它们添加到enc_free_list中。调用env_init_percpu，该函数使用分段硬件为内核态和用户态单独设置了段。
  - env_setup_vm()：为一个新的环境分配一个页目录，初始化新环境的地址空间的内核部分
  - region_alloc()：为一个新环境分配并映射物理内存
  - load_icode()：解析一个ELF格式的二进制映像，并将其加载到新环境的用户地址空间
  - env_create()：使用env_alloc申请一个新环境，并调用load_icode向环境中加载一个ELF二进制文件
  - env_run()：启动一个给定的以用户模式运行的环境
  - 使用cprintf的%e可以输出错误信息（会引发恐慌）

- env_init

```c
void env_init(void){
  // Set up envs array
  // LAB 3: Your code here.
  int i;
  for(i=NENV;i>0;i--){
    envs[i].env_id = 0;
    envs[i].env_link = env_free_list->env_link;
    env_free_list = &envs[i];
  }
  // Per-CPU part of the initialization
  env_init_percpu();
}
```

- env_setup_vm

```c
static int env_setup_vm(struct Env *e){
  int i;
  struct PageInfo *p = NULL;

  // Allocate a page for the page directory
  if (!(p = page_alloc(ALLOC_ZERO)))
    return -E_NO_MEM;

  // Now, set e->env_pgdir and initialize the page directory.
  //
  // Hint:
  //    - The VA space of all envs is identical above UTOP
  //  (except at UVPT, which we've set below).
  //  See inc/memlayout.h for permissions and layout.
  //  Can you use kern_pgdir as a template?  Hint: Yes.
  //  (Make sure you got the permissions right in Lab 2.)
  //    - The initial VA below UTOP is empty.
  //    - You do not need to make any more calls to page_alloc.
  //    - Note: In general, pp_ref is not maintained for
  //  physical pages mapped only above UTOP, but env_pgdir
  //  is an exception -- you need to increment env_pgdir's
  //  pp_ref for env_free to work correctly.
  //    - The functions in kern/pmap.h are handy.

  // LAB 3: Your code here.
  p->pp_ref++;
  e->env_pgdir = (pde_t *)page2kva(p);
  memcpy(e->env_pgdir, kern_pgdir, PGSIZE);

  // UVPT maps the env's own page table read-only.
  // Permissions: kernel R, user R
  e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
  return 0;
}
```

- region_alloc

```c
static void region_alloc(struct Env *e, void *va, size_t len){
  // LAB 3: Your code here.
  // (But only if you need it for load_icode.)
  void *begin = ROUNDDOWN(va, PGSIZE);
  void *end = ROUNDUP(va+len, PGSIZE);
  for(; begin<end;begin+=PGSIZE){
    struct PageInfo* p = page_alloc(0);
    if(!p) cprintf("%e", "region_alloc error");
    page_insert(e->env_pgdir, p, begin, PTE_W|PTE_U);
  }
  // Hint: It is easier to use region_alloc if the caller can pass
  //   'va' and 'len' values that are not page-aligned.
  //   You should round va down, and round (va + len) up.
  //   (Watch out for corner-cases!)
}
```

- load_icode

```c
static void load_icode(struct Env *e, uint8_t *binary){
  // Hints:
  //  Load each program segment into virtual memory
  //  at the address specified in the ELF segment header.
  //  You should only load segments with ph->p_type == ELF_PROG_LOAD.
  //  Each segment's virtual address can be found in ph->p_va
  //  and its size in memory can be found in ph->p_memsz.
  //  The ph->p_filesz bytes from the ELF binary, starting at
  //  'binary + ph->p_offset', should be copied to virtual address
  //  ph->p_va.  Any remaining memory bytes should be cleared to zero.
  //  (The ELF header should have ph->p_filesz <= ph->p_memsz.)
  //  Use functions from the previous lab to allocate and map pages.
  //
  //  All page protection bits should be user read/write for now.
  //  ELF segments are not necessarily page-aligned, but you can
  //  assume for this function that no two segments will touch
  //  the same virtual page.
  //
  //  You may find a function like region_alloc useful.
  //
  //  Loading the segments is much simpler if you can move data
  //  directly into the virtual addresses stored in the ELF binary.
  //  So which page directory should be in force during
  //  this function?
  //
  //  You must also do something with the program's entry point,
  //  to make sure that the environment starts executing there.
  //  What?  (See env_run() and env_pop_tf() below.)

  // LAB 3: Your code here.
  struct Elf* ELFHDR = (struct Elf*) binary; // ELF文件头部指针
  struct Proghdr *ph, *eph; // 进程头部指针
  if(ELFHDR->e_magic != ELF_MAGIC){
    panic("The file is not a ELF format file");
  }
  ph = (struct Proghdr*)((uint8_t*)ELFHDR + ELFHDR->e_phoff);// 进程头指向e_phoff偏移处
  eph = ph + ELFHDR->e_phnum;

  lcr3(PADDR(e->env_pgdir));// 加载env页
  for(;ph<eph;ph++){
    if(ph->p_type == ELF_PROG_LOAD){
      region_alloc(e, (void*)ph->p_va, ph->p_memsz);
      memset((void*)ph->p_va, 0, ph->p_memsz);
      memcpy((void*)ph->p_va, binary+ph->p_offset, ph->p_filesz);
    }
  }

  lcr3(PADDR(kern_pgdir));

  e->env_tf.tf_eip = ELFHDR->e_entry;
  
  // Now map one page for the program's initial stack
  // at virtual address USTACKTOP - PGSIZE.

  // LAB 3: Your code here.
  region_alloc(e, (void*)(USTACKTOP - PGSIZE), PGSIZE);
}
```

- env_create

```c
void env_create(uint8_t *binary, enum EnvType type){
  // LAB 3: Your code here.
  struct Env* penv;
  env_alloc(&penv, 0);
  load_icode(penv, binary);
}
```

- env_run

```c
void env_run(struct Env *e){
  // Step 1: If this is a context switch (a new environment is running):
  //     1. Set the current environment (if any) back to
  //        ENV_RUNNABLE if it is ENV_RUNNING (think about
  //        what other states it can be in),
  //     2. Set 'curenv' to the new environment,
  //     3. Set its status to ENV_RUNNING,
  //     4. Update its 'env_runs' counter,
  //     5. Use lcr3() to switch to its address space.
  // Step 2: Use env_pop_tf() to restore the environment's
  //     registers and drop into user mode in the
  //     environment.

  // Hint: This function loads the new environment's state from
  //  e->env_tf.  Go back through the code you wrote above
  //  and make sure you have set the relevant parts of
  //  e->env_tf to sensible values.

  // LAB 3: Your code here.
  if(e->env_status == ENV_RUNNING){
    e->env_status = ENV_RUNNABLE;
  }
  curenv = e;
  e->env_status = ENV_RUNNING;
  e->env_runs++;
  lcr3(PADDR(e->env_pgdir));
  env_pop_tf(&e->env_tf);
  // panic("env_run not yet implemented");
}
```

以下是用户环境运行前的调用顺序：

- start (kern/entry.S)
- i386_init (kern/init.c)
  - cons_init
  - mem_init
  - env_init
  - trap_init (此时未实现)
  - env_create
  - env_run
    - env_pop_tf

### Basics of Protected Control Transfer

异常和中断都是受保护的控制传输方式，它们会使得处理器从用户态切换至内核态，同时防止用户代码干扰内核或其他环境（进程）。中断是处理器外部的异步事件引起的，而异常是代码同步引起的（如除以0、无效内存访问）。

为了确保这些机制受到保护，在中断或异常发生时，处理器会确保只能在严格的条件下进入内核，x86中有两种机制共同提供了这类保护:

1. 中断描述符表。处理器确保中断和异常只能通过定义好的入口点进入内核，而不是由在中断或异常发生时的代码来进入。x86最多允许256了不同的中断或异常入口点，每个都具有不同的中断向量。中断向量是0-255间的数字，CPU使用该数字作为到中断描述符表的索引，内核讲IDT设置在一块专门的内存中，这点与GDT十分类似。从合适的IDT入口处，CPU会加载：
   1. 要加载到EIP寄存器的值，指向指定处理该类型异常的内核代码。
   2. 要加载到CS寄存器的值，该寄存器以0-1位的形式包含要运行异常处理程序的特权级，JOS中所有的异常特权级都为0。
2. 任务状态段。处理器需要保留中断或异常发生前的状态，以便在中断或异常恢复后离开。同时保存先前状态的区域必须受到保护，不能被非特权用户模式代码所影响，否则恶意的用户代码可能会危及内核。因此当x86处理器发生中断或陷入，导致用户态转换到内核态的特权级变化时，它还会切换到内核内存中的栈，任务状态段（TSS）这一结构指定了栈段的段选择子和地址。处理器将SS、ESP、EFLAGS、CS、EIP和一个作为可选项的错误码压栈，然后从中断描述符中加载CS和EIP，再设置ESP和SS引用新的栈。尽管TSS很大、可以有多种用途，JOS中只使用它定义处理器从用户态转换到内核态对应的内核栈。由于JOS的内核态对应x86的特权级0，因此在进入内核模式时，处理器使用TSS的TSP0和SS0字段定义内核栈。

### Types of Exceptions and Interrupts

x86能在内部生成的所有同步异常都使用0-31间的中断向量，因此映射IDT的0-31条目。例如页错误总是由中断向量14引起。大于31的中断向量仅用于：软件中断，其可由INT指令生成；或在外部设备需要被注意时产生的异步硬件中断。

### An Example

假设处理器正在用户环境中执行代码，遇到了一条试图除以0的除法指令。

1. 处理器切换到由TSS的SS0和ESP0定义的栈，在JOS中这两个字段分别包含GD_KD和KSTACKTOP值。
2. 处理器将异常参数压入内核栈，并从KSTACKTOP开始执行

    ```c
      +--------------------+ KSTACKTOP
    | 0x00000 | old SS   |     " - 4
    |      old ESP       |     " - 8
    |     old EFLAGS     |     " - 12
    | 0x00000 | old CS   |     " - 16
    |      old EIP       |     " - 20 <---- ESP
    +--------------------+
    ```

3. 因为我们正在处理一个除法错误，对应着x86的中断向量0，所以处理器通过读取IDT条目0并设置CS:EIP来指向条目描述的处理函数。
4. 处理程序控制并处理异常，例如终止用户环境。

对于某些类型的x86异常，除了上图的5个标准字段外，处理器还会将一个错误代码压栈。页错误异常是一个很重要的例子。当处理器推送错误代码、从用户模式进入异常处理程序时，栈如下所示：

```c
+--------------------+ KSTACKTOP
| 0x00000 | old SS   |     " - 4
|      old ESP       |     " - 8
|     old EFLAGS     |     " - 12
| 0x00000 | old CS   |     " - 16
|      old EIP       |     " - 20
|     error code     |     " - 24 <---- ESP
+--------------------+
```

### Nested Exceptions and Interrupts

处理器可以从内核态和用户态获取异常和中断。然而，只有在从用户态进入内核态时，x86处理器才会在将*旧的寄存器状态压栈并通过IDT调用异常处理程序*之前自动切换栈。如果发生中断或异常时处理器已经处于内核态（CS低2位为0），那么CPU仅会向同一个内核栈压入更多的值。这样，内核可以优雅地处理由内核本身的内部代码引发的嵌套异常。

如果处理器已经处于内核态并获取了嵌套异常，因为它不需要切换栈，所以处理器不需要保存旧的SS或ESP寄存器。有的异常类型不推送错误码，因此内核栈的异常处理入口处看起来类似下图所示。

```c
+--------------------+ <---- old ESP
|     old EFLAGS     |     " - 4
| 0x00000 | old CS   |     " - 8
|      old EIP       |     " - 12
+--------------------+
```

对于将错误码压栈的异常类型，处理器会像之前一样在旧的EIP后立刻将错误码压栈。处理器嵌套异常功能有一个重要的警告，如果处理器处于内核态时已经发生异常，并且由于栈空间不足等原因无法将旧状态压栈，那么处理器就无法进行任何恢复行为，此时处理器只会重置自身。