
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 60 11 00       	mov    $0x116000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 60 11 f0       	mov    $0xf0116000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
int backtrace(int argc, char **argv, struct Trapframe *tf);

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 60 19 10 f0       	push   $0xf0101960
f0100050:	e8 a0 09 00 00       	call   f01009f5 <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 4d 07 00 00       	call   f01007c8 <backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 7c 19 10 f0       	push   $0xf010197c
f0100087:	e8 69 09 00 00       	call   f01009f5 <cprintf>
f010008c:	83 c4 10             	add    $0x10,%esp
}
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 48 89 11 f0       	mov    $0xf0118948,%eax
f010009f:	2d 00 83 11 f0       	sub    $0xf0118300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 83 11 f0       	push   $0xf0118300
f01000ac:	e8 54 14 00 00       	call   f0101505 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 76 04 00 00       	call   f010052c <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 97 19 10 f0       	push   $0xf0101997
f01000c3:	e8 2d 09 00 00       	call   f01009f5 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 85 07 00 00       	call   f0100866 <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 40 89 11 f0 00 	cmpl   $0x0,0xf0118940
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 40 89 11 f0    	mov    %esi,0xf0118940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 b2 19 10 f0       	push   $0xf01019b2
f0100110:	e8 e0 08 00 00       	call   f01009f5 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 b0 08 00 00       	call   f01009cf <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 ee 19 10 f0 	movl   $0xf01019ee,(%esp)
f0100126:	e8 ca 08 00 00       	call   f01009f5 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 2e 07 00 00       	call   f0100866 <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 ca 19 10 f0       	push   $0xf01019ca
f0100152:	e8 9e 08 00 00       	call   f01009f5 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 6c 08 00 00       	call   f01009cf <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 ee 19 10 f0 	movl   $0xf01019ee,(%esp)
f010016a:	e8 86 08 00 00       	call   f01009f5 <cprintf>
	va_end(ap);
f010016f:	83 c4 10             	add    $0x10,%esp
}
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    
	...

f0100178 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100178:	55                   	push   %ebp
f0100179:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017b:	ba 84 00 00 00       	mov    $0x84,%edx
f0100180:	ec                   	in     (%dx),%al
f0100181:	ec                   	in     (%dx),%al
f0100182:	ec                   	in     (%dx),%al
f0100183:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f0100184:	c9                   	leave  
f0100185:	c3                   	ret    

f0100186 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100186:	55                   	push   %ebp
f0100187:	89 e5                	mov    %esp,%ebp
f0100189:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010018e:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010018f:	a8 01                	test   $0x1,%al
f0100191:	74 08                	je     f010019b <serial_proc_data+0x15>
f0100193:	b2 f8                	mov    $0xf8,%dl
f0100195:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100196:	0f b6 c0             	movzbl %al,%eax
f0100199:	eb 05                	jmp    f01001a0 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010019b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001a0:	c9                   	leave  
f01001a1:	c3                   	ret    

f01001a2 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001a2:	55                   	push   %ebp
f01001a3:	89 e5                	mov    %esp,%ebp
f01001a5:	53                   	push   %ebx
f01001a6:	83 ec 04             	sub    $0x4,%esp
f01001a9:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001ab:	eb 29                	jmp    f01001d6 <cons_intr+0x34>
		if (c == 0)
f01001ad:	85 c0                	test   %eax,%eax
f01001af:	74 25                	je     f01001d6 <cons_intr+0x34>
			continue;
		cons.buf[cons.wpos++] = c;
f01001b1:	8b 15 24 85 11 f0    	mov    0xf0118524,%edx
f01001b7:	88 82 20 83 11 f0    	mov    %al,-0xfee7ce0(%edx)
f01001bd:	8d 42 01             	lea    0x1(%edx),%eax
f01001c0:	a3 24 85 11 f0       	mov    %eax,0xf0118524
		if (cons.wpos == CONSBUFSIZE)
f01001c5:	3d 00 02 00 00       	cmp    $0x200,%eax
f01001ca:	75 0a                	jne    f01001d6 <cons_intr+0x34>
			cons.wpos = 0;
f01001cc:	c7 05 24 85 11 f0 00 	movl   $0x0,0xf0118524
f01001d3:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001d6:	ff d3                	call   *%ebx
f01001d8:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001db:	75 d0                	jne    f01001ad <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001dd:	83 c4 04             	add    $0x4,%esp
f01001e0:	5b                   	pop    %ebx
f01001e1:	c9                   	leave  
f01001e2:	c3                   	ret    

f01001e3 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01001e3:	55                   	push   %ebp
f01001e4:	89 e5                	mov    %esp,%ebp
f01001e6:	57                   	push   %edi
f01001e7:	56                   	push   %esi
f01001e8:	53                   	push   %ebx
f01001e9:	83 ec 0c             	sub    $0xc,%esp
f01001ec:	89 c6                	mov    %eax,%esi
f01001ee:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001f3:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01001f4:	a8 20                	test   $0x20,%al
f01001f6:	75 19                	jne    f0100211 <cons_putc+0x2e>
f01001f8:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01001fd:	bf fd 03 00 00       	mov    $0x3fd,%edi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f0100202:	e8 71 ff ff ff       	call   f0100178 <delay>
f0100207:	89 fa                	mov    %edi,%edx
f0100209:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010020a:	a8 20                	test   $0x20,%al
f010020c:	75 03                	jne    f0100211 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010020e:	4b                   	dec    %ebx
f010020f:	75 f1                	jne    f0100202 <cons_putc+0x1f>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100211:	89 f7                	mov    %esi,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100213:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100218:	89 f0                	mov    %esi,%eax
f010021a:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010021b:	b2 79                	mov    $0x79,%dl
f010021d:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010021e:	84 c0                	test   %al,%al
f0100220:	78 1d                	js     f010023f <cons_putc+0x5c>
f0100222:	bb 00 00 00 00       	mov    $0x0,%ebx
		delay();
f0100227:	e8 4c ff ff ff       	call   f0100178 <delay>
f010022c:	ba 79 03 00 00       	mov    $0x379,%edx
f0100231:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100232:	84 c0                	test   %al,%al
f0100234:	78 09                	js     f010023f <cons_putc+0x5c>
f0100236:	43                   	inc    %ebx
f0100237:	81 fb 00 32 00 00    	cmp    $0x3200,%ebx
f010023d:	75 e8                	jne    f0100227 <cons_putc+0x44>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010023f:	ba 78 03 00 00       	mov    $0x378,%edx
f0100244:	89 f8                	mov    %edi,%eax
f0100246:	ee                   	out    %al,(%dx)
f0100247:	b2 7a                	mov    $0x7a,%dl
f0100249:	b0 0d                	mov    $0xd,%al
f010024b:	ee                   	out    %al,(%dx)
f010024c:	b0 08                	mov    $0x8,%al
f010024e:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!csa) csa = 0x0700;
f010024f:	83 3d 44 89 11 f0 00 	cmpl   $0x0,0xf0118944
f0100256:	75 0a                	jne    f0100262 <cons_putc+0x7f>
f0100258:	c7 05 44 89 11 f0 00 	movl   $0x700,0xf0118944
f010025f:	07 00 00 
	if (!(c & ~0xFF))
f0100262:	f7 c6 00 ff ff ff    	test   $0xffffff00,%esi
f0100268:	75 06                	jne    f0100270 <cons_putc+0x8d>
		c |= csa;
f010026a:	0b 35 44 89 11 f0    	or     0xf0118944,%esi

	switch (c & 0xff) {
f0100270:	89 f0                	mov    %esi,%eax
f0100272:	25 ff 00 00 00       	and    $0xff,%eax
f0100277:	83 f8 09             	cmp    $0x9,%eax
f010027a:	74 78                	je     f01002f4 <cons_putc+0x111>
f010027c:	83 f8 09             	cmp    $0x9,%eax
f010027f:	7f 0b                	jg     f010028c <cons_putc+0xa9>
f0100281:	83 f8 08             	cmp    $0x8,%eax
f0100284:	0f 85 9e 00 00 00    	jne    f0100328 <cons_putc+0x145>
f010028a:	eb 10                	jmp    f010029c <cons_putc+0xb9>
f010028c:	83 f8 0a             	cmp    $0xa,%eax
f010028f:	74 39                	je     f01002ca <cons_putc+0xe7>
f0100291:	83 f8 0d             	cmp    $0xd,%eax
f0100294:	0f 85 8e 00 00 00    	jne    f0100328 <cons_putc+0x145>
f010029a:	eb 36                	jmp    f01002d2 <cons_putc+0xef>
	case '\b':
		if (crt_pos > 0) {
f010029c:	66 a1 00 83 11 f0    	mov    0xf0118300,%ax
f01002a2:	66 85 c0             	test   %ax,%ax
f01002a5:	0f 84 e0 00 00 00    	je     f010038b <cons_putc+0x1a8>
			crt_pos--;
f01002ab:	48                   	dec    %eax
f01002ac:	66 a3 00 83 11 f0    	mov    %ax,0xf0118300
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002b2:	0f b7 c0             	movzwl %ax,%eax
f01002b5:	81 e6 00 ff ff ff    	and    $0xffffff00,%esi
f01002bb:	83 ce 20             	or     $0x20,%esi
f01002be:	8b 15 04 83 11 f0    	mov    0xf0118304,%edx
f01002c4:	66 89 34 42          	mov    %si,(%edx,%eax,2)
f01002c8:	eb 78                	jmp    f0100342 <cons_putc+0x15f>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01002ca:	66 83 05 00 83 11 f0 	addw   $0x50,0xf0118300
f01002d1:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01002d2:	66 8b 0d 00 83 11 f0 	mov    0xf0118300,%cx
f01002d9:	bb 50 00 00 00       	mov    $0x50,%ebx
f01002de:	89 c8                	mov    %ecx,%eax
f01002e0:	ba 00 00 00 00       	mov    $0x0,%edx
f01002e5:	66 f7 f3             	div    %bx
f01002e8:	66 29 d1             	sub    %dx,%cx
f01002eb:	66 89 0d 00 83 11 f0 	mov    %cx,0xf0118300
f01002f2:	eb 4e                	jmp    f0100342 <cons_putc+0x15f>
		break;
	case '\t':
		cons_putc(' ');
f01002f4:	b8 20 00 00 00       	mov    $0x20,%eax
f01002f9:	e8 e5 fe ff ff       	call   f01001e3 <cons_putc>
		cons_putc(' ');
f01002fe:	b8 20 00 00 00       	mov    $0x20,%eax
f0100303:	e8 db fe ff ff       	call   f01001e3 <cons_putc>
		cons_putc(' ');
f0100308:	b8 20 00 00 00       	mov    $0x20,%eax
f010030d:	e8 d1 fe ff ff       	call   f01001e3 <cons_putc>
		cons_putc(' ');
f0100312:	b8 20 00 00 00       	mov    $0x20,%eax
f0100317:	e8 c7 fe ff ff       	call   f01001e3 <cons_putc>
		cons_putc(' ');
f010031c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100321:	e8 bd fe ff ff       	call   f01001e3 <cons_putc>
f0100326:	eb 1a                	jmp    f0100342 <cons_putc+0x15f>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100328:	66 a1 00 83 11 f0    	mov    0xf0118300,%ax
f010032e:	0f b7 c8             	movzwl %ax,%ecx
f0100331:	8b 15 04 83 11 f0    	mov    0xf0118304,%edx
f0100337:	66 89 34 4a          	mov    %si,(%edx,%ecx,2)
f010033b:	40                   	inc    %eax
f010033c:	66 a3 00 83 11 f0    	mov    %ax,0xf0118300
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100342:	66 81 3d 00 83 11 f0 	cmpw   $0x7cf,0xf0118300
f0100349:	cf 07 
f010034b:	76 3e                	jbe    f010038b <cons_putc+0x1a8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010034d:	a1 04 83 11 f0       	mov    0xf0118304,%eax
f0100352:	83 ec 04             	sub    $0x4,%esp
f0100355:	68 00 0f 00 00       	push   $0xf00
f010035a:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100360:	52                   	push   %edx
f0100361:	50                   	push   %eax
f0100362:	e8 e8 11 00 00       	call   f010154f <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100367:	8b 15 04 83 11 f0    	mov    0xf0118304,%edx
f010036d:	83 c4 10             	add    $0x10,%esp
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100370:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100375:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010037b:	40                   	inc    %eax
f010037c:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100381:	75 f2                	jne    f0100375 <cons_putc+0x192>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100383:	66 83 2d 00 83 11 f0 	subw   $0x50,0xf0118300
f010038a:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010038b:	8b 0d 08 83 11 f0    	mov    0xf0118308,%ecx
f0100391:	b0 0e                	mov    $0xe,%al
f0100393:	89 ca                	mov    %ecx,%edx
f0100395:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100396:	66 8b 35 00 83 11 f0 	mov    0xf0118300,%si
f010039d:	8d 59 01             	lea    0x1(%ecx),%ebx
f01003a0:	89 f0                	mov    %esi,%eax
f01003a2:	66 c1 e8 08          	shr    $0x8,%ax
f01003a6:	89 da                	mov    %ebx,%edx
f01003a8:	ee                   	out    %al,(%dx)
f01003a9:	b0 0f                	mov    $0xf,%al
f01003ab:	89 ca                	mov    %ecx,%edx
f01003ad:	ee                   	out    %al,(%dx)
f01003ae:	89 f0                	mov    %esi,%eax
f01003b0:	89 da                	mov    %ebx,%edx
f01003b2:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003b3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01003b6:	5b                   	pop    %ebx
f01003b7:	5e                   	pop    %esi
f01003b8:	5f                   	pop    %edi
f01003b9:	c9                   	leave  
f01003ba:	c3                   	ret    

f01003bb <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003bb:	55                   	push   %ebp
f01003bc:	89 e5                	mov    %esp,%ebp
f01003be:	53                   	push   %ebx
f01003bf:	83 ec 04             	sub    $0x4,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003c2:	ba 64 00 00 00       	mov    $0x64,%edx
f01003c7:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01003c8:	a8 01                	test   $0x1,%al
f01003ca:	0f 84 dc 00 00 00    	je     f01004ac <kbd_proc_data+0xf1>
f01003d0:	b2 60                	mov    $0x60,%dl
f01003d2:	ec                   	in     (%dx),%al
f01003d3:	88 c2                	mov    %al,%dl
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01003d5:	3c e0                	cmp    $0xe0,%al
f01003d7:	75 11                	jne    f01003ea <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01003d9:	83 0d 28 85 11 f0 40 	orl    $0x40,0xf0118528
		return 0;
f01003e0:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003e5:	e9 c7 00 00 00       	jmp    f01004b1 <kbd_proc_data+0xf6>
	} else if (data & 0x80) {
f01003ea:	84 c0                	test   %al,%al
f01003ec:	79 33                	jns    f0100421 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003ee:	8b 0d 28 85 11 f0    	mov    0xf0118528,%ecx
f01003f4:	f6 c1 40             	test   $0x40,%cl
f01003f7:	75 05                	jne    f01003fe <kbd_proc_data+0x43>
f01003f9:	88 c2                	mov    %al,%dl
f01003fb:	83 e2 7f             	and    $0x7f,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003fe:	0f b6 d2             	movzbl %dl,%edx
f0100401:	8a 82 20 1a 10 f0    	mov    -0xfefe5e0(%edx),%al
f0100407:	83 c8 40             	or     $0x40,%eax
f010040a:	0f b6 c0             	movzbl %al,%eax
f010040d:	f7 d0                	not    %eax
f010040f:	21 c1                	and    %eax,%ecx
f0100411:	89 0d 28 85 11 f0    	mov    %ecx,0xf0118528
		return 0;
f0100417:	bb 00 00 00 00       	mov    $0x0,%ebx
f010041c:	e9 90 00 00 00       	jmp    f01004b1 <kbd_proc_data+0xf6>
	} else if (shift & E0ESC) {
f0100421:	8b 0d 28 85 11 f0    	mov    0xf0118528,%ecx
f0100427:	f6 c1 40             	test   $0x40,%cl
f010042a:	74 0e                	je     f010043a <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010042c:	88 c2                	mov    %al,%dl
f010042e:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f0100431:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100434:	89 0d 28 85 11 f0    	mov    %ecx,0xf0118528
	}

	shift |= shiftcode[data];
f010043a:	0f b6 d2             	movzbl %dl,%edx
f010043d:	0f b6 82 20 1a 10 f0 	movzbl -0xfefe5e0(%edx),%eax
f0100444:	0b 05 28 85 11 f0    	or     0xf0118528,%eax
	shift ^= togglecode[data];
f010044a:	0f b6 8a 20 1b 10 f0 	movzbl -0xfefe4e0(%edx),%ecx
f0100451:	31 c8                	xor    %ecx,%eax
f0100453:	a3 28 85 11 f0       	mov    %eax,0xf0118528

	c = charcode[shift & (CTL | SHIFT)][data];
f0100458:	89 c1                	mov    %eax,%ecx
f010045a:	83 e1 03             	and    $0x3,%ecx
f010045d:	8b 0c 8d 20 1c 10 f0 	mov    -0xfefe3e0(,%ecx,4),%ecx
f0100464:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f0100468:	a8 08                	test   $0x8,%al
f010046a:	74 18                	je     f0100484 <kbd_proc_data+0xc9>
		if ('a' <= c && c <= 'z')
f010046c:	8d 53 9f             	lea    -0x61(%ebx),%edx
f010046f:	83 fa 19             	cmp    $0x19,%edx
f0100472:	77 05                	ja     f0100479 <kbd_proc_data+0xbe>
			c += 'A' - 'a';
f0100474:	83 eb 20             	sub    $0x20,%ebx
f0100477:	eb 0b                	jmp    f0100484 <kbd_proc_data+0xc9>
		else if ('A' <= c && c <= 'Z')
f0100479:	8d 53 bf             	lea    -0x41(%ebx),%edx
f010047c:	83 fa 19             	cmp    $0x19,%edx
f010047f:	77 03                	ja     f0100484 <kbd_proc_data+0xc9>
			c += 'a' - 'A';
f0100481:	83 c3 20             	add    $0x20,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100484:	f7 d0                	not    %eax
f0100486:	a8 06                	test   $0x6,%al
f0100488:	75 27                	jne    f01004b1 <kbd_proc_data+0xf6>
f010048a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100490:	75 1f                	jne    f01004b1 <kbd_proc_data+0xf6>
		cprintf("Rebooting!\n");
f0100492:	83 ec 0c             	sub    $0xc,%esp
f0100495:	68 e4 19 10 f0       	push   $0xf01019e4
f010049a:	e8 56 05 00 00       	call   f01009f5 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010049f:	ba 92 00 00 00       	mov    $0x92,%edx
f01004a4:	b0 03                	mov    $0x3,%al
f01004a6:	ee                   	out    %al,(%dx)
f01004a7:	83 c4 10             	add    $0x10,%esp
f01004aa:	eb 05                	jmp    f01004b1 <kbd_proc_data+0xf6>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01004ac:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01004b1:	89 d8                	mov    %ebx,%eax
f01004b3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01004b6:	c9                   	leave  
f01004b7:	c3                   	ret    

f01004b8 <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004b8:	55                   	push   %ebp
f01004b9:	89 e5                	mov    %esp,%ebp
f01004bb:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f01004be:	80 3d 0c 83 11 f0 00 	cmpb   $0x0,0xf011830c
f01004c5:	74 0a                	je     f01004d1 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f01004c7:	b8 86 01 10 f0       	mov    $0xf0100186,%eax
f01004cc:	e8 d1 fc ff ff       	call   f01001a2 <cons_intr>
}
f01004d1:	c9                   	leave  
f01004d2:	c3                   	ret    

