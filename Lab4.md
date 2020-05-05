# Lab 4: Preemptive Multitasking

## Part A: Multiprocessor Support and Cooperative Multitasking

### 多处理器支持

我们将使JOS支持对称多处理（SMP），对称多处理是一种多处理器的模型，其中所有的CPU对系统资源（内存、I/O总线等）具有同等访问权限。尽管SMP种所有的CPU在功能上等同，但是在引导过程中它们可以分为两种类型：引导处理器（bootstrap processor, BSP）负责初始化和引导操作系统；只有在操作系统启动并运行之后，BSP才会激活应用处理器（AP）。BSP由硬件和BIOS决定。到目前为止，所有JOS代码都是在BSP上运行的。

在SMP系统中，每个CPU都有一个对应的本地APIC（Local Advanced Programmable Interrupt Controller，本地高级可编程中断控制器，LAPIC）单元。LAPIC单元负责在整个系统中提供中断，同时还为其连接的CPU提供唯一标识符。本实验使用了LAPIC的下述基本功能：

    - 读取LAPIC标识符（APIC ID）来得知运行当前代码的CPU。
    - 将处理器内部中断（IPI）`STARTUP`从BSP发送到AP，以启动其他CPU。
    - 在Part C中，对LAPIC的内建计时器进行编程以触发时钟中断，以支持抢占式多任务。

处理器通过使用内存映射I/O（MMIO）访问其LAPIC。在MMIO中，物理内存的一部分被硬连接到一些I/O设备的寄存器，因此通常用于访问内存的加载/存储指令也可以用于访问设备寄存器。

### 应用处理器引导

在启动AP之前，BSP应该首先收集关于多处理器系统的信息，例如CPU的总数、对应的APIC id和LAPIC单元的MMIO地址。kern/mpconfig.c中的mp_init()通过读取驻留在BIOS内存区域中的MP配置表来检索这些信息。

boot_aps()驱动了AP引导进程，AP以实模式启动，与boot.S中的引导程序非常相近，因此boot_aps()将AP入口代码复制到一个实模式下可寻址的内存区域内。与bootloader不同，我们可以控制AP从指定位置开始执行代码。我们将入口代码复制到0x7000处，但实际上任何低于640KB的页对齐的未使用物理地址也同样可以（存放入口代码）。

之后，boot_aps()将STARTIP IPIs发送到相应的LAPIC单元，并将其CS:IP初始化为AP的入口代码地址。入口处代码和boot.S十分相似。经过一些简单的设置后，使AP进入保护模式并开启分页机制，之后调用C语言设置例程mp_main()。boot_aps()等待AP在其结构体CpuInfo的cpu_status字段中发出CPU_STARTED标志的信号，然后继续唤醒下一个AP。

### Per-CPU的状态及其初始化

> 翻译时对per-CPU这个东西有点懵，于是百度了一下，发现是Linux中使用了的一种机制。简单地说，per-CPU是一个变量，每个CPU都有一个该变量的副本，每个CPU都在自己的per-CPU上工作。

在编写多处理器操作系统时，需要区分私有的per-CPU状态和整个系统共享的全局状态。kern/cpu.h定义了大部分per-CPU内容，其中包括struct CpuInfo。其存储了per-CPU的变量，cpunum()返回调用它的CPU的ID，ID可以用来作为如cpus数组的索引。

以下是需要注意的几个CPU状态：

- Per-CPU内核栈：因为多个CPU可以同时陷入内核，所以需要为per-CPU单独创建一个内核栈。lab2中，映射了引导栈将其作为BSP内核栈的物理内存，相似地，在lab3中，需要把per-CPU的内核栈都映射到这个区域，该区域使用了保护页作为这些CPU间的缓冲。CPU0的栈将会从KSTACKTOP向下生长，CPU1的栈将在CPU0的栈下方KSTKGAP处开始，以此类推。
- Per-CPU的TSS和TSS描述符：per-CPU任务状态段被用来指定每个CPU的内核栈位置。CPUi的TSS存储在`cpus[i].cpu_ts`内，交叉TSS描述符在GDT表项`gdt[(GD_TSS0 >> 3)+i]`处被定义。kern/trap.c定义的全局变量ts将不再有效。
- Per-CPU当前环境指针：因为每一个CPU都可以同时运行不同的用户进程，所以我们重新定义了curenv符号来指代`cpus[cpunum()].cpu_env 或 thiscpu->cpu_env`，它指向当前CPU正在运行的环境
- Per-CPU系统寄存器：所有的寄存器对CPU都是私有的。因此初始化这些寄存器的指令必须在每一个CPU上都被执行一次。

### Locking

当前代码在mp_main()中初始化了AP后开始旋转。在让AP更进一步之前，需要先解决多个CPU同时运行内核代码时的竞争条件。实现这一点最简单的方法就是使用一个大内核锁。大内核锁是一个单独的全局锁，每当有环境进入内核模式，它就会被占用、当环境返回到用户态时被释放。在这个模型中，用户态的环境可以并发地运行在任何一个可用的CPU上，但是在内核模式下，最多只能运行一个环境。

kern/spinlock.h声明了大内核锁，命名为kernel_lock。它同时还提供了lock_kernel()和unlock_nernel()，用来便捷地请求和释放锁。大内核锁应当在四个地方被应用：

- i386_init中，在BSP唤醒其他CPU前获取锁
- mp_main中，初始化AP后获取锁，然后调用sched_yield()以在此AP上开始运行环境
- trap中，在陷入用户态时申请锁。为了检查陷入发生在用户模式还是内核模式，需要检查tf_cs的低位。
- env_run中，在切换到用户态之前释放锁。该实现的时机不能过早也不能过晚，否则将发生竞争或死锁。

### Round-Robin Scheduling

> 实现轮询法进行调度。
