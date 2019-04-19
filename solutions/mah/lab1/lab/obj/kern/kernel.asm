
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
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 10 11 00       	mov    $0x111000,%eax
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
f0100034:	bc 00 10 11 f0       	mov    $0xf0111000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

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
f010004b:	68 00 1b 10 f0       	push   $0xf0101b00
f0100050:	e8 21 09 00 00       	call   f0100976 <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 25                	jle    f0100081 <test_backtrace+0x41>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
	else
		mon_backtrace(0, 0, 0);
	cprintf("leaving test_backtrace %d\n", x);
f010006b:	83 ec 08             	sub    $0x8,%esp
f010006e:	53                   	push   %ebx
f010006f:	68 1c 1b 10 f0       	push   $0xf0101b1c
f0100074:	e8 fd 08 00 00       	call   f0100976 <cprintf>
}
f0100079:	83 c4 10             	add    $0x10,%esp
f010007c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010007f:	c9                   	leave  
f0100080:	c3                   	ret    
		mon_backtrace(0, 0, 0);
f0100081:	83 ec 04             	sub    $0x4,%esp
f0100084:	6a 00                	push   $0x0
f0100086:	6a 00                	push   $0x0
f0100088:	6a 00                	push   $0x0
f010008a:	e8 dc 06 00 00       	call   f010076b <mon_backtrace>
f010008f:	83 c4 10             	add    $0x10,%esp
f0100092:	eb d7                	jmp    f010006b <test_backtrace+0x2b>

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
f010009a:	b8 44 39 11 f0       	mov    $0xf0113944,%eax
f010009f:	2d 00 33 11 f0       	sub    $0xf0113300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 33 11 f0       	push   $0xf0113300
f01000ac:	e8 da 15 00 00       	call   f010168b <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 91 04 00 00       	call   f0100547 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 37 1b 10 f0       	push   $0xf0101b37
f01000c3:	e8 ae 08 00 00       	call   f0100976 <cprintf>

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
f01000dc:	e8 25 07 00 00       	call   f0100806 <monitor>
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
f01000ee:	83 3d 40 39 11 f0 00 	cmpl   $0x0,0xf0113940
f01000f5:	74 0f                	je     f0100106 <_panic+0x20>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000f7:	83 ec 0c             	sub    $0xc,%esp
f01000fa:	6a 00                	push   $0x0
f01000fc:	e8 05 07 00 00       	call   f0100806 <monitor>
f0100101:	83 c4 10             	add    $0x10,%esp
f0100104:	eb f1                	jmp    f01000f7 <_panic+0x11>
	panicstr = fmt;
f0100106:	89 35 40 39 11 f0    	mov    %esi,0xf0113940
	__asm __volatile("cli; cld");
f010010c:	fa                   	cli    
f010010d:	fc                   	cld    
	va_start(ap, fmt);
f010010e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100111:	83 ec 04             	sub    $0x4,%esp
f0100114:	ff 75 0c             	pushl  0xc(%ebp)
f0100117:	ff 75 08             	pushl  0x8(%ebp)
f010011a:	68 52 1b 10 f0       	push   $0xf0101b52
f010011f:	e8 52 08 00 00       	call   f0100976 <cprintf>
	vcprintf(fmt, ap);
f0100124:	83 c4 08             	add    $0x8,%esp
f0100127:	53                   	push   %ebx
f0100128:	56                   	push   %esi
f0100129:	e8 22 08 00 00       	call   f0100950 <vcprintf>
	cprintf("\n");
f010012e:	c7 04 24 8e 1b 10 f0 	movl   $0xf0101b8e,(%esp)
f0100135:	e8 3c 08 00 00       	call   f0100976 <cprintf>
f010013a:	83 c4 10             	add    $0x10,%esp
f010013d:	eb b8                	jmp    f01000f7 <_panic+0x11>

f010013f <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013f:	55                   	push   %ebp
f0100140:	89 e5                	mov    %esp,%ebp
f0100142:	53                   	push   %ebx
f0100143:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100146:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100149:	ff 75 0c             	pushl  0xc(%ebp)
f010014c:	ff 75 08             	pushl  0x8(%ebp)
f010014f:	68 6a 1b 10 f0       	push   $0xf0101b6a
f0100154:	e8 1d 08 00 00       	call   f0100976 <cprintf>
	vcprintf(fmt, ap);
f0100159:	83 c4 08             	add    $0x8,%esp
f010015c:	53                   	push   %ebx
f010015d:	ff 75 10             	pushl  0x10(%ebp)
f0100160:	e8 eb 07 00 00       	call   f0100950 <vcprintf>
	cprintf("\n");
f0100165:	c7 04 24 8e 1b 10 f0 	movl   $0xf0101b8e,(%esp)
f010016c:	e8 05 08 00 00       	call   f0100976 <cprintf>
	va_end(ap);
}
f0100171:	83 c4 10             	add    $0x10,%esp
f0100174:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100177:	c9                   	leave  
f0100178:	c3                   	ret    

f0100179 <serial_proc_data>:

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100179:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017e:	ec                   	in     (%dx),%al
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010017f:	a8 01                	test   $0x1,%al
f0100181:	74 0a                	je     f010018d <serial_proc_data+0x14>
f0100183:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100188:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100189:	0f b6 c0             	movzbl %al,%eax
f010018c:	c3                   	ret    
		return -1;
f010018d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f0100192:	c3                   	ret    

f0100193 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100193:	55                   	push   %ebp
f0100194:	89 e5                	mov    %esp,%ebp
f0100196:	53                   	push   %ebx
f0100197:	83 ec 04             	sub    $0x4,%esp
f010019a:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019c:	ff d3                	call   *%ebx
f010019e:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001a1:	74 29                	je     f01001cc <cons_intr+0x39>
		if (c == 0)
f01001a3:	85 c0                	test   %eax,%eax
f01001a5:	74 f5                	je     f010019c <cons_intr+0x9>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a7:	8b 0d 24 35 11 f0    	mov    0xf0113524,%ecx
f01001ad:	8d 51 01             	lea    0x1(%ecx),%edx
f01001b0:	88 81 20 33 11 f0    	mov    %al,-0xfeecce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001b6:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01001bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001c1:	0f 44 d0             	cmove  %eax,%edx
f01001c4:	89 15 24 35 11 f0    	mov    %edx,0xf0113524
f01001ca:	eb d0                	jmp    f010019c <cons_intr+0x9>
	}
}
f01001cc:	83 c4 04             	add    $0x4,%esp
f01001cf:	5b                   	pop    %ebx
f01001d0:	5d                   	pop    %ebp
f01001d1:	c3                   	ret    