f01004d3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004d3:	55                   	push   %ebp
f01004d4:	89 e5                	mov    %esp,%ebp
f01004d6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004d9:	b8 bb 03 10 f0       	mov    $0xf01003bb,%eax
f01004de:	e8 bf fc ff ff       	call   f01001a2 <cons_intr>
}
f01004e3:	c9                   	leave  
f01004e4:	c3                   	ret    

f01004e5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004e5:	55                   	push   %ebp
f01004e6:	89 e5                	mov    %esp,%ebp
f01004e8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004eb:	e8 c8 ff ff ff       	call   f01004b8 <serial_intr>
	kbd_intr();
f01004f0:	e8 de ff ff ff       	call   f01004d3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004f5:	8b 15 20 85 11 f0    	mov    0xf0118520,%edx
f01004fb:	3b 15 24 85 11 f0    	cmp    0xf0118524,%edx
f0100501:	74 22                	je     f0100525 <cons_getc+0x40>
		c = cons.buf[cons.rpos++];
f0100503:	0f b6 82 20 83 11 f0 	movzbl -0xfee7ce0(%edx),%eax
f010050a:	42                   	inc    %edx
f010050b:	89 15 20 85 11 f0    	mov    %edx,0xf0118520
		if (cons.rpos == CONSBUFSIZE)
f0100511:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100517:	75 11                	jne    f010052a <cons_getc+0x45>
			cons.rpos = 0;
f0100519:	c7 05 20 85 11 f0 00 	movl   $0x0,0xf0118520
f0100520:	00 00 00 
f0100523:	eb 05                	jmp    f010052a <cons_getc+0x45>
		return c;
	}
	return 0;
f0100525:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010052a:	c9                   	leave  
f010052b:	c3                   	ret    

f010052c <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010052c:	55                   	push   %ebp
f010052d:	89 e5                	mov    %esp,%ebp
f010052f:	57                   	push   %edi
f0100530:	56                   	push   %esi
f0100531:	53                   	push   %ebx
f0100532:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100535:	66 8b 15 00 80 0b f0 	mov    0xf00b8000,%dx
	*cp = (uint16_t) 0xA55A;
f010053c:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100543:	5a a5 
	if (*cp != 0xA55A) {
f0100545:	66 a1 00 80 0b f0    	mov    0xf00b8000,%ax
f010054b:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010054f:	74 11                	je     f0100562 <cons_init+0x36>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100551:	c7 05 08 83 11 f0 b4 	movl   $0x3b4,0xf0118308
f0100558:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010055b:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100560:	eb 16                	jmp    f0100578 <cons_init+0x4c>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100562:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100569:	c7 05 08 83 11 f0 d4 	movl   $0x3d4,0xf0118308
f0100570:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100573:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100578:	8b 0d 08 83 11 f0    	mov    0xf0118308,%ecx
f010057e:	b0 0e                	mov    $0xe,%al
f0100580:	89 ca                	mov    %ecx,%edx
f0100582:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100583:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100586:	89 da                	mov    %ebx,%edx
f0100588:	ec                   	in     (%dx),%al
f0100589:	0f b6 f8             	movzbl %al,%edi
f010058c:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010058f:	b0 0f                	mov    $0xf,%al
f0100591:	89 ca                	mov    %ecx,%edx
f0100593:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100594:	89 da                	mov    %ebx,%edx
f0100596:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100597:	89 35 04 83 11 f0    	mov    %esi,0xf0118304

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f010059d:	0f b6 d8             	movzbl %al,%ebx
f01005a0:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005a2:	66 89 3d 00 83 11 f0 	mov    %di,0xf0118300
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005a9:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01005ae:	b0 00                	mov    $0x0,%al
f01005b0:	89 da                	mov    %ebx,%edx
f01005b2:	ee                   	out    %al,(%dx)
f01005b3:	b2 fb                	mov    $0xfb,%dl
f01005b5:	b0 80                	mov    $0x80,%al
f01005b7:	ee                   	out    %al,(%dx)
f01005b8:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f01005bd:	b0 0c                	mov    $0xc,%al
f01005bf:	89 ca                	mov    %ecx,%edx
f01005c1:	ee                   	out    %al,(%dx)
f01005c2:	b2 f9                	mov    $0xf9,%dl
f01005c4:	b0 00                	mov    $0x0,%al
f01005c6:	ee                   	out    %al,(%dx)
f01005c7:	b2 fb                	mov    $0xfb,%dl
f01005c9:	b0 03                	mov    $0x3,%al
f01005cb:	ee                   	out    %al,(%dx)
f01005cc:	b2 fc                	mov    $0xfc,%dl
f01005ce:	b0 00                	mov    $0x0,%al
f01005d0:	ee                   	out    %al,(%dx)
f01005d1:	b2 f9                	mov    $0xf9,%dl
f01005d3:	b0 01                	mov    $0x1,%al
f01005d5:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d6:	b2 fd                	mov    $0xfd,%dl
f01005d8:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d9:	3c ff                	cmp    $0xff,%al
f01005db:	0f 95 45 e7          	setne  -0x19(%ebp)
f01005df:	8a 45 e7             	mov    -0x19(%ebp),%al
f01005e2:	a2 0c 83 11 f0       	mov    %al,0xf011830c
f01005e7:	89 da                	mov    %ebx,%edx
f01005e9:	ec                   	in     (%dx),%al
f01005ea:	89 ca                	mov    %ecx,%edx
f01005ec:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005ed:	80 7d e7 00          	cmpb   $0x0,-0x19(%ebp)
f01005f1:	75 10                	jne    f0100603 <cons_init+0xd7>
		cprintf("Serial port does not exist!\n");
f01005f3:	83 ec 0c             	sub    $0xc,%esp
f01005f6:	68 f0 19 10 f0       	push   $0xf01019f0
f01005fb:	e8 f5 03 00 00       	call   f01009f5 <cprintf>
f0100600:	83 c4 10             	add    $0x10,%esp
}
f0100603:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100606:	5b                   	pop    %ebx
f0100607:	5e                   	pop    %esi
f0100608:	5f                   	pop    %edi
f0100609:	c9                   	leave  
f010060a:	c3                   	ret    

f010060b <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010060b:	55                   	push   %ebp
f010060c:	89 e5                	mov    %esp,%ebp
f010060e:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100611:	8b 45 08             	mov    0x8(%ebp),%eax
f0100614:	e8 ca fb ff ff       	call   f01001e3 <cons_putc>
}
f0100619:	c9                   	leave  
f010061a:	c3                   	ret    

f010061b <getchar>:

int
getchar(void)
{
f010061b:	55                   	push   %ebp
f010061c:	89 e5                	mov    %esp,%ebp
f010061e:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100621:	e8 bf fe ff ff       	call   f01004e5 <cons_getc>
f0100626:	85 c0                	test   %eax,%eax
f0100628:	74 f7                	je     f0100621 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010062a:	c9                   	leave  
f010062b:	c3                   	ret    

f010062c <iscons>:

int
iscons(int fdnum)
{
f010062c:	55                   	push   %ebp
f010062d:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010062f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100634:	c9                   	leave  
f0100635:	c3                   	ret    
	...

f0100638 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100638:	55                   	push   %ebp
f0100639:	89 e5                	mov    %esp,%ebp
f010063b:	56                   	push   %esi
f010063c:	53                   	push   %ebx

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010063d:	89 eb                	mov    %ebp,%ebx
	uint32_t* ebp = (uint32_t*) read_ebp();
f010063f:	89 de                	mov    %ebx,%esi
	cprintf("Stack backtrace:\n");
f0100641:	83 ec 0c             	sub    $0xc,%esp
f0100644:	68 30 1c 10 f0       	push   $0xf0101c30
f0100649:	e8 a7 03 00 00       	call   f01009f5 <cprintf>
	while (ebp) {
f010064e:	83 c4 10             	add    $0x10,%esp
f0100651:	85 db                	test   %ebx,%ebx
f0100653:	74 48                	je     f010069d <mon_backtrace+0x65>
		cprintf("ebp %x  eip %x  args", ebp, ebp[1]);
f0100655:	83 ec 04             	sub    $0x4,%esp
f0100658:	ff 76 04             	pushl  0x4(%esi)
f010065b:	56                   	push   %esi
f010065c:	68 42 1c 10 f0       	push   $0xf0101c42
f0100661:	e8 8f 03 00 00       	call   f01009f5 <cprintf>
f0100666:	83 c4 10             	add    $0x10,%esp
		int i;
		for (i = 2; i <= 6; ++i)
f0100669:	bb 02 00 00 00       	mov    $0x2,%ebx
			cprintf(" %08.x", ebp[i]);
f010066e:	83 ec 08             	sub    $0x8,%esp
f0100671:	ff 34 9e             	pushl  (%esi,%ebx,4)
f0100674:	68 57 1c 10 f0       	push   $0xf0101c57
f0100679:	e8 77 03 00 00       	call   f01009f5 <cprintf>
	uint32_t* ebp = (uint32_t*) read_ebp();
	cprintf("Stack backtrace:\n");
	while (ebp) {
		cprintf("ebp %x  eip %x  args", ebp, ebp[1]);
		int i;
		for (i = 2; i <= 6; ++i)
f010067e:	43                   	inc    %ebx
f010067f:	83 c4 10             	add    $0x10,%esp
f0100682:	83 fb 07             	cmp    $0x7,%ebx
f0100685:	75 e7                	jne    f010066e <mon_backtrace+0x36>
			cprintf(" %08.x", ebp[i]);
		cprintf("\n");
f0100687:	83 ec 0c             	sub    $0xc,%esp
f010068a:	68 ee 19 10 f0       	push   $0xf01019ee
f010068f:	e8 61 03 00 00       	call   f01009f5 <cprintf>
		ebp = (uint32_t*) *ebp;
f0100694:	8b 36                	mov    (%esi),%esi
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t* ebp = (uint32_t*) read_ebp();
	cprintf("Stack backtrace:\n");
	while (ebp) {
f0100696:	83 c4 10             	add    $0x10,%esp
f0100699:	85 f6                	test   %esi,%esi
f010069b:	75 b8                	jne    f0100655 <mon_backtrace+0x1d>
			cprintf(" %08.x", ebp[i]);
		cprintf("\n");
		ebp = (uint32_t*) *ebp;
	}
	return 0;
}
f010069d:	b8 00 00 00 00       	mov    $0x0,%eax
f01006a2:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01006a5:	5b                   	pop    %ebx
f01006a6:	5e                   	pop    %esi
f01006a7:	c9                   	leave  
f01006a8:	c3                   	ret    

f01006a9 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006a9:	55                   	push   %ebp
f01006aa:	89 e5                	mov    %esp,%ebp
f01006ac:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006af:	68 5e 1c 10 f0       	push   $0xf0101c5e
f01006b4:	e8 3c 03 00 00       	call   f01009f5 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006b9:	83 c4 08             	add    $0x8,%esp
f01006bc:	68 0c 00 10 00       	push   $0x10000c
f01006c1:	68 28 1d 10 f0       	push   $0xf0101d28
f01006c6:	e8 2a 03 00 00       	call   f01009f5 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006cb:	83 c4 0c             	add    $0xc,%esp
f01006ce:	68 0c 00 10 00       	push   $0x10000c
f01006d3:	68 0c 00 10 f0       	push   $0xf010000c
f01006d8:	68 50 1d 10 f0       	push   $0xf0101d50
f01006dd:	e8 13 03 00 00       	call   f01009f5 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006e2:	83 c4 0c             	add    $0xc,%esp
f01006e5:	68 54 19 10 00       	push   $0x101954
f01006ea:	68 54 19 10 f0       	push   $0xf0101954
f01006ef:	68 74 1d 10 f0       	push   $0xf0101d74
f01006f4:	e8 fc 02 00 00       	call   f01009f5 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006f9:	83 c4 0c             	add    $0xc,%esp
f01006fc:	68 00 83 11 00       	push   $0x118300
f0100701:	68 00 83 11 f0       	push   $0xf0118300
f0100706:	68 98 1d 10 f0       	push   $0xf0101d98
f010070b:	e8 e5 02 00 00       	call   f01009f5 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100710:	83 c4 0c             	add    $0xc,%esp
f0100713:	68 48 89 11 00       	push   $0x118948
f0100718:	68 48 89 11 f0       	push   $0xf0118948
f010071d:	68 bc 1d 10 f0       	push   $0xf0101dbc
f0100722:	e8 ce 02 00 00       	call   f01009f5 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100727:	b8 47 8d 11 f0       	mov    $0xf0118d47,%eax
f010072c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100731:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100734:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100739:	89 c2                	mov    %eax,%edx
f010073b:	85 c0                	test   %eax,%eax
f010073d:	79 06                	jns    f0100745 <mon_kerninfo+0x9c>
f010073f:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100745:	c1 fa 0a             	sar    $0xa,%edx
f0100748:	52                   	push   %edx
f0100749:	68 e0 1d 10 f0       	push   $0xf0101de0
f010074e:	e8 a2 02 00 00       	call   f01009f5 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100753:	b8 00 00 00 00       	mov    $0x0,%eax
f0100758:	c9                   	leave  
f0100759:	c3                   	ret    

f010075a <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010075a:	55                   	push   %ebp
f010075b:	89 e5                	mov    %esp,%ebp
f010075d:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100760:	ff 35 84 1e 10 f0    	pushl  0xf0101e84
f0100766:	ff 35 80 1e 10 f0    	pushl  0xf0101e80
f010076c:	68 77 1c 10 f0       	push   $0xf0101c77
f0100771:	e8 7f 02 00 00       	call   f01009f5 <cprintf>
f0100776:	83 c4 0c             	add    $0xc,%esp
f0100779:	ff 35 90 1e 10 f0    	pushl  0xf0101e90
f010077f:	ff 35 8c 1e 10 f0    	pushl  0xf0101e8c
f0100785:	68 77 1c 10 f0       	push   $0xf0101c77
f010078a:	e8 66 02 00 00       	call   f01009f5 <cprintf>
f010078f:	83 c4 0c             	add    $0xc,%esp
f0100792:	ff 35 9c 1e 10 f0    	pushl  0xf0101e9c
f0100798:	ff 35 98 1e 10 f0    	pushl  0xf0101e98
f010079e:	68 77 1c 10 f0       	push   $0xf0101c77
f01007a3:	e8 4d 02 00 00       	call   f01009f5 <cprintf>
f01007a8:	83 c4 0c             	add    $0xc,%esp
f01007ab:	ff 35 a8 1e 10 f0    	pushl  0xf0101ea8
f01007b1:	ff 35 a4 1e 10 f0    	pushl  0xf0101ea4
f01007b7:	68 77 1c 10 f0       	push   $0xf0101c77
f01007bc:	e8 34 02 00 00       	call   f01009f5 <cprintf>
	return 0;
}
f01007c1:	b8 00 00 00 00       	mov    $0x0,%eax
f01007c6:	c9                   	leave  
f01007c7:	c3                   	ret    

f01007c8 <backtrace>:
	return 0;
}

int
backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007c8:	55                   	push   %ebp
f01007c9:	89 e5                	mov    %esp,%ebp
f01007cb:	57                   	push   %edi
f01007cc:	56                   	push   %esi
f01007cd:	53                   	push   %ebx
f01007ce:	83 ec 38             	sub    $0x38,%esp
f01007d1:	89 eb                	mov    %ebp,%ebx
	uint32_t* ebp = (uint32_t*) read_ebp();
f01007d3:	89 de                	mov    %ebx,%esi
	cprintf("Stack backtrace:\n");
f01007d5:	68 30 1c 10 f0       	push   $0xf0101c30
f01007da:	e8 16 02 00 00       	call   f01009f5 <cprintf>
	while (ebp) {
f01007df:	83 c4 10             	add    $0x10,%esp
f01007e2:	85 db                	test   %ebx,%ebx
f01007e4:	74 73                	je     f0100859 <backtrace+0x91>
		uint32_t eip = ebp[1];
f01007e6:	8b 7e 04             	mov    0x4(%esi),%edi
		cprintf("ebp %x  eip %x  args", ebp, eip);
f01007e9:	83 ec 04             	sub    $0x4,%esp
f01007ec:	57                   	push   %edi
f01007ed:	56                   	push   %esi
f01007ee:	68 42 1c 10 f0       	push   $0xf0101c42
f01007f3:	e8 fd 01 00 00       	call   f01009f5 <cprintf>
f01007f8:	83 c4 10             	add    $0x10,%esp
		int i;
		for (i = 2; i <= 6; ++i)
f01007fb:	bb 02 00 00 00       	mov    $0x2,%ebx
			cprintf(" %08.x", ebp[i]);
f0100800:	83 ec 08             	sub    $0x8,%esp
f0100803:	ff 34 9e             	pushl  (%esi,%ebx,4)
f0100806:	68 57 1c 10 f0       	push   $0xf0101c57
f010080b:	e8 e5 01 00 00       	call   f01009f5 <cprintf>
	cprintf("Stack backtrace:\n");
	while (ebp) {
		uint32_t eip = ebp[1];
		cprintf("ebp %x  eip %x  args", ebp, eip);
		int i;
		for (i = 2; i <= 6; ++i)
f0100810:	43                   	inc    %ebx
f0100811:	83 c4 10             	add    $0x10,%esp
f0100814:	83 fb 07             	cmp    $0x7,%ebx
f0100817:	75 e7                	jne    f0100800 <backtrace+0x38>
			cprintf(" %08.x", ebp[i]);
		cprintf("\n");
f0100819:	83 ec 0c             	sub    $0xc,%esp
f010081c:	68 ee 19 10 f0       	push   $0xf01019ee
f0100821:	e8 cf 01 00 00       	call   f01009f5 <cprintf>
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
f0100826:	83 c4 08             	add    $0x8,%esp
f0100829:	8d 45 d0             	lea    -0x30(%ebp),%eax
f010082c:	50                   	push   %eax
f010082d:	57                   	push   %edi
f010082e:	e8 fe 02 00 00       	call   f0100b31 <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\n", 
f0100833:	83 c4 08             	add    $0x8,%esp
f0100836:	2b 7d e0             	sub    -0x20(%ebp),%edi
f0100839:	57                   	push   %edi
f010083a:	ff 75 d8             	pushl  -0x28(%ebp)
f010083d:	ff 75 dc             	pushl  -0x24(%ebp)
f0100840:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100843:	ff 75 d0             	pushl  -0x30(%ebp)
f0100846:	68 80 1c 10 f0       	push   $0xf0101c80
f010084b:	e8 a5 01 00 00       	call   f01009f5 <cprintf>
			info.eip_file, info.eip_line,
			info.eip_fn_namelen, info.eip_fn_name,
			eip-info.eip_fn_addr);
//         kern/monitor.c:143: monitor+106
		ebp = (uint32_t*) *ebp;
f0100850:	8b 36                	mov    (%esi),%esi
int
backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t* ebp = (uint32_t*) read_ebp();
	cprintf("Stack backtrace:\n");
	while (ebp) {
f0100852:	83 c4 20             	add    $0x20,%esp
f0100855:	85 f6                	test   %esi,%esi
f0100857:	75 8d                	jne    f01007e6 <backtrace+0x1e>
			eip-info.eip_fn_addr);
//         kern/monitor.c:143: monitor+106
		ebp = (uint32_t*) *ebp;
	}
	return 0;
}
f0100859:	b8 00 00 00 00       	mov    $0x0,%eax
f010085e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100861:	5b                   	pop    %ebx
f0100862:	5e                   	pop    %esi
f0100863:	5f                   	pop    %edi
f0100864:	c9                   	leave  
f0100865:	c3                   	ret    

f0100866 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100866:	55                   	push   %ebp
f0100867:	89 e5                	mov    %esp,%ebp
f0100869:	57                   	push   %edi
f010086a:	56                   	push   %esi
f010086b:	53                   	push   %ebx
f010086c:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010086f:	68 0c 1e 10 f0       	push   $0xf0101e0c
f0100874:	e8 7c 01 00 00       	call   f01009f5 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100879:	c7 04 24 30 1e 10 f0 	movl   $0xf0101e30,(%esp)
f0100880:	e8 70 01 00 00       	call   f01009f5 <cprintf>
	cprintf("%m%s\n%m%s\n%m%s\n", 
f0100885:	83 c4 0c             	add    $0xc,%esp
f0100888:	68 91 1c 10 f0       	push   $0xf0101c91
f010088d:	68 00 04 00 00       	push   $0x400
f0100892:	68 95 1c 10 f0       	push   $0xf0101c95
f0100897:	68 00 02 00 00       	push   $0x200
f010089c:	68 9b 1c 10 f0       	push   $0xf0101c9b
f01008a1:	68 00 01 00 00       	push   $0x100
f01008a6:	68 a0 1c 10 f0       	push   $0xf0101ca0
f01008ab:	e8 45 01 00 00       	call   f01009f5 <cprintf>
f01008b0:	83 c4 20             	add    $0x20,%esp
		0x0100, "blue", 0x0200, "green", 0x0400, "red");


	while (1) {
		buf = readline("K> ");
f01008b3:	83 ec 0c             	sub    $0xc,%esp
f01008b6:	68 b0 1c 10 f0       	push   $0xf0101cb0
f01008bb:	e8 ac 09 00 00       	call   f010126c <readline>
f01008c0:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01008c2:	83 c4 10             	add    $0x10,%esp
f01008c5:	85 c0                	test   %eax,%eax
f01008c7:	74 ea                	je     f01008b3 <monitor+0x4d>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008c9:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008d0:	be 00 00 00 00       	mov    $0x0,%esi
f01008d5:	eb 04                	jmp    f01008db <monitor+0x75>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008d7:	c6 03 00             	movb   $0x0,(%ebx)
f01008da:	43                   	inc    %ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008db:	8a 03                	mov    (%ebx),%al
f01008dd:	84 c0                	test   %al,%al
f01008df:	74 64                	je     f0100945 <monitor+0xdf>
f01008e1:	83 ec 08             	sub    $0x8,%esp
f01008e4:	0f be c0             	movsbl %al,%eax
f01008e7:	50                   	push   %eax
f01008e8:	68 b4 1c 10 f0       	push   $0xf0101cb4
f01008ed:	e8 c3 0b 00 00       	call   f01014b5 <strchr>
f01008f2:	83 c4 10             	add    $0x10,%esp
f01008f5:	85 c0                	test   %eax,%eax
f01008f7:	75 de                	jne    f01008d7 <monitor+0x71>
			*buf++ = 0;
		if (*buf == 0)
f01008f9:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008fc:	74 47                	je     f0100945 <monitor+0xdf>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008fe:	83 fe 0f             	cmp    $0xf,%esi
f0100901:	75 14                	jne    f0100917 <monitor+0xb1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100903:	83 ec 08             	sub    $0x8,%esp
f0100906:	6a 10                	push   $0x10
f0100908:	68 b9 1c 10 f0       	push   $0xf0101cb9
f010090d:	e8 e3 00 00 00       	call   f01009f5 <cprintf>
f0100912:	83 c4 10             	add    $0x10,%esp
f0100915:	eb 9c                	jmp    f01008b3 <monitor+0x4d>
			return 0;
		}
		argv[argc++] = buf;
f0100917:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010091b:	46                   	inc    %esi
		while (*buf && !strchr(WHITESPACE, *buf))
f010091c:	8a 03                	mov    (%ebx),%al
f010091e:	84 c0                	test   %al,%al
f0100920:	75 09                	jne    f010092b <monitor+0xc5>
f0100922:	eb b7                	jmp    f01008db <monitor+0x75>
			buf++;
f0100924:	43                   	inc    %ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100925:	8a 03                	mov    (%ebx),%al
f0100927:	84 c0                	test   %al,%al
f0100929:	74 b0                	je     f01008db <monitor+0x75>
f010092b:	83 ec 08             	sub    $0x8,%esp
f010092e:	0f be c0             	movsbl %al,%eax
f0100931:	50                   	push   %eax
f0100932:	68 b4 1c 10 f0       	push   $0xf0101cb4
f0100937:	e8 79 0b 00 00       	call   f01014b5 <strchr>
f010093c:	83 c4 10             	add    $0x10,%esp
f010093f:	85 c0                	test   %eax,%eax
f0100941:	74 e1                	je     f0100924 <monitor+0xbe>
f0100943:	eb 96                	jmp    f01008db <monitor+0x75>
			buf++;
	}
	argv[argc] = 0;
f0100945:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010094c:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010094d:	85 f6                	test   %esi,%esi
f010094f:	0f 84 5e ff ff ff    	je     f01008b3 <monitor+0x4d>
f0100955:	bb 80 1e 10 f0       	mov    $0xf0101e80,%ebx
f010095a:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010095f:	83 ec 08             	sub    $0x8,%esp
f0100962:	ff 33                	pushl  (%ebx)
f0100964:	ff 75 a8             	pushl  -0x58(%ebp)
f0100967:	e8 db 0a 00 00       	call   f0101447 <strcmp>
f010096c:	83 c4 10             	add    $0x10,%esp
f010096f:	85 c0                	test   %eax,%eax
f0100971:	75 20                	jne    f0100993 <monitor+0x12d>
			return commands[i].func(argc, argv, tf);
f0100973:	83 ec 04             	sub    $0x4,%esp
f0100976:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100979:	ff 75 08             	pushl  0x8(%ebp)
f010097c:	8d 45 a8             	lea    -0x58(%ebp),%eax
f010097f:	50                   	push   %eax
f0100980:	56                   	push   %esi
f0100981:	ff 97 88 1e 10 f0    	call   *-0xfefe178(%edi)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100987:	83 c4 10             	add    $0x10,%esp
f010098a:	85 c0                	test   %eax,%eax
f010098c:	78 26                	js     f01009b4 <monitor+0x14e>
f010098e:	e9 20 ff ff ff       	jmp    f01008b3 <monitor+0x4d>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100993:	47                   	inc    %edi
f0100994:	83 c3 0c             	add    $0xc,%ebx
f0100997:	83 ff 04             	cmp    $0x4,%edi
f010099a:	75 c3                	jne    f010095f <monitor+0xf9>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010099c:	83 ec 08             	sub    $0x8,%esp
f010099f:	ff 75 a8             	pushl  -0x58(%ebp)
f01009a2:	68 d6 1c 10 f0       	push   $0xf0101cd6
f01009a7:	e8 49 00 00 00       	call   f01009f5 <cprintf>
f01009ac:	83 c4 10             	add    $0x10,%esp
f01009af:	e9 ff fe ff ff       	jmp    f01008b3 <monitor+0x4d>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01009b4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01009b7:	5b                   	pop    %ebx
f01009b8:	5e                   	pop    %esi
f01009b9:	5f                   	pop    %edi
f01009ba:	c9                   	leave  
f01009bb:	c3                   	ret    

f01009bc <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01009bc:	55                   	push   %ebp
f01009bd:	89 e5                	mov    %esp,%ebp
f01009bf:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01009c2:	ff 75 08             	pushl  0x8(%ebp)
f01009c5:	e8 41 fc ff ff       	call   f010060b <cputchar>
f01009ca:	83 c4 10             	add    $0x10,%esp
	*cnt++;
}
f01009cd:	c9                   	leave  
f01009ce:	c3                   	ret    

f01009cf <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01009cf:	55                   	push   %ebp
f01009d0:	89 e5                	mov    %esp,%ebp
f01009d2:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01009d5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009dc:	ff 75 0c             	pushl  0xc(%ebp)
f01009df:	ff 75 08             	pushl  0x8(%ebp)
f01009e2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009e5:	50                   	push   %eax
f01009e6:	68 bc 09 10 f0       	push   $0xf01009bc
f01009eb:	e8 91 04 00 00       	call   f0100e81 <vprintfmt>
	return cnt;
}
f01009f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009f3:	c9                   	leave  
f01009f4:	c3                   	ret    

f01009f5 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009f5:	55                   	push   %ebp
f01009f6:	89 e5                	mov    %esp,%ebp
f01009f8:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009fb:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009fe:	50                   	push   %eax
f01009ff:	ff 75 08             	pushl  0x8(%ebp)
f0100a02:	e8 c8 ff ff ff       	call   f01009cf <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a07:	c9                   	leave  
f0100a08:	c3                   	ret    
f0100a09:	00 00                	add    %al,(%eax)
	...