f01001d2 <kbd_proc_data>:
{
f01001d2:	55                   	push   %ebp
f01001d3:	89 e5                	mov    %esp,%ebp
f01001d5:	53                   	push   %ebx
f01001d6:	83 ec 04             	sub    $0x4,%esp
f01001d9:	ba 64 00 00 00       	mov    $0x64,%edx
f01001de:	ec                   	in     (%dx),%al
	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001df:	a8 01                	test   $0x1,%al
f01001e1:	0f 84 ea 00 00 00    	je     f01002d1 <kbd_proc_data+0xff>
f01001e7:	ba 60 00 00 00       	mov    $0x60,%edx
f01001ec:	ec                   	in     (%dx),%al
f01001ed:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01001ef:	3c e0                	cmp    $0xe0,%al
f01001f1:	74 61                	je     f0100254 <kbd_proc_data+0x82>
	} else if (data & 0x80) {
f01001f3:	84 c0                	test   %al,%al
f01001f5:	78 70                	js     f0100267 <kbd_proc_data+0x95>
	} else if (shift & E0ESC) {
f01001f7:	8b 0d 00 33 11 f0    	mov    0xf0113300,%ecx
f01001fd:	f6 c1 40             	test   $0x40,%cl
f0100200:	74 0e                	je     f0100210 <kbd_proc_data+0x3e>
		data |= 0x80;
f0100202:	83 c8 80             	or     $0xffffff80,%eax
f0100205:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100207:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020a:	89 0d 00 33 11 f0    	mov    %ecx,0xf0113300
	shift |= shiftcode[data];
f0100210:	0f b6 d2             	movzbl %dl,%edx
f0100213:	0f b6 82 e0 1c 10 f0 	movzbl -0xfefe320(%edx),%eax
f010021a:	0b 05 00 33 11 f0    	or     0xf0113300,%eax
	shift ^= togglecode[data];
f0100220:	0f b6 8a e0 1b 10 f0 	movzbl -0xfefe420(%edx),%ecx
f0100227:	31 c8                	xor    %ecx,%eax
f0100229:	a3 00 33 11 f0       	mov    %eax,0xf0113300
	c = charcode[shift & (CTL | SHIFT)][data];
f010022e:	89 c1                	mov    %eax,%ecx
f0100230:	83 e1 03             	and    $0x3,%ecx
f0100233:	8b 0c 8d c0 1b 10 f0 	mov    -0xfefe440(,%ecx,4),%ecx
f010023a:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010023e:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100241:	a8 08                	test   $0x8,%al
f0100243:	74 61                	je     f01002a6 <kbd_proc_data+0xd4>
		if ('a' <= c && c <= 'z')
f0100245:	89 da                	mov    %ebx,%edx
f0100247:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010024a:	83 f9 19             	cmp    $0x19,%ecx
f010024d:	77 4b                	ja     f010029a <kbd_proc_data+0xc8>
			c += 'A' - 'a';
f010024f:	83 eb 20             	sub    $0x20,%ebx
f0100252:	eb 0c                	jmp    f0100260 <kbd_proc_data+0x8e>
		shift |= E0ESC;
f0100254:	83 0d 00 33 11 f0 40 	orl    $0x40,0xf0113300
		return 0;
f010025b:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0100260:	89 d8                	mov    %ebx,%eax
f0100262:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100265:	c9                   	leave  
f0100266:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f0100267:	8b 0d 00 33 11 f0    	mov    0xf0113300,%ecx
f010026d:	89 cb                	mov    %ecx,%ebx
f010026f:	83 e3 40             	and    $0x40,%ebx
f0100272:	83 e0 7f             	and    $0x7f,%eax
f0100275:	85 db                	test   %ebx,%ebx
f0100277:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010027a:	0f b6 d2             	movzbl %dl,%edx
f010027d:	0f b6 82 e0 1c 10 f0 	movzbl -0xfefe320(%edx),%eax
f0100284:	83 c8 40             	or     $0x40,%eax
f0100287:	0f b6 c0             	movzbl %al,%eax
f010028a:	f7 d0                	not    %eax
f010028c:	21 c8                	and    %ecx,%eax
f010028e:	a3 00 33 11 f0       	mov    %eax,0xf0113300
		return 0;
f0100293:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100298:	eb c6                	jmp    f0100260 <kbd_proc_data+0x8e>
		else if ('A' <= c && c <= 'Z')
f010029a:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010029d:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002a0:	83 fa 1a             	cmp    $0x1a,%edx
f01002a3:	0f 42 d9             	cmovb  %ecx,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002a6:	f7 d0                	not    %eax
f01002a8:	a8 06                	test   $0x6,%al
f01002aa:	75 b4                	jne    f0100260 <kbd_proc_data+0x8e>
f01002ac:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002b2:	75 ac                	jne    f0100260 <kbd_proc_data+0x8e>
		cprintf("Rebooting!\n");
f01002b4:	83 ec 0c             	sub    $0xc,%esp
f01002b7:	68 84 1b 10 f0       	push   $0xf0101b84
f01002bc:	e8 b5 06 00 00       	call   f0100976 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c1:	b8 03 00 00 00       	mov    $0x3,%eax
f01002c6:	ba 92 00 00 00       	mov    $0x92,%edx
f01002cb:	ee                   	out    %al,(%dx)
f01002cc:	83 c4 10             	add    $0x10,%esp
f01002cf:	eb 8f                	jmp    f0100260 <kbd_proc_data+0x8e>
		return -1;
f01002d1:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01002d6:	eb 88                	jmp    f0100260 <kbd_proc_data+0x8e>

f01002d8 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002d8:	55                   	push   %ebp
f01002d9:	89 e5                	mov    %esp,%ebp
f01002db:	57                   	push   %edi
f01002dc:	56                   	push   %esi
f01002dd:	53                   	push   %ebx
f01002de:	83 ec 0c             	sub    $0xc,%esp
f01002e1:	89 c1                	mov    %eax,%ecx
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002e3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01002e8:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002e9:	a8 20                	test   $0x20,%al
f01002eb:	75 27                	jne    f0100314 <cons_putc+0x3c>
	for (i = 0;
f01002ed:	be 00 00 00 00       	mov    $0x0,%esi
f01002f2:	bb 84 00 00 00       	mov    $0x84,%ebx
f01002f7:	bf fd 03 00 00       	mov    $0x3fd,%edi
f01002fc:	89 da                	mov    %ebx,%edx
f01002fe:	ec                   	in     (%dx),%al
f01002ff:	ec                   	in     (%dx),%al
f0100300:	ec                   	in     (%dx),%al
f0100301:	ec                   	in     (%dx),%al
	     i++)
f0100302:	83 c6 01             	add    $0x1,%esi
f0100305:	89 fa                	mov    %edi,%edx
f0100307:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100308:	a8 20                	test   $0x20,%al
f010030a:	75 08                	jne    f0100314 <cons_putc+0x3c>
f010030c:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100312:	7e e8                	jle    f01002fc <cons_putc+0x24>
	outb(COM1 + COM_TX, c);
f0100314:	89 cf                	mov    %ecx,%edi
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100316:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010031b:	89 c8                	mov    %ecx,%eax
f010031d:	ee                   	out    %al,(%dx)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010031e:	ba 79 03 00 00       	mov    $0x379,%edx
f0100323:	ec                   	in     (%dx),%al
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100324:	84 c0                	test   %al,%al
f0100326:	78 25                	js     f010034d <cons_putc+0x75>
f0100328:	be 00 00 00 00       	mov    $0x0,%esi
f010032d:	bb 84 00 00 00       	mov    $0x84,%ebx
f0100332:	89 da                	mov    %ebx,%edx
f0100334:	ec                   	in     (%dx),%al
f0100335:	ec                   	in     (%dx),%al
f0100336:	ec                   	in     (%dx),%al
f0100337:	ec                   	in     (%dx),%al
f0100338:	83 c6 01             	add    $0x1,%esi
f010033b:	ba 79 03 00 00       	mov    $0x379,%edx
f0100340:	ec                   	in     (%dx),%al
f0100341:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100347:	7f 04                	jg     f010034d <cons_putc+0x75>
f0100349:	84 c0                	test   %al,%al
f010034b:	79 e5                	jns    f0100332 <cons_putc+0x5a>
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034d:	ba 78 03 00 00       	mov    $0x378,%edx
f0100352:	89 f8                	mov    %edi,%eax
f0100354:	ee                   	out    %al,(%dx)
f0100355:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010035a:	b8 0d 00 00 00       	mov    $0xd,%eax
f010035f:	ee                   	out    %al,(%dx)
f0100360:	b8 08 00 00 00       	mov    $0x8,%eax
f0100365:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100366:	89 ca                	mov    %ecx,%edx
f0100368:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010036e:	89 c8                	mov    %ecx,%eax
f0100370:	80 cc 07             	or     $0x7,%ah
f0100373:	85 d2                	test   %edx,%edx
f0100375:	0f 44 c8             	cmove  %eax,%ecx
	switch (c & 0xff) {
f0100378:	0f b6 c1             	movzbl %cl,%eax
f010037b:	83 f8 09             	cmp    $0x9,%eax
f010037e:	0f 84 b0 00 00 00    	je     f0100434 <cons_putc+0x15c>
f0100384:	7e 73                	jle    f01003f9 <cons_putc+0x121>
f0100386:	83 f8 0a             	cmp    $0xa,%eax
f0100389:	0f 84 98 00 00 00    	je     f0100427 <cons_putc+0x14f>
f010038f:	83 f8 0d             	cmp    $0xd,%eax
f0100392:	0f 85 d3 00 00 00    	jne    f010046b <cons_putc+0x193>
		crt_pos -= (crt_pos % CRT_COLS);
f0100398:	0f b7 05 28 35 11 f0 	movzwl 0xf0113528,%eax
f010039f:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003a5:	c1 e8 16             	shr    $0x16,%eax
f01003a8:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003ab:	c1 e0 04             	shl    $0x4,%eax
f01003ae:	66 a3 28 35 11 f0    	mov    %ax,0xf0113528
	if (crt_pos >= CRT_SIZE) {
f01003b4:	66 81 3d 28 35 11 f0 	cmpw   $0x7cf,0xf0113528
f01003bb:	cf 07 
f01003bd:	0f 87 cb 00 00 00    	ja     f010048e <cons_putc+0x1b6>
	outb(addr_6845, 14);
f01003c3:	8b 0d 30 35 11 f0    	mov    0xf0113530,%ecx
f01003c9:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003ce:	89 ca                	mov    %ecx,%edx
f01003d0:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003d1:	0f b7 1d 28 35 11 f0 	movzwl 0xf0113528,%ebx
f01003d8:	8d 71 01             	lea    0x1(%ecx),%esi
f01003db:	89 d8                	mov    %ebx,%eax
f01003dd:	66 c1 e8 08          	shr    $0x8,%ax
f01003e1:	89 f2                	mov    %esi,%edx
f01003e3:	ee                   	out    %al,(%dx)
f01003e4:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003e9:	89 ca                	mov    %ecx,%edx
f01003eb:	ee                   	out    %al,(%dx)
f01003ec:	89 d8                	mov    %ebx,%eax
f01003ee:	89 f2                	mov    %esi,%edx
f01003f0:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003f1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01003f4:	5b                   	pop    %ebx
f01003f5:	5e                   	pop    %esi
f01003f6:	5f                   	pop    %edi
f01003f7:	5d                   	pop    %ebp
f01003f8:	c3                   	ret    
	switch (c & 0xff) {
f01003f9:	83 f8 08             	cmp    $0x8,%eax
f01003fc:	75 6d                	jne    f010046b <cons_putc+0x193>
		if (crt_pos > 0) {
f01003fe:	0f b7 05 28 35 11 f0 	movzwl 0xf0113528,%eax
f0100405:	66 85 c0             	test   %ax,%ax
f0100408:	74 b9                	je     f01003c3 <cons_putc+0xeb>
			crt_pos--;
f010040a:	83 e8 01             	sub    $0x1,%eax
f010040d:	66 a3 28 35 11 f0    	mov    %ax,0xf0113528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100413:	0f b7 c0             	movzwl %ax,%eax
f0100416:	b1 00                	mov    $0x0,%cl
f0100418:	83 c9 20             	or     $0x20,%ecx
f010041b:	8b 15 2c 35 11 f0    	mov    0xf011352c,%edx
f0100421:	66 89 0c 42          	mov    %cx,(%edx,%eax,2)
f0100425:	eb 8d                	jmp    f01003b4 <cons_putc+0xdc>
		crt_pos += CRT_COLS;
f0100427:	66 83 05 28 35 11 f0 	addw   $0x50,0xf0113528
f010042e:	50 
f010042f:	e9 64 ff ff ff       	jmp    f0100398 <cons_putc+0xc0>
		cons_putc(' ');
f0100434:	b8 20 00 00 00       	mov    $0x20,%eax
f0100439:	e8 9a fe ff ff       	call   f01002d8 <cons_putc>
		cons_putc(' ');
f010043e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100443:	e8 90 fe ff ff       	call   f01002d8 <cons_putc>
		cons_putc(' ');
f0100448:	b8 20 00 00 00       	mov    $0x20,%eax
f010044d:	e8 86 fe ff ff       	call   f01002d8 <cons_putc>
		cons_putc(' ');
f0100452:	b8 20 00 00 00       	mov    $0x20,%eax
f0100457:	e8 7c fe ff ff       	call   f01002d8 <cons_putc>
		cons_putc(' ');
f010045c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100461:	e8 72 fe ff ff       	call   f01002d8 <cons_putc>
f0100466:	e9 49 ff ff ff       	jmp    f01003b4 <cons_putc+0xdc>
		crt_buf[crt_pos++] = c;		/* write the character */
f010046b:	0f b7 05 28 35 11 f0 	movzwl 0xf0113528,%eax
f0100472:	8d 50 01             	lea    0x1(%eax),%edx
f0100475:	66 89 15 28 35 11 f0 	mov    %dx,0xf0113528
f010047c:	0f b7 c0             	movzwl %ax,%eax
f010047f:	8b 15 2c 35 11 f0    	mov    0xf011352c,%edx
f0100485:	66 89 0c 42          	mov    %cx,(%edx,%eax,2)
f0100489:	e9 26 ff ff ff       	jmp    f01003b4 <cons_putc+0xdc>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010048e:	a1 2c 35 11 f0       	mov    0xf011352c,%eax
f0100493:	83 ec 04             	sub    $0x4,%esp
f0100496:	68 00 0f 00 00       	push   $0xf00
f010049b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004a1:	52                   	push   %edx
f01004a2:	50                   	push   %eax
f01004a3:	e8 2b 12 00 00       	call   f01016d3 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004a8:	8b 15 2c 35 11 f0    	mov    0xf011352c,%edx
f01004ae:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004b4:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004ba:	83 c4 10             	add    $0x10,%esp
f01004bd:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004c2:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004c5:	39 d0                	cmp    %edx,%eax
f01004c7:	75 f4                	jne    f01004bd <cons_putc+0x1e5>
		crt_pos -= CRT_COLS;
f01004c9:	66 83 2d 28 35 11 f0 	subw   $0x50,0xf0113528
f01004d0:	50 
f01004d1:	e9 ed fe ff ff       	jmp    f01003c3 <cons_putc+0xeb>

f01004d6 <serial_intr>:
	if (serial_exists)
f01004d6:	80 3d 34 35 11 f0 00 	cmpb   $0x0,0xf0113534
f01004dd:	75 01                	jne    f01004e0 <serial_intr+0xa>
f01004df:	c3                   	ret    
{
f01004e0:	55                   	push   %ebp
f01004e1:	89 e5                	mov    %esp,%ebp
f01004e3:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f01004e6:	b8 79 01 10 f0       	mov    $0xf0100179,%eax
f01004eb:	e8 a3 fc ff ff       	call   f0100193 <cons_intr>
}
f01004f0:	c9                   	leave  
f01004f1:	c3                   	ret    

f01004f2 <kbd_intr>:
{
f01004f2:	55                   	push   %ebp
f01004f3:	89 e5                	mov    %esp,%ebp
f01004f5:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004f8:	b8 d2 01 10 f0       	mov    $0xf01001d2,%eax
f01004fd:	e8 91 fc ff ff       	call   f0100193 <cons_intr>
}
f0100502:	c9                   	leave  
f0100503:	c3                   	ret    

f0100504 <cons_getc>:
{
f0100504:	55                   	push   %ebp
f0100505:	89 e5                	mov    %esp,%ebp
f0100507:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f010050a:	e8 c7 ff ff ff       	call   f01004d6 <serial_intr>
	kbd_intr();
f010050f:	e8 de ff ff ff       	call   f01004f2 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100514:	8b 15 20 35 11 f0    	mov    0xf0113520,%edx
	return 0;
f010051a:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f010051f:	3b 15 24 35 11 f0    	cmp    0xf0113524,%edx
f0100525:	74 1e                	je     f0100545 <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f0100527:	8d 4a 01             	lea    0x1(%edx),%ecx
f010052a:	0f b6 82 20 33 11 f0 	movzbl -0xfeecce0(%edx),%eax
			cons.rpos = 0;
f0100531:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100537:	ba 00 00 00 00       	mov    $0x0,%edx
f010053c:	0f 44 ca             	cmove  %edx,%ecx
f010053f:	89 0d 20 35 11 f0    	mov    %ecx,0xf0113520
}
f0100545:	c9                   	leave  
f0100546:	c3                   	ret    

f0100547 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f0100547:	55                   	push   %ebp
f0100548:	89 e5                	mov    %esp,%ebp
f010054a:	57                   	push   %edi
f010054b:	56                   	push   %esi
f010054c:	53                   	push   %ebx
f010054d:	83 ec 0c             	sub    $0xc,%esp
	was = *cp;
f0100550:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100557:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010055e:	5a a5 
	if (*cp != 0xA55A) {
f0100560:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100567:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010056b:	0f 84 b7 00 00 00    	je     f0100628 <cons_init+0xe1>
		addr_6845 = MONO_BASE;
f0100571:	c7 05 30 35 11 f0 b4 	movl   $0x3b4,0xf0113530
f0100578:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010057b:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
	outb(addr_6845, 14);
f0100580:	8b 3d 30 35 11 f0    	mov    0xf0113530,%edi
f0100586:	b8 0e 00 00 00       	mov    $0xe,%eax
f010058b:	89 fa                	mov    %edi,%edx
f010058d:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010058e:	8d 4f 01             	lea    0x1(%edi),%ecx
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100591:	89 ca                	mov    %ecx,%edx
f0100593:	ec                   	in     (%dx),%al
f0100594:	0f b6 c0             	movzbl %al,%eax
f0100597:	c1 e0 08             	shl    $0x8,%eax
f010059a:	89 c3                	mov    %eax,%ebx
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010059c:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005a1:	89 fa                	mov    %edi,%edx
f01005a3:	ee                   	out    %al,(%dx)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005a4:	89 ca                	mov    %ecx,%edx
f01005a6:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f01005a7:	89 35 2c 35 11 f0    	mov    %esi,0xf011352c
	pos |= inb(addr_6845 + 1);
f01005ad:	0f b6 c0             	movzbl %al,%eax
f01005b0:	09 d8                	or     %ebx,%eax
	crt_pos = pos;
f01005b2:	66 a3 28 35 11 f0    	mov    %ax,0xf0113528
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005b8:	bb 00 00 00 00       	mov    $0x0,%ebx
f01005bd:	b9 fa 03 00 00       	mov    $0x3fa,%ecx
f01005c2:	89 d8                	mov    %ebx,%eax
f01005c4:	89 ca                	mov    %ecx,%edx
f01005c6:	ee                   	out    %al,(%dx)
f01005c7:	bf fb 03 00 00       	mov    $0x3fb,%edi
f01005cc:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005d1:	89 fa                	mov    %edi,%edx
f01005d3:	ee                   	out    %al,(%dx)
f01005d4:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005d9:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01005de:	ee                   	out    %al,(%dx)
f01005df:	be f9 03 00 00       	mov    $0x3f9,%esi
f01005e4:	89 d8                	mov    %ebx,%eax
f01005e6:	89 f2                	mov    %esi,%edx
f01005e8:	ee                   	out    %al,(%dx)
f01005e9:	b8 03 00 00 00       	mov    $0x3,%eax
f01005ee:	89 fa                	mov    %edi,%edx
f01005f0:	ee                   	out    %al,(%dx)
f01005f1:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005f6:	89 d8                	mov    %ebx,%eax
f01005f8:	ee                   	out    %al,(%dx)
f01005f9:	b8 01 00 00 00       	mov    $0x1,%eax
f01005fe:	89 f2                	mov    %esi,%edx
f0100600:	ee                   	out    %al,(%dx)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100601:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100606:	ec                   	in     (%dx),%al
f0100607:	89 c3                	mov    %eax,%ebx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100609:	3c ff                	cmp    $0xff,%al
f010060b:	0f 95 05 34 35 11 f0 	setne  0xf0113534
f0100612:	89 ca                	mov    %ecx,%edx
f0100614:	ec                   	in     (%dx),%al
f0100615:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010061a:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010061b:	80 fb ff             	cmp    $0xff,%bl
f010061e:	74 23                	je     f0100643 <cons_init+0xfc>
		cprintf("Serial port does not exist!\n");
}
f0100620:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100623:	5b                   	pop    %ebx
f0100624:	5e                   	pop    %esi
f0100625:	5f                   	pop    %edi
f0100626:	5d                   	pop    %ebp
f0100627:	c3                   	ret    
		*cp = was;
f0100628:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010062f:	c7 05 30 35 11 f0 d4 	movl   $0x3d4,0xf0113530
f0100636:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100639:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
f010063e:	e9 3d ff ff ff       	jmp    f0100580 <cons_init+0x39>
		cprintf("Serial port does not exist!\n");
f0100643:	83 ec 0c             	sub    $0xc,%esp
f0100646:	68 90 1b 10 f0       	push   $0xf0101b90
f010064b:	e8 26 03 00 00       	call   f0100976 <cprintf>
f0100650:	83 c4 10             	add    $0x10,%esp
}
f0100653:	eb cb                	jmp    f0100620 <cons_init+0xd9>

f0100655 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100655:	55                   	push   %ebp
f0100656:	89 e5                	mov    %esp,%ebp
f0100658:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010065b:	8b 45 08             	mov    0x8(%ebp),%eax
f010065e:	e8 75 fc ff ff       	call   f01002d8 <cons_putc>
}
f0100663:	c9                   	leave  
f0100664:	c3                   	ret    

f0100665 <getchar>:

int
getchar(void)
{
f0100665:	55                   	push   %ebp
f0100666:	89 e5                	mov    %esp,%ebp
f0100668:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010066b:	e8 94 fe ff ff       	call   f0100504 <cons_getc>
f0100670:	85 c0                	test   %eax,%eax
f0100672:	74 f7                	je     f010066b <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100674:	c9                   	leave  
f0100675:	c3                   	ret    

f0100676 <iscons>:
int
iscons(int fdnum)
{
	// used by readline
	return 1;
}
f0100676:	b8 01 00 00 00       	mov    $0x1,%eax
f010067b:	c3                   	ret    

f010067c <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010067c:	55                   	push   %ebp
f010067d:	89 e5                	mov    %esp,%ebp
f010067f:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100682:	68 e0 1d 10 f0       	push   $0xf0101de0
f0100687:	68 fe 1d 10 f0       	push   $0xf0101dfe
f010068c:	68 03 1e 10 f0       	push   $0xf0101e03
f0100691:	e8 e0 02 00 00       	call   f0100976 <cprintf>
f0100696:	83 c4 0c             	add    $0xc,%esp
f0100699:	68 b0 1e 10 f0       	push   $0xf0101eb0
f010069e:	68 0c 1e 10 f0       	push   $0xf0101e0c
f01006a3:	68 03 1e 10 f0       	push   $0xf0101e03
f01006a8:	e8 c9 02 00 00       	call   f0100976 <cprintf>
f01006ad:	83 c4 0c             	add    $0xc,%esp
f01006b0:	68 d8 1e 10 f0       	push   $0xf0101ed8
f01006b5:	68 15 1e 10 f0       	push   $0xf0101e15
f01006ba:	68 03 1e 10 f0       	push   $0xf0101e03
f01006bf:	e8 b2 02 00 00       	call   f0100976 <cprintf>
	return 0;
}
f01006c4:	b8 00 00 00 00       	mov    $0x0,%eax
f01006c9:	c9                   	leave  
f01006ca:	c3                   	ret    

f01006cb <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006cb:	55                   	push   %ebp
f01006cc:	89 e5                	mov    %esp,%ebp
f01006ce:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006d1:	68 1f 1e 10 f0       	push   $0xf0101e1f
f01006d6:	e8 9b 02 00 00       	call   f0100976 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006db:	83 c4 08             	add    $0x8,%esp
f01006de:	68 0c 00 10 00       	push   $0x10000c
f01006e3:	68 f8 1e 10 f0       	push   $0xf0101ef8
f01006e8:	e8 89 02 00 00       	call   f0100976 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006ed:	83 c4 0c             	add    $0xc,%esp
f01006f0:	68 0c 00 10 00       	push   $0x10000c
f01006f5:	68 0c 00 10 f0       	push   $0xf010000c
f01006fa:	68 20 1f 10 f0       	push   $0xf0101f20
f01006ff:	e8 72 02 00 00       	call   f0100976 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100704:	83 c4 0c             	add    $0xc,%esp
f0100707:	68 ff 1a 10 00       	push   $0x101aff
f010070c:	68 ff 1a 10 f0       	push   $0xf0101aff
f0100711:	68 44 1f 10 f0       	push   $0xf0101f44
f0100716:	e8 5b 02 00 00       	call   f0100976 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010071b:	83 c4 0c             	add    $0xc,%esp
f010071e:	68 00 33 11 00       	push   $0x113300
f0100723:	68 00 33 11 f0       	push   $0xf0113300
f0100728:	68 68 1f 10 f0       	push   $0xf0101f68
f010072d:	e8 44 02 00 00       	call   f0100976 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100732:	83 c4 0c             	add    $0xc,%esp
f0100735:	68 44 39 11 00       	push   $0x113944
f010073a:	68 44 39 11 f0       	push   $0xf0113944
f010073f:	68 8c 1f 10 f0       	push   $0xf0101f8c
f0100744:	e8 2d 02 00 00       	call   f0100976 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100749:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010074c:	b8 44 39 11 f0       	mov    $0xf0113944,%eax
f0100751:	2d 0d fc 0f f0       	sub    $0xf00ffc0d,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100756:	c1 f8 0a             	sar    $0xa,%eax
f0100759:	50                   	push   %eax
f010075a:	68 b0 1f 10 f0       	push   $0xf0101fb0
f010075f:	e8 12 02 00 00       	call   f0100976 <cprintf>
	return 0;
}
f0100764:	b8 00 00 00 00       	mov    $0x0,%eax
f0100769:	c9                   	leave  
f010076a:	c3                   	ret    

f010076b <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010076b:	55                   	push   %ebp
f010076c:	89 e5                	mov    %esp,%ebp
f010076e:	56                   	push   %esi
f010076f:	53                   	push   %ebx
f0100770:	83 ec 2c             	sub    $0x2c,%esp
    cprintf("Stack backtrace:\n");
f0100773:	68 38 1e 10 f0       	push   $0xf0101e38
f0100778:	e8 f9 01 00 00       	call   f0100976 <cprintf>

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010077d:	89 e8                	mov    %ebp,%eax
    uint32_t *ebp = (uint32_t *)read_ebp();
    while (ebp) {
f010077f:	83 c4 10             	add    $0x10,%esp
f0100782:	85 c0                	test   %eax,%eax
f0100784:	74 74                	je     f01007fa <mon_backtrace+0x8f>
f0100786:	89 c3                	mov    %eax,%ebx
        cprintf("eip %08x ", ebp[1]);
        cprintf("args %08x %08x %08x %08x %08x\n",
                ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);

        struct Eipdebuginfo info;
        debuginfo_eip(ebp[1], &info);
f0100788:	8d 75 e0             	lea    -0x20(%ebp),%esi
        cprintf("  ebp %08x ", ebp);
f010078b:	83 ec 08             	sub    $0x8,%esp
f010078e:	53                   	push   %ebx
f010078f:	68 4a 1e 10 f0       	push   $0xf0101e4a
f0100794:	e8 dd 01 00 00       	call   f0100976 <cprintf>
        cprintf("eip %08x ", ebp[1]);
f0100799:	83 c4 08             	add    $0x8,%esp
f010079c:	ff 73 04             	pushl  0x4(%ebx)
f010079f:	68 56 1e 10 f0       	push   $0xf0101e56
f01007a4:	e8 cd 01 00 00       	call   f0100976 <cprintf>
        cprintf("args %08x %08x %08x %08x %08x\n",
f01007a9:	83 c4 08             	add    $0x8,%esp
f01007ac:	ff 73 18             	pushl  0x18(%ebx)
f01007af:	ff 73 14             	pushl  0x14(%ebx)
f01007b2:	ff 73 10             	pushl  0x10(%ebx)
f01007b5:	ff 73 0c             	pushl  0xc(%ebx)
f01007b8:	ff 73 08             	pushl  0x8(%ebx)
f01007bb:	68 dc 1f 10 f0       	push   $0xf0101fdc
f01007c0:	e8 b1 01 00 00       	call   f0100976 <cprintf>
        debuginfo_eip(ebp[1], &info);
f01007c5:	83 c4 18             	add    $0x18,%esp
f01007c8:	56                   	push   %esi
f01007c9:	ff 73 04             	pushl  0x4(%ebx)
f01007cc:	e8 f4 02 00 00       	call   f0100ac5 <debuginfo_eip>
        cprintf("   %s:%d: %.*s+%u\n",
f01007d1:	83 c4 08             	add    $0x8,%esp
f01007d4:	8b 43 04             	mov    0x4(%ebx),%eax
f01007d7:	2b 45 f0             	sub    -0x10(%ebp),%eax
f01007da:	50                   	push   %eax
f01007db:	ff 75 e8             	pushl  -0x18(%ebp)
f01007de:	ff 75 ec             	pushl  -0x14(%ebp)
f01007e1:	ff 75 e4             	pushl  -0x1c(%ebp)
f01007e4:	ff 75 e0             	pushl  -0x20(%ebp)
f01007e7:	68 60 1e 10 f0       	push   $0xf0101e60
f01007ec:	e8 85 01 00 00       	call   f0100976 <cprintf>
                info.eip_fn_namelen,
                info.eip_fn_name,
                ebp[1] - info.eip_fn_addr);


        ebp = (uint32_t*)*ebp;
f01007f1:	8b 1b                	mov    (%ebx),%ebx
    while (ebp) {
f01007f3:	83 c4 20             	add    $0x20,%esp
f01007f6:	85 db                	test   %ebx,%ebx
f01007f8:	75 91                	jne    f010078b <mon_backtrace+0x20>
    }
	return 0;
}
f01007fa:	b8 00 00 00 00       	mov    $0x0,%eax
f01007ff:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100802:	5b                   	pop    %ebx
f0100803:	5e                   	pop    %esi
f0100804:	5d                   	pop    %ebp
f0100805:	c3                   	ret    

f0100806 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100806:	55                   	push   %ebp
f0100807:	89 e5                	mov    %esp,%ebp
f0100809:	57                   	push   %edi
f010080a:	56                   	push   %esi
f010080b:	53                   	push   %ebx
f010080c:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010080f:	68 fc 1f 10 f0       	push   $0xf0101ffc
f0100814:	e8 5d 01 00 00       	call   f0100976 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100819:	c7 04 24 20 20 10 f0 	movl   $0xf0102020,(%esp)
f0100820:	e8 51 01 00 00       	call   f0100976 <cprintf>
f0100825:	83 c4 10             	add    $0x10,%esp
f0100828:	e9 c5 00 00 00       	jmp    f01008f2 <monitor+0xec>
		while (*buf && strchr(WHITESPACE, *buf))
f010082d:	83 ec 08             	sub    $0x8,%esp
f0100830:	0f be c0             	movsbl %al,%eax
f0100833:	50                   	push   %eax
f0100834:	68 77 1e 10 f0       	push   $0xf0101e77
f0100839:	e8 ef 0d 00 00       	call   f010162d <strchr>
f010083e:	83 c4 10             	add    $0x10,%esp
f0100841:	85 c0                	test   %eax,%eax
f0100843:	74 0a                	je     f010084f <monitor+0x49>
			*buf++ = 0;
f0100845:	c6 03 00             	movb   $0x0,(%ebx)
f0100848:	89 f7                	mov    %esi,%edi
f010084a:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010084d:	eb 3e                	jmp    f010088d <monitor+0x87>
		if (*buf == 0)
f010084f:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100852:	74 42                	je     f0100896 <monitor+0x90>
		if (argc == MAXARGS-1) {
f0100854:	83 fe 0f             	cmp    $0xf,%esi
f0100857:	0f 84 83 00 00 00    	je     f01008e0 <monitor+0xda>
		argv[argc++] = buf;
f010085d:	8d 7e 01             	lea    0x1(%esi),%edi
f0100860:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100864:	0f b6 03             	movzbl (%ebx),%eax
f0100867:	84 c0                	test   %al,%al
f0100869:	74 22                	je     f010088d <monitor+0x87>
f010086b:	83 ec 08             	sub    $0x8,%esp
f010086e:	0f be c0             	movsbl %al,%eax
f0100871:	50                   	push   %eax
f0100872:	68 77 1e 10 f0       	push   $0xf0101e77
f0100877:	e8 b1 0d 00 00       	call   f010162d <strchr>
f010087c:	83 c4 10             	add    $0x10,%esp
f010087f:	85 c0                	test   %eax,%eax
f0100881:	75 0a                	jne    f010088d <monitor+0x87>
			buf++;
f0100883:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f0100886:	0f b6 03             	movzbl (%ebx),%eax
f0100889:	84 c0                	test   %al,%al
f010088b:	75 de                	jne    f010086b <monitor+0x65>
			*buf++ = 0;
f010088d:	89 fe                	mov    %edi,%esi
		while (*buf && strchr(WHITESPACE, *buf))
f010088f:	0f b6 03             	movzbl (%ebx),%eax
f0100892:	84 c0                	test   %al,%al
f0100894:	75 97                	jne    f010082d <monitor+0x27>
	argv[argc] = 0;
f0100896:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010089d:	00 
	if (argc == 0)
f010089e:	85 f6                	test   %esi,%esi
f01008a0:	74 50                	je     f01008f2 <monitor+0xec>
	for (i = 0; i < NCOMMANDS; i++) {
f01008a2:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (strcmp(argv[0], commands[i].name) == 0)
f01008a7:	83 ec 08             	sub    $0x8,%esp
f01008aa:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008ad:	ff 34 85 60 20 10 f0 	pushl  -0xfefdfa0(,%eax,4)
f01008b4:	ff 75 a8             	pushl  -0x58(%ebp)
f01008b7:	e8 f6 0c 00 00       	call   f01015b2 <strcmp>
f01008bc:	83 c4 10             	add    $0x10,%esp
f01008bf:	85 c0                	test   %eax,%eax
f01008c1:	74 56                	je     f0100919 <monitor+0x113>
	for (i = 0; i < NCOMMANDS; i++) {
f01008c3:	83 c3 01             	add    $0x1,%ebx
f01008c6:	83 fb 03             	cmp    $0x3,%ebx
f01008c9:	75 dc                	jne    f01008a7 <monitor+0xa1>
	cprintf("Unknown command '%s'\n", argv[0]);
f01008cb:	83 ec 08             	sub    $0x8,%esp
f01008ce:	ff 75 a8             	pushl  -0x58(%ebp)
f01008d1:	68 99 1e 10 f0       	push   $0xf0101e99
f01008d6:	e8 9b 00 00 00       	call   f0100976 <cprintf>
f01008db:	83 c4 10             	add    $0x10,%esp
f01008de:	eb 12                	jmp    f01008f2 <monitor+0xec>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008e0:	83 ec 08             	sub    $0x8,%esp
f01008e3:	6a 10                	push   $0x10
f01008e5:	68 7c 1e 10 f0       	push   $0xf0101e7c
f01008ea:	e8 87 00 00 00       	call   f0100976 <cprintf>
f01008ef:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01008f2:	83 ec 0c             	sub    $0xc,%esp
f01008f5:	68 73 1e 10 f0       	push   $0xf0101e73
f01008fa:	e8 c2 0a 00 00       	call   f01013c1 <readline>
f01008ff:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100901:	83 c4 10             	add    $0x10,%esp
f0100904:	85 c0                	test   %eax,%eax
f0100906:	74 ea                	je     f01008f2 <monitor+0xec>
	argv[argc] = 0;
f0100908:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f010090f:	be 00 00 00 00       	mov    $0x0,%esi
f0100914:	e9 76 ff ff ff       	jmp    f010088f <monitor+0x89>
			return commands[i].func(argc, argv, tf);
f0100919:	83 ec 04             	sub    $0x4,%esp
f010091c:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010091f:	ff 75 08             	pushl  0x8(%ebp)
f0100922:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100925:	52                   	push   %edx
f0100926:	56                   	push   %esi
f0100927:	ff 14 85 68 20 10 f0 	call   *-0xfefdf98(,%eax,4)
			if (runcmd(buf, tf) < 0)
f010092e:	83 c4 10             	add    $0x10,%esp
f0100931:	85 c0                	test   %eax,%eax
f0100933:	79 bd                	jns    f01008f2 <monitor+0xec>
				break;
	}
}
f0100935:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100938:	5b                   	pop    %ebx
f0100939:	5e                   	pop    %esi
f010093a:	5f                   	pop    %edi
f010093b:	5d                   	pop    %ebp
f010093c:	c3                   	ret    

f010093d <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010093d:	55                   	push   %ebp
f010093e:	89 e5                	mov    %esp,%ebp
f0100940:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0100943:	ff 75 08             	pushl  0x8(%ebp)
f0100946:	e8 0a fd ff ff       	call   f0100655 <cputchar>
	*cnt++;
}
f010094b:	83 c4 10             	add    $0x10,%esp
f010094e:	c9                   	leave  
f010094f:	c3                   	ret    

f0100950 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100950:	55                   	push   %ebp
f0100951:	89 e5                	mov    %esp,%ebp
f0100953:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100956:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010095d:	ff 75 0c             	pushl  0xc(%ebp)
f0100960:	ff 75 08             	pushl  0x8(%ebp)
f0100963:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100966:	50                   	push   %eax
f0100967:	68 3d 09 10 f0       	push   $0xf010093d
f010096c:	e8 9b 04 00 00       	call   f0100e0c <vprintfmt>
	return cnt;
}
f0100971:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100974:	c9                   	leave  
f0100975:	c3                   	ret    

f0100976 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100976:	55                   	push   %ebp
f0100977:	89 e5                	mov    %esp,%ebp
f0100979:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010097c:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010097f:	50                   	push   %eax
f0100980:	ff 75 08             	pushl  0x8(%ebp)
f0100983:	e8 c8 ff ff ff       	call   f0100950 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100988:	c9                   	leave  
f0100989:	c3                   	ret    

f010098a <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010098a:	55                   	push   %ebp
f010098b:	89 e5                	mov    %esp,%ebp
f010098d:	57                   	push   %edi
f010098e:	56                   	push   %esi
f010098f:	53                   	push   %ebx
f0100990:	83 ec 14             	sub    $0x14,%esp
f0100993:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100996:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100999:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010099c:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f010099f:	8b 1a                	mov    (%edx),%ebx
f01009a1:	8b 01                	mov    (%ecx),%eax
f01009a3:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while (l <= r) {
f01009a6:	39 c3                	cmp    %eax,%ebx
f01009a8:	0f 8f eb 00 00 00    	jg     f0100a99 <stab_binsearch+0x10f>
	int l = *region_left, r = *region_right, any_matches = 0;
f01009ae:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
f01009b5:	eb 18                	jmp    f01009cf <stab_binsearch+0x45>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01009b7:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01009ba:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01009bc:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f01009bf:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f01009c6:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01009c9:	0f 8f 86 00 00 00    	jg     f0100a55 <stab_binsearch+0xcb>
		int true_m = (l + r) / 2, m = true_m;
f01009cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009d2:	01 d8                	add    %ebx,%eax
f01009d4:	89 c7                	mov    %eax,%edi
f01009d6:	c1 ef 1f             	shr    $0x1f,%edi
f01009d9:	01 c7                	add    %eax,%edi
f01009db:	d1 ff                	sar    %edi
		while (m >= l && stabs[m].n_type != type)
f01009dd:	39 df                	cmp    %ebx,%edi
f01009df:	0f 8c d1 00 00 00    	jl     f0100ab6 <stab_binsearch+0x12c>
f01009e5:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f01009e8:	c1 e0 02             	shl    $0x2,%eax
f01009eb:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009ee:	0f b6 54 01 04       	movzbl 0x4(%ecx,%eax,1),%edx
f01009f3:	39 d6                	cmp    %edx,%esi
f01009f5:	0f 84 c3 00 00 00    	je     f0100abe <stab_binsearch+0x134>
f01009fb:	8d 54 01 f8          	lea    -0x8(%ecx,%eax,1),%edx
		int true_m = (l + r) / 2, m = true_m;
f01009ff:	89 f8                	mov    %edi,%eax
			m--;
f0100a01:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0100a04:	39 d8                	cmp    %ebx,%eax
f0100a06:	0f 8c aa 00 00 00    	jl     f0100ab6 <stab_binsearch+0x12c>
f0100a0c:	0f b6 0a             	movzbl (%edx),%ecx
f0100a0f:	83 ea 0c             	sub    $0xc,%edx
f0100a12:	39 f1                	cmp    %esi,%ecx
f0100a14:	75 eb                	jne    f0100a01 <stab_binsearch+0x77>
		if (stabs[m].n_value < addr) {
f0100a16:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a19:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a1c:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100a20:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a23:	72 92                	jb     f01009b7 <stab_binsearch+0x2d>
		} else if (stabs[m].n_value > addr) {
f0100a25:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a28:	76 14                	jbe    f0100a3e <stab_binsearch+0xb4>
			*region_right = m - 1;
f0100a2a:	83 e8 01             	sub    $0x1,%eax
f0100a2d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a30:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100a33:	89 07                	mov    %eax,(%edi)
		any_matches = 1;
f0100a35:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a3c:	eb 88                	jmp    f01009c6 <stab_binsearch+0x3c>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a3e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100a41:	89 07                	mov    %eax,(%edi)
			l = m;
			addr++;
f0100a43:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100a47:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f0100a49:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a50:	e9 71 ff ff ff       	jmp    f01009c6 <stab_binsearch+0x3c>
		}
	}

	if (!any_matches)
f0100a55:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100a59:	74 3e                	je     f0100a99 <stab_binsearch+0x10f>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a5b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a5e:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a60:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100a63:	8b 17                	mov    (%edi),%edx
		for (l = *region_right;
f0100a65:	39 d0                	cmp    %edx,%eax
f0100a67:	7e 45                	jle    f0100aae <stab_binsearch+0x124>
		     l > *region_left && stabs[l].n_type != type;
f0100a69:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100a6c:	c1 e1 02             	shl    $0x2,%ecx
f0100a6f:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100a72:	0f b6 5c 0f 04       	movzbl 0x4(%edi,%ecx,1),%ebx
f0100a77:	39 de                	cmp    %ebx,%esi
f0100a79:	74 37                	je     f0100ab2 <stab_binsearch+0x128>
f0100a7b:	8d 4c 0f f8          	lea    -0x8(%edi,%ecx,1),%ecx
		     l--)
f0100a7f:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0100a82:	39 d0                	cmp    %edx,%eax
f0100a84:	74 0c                	je     f0100a92 <stab_binsearch+0x108>
		     l > *region_left && stabs[l].n_type != type;
f0100a86:	0f b6 19             	movzbl (%ecx),%ebx
f0100a89:	83 e9 0c             	sub    $0xc,%ecx
f0100a8c:	39 f3                	cmp    %esi,%ebx
f0100a8e:	75 ef                	jne    f0100a7f <stab_binsearch+0xf5>
		     l--)
f0100a90:	89 c2                	mov    %eax,%edx
			/* do nothing */;
		*region_left = l;
f0100a92:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a95:	89 10                	mov    %edx,(%eax)
	}
}
f0100a97:	eb 0d                	jmp    f0100aa6 <stab_binsearch+0x11c>
		*region_right = *region_left - 1;