f0100a0c <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a0c:	55                   	push   %ebp
f0100a0d:	89 e5                	mov    %esp,%ebp
f0100a0f:	57                   	push   %edi
f0100a10:	56                   	push   %esi
f0100a11:	53                   	push   %ebx
f0100a12:	83 ec 14             	sub    $0x14,%esp
f0100a15:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a18:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a1b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100a1e:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a21:	8b 1a                	mov    (%edx),%ebx
f0100a23:	8b 01                	mov    (%ecx),%eax
f0100a25:	89 45 ec             	mov    %eax,-0x14(%ebp)

	while (l <= r) {
f0100a28:	39 c3                	cmp    %eax,%ebx
f0100a2a:	0f 8f 97 00 00 00    	jg     f0100ac7 <stab_binsearch+0xbb>
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a30:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0100a37:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a3a:	01 d8                	add    %ebx,%eax
f0100a3c:	89 c7                	mov    %eax,%edi
f0100a3e:	c1 ef 1f             	shr    $0x1f,%edi
f0100a41:	01 c7                	add    %eax,%edi
f0100a43:	d1 ff                	sar    %edi

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a45:	39 df                	cmp    %ebx,%edi
f0100a47:	7c 31                	jl     f0100a7a <stab_binsearch+0x6e>
f0100a49:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100a4c:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100a4f:	0f b6 44 82 04       	movzbl 0x4(%edx,%eax,4),%eax
f0100a54:	39 f0                	cmp    %esi,%eax
f0100a56:	0f 84 b3 00 00 00    	je     f0100b0f <stab_binsearch+0x103>
f0100a5c:	8d 44 7f fd          	lea    -0x3(%edi,%edi,2),%eax
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100a60:	8d 54 82 04          	lea    0x4(%edx,%eax,4),%edx
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0100a64:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0100a66:	48                   	dec    %eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a67:	39 d8                	cmp    %ebx,%eax
f0100a69:	7c 0f                	jl     f0100a7a <stab_binsearch+0x6e>
f0100a6b:	0f b6 0a             	movzbl (%edx),%ecx
f0100a6e:	83 ea 0c             	sub    $0xc,%edx
f0100a71:	39 f1                	cmp    %esi,%ecx
f0100a73:	75 f1                	jne    f0100a66 <stab_binsearch+0x5a>
f0100a75:	e9 97 00 00 00       	jmp    f0100b11 <stab_binsearch+0x105>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a7a:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0100a7d:	eb 39                	jmp    f0100ab8 <stab_binsearch+0xac>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a7f:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100a82:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
f0100a84:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a87:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0100a8e:	eb 28                	jmp    f0100ab8 <stab_binsearch+0xac>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a90:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a93:	76 12                	jbe    f0100aa7 <stab_binsearch+0x9b>
			*region_right = m - 1;
f0100a95:	48                   	dec    %eax
f0100a96:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100a99:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100a9c:	89 02                	mov    %eax,(%edx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a9e:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0100aa5:	eb 11                	jmp    f0100ab8 <stab_binsearch+0xac>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100aa7:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100aaa:	89 01                	mov    %eax,(%ecx)
			l = m;
			addr++;
f0100aac:	ff 45 0c             	incl   0xc(%ebp)
f0100aaf:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100ab1:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100ab8:	39 5d ec             	cmp    %ebx,-0x14(%ebp)
f0100abb:	0f 8d 76 ff ff ff    	jge    f0100a37 <stab_binsearch+0x2b>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100ac1:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100ac5:	75 0d                	jne    f0100ad4 <stab_binsearch+0xc8>
		*region_right = *region_left - 1;
f0100ac7:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100aca:	8b 03                	mov    (%ebx),%eax
f0100acc:	48                   	dec    %eax
f0100acd:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100ad0:	89 02                	mov    %eax,(%edx)
f0100ad2:	eb 55                	jmp    f0100b29 <stab_binsearch+0x11d>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ad4:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100ad7:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100ad9:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100adc:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ade:	39 c1                	cmp    %eax,%ecx
f0100ae0:	7d 26                	jge    f0100b08 <stab_binsearch+0xfc>
		     l > *region_left && stabs[l].n_type != type;
f0100ae2:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100ae5:	8b 5d f0             	mov    -0x10(%ebp),%ebx
f0100ae8:	0f b6 54 93 04       	movzbl 0x4(%ebx,%edx,4),%edx
f0100aed:	39 f2                	cmp    %esi,%edx
f0100aef:	74 17                	je     f0100b08 <stab_binsearch+0xfc>
f0100af1:	8d 54 40 fd          	lea    -0x3(%eax,%eax,2),%edx
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100af5:	8d 54 93 04          	lea    0x4(%ebx,%edx,4),%edx
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100af9:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100afa:	39 c1                	cmp    %eax,%ecx
f0100afc:	7d 0a                	jge    f0100b08 <stab_binsearch+0xfc>
		     l > *region_left && stabs[l].n_type != type;
f0100afe:	0f b6 1a             	movzbl (%edx),%ebx
f0100b01:	83 ea 0c             	sub    $0xc,%edx
f0100b04:	39 f3                	cmp    %esi,%ebx
f0100b06:	75 f1                	jne    f0100af9 <stab_binsearch+0xed>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100b08:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100b0b:	89 02                	mov    %eax,(%edx)
f0100b0d:	eb 1a                	jmp    f0100b29 <stab_binsearch+0x11d>
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0100b0f:	89 f8                	mov    %edi,%eax
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100b11:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b14:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0100b17:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100b1b:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100b1e:	0f 82 5b ff ff ff    	jb     f0100a7f <stab_binsearch+0x73>
f0100b24:	e9 67 ff ff ff       	jmp    f0100a90 <stab_binsearch+0x84>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0100b29:	83 c4 14             	add    $0x14,%esp
f0100b2c:	5b                   	pop    %ebx
f0100b2d:	5e                   	pop    %esi
f0100b2e:	5f                   	pop    %edi
f0100b2f:	c9                   	leave  
f0100b30:	c3                   	ret    

f0100b31 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b31:	55                   	push   %ebp
f0100b32:	89 e5                	mov    %esp,%ebp
f0100b34:	57                   	push   %edi
f0100b35:	56                   	push   %esi
f0100b36:	53                   	push   %ebx
f0100b37:	83 ec 3c             	sub    $0x3c,%esp
f0100b3a:	8b 75 08             	mov    0x8(%ebp),%esi
f0100b3d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b40:	c7 03 b0 1e 10 f0    	movl   $0xf0101eb0,(%ebx)
	info->eip_line = 0;
f0100b46:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100b4d:	c7 43 08 b0 1e 10 f0 	movl   $0xf0101eb0,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100b54:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b5b:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b5e:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
	// return 0;
	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b65:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b6b:	76 12                	jbe    f0100b7f <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b6d:	b8 81 db 10 f0       	mov    $0xf010db81,%eax
f0100b72:	3d 29 68 10 f0       	cmp    $0xf0106829,%eax
f0100b77:	0f 86 81 01 00 00    	jbe    f0100cfe <debuginfo_eip+0x1cd>
f0100b7d:	eb 14                	jmp    f0100b93 <debuginfo_eip+0x62>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b7f:	83 ec 04             	sub    $0x4,%esp
f0100b82:	68 ba 1e 10 f0       	push   $0xf0101eba
f0100b87:	6a 7f                	push   $0x7f
f0100b89:	68 c7 1e 10 f0       	push   $0xf0101ec7
f0100b8e:	e8 53 f5 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100b93:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b98:	80 3d 80 db 10 f0 00 	cmpb   $0x0,0xf010db80
f0100b9f:	0f 85 65 01 00 00    	jne    f0100d0a <debuginfo_eip+0x1d9>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100ba5:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100bac:	b8 28 68 10 f0       	mov    $0xf0106828,%eax
f0100bb1:	2d e8 20 10 f0       	sub    $0xf01020e8,%eax
f0100bb6:	c1 f8 02             	sar    $0x2,%eax
f0100bb9:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100bbf:	48                   	dec    %eax
f0100bc0:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100bc3:	83 ec 08             	sub    $0x8,%esp
f0100bc6:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100bc9:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100bcc:	56                   	push   %esi
f0100bcd:	6a 64                	push   $0x64
f0100bcf:	b8 e8 20 10 f0       	mov    $0xf01020e8,%eax
f0100bd4:	e8 33 fe ff ff       	call   f0100a0c <stab_binsearch>
	if (lfile == 0)
f0100bd9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100bdc:	83 c4 10             	add    $0x10,%esp
		return -1;
f0100bdf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0100be4:	85 d2                	test   %edx,%edx
f0100be6:	0f 84 1e 01 00 00    	je     f0100d0a <debuginfo_eip+0x1d9>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100bec:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0100bef:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bf2:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100bf5:	83 ec 08             	sub    $0x8,%esp
f0100bf8:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100bfb:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100bfe:	56                   	push   %esi
f0100bff:	6a 24                	push   $0x24
f0100c01:	b8 e8 20 10 f0       	mov    $0xf01020e8,%eax
f0100c06:	e8 01 fe ff ff       	call   f0100a0c <stab_binsearch>

	if (lfun <= rfun) {
f0100c0b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100c0e:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100c11:	83 c4 10             	add    $0x10,%esp
f0100c14:	39 d0                	cmp    %edx,%eax
f0100c16:	7f 37                	jg     f0100c4f <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100c18:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100c1b:	8b 89 e8 20 10 f0    	mov    -0xfefdf18(%ecx),%ecx
f0100c21:	bf 81 db 10 f0       	mov    $0xf010db81,%edi
f0100c26:	81 ef 29 68 10 f0    	sub    $0xf0106829,%edi
f0100c2c:	39 f9                	cmp    %edi,%ecx
f0100c2e:	73 09                	jae    f0100c39 <debuginfo_eip+0x108>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c30:	81 c1 29 68 10 f0    	add    $0xf0106829,%ecx
f0100c36:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c39:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100c3c:	8b 89 f0 20 10 f0    	mov    -0xfefdf10(%ecx),%ecx
f0100c42:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100c45:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100c47:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100c4a:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100c4d:	eb 0f                	jmp    f0100c5e <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c4f:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c52:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c55:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100c58:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c5b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c5e:	83 ec 08             	sub    $0x8,%esp
f0100c61:	6a 3a                	push   $0x3a
f0100c63:	ff 73 08             	pushl  0x8(%ebx)
f0100c66:	e8 78 08 00 00       	call   f01014e3 <strfind>
f0100c6b:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c6e:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100c71:	83 c4 08             	add    $0x8,%esp
f0100c74:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100c77:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100c7a:	56                   	push   %esi
f0100c7b:	6a 44                	push   $0x44
f0100c7d:	b8 e8 20 10 f0       	mov    $0xf01020e8,%eax
f0100c82:	e8 85 fd ff ff       	call   f0100a0c <stab_binsearch>
	info->eip_line = lline;
f0100c87:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c8a:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c8d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100c90:	89 c2                	mov    %eax,%edx
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100c92:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100c95:	05 f0 20 10 f0       	add    $0xf01020f0,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c9a:	83 c4 10             	add    $0x10,%esp
f0100c9d:	eb 04                	jmp    f0100ca3 <debuginfo_eip+0x172>
f0100c9f:	4a                   	dec    %edx
f0100ca0:	83 e8 0c             	sub    $0xc,%eax
f0100ca3:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f0100ca6:	39 d6                	cmp    %edx,%esi
f0100ca8:	7f 1b                	jg     f0100cc5 <debuginfo_eip+0x194>
	       && stabs[lline].n_type != N_SOL
f0100caa:	8a 48 fc             	mov    -0x4(%eax),%cl
f0100cad:	80 f9 84             	cmp    $0x84,%cl
f0100cb0:	74 60                	je     f0100d12 <debuginfo_eip+0x1e1>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100cb2:	80 f9 64             	cmp    $0x64,%cl
f0100cb5:	75 e8                	jne    f0100c9f <debuginfo_eip+0x16e>
f0100cb7:	83 38 00             	cmpl   $0x0,(%eax)
f0100cba:	74 e3                	je     f0100c9f <debuginfo_eip+0x16e>
f0100cbc:	eb 54                	jmp    f0100d12 <debuginfo_eip+0x1e1>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100cbe:	05 29 68 10 f0       	add    $0xf0106829,%eax
f0100cc3:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cc5:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100cc8:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100ccb:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cd0:	39 ca                	cmp    %ecx,%edx
f0100cd2:	7d 36                	jge    f0100d0a <debuginfo_eip+0x1d9>
		for (lline = lfun + 1;
f0100cd4:	8d 42 01             	lea    0x1(%edx),%eax
f0100cd7:	89 c2                	mov    %eax,%edx
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100cd9:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100cdc:	05 ec 20 10 f0       	add    $0xf01020ec,%eax
f0100ce1:	89 ce                	mov    %ecx,%esi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100ce3:	eb 03                	jmp    f0100ce8 <debuginfo_eip+0x1b7>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100ce5:	ff 43 14             	incl   0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100ce8:	39 f2                	cmp    %esi,%edx
f0100cea:	7d 19                	jge    f0100d05 <debuginfo_eip+0x1d4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100cec:	8a 08                	mov    (%eax),%cl
f0100cee:	42                   	inc    %edx
f0100cef:	83 c0 0c             	add    $0xc,%eax
f0100cf2:	80 f9 a0             	cmp    $0xa0,%cl
f0100cf5:	74 ee                	je     f0100ce5 <debuginfo_eip+0x1b4>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cf7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cfc:	eb 0c                	jmp    f0100d0a <debuginfo_eip+0x1d9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100cfe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d03:	eb 05                	jmp    f0100d0a <debuginfo_eip+0x1d9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d05:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d0a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d0d:	5b                   	pop    %ebx
f0100d0e:	5e                   	pop    %esi
f0100d0f:	5f                   	pop    %edi
f0100d10:	c9                   	leave  
f0100d11:	c3                   	ret    
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100d12:	6b 45 c4 0c          	imul   $0xc,-0x3c(%ebp),%eax
f0100d16:	8b 80 e8 20 10 f0    	mov    -0xfefdf18(%eax),%eax
f0100d1c:	ba 81 db 10 f0       	mov    $0xf010db81,%edx
f0100d21:	81 ea 29 68 10 f0    	sub    $0xf0106829,%edx
f0100d27:	39 d0                	cmp    %edx,%eax
f0100d29:	72 93                	jb     f0100cbe <debuginfo_eip+0x18d>
f0100d2b:	eb 98                	jmp    f0100cc5 <debuginfo_eip+0x194>
f0100d2d:	00 00                	add    %al,(%eax)
	...

f0100d30 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d30:	55                   	push   %ebp
f0100d31:	89 e5                	mov    %esp,%ebp
f0100d33:	57                   	push   %edi
f0100d34:	56                   	push   %esi
f0100d35:	53                   	push   %ebx
f0100d36:	83 ec 2c             	sub    $0x2c,%esp
f0100d39:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d3c:	89 d6                	mov    %edx,%esi
f0100d3e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d41:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100d44:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d47:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100d4a:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d4d:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100d50:	8b 7d 18             	mov    0x18(%ebp),%edi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d53:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100d56:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f0100d5d:	39 55 d4             	cmp    %edx,-0x2c(%ebp)
f0100d60:	72 0c                	jb     f0100d6e <printnum+0x3e>
f0100d62:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100d65:	76 07                	jbe    f0100d6e <printnum+0x3e>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d67:	4b                   	dec    %ebx
f0100d68:	85 db                	test   %ebx,%ebx
f0100d6a:	7f 31                	jg     f0100d9d <printnum+0x6d>
f0100d6c:	eb 3f                	jmp    f0100dad <printnum+0x7d>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d6e:	83 ec 0c             	sub    $0xc,%esp
f0100d71:	57                   	push   %edi
f0100d72:	4b                   	dec    %ebx
f0100d73:	53                   	push   %ebx
f0100d74:	50                   	push   %eax
f0100d75:	83 ec 08             	sub    $0x8,%esp
f0100d78:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100d7b:	ff 75 d0             	pushl  -0x30(%ebp)
f0100d7e:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d81:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d84:	e8 83 09 00 00       	call   f010170c <__udivdi3>
f0100d89:	83 c4 18             	add    $0x18,%esp
f0100d8c:	52                   	push   %edx
f0100d8d:	50                   	push   %eax
f0100d8e:	89 f2                	mov    %esi,%edx
f0100d90:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d93:	e8 98 ff ff ff       	call   f0100d30 <printnum>
f0100d98:	83 c4 20             	add    $0x20,%esp
f0100d9b:	eb 10                	jmp    f0100dad <printnum+0x7d>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d9d:	83 ec 08             	sub    $0x8,%esp
f0100da0:	56                   	push   %esi
f0100da1:	57                   	push   %edi
f0100da2:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100da5:	4b                   	dec    %ebx
f0100da6:	83 c4 10             	add    $0x10,%esp
f0100da9:	85 db                	test   %ebx,%ebx
f0100dab:	7f f0                	jg     f0100d9d <printnum+0x6d>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100dad:	83 ec 08             	sub    $0x8,%esp
f0100db0:	56                   	push   %esi
f0100db1:	83 ec 04             	sub    $0x4,%esp
f0100db4:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100db7:	ff 75 d0             	pushl  -0x30(%ebp)
f0100dba:	ff 75 dc             	pushl  -0x24(%ebp)
f0100dbd:	ff 75 d8             	pushl  -0x28(%ebp)
f0100dc0:	e8 63 0a 00 00       	call   f0101828 <__umoddi3>
f0100dc5:	83 c4 14             	add    $0x14,%esp
f0100dc8:	0f be 80 d5 1e 10 f0 	movsbl -0xfefe12b(%eax),%eax
f0100dcf:	50                   	push   %eax
f0100dd0:	ff 55 e4             	call   *-0x1c(%ebp)
f0100dd3:	83 c4 10             	add    $0x10,%esp
}
f0100dd6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100dd9:	5b                   	pop    %ebx
f0100dda:	5e                   	pop    %esi
f0100ddb:	5f                   	pop    %edi
f0100ddc:	c9                   	leave  
f0100ddd:	c3                   	ret    

f0100dde <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100dde:	55                   	push   %ebp
f0100ddf:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100de1:	83 fa 01             	cmp    $0x1,%edx
f0100de4:	7e 0e                	jle    f0100df4 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100de6:	8b 10                	mov    (%eax),%edx
f0100de8:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100deb:	89 08                	mov    %ecx,(%eax)
f0100ded:	8b 02                	mov    (%edx),%eax
f0100def:	8b 52 04             	mov    0x4(%edx),%edx
f0100df2:	eb 22                	jmp    f0100e16 <getuint+0x38>
	else if (lflag)
f0100df4:	85 d2                	test   %edx,%edx
f0100df6:	74 10                	je     f0100e08 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100df8:	8b 10                	mov    (%eax),%edx
f0100dfa:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100dfd:	89 08                	mov    %ecx,(%eax)
f0100dff:	8b 02                	mov    (%edx),%eax
f0100e01:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e06:	eb 0e                	jmp    f0100e16 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e08:	8b 10                	mov    (%eax),%edx
f0100e0a:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e0d:	89 08                	mov    %ecx,(%eax)
f0100e0f:	8b 02                	mov    (%edx),%eax
f0100e11:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e16:	c9                   	leave  
f0100e17:	c3                   	ret    

f0100e18 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0100e18:	55                   	push   %ebp
f0100e19:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e1b:	83 fa 01             	cmp    $0x1,%edx
f0100e1e:	7e 0e                	jle    f0100e2e <getint+0x16>
		return va_arg(*ap, long long);
f0100e20:	8b 10                	mov    (%eax),%edx
f0100e22:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100e25:	89 08                	mov    %ecx,(%eax)
f0100e27:	8b 02                	mov    (%edx),%eax
f0100e29:	8b 52 04             	mov    0x4(%edx),%edx
f0100e2c:	eb 1a                	jmp    f0100e48 <getint+0x30>
	else if (lflag)
f0100e2e:	85 d2                	test   %edx,%edx
f0100e30:	74 0c                	je     f0100e3e <getint+0x26>
		return va_arg(*ap, long);
f0100e32:	8b 10                	mov    (%eax),%edx
f0100e34:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e37:	89 08                	mov    %ecx,(%eax)
f0100e39:	8b 02                	mov    (%edx),%eax
f0100e3b:	99                   	cltd   
f0100e3c:	eb 0a                	jmp    f0100e48 <getint+0x30>
	else
		return va_arg(*ap, int);
f0100e3e:	8b 10                	mov    (%eax),%edx
f0100e40:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e43:	89 08                	mov    %ecx,(%eax)
f0100e45:	8b 02                	mov    (%edx),%eax
f0100e47:	99                   	cltd   
}
f0100e48:	c9                   	leave  
f0100e49:	c3                   	ret    

f0100e4a <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e4a:	55                   	push   %ebp
f0100e4b:	89 e5                	mov    %esp,%ebp
f0100e4d:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e50:	ff 40 08             	incl   0x8(%eax)
	if (b->buf < b->ebuf)
f0100e53:	8b 10                	mov    (%eax),%edx
f0100e55:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e58:	73 08                	jae    f0100e62 <sprintputch+0x18>
		*b->buf++ = ch;
f0100e5a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100e5d:	88 0a                	mov    %cl,(%edx)
f0100e5f:	42                   	inc    %edx
f0100e60:	89 10                	mov    %edx,(%eax)
}
f0100e62:	c9                   	leave  
f0100e63:	c3                   	ret    

f0100e64 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100e64:	55                   	push   %ebp
f0100e65:	89 e5                	mov    %esp,%ebp
f0100e67:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100e6a:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e6d:	50                   	push   %eax
f0100e6e:	ff 75 10             	pushl  0x10(%ebp)
f0100e71:	ff 75 0c             	pushl  0xc(%ebp)
f0100e74:	ff 75 08             	pushl  0x8(%ebp)
f0100e77:	e8 05 00 00 00       	call   f0100e81 <vprintfmt>
	va_end(ap);
f0100e7c:	83 c4 10             	add    $0x10,%esp
}
f0100e7f:	c9                   	leave  
f0100e80:	c3                   	ret    

f0100e81 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100e81:	55                   	push   %ebp
f0100e82:	89 e5                	mov    %esp,%ebp
f0100e84:	57                   	push   %edi
f0100e85:	56                   	push   %esi
f0100e86:	53                   	push   %ebx
f0100e87:	83 ec 2c             	sub    $0x2c,%esp
f0100e8a:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100e8d:	8b 75 10             	mov    0x10(%ebp),%esi
f0100e90:	eb 21                	jmp    f0100eb3 <vprintfmt+0x32>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0') {
f0100e92:	85 c0                	test   %eax,%eax
f0100e94:	75 12                	jne    f0100ea8 <vprintfmt+0x27>
				csa = 0x0700;
f0100e96:	c7 05 44 89 11 f0 00 	movl   $0x700,0xf0118944
f0100e9d:	07 00 00 
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
f0100ea0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ea3:	5b                   	pop    %ebx
f0100ea4:	5e                   	pop    %esi
f0100ea5:	5f                   	pop    %edi
f0100ea6:	c9                   	leave  
f0100ea7:	c3                   	ret    
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0') {
				csa = 0x0700;
				return;
			}
			putch(ch, putdat);
f0100ea8:	83 ec 08             	sub    $0x8,%esp
f0100eab:	57                   	push   %edi
f0100eac:	50                   	push   %eax
f0100ead:	ff 55 08             	call   *0x8(%ebp)
f0100eb0:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100eb3:	0f b6 06             	movzbl (%esi),%eax
f0100eb6:	46                   	inc    %esi
f0100eb7:	83 f8 25             	cmp    $0x25,%eax
f0100eba:	75 d6                	jne    f0100e92 <vprintfmt+0x11>
f0100ebc:	c6 45 dc 20          	movb   $0x20,-0x24(%ebp)
f0100ec0:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0100ec7:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100ece:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100ed5:	ba 00 00 00 00       	mov    $0x0,%edx
f0100eda:	eb 28                	jmp    f0100f04 <vprintfmt+0x83>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100edc:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100ede:	c6 45 dc 2d          	movb   $0x2d,-0x24(%ebp)
f0100ee2:	eb 20                	jmp    f0100f04 <vprintfmt+0x83>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ee4:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100ee6:	c6 45 dc 30          	movb   $0x30,-0x24(%ebp)
f0100eea:	eb 18                	jmp    f0100f04 <vprintfmt+0x83>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eec:	89 de                	mov    %ebx,%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0100eee:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100ef5:	eb 0d                	jmp    f0100f04 <vprintfmt+0x83>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100ef7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100efa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100efd:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f04:	8a 06                	mov    (%esi),%al
f0100f06:	0f b6 c8             	movzbl %al,%ecx
f0100f09:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100f0c:	83 e8 23             	sub    $0x23,%eax
f0100f0f:	3c 55                	cmp    $0x55,%al
f0100f11:	0f 87 c7 02 00 00    	ja     f01011de <vprintfmt+0x35d>
f0100f17:	0f b6 c0             	movzbl %al,%eax
f0100f1a:	ff 24 85 64 1f 10 f0 	jmp    *-0xfefe09c(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f21:	83 e9 30             	sub    $0x30,%ecx
f0100f24:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
				ch = *fmt;
f0100f27:	0f be 03             	movsbl (%ebx),%eax
				if (ch < '0' || ch > '9')
f0100f2a:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100f2d:	83 f9 09             	cmp    $0x9,%ecx
f0100f30:	77 44                	ja     f0100f76 <vprintfmt+0xf5>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f32:	89 de                	mov    %ebx,%esi
f0100f34:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f37:	46                   	inc    %esi
				precision = precision * 10 + ch - '0';
f0100f38:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100f3b:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0100f3f:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100f42:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0100f45:	83 fb 09             	cmp    $0x9,%ebx
f0100f48:	76 ed                	jbe    f0100f37 <vprintfmt+0xb6>
f0100f4a:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0100f4d:	eb 29                	jmp    f0100f78 <vprintfmt+0xf7>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f4f:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f52:	8d 48 04             	lea    0x4(%eax),%ecx
f0100f55:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100f58:	8b 00                	mov    (%eax),%eax
f0100f5a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f5d:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100f5f:	eb 17                	jmp    f0100f78 <vprintfmt+0xf7>

		case '.':
			if (width < 0)
f0100f61:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100f65:	78 85                	js     f0100eec <vprintfmt+0x6b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f67:	89 de                	mov    %ebx,%esi
f0100f69:	eb 99                	jmp    f0100f04 <vprintfmt+0x83>
f0100f6b:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100f6d:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0100f74:	eb 8e                	jmp    f0100f04 <vprintfmt+0x83>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f76:	89 de                	mov    %ebx,%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100f78:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100f7c:	79 86                	jns    f0100f04 <vprintfmt+0x83>
f0100f7e:	e9 74 ff ff ff       	jmp    f0100ef7 <vprintfmt+0x76>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100f83:	42                   	inc    %edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f84:	89 de                	mov    %ebx,%esi
f0100f86:	e9 79 ff ff ff       	jmp    f0100f04 <vprintfmt+0x83>
f0100f8b:	89 5d d8             	mov    %ebx,-0x28(%ebp)
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100f8e:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f91:	8d 50 04             	lea    0x4(%eax),%edx
f0100f94:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f97:	83 ec 08             	sub    $0x8,%esp
f0100f9a:	57                   	push   %edi
f0100f9b:	ff 30                	pushl  (%eax)
f0100f9d:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100fa0:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fa3:	8b 75 d8             	mov    -0x28(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100fa6:	e9 08 ff ff ff       	jmp    f0100eb3 <vprintfmt+0x32>
f0100fab:	89 5d d8             	mov    %ebx,-0x28(%ebp)

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100fae:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fb1:	8d 50 04             	lea    0x4(%eax),%edx
f0100fb4:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fb7:	8b 00                	mov    (%eax),%eax
f0100fb9:	85 c0                	test   %eax,%eax
f0100fbb:	79 02                	jns    f0100fbf <vprintfmt+0x13e>
f0100fbd:	f7 d8                	neg    %eax
f0100fbf:	89 c2                	mov    %eax,%edx
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100fc1:	83 f8 06             	cmp    $0x6,%eax
f0100fc4:	7f 0b                	jg     f0100fd1 <vprintfmt+0x150>
f0100fc6:	8b 04 85 bc 20 10 f0 	mov    -0xfefdf44(,%eax,4),%eax
f0100fcd:	85 c0                	test   %eax,%eax
f0100fcf:	75 1a                	jne    f0100feb <vprintfmt+0x16a>
				printfmt(putch, putdat, "error %d", err);
f0100fd1:	52                   	push   %edx
f0100fd2:	68 ed 1e 10 f0       	push   $0xf0101eed
f0100fd7:	57                   	push   %edi
f0100fd8:	ff 75 08             	pushl  0x8(%ebp)
f0100fdb:	e8 84 fe ff ff       	call   f0100e64 <printfmt>
f0100fe0:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fe3:	8b 75 d8             	mov    -0x28(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100fe6:	e9 c8 fe ff ff       	jmp    f0100eb3 <vprintfmt+0x32>
			else
				printfmt(putch, putdat, "%s", p);
f0100feb:	50                   	push   %eax
f0100fec:	68 f6 1e 10 f0       	push   $0xf0101ef6
f0100ff1:	57                   	push   %edi
f0100ff2:	ff 75 08             	pushl  0x8(%ebp)
f0100ff5:	e8 6a fe ff ff       	call   f0100e64 <printfmt>
f0100ffa:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ffd:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0101000:	e9 ae fe ff ff       	jmp    f0100eb3 <vprintfmt+0x32>
f0101005:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0101008:	89 de                	mov    %ebx,%esi
f010100a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010100d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101010:	8b 45 14             	mov    0x14(%ebp),%eax
f0101013:	8d 50 04             	lea    0x4(%eax),%edx
f0101016:	89 55 14             	mov    %edx,0x14(%ebp)
f0101019:	8b 00                	mov    (%eax),%eax
f010101b:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010101e:	85 c0                	test   %eax,%eax
f0101020:	75 07                	jne    f0101029 <vprintfmt+0x1a8>
				p = "(null)";
f0101022:	c7 45 d0 e6 1e 10 f0 	movl   $0xf0101ee6,-0x30(%ebp)
			if (width > 0 && padc != '-')
f0101029:	85 db                	test   %ebx,%ebx
f010102b:	7e 42                	jle    f010106f <vprintfmt+0x1ee>
f010102d:	80 7d dc 2d          	cmpb   $0x2d,-0x24(%ebp)
f0101031:	74 3c                	je     f010106f <vprintfmt+0x1ee>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101033:	83 ec 08             	sub    $0x8,%esp
f0101036:	51                   	push   %ecx
f0101037:	ff 75 d0             	pushl  -0x30(%ebp)
f010103a:	e8 1d 03 00 00       	call   f010135c <strnlen>
f010103f:	29 c3                	sub    %eax,%ebx
f0101041:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0101044:	83 c4 10             	add    $0x10,%esp
f0101047:	85 db                	test   %ebx,%ebx
f0101049:	7e 24                	jle    f010106f <vprintfmt+0x1ee>
					putch(padc, putdat);
f010104b:	0f be 5d dc          	movsbl -0x24(%ebp),%ebx
f010104f:	89 75 dc             	mov    %esi,-0x24(%ebp)
f0101052:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101055:	83 ec 08             	sub    $0x8,%esp
f0101058:	57                   	push   %edi
f0101059:	53                   	push   %ebx
f010105a:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010105d:	4e                   	dec    %esi
f010105e:	83 c4 10             	add    $0x10,%esp
f0101061:	85 f6                	test   %esi,%esi
f0101063:	7f f0                	jg     f0101055 <vprintfmt+0x1d4>
f0101065:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0101068:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010106f:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101072:	0f be 02             	movsbl (%edx),%eax
f0101075:	85 c0                	test   %eax,%eax
f0101077:	75 47                	jne    f01010c0 <vprintfmt+0x23f>
f0101079:	eb 37                	jmp    f01010b2 <vprintfmt+0x231>
				if (altflag && (ch < ' ' || ch > '~'))
f010107b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010107f:	74 16                	je     f0101097 <vprintfmt+0x216>
f0101081:	8d 50 e0             	lea    -0x20(%eax),%edx
f0101084:	83 fa 5e             	cmp    $0x5e,%edx
f0101087:	76 0e                	jbe    f0101097 <vprintfmt+0x216>
					putch('?', putdat);
f0101089:	83 ec 08             	sub    $0x8,%esp
f010108c:	57                   	push   %edi
f010108d:	6a 3f                	push   $0x3f
f010108f:	ff 55 08             	call   *0x8(%ebp)
f0101092:	83 c4 10             	add    $0x10,%esp
f0101095:	eb 0b                	jmp    f01010a2 <vprintfmt+0x221>
				else
					putch(ch, putdat);
f0101097:	83 ec 08             	sub    $0x8,%esp
f010109a:	57                   	push   %edi
f010109b:	50                   	push   %eax
f010109c:	ff 55 08             	call   *0x8(%ebp)
f010109f:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010a2:	ff 4d e4             	decl   -0x1c(%ebp)
f01010a5:	0f be 03             	movsbl (%ebx),%eax
f01010a8:	85 c0                	test   %eax,%eax
f01010aa:	74 03                	je     f01010af <vprintfmt+0x22e>
f01010ac:	43                   	inc    %ebx
f01010ad:	eb 1b                	jmp    f01010ca <vprintfmt+0x249>
f01010af:	8b 75 dc             	mov    -0x24(%ebp),%esi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01010b2:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01010b6:	7f 1e                	jg     f01010d6 <vprintfmt+0x255>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010b8:	8b 75 d8             	mov    -0x28(%ebp),%esi
f01010bb:	e9 f3 fd ff ff       	jmp    f0100eb3 <vprintfmt+0x32>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010c0:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f01010c3:	43                   	inc    %ebx
f01010c4:	89 75 dc             	mov    %esi,-0x24(%ebp)
f01010c7:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f01010ca:	85 f6                	test   %esi,%esi
f01010cc:	78 ad                	js     f010107b <vprintfmt+0x1fa>
f01010ce:	4e                   	dec    %esi
f01010cf:	79 aa                	jns    f010107b <vprintfmt+0x1fa>
f01010d1:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01010d4:	eb dc                	jmp    f01010b2 <vprintfmt+0x231>
f01010d6:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01010d9:	83 ec 08             	sub    $0x8,%esp
f01010dc:	57                   	push   %edi
f01010dd:	6a 20                	push   $0x20
f01010df:	ff 55 08             	call   *0x8(%ebp)
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01010e2:	4b                   	dec    %ebx
f01010e3:	83 c4 10             	add    $0x10,%esp
f01010e6:	85 db                	test   %ebx,%ebx
f01010e8:	7f ef                	jg     f01010d9 <vprintfmt+0x258>
f01010ea:	e9 c4 fd ff ff       	jmp    f0100eb3 <vprintfmt+0x32>
f01010ef:	89 5d d8             	mov    %ebx,-0x28(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01010f2:	8d 45 14             	lea    0x14(%ebp),%eax
f01010f5:	e8 1e fd ff ff       	call   f0100e18 <getint>
f01010fa:	89 c3                	mov    %eax,%ebx
f01010fc:	89 d6                	mov    %edx,%esi
			if ((long long) num < 0) {
f01010fe:	85 d2                	test   %edx,%edx
f0101100:	78 0a                	js     f010110c <vprintfmt+0x28b>
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101102:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101107:	e9 81 00 00 00       	jmp    f010118d <vprintfmt+0x30c>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
f010110c:	83 ec 08             	sub    $0x8,%esp
f010110f:	57                   	push   %edi
f0101110:	6a 2d                	push   $0x2d
f0101112:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101115:	89 d8                	mov    %ebx,%eax
f0101117:	89 f2                	mov    %esi,%edx
f0101119:	f7 d8                	neg    %eax
f010111b:	83 d2 00             	adc    $0x0,%edx
f010111e:	f7 da                	neg    %edx
f0101120:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0101123:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101128:	eb 63                	jmp    f010118d <vprintfmt+0x30c>
f010112a:	89 5d d8             	mov    %ebx,-0x28(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010112d:	8d 45 14             	lea    0x14(%ebp),%eax
f0101130:	e8 a9 fc ff ff       	call   f0100dde <getuint>
			base = 10;
f0101135:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f010113a:	eb 51                	jmp    f010118d <vprintfmt+0x30c>
f010113c:	89 5d d8             	mov    %ebx,-0x28(%ebp)

		// (unsigned) octal
		case 'o':
      num = getuint(&ap, lflag);
f010113f:	8d 45 14             	lea    0x14(%ebp),%eax
f0101142:	e8 97 fc ff ff       	call   f0100dde <getuint>
      base = 8;
f0101147:	b9 08 00 00 00       	mov    $0x8,%ecx
      goto number;
f010114c:	eb 3f                	jmp    f010118d <vprintfmt+0x30c>
f010114e:	89 5d d8             	mov    %ebx,-0x28(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
f0101151:	83 ec 08             	sub    $0x8,%esp
f0101154:	57                   	push   %edi
f0101155:	6a 30                	push   $0x30
f0101157:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f010115a:	83 c4 08             	add    $0x8,%esp
f010115d:	57                   	push   %edi
f010115e:	6a 78                	push   $0x78
f0101160:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101163:	8b 45 14             	mov    0x14(%ebp),%eax
f0101166:	8d 50 04             	lea    0x4(%eax),%edx
f0101169:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f010116c:	8b 00                	mov    (%eax),%eax
f010116e:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101173:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101176:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f010117b:	eb 10                	jmp    f010118d <vprintfmt+0x30c>
f010117d:	89 5d d8             	mov    %ebx,-0x28(%ebp)

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101180:	8d 45 14             	lea    0x14(%ebp),%eax
f0101183:	e8 56 fc ff ff       	call   f0100dde <getuint>
			base = 16;
f0101188:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f010118d:	83 ec 0c             	sub    $0xc,%esp
f0101190:	0f be 5d dc          	movsbl -0x24(%ebp),%ebx
f0101194:	53                   	push   %ebx
f0101195:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101198:	51                   	push   %ecx
f0101199:	52                   	push   %edx
f010119a:	50                   	push   %eax
f010119b:	89 fa                	mov    %edi,%edx
f010119d:	8b 45 08             	mov    0x8(%ebp),%eax
f01011a0:	e8 8b fb ff ff       	call   f0100d30 <printnum>
			break;
f01011a5:	83 c4 20             	add    $0x20,%esp
f01011a8:	8b 75 d8             	mov    -0x28(%ebp),%esi
f01011ab:	e9 03 fd ff ff       	jmp    f0100eb3 <vprintfmt+0x32>
f01011b0:	89 5d d8             	mov    %ebx,-0x28(%ebp)

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01011b3:	83 ec 08             	sub    $0x8,%esp
f01011b6:	57                   	push   %edi
f01011b7:	51                   	push   %ecx
f01011b8:	ff 55 08             	call   *0x8(%ebp)
			break;
f01011bb:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011be:	8b 75 d8             	mov    -0x28(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01011c1:	e9 ed fc ff ff       	jmp    f0100eb3 <vprintfmt+0x32>
f01011c6:	89 5d d8             	mov    %ebx,-0x28(%ebp)

		case 'm':
			num = getint(&ap, lflag);
f01011c9:	8d 45 14             	lea    0x14(%ebp),%eax
f01011cc:	e8 47 fc ff ff       	call   f0100e18 <getint>
			csa = num;
f01011d1:	a3 44 89 11 f0       	mov    %eax,0xf0118944
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011d6:	8b 75 d8             	mov    -0x28(%ebp),%esi
			break;

		case 'm':
			num = getint(&ap, lflag);
			csa = num;
			break;
f01011d9:	e9 d5 fc ff ff       	jmp    f0100eb3 <vprintfmt+0x32>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01011de:	83 ec 08             	sub    $0x8,%esp
f01011e1:	57                   	push   %edi
f01011e2:	6a 25                	push   $0x25
f01011e4:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01011e7:	83 c4 10             	add    $0x10,%esp
f01011ea:	eb 02                	jmp    f01011ee <vprintfmt+0x36d>
f01011ec:	89 c6                	mov    %eax,%esi
f01011ee:	8d 46 ff             	lea    -0x1(%esi),%eax
f01011f1:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01011f5:	75 f5                	jne    f01011ec <vprintfmt+0x36b>
f01011f7:	e9 b7 fc ff ff       	jmp    f0100eb3 <vprintfmt+0x32>

f01011fc <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01011fc:	55                   	push   %ebp
f01011fd:	89 e5                	mov    %esp,%ebp
f01011ff:	83 ec 18             	sub    $0x18,%esp
f0101202:	8b 45 08             	mov    0x8(%ebp),%eax
f0101205:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101208:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010120b:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010120f:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101212:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101219:	85 c0                	test   %eax,%eax
f010121b:	74 26                	je     f0101243 <vsnprintf+0x47>
f010121d:	85 d2                	test   %edx,%edx
f010121f:	7e 29                	jle    f010124a <vsnprintf+0x4e>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101221:	ff 75 14             	pushl  0x14(%ebp)
f0101224:	ff 75 10             	pushl  0x10(%ebp)
f0101227:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010122a:	50                   	push   %eax
f010122b:	68 4a 0e 10 f0       	push   $0xf0100e4a
f0101230:	e8 4c fc ff ff       	call   f0100e81 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101235:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101238:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010123b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010123e:	83 c4 10             	add    $0x10,%esp
f0101241:	eb 0c                	jmp    f010124f <vsnprintf+0x53>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101243:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0101248:	eb 05                	jmp    f010124f <vsnprintf+0x53>
f010124a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010124f:	c9                   	leave  
f0101250:	c3                   	ret    

f0101251 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101251:	55                   	push   %ebp
f0101252:	89 e5                	mov    %esp,%ebp
f0101254:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101257:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010125a:	50                   	push   %eax
f010125b:	ff 75 10             	pushl  0x10(%ebp)
f010125e:	ff 75 0c             	pushl  0xc(%ebp)
f0101261:	ff 75 08             	pushl  0x8(%ebp)
f0101264:	e8 93 ff ff ff       	call   f01011fc <vsnprintf>
	va_end(ap);

	return rc;
}
f0101269:	c9                   	leave  
f010126a:	c3                   	ret    
	...

f010126c <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010126c:	55                   	push   %ebp
f010126d:	89 e5                	mov    %esp,%ebp
f010126f:	57                   	push   %edi
f0101270:	56                   	push   %esi
f0101271:	53                   	push   %ebx
f0101272:	83 ec 0c             	sub    $0xc,%esp
f0101275:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101278:	85 c0                	test   %eax,%eax
f010127a:	74 11                	je     f010128d <readline+0x21>
		cprintf("%s", prompt);
f010127c:	83 ec 08             	sub    $0x8,%esp
f010127f:	50                   	push   %eax
f0101280:	68 f6 1e 10 f0       	push   $0xf0101ef6
f0101285:	e8 6b f7 ff ff       	call   f01009f5 <cprintf>
f010128a:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010128d:	83 ec 0c             	sub    $0xc,%esp
f0101290:	6a 00                	push   $0x0
f0101292:	e8 95 f3 ff ff       	call   f010062c <iscons>
f0101297:	89 c7                	mov    %eax,%edi
f0101299:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010129c:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01012a1:	e8 75 f3 ff ff       	call   f010061b <getchar>
f01012a6:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01012a8:	85 c0                	test   %eax,%eax
f01012aa:	79 18                	jns    f01012c4 <readline+0x58>
			cprintf("read error: %e\n", c);
f01012ac:	83 ec 08             	sub    $0x8,%esp
f01012af:	50                   	push   %eax
f01012b0:	68 d8 20 10 f0       	push   $0xf01020d8
f01012b5:	e8 3b f7 ff ff       	call   f01009f5 <cprintf>
			return NULL;
f01012ba:	83 c4 10             	add    $0x10,%esp
f01012bd:	b8 00 00 00 00       	mov    $0x0,%eax
f01012c2:	eb 6f                	jmp    f0101333 <readline+0xc7>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01012c4:	83 f8 08             	cmp    $0x8,%eax
f01012c7:	74 05                	je     f01012ce <readline+0x62>
f01012c9:	83 f8 7f             	cmp    $0x7f,%eax
f01012cc:	75 18                	jne    f01012e6 <readline+0x7a>
f01012ce:	85 f6                	test   %esi,%esi
f01012d0:	7e 14                	jle    f01012e6 <readline+0x7a>
			if (echoing)
f01012d2:	85 ff                	test   %edi,%edi
f01012d4:	74 0d                	je     f01012e3 <readline+0x77>
				cputchar('\b');
f01012d6:	83 ec 0c             	sub    $0xc,%esp
f01012d9:	6a 08                	push   $0x8
f01012db:	e8 2b f3 ff ff       	call   f010060b <cputchar>
f01012e0:	83 c4 10             	add    $0x10,%esp
			i--;
f01012e3:	4e                   	dec    %esi
f01012e4:	eb bb                	jmp    f01012a1 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01012e6:	83 fb 1f             	cmp    $0x1f,%ebx
f01012e9:	7e 21                	jle    f010130c <readline+0xa0>
f01012eb:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01012f1:	7f 19                	jg     f010130c <readline+0xa0>
			if (echoing)
f01012f3:	85 ff                	test   %edi,%edi
f01012f5:	74 0c                	je     f0101303 <readline+0x97>
				cputchar(c);
f01012f7:	83 ec 0c             	sub    $0xc,%esp
f01012fa:	53                   	push   %ebx
f01012fb:	e8 0b f3 ff ff       	call   f010060b <cputchar>
f0101300:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101303:	88 9e 40 85 11 f0    	mov    %bl,-0xfee7ac0(%esi)
f0101309:	46                   	inc    %esi
f010130a:	eb 95                	jmp    f01012a1 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f010130c:	83 fb 0a             	cmp    $0xa,%ebx
f010130f:	74 05                	je     f0101316 <readline+0xaa>
f0101311:	83 fb 0d             	cmp    $0xd,%ebx
f0101314:	75 8b                	jne    f01012a1 <readline+0x35>
			if (echoing)
f0101316:	85 ff                	test   %edi,%edi
f0101318:	74 0d                	je     f0101327 <readline+0xbb>
				cputchar('\n');
f010131a:	83 ec 0c             	sub    $0xc,%esp
f010131d:	6a 0a                	push   $0xa
f010131f:	e8 e7 f2 ff ff       	call   f010060b <cputchar>
f0101324:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101327:	c6 86 40 85 11 f0 00 	movb   $0x0,-0xfee7ac0(%esi)
			return buf;
f010132e:	b8 40 85 11 f0       	mov    $0xf0118540,%eax
		}
	}
}
f0101333:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101336:	5b                   	pop    %ebx
f0101337:	5e                   	pop    %esi
f0101338:	5f                   	pop    %edi
f0101339:	c9                   	leave  
f010133a:	c3                   	ret    
	...

f010133c <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010133c:	55                   	push   %ebp
f010133d:	89 e5                	mov    %esp,%ebp
f010133f:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101342:	80 3a 00             	cmpb   $0x0,(%edx)
f0101345:	74 0e                	je     f0101355 <strlen+0x19>
f0101347:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f010134c:	40                   	inc    %eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010134d:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101351:	75 f9                	jne    f010134c <strlen+0x10>
f0101353:	eb 05                	jmp    f010135a <strlen+0x1e>
f0101355:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f010135a:	c9                   	leave  
f010135b:	c3                   	ret    

f010135c <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010135c:	55                   	push   %ebp
f010135d:	89 e5                	mov    %esp,%ebp
f010135f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101362:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101365:	85 d2                	test   %edx,%edx
f0101367:	74 17                	je     f0101380 <strnlen+0x24>
f0101369:	80 39 00             	cmpb   $0x0,(%ecx)
f010136c:	74 19                	je     f0101387 <strnlen+0x2b>
f010136e:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0101373:	40                   	inc    %eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101374:	39 d0                	cmp    %edx,%eax
f0101376:	74 14                	je     f010138c <strnlen+0x30>
f0101378:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f010137c:	75 f5                	jne    f0101373 <strnlen+0x17>
f010137e:	eb 0c                	jmp    f010138c <strnlen+0x30>
f0101380:	b8 00 00 00 00       	mov    $0x0,%eax
f0101385:	eb 05                	jmp    f010138c <strnlen+0x30>
f0101387:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f010138c:	c9                   	leave  
f010138d:	c3                   	ret    

f010138e <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010138e:	55                   	push   %ebp
f010138f:	89 e5                	mov    %esp,%ebp
f0101391:	53                   	push   %ebx
f0101392:	8b 45 08             	mov    0x8(%ebp),%eax
f0101395:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101398:	ba 00 00 00 00       	mov    $0x0,%edx
f010139d:	8a 0c 13             	mov    (%ebx,%edx,1),%cl
f01013a0:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01013a3:	42                   	inc    %edx
f01013a4:	84 c9                	test   %cl,%cl
f01013a6:	75 f5                	jne    f010139d <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01013a8:	5b                   	pop    %ebx
f01013a9:	c9                   	leave  
f01013aa:	c3                   	ret    

f01013ab <strcat>:

char *
strcat(char *dst, const char *src)
{
f01013ab:	55                   	push   %ebp
f01013ac:	89 e5                	mov    %esp,%ebp
f01013ae:	53                   	push   %ebx
f01013af:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01013b2:	53                   	push   %ebx
f01013b3:	e8 84 ff ff ff       	call   f010133c <strlen>
f01013b8:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01013bb:	ff 75 0c             	pushl  0xc(%ebp)
f01013be:	8d 04 03             	lea    (%ebx,%eax,1),%eax
f01013c1:	50                   	push   %eax
f01013c2:	e8 c7 ff ff ff       	call   f010138e <strcpy>
	return dst;
}
f01013c7:	89 d8                	mov    %ebx,%eax
f01013c9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01013cc:	c9                   	leave  
f01013cd:	c3                   	ret    

f01013ce <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01013ce:	55                   	push   %ebp
f01013cf:	89 e5                	mov    %esp,%ebp
f01013d1:	56                   	push   %esi
f01013d2:	53                   	push   %ebx
f01013d3:	8b 45 08             	mov    0x8(%ebp),%eax
f01013d6:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013d9:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013dc:	85 f6                	test   %esi,%esi
f01013de:	74 15                	je     f01013f5 <strncpy+0x27>
f01013e0:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f01013e5:	8a 1a                	mov    (%edx),%bl
f01013e7:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01013ea:	80 3a 01             	cmpb   $0x1,(%edx)
f01013ed:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013f0:	41                   	inc    %ecx
f01013f1:	39 ce                	cmp    %ecx,%esi
f01013f3:	77 f0                	ja     f01013e5 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01013f5:	5b                   	pop    %ebx
f01013f6:	5e                   	pop    %esi
f01013f7:	c9                   	leave  
f01013f8:	c3                   	ret    

f01013f9 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01013f9:	55                   	push   %ebp
f01013fa:	89 e5                	mov    %esp,%ebp
f01013fc:	57                   	push   %edi
f01013fd:	56                   	push   %esi
f01013fe:	53                   	push   %ebx
f01013ff:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101402:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101405:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101408:	85 f6                	test   %esi,%esi
f010140a:	74 32                	je     f010143e <strlcpy+0x45>
		while (--size > 0 && *src != '\0')
f010140c:	83 fe 01             	cmp    $0x1,%esi
f010140f:	74 22                	je     f0101433 <strlcpy+0x3a>
f0101411:	8a 0b                	mov    (%ebx),%cl
f0101413:	84 c9                	test   %cl,%cl
f0101415:	74 20                	je     f0101437 <strlcpy+0x3e>
f0101417:	89 f8                	mov    %edi,%eax
f0101419:	ba 00 00 00 00       	mov    $0x0,%edx
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f010141e:	83 ee 02             	sub    $0x2,%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101421:	88 08                	mov    %cl,(%eax)
f0101423:	40                   	inc    %eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101424:	39 f2                	cmp    %esi,%edx
f0101426:	74 11                	je     f0101439 <strlcpy+0x40>
f0101428:	8a 4c 13 01          	mov    0x1(%ebx,%edx,1),%cl
f010142c:	42                   	inc    %edx
f010142d:	84 c9                	test   %cl,%cl
f010142f:	75 f0                	jne    f0101421 <strlcpy+0x28>
f0101431:	eb 06                	jmp    f0101439 <strlcpy+0x40>
f0101433:	89 f8                	mov    %edi,%eax
f0101435:	eb 02                	jmp    f0101439 <strlcpy+0x40>
f0101437:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101439:	c6 00 00             	movb   $0x0,(%eax)
f010143c:	eb 02                	jmp    f0101440 <strlcpy+0x47>
strlcpy(char *dst, const char *src, size_t size)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010143e:	89 f8                	mov    %edi,%eax
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
		*dst = '\0';
	}
	return dst - dst_in;
f0101440:	29 f8                	sub    %edi,%eax
}
f0101442:	5b                   	pop    %ebx
f0101443:	5e                   	pop    %esi
f0101444:	5f                   	pop    %edi
f0101445:	c9                   	leave  
f0101446:	c3                   	ret    

f0101447 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101447:	55                   	push   %ebp
f0101448:	89 e5                	mov    %esp,%ebp
f010144a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010144d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101450:	8a 01                	mov    (%ecx),%al
f0101452:	84 c0                	test   %al,%al
f0101454:	74 10                	je     f0101466 <strcmp+0x1f>
f0101456:	3a 02                	cmp    (%edx),%al
f0101458:	75 0c                	jne    f0101466 <strcmp+0x1f>
		p++, q++;
f010145a:	41                   	inc    %ecx
f010145b:	42                   	inc    %edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010145c:	8a 01                	mov    (%ecx),%al
f010145e:	84 c0                	test   %al,%al
f0101460:	74 04                	je     f0101466 <strcmp+0x1f>
f0101462:	3a 02                	cmp    (%edx),%al
f0101464:	74 f4                	je     f010145a <strcmp+0x13>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101466:	0f b6 c0             	movzbl %al,%eax
f0101469:	0f b6 12             	movzbl (%edx),%edx
f010146c:	29 d0                	sub    %edx,%eax
}
f010146e:	c9                   	leave  
f010146f:	c3                   	ret    

f0101470 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101470:	55                   	push   %ebp
f0101471:	89 e5                	mov    %esp,%ebp
f0101473:	53                   	push   %ebx
f0101474:	8b 55 08             	mov    0x8(%ebp),%edx
f0101477:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010147a:	8b 45 10             	mov    0x10(%ebp),%eax
	while (n > 0 && *p && *p == *q)
f010147d:	85 c0                	test   %eax,%eax
f010147f:	74 1b                	je     f010149c <strncmp+0x2c>
f0101481:	8a 1a                	mov    (%edx),%bl
f0101483:	84 db                	test   %bl,%bl
f0101485:	74 24                	je     f01014ab <strncmp+0x3b>
f0101487:	3a 19                	cmp    (%ecx),%bl
f0101489:	75 20                	jne    f01014ab <strncmp+0x3b>
f010148b:	48                   	dec    %eax
f010148c:	74 15                	je     f01014a3 <strncmp+0x33>
		n--, p++, q++;
f010148e:	42                   	inc    %edx
f010148f:	41                   	inc    %ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101490:	8a 1a                	mov    (%edx),%bl
f0101492:	84 db                	test   %bl,%bl
f0101494:	74 15                	je     f01014ab <strncmp+0x3b>
f0101496:	3a 19                	cmp    (%ecx),%bl
f0101498:	74 f1                	je     f010148b <strncmp+0x1b>
f010149a:	eb 0f                	jmp    f01014ab <strncmp+0x3b>
		n--, p++, q++;
	if (n == 0)
		return 0;
f010149c:	b8 00 00 00 00       	mov    $0x0,%eax
f01014a1:	eb 05                	jmp    f01014a8 <strncmp+0x38>
f01014a3:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01014a8:	5b                   	pop    %ebx
f01014a9:	c9                   	leave  
f01014aa:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01014ab:	0f b6 02             	movzbl (%edx),%eax
f01014ae:	0f b6 11             	movzbl (%ecx),%edx
f01014b1:	29 d0                	sub    %edx,%eax
f01014b3:	eb f3                	jmp    f01014a8 <strncmp+0x38>

f01014b5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01014b5:	55                   	push   %ebp
f01014b6:	89 e5                	mov    %esp,%ebp
f01014b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01014bb:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f01014be:	8a 10                	mov    (%eax),%dl
f01014c0:	84 d2                	test   %dl,%dl
f01014c2:	74 18                	je     f01014dc <strchr+0x27>
		if (*s == c)
f01014c4:	38 ca                	cmp    %cl,%dl
f01014c6:	75 06                	jne    f01014ce <strchr+0x19>
f01014c8:	eb 17                	jmp    f01014e1 <strchr+0x2c>
f01014ca:	38 ca                	cmp    %cl,%dl
f01014cc:	74 13                	je     f01014e1 <strchr+0x2c>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01014ce:	40                   	inc    %eax
f01014cf:	8a 10                	mov    (%eax),%dl
f01014d1:	84 d2                	test   %dl,%dl
f01014d3:	75 f5                	jne    f01014ca <strchr+0x15>
		if (*s == c)
			return (char *) s;
	return 0;
f01014d5:	b8 00 00 00 00       	mov    $0x0,%eax
f01014da:	eb 05                	jmp    f01014e1 <strchr+0x2c>
f01014dc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014e1:	c9                   	leave  
f01014e2:	c3                   	ret    

f01014e3 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01014e3:	55                   	push   %ebp
f01014e4:	89 e5                	mov    %esp,%ebp
f01014e6:	8b 45 08             	mov    0x8(%ebp),%eax
f01014e9:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f01014ec:	8a 10                	mov    (%eax),%dl
f01014ee:	84 d2                	test   %dl,%dl
f01014f0:	74 11                	je     f0101503 <strfind+0x20>
		if (*s == c)
f01014f2:	38 ca                	cmp    %cl,%dl
f01014f4:	75 06                	jne    f01014fc <strfind+0x19>
f01014f6:	eb 0b                	jmp    f0101503 <strfind+0x20>
f01014f8:	38 ca                	cmp    %cl,%dl
f01014fa:	74 07                	je     f0101503 <strfind+0x20>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01014fc:	40                   	inc    %eax
f01014fd:	8a 10                	mov    (%eax),%dl
f01014ff:	84 d2                	test   %dl,%dl
f0101501:	75 f5                	jne    f01014f8 <strfind+0x15>
		if (*s == c)
			break;
	return (char *) s;
}
f0101503:	c9                   	leave  
f0101504:	c3                   	ret    