f0100a99:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a9c:	8b 00                	mov    (%eax),%eax
f0100a9e:	83 e8 01             	sub    $0x1,%eax
f0100aa1:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100aa4:	89 06                	mov    %eax,(%esi)
}
f0100aa6:	83 c4 14             	add    $0x14,%esp
f0100aa9:	5b                   	pop    %ebx
f0100aaa:	5e                   	pop    %esi
f0100aab:	5f                   	pop    %edi
f0100aac:	5d                   	pop    %ebp
f0100aad:	c3                   	ret    
		for (l = *region_right;
f0100aae:	89 c2                	mov    %eax,%edx
f0100ab0:	eb e0                	jmp    f0100a92 <stab_binsearch+0x108>
f0100ab2:	89 c2                	mov    %eax,%edx
f0100ab4:	eb dc                	jmp    f0100a92 <stab_binsearch+0x108>
			l = true_m + 1;
f0100ab6:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0100ab9:	e9 08 ff ff ff       	jmp    f01009c6 <stab_binsearch+0x3c>
		int true_m = (l + r) / 2, m = true_m;
f0100abe:	89 f8                	mov    %edi,%eax
f0100ac0:	e9 51 ff ff ff       	jmp    f0100a16 <stab_binsearch+0x8c>

f0100ac5 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100ac5:	55                   	push   %ebp
f0100ac6:	89 e5                	mov    %esp,%ebp
f0100ac8:	57                   	push   %edi
f0100ac9:	56                   	push   %esi
f0100aca:	53                   	push   %ebx
f0100acb:	83 ec 3c             	sub    $0x3c,%esp
f0100ace:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ad1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100ad4:	c7 03 84 20 10 f0    	movl   $0xf0102084,(%ebx)
	info->eip_line = 0;
f0100ada:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100ae1:	c7 43 08 84 20 10 f0 	movl   $0xf0102084,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100ae8:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100aef:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100af2:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100af9:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100aff:	0f 86 2d 01 00 00    	jbe    f0100c32 <debuginfo_eip+0x16d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b05:	b8 77 84 10 f0       	mov    $0xf0108477,%eax
f0100b0a:	3d a5 6a 10 f0       	cmp    $0xf0106aa5,%eax
f0100b0f:	0f 86 e4 01 00 00    	jbe    f0100cf9 <debuginfo_eip+0x234>
f0100b15:	80 3d 76 84 10 f0 00 	cmpb   $0x0,0xf0108476
f0100b1c:	0f 85 de 01 00 00    	jne    f0100d00 <debuginfo_eip+0x23b>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b22:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b29:	b8 a4 6a 10 f0       	mov    $0xf0106aa4,%eax
f0100b2e:	2d bc 22 10 f0       	sub    $0xf01022bc,%eax
f0100b33:	c1 f8 02             	sar    $0x2,%eax
f0100b36:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b3c:	83 e8 01             	sub    $0x1,%eax
f0100b3f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b42:	83 ec 08             	sub    $0x8,%esp
f0100b45:	56                   	push   %esi
f0100b46:	6a 64                	push   $0x64
f0100b48:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b4b:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b4e:	b8 bc 22 10 f0       	mov    $0xf01022bc,%eax
f0100b53:	e8 32 fe ff ff       	call   f010098a <stab_binsearch>
	if (lfile == 0)
f0100b58:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b5b:	83 c4 10             	add    $0x10,%esp
f0100b5e:	85 c0                	test   %eax,%eax
f0100b60:	0f 84 a1 01 00 00    	je     f0100d07 <debuginfo_eip+0x242>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b66:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b69:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b6c:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b6f:	83 ec 08             	sub    $0x8,%esp
f0100b72:	56                   	push   %esi
f0100b73:	6a 24                	push   $0x24
f0100b75:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b78:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b7b:	b8 bc 22 10 f0       	mov    $0xf01022bc,%eax
f0100b80:	e8 05 fe ff ff       	call   f010098a <stab_binsearch>

	if (lfun <= rfun) {
f0100b85:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100b88:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100b8b:	83 c4 10             	add    $0x10,%esp
f0100b8e:	39 d0                	cmp    %edx,%eax
f0100b90:	0f 8f b0 00 00 00    	jg     f0100c46 <debuginfo_eip+0x181>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b96:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100b99:	c1 e1 02             	shl    $0x2,%ecx
f0100b9c:	8d b9 bc 22 10 f0    	lea    -0xfefdd44(%ecx),%edi
f0100ba2:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100ba5:	8b b9 bc 22 10 f0    	mov    -0xfefdd44(%ecx),%edi
f0100bab:	b9 77 84 10 f0       	mov    $0xf0108477,%ecx
f0100bb0:	81 e9 a5 6a 10 f0    	sub    $0xf0106aa5,%ecx
f0100bb6:	39 cf                	cmp    %ecx,%edi
f0100bb8:	73 09                	jae    f0100bc3 <debuginfo_eip+0xfe>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100bba:	81 c7 a5 6a 10 f0    	add    $0xf0106aa5,%edi
f0100bc0:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100bc3:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100bc6:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100bc9:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100bcc:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100bce:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100bd1:	89 55 d0             	mov    %edx,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bd4:	83 ec 08             	sub    $0x8,%esp
f0100bd7:	6a 3a                	push   $0x3a
f0100bd9:	ff 73 08             	pushl  0x8(%ebx)
f0100bdc:	e8 82 0a 00 00       	call   f0101663 <strfind>
f0100be1:	2b 43 08             	sub    0x8(%ebx),%eax
f0100be4:	89 43 0c             	mov    %eax,0xc(%ebx)
	//
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
    stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100be7:	83 c4 08             	add    $0x8,%esp
f0100bea:	56                   	push   %esi
f0100beb:	6a 44                	push   $0x44
f0100bed:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100bf0:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100bf3:	b8 bc 22 10 f0       	mov    $0xf01022bc,%eax
f0100bf8:	e8 8d fd ff ff       	call   f010098a <stab_binsearch>
    if (lline <= rline) {
f0100bfd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c00:	83 c4 10             	add    $0x10,%esp
f0100c03:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100c06:	0f 8f 02 01 00 00    	jg     f0100d0e <debuginfo_eip+0x249>
        info->eip_line = stabs[lline].n_desc;
f0100c0c:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100c0f:	8d 0c 95 bc 22 10 f0 	lea    -0xfefdd44(,%edx,4),%ecx
f0100c16:	0f b7 51 06          	movzwl 0x6(%ecx),%edx
f0100c1a:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c1d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100c20:	39 f0                	cmp    %esi,%eax
f0100c22:	7c 7e                	jl     f0100ca2 <debuginfo_eip+0x1dd>
	       && stabs[lline].n_type != N_SOL
f0100c24:	0f b6 51 04          	movzbl 0x4(%ecx),%edx
f0100c28:	80 fa 84             	cmp    $0x84,%dl
f0100c2b:	74 55                	je     f0100c82 <debuginfo_eip+0x1bd>
f0100c2d:	83 c1 08             	add    $0x8,%ecx
f0100c30:	eb 42                	jmp    f0100c74 <debuginfo_eip+0x1af>
  	        panic("User address");
f0100c32:	83 ec 04             	sub    $0x4,%esp
f0100c35:	68 8e 20 10 f0       	push   $0xf010208e
f0100c3a:	6a 7f                	push   $0x7f
f0100c3c:	68 9b 20 10 f0       	push   $0xf010209b
f0100c41:	e8 a0 f4 ff ff       	call   f01000e6 <_panic>
		info->eip_fn_addr = addr;
f0100c46:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c49:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c4c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100c4f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c52:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100c55:	e9 7a ff ff ff       	jmp    f0100bd4 <debuginfo_eip+0x10f>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100c5a:	83 e8 01             	sub    $0x1,%eax
	while (lline >= lfile
f0100c5d:	39 f0                	cmp    %esi,%eax
f0100c5f:	7c 41                	jl     f0100ca2 <debuginfo_eip+0x1dd>
	       && stabs[lline].n_type != N_SOL
f0100c61:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100c64:	0f b6 14 95 c0 22 10 	movzbl -0xfefdd40(,%edx,4),%edx
f0100c6b:	f0 
f0100c6c:	83 e9 0c             	sub    $0xc,%ecx
f0100c6f:	80 fa 84             	cmp    $0x84,%dl
f0100c72:	74 0e                	je     f0100c82 <debuginfo_eip+0x1bd>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c74:	80 fa 64             	cmp    $0x64,%dl
f0100c77:	75 e1                	jne    f0100c5a <debuginfo_eip+0x195>
f0100c79:	83 39 00             	cmpl   $0x0,(%ecx)
f0100c7c:	74 dc                	je     f0100c5a <debuginfo_eip+0x195>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c7e:	39 c6                	cmp    %eax,%esi
f0100c80:	7f 20                	jg     f0100ca2 <debuginfo_eip+0x1dd>
f0100c82:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100c85:	8b 14 85 bc 22 10 f0 	mov    -0xfefdd44(,%eax,4),%edx
f0100c8c:	b8 77 84 10 f0       	mov    $0xf0108477,%eax
f0100c91:	2d a5 6a 10 f0       	sub    $0xf0106aa5,%eax
f0100c96:	39 c2                	cmp    %eax,%edx
f0100c98:	73 08                	jae    f0100ca2 <debuginfo_eip+0x1dd>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c9a:	81 c2 a5 6a 10 f0    	add    $0xf0106aa5,%edx
f0100ca0:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100ca2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ca5:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100ca8:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100cad:	39 f2                	cmp    %esi,%edx
f0100caf:	7d 40                	jge    f0100cf1 <debuginfo_eip+0x22c>
		for (lline = lfun + 1;
f0100cb1:	8d 42 01             	lea    0x1(%edx),%eax
f0100cb4:	39 c6                	cmp    %eax,%esi
f0100cb6:	7e 5d                	jle    f0100d15 <debuginfo_eip+0x250>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100cb8:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100cbb:	80 3c 95 c0 22 10 f0 	cmpb   $0xa0,-0xfefdd40(,%edx,4)
f0100cc2:	a0 
f0100cc3:	75 57                	jne    f0100d1c <debuginfo_eip+0x257>
f0100cc5:	8b 53 14             	mov    0x14(%ebx),%edx
			info->eip_fn_narg++;
f0100cc8:	83 c2 01             	add    $0x1,%edx
		     lline++)
f0100ccb:	83 c0 01             	add    $0x1,%eax
		for (lline = lfun + 1;
f0100cce:	39 c6                	cmp    %eax,%esi
f0100cd0:	74 17                	je     f0100ce9 <debuginfo_eip+0x224>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100cd2:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100cd5:	80 3c 8d c0 22 10 f0 	cmpb   $0xa0,-0xfefdd40(,%ecx,4)
f0100cdc:	a0 
f0100cdd:	74 e9                	je     f0100cc8 <debuginfo_eip+0x203>
f0100cdf:	89 53 14             	mov    %edx,0x14(%ebx)
	return 0;
f0100ce2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ce7:	eb 08                	jmp    f0100cf1 <debuginfo_eip+0x22c>
f0100ce9:	89 53 14             	mov    %edx,0x14(%ebx)
f0100cec:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100cf1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cf4:	5b                   	pop    %ebx
f0100cf5:	5e                   	pop    %esi
f0100cf6:	5f                   	pop    %edi
f0100cf7:	5d                   	pop    %ebp
f0100cf8:	c3                   	ret    
		return -1;
f0100cf9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cfe:	eb f1                	jmp    f0100cf1 <debuginfo_eip+0x22c>
f0100d00:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d05:	eb ea                	jmp    f0100cf1 <debuginfo_eip+0x22c>
		return -1;
f0100d07:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d0c:	eb e3                	jmp    f0100cf1 <debuginfo_eip+0x22c>
        return -1;
f0100d0e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d13:	eb dc                	jmp    f0100cf1 <debuginfo_eip+0x22c>
	return 0;
f0100d15:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d1a:	eb d5                	jmp    f0100cf1 <debuginfo_eip+0x22c>
f0100d1c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d21:	eb ce                	jmp    f0100cf1 <debuginfo_eip+0x22c>

f0100d23 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d23:	55                   	push   %ebp
f0100d24:	89 e5                	mov    %esp,%ebp
f0100d26:	57                   	push   %edi
f0100d27:	56                   	push   %esi
f0100d28:	53                   	push   %ebx
f0100d29:	83 ec 1c             	sub    $0x1c,%esp
f0100d2c:	89 c7                	mov    %eax,%edi
f0100d2e:	89 d6                	mov    %edx,%esi
f0100d30:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d33:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100d36:	89 c1                	mov    %eax,%ecx
f0100d38:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d3b:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100d3e:	8b 45 10             	mov    0x10(%ebp),%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d41:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d44:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100d4b:	39 c1                	cmp    %eax,%ecx
f0100d4d:	1b 55 e4             	sbb    -0x1c(%ebp),%edx
f0100d50:	73 4b                	jae    f0100d9d <printnum+0x7a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d52:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d55:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100d58:	85 db                	test   %ebx,%ebx
f0100d5a:	7e 11                	jle    f0100d6d <printnum+0x4a>
			putch(padc, putdat);
f0100d5c:	83 ec 08             	sub    $0x8,%esp
f0100d5f:	56                   	push   %esi
f0100d60:	ff 75 18             	pushl  0x18(%ebp)
f0100d63:	ff d7                	call   *%edi
		while (--width > 0)
f0100d65:	83 c4 10             	add    $0x10,%esp
f0100d68:	83 eb 01             	sub    $0x1,%ebx
f0100d6b:	75 ef                	jne    f0100d5c <printnum+0x39>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d6d:	83 ec 08             	sub    $0x8,%esp
f0100d70:	56                   	push   %esi
f0100d71:	83 ec 04             	sub    $0x4,%esp
f0100d74:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d77:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d7a:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d7d:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d80:	e8 3b 0c 00 00       	call   f01019c0 <__umoddi3>
f0100d85:	83 c4 14             	add    $0x14,%esp
f0100d88:	0f be 80 a9 20 10 f0 	movsbl -0xfefdf57(%eax),%eax
f0100d8f:	50                   	push   %eax
f0100d90:	ff d7                	call   *%edi
}
f0100d92:	83 c4 10             	add    $0x10,%esp
f0100d95:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d98:	5b                   	pop    %ebx
f0100d99:	5e                   	pop    %esi
f0100d9a:	5f                   	pop    %edi
f0100d9b:	5d                   	pop    %ebp
f0100d9c:	c3                   	ret    
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d9d:	83 ec 0c             	sub    $0xc,%esp
f0100da0:	ff 75 18             	pushl  0x18(%ebp)
f0100da3:	8b 55 14             	mov    0x14(%ebp),%edx
f0100da6:	83 ea 01             	sub    $0x1,%edx
f0100da9:	52                   	push   %edx
f0100daa:	50                   	push   %eax
f0100dab:	83 ec 08             	sub    $0x8,%esp
f0100dae:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100db1:	ff 75 e0             	pushl  -0x20(%ebp)
f0100db4:	ff 75 dc             	pushl  -0x24(%ebp)
f0100db7:	ff 75 d8             	pushl  -0x28(%ebp)
f0100dba:	e8 f1 0a 00 00       	call   f01018b0 <__udivdi3>
f0100dbf:	83 c4 18             	add    $0x18,%esp
f0100dc2:	52                   	push   %edx
f0100dc3:	50                   	push   %eax
f0100dc4:	89 f2                	mov    %esi,%edx
f0100dc6:	89 f8                	mov    %edi,%eax
f0100dc8:	e8 56 ff ff ff       	call   f0100d23 <printnum>
f0100dcd:	83 c4 20             	add    $0x20,%esp
f0100dd0:	eb 9b                	jmp    f0100d6d <printnum+0x4a>

f0100dd2 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100dd2:	55                   	push   %ebp
f0100dd3:	89 e5                	mov    %esp,%ebp
f0100dd5:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100dd8:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100ddc:	8b 10                	mov    (%eax),%edx
f0100dde:	3b 50 04             	cmp    0x4(%eax),%edx
f0100de1:	73 0a                	jae    f0100ded <sprintputch+0x1b>
		*b->buf++ = ch;
f0100de3:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100de6:	89 08                	mov    %ecx,(%eax)
f0100de8:	8b 45 08             	mov    0x8(%ebp),%eax
f0100deb:	88 02                	mov    %al,(%edx)
}
f0100ded:	5d                   	pop    %ebp
f0100dee:	c3                   	ret    

f0100def <printfmt>:
{
f0100def:	55                   	push   %ebp
f0100df0:	89 e5                	mov    %esp,%ebp
f0100df2:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0100df5:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100df8:	50                   	push   %eax
f0100df9:	ff 75 10             	pushl  0x10(%ebp)
f0100dfc:	ff 75 0c             	pushl  0xc(%ebp)
f0100dff:	ff 75 08             	pushl  0x8(%ebp)
f0100e02:	e8 05 00 00 00       	call   f0100e0c <vprintfmt>
}
f0100e07:	83 c4 10             	add    $0x10,%esp
f0100e0a:	c9                   	leave  
f0100e0b:	c3                   	ret    

f0100e0c <vprintfmt>:
{
f0100e0c:	55                   	push   %ebp
f0100e0d:	89 e5                	mov    %esp,%ebp
f0100e0f:	57                   	push   %edi
f0100e10:	56                   	push   %esi
f0100e11:	53                   	push   %ebx
f0100e12:	83 ec 2c             	sub    $0x2c,%esp
f0100e15:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100e18:	89 df                	mov    %ebx,%edi
f0100e1a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e1d:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e20:	8d 70 01             	lea    0x1(%eax),%esi
f0100e23:	0f b6 00             	movzbl (%eax),%eax
f0100e26:	83 f8 25             	cmp    $0x25,%eax
f0100e29:	74 2b                	je     f0100e56 <vprintfmt+0x4a>
			if (ch == '\0')
f0100e2b:	85 c0                	test   %eax,%eax
f0100e2d:	74 1a                	je     f0100e49 <vprintfmt+0x3d>
			putch(ch, putdat);
f0100e2f:	83 ec 08             	sub    $0x8,%esp
f0100e32:	53                   	push   %ebx
f0100e33:	50                   	push   %eax
f0100e34:	ff d7                	call   *%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e36:	83 c6 01             	add    $0x1,%esi
f0100e39:	0f b6 46 ff          	movzbl -0x1(%esi),%eax
f0100e3d:	83 c4 10             	add    $0x10,%esp
f0100e40:	83 f8 25             	cmp    $0x25,%eax
f0100e43:	74 11                	je     f0100e56 <vprintfmt+0x4a>
			if (ch == '\0')
f0100e45:	85 c0                	test   %eax,%eax
f0100e47:	75 e6                	jne    f0100e2f <vprintfmt+0x23>
}
f0100e49:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e4c:	5b                   	pop    %ebx
f0100e4d:	5e                   	pop    %esi
f0100e4e:	5f                   	pop    %edi
f0100e4f:	5d                   	pop    %ebp
f0100e50:	c3                   	ret    
			for (fmt--; fmt[-1] != '%'; fmt--)
f0100e51:	89 75 10             	mov    %esi,0x10(%ebp)
f0100e54:	eb c7                	jmp    f0100e1d <vprintfmt+0x11>
		padc = ' ';
f0100e56:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
		altflag = 0;
f0100e5a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0100e61:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
f0100e68:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
		lflag = 0;
f0100e6f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e74:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100e77:	8d 4e 01             	lea    0x1(%esi),%ecx
f0100e7a:	0f b6 16             	movzbl (%esi),%edx
f0100e7d:	8d 42 dd             	lea    -0x23(%edx),%eax
f0100e80:	3c 55                	cmp    $0x55,%al
f0100e82:	0f 87 27 04 00 00    	ja     f01012af <vprintfmt+0x4a3>
f0100e88:	0f b6 c0             	movzbl %al,%eax
f0100e8b:	ff 24 85 38 21 10 f0 	jmp    *-0xfefdec8(,%eax,4)
f0100e92:	89 ce                	mov    %ecx,%esi
			padc = '-';
f0100e94:	c6 45 e3 2d          	movb   $0x2d,-0x1d(%ebp)
f0100e98:	eb dd                	jmp    f0100e77 <vprintfmt+0x6b>
		switch (ch = *(unsigned char *) fmt++) {
f0100e9a:	89 ce                	mov    %ecx,%esi
			padc = '0';
f0100e9c:	c6 45 e3 30          	movb   $0x30,-0x1d(%ebp)
f0100ea0:	eb d5                	jmp    f0100e77 <vprintfmt+0x6b>
		switch (ch = *(unsigned char *) fmt++) {
f0100ea2:	0f b6 d2             	movzbl %dl,%edx
				precision = precision * 10 + ch - '0';
f0100ea5:	8d 42 d0             	lea    -0x30(%edx),%eax
f0100ea8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				ch = *fmt;
f0100eab:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0100eaf:	8d 50 d0             	lea    -0x30(%eax),%edx
f0100eb2:	83 fa 09             	cmp    $0x9,%edx
f0100eb5:	77 6f                	ja     f0100f26 <vprintfmt+0x11a>
f0100eb7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			for (precision = 0; ; ++fmt) {
f0100eba:	83 c1 01             	add    $0x1,%ecx
				precision = precision * 10 + ch - '0';
f0100ebd:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0100ec0:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0100ec4:	0f be 01             	movsbl (%ecx),%eax
				if (ch < '0' || ch > '9')
f0100ec7:	8d 70 d0             	lea    -0x30(%eax),%esi
f0100eca:	83 fe 09             	cmp    $0x9,%esi
f0100ecd:	76 eb                	jbe    f0100eba <vprintfmt+0xae>
f0100ecf:	89 55 d4             	mov    %edx,-0x2c(%ebp)
			for (precision = 0; ; ++fmt) {
f0100ed2:	89 ce                	mov    %ecx,%esi
f0100ed4:	eb 13                	jmp    f0100ee9 <vprintfmt+0xdd>
			precision = va_arg(ap, int);
f0100ed6:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ed9:	8b 00                	mov    (%eax),%eax
f0100edb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100ede:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ee1:	8d 40 04             	lea    0x4(%eax),%eax
f0100ee4:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100ee7:	89 ce                	mov    %ecx,%esi
			if (width < 0)
f0100ee9:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100eed:	79 88                	jns    f0100e77 <vprintfmt+0x6b>
				width = precision, precision = -1;
f0100eef:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ef2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100ef5:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100efc:	e9 76 ff ff ff       	jmp    f0100e77 <vprintfmt+0x6b>
f0100f01:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f04:	85 c0                	test   %eax,%eax
f0100f06:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f0b:	0f 49 d0             	cmovns %eax,%edx
f0100f0e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f11:	89 ce                	mov    %ecx,%esi
f0100f13:	e9 5f ff ff ff       	jmp    f0100e77 <vprintfmt+0x6b>
f0100f18:	89 ce                	mov    %ecx,%esi
			altflag = 1;
f0100f1a:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100f21:	e9 51 ff ff ff       	jmp    f0100e77 <vprintfmt+0x6b>
		switch (ch = *(unsigned char *) fmt++) {
f0100f26:	89 ce                	mov    %ecx,%esi
f0100f28:	eb bf                	jmp    f0100ee9 <vprintfmt+0xdd>
			lflag++;
f0100f2a:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f2e:	89 ce                	mov    %ecx,%esi
			goto reswitch;
f0100f30:	e9 42 ff ff ff       	jmp    f0100e77 <vprintfmt+0x6b>
f0100f35:	89 4d 10             	mov    %ecx,0x10(%ebp)
			putch(va_arg(ap, int), putdat);
f0100f38:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f3b:	8d 70 04             	lea    0x4(%eax),%esi
f0100f3e:	83 ec 08             	sub    $0x8,%esp
f0100f41:	53                   	push   %ebx
f0100f42:	ff 30                	pushl  (%eax)
f0100f44:	ff d7                	call   *%edi
			break;
f0100f46:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0100f49:	89 75 14             	mov    %esi,0x14(%ebp)
			break;
f0100f4c:	e9 cc fe ff ff       	jmp    f0100e1d <vprintfmt+0x11>
f0100f51:	89 4d 10             	mov    %ecx,0x10(%ebp)
			err = va_arg(ap, int);
f0100f54:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f57:	8d 70 04             	lea    0x4(%eax),%esi
f0100f5a:	8b 00                	mov    (%eax),%eax
f0100f5c:	99                   	cltd   
f0100f5d:	31 d0                	xor    %edx,%eax
f0100f5f:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f61:	83 f8 06             	cmp    $0x6,%eax
f0100f64:	7f 23                	jg     f0100f89 <vprintfmt+0x17d>
f0100f66:	8b 14 85 90 22 10 f0 	mov    -0xfefdd70(,%eax,4),%edx
f0100f6d:	85 d2                	test   %edx,%edx
f0100f6f:	74 18                	je     f0100f89 <vprintfmt+0x17d>
				printfmt(putch, putdat, "%s", p);
f0100f71:	52                   	push   %edx
f0100f72:	68 ca 20 10 f0       	push   $0xf01020ca
f0100f77:	53                   	push   %ebx
f0100f78:	57                   	push   %edi
f0100f79:	e8 71 fe ff ff       	call   f0100def <printfmt>
f0100f7e:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0100f81:	89 75 14             	mov    %esi,0x14(%ebp)
f0100f84:	e9 94 fe ff ff       	jmp    f0100e1d <vprintfmt+0x11>
				printfmt(putch, putdat, "error %d", err);
f0100f89:	50                   	push   %eax
f0100f8a:	68 c1 20 10 f0       	push   $0xf01020c1
f0100f8f:	53                   	push   %ebx
f0100f90:	57                   	push   %edi
f0100f91:	e8 59 fe ff ff       	call   f0100def <printfmt>
f0100f96:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0100f99:	89 75 14             	mov    %esi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0100f9c:	e9 7c fe ff ff       	jmp    f0100e1d <vprintfmt+0x11>
f0100fa1:	89 4d 10             	mov    %ecx,0x10(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
f0100fa4:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fa7:	83 c0 04             	add    $0x4,%eax
f0100faa:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100fad:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fb0:	8b 00                	mov    (%eax),%eax
f0100fb2:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100fb5:	85 c0                	test   %eax,%eax
f0100fb7:	0f 84 28 03 00 00    	je     f01012e5 <vprintfmt+0x4d9>
			if (width > 0 && padc != '-')
f0100fbd:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100fc1:	7e 06                	jle    f0100fc9 <vprintfmt+0x1bd>
f0100fc3:	80 7d e3 2d          	cmpb   $0x2d,-0x1d(%ebp)
f0100fc7:	75 22                	jne    f0100feb <vprintfmt+0x1df>
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100fc9:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0100fcc:	8d 70 01             	lea    0x1(%eax),%esi
f0100fcf:	0f b6 00             	movzbl (%eax),%eax
f0100fd2:	0f be d0             	movsbl %al,%edx
f0100fd5:	85 d2                	test   %edx,%edx
f0100fd7:	0f 84 ae 00 00 00    	je     f010108b <vprintfmt+0x27f>
f0100fdd:	89 7d 08             	mov    %edi,0x8(%ebp)
f0100fe0:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100fe3:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100fe6:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100fe9:	eb 6d                	jmp    f0101058 <vprintfmt+0x24c>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100feb:	83 ec 08             	sub    $0x8,%esp
f0100fee:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100ff1:	50                   	push   %eax
f0100ff2:	e8 ce 04 00 00       	call   f01014c5 <strnlen>
f0100ff7:	29 45 e4             	sub    %eax,-0x1c(%ebp)
f0100ffa:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100ffd:	83 c4 10             	add    $0x10,%esp
f0101000:	85 c9                	test   %ecx,%ecx
f0101002:	7e 14                	jle    f0101018 <vprintfmt+0x20c>
					putch(padc, putdat);
f0101004:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f0101008:	83 ec 08             	sub    $0x8,%esp
f010100b:	53                   	push   %ebx
f010100c:	56                   	push   %esi
f010100d:	ff d7                	call   *%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f010100f:	83 c4 10             	add    $0x10,%esp
f0101012:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f0101016:	75 f0                	jne    f0101008 <vprintfmt+0x1fc>
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101018:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010101b:	8d 70 01             	lea    0x1(%eax),%esi
f010101e:	0f b6 00             	movzbl (%eax),%eax
f0101021:	0f be d0             	movsbl %al,%edx
f0101024:	85 d2                	test   %edx,%edx
f0101026:	0f 84 ae 02 00 00    	je     f01012da <vprintfmt+0x4ce>
f010102c:	89 7d 08             	mov    %edi,0x8(%ebp)
f010102f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101032:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101035:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0101038:	eb 1e                	jmp    f0101058 <vprintfmt+0x24c>
					putch(ch, putdat);
f010103a:	83 ec 08             	sub    $0x8,%esp
f010103d:	ff 75 0c             	pushl  0xc(%ebp)
f0101040:	52                   	push   %edx
f0101041:	ff 55 08             	call   *0x8(%ebp)
f0101044:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101047:	83 eb 01             	sub    $0x1,%ebx
f010104a:	83 c6 01             	add    $0x1,%esi
f010104d:	0f b6 46 ff          	movzbl -0x1(%esi),%eax
f0101051:	0f be d0             	movsbl %al,%edx
f0101054:	85 d2                	test   %edx,%edx
f0101056:	74 2a                	je     f0101082 <vprintfmt+0x276>
f0101058:	85 ff                	test   %edi,%edi
f010105a:	78 05                	js     f0101061 <vprintfmt+0x255>
f010105c:	83 ef 01             	sub    $0x1,%edi
f010105f:	78 4e                	js     f01010af <vprintfmt+0x2a3>
				if (altflag && (ch < ' ' || ch > '~'))
f0101061:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101065:	74 d3                	je     f010103a <vprintfmt+0x22e>
f0101067:	0f be c0             	movsbl %al,%eax
f010106a:	83 e8 20             	sub    $0x20,%eax
f010106d:	83 f8 5e             	cmp    $0x5e,%eax
f0101070:	76 c8                	jbe    f010103a <vprintfmt+0x22e>
					putch('?', putdat);
f0101072:	83 ec 08             	sub    $0x8,%esp
f0101075:	ff 75 0c             	pushl  0xc(%ebp)
f0101078:	6a 3f                	push   $0x3f
f010107a:	ff 55 08             	call   *0x8(%ebp)
f010107d:	83 c4 10             	add    $0x10,%esp
f0101080:	eb c5                	jmp    f0101047 <vprintfmt+0x23b>
f0101082:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0101085:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101088:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010108b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
			for (; width > 0; width--)
f010108e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101092:	7e 26                	jle    f01010ba <vprintfmt+0x2ae>
				putch(' ', putdat);
f0101094:	83 ec 08             	sub    $0x8,%esp
f0101097:	53                   	push   %ebx
f0101098:	6a 20                	push   $0x20
f010109a:	ff d7                	call   *%edi
			for (; width > 0; width--)
f010109c:	83 c4 10             	add    $0x10,%esp
f010109f:	83 ee 01             	sub    $0x1,%esi
f01010a2:	75 f0                	jne    f0101094 <vprintfmt+0x288>
			if ((p = va_arg(ap, char *)) == NULL)
f01010a4:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01010a7:	89 45 14             	mov    %eax,0x14(%ebp)
f01010aa:	e9 6e fd ff ff       	jmp    f0100e1d <vprintfmt+0x11>
f01010af:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01010b2:	8b 7d 08             	mov    0x8(%ebp),%edi
f01010b5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01010b8:	eb d1                	jmp    f010108b <vprintfmt+0x27f>
f01010ba:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01010bd:	89 45 14             	mov    %eax,0x14(%ebp)
f01010c0:	e9 58 fd ff ff       	jmp    f0100e1d <vprintfmt+0x11>
f01010c5:	89 4d 10             	mov    %ecx,0x10(%ebp)
f01010c8:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01010cb:	83 f9 01             	cmp    $0x1,%ecx
f01010ce:	7f 1f                	jg     f01010ef <vprintfmt+0x2e3>
	else if (lflag)
f01010d0:	85 c9                	test   %ecx,%ecx
f01010d2:	74 67                	je     f010113b <vprintfmt+0x32f>
		return va_arg(*ap, long);
f01010d4:	8b 45 14             	mov    0x14(%ebp),%eax
f01010d7:	8b 30                	mov    (%eax),%esi
f01010d9:	89 75 d8             	mov    %esi,-0x28(%ebp)
f01010dc:	89 f0                	mov    %esi,%eax
f01010de:	c1 f8 1f             	sar    $0x1f,%eax
f01010e1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01010e4:	8b 45 14             	mov    0x14(%ebp),%eax
f01010e7:	8d 40 04             	lea    0x4(%eax),%eax
f01010ea:	89 45 14             	mov    %eax,0x14(%ebp)
f01010ed:	eb 17                	jmp    f0101106 <vprintfmt+0x2fa>
		return va_arg(*ap, long long);
f01010ef:	8b 45 14             	mov    0x14(%ebp),%eax
f01010f2:	8b 50 04             	mov    0x4(%eax),%edx
f01010f5:	8b 00                	mov    (%eax),%eax
f01010f7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010fa:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01010fd:	8b 45 14             	mov    0x14(%ebp),%eax
f0101100:	8d 40 08             	lea    0x8(%eax),%eax
f0101103:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0101106:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101109:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f010110c:	b8 0a 00 00 00       	mov    $0xa,%eax
			if ((long long) num < 0) {
f0101111:	85 c9                	test   %ecx,%ecx
f0101113:	0f 89 12 01 00 00    	jns    f010122b <vprintfmt+0x41f>
				putch('-', putdat);
f0101119:	83 ec 08             	sub    $0x8,%esp
f010111c:	53                   	push   %ebx
f010111d:	6a 2d                	push   $0x2d
f010111f:	ff d7                	call   *%edi
				num = -(long long) num;
f0101121:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101124:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101127:	f7 da                	neg    %edx
f0101129:	83 d1 00             	adc    $0x0,%ecx
f010112c:	f7 d9                	neg    %ecx
f010112e:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0101131:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101136:	e9 f0 00 00 00       	jmp    f010122b <vprintfmt+0x41f>
		return va_arg(*ap, int);
f010113b:	8b 45 14             	mov    0x14(%ebp),%eax
f010113e:	8b 30                	mov    (%eax),%esi
f0101140:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0101143:	89 f0                	mov    %esi,%eax
f0101145:	c1 f8 1f             	sar    $0x1f,%eax
f0101148:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010114b:	8b 45 14             	mov    0x14(%ebp),%eax
f010114e:	8d 40 04             	lea    0x4(%eax),%eax
f0101151:	89 45 14             	mov    %eax,0x14(%ebp)
f0101154:	eb b0                	jmp    f0101106 <vprintfmt+0x2fa>
f0101156:	89 4d 10             	mov    %ecx,0x10(%ebp)
f0101159:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f010115c:	83 f9 01             	cmp    $0x1,%ecx
f010115f:	7f 1e                	jg     f010117f <vprintfmt+0x373>
	else if (lflag)
f0101161:	85 c9                	test   %ecx,%ecx
f0101163:	74 32                	je     f0101197 <vprintfmt+0x38b>
		return va_arg(*ap, unsigned long);
f0101165:	8b 45 14             	mov    0x14(%ebp),%eax
f0101168:	8b 10                	mov    (%eax),%edx
f010116a:	b9 00 00 00 00       	mov    $0x0,%ecx
f010116f:	8d 40 04             	lea    0x4(%eax),%eax
f0101172:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101175:	b8 0a 00 00 00       	mov    $0xa,%eax
f010117a:	e9 ac 00 00 00       	jmp    f010122b <vprintfmt+0x41f>
		return va_arg(*ap, unsigned long long);
f010117f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101182:	8b 10                	mov    (%eax),%edx
f0101184:	8b 48 04             	mov    0x4(%eax),%ecx
f0101187:	8d 40 08             	lea    0x8(%eax),%eax
f010118a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010118d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101192:	e9 94 00 00 00       	jmp    f010122b <vprintfmt+0x41f>
		return va_arg(*ap, unsigned int);
f0101197:	8b 45 14             	mov    0x14(%ebp),%eax
f010119a:	8b 10                	mov    (%eax),%edx
f010119c:	b9 00 00 00 00       	mov    $0x0,%ecx
f01011a1:	8d 40 04             	lea    0x4(%eax),%eax
f01011a4:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01011a7:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011ac:	eb 7d                	jmp    f010122b <vprintfmt+0x41f>
f01011ae:	89 4d 10             	mov    %ecx,0x10(%ebp)
f01011b1:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01011b4:	83 f9 01             	cmp    $0x1,%ecx
f01011b7:	7f 1b                	jg     f01011d4 <vprintfmt+0x3c8>
	else if (lflag)
f01011b9:	85 c9                	test   %ecx,%ecx
f01011bb:	74 2c                	je     f01011e9 <vprintfmt+0x3dd>
		return va_arg(*ap, unsigned long);
f01011bd:	8b 45 14             	mov    0x14(%ebp),%eax
f01011c0:	8b 10                	mov    (%eax),%edx
f01011c2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01011c7:	8d 40 04             	lea    0x4(%eax),%eax
f01011ca:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01011cd:	b8 08 00 00 00       	mov    $0x8,%eax
f01011d2:	eb 57                	jmp    f010122b <vprintfmt+0x41f>
		return va_arg(*ap, unsigned long long);
f01011d4:	8b 45 14             	mov    0x14(%ebp),%eax
f01011d7:	8b 10                	mov    (%eax),%edx
f01011d9:	8b 48 04             	mov    0x4(%eax),%ecx
f01011dc:	8d 40 08             	lea    0x8(%eax),%eax
f01011df:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01011e2:	b8 08 00 00 00       	mov    $0x8,%eax
f01011e7:	eb 42                	jmp    f010122b <vprintfmt+0x41f>
		return va_arg(*ap, unsigned int);
f01011e9:	8b 45 14             	mov    0x14(%ebp),%eax
f01011ec:	8b 10                	mov    (%eax),%edx
f01011ee:	b9 00 00 00 00       	mov    $0x0,%ecx
f01011f3:	8d 40 04             	lea    0x4(%eax),%eax
f01011f6:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01011f9:	b8 08 00 00 00       	mov    $0x8,%eax
f01011fe:	eb 2b                	jmp    f010122b <vprintfmt+0x41f>
f0101200:	89 4d 10             	mov    %ecx,0x10(%ebp)
			putch('0', putdat);
f0101203:	83 ec 08             	sub    $0x8,%esp
f0101206:	53                   	push   %ebx
f0101207:	6a 30                	push   $0x30
f0101209:	ff d7                	call   *%edi
			putch('x', putdat);
f010120b:	83 c4 08             	add    $0x8,%esp
f010120e:	53                   	push   %ebx
f010120f:	6a 78                	push   $0x78
f0101211:	ff d7                	call   *%edi
			num = (unsigned long long)
f0101213:	8b 45 14             	mov    0x14(%ebp),%eax
f0101216:	8b 10                	mov    (%eax),%edx
f0101218:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f010121d:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0101220:	8d 40 04             	lea    0x4(%eax),%eax
f0101223:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101226:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f010122b:	83 ec 0c             	sub    $0xc,%esp
f010122e:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f0101232:	56                   	push   %esi
f0101233:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101236:	50                   	push   %eax
f0101237:	51                   	push   %ecx
f0101238:	52                   	push   %edx
f0101239:	89 da                	mov    %ebx,%edx
f010123b:	89 f8                	mov    %edi,%eax
f010123d:	e8 e1 fa ff ff       	call   f0100d23 <printnum>
			break;
f0101242:	83 c4 20             	add    $0x20,%esp
f0101245:	e9 d3 fb ff ff       	jmp    f0100e1d <vprintfmt+0x11>
f010124a:	89 4d 10             	mov    %ecx,0x10(%ebp)
f010124d:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0101250:	83 f9 01             	cmp    $0x1,%ecx
f0101253:	7f 1b                	jg     f0101270 <vprintfmt+0x464>
	else if (lflag)
f0101255:	85 c9                	test   %ecx,%ecx
f0101257:	74 2c                	je     f0101285 <vprintfmt+0x479>
		return va_arg(*ap, unsigned long);
f0101259:	8b 45 14             	mov    0x14(%ebp),%eax
f010125c:	8b 10                	mov    (%eax),%edx
f010125e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101263:	8d 40 04             	lea    0x4(%eax),%eax
f0101266:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101269:	b8 10 00 00 00       	mov    $0x10,%eax
f010126e:	eb bb                	jmp    f010122b <vprintfmt+0x41f>
		return va_arg(*ap, unsigned long long);
f0101270:	8b 45 14             	mov    0x14(%ebp),%eax
f0101273:	8b 10                	mov    (%eax),%edx
f0101275:	8b 48 04             	mov    0x4(%eax),%ecx
f0101278:	8d 40 08             	lea    0x8(%eax),%eax
f010127b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010127e:	b8 10 00 00 00       	mov    $0x10,%eax
f0101283:	eb a6                	jmp    f010122b <vprintfmt+0x41f>
		return va_arg(*ap, unsigned int);
f0101285:	8b 45 14             	mov    0x14(%ebp),%eax
f0101288:	8b 10                	mov    (%eax),%edx
f010128a:	b9 00 00 00 00       	mov    $0x0,%ecx
f010128f:	8d 40 04             	lea    0x4(%eax),%eax
f0101292:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101295:	b8 10 00 00 00       	mov    $0x10,%eax
f010129a:	eb 8f                	jmp    f010122b <vprintfmt+0x41f>
f010129c:	89 4d 10             	mov    %ecx,0x10(%ebp)
			putch(ch, putdat);
f010129f:	83 ec 08             	sub    $0x8,%esp
f01012a2:	53                   	push   %ebx
f01012a3:	6a 25                	push   $0x25
f01012a5:	ff d7                	call   *%edi
			break;
f01012a7:	83 c4 10             	add    $0x10,%esp
f01012aa:	e9 6e fb ff ff       	jmp    f0100e1d <vprintfmt+0x11>
			putch('%', putdat);
f01012af:	83 ec 08             	sub    $0x8,%esp
f01012b2:	53                   	push   %ebx
f01012b3:	6a 25                	push   $0x25
f01012b5:	ff d7                	call   *%edi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01012b7:	83 c4 10             	add    $0x10,%esp
f01012ba:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01012be:	0f 84 8d fb ff ff    	je     f0100e51 <vprintfmt+0x45>
f01012c4:	89 75 10             	mov    %esi,0x10(%ebp)
f01012c7:	89 f0                	mov    %esi,%eax
f01012c9:	83 e8 01             	sub    $0x1,%eax
f01012cc:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01012d0:	75 f7                	jne    f01012c9 <vprintfmt+0x4bd>
f01012d2:	89 45 10             	mov    %eax,0x10(%ebp)
f01012d5:	e9 43 fb ff ff       	jmp    f0100e1d <vprintfmt+0x11>
			if ((p = va_arg(ap, char *)) == NULL)
f01012da:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01012dd:	89 45 14             	mov    %eax,0x14(%ebp)
f01012e0:	e9 38 fb ff ff       	jmp    f0100e1d <vprintfmt+0x11>
			if (width > 0 && padc != '-')
f01012e5:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01012e9:	7e 06                	jle    f01012f1 <vprintfmt+0x4e5>
f01012eb:	80 7d e3 2d          	cmpb   $0x2d,-0x1d(%ebp)
f01012ef:	75 20                	jne    f0101311 <vprintfmt+0x505>
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01012f1:	ba 28 00 00 00       	mov    $0x28,%edx
f01012f6:	be bb 20 10 f0       	mov    $0xf01020bb,%esi
f01012fb:	b8 28 00 00 00       	mov    $0x28,%eax
f0101300:	89 7d 08             	mov    %edi,0x8(%ebp)
f0101303:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101306:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101309:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010130c:	e9 47 fd ff ff       	jmp    f0101058 <vprintfmt+0x24c>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101311:	83 ec 08             	sub    $0x8,%esp
f0101314:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101317:	68 ba 20 10 f0       	push   $0xf01020ba
f010131c:	e8 a4 01 00 00       	call   f01014c5 <strnlen>
f0101321:	29 45 e4             	sub    %eax,-0x1c(%ebp)
f0101324:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101327:	83 c4 10             	add    $0x10,%esp
				p = "(null)";
f010132a:	c7 45 cc ba 20 10 f0 	movl   $0xf01020ba,-0x34(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0101331:	85 c9                	test   %ecx,%ecx
f0101333:	0f 8f cb fc ff ff    	jg     f0101004 <vprintfmt+0x1f8>
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101339:	be bb 20 10 f0       	mov    $0xf01020bb,%esi
f010133e:	ba 28 00 00 00       	mov    $0x28,%edx
f0101343:	b8 28 00 00 00       	mov    $0x28,%eax
f0101348:	89 7d 08             	mov    %edi,0x8(%ebp)
f010134b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010134e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101351:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0101354:	e9 ff fc ff ff       	jmp    f0101058 <vprintfmt+0x24c>

f0101359 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101359:	55                   	push   %ebp
f010135a:	89 e5                	mov    %esp,%ebp
f010135c:	83 ec 18             	sub    $0x18,%esp
f010135f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101362:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101365:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101368:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010136c:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010136f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101376:	85 c0                	test   %eax,%eax
f0101378:	74 26                	je     f01013a0 <vsnprintf+0x47>
f010137a:	85 d2                	test   %edx,%edx
f010137c:	7e 22                	jle    f01013a0 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010137e:	ff 75 14             	pushl  0x14(%ebp)
f0101381:	ff 75 10             	pushl  0x10(%ebp)
f0101384:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101387:	50                   	push   %eax
f0101388:	68 d2 0d 10 f0       	push   $0xf0100dd2
f010138d:	e8 7a fa ff ff       	call   f0100e0c <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101392:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101395:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101398:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010139b:	83 c4 10             	add    $0x10,%esp
}
f010139e:	c9                   	leave  
f010139f:	c3                   	ret    
		return -E_INVAL;
f01013a0:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01013a5:	eb f7                	jmp    f010139e <vsnprintf+0x45>

f01013a7 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01013a7:	55                   	push   %ebp
f01013a8:	89 e5                	mov    %esp,%ebp
f01013aa:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01013ad:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01013b0:	50                   	push   %eax
f01013b1:	ff 75 10             	pushl  0x10(%ebp)
f01013b4:	ff 75 0c             	pushl  0xc(%ebp)
f01013b7:	ff 75 08             	pushl  0x8(%ebp)
f01013ba:	e8 9a ff ff ff       	call   f0101359 <vsnprintf>
	va_end(ap);

	return rc;
}
f01013bf:	c9                   	leave  
f01013c0:	c3                   	ret    

f01013c1 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01013c1:	55                   	push   %ebp
f01013c2:	89 e5                	mov    %esp,%ebp
f01013c4:	57                   	push   %edi
f01013c5:	56                   	push   %esi
f01013c6:	53                   	push   %ebx
f01013c7:	83 ec 0c             	sub    $0xc,%esp
f01013ca:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01013cd:	85 c0                	test   %eax,%eax
f01013cf:	74 11                	je     f01013e2 <readline+0x21>
		cprintf("%s", prompt);
f01013d1:	83 ec 08             	sub    $0x8,%esp
f01013d4:	50                   	push   %eax
f01013d5:	68 ca 20 10 f0       	push   $0xf01020ca
f01013da:	e8 97 f5 ff ff       	call   f0100976 <cprintf>
f01013df:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01013e2:	83 ec 0c             	sub    $0xc,%esp
f01013e5:	6a 00                	push   $0x0
f01013e7:	e8 8a f2 ff ff       	call   f0100676 <iscons>
f01013ec:	89 c7                	mov    %eax,%edi
f01013ee:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01013f1:	be 00 00 00 00       	mov    $0x0,%esi
f01013f6:	eb 4b                	jmp    f0101443 <readline+0x82>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f01013f8:	83 ec 08             	sub    $0x8,%esp
f01013fb:	50                   	push   %eax
f01013fc:	68 ac 22 10 f0       	push   $0xf01022ac
f0101401:	e8 70 f5 ff ff       	call   f0100976 <cprintf>
			return NULL;
f0101406:	83 c4 10             	add    $0x10,%esp
f0101409:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f010140e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101411:	5b                   	pop    %ebx
f0101412:	5e                   	pop    %esi
f0101413:	5f                   	pop    %edi
f0101414:	5d                   	pop    %ebp
f0101415:	c3                   	ret    
			if (echoing)
f0101416:	85 ff                	test   %edi,%edi
f0101418:	75 05                	jne    f010141f <readline+0x5e>
			i--;
f010141a:	83 ee 01             	sub    $0x1,%esi
f010141d:	eb 24                	jmp    f0101443 <readline+0x82>
				cputchar('\b');
f010141f:	83 ec 0c             	sub    $0xc,%esp
f0101422:	6a 08                	push   $0x8
f0101424:	e8 2c f2 ff ff       	call   f0100655 <cputchar>
f0101429:	83 c4 10             	add    $0x10,%esp
f010142c:	eb ec                	jmp    f010141a <readline+0x59>
				cputchar(c);
f010142e:	83 ec 0c             	sub    $0xc,%esp
f0101431:	53                   	push   %ebx
f0101432:	e8 1e f2 ff ff       	call   f0100655 <cputchar>
f0101437:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010143a:	88 9e 40 35 11 f0    	mov    %bl,-0xfeecac0(%esi)
f0101440:	8d 76 01             	lea    0x1(%esi),%esi
		c = getchar();
f0101443:	e8 1d f2 ff ff       	call   f0100665 <getchar>
f0101448:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010144a:	85 c0                	test   %eax,%eax
f010144c:	78 aa                	js     f01013f8 <readline+0x37>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010144e:	83 f8 08             	cmp    $0x8,%eax
f0101451:	0f 94 c2             	sete   %dl
f0101454:	83 f8 7f             	cmp    $0x7f,%eax
f0101457:	0f 94 c0             	sete   %al
f010145a:	08 c2                	or     %al,%dl
f010145c:	74 04                	je     f0101462 <readline+0xa1>
f010145e:	85 f6                	test   %esi,%esi
f0101460:	7f b4                	jg     f0101416 <readline+0x55>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101462:	83 fb 1f             	cmp    $0x1f,%ebx
f0101465:	7e 0e                	jle    f0101475 <readline+0xb4>
f0101467:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010146d:	7f 06                	jg     f0101475 <readline+0xb4>
			if (echoing)
f010146f:	85 ff                	test   %edi,%edi
f0101471:	74 c7                	je     f010143a <readline+0x79>
f0101473:	eb b9                	jmp    f010142e <readline+0x6d>
		} else if (c == '\n' || c == '\r') {
f0101475:	83 fb 0a             	cmp    $0xa,%ebx
f0101478:	74 05                	je     f010147f <readline+0xbe>
f010147a:	83 fb 0d             	cmp    $0xd,%ebx
f010147d:	75 c4                	jne    f0101443 <readline+0x82>
			if (echoing)
f010147f:	85 ff                	test   %edi,%edi
f0101481:	75 11                	jne    f0101494 <readline+0xd3>
			buf[i] = 0;
f0101483:	c6 86 40 35 11 f0 00 	movb   $0x0,-0xfeecac0(%esi)
			return buf;
f010148a:	b8 40 35 11 f0       	mov    $0xf0113540,%eax
f010148f:	e9 7a ff ff ff       	jmp    f010140e <readline+0x4d>
				cputchar('\n');
f0101494:	83 ec 0c             	sub    $0xc,%esp
f0101497:	6a 0a                	push   $0xa
f0101499:	e8 b7 f1 ff ff       	call   f0100655 <cputchar>
f010149e:	83 c4 10             	add    $0x10,%esp
f01014a1:	eb e0                	jmp    f0101483 <readline+0xc2>

f01014a3 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01014a3:	55                   	push   %ebp
f01014a4:	89 e5                	mov    %esp,%ebp
f01014a6:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01014a9:	80 3a 00             	cmpb   $0x0,(%edx)
f01014ac:	74 10                	je     f01014be <strlen+0x1b>
f01014ae:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f01014b3:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f01014b6:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01014ba:	75 f7                	jne    f01014b3 <strlen+0x10>
	return n;
}
f01014bc:	5d                   	pop    %ebp
f01014bd:	c3                   	ret    
	for (n = 0; *s != '\0'; s++)
f01014be:	b8 00 00 00 00       	mov    $0x0,%eax
	return n;
f01014c3:	eb f7                	jmp    f01014bc <strlen+0x19>

f01014c5 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01014c5:	55                   	push   %ebp
f01014c6:	89 e5                	mov    %esp,%ebp
f01014c8:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014cb:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014ce:	85 d2                	test   %edx,%edx
f01014d0:	74 19                	je     f01014eb <strnlen+0x26>
f01014d2:	80 39 00             	cmpb   $0x0,(%ecx)
f01014d5:	74 1b                	je     f01014f2 <strnlen+0x2d>
f01014d7:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f01014dc:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014df:	39 c2                	cmp    %eax,%edx
f01014e1:	74 06                	je     f01014e9 <strnlen+0x24>
f01014e3:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01014e7:	75 f3                	jne    f01014dc <strnlen+0x17>
	return n;
}
f01014e9:	5d                   	pop    %ebp
f01014ea:	c3                   	ret    
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014eb:	b8 00 00 00 00       	mov    $0x0,%eax
f01014f0:	eb f7                	jmp    f01014e9 <strnlen+0x24>
f01014f2:	b8 00 00 00 00       	mov    $0x0,%eax
	return n;
f01014f7:	eb f0                	jmp    f01014e9 <strnlen+0x24>

f01014f9 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01014f9:	55                   	push   %ebp
f01014fa:	89 e5                	mov    %esp,%ebp
f01014fc:	53                   	push   %ebx
f01014fd:	8b 45 08             	mov    0x8(%ebp),%eax
f0101500:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101503:	ba 00 00 00 00       	mov    $0x0,%edx
f0101508:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010150c:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f010150f:	83 c2 01             	add    $0x1,%edx
f0101512:	84 c9                	test   %cl,%cl
f0101514:	75 f2                	jne    f0101508 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0101516:	5b                   	pop    %ebx
f0101517:	5d                   	pop    %ebp
f0101518:	c3                   	ret    

f0101519 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101519:	55                   	push   %ebp
f010151a:	89 e5                	mov    %esp,%ebp
f010151c:	53                   	push   %ebx
f010151d:	83 ec 10             	sub    $0x10,%esp
f0101520:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101523:	53                   	push   %ebx
f0101524:	e8 7a ff ff ff       	call   f01014a3 <strlen>
f0101529:	83 c4 08             	add    $0x8,%esp
	strcpy(dst + len, src);
f010152c:	ff 75 0c             	pushl  0xc(%ebp)
f010152f:	01 d8                	add    %ebx,%eax
f0101531:	50                   	push   %eax
f0101532:	e8 c2 ff ff ff       	call   f01014f9 <strcpy>
	return dst;
}
f0101537:	89 d8                	mov    %ebx,%eax
f0101539:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010153c:	c9                   	leave  
f010153d:	c3                   	ret    

f010153e <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010153e:	55                   	push   %ebp
f010153f:	89 e5                	mov    %esp,%ebp
f0101541:	56                   	push   %esi
f0101542:	53                   	push   %ebx
f0101543:	8b 45 08             	mov    0x8(%ebp),%eax
f0101546:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101549:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010154c:	85 f6                	test   %esi,%esi
f010154e:	74 17                	je     f0101567 <strncpy+0x29>
f0101550:	01 c6                	add    %eax,%esi
f0101552:	89 c2                	mov    %eax,%edx
		*dst++ = *src;
f0101554:	83 c2 01             	add    $0x1,%edx
f0101557:	0f b6 0b             	movzbl (%ebx),%ecx
f010155a:	88 4a ff             	mov    %cl,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010155d:	80 f9 01             	cmp    $0x1,%cl
f0101560:	83 db ff             	sbb    $0xffffffff,%ebx
	for (i = 0; i < size; i++) {
f0101563:	39 d6                	cmp    %edx,%esi
f0101565:	75 ed                	jne    f0101554 <strncpy+0x16>
	}
	return ret;
}
f0101567:	5b                   	pop    %ebx
f0101568:	5e                   	pop    %esi
f0101569:	5d                   	pop    %ebp
f010156a:	c3                   	ret    

f010156b <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010156b:	55                   	push   %ebp
f010156c:	89 e5                	mov    %esp,%ebp
f010156e:	57                   	push   %edi
f010156f:	56                   	push   %esi
f0101570:	53                   	push   %ebx
f0101571:	8b 75 08             	mov    0x8(%ebp),%esi
f0101574:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101577:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010157a:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010157c:	85 db                	test   %ebx,%ebx
f010157e:	74 2b                	je     f01015ab <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f0101580:	83 fb 01             	cmp    $0x1,%ebx
f0101583:	74 23                	je     f01015a8 <strlcpy+0x3d>
f0101585:	0f b6 0f             	movzbl (%edi),%ecx
f0101588:	84 c9                	test   %cl,%cl
f010158a:	74 1c                	je     f01015a8 <strlcpy+0x3d>
f010158c:	8d 57 01             	lea    0x1(%edi),%edx
f010158f:	8d 5c 1f ff          	lea    -0x1(%edi,%ebx,1),%ebx
			*dst++ = *src++;
f0101593:	83 c0 01             	add    $0x1,%eax
f0101596:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0101599:	39 da                	cmp    %ebx,%edx
f010159b:	74 0b                	je     f01015a8 <strlcpy+0x3d>
f010159d:	83 c2 01             	add    $0x1,%edx
f01015a0:	0f b6 4a ff          	movzbl -0x1(%edx),%ecx
f01015a4:	84 c9                	test   %cl,%cl
f01015a6:	75 eb                	jne    f0101593 <strlcpy+0x28>
		*dst = '\0';
f01015a8:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01015ab:	29 f0                	sub    %esi,%eax
}
f01015ad:	5b                   	pop    %ebx
f01015ae:	5e                   	pop    %esi
f01015af:	5f                   	pop    %edi
f01015b0:	5d                   	pop    %ebp
f01015b1:	c3                   	ret    

f01015b2 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01015b2:	55                   	push   %ebp
f01015b3:	89 e5                	mov    %esp,%ebp
f01015b5:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015b8:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01015bb:	0f b6 01             	movzbl (%ecx),%eax
f01015be:	84 c0                	test   %al,%al
f01015c0:	74 15                	je     f01015d7 <strcmp+0x25>
f01015c2:	3a 02                	cmp    (%edx),%al
f01015c4:	75 11                	jne    f01015d7 <strcmp+0x25>
		p++, q++;
f01015c6:	83 c1 01             	add    $0x1,%ecx
f01015c9:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f01015cc:	0f b6 01             	movzbl (%ecx),%eax
f01015cf:	84 c0                	test   %al,%al
f01015d1:	74 04                	je     f01015d7 <strcmp+0x25>
f01015d3:	3a 02                	cmp    (%edx),%al
f01015d5:	74 ef                	je     f01015c6 <strcmp+0x14>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01015d7:	0f b6 c0             	movzbl %al,%eax
f01015da:	0f b6 12             	movzbl (%edx),%edx
f01015dd:	29 d0                	sub    %edx,%eax
}
f01015df:	5d                   	pop    %ebp
f01015e0:	c3                   	ret    

f01015e1 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01015e1:	55                   	push   %ebp
f01015e2:	89 e5                	mov    %esp,%ebp
f01015e4:	53                   	push   %ebx
f01015e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01015e8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01015eb:	8b 5d 10             	mov    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01015ee:	85 db                	test   %ebx,%ebx
f01015f0:	74 2d                	je     f010161f <strncmp+0x3e>
f01015f2:	0f b6 08             	movzbl (%eax),%ecx
f01015f5:	84 c9                	test   %cl,%cl
f01015f7:	74 1b                	je     f0101614 <strncmp+0x33>
f01015f9:	3a 0a                	cmp    (%edx),%cl
f01015fb:	75 17                	jne    f0101614 <strncmp+0x33>
f01015fd:	01 c3                	add    %eax,%ebx
		n--, p++, q++;
f01015ff:	83 c0 01             	add    $0x1,%eax
f0101602:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0101605:	39 d8                	cmp    %ebx,%eax
f0101607:	74 1d                	je     f0101626 <strncmp+0x45>
f0101609:	0f b6 08             	movzbl (%eax),%ecx
f010160c:	84 c9                	test   %cl,%cl
f010160e:	74 04                	je     f0101614 <strncmp+0x33>
f0101610:	3a 0a                	cmp    (%edx),%cl
f0101612:	74 eb                	je     f01015ff <strncmp+0x1e>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101614:	0f b6 00             	movzbl (%eax),%eax
f0101617:	0f b6 12             	movzbl (%edx),%edx
f010161a:	29 d0                	sub    %edx,%eax
}
f010161c:	5b                   	pop    %ebx
f010161d:	5d                   	pop    %ebp
f010161e:	c3                   	ret    
		return 0;
f010161f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101624:	eb f6                	jmp    f010161c <strncmp+0x3b>
f0101626:	b8 00 00 00 00       	mov    $0x0,%eax
f010162b:	eb ef                	jmp    f010161c <strncmp+0x3b>

f010162d <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010162d:	55                   	push   %ebp
f010162e:	89 e5                	mov    %esp,%ebp
f0101630:	53                   	push   %ebx
f0101631:	8b 45 08             	mov    0x8(%ebp),%eax
f0101634:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	for (; *s; s++)
f0101637:	0f b6 10             	movzbl (%eax),%edx
f010163a:	84 d2                	test   %dl,%dl
f010163c:	74 1e                	je     f010165c <strchr+0x2f>
f010163e:	89 d9                	mov    %ebx,%ecx
		if (*s == c)
f0101640:	38 d3                	cmp    %dl,%bl
f0101642:	74 15                	je     f0101659 <strchr+0x2c>
	for (; *s; s++)
f0101644:	83 c0 01             	add    $0x1,%eax
f0101647:	0f b6 10             	movzbl (%eax),%edx
f010164a:	84 d2                	test   %dl,%dl
f010164c:	74 06                	je     f0101654 <strchr+0x27>
		if (*s == c)
f010164e:	38 ca                	cmp    %cl,%dl
f0101650:	75 f2                	jne    f0101644 <strchr+0x17>
f0101652:	eb 05                	jmp    f0101659 <strchr+0x2c>
			return (char *) s;
	return 0;
f0101654:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101659:	5b                   	pop    %ebx
f010165a:	5d                   	pop    %ebp
f010165b:	c3                   	ret    
	return 0;
f010165c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101661:	eb f6                	jmp    f0101659 <strchr+0x2c>

f0101663 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101663:	55                   	push   %ebp
f0101664:	89 e5                	mov    %esp,%ebp
f0101666:	53                   	push   %ebx
f0101667:	8b 45 08             	mov    0x8(%ebp),%eax
f010166a:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f010166d:	0f b6 18             	movzbl (%eax),%ebx
		if (*s == c)
f0101670:	38 d3                	cmp    %dl,%bl
f0101672:	74 14                	je     f0101688 <strfind+0x25>
f0101674:	89 d1                	mov    %edx,%ecx
f0101676:	84 db                	test   %bl,%bl
f0101678:	74 0e                	je     f0101688 <strfind+0x25>
	for (; *s; s++)
f010167a:	83 c0 01             	add    $0x1,%eax
f010167d:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101680:	38 ca                	cmp    %cl,%dl
f0101682:	74 04                	je     f0101688 <strfind+0x25>
f0101684:	84 d2                	test   %dl,%dl
f0101686:	75 f2                	jne    f010167a <strfind+0x17>
			break;
	return (char *) s;
}
f0101688:	5b                   	pop    %ebx
f0101689:	5d                   	pop    %ebp
f010168a:	c3                   	ret    

f010168b <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010168b:	55                   	push   %ebp
f010168c:	89 e5                	mov    %esp,%ebp
f010168e:	57                   	push   %edi
f010168f:	56                   	push   %esi
f0101690:	53                   	push   %ebx
f0101691:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101694:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101697:	85 c9                	test   %ecx,%ecx
f0101699:	74 31                	je     f01016cc <memset+0x41>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010169b:	89 f8                	mov    %edi,%eax
f010169d:	09 c8                	or     %ecx,%eax
f010169f:	a8 03                	test   $0x3,%al
f01016a1:	75 23                	jne    f01016c6 <memset+0x3b>
		c &= 0xFF;
f01016a3:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01016a7:	89 d3                	mov    %edx,%ebx
f01016a9:	c1 e3 08             	shl    $0x8,%ebx
f01016ac:	89 d0                	mov    %edx,%eax
f01016ae:	c1 e0 18             	shl    $0x18,%eax
f01016b1:	89 d6                	mov    %edx,%esi
f01016b3:	c1 e6 10             	shl    $0x10,%esi
f01016b6:	09 f0                	or     %esi,%eax
f01016b8:	09 c2                	or     %eax,%edx
f01016ba:	09 da                	or     %ebx,%edx
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01016bc:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f01016bf:	89 d0                	mov    %edx,%eax
f01016c1:	fc                   	cld    
f01016c2:	f3 ab                	rep stos %eax,%es:(%edi)
f01016c4:	eb 06                	jmp    f01016cc <memset+0x41>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01016c6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016c9:	fc                   	cld    
f01016ca:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01016cc:	89 f8                	mov    %edi,%eax
f01016ce:	5b                   	pop    %ebx
f01016cf:	5e                   	pop    %esi
f01016d0:	5f                   	pop    %edi
f01016d1:	5d                   	pop    %ebp
f01016d2:	c3                   	ret    

f01016d3 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01016d3:	55                   	push   %ebp
f01016d4:	89 e5                	mov    %esp,%ebp
f01016d6:	57                   	push   %edi
f01016d7:	56                   	push   %esi
f01016d8:	8b 45 08             	mov    0x8(%ebp),%eax
f01016db:	8b 75 0c             	mov    0xc(%ebp),%esi
f01016de:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01016e1:	39 c6                	cmp    %eax,%esi
f01016e3:	73 32                	jae    f0101717 <memmove+0x44>
f01016e5:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01016e8:	39 c2                	cmp    %eax,%edx
f01016ea:	76 2b                	jbe    f0101717 <memmove+0x44>
		s += n;
		d += n;
f01016ec:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016ef:	89 fe                	mov    %edi,%esi
f01016f1:	09 ce                	or     %ecx,%esi
f01016f3:	09 d6                	or     %edx,%esi
f01016f5:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01016fb:	75 0e                	jne    f010170b <memmove+0x38>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01016fd:	83 ef 04             	sub    $0x4,%edi
f0101700:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101703:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0101706:	fd                   	std    
f0101707:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101709:	eb 09                	jmp    f0101714 <memmove+0x41>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010170b:	83 ef 01             	sub    $0x1,%edi
f010170e:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0101711:	fd                   	std    
f0101712:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101714:	fc                   	cld    
f0101715:	eb 1a                	jmp    f0101731 <memmove+0x5e>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101717:	89 c2                	mov    %eax,%edx
f0101719:	09 ca                	or     %ecx,%edx
f010171b:	09 f2                	or     %esi,%edx
f010171d:	f6 c2 03             	test   $0x3,%dl
f0101720:	75 0a                	jne    f010172c <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101722:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0101725:	89 c7                	mov    %eax,%edi
f0101727:	fc                   	cld    
f0101728:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010172a:	eb 05                	jmp    f0101731 <memmove+0x5e>
		else
			asm volatile("cld; rep movsb\n"
f010172c:	89 c7                	mov    %eax,%edi
f010172e:	fc                   	cld    
f010172f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101731:	5e                   	pop    %esi
f0101732:	5f                   	pop    %edi
f0101733:	5d                   	pop    %ebp
f0101734:	c3                   	ret    

f0101735 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101735:	55                   	push   %ebp
f0101736:	89 e5                	mov    %esp,%ebp
f0101738:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010173b:	ff 75 10             	pushl  0x10(%ebp)
f010173e:	ff 75 0c             	pushl  0xc(%ebp)
f0101741:	ff 75 08             	pushl  0x8(%ebp)
f0101744:	e8 8a ff ff ff       	call   f01016d3 <memmove>
}
f0101749:	c9                   	leave  
f010174a:	c3                   	ret    

f010174b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010174b:	55                   	push   %ebp
f010174c:	89 e5                	mov    %esp,%ebp
f010174e:	56                   	push   %esi
f010174f:	53                   	push   %ebx
f0101750:	8b 45 08             	mov    0x8(%ebp),%eax
f0101753:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101756:	8b 75 10             	mov    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101759:	85 f6                	test   %esi,%esi
f010175b:	74 33                	je     f0101790 <memcmp+0x45>
		if (*s1 != *s2)
f010175d:	0f b6 08             	movzbl (%eax),%ecx
f0101760:	0f b6 1a             	movzbl (%edx),%ebx
f0101763:	01 c6                	add    %eax,%esi
f0101765:	38 d9                	cmp    %bl,%cl
f0101767:	75 14                	jne    f010177d <memcmp+0x32>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0101769:	83 c0 01             	add    $0x1,%eax
f010176c:	83 c2 01             	add    $0x1,%edx
	while (n-- > 0) {
f010176f:	39 c6                	cmp    %eax,%esi
f0101771:	74 16                	je     f0101789 <memcmp+0x3e>
		if (*s1 != *s2)
f0101773:	0f b6 08             	movzbl (%eax),%ecx
f0101776:	0f b6 1a             	movzbl (%edx),%ebx
f0101779:	38 d9                	cmp    %bl,%cl
f010177b:	74 ec                	je     f0101769 <memcmp+0x1e>
			return (int) *s1 - (int) *s2;
f010177d:	0f b6 c1             	movzbl %cl,%eax
f0101780:	0f b6 db             	movzbl %bl,%ebx
f0101783:	29 d8                	sub    %ebx,%eax
	}

	return 0;
}
f0101785:	5b                   	pop    %ebx
f0101786:	5e                   	pop    %esi
f0101787:	5d                   	pop    %ebp
f0101788:	c3                   	ret    
	return 0;