f0101505 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101505:	55                   	push   %ebp
f0101506:	89 e5                	mov    %esp,%ebp
f0101508:	57                   	push   %edi
f0101509:	56                   	push   %esi
f010150a:	53                   	push   %ebx
f010150b:	8b 7d 08             	mov    0x8(%ebp),%edi
f010150e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101511:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101514:	85 c9                	test   %ecx,%ecx
f0101516:	74 30                	je     f0101548 <memset+0x43>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101518:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010151e:	75 25                	jne    f0101545 <memset+0x40>
f0101520:	f6 c1 03             	test   $0x3,%cl
f0101523:	75 20                	jne    f0101545 <memset+0x40>
		c &= 0xFF;
f0101525:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101528:	89 d3                	mov    %edx,%ebx
f010152a:	c1 e3 08             	shl    $0x8,%ebx
f010152d:	89 d6                	mov    %edx,%esi
f010152f:	c1 e6 18             	shl    $0x18,%esi
f0101532:	89 d0                	mov    %edx,%eax
f0101534:	c1 e0 10             	shl    $0x10,%eax
f0101537:	09 f0                	or     %esi,%eax
f0101539:	09 d0                	or     %edx,%eax
f010153b:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010153d:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101540:	fc                   	cld    
f0101541:	f3 ab                	rep stos %eax,%es:(%edi)
f0101543:	eb 03                	jmp    f0101548 <memset+0x43>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101545:	fc                   	cld    
f0101546:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101548:	89 f8                	mov    %edi,%eax
f010154a:	5b                   	pop    %ebx
f010154b:	5e                   	pop    %esi
f010154c:	5f                   	pop    %edi
f010154d:	c9                   	leave  
f010154e:	c3                   	ret    