f0101789:	b8 00 00 00 00       	mov    $0x0,%eax
f010178e:	eb f5                	jmp    f0101785 <memcmp+0x3a>
f0101790:	b8 00 00 00 00       	mov    $0x0,%eax
f0101795:	eb ee                	jmp    f0101785 <memcmp+0x3a>

f0101797 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101797:	55                   	push   %ebp
f0101798:	89 e5                	mov    %esp,%ebp
f010179a:	53                   	push   %ebx
f010179b:	8b 55 08             	mov    0x8(%ebp),%edx
f010179e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f01017a1:	89 d0                	mov    %edx,%eax
f01017a3:	03 45 10             	add    0x10(%ebp),%eax
	for (; s < ends; s++)
f01017a6:	39 c2                	cmp    %eax,%edx
f01017a8:	73 16                	jae    f01017c0 <memfind+0x29>
		if (*(const unsigned char *) s == (unsigned char) c)
f01017aa:	89 d9                	mov    %ebx,%ecx
f01017ac:	38 1a                	cmp    %bl,(%edx)
f01017ae:	74 14                	je     f01017c4 <memfind+0x2d>
	for (; s < ends; s++)
f01017b0:	83 c2 01             	add    $0x1,%edx
f01017b3:	39 d0                	cmp    %edx,%eax
f01017b5:	74 06                	je     f01017bd <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
f01017b7:	38 0a                	cmp    %cl,(%edx)
f01017b9:	75 f5                	jne    f01017b0 <memfind+0x19>
	for (; s < ends; s++)