f010154f <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010154f:	55                   	push   %ebp
f0101550:	89 e5                	mov    %esp,%ebp
f0101552:	57                   	push   %edi
f0101553:	56                   	push   %esi
f0101554:	8b 45 08             	mov    0x8(%ebp),%eax
f0101557:	8b 75 0c             	mov    0xc(%ebp),%esi
f010155a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010155d:	39 c6                	cmp    %eax,%esi
f010155f:	73 34                	jae    f0101595 <memmove+0x46>
f0101561:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101564:	39 d0                	cmp    %edx,%eax
f0101566:	73 2d                	jae    f0101595 <memmove+0x46>
		s += n;
		d += n;
f0101568:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010156b:	f6 c2 03             	test   $0x3,%dl
f010156e:	75 1b                	jne    f010158b <memmove+0x3c>
f0101570:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101576:	75 13                	jne    f010158b <memmove+0x3c>
f0101578:	f6 c1 03             	test   $0x3,%cl
f010157b:	75 0e                	jne    f010158b <memmove+0x3c>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f010157d:	83 ef 04             	sub    $0x4,%edi
f0101580:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101583:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0101586:	fd                   	std    
f0101587:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101589:	eb 07                	jmp    f0101592 <memmove+0x43>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010158b:	4f                   	dec    %edi
f010158c:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010158f:	fd                   	std    
f0101590:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101592:	fc                   	cld    
f0101593:	eb 20                	jmp    f01015b5 <memmove+0x66>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101595:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010159b:	75 13                	jne    f01015b0 <memmove+0x61>
f010159d:	a8 03                	test   $0x3,%al
f010159f:	75 0f                	jne    f01015b0 <memmove+0x61>
f01015a1:	f6 c1 03             	test   $0x3,%cl
f01015a4:	75 0a                	jne    f01015b0 <memmove+0x61>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01015a6:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01015a9:	89 c7                	mov    %eax,%edi
f01015ab:	fc                   	cld    
f01015ac:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015ae:	eb 05                	jmp    f01015b5 <memmove+0x66>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01015b0:	89 c7                	mov    %eax,%edi
f01015b2:	fc                   	cld    
f01015b3:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01015b5:	5e                   	pop    %esi
f01015b6:	5f                   	pop    %edi
f01015b7:	c9                   	leave  
f01015b8:	c3                   	ret    

f01015b9 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01015b9:	55                   	push   %ebp
f01015ba:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01015bc:	ff 75 10             	pushl  0x10(%ebp)
f01015bf:	ff 75 0c             	pushl  0xc(%ebp)
f01015c2:	ff 75 08             	pushl  0x8(%ebp)
f01015c5:	e8 85 ff ff ff       	call   f010154f <memmove>
}
f01015ca:	c9                   	leave  
f01015cb:	c3                   	ret    

f01015cc <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01015cc:	55                   	push   %ebp
f01015cd:	89 e5                	mov    %esp,%ebp
f01015cf:	57                   	push   %edi
f01015d0:	56                   	push   %esi
f01015d1:	53                   	push   %ebx
f01015d2:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01015d5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015d8:	8b 7d 10             	mov    0x10(%ebp),%edi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01015db:	85 ff                	test   %edi,%edi
f01015dd:	74 32                	je     f0101611 <memcmp+0x45>
		if (*s1 != *s2)
f01015df:	8a 03                	mov    (%ebx),%al
f01015e1:	8a 0e                	mov    (%esi),%cl
f01015e3:	38 c8                	cmp    %cl,%al
f01015e5:	74 19                	je     f0101600 <memcmp+0x34>
f01015e7:	eb 0d                	jmp    f01015f6 <memcmp+0x2a>
f01015e9:	8a 44 13 01          	mov    0x1(%ebx,%edx,1),%al
f01015ed:	8a 4c 16 01          	mov    0x1(%esi,%edx,1),%cl
f01015f1:	42                   	inc    %edx
f01015f2:	38 c8                	cmp    %cl,%al
f01015f4:	74 10                	je     f0101606 <memcmp+0x3a>
			return (int) *s1 - (int) *s2;
f01015f6:	0f b6 c0             	movzbl %al,%eax
f01015f9:	0f b6 c9             	movzbl %cl,%ecx
f01015fc:	29 c8                	sub    %ecx,%eax
f01015fe:	eb 16                	jmp    f0101616 <memcmp+0x4a>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101600:	4f                   	dec    %edi
f0101601:	ba 00 00 00 00       	mov    $0x0,%edx
f0101606:	39 fa                	cmp    %edi,%edx
f0101608:	75 df                	jne    f01015e9 <memcmp+0x1d>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010160a:	b8 00 00 00 00       	mov    $0x0,%eax
f010160f:	eb 05                	jmp    f0101616 <memcmp+0x4a>
f0101611:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101616:	5b                   	pop    %ebx
f0101617:	5e                   	pop    %esi
f0101618:	5f                   	pop    %edi
f0101619:	c9                   	leave  
f010161a:	c3                   	ret    

f010161b <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010161b:	55                   	push   %ebp
f010161c:	89 e5                	mov    %esp,%ebp
f010161e:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101621:	89 c2                	mov    %eax,%edx
f0101623:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101626:	39 d0                	cmp    %edx,%eax
f0101628:	73 12                	jae    f010163c <memfind+0x21>
		if (*(const unsigned char *) s == (unsigned char) c)
f010162a:	8a 4d 0c             	mov    0xc(%ebp),%cl
f010162d:	38 08                	cmp    %cl,(%eax)
f010162f:	75 06                	jne    f0101637 <memfind+0x1c>
f0101631:	eb 09                	jmp    f010163c <memfind+0x21>
f0101633:	38 08                	cmp    %cl,(%eax)
f0101635:	74 05                	je     f010163c <memfind+0x21>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101637:	40                   	inc    %eax
f0101638:	39 c2                	cmp    %eax,%edx
f010163a:	77 f7                	ja     f0101633 <memfind+0x18>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010163c:	c9                   	leave  
f010163d:	c3                   	ret    

f010163e <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010163e:	55                   	push   %ebp
f010163f:	89 e5                	mov    %esp,%ebp
f0101641:	57                   	push   %edi
f0101642:	56                   	push   %esi
f0101643:	53                   	push   %ebx
f0101644:	8b 55 08             	mov    0x8(%ebp),%edx
f0101647:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010164a:	eb 01                	jmp    f010164d <strtol+0xf>
		s++;
f010164c:	42                   	inc    %edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010164d:	8a 02                	mov    (%edx),%al
f010164f:	3c 20                	cmp    $0x20,%al
f0101651:	74 f9                	je     f010164c <strtol+0xe>
f0101653:	3c 09                	cmp    $0x9,%al
f0101655:	74 f5                	je     f010164c <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101657:	3c 2b                	cmp    $0x2b,%al
f0101659:	75 08                	jne    f0101663 <strtol+0x25>
		s++;
f010165b:	42                   	inc    %edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010165c:	bf 00 00 00 00       	mov    $0x0,%edi
f0101661:	eb 13                	jmp    f0101676 <strtol+0x38>
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101663:	3c 2d                	cmp    $0x2d,%al
f0101665:	75 0a                	jne    f0101671 <strtol+0x33>
		s++, neg = 1;
f0101667:	8d 52 01             	lea    0x1(%edx),%edx
f010166a:	bf 01 00 00 00       	mov    $0x1,%edi
f010166f:	eb 05                	jmp    f0101676 <strtol+0x38>
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101671:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101676:	85 db                	test   %ebx,%ebx
f0101678:	74 05                	je     f010167f <strtol+0x41>
f010167a:	83 fb 10             	cmp    $0x10,%ebx
f010167d:	75 28                	jne    f01016a7 <strtol+0x69>
f010167f:	8a 02                	mov    (%edx),%al
f0101681:	3c 30                	cmp    $0x30,%al
f0101683:	75 10                	jne    f0101695 <strtol+0x57>
f0101685:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101689:	75 0a                	jne    f0101695 <strtol+0x57>
		s += 2, base = 16;
f010168b:	83 c2 02             	add    $0x2,%edx
f010168e:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101693:	eb 12                	jmp    f01016a7 <strtol+0x69>
	else if (base == 0 && s[0] == '0')
f0101695:	85 db                	test   %ebx,%ebx
f0101697:	75 0e                	jne    f01016a7 <strtol+0x69>
f0101699:	3c 30                	cmp    $0x30,%al
f010169b:	75 05                	jne    f01016a2 <strtol+0x64>
		s++, base = 8;
f010169d:	42                   	inc    %edx
f010169e:	b3 08                	mov    $0x8,%bl
f01016a0:	eb 05                	jmp    f01016a7 <strtol+0x69>
	else if (base == 0)
		base = 10;
f01016a2:	bb 0a 00 00 00       	mov    $0xa,%ebx
f01016a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01016ac:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01016ae:	8a 0a                	mov    (%edx),%cl
f01016b0:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f01016b3:	80 fb 09             	cmp    $0x9,%bl
f01016b6:	77 08                	ja     f01016c0 <strtol+0x82>
			dig = *s - '0';
f01016b8:	0f be c9             	movsbl %cl,%ecx
f01016bb:	83 e9 30             	sub    $0x30,%ecx
f01016be:	eb 1e                	jmp    f01016de <strtol+0xa0>
		else if (*s >= 'a' && *s <= 'z')
f01016c0:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f01016c3:	80 fb 19             	cmp    $0x19,%bl
f01016c6:	77 08                	ja     f01016d0 <strtol+0x92>
			dig = *s - 'a' + 10;
f01016c8:	0f be c9             	movsbl %cl,%ecx
f01016cb:	83 e9 57             	sub    $0x57,%ecx
f01016ce:	eb 0e                	jmp    f01016de <strtol+0xa0>
		else if (*s >= 'A' && *s <= 'Z')
f01016d0:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f01016d3:	80 fb 19             	cmp    $0x19,%bl
f01016d6:	77 13                	ja     f01016eb <strtol+0xad>
			dig = *s - 'A' + 10;
f01016d8:	0f be c9             	movsbl %cl,%ecx
f01016db:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01016de:	39 f1                	cmp    %esi,%ecx
f01016e0:	7d 0d                	jge    f01016ef <strtol+0xb1>
			break;
		s++, val = (val * base) + dig;
f01016e2:	42                   	inc    %edx
f01016e3:	0f af c6             	imul   %esi,%eax
f01016e6:	8d 04 01             	lea    (%ecx,%eax,1),%eax
		// we don't properly detect overflow!
	}
f01016e9:	eb c3                	jmp    f01016ae <strtol+0x70>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f01016eb:	89 c1                	mov    %eax,%ecx
f01016ed:	eb 02                	jmp    f01016f1 <strtol+0xb3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01016ef:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f01016f1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01016f5:	74 05                	je     f01016fc <strtol+0xbe>
		*endptr = (char *) s;
f01016f7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01016fa:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f01016fc:	85 ff                	test   %edi,%edi
f01016fe:	74 04                	je     f0101704 <strtol+0xc6>
f0101700:	89 c8                	mov    %ecx,%eax
f0101702:	f7 d8                	neg    %eax
}
f0101704:	5b                   	pop    %ebx
f0101705:	5e                   	pop    %esi
f0101706:	5f                   	pop    %edi
f0101707:	c9                   	leave  
f0101708:	c3                   	ret    
f0101709:	00 00                	add    %al,(%eax)
	...

f010170c <__udivdi3>:
f010170c:	55                   	push   %ebp
f010170d:	89 e5                	mov    %esp,%ebp
f010170f:	57                   	push   %edi
f0101710:	56                   	push   %esi
f0101711:	83 ec 10             	sub    $0x10,%esp
f0101714:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101717:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010171a:	89 7d f0             	mov    %edi,-0x10(%ebp)
f010171d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101720:	89 4d f4             	mov    %ecx,-0xc(%ebp)
f0101723:	8b 45 14             	mov    0x14(%ebp),%eax
f0101726:	85 c0                	test   %eax,%eax
f0101728:	75 2e                	jne    f0101758 <__udivdi3+0x4c>
f010172a:	39 f1                	cmp    %esi,%ecx
f010172c:	77 5a                	ja     f0101788 <__udivdi3+0x7c>
f010172e:	85 c9                	test   %ecx,%ecx
f0101730:	75 0b                	jne    f010173d <__udivdi3+0x31>
f0101732:	b8 01 00 00 00       	mov    $0x1,%eax
f0101737:	31 d2                	xor    %edx,%edx
f0101739:	f7 f1                	div    %ecx
f010173b:	89 c1                	mov    %eax,%ecx
f010173d:	31 d2                	xor    %edx,%edx
f010173f:	89 f0                	mov    %esi,%eax
f0101741:	f7 f1                	div    %ecx
f0101743:	89 c6                	mov    %eax,%esi
f0101745:	89 f8                	mov    %edi,%eax
f0101747:	f7 f1                	div    %ecx
f0101749:	89 c7                	mov    %eax,%edi
f010174b:	89 f8                	mov    %edi,%eax
f010174d:	89 f2                	mov    %esi,%edx
f010174f:	83 c4 10             	add    $0x10,%esp
f0101752:	5e                   	pop    %esi
f0101753:	5f                   	pop    %edi
f0101754:	c9                   	leave  
f0101755:	c3                   	ret    
f0101756:	66 90                	xchg   %ax,%ax
f0101758:	39 f0                	cmp    %esi,%eax
f010175a:	77 1c                	ja     f0101778 <__udivdi3+0x6c>
f010175c:	0f bd f8             	bsr    %eax,%edi
f010175f:	83 f7 1f             	xor    $0x1f,%edi
f0101762:	75 3c                	jne    f01017a0 <__udivdi3+0x94>
f0101764:	39 f0                	cmp    %esi,%eax
f0101766:	0f 82 90 00 00 00    	jb     f01017fc <__udivdi3+0xf0>
f010176c:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010176f:	39 55 f4             	cmp    %edx,-0xc(%ebp)
f0101772:	0f 86 84 00 00 00    	jbe    f01017fc <__udivdi3+0xf0>
f0101778:	31 f6                	xor    %esi,%esi
f010177a:	31 ff                	xor    %edi,%edi
f010177c:	89 f8                	mov    %edi,%eax
f010177e:	89 f2                	mov    %esi,%edx
f0101780:	83 c4 10             	add    $0x10,%esp
f0101783:	5e                   	pop    %esi
f0101784:	5f                   	pop    %edi
f0101785:	c9                   	leave  
f0101786:	c3                   	ret    
f0101787:	90                   	nop
f0101788:	89 f2                	mov    %esi,%edx
f010178a:	89 f8                	mov    %edi,%eax
f010178c:	f7 f1                	div    %ecx
f010178e:	89 c7                	mov    %eax,%edi
f0101790:	31 f6                	xor    %esi,%esi
f0101792:	89 f8                	mov    %edi,%eax
f0101794:	89 f2                	mov    %esi,%edx
f0101796:	83 c4 10             	add    $0x10,%esp
f0101799:	5e                   	pop    %esi
f010179a:	5f                   	pop    %edi
f010179b:	c9                   	leave  
f010179c:	c3                   	ret    
f010179d:	8d 76 00             	lea    0x0(%esi),%esi
f01017a0:	89 f9                	mov    %edi,%ecx
f01017a2:	d3 e0                	shl    %cl,%eax
f01017a4:	89 45 e8             	mov    %eax,-0x18(%ebp)
f01017a7:	b8 20 00 00 00       	mov    $0x20,%eax
f01017ac:	29 f8                	sub    %edi,%eax
f01017ae:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01017b1:	88 c1                	mov    %al,%cl
f01017b3:	d3 ea                	shr    %cl,%edx
f01017b5:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f01017b8:	09 ca                	or     %ecx,%edx
f01017ba:	89 55 ec             	mov    %edx,-0x14(%ebp)
f01017bd:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01017c0:	89 f9                	mov    %edi,%ecx
f01017c2:	d3 e2                	shl    %cl,%edx
f01017c4:	89 55 f4             	mov    %edx,-0xc(%ebp)
f01017c7:	89 f2                	mov    %esi,%edx
f01017c9:	88 c1                	mov    %al,%cl
f01017cb:	d3 ea                	shr    %cl,%edx
f01017cd:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01017d0:	89 f2                	mov    %esi,%edx
f01017d2:	89 f9                	mov    %edi,%ecx
f01017d4:	d3 e2                	shl    %cl,%edx
f01017d6:	8b 75 f0             	mov    -0x10(%ebp),%esi
f01017d9:	88 c1                	mov    %al,%cl
f01017db:	d3 ee                	shr    %cl,%esi
f01017dd:	09 d6                	or     %edx,%esi
f01017df:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f01017e2:	89 f0                	mov    %esi,%eax
f01017e4:	89 ca                	mov    %ecx,%edx
f01017e6:	f7 75 ec             	divl   -0x14(%ebp)
f01017e9:	89 d1                	mov    %edx,%ecx
f01017eb:	89 c6                	mov    %eax,%esi
f01017ed:	f7 65 f4             	mull   -0xc(%ebp)
f01017f0:	39 d1                	cmp    %edx,%ecx
f01017f2:	72 28                	jb     f010181c <__udivdi3+0x110>
f01017f4:	74 1a                	je     f0101810 <__udivdi3+0x104>
f01017f6:	89 f7                	mov    %esi,%edi
f01017f8:	31 f6                	xor    %esi,%esi
f01017fa:	eb 80                	jmp    f010177c <__udivdi3+0x70>
f01017fc:	31 f6                	xor    %esi,%esi
f01017fe:	bf 01 00 00 00       	mov    $0x1,%edi
f0101803:	89 f8                	mov    %edi,%eax
f0101805:	89 f2                	mov    %esi,%edx
f0101807:	83 c4 10             	add    $0x10,%esp
f010180a:	5e                   	pop    %esi
f010180b:	5f                   	pop    %edi
f010180c:	c9                   	leave  
f010180d:	c3                   	ret    
f010180e:	66 90                	xchg   %ax,%ax
f0101810:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101813:	89 f9                	mov    %edi,%ecx
f0101815:	d3 e2                	shl    %cl,%edx
f0101817:	39 c2                	cmp    %eax,%edx
f0101819:	73 db                	jae    f01017f6 <__udivdi3+0xea>
f010181b:	90                   	nop
f010181c:	8d 7e ff             	lea    -0x1(%esi),%edi
f010181f:	31 f6                	xor    %esi,%esi
f0101821:	e9 56 ff ff ff       	jmp    f010177c <__udivdi3+0x70>
	...

f0101828 <__umoddi3>:
f0101828:	55                   	push   %ebp
f0101829:	89 e5                	mov    %esp,%ebp
f010182b:	57                   	push   %edi
f010182c:	56                   	push   %esi
f010182d:	83 ec 20             	sub    $0x20,%esp
f0101830:	8b 45 08             	mov    0x8(%ebp),%eax
f0101833:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101836:	89 45 e8             	mov    %eax,-0x18(%ebp)
f0101839:	8b 75 0c             	mov    0xc(%ebp),%esi
f010183c:	89 4d f4             	mov    %ecx,-0xc(%ebp)
f010183f:	8b 7d 14             	mov    0x14(%ebp),%edi
f0101842:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101845:	89 f2                	mov    %esi,%edx
f0101847:	85 ff                	test   %edi,%edi
f0101849:	75 15                	jne    f0101860 <__umoddi3+0x38>
f010184b:	39 f1                	cmp    %esi,%ecx
f010184d:	0f 86 99 00 00 00    	jbe    f01018ec <__umoddi3+0xc4>
f0101853:	f7 f1                	div    %ecx
f0101855:	89 d0                	mov    %edx,%eax
f0101857:	31 d2                	xor    %edx,%edx
f0101859:	83 c4 20             	add    $0x20,%esp
f010185c:	5e                   	pop    %esi
f010185d:	5f                   	pop    %edi
f010185e:	c9                   	leave  
f010185f:	c3                   	ret    
f0101860:	39 f7                	cmp    %esi,%edi
f0101862:	0f 87 a4 00 00 00    	ja     f010190c <__umoddi3+0xe4>
f0101868:	0f bd c7             	bsr    %edi,%eax
f010186b:	83 f0 1f             	xor    $0x1f,%eax
f010186e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101871:	0f 84 a1 00 00 00    	je     f0101918 <__umoddi3+0xf0>
f0101877:	89 f8                	mov    %edi,%eax
f0101879:	8a 4d ec             	mov    -0x14(%ebp),%cl
f010187c:	d3 e0                	shl    %cl,%eax
f010187e:	bf 20 00 00 00       	mov    $0x20,%edi
f0101883:	2b 7d ec             	sub    -0x14(%ebp),%edi
f0101886:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101889:	89 f9                	mov    %edi,%ecx
f010188b:	d3 ea                	shr    %cl,%edx
f010188d:	09 c2                	or     %eax,%edx
f010188f:	89 55 f0             	mov    %edx,-0x10(%ebp)
f0101892:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101895:	8a 4d ec             	mov    -0x14(%ebp),%cl
f0101898:	d3 e0                	shl    %cl,%eax
f010189a:	89 45 f4             	mov    %eax,-0xc(%ebp)
f010189d:	89 f2                	mov    %esi,%edx
f010189f:	d3 e2                	shl    %cl,%edx
f01018a1:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01018a4:	d3 e0                	shl    %cl,%eax
f01018a6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01018a9:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01018ac:	89 f9                	mov    %edi,%ecx
f01018ae:	d3 e8                	shr    %cl,%eax
f01018b0:	09 d0                	or     %edx,%eax
f01018b2:	d3 ee                	shr    %cl,%esi
f01018b4:	89 f2                	mov    %esi,%edx
f01018b6:	f7 75 f0             	divl   -0x10(%ebp)
f01018b9:	89 d6                	mov    %edx,%esi
f01018bb:	f7 65 f4             	mull   -0xc(%ebp)
f01018be:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01018c1:	89 c1                	mov    %eax,%ecx
f01018c3:	39 d6                	cmp    %edx,%esi
f01018c5:	72 71                	jb     f0101938 <__umoddi3+0x110>
f01018c7:	74 7f                	je     f0101948 <__umoddi3+0x120>
f01018c9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01018cc:	29 c8                	sub    %ecx,%eax
f01018ce:	19 d6                	sbb    %edx,%esi
f01018d0:	8a 4d ec             	mov    -0x14(%ebp),%cl
f01018d3:	d3 e8                	shr    %cl,%eax
f01018d5:	89 f2                	mov    %esi,%edx
f01018d7:	89 f9                	mov    %edi,%ecx
f01018d9:	d3 e2                	shl    %cl,%edx
f01018db:	09 d0                	or     %edx,%eax
f01018dd:	89 f2                	mov    %esi,%edx
f01018df:	8a 4d ec             	mov    -0x14(%ebp),%cl
f01018e2:	d3 ea                	shr    %cl,%edx
f01018e4:	83 c4 20             	add    $0x20,%esp
f01018e7:	5e                   	pop    %esi
f01018e8:	5f                   	pop    %edi
f01018e9:	c9                   	leave  
f01018ea:	c3                   	ret    
f01018eb:	90                   	nop
f01018ec:	85 c9                	test   %ecx,%ecx
f01018ee:	75 0b                	jne    f01018fb <__umoddi3+0xd3>
f01018f0:	b8 01 00 00 00       	mov    $0x1,%eax
f01018f5:	31 d2                	xor    %edx,%edx
f01018f7:	f7 f1                	div    %ecx
f01018f9:	89 c1                	mov    %eax,%ecx
f01018fb:	89 f0                	mov    %esi,%eax
f01018fd:	31 d2                	xor    %edx,%edx
f01018ff:	f7 f1                	div    %ecx
f0101901:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101904:	f7 f1                	div    %ecx
f0101906:	e9 4a ff ff ff       	jmp    f0101855 <__umoddi3+0x2d>
f010190b:	90                   	nop
f010190c:	89 f2                	mov    %esi,%edx
f010190e:	83 c4 20             	add    $0x20,%esp
f0101911:	5e                   	pop    %esi
f0101912:	5f                   	pop    %edi
f0101913:	c9                   	leave  
f0101914:	c3                   	ret    
f0101915:	8d 76 00             	lea    0x0(%esi),%esi
f0101918:	39 f7                	cmp    %esi,%edi
f010191a:	72 05                	jb     f0101921 <__umoddi3+0xf9>
f010191c:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f010191f:	77 0c                	ja     f010192d <__umoddi3+0x105>
f0101921:	89 f2                	mov    %esi,%edx
f0101923:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101926:	29 c8                	sub    %ecx,%eax
f0101928:	19 fa                	sbb    %edi,%edx
f010192a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010192d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101930:	83 c4 20             	add    $0x20,%esp
f0101933:	5e                   	pop    %esi
f0101934:	5f                   	pop    %edi
f0101935:	c9                   	leave  
f0101936:	c3                   	ret    
f0101937:	90                   	nop
f0101938:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010193b:	89 c1                	mov    %eax,%ecx
f010193d:	2b 4d f4             	sub    -0xc(%ebp),%ecx
f0101940:	1b 55 f0             	sbb    -0x10(%ebp),%edx
f0101943:	eb 84                	jmp    f01018c9 <__umoddi3+0xa1>
f0101945:	8d 76 00             	lea    0x0(%esi),%esi
f0101948:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f010194b:	72 eb                	jb     f0101938 <__umoddi3+0x110>
f010194d:	89 f2                	mov    %esi,%edx
f010194f:	e9 75 ff ff ff       	jmp    f01018c9 <__umoddi3+0xa1>