f01017bb:	89 d0                	mov    %edx,%eax
			break;
	return (void *) s;
}
f01017bd:	5b                   	pop    %ebx
f01017be:	5d                   	pop    %ebp
f01017bf:	c3                   	ret    
	for (; s < ends; s++)
f01017c0:	89 d0                	mov    %edx,%eax
f01017c2:	eb f9                	jmp    f01017bd <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
f01017c4:	89 d0                	mov    %edx,%eax
f01017c6:	eb f5                	jmp    f01017bd <memfind+0x26>

f01017c8 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01017c8:	55                   	push   %ebp
f01017c9:	89 e5                	mov    %esp,%ebp
f01017cb:	57                   	push   %edi
f01017cc:	56                   	push   %esi
f01017cd:	53                   	push   %ebx
f01017ce:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01017d1:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01017d4:	0f b6 01             	movzbl (%ecx),%eax
f01017d7:	3c 20                	cmp    $0x20,%al
f01017d9:	74 04                	je     f01017df <strtol+0x17>
f01017db:	3c 09                	cmp    $0x9,%al
f01017dd:	75 0e                	jne    f01017ed <strtol+0x25>
		s++;
f01017df:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f01017e2:	0f b6 01             	movzbl (%ecx),%eax
f01017e5:	3c 20                	cmp    $0x20,%al
f01017e7:	74 f6                	je     f01017df <strtol+0x17>
f01017e9:	3c 09                	cmp    $0x9,%al
f01017eb:	74 f2                	je     f01017df <strtol+0x17>

	// plus/minus sign
	if (*s == '+')
f01017ed:	3c 2b                	cmp    $0x2b,%al
f01017ef:	74 2a                	je     f010181b <strtol+0x53>
	int neg = 0;
f01017f1:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f01017f6:	3c 2d                	cmp    $0x2d,%al
f01017f8:	74 2b                	je     f0101825 <strtol+0x5d>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01017fa:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101800:	75 0f                	jne    f0101811 <strtol+0x49>
f0101802:	80 39 30             	cmpb   $0x30,(%ecx)
f0101805:	74 28                	je     f010182f <strtol+0x67>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101807:	85 db                	test   %ebx,%ebx
f0101809:	b8 0a 00 00 00       	mov    $0xa,%eax
f010180e:	0f 44 d8             	cmove  %eax,%ebx
f0101811:	b8 00 00 00 00       	mov    $0x0,%eax
f0101816:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101819:	eb 50                	jmp    f010186b <strtol+0xa3>
		s++;
f010181b:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f010181e:	bf 00 00 00 00       	mov    $0x0,%edi
f0101823:	eb d5                	jmp    f01017fa <strtol+0x32>
		s++, neg = 1;
f0101825:	83 c1 01             	add    $0x1,%ecx
f0101828:	bf 01 00 00 00       	mov    $0x1,%edi
f010182d:	eb cb                	jmp    f01017fa <strtol+0x32>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010182f:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101833:	74 0e                	je     f0101843 <strtol+0x7b>
	else if (base == 0 && s[0] == '0')
f0101835:	85 db                	test   %ebx,%ebx
f0101837:	75 d8                	jne    f0101811 <strtol+0x49>
		s++, base = 8;
f0101839:	83 c1 01             	add    $0x1,%ecx
f010183c:	bb 08 00 00 00       	mov    $0x8,%ebx
f0101841:	eb ce                	jmp    f0101811 <strtol+0x49>
		s += 2, base = 16;
f0101843:	83 c1 02             	add    $0x2,%ecx
f0101846:	bb 10 00 00 00       	mov    $0x10,%ebx
f010184b:	eb c4                	jmp    f0101811 <strtol+0x49>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f010184d:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101850:	89 f3                	mov    %esi,%ebx
f0101852:	80 fb 19             	cmp    $0x19,%bl
f0101855:	77 29                	ja     f0101880 <strtol+0xb8>
			dig = *s - 'a' + 10;
f0101857:	0f be d2             	movsbl %dl,%edx
f010185a:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f010185d:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101860:	7d 30                	jge    f0101892 <strtol+0xca>
			break;
		s++, val = (val * base) + dig;
f0101862:	83 c1 01             	add    $0x1,%ecx
f0101865:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101869:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f010186b:	0f b6 11             	movzbl (%ecx),%edx
f010186e:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101871:	89 f3                	mov    %esi,%ebx
f0101873:	80 fb 09             	cmp    $0x9,%bl
f0101876:	77 d5                	ja     f010184d <strtol+0x85>
			dig = *s - '0';
f0101878:	0f be d2             	movsbl %dl,%edx
f010187b:	83 ea 30             	sub    $0x30,%edx
f010187e:	eb dd                	jmp    f010185d <strtol+0x95>
		else if (*s >= 'A' && *s <= 'Z')
f0101880:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101883:	89 f3                	mov    %esi,%ebx
f0101885:	80 fb 19             	cmp    $0x19,%bl
f0101888:	77 08                	ja     f0101892 <strtol+0xca>
			dig = *s - 'A' + 10;
f010188a:	0f be d2             	movsbl %dl,%edx
f010188d:	83 ea 37             	sub    $0x37,%edx
f0101890:	eb cb                	jmp    f010185d <strtol+0x95>
		// we don't properly detect overflow!
	}

	if (endptr)
f0101892:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101896:	74 05                	je     f010189d <strtol+0xd5>
		*endptr = (char *) s;
f0101898:	8b 75 0c             	mov    0xc(%ebp),%esi
f010189b:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f010189d:	89 c2                	mov    %eax,%edx
f010189f:	f7 da                	neg    %edx
f01018a1:	85 ff                	test   %edi,%edi
f01018a3:	0f 45 c2             	cmovne %edx,%eax
}
f01018a6:	5b                   	pop    %ebx
f01018a7:	5e                   	pop    %esi
f01018a8:	5f                   	pop    %edi
f01018a9:	5d                   	pop    %ebp
f01018aa:	c3                   	ret    
f01018ab:	66 90                	xchg   %ax,%ax
f01018ad:	66 90                	xchg   %ax,%ax
f01018af:	90                   	nop

f01018b0 <__udivdi3>:
f01018b0:	f3 0f 1e fb          	endbr32 
f01018b4:	55                   	push   %ebp
f01018b5:	57                   	push   %edi
f01018b6:	56                   	push   %esi
f01018b7:	53                   	push   %ebx
f01018b8:	83 ec 1c             	sub    $0x1c,%esp
f01018bb:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01018bf:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01018c3:	8b 74 24 34          	mov    0x34(%esp),%esi
f01018c7:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f01018cb:	85 d2                	test   %edx,%edx
f01018cd:	75 49                	jne    f0101918 <__udivdi3+0x68>
f01018cf:	39 f3                	cmp    %esi,%ebx
f01018d1:	76 15                	jbe    f01018e8 <__udivdi3+0x38>
f01018d3:	31 ff                	xor    %edi,%edi
f01018d5:	89 e8                	mov    %ebp,%eax
f01018d7:	89 f2                	mov    %esi,%edx
f01018d9:	f7 f3                	div    %ebx
f01018db:	89 fa                	mov    %edi,%edx
f01018dd:	83 c4 1c             	add    $0x1c,%esp
f01018e0:	5b                   	pop    %ebx
f01018e1:	5e                   	pop    %esi
f01018e2:	5f                   	pop    %edi
f01018e3:	5d                   	pop    %ebp
f01018e4:	c3                   	ret    
f01018e5:	8d 76 00             	lea    0x0(%esi),%esi
f01018e8:	89 d9                	mov    %ebx,%ecx
f01018ea:	85 db                	test   %ebx,%ebx
f01018ec:	75 0b                	jne    f01018f9 <__udivdi3+0x49>
f01018ee:	b8 01 00 00 00       	mov    $0x1,%eax
f01018f3:	31 d2                	xor    %edx,%edx
f01018f5:	f7 f3                	div    %ebx
f01018f7:	89 c1                	mov    %eax,%ecx
f01018f9:	31 d2                	xor    %edx,%edx
f01018fb:	89 f0                	mov    %esi,%eax
f01018fd:	f7 f1                	div    %ecx
f01018ff:	89 c6                	mov    %eax,%esi
f0101901:	89 e8                	mov    %ebp,%eax
f0101903:	89 f7                	mov    %esi,%edi
f0101905:	f7 f1                	div    %ecx
f0101907:	89 fa                	mov    %edi,%edx
f0101909:	83 c4 1c             	add    $0x1c,%esp
f010190c:	5b                   	pop    %ebx
f010190d:	5e                   	pop    %esi
f010190e:	5f                   	pop    %edi
f010190f:	5d                   	pop    %ebp
f0101910:	c3                   	ret    
f0101911:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101918:	39 f2                	cmp    %esi,%edx
f010191a:	77 1c                	ja     f0101938 <__udivdi3+0x88>
f010191c:	0f bd fa             	bsr    %edx,%edi
f010191f:	83 f7 1f             	xor    $0x1f,%edi
f0101922:	75 2c                	jne    f0101950 <__udivdi3+0xa0>
f0101924:	39 f2                	cmp    %esi,%edx
f0101926:	72 06                	jb     f010192e <__udivdi3+0x7e>
f0101928:	31 c0                	xor    %eax,%eax
f010192a:	39 eb                	cmp    %ebp,%ebx
f010192c:	77 ad                	ja     f01018db <__udivdi3+0x2b>
f010192e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101933:	eb a6                	jmp    f01018db <__udivdi3+0x2b>
f0101935:	8d 76 00             	lea    0x0(%esi),%esi
f0101938:	31 ff                	xor    %edi,%edi
f010193a:	31 c0                	xor    %eax,%eax
f010193c:	89 fa                	mov    %edi,%edx
f010193e:	83 c4 1c             	add    $0x1c,%esp
f0101941:	5b                   	pop    %ebx
f0101942:	5e                   	pop    %esi
f0101943:	5f                   	pop    %edi
f0101944:	5d                   	pop    %ebp
f0101945:	c3                   	ret    
f0101946:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f010194d:	8d 76 00             	lea    0x0(%esi),%esi
f0101950:	89 f9                	mov    %edi,%ecx
f0101952:	b8 20 00 00 00       	mov    $0x20,%eax
f0101957:	29 f8                	sub    %edi,%eax
f0101959:	d3 e2                	shl    %cl,%edx
f010195b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010195f:	89 c1                	mov    %eax,%ecx
f0101961:	89 da                	mov    %ebx,%edx
f0101963:	d3 ea                	shr    %cl,%edx
f0101965:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101969:	09 d1                	or     %edx,%ecx
f010196b:	89 f2                	mov    %esi,%edx
f010196d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101971:	89 f9                	mov    %edi,%ecx
f0101973:	d3 e3                	shl    %cl,%ebx
f0101975:	89 c1                	mov    %eax,%ecx
f0101977:	d3 ea                	shr    %cl,%edx
f0101979:	89 f9                	mov    %edi,%ecx
f010197b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010197f:	89 eb                	mov    %ebp,%ebx
f0101981:	d3 e6                	shl    %cl,%esi
f0101983:	89 c1                	mov    %eax,%ecx
f0101985:	d3 eb                	shr    %cl,%ebx
f0101987:	09 de                	or     %ebx,%esi
f0101989:	89 f0                	mov    %esi,%eax
f010198b:	f7 74 24 08          	divl   0x8(%esp)
f010198f:	89 d6                	mov    %edx,%esi
f0101991:	89 c3                	mov    %eax,%ebx
f0101993:	f7 64 24 0c          	mull   0xc(%esp)
f0101997:	39 d6                	cmp    %edx,%esi
f0101999:	72 15                	jb     f01019b0 <__udivdi3+0x100>
f010199b:	89 f9                	mov    %edi,%ecx
f010199d:	d3 e5                	shl    %cl,%ebp
f010199f:	39 c5                	cmp    %eax,%ebp
f01019a1:	73 04                	jae    f01019a7 <__udivdi3+0xf7>
f01019a3:	39 d6                	cmp    %edx,%esi
f01019a5:	74 09                	je     f01019b0 <__udivdi3+0x100>
f01019a7:	89 d8                	mov    %ebx,%eax
f01019a9:	31 ff                	xor    %edi,%edi
f01019ab:	e9 2b ff ff ff       	jmp    f01018db <__udivdi3+0x2b>
f01019b0:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01019b3:	31 ff                	xor    %edi,%edi
f01019b5:	e9 21 ff ff ff       	jmp    f01018db <__udivdi3+0x2b>
f01019ba:	66 90                	xchg   %ax,%ax
f01019bc:	66 90                	xchg   %ax,%ax
f01019be:	66 90                	xchg   %ax,%ax

f01019c0 <__umoddi3>:
f01019c0:	f3 0f 1e fb          	endbr32 
f01019c4:	55                   	push   %ebp
f01019c5:	57                   	push   %edi
f01019c6:	56                   	push   %esi
f01019c7:	53                   	push   %ebx
f01019c8:	83 ec 1c             	sub    $0x1c,%esp
f01019cb:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f01019cf:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f01019d3:	8b 74 24 30          	mov    0x30(%esp),%esi
f01019d7:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01019db:	89 da                	mov    %ebx,%edx
f01019dd:	85 c0                	test   %eax,%eax
f01019df:	75 3f                	jne    f0101a20 <__umoddi3+0x60>
f01019e1:	39 df                	cmp    %ebx,%edi
f01019e3:	76 13                	jbe    f01019f8 <__umoddi3+0x38>
f01019e5:	89 f0                	mov    %esi,%eax
f01019e7:	f7 f7                	div    %edi
f01019e9:	89 d0                	mov    %edx,%eax
f01019eb:	31 d2                	xor    %edx,%edx
f01019ed:	83 c4 1c             	add    $0x1c,%esp
f01019f0:	5b                   	pop    %ebx
f01019f1:	5e                   	pop    %esi
f01019f2:	5f                   	pop    %edi
f01019f3:	5d                   	pop    %ebp
f01019f4:	c3                   	ret    
f01019f5:	8d 76 00             	lea    0x0(%esi),%esi
f01019f8:	89 fd                	mov    %edi,%ebp
f01019fa:	85 ff                	test   %edi,%edi
f01019fc:	75 0b                	jne    f0101a09 <__umoddi3+0x49>
f01019fe:	b8 01 00 00 00       	mov    $0x1,%eax
f0101a03:	31 d2                	xor    %edx,%edx
f0101a05:	f7 f7                	div    %edi
f0101a07:	89 c5                	mov    %eax,%ebp
f0101a09:	89 d8                	mov    %ebx,%eax
f0101a0b:	31 d2                	xor    %edx,%edx
f0101a0d:	f7 f5                	div    %ebp
f0101a0f:	89 f0                	mov    %esi,%eax
f0101a11:	f7 f5                	div    %ebp
f0101a13:	89 d0                	mov    %edx,%eax
f0101a15:	eb d4                	jmp    f01019eb <__umoddi3+0x2b>
f0101a17:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101a1e:	66 90                	xchg   %ax,%ax
f0101a20:	89 f1                	mov    %esi,%ecx
f0101a22:	39 d8                	cmp    %ebx,%eax
f0101a24:	76 0a                	jbe    f0101a30 <__umoddi3+0x70>
f0101a26:	89 f0                	mov    %esi,%eax
f0101a28:	83 c4 1c             	add    $0x1c,%esp
f0101a2b:	5b                   	pop    %ebx
f0101a2c:	5e                   	pop    %esi
f0101a2d:	5f                   	pop    %edi
f0101a2e:	5d                   	pop    %ebp
f0101a2f:	c3                   	ret    
f0101a30:	0f bd e8             	bsr    %eax,%ebp
f0101a33:	83 f5 1f             	xor    $0x1f,%ebp
f0101a36:	75 20                	jne    f0101a58 <__umoddi3+0x98>
f0101a38:	39 d8                	cmp    %ebx,%eax
f0101a3a:	0f 82 b0 00 00 00    	jb     f0101af0 <__umoddi3+0x130>
f0101a40:	39 f7                	cmp    %esi,%edi
f0101a42:	0f 86 a8 00 00 00    	jbe    f0101af0 <__umoddi3+0x130>
f0101a48:	89 c8                	mov    %ecx,%eax
f0101a4a:	83 c4 1c             	add    $0x1c,%esp
f0101a4d:	5b                   	pop    %ebx
f0101a4e:	5e                   	pop    %esi
f0101a4f:	5f                   	pop    %edi
f0101a50:	5d                   	pop    %ebp
f0101a51:	c3                   	ret    
f0101a52:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101a58:	89 e9                	mov    %ebp,%ecx
f0101a5a:	ba 20 00 00 00       	mov    $0x20,%edx
f0101a5f:	29 ea                	sub    %ebp,%edx
f0101a61:	d3 e0                	shl    %cl,%eax
f0101a63:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101a67:	89 d1                	mov    %edx,%ecx
f0101a69:	89 f8                	mov    %edi,%eax
f0101a6b:	d3 e8                	shr    %cl,%eax
f0101a6d:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101a71:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101a75:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101a79:	09 c1                	or     %eax,%ecx
f0101a7b:	89 d8                	mov    %ebx,%eax
f0101a7d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101a81:	89 e9                	mov    %ebp,%ecx
f0101a83:	d3 e7                	shl    %cl,%edi
f0101a85:	89 d1                	mov    %edx,%ecx
f0101a87:	d3 e8                	shr    %cl,%eax
f0101a89:	89 e9                	mov    %ebp,%ecx
f0101a8b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101a8f:	d3 e3                	shl    %cl,%ebx
f0101a91:	89 c7                	mov    %eax,%edi
f0101a93:	89 d1                	mov    %edx,%ecx
f0101a95:	89 f0                	mov    %esi,%eax
f0101a97:	d3 e8                	shr    %cl,%eax
f0101a99:	89 e9                	mov    %ebp,%ecx
f0101a9b:	89 fa                	mov    %edi,%edx
f0101a9d:	d3 e6                	shl    %cl,%esi
f0101a9f:	09 d8                	or     %ebx,%eax
f0101aa1:	f7 74 24 08          	divl   0x8(%esp)
f0101aa5:	89 d1                	mov    %edx,%ecx
f0101aa7:	89 f3                	mov    %esi,%ebx
f0101aa9:	f7 64 24 0c          	mull   0xc(%esp)
f0101aad:	89 c6                	mov    %eax,%esi
f0101aaf:	89 d7                	mov    %edx,%edi
f0101ab1:	39 d1                	cmp    %edx,%ecx
f0101ab3:	72 06                	jb     f0101abb <__umoddi3+0xfb>
f0101ab5:	75 10                	jne    f0101ac7 <__umoddi3+0x107>
f0101ab7:	39 c3                	cmp    %eax,%ebx
f0101ab9:	73 0c                	jae    f0101ac7 <__umoddi3+0x107>
f0101abb:	2b 44 24 0c          	sub    0xc(%esp),%eax
f0101abf:	1b 54 24 08          	sbb    0x8(%esp),%edx
f0101ac3:	89 d7                	mov    %edx,%edi
f0101ac5:	89 c6                	mov    %eax,%esi
f0101ac7:	89 ca                	mov    %ecx,%edx
f0101ac9:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101ace:	29 f3                	sub    %esi,%ebx
f0101ad0:	19 fa                	sbb    %edi,%edx
f0101ad2:	89 d0                	mov    %edx,%eax
f0101ad4:	d3 e0                	shl    %cl,%eax
f0101ad6:	89 e9                	mov    %ebp,%ecx
f0101ad8:	d3 eb                	shr    %cl,%ebx
f0101ada:	d3 ea                	shr    %cl,%edx
f0101adc:	09 d8                	or     %ebx,%eax
f0101ade:	83 c4 1c             	add    $0x1c,%esp
f0101ae1:	5b                   	pop    %ebx
f0101ae2:	5e                   	pop    %esi
f0101ae3:	5f                   	pop    %edi
f0101ae4:	5d                   	pop    %ebp
f0101ae5:	c3                   	ret    
f0101ae6:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101aed:	8d 76 00             	lea    0x0(%esi),%esi
f0101af0:	89 da                	mov    %ebx,%edx
f0101af2:	29 fe                	sub    %edi,%esi
f0101af4:	19 c2                	sbb    %eax,%edx
f0101af6:	89 f1                	mov    %esi,%ecx
f0101af8:	89 c8                	mov    %ecx,%eax
f0101afa:	e9 4b ff ff ff       	jmp    f0101a4a <__umoddi3+0x8a>
