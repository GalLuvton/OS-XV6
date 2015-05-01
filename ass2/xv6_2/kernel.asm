
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4 0f                	in     $0xf,%al

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 a0 10 00       	mov    $0x10a000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc 50 c6 10 80       	mov    $0x8010c650,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 9f 37 10 80       	mov    $0x8010379f,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  initlock(&bcache.lock, "bcache");
8010003a:	c7 44 24 04 c0 86 10 	movl   $0x801086c0,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100049:	e8 30 50 00 00       	call   8010507e <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 70 05 11 80 64 	movl   $0x80110564,0x80110570
80100055:	05 11 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 74 05 11 80 64 	movl   $0x80110564,0x80110574
8010005f:	05 11 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 94 c6 10 80 	movl   $0x8010c694,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 74 05 11 80    	mov    0x80110574,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c 64 05 11 80 	movl   $0x80110564,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 74 05 11 80       	mov    0x80110574,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 74 05 11 80       	mov    %eax,0x80110574

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 64 05 11 80 	cmpl   $0x80110564,-0xc(%ebp)
801000ac:	72 bd                	jb     8010006b <binit+0x37>
    b->prev = &bcache.head;
    b->dev = -1;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
}
801000ae:	c9                   	leave  
801000af:	c3                   	ret    

801000b0 <bget>:
// Look through buffer cache for sector on device dev.
// If not found, allocate a buffer.
// In either case, return B_BUSY buffer.
static struct buf*
bget(uint dev, uint sector)
{
801000b0:	55                   	push   %ebp
801000b1:	89 e5                	mov    %esp,%ebp
801000b3:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  acquire(&bcache.lock);
801000b6:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801000bd:	e8 dd 4f 00 00       	call   8010509f <acquire>

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 74 05 11 80       	mov    0x80110574,%eax
801000c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801000ca:	eb 63                	jmp    8010012f <bget+0x7f>
    if(b->dev == dev && b->sector == sector){
801000cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000cf:	8b 40 04             	mov    0x4(%eax),%eax
801000d2:	3b 45 08             	cmp    0x8(%ebp),%eax
801000d5:	75 4f                	jne    80100126 <bget+0x76>
801000d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000da:	8b 40 08             	mov    0x8(%eax),%eax
801000dd:	3b 45 0c             	cmp    0xc(%ebp),%eax
801000e0:	75 44                	jne    80100126 <bget+0x76>
      if(!(b->flags & B_BUSY)){
801000e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000e5:	8b 00                	mov    (%eax),%eax
801000e7:	83 e0 01             	and    $0x1,%eax
801000ea:	85 c0                	test   %eax,%eax
801000ec:	75 23                	jne    80100111 <bget+0x61>
        b->flags |= B_BUSY;
801000ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000f1:	8b 00                	mov    (%eax),%eax
801000f3:	89 c2                	mov    %eax,%edx
801000f5:	83 ca 01             	or     $0x1,%edx
801000f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000fb:	89 10                	mov    %edx,(%eax)
        release(&bcache.lock);
801000fd:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100104:	e8 f8 4f 00 00       	call   80105101 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 c6 10 	movl   $0x8010c660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 25 4c 00 00       	call   80104d49 <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 64 05 11 80 	cmpl   $0x80110564,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
  }

  // Not cached; recycle some non-busy and clean buffer.
  // "clean" because B_DIRTY and !B_BUSY means log.c
  // hasn't yet committed the changes to the buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 70 05 11 80       	mov    0x80110570,%eax
8010013d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100140:	eb 4d                	jmp    8010018f <bget+0xdf>
    if((b->flags & B_BUSY) == 0 && (b->flags & B_DIRTY) == 0){
80100142:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100145:	8b 00                	mov    (%eax),%eax
80100147:	83 e0 01             	and    $0x1,%eax
8010014a:	85 c0                	test   %eax,%eax
8010014c:	75 38                	jne    80100186 <bget+0xd6>
8010014e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100151:	8b 00                	mov    (%eax),%eax
80100153:	83 e0 04             	and    $0x4,%eax
80100156:	85 c0                	test   %eax,%eax
80100158:	75 2c                	jne    80100186 <bget+0xd6>
      b->dev = dev;
8010015a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010015d:	8b 55 08             	mov    0x8(%ebp),%edx
80100160:	89 50 04             	mov    %edx,0x4(%eax)
      b->sector = sector;
80100163:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100166:	8b 55 0c             	mov    0xc(%ebp),%edx
80100169:	89 50 08             	mov    %edx,0x8(%eax)
      b->flags = B_BUSY;
8010016c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010016f:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
      release(&bcache.lock);
80100175:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010017c:	e8 80 4f 00 00       	call   80105101 <release>
      return b;
80100181:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100184:	eb 1e                	jmp    801001a4 <bget+0xf4>
  }

  // Not cached; recycle some non-busy and clean buffer.
  // "clean" because B_DIRTY and !B_BUSY means log.c
  // hasn't yet committed the changes to the buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100186:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100189:	8b 40 0c             	mov    0xc(%eax),%eax
8010018c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010018f:	81 7d f4 64 05 11 80 	cmpl   $0x80110564,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 c7 86 10 80 	movl   $0x801086c7,(%esp)
8010019f:	e8 99 03 00 00       	call   8010053d <panic>
}
801001a4:	c9                   	leave  
801001a5:	c3                   	ret    

801001a6 <bread>:

// Return a B_BUSY buf with the contents of the indicated disk sector.
struct buf*
bread(uint dev, uint sector)
{
801001a6:	55                   	push   %ebp
801001a7:	89 e5                	mov    %esp,%ebp
801001a9:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  b = bget(dev, sector);
801001ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801001af:	89 44 24 04          	mov    %eax,0x4(%esp)
801001b3:	8b 45 08             	mov    0x8(%ebp),%eax
801001b6:	89 04 24             	mov    %eax,(%esp)
801001b9:	e8 f2 fe ff ff       	call   801000b0 <bget>
801001be:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(!(b->flags & B_VALID))
801001c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001c4:	8b 00                	mov    (%eax),%eax
801001c6:	83 e0 02             	and    $0x2,%eax
801001c9:	85 c0                	test   %eax,%eax
801001cb:	75 0b                	jne    801001d8 <bread+0x32>
    iderw(b);
801001cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001d0:	89 04 24             	mov    %eax,(%esp)
801001d3:	e8 18 26 00 00       	call   801027f0 <iderw>
  return b;
801001d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801001db:	c9                   	leave  
801001dc:	c3                   	ret    

801001dd <bwrite>:

// Write b's contents to disk.  Must be B_BUSY.
void
bwrite(struct buf *b)
{
801001dd:	55                   	push   %ebp
801001de:	89 e5                	mov    %esp,%ebp
801001e0:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
801001e3:	8b 45 08             	mov    0x8(%ebp),%eax
801001e6:	8b 00                	mov    (%eax),%eax
801001e8:	83 e0 01             	and    $0x1,%eax
801001eb:	85 c0                	test   %eax,%eax
801001ed:	75 0c                	jne    801001fb <bwrite+0x1e>
    panic("bwrite");
801001ef:	c7 04 24 d8 86 10 80 	movl   $0x801086d8,(%esp)
801001f6:	e8 42 03 00 00       	call   8010053d <panic>
  b->flags |= B_DIRTY;
801001fb:	8b 45 08             	mov    0x8(%ebp),%eax
801001fe:	8b 00                	mov    (%eax),%eax
80100200:	89 c2                	mov    %eax,%edx
80100202:	83 ca 04             	or     $0x4,%edx
80100205:	8b 45 08             	mov    0x8(%ebp),%eax
80100208:	89 10                	mov    %edx,(%eax)
  iderw(b);
8010020a:	8b 45 08             	mov    0x8(%ebp),%eax
8010020d:	89 04 24             	mov    %eax,(%esp)
80100210:	e8 db 25 00 00       	call   801027f0 <iderw>
}
80100215:	c9                   	leave  
80100216:	c3                   	ret    

80100217 <brelse>:

// Release a B_BUSY buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
80100217:	55                   	push   %ebp
80100218:	89 e5                	mov    %esp,%ebp
8010021a:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
8010021d:	8b 45 08             	mov    0x8(%ebp),%eax
80100220:	8b 00                	mov    (%eax),%eax
80100222:	83 e0 01             	and    $0x1,%eax
80100225:	85 c0                	test   %eax,%eax
80100227:	75 0c                	jne    80100235 <brelse+0x1e>
    panic("brelse");
80100229:	c7 04 24 df 86 10 80 	movl   $0x801086df,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010023c:	e8 5e 4e 00 00       	call   8010509f <acquire>

  b->next->prev = b->prev;
80100241:	8b 45 08             	mov    0x8(%ebp),%eax
80100244:	8b 40 10             	mov    0x10(%eax),%eax
80100247:	8b 55 08             	mov    0x8(%ebp),%edx
8010024a:	8b 52 0c             	mov    0xc(%edx),%edx
8010024d:	89 50 0c             	mov    %edx,0xc(%eax)
  b->prev->next = b->next;
80100250:	8b 45 08             	mov    0x8(%ebp),%eax
80100253:	8b 40 0c             	mov    0xc(%eax),%eax
80100256:	8b 55 08             	mov    0x8(%ebp),%edx
80100259:	8b 52 10             	mov    0x10(%edx),%edx
8010025c:	89 50 10             	mov    %edx,0x10(%eax)
  b->next = bcache.head.next;
8010025f:	8b 15 74 05 11 80    	mov    0x80110574,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c 64 05 11 80 	movl   $0x80110564,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 74 05 11 80       	mov    0x80110574,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 74 05 11 80       	mov    %eax,0x80110574

  b->flags &= ~B_BUSY;
80100288:	8b 45 08             	mov    0x8(%ebp),%eax
8010028b:	8b 00                	mov    (%eax),%eax
8010028d:	89 c2                	mov    %eax,%edx
8010028f:	83 e2 fe             	and    $0xfffffffe,%edx
80100292:	8b 45 08             	mov    0x8(%ebp),%eax
80100295:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80100297:	8b 45 08             	mov    0x8(%ebp),%eax
8010029a:	89 04 24             	mov    %eax,(%esp)
8010029d:	e8 b6 4b 00 00       	call   80104e58 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801002a9:	e8 53 4e 00 00       	call   80105101 <release>
}
801002ae:	c9                   	leave  
801002af:	c3                   	ret    

801002b0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801002b0:	55                   	push   %ebp
801002b1:	89 e5                	mov    %esp,%ebp
801002b3:	53                   	push   %ebx
801002b4:	83 ec 14             	sub    $0x14,%esp
801002b7:	8b 45 08             	mov    0x8(%ebp),%eax
801002ba:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801002be:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801002c2:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801002c6:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801002ca:	ec                   	in     (%dx),%al
801002cb:	89 c3                	mov    %eax,%ebx
801002cd:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801002d0:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801002d4:	83 c4 14             	add    $0x14,%esp
801002d7:	5b                   	pop    %ebx
801002d8:	5d                   	pop    %ebp
801002d9:	c3                   	ret    

801002da <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801002da:	55                   	push   %ebp
801002db:	89 e5                	mov    %esp,%ebp
801002dd:	83 ec 08             	sub    $0x8,%esp
801002e0:	8b 55 08             	mov    0x8(%ebp),%edx
801002e3:	8b 45 0c             	mov    0xc(%ebp),%eax
801002e6:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801002ea:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801002ed:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801002f1:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801002f5:	ee                   	out    %al,(%dx)
}
801002f6:	c9                   	leave  
801002f7:	c3                   	ret    

801002f8 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801002f8:	55                   	push   %ebp
801002f9:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
801002fb:	fa                   	cli    
}
801002fc:	5d                   	pop    %ebp
801002fd:	c3                   	ret    

801002fe <printint>:
  int locking;
} cons;

static void
printint(int xx, int base, int sign)
{
801002fe:	55                   	push   %ebp
801002ff:	89 e5                	mov    %esp,%ebp
80100301:	83 ec 48             	sub    $0x48,%esp
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
80100304:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100308:	74 19                	je     80100323 <printint+0x25>
8010030a:	8b 45 08             	mov    0x8(%ebp),%eax
8010030d:	c1 e8 1f             	shr    $0x1f,%eax
80100310:	89 45 10             	mov    %eax,0x10(%ebp)
80100313:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100317:	74 0a                	je     80100323 <printint+0x25>
    x = -xx;
80100319:	8b 45 08             	mov    0x8(%ebp),%eax
8010031c:	f7 d8                	neg    %eax
8010031e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100321:	eb 06                	jmp    80100329 <printint+0x2b>
  else
    x = xx;
80100323:	8b 45 08             	mov    0x8(%ebp),%eax
80100326:	89 45 f0             	mov    %eax,-0x10(%ebp)

  i = 0;
80100329:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
80100330:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80100333:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100336:	ba 00 00 00 00       	mov    $0x0,%edx
8010033b:	f7 f1                	div    %ecx
8010033d:	89 d0                	mov    %edx,%eax
8010033f:	0f b6 90 04 90 10 80 	movzbl -0x7fef6ffc(%eax),%edx
80100346:	8d 45 e0             	lea    -0x20(%ebp),%eax
80100349:	03 45 f4             	add    -0xc(%ebp),%eax
8010034c:	88 10                	mov    %dl,(%eax)
8010034e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  }while((x /= base) != 0);
80100352:	8b 55 0c             	mov    0xc(%ebp),%edx
80100355:	89 55 d4             	mov    %edx,-0x2c(%ebp)
80100358:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010035b:	ba 00 00 00 00       	mov    $0x0,%edx
80100360:	f7 75 d4             	divl   -0x2c(%ebp)
80100363:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100366:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010036a:	75 c4                	jne    80100330 <printint+0x32>

  if(sign)
8010036c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100370:	74 23                	je     80100395 <printint+0x97>
    buf[i++] = '-';
80100372:	8d 45 e0             	lea    -0x20(%ebp),%eax
80100375:	03 45 f4             	add    -0xc(%ebp),%eax
80100378:	c6 00 2d             	movb   $0x2d,(%eax)
8010037b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

  while(--i >= 0)
8010037f:	eb 14                	jmp    80100395 <printint+0x97>
    consputc(buf[i]);
80100381:	8d 45 e0             	lea    -0x20(%ebp),%eax
80100384:	03 45 f4             	add    -0xc(%ebp),%eax
80100387:	0f b6 00             	movzbl (%eax),%eax
8010038a:	0f be c0             	movsbl %al,%eax
8010038d:	89 04 24             	mov    %eax,(%esp)
80100390:	e8 bb 03 00 00       	call   80100750 <consputc>
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
80100395:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100399:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010039d:	79 e2                	jns    80100381 <printint+0x83>
    consputc(buf[i]);
}
8010039f:	c9                   	leave  
801003a0:	c3                   	ret    

801003a1 <cprintf>:
//PAGEBREAK: 50

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
801003a1:	55                   	push   %ebp
801003a2:	89 e5                	mov    %esp,%ebp
801003a4:	83 ec 38             	sub    $0x38,%esp
  int i, c, locking;
  uint *argp;
  char *s;

  locking = cons.locking;
801003a7:	a1 f4 b5 10 80       	mov    0x8010b5f4,%eax
801003ac:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003af:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003b3:	74 0c                	je     801003c1 <cprintf+0x20>
    acquire(&cons.lock);
801003b5:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
801003bc:	e8 de 4c 00 00       	call   8010509f <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 e6 86 10 80 	movl   $0x801086e6,(%esp)
801003cf:	e8 69 01 00 00       	call   8010053d <panic>

  argp = (uint*)(void*)(&fmt + 1);
801003d4:	8d 45 0c             	lea    0xc(%ebp),%eax
801003d7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
801003da:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801003e1:	e9 20 01 00 00       	jmp    80100506 <cprintf+0x165>
    if(c != '%'){
801003e6:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
801003ea:	74 10                	je     801003fc <cprintf+0x5b>
      consputc(c);
801003ec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801003ef:	89 04 24             	mov    %eax,(%esp)
801003f2:	e8 59 03 00 00       	call   80100750 <consputc>
      continue;
801003f7:	e9 06 01 00 00       	jmp    80100502 <cprintf+0x161>
    }
    c = fmt[++i] & 0xff;
801003fc:	8b 55 08             	mov    0x8(%ebp),%edx
801003ff:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100403:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100406:	01 d0                	add    %edx,%eax
80100408:	0f b6 00             	movzbl (%eax),%eax
8010040b:	0f be c0             	movsbl %al,%eax
8010040e:	25 ff 00 00 00       	and    $0xff,%eax
80100413:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(c == 0)
80100416:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
8010041a:	0f 84 08 01 00 00    	je     80100528 <cprintf+0x187>
      break;
    switch(c){
80100420:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100423:	83 f8 70             	cmp    $0x70,%eax
80100426:	74 4d                	je     80100475 <cprintf+0xd4>
80100428:	83 f8 70             	cmp    $0x70,%eax
8010042b:	7f 13                	jg     80100440 <cprintf+0x9f>
8010042d:	83 f8 25             	cmp    $0x25,%eax
80100430:	0f 84 a6 00 00 00    	je     801004dc <cprintf+0x13b>
80100436:	83 f8 64             	cmp    $0x64,%eax
80100439:	74 14                	je     8010044f <cprintf+0xae>
8010043b:	e9 aa 00 00 00       	jmp    801004ea <cprintf+0x149>
80100440:	83 f8 73             	cmp    $0x73,%eax
80100443:	74 53                	je     80100498 <cprintf+0xf7>
80100445:	83 f8 78             	cmp    $0x78,%eax
80100448:	74 2b                	je     80100475 <cprintf+0xd4>
8010044a:	e9 9b 00 00 00       	jmp    801004ea <cprintf+0x149>
    case 'd':
      printint(*argp++, 10, 1);
8010044f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100452:	8b 00                	mov    (%eax),%eax
80100454:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
80100458:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
8010045f:	00 
80100460:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80100467:	00 
80100468:	89 04 24             	mov    %eax,(%esp)
8010046b:	e8 8e fe ff ff       	call   801002fe <printint>
      break;
80100470:	e9 8d 00 00 00       	jmp    80100502 <cprintf+0x161>
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
80100475:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100478:	8b 00                	mov    (%eax),%eax
8010047a:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
8010047e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100485:	00 
80100486:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
8010048d:	00 
8010048e:	89 04 24             	mov    %eax,(%esp)
80100491:	e8 68 fe ff ff       	call   801002fe <printint>
      break;
80100496:	eb 6a                	jmp    80100502 <cprintf+0x161>
    case 's':
      if((s = (char*)*argp++) == 0)
80100498:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010049b:	8b 00                	mov    (%eax),%eax
8010049d:	89 45 ec             	mov    %eax,-0x14(%ebp)
801004a0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801004a4:	0f 94 c0             	sete   %al
801004a7:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
801004ab:	84 c0                	test   %al,%al
801004ad:	74 20                	je     801004cf <cprintf+0x12e>
        s = "(null)";
801004af:	c7 45 ec ef 86 10 80 	movl   $0x801086ef,-0x14(%ebp)
      for(; *s; s++)
801004b6:	eb 17                	jmp    801004cf <cprintf+0x12e>
        consputc(*s);
801004b8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004bb:	0f b6 00             	movzbl (%eax),%eax
801004be:	0f be c0             	movsbl %al,%eax
801004c1:	89 04 24             	mov    %eax,(%esp)
801004c4:	e8 87 02 00 00       	call   80100750 <consputc>
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
        s = "(null)";
      for(; *s; s++)
801004c9:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
801004cd:	eb 01                	jmp    801004d0 <cprintf+0x12f>
801004cf:	90                   	nop
801004d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004d3:	0f b6 00             	movzbl (%eax),%eax
801004d6:	84 c0                	test   %al,%al
801004d8:	75 de                	jne    801004b8 <cprintf+0x117>
        consputc(*s);
      break;
801004da:	eb 26                	jmp    80100502 <cprintf+0x161>
    case '%':
      consputc('%');
801004dc:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004e3:	e8 68 02 00 00       	call   80100750 <consputc>
      break;
801004e8:	eb 18                	jmp    80100502 <cprintf+0x161>
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
801004ea:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004f1:	e8 5a 02 00 00       	call   80100750 <consputc>
      consputc(c);
801004f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801004f9:	89 04 24             	mov    %eax,(%esp)
801004fc:	e8 4f 02 00 00       	call   80100750 <consputc>
      break;
80100501:	90                   	nop

  if (fmt == 0)
    panic("null fmt");

  argp = (uint*)(void*)(&fmt + 1);
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100502:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100506:	8b 55 08             	mov    0x8(%ebp),%edx
80100509:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010050c:	01 d0                	add    %edx,%eax
8010050e:	0f b6 00             	movzbl (%eax),%eax
80100511:	0f be c0             	movsbl %al,%eax
80100514:	25 ff 00 00 00       	and    $0xff,%eax
80100519:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010051c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100520:	0f 85 c0 fe ff ff    	jne    801003e6 <cprintf+0x45>
80100526:	eb 01                	jmp    80100529 <cprintf+0x188>
      consputc(c);
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
80100528:	90                   	nop
      consputc(c);
      break;
    }
  }

  if(locking)
80100529:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010052d:	74 0c                	je     8010053b <cprintf+0x19a>
    release(&cons.lock);
8010052f:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100536:	e8 c6 4b 00 00       	call   80105101 <release>
}
8010053b:	c9                   	leave  
8010053c:	c3                   	ret    

8010053d <panic>:

void
panic(char *s)
{
8010053d:	55                   	push   %ebp
8010053e:	89 e5                	mov    %esp,%ebp
80100540:	83 ec 48             	sub    $0x48,%esp
  int i;
  uint pcs[10];
  
  cli();
80100543:	e8 b0 fd ff ff       	call   801002f8 <cli>
  cons.locking = 0;
80100548:	c7 05 f4 b5 10 80 00 	movl   $0x0,0x8010b5f4
8010054f:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
80100552:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80100558:	0f b6 00             	movzbl (%eax),%eax
8010055b:	0f b6 c0             	movzbl %al,%eax
8010055e:	89 44 24 04          	mov    %eax,0x4(%esp)
80100562:	c7 04 24 f6 86 10 80 	movl   $0x801086f6,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 05 87 10 80 	movl   $0x80108705,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 b9 4b 00 00       	call   80105150 <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 07 87 10 80 	movl   $0x80108707,(%esp)
801005b2:	e8 ea fd ff ff       	call   801003a1 <cprintf>
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
801005b7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801005bb:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801005bf:	7e df                	jle    801005a0 <panic+0x63>
    cprintf(" %p", pcs[i]);
  panicked = 1; // freeze other CPU
801005c1:	c7 05 a0 b5 10 80 01 	movl   $0x1,0x8010b5a0
801005c8:	00 00 00 
  for(;;)
    ;
801005cb:	eb fe                	jmp    801005cb <panic+0x8e>

801005cd <cgaputc>:
#define CRTPORT 0x3d4
static ushort *crt = (ushort*)P2V(0xb8000);  // CGA memory

static void
cgaputc(int c)
{
801005cd:	55                   	push   %ebp
801005ce:	89 e5                	mov    %esp,%ebp
801005d0:	83 ec 28             	sub    $0x28,%esp
  int pos;
  
  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
801005d3:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801005da:	00 
801005db:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801005e2:	e8 f3 fc ff ff       	call   801002da <outb>
  pos = inb(CRTPORT+1) << 8;
801005e7:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
801005ee:	e8 bd fc ff ff       	call   801002b0 <inb>
801005f3:	0f b6 c0             	movzbl %al,%eax
801005f6:	c1 e0 08             	shl    $0x8,%eax
801005f9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  outb(CRTPORT, 15);
801005fc:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80100603:	00 
80100604:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
8010060b:	e8 ca fc ff ff       	call   801002da <outb>
  pos |= inb(CRTPORT+1);
80100610:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100617:	e8 94 fc ff ff       	call   801002b0 <inb>
8010061c:	0f b6 c0             	movzbl %al,%eax
8010061f:	09 45 f4             	or     %eax,-0xc(%ebp)

  if(c == '\n')
80100622:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
80100626:	75 30                	jne    80100658 <cgaputc+0x8b>
    pos += 80 - pos%80;
80100628:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010062b:	ba 67 66 66 66       	mov    $0x66666667,%edx
80100630:	89 c8                	mov    %ecx,%eax
80100632:	f7 ea                	imul   %edx
80100634:	c1 fa 05             	sar    $0x5,%edx
80100637:	89 c8                	mov    %ecx,%eax
80100639:	c1 f8 1f             	sar    $0x1f,%eax
8010063c:	29 c2                	sub    %eax,%edx
8010063e:	89 d0                	mov    %edx,%eax
80100640:	c1 e0 02             	shl    $0x2,%eax
80100643:	01 d0                	add    %edx,%eax
80100645:	c1 e0 04             	shl    $0x4,%eax
80100648:	89 ca                	mov    %ecx,%edx
8010064a:	29 c2                	sub    %eax,%edx
8010064c:	b8 50 00 00 00       	mov    $0x50,%eax
80100651:	29 d0                	sub    %edx,%eax
80100653:	01 45 f4             	add    %eax,-0xc(%ebp)
80100656:	eb 32                	jmp    8010068a <cgaputc+0xbd>
  else if(c == BACKSPACE){
80100658:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010065f:	75 0c                	jne    8010066d <cgaputc+0xa0>
    if(pos > 0) --pos;
80100661:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100665:	7e 23                	jle    8010068a <cgaputc+0xbd>
80100667:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
8010066b:	eb 1d                	jmp    8010068a <cgaputc+0xbd>
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010066d:	a1 00 90 10 80       	mov    0x80109000,%eax
80100672:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100675:	01 d2                	add    %edx,%edx
80100677:	01 c2                	add    %eax,%edx
80100679:	8b 45 08             	mov    0x8(%ebp),%eax
8010067c:	66 25 ff 00          	and    $0xff,%ax
80100680:	80 cc 07             	or     $0x7,%ah
80100683:	66 89 02             	mov    %ax,(%edx)
80100686:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  
  if((pos/80) >= 24){  // Scroll up.
8010068a:	81 7d f4 7f 07 00 00 	cmpl   $0x77f,-0xc(%ebp)
80100691:	7e 53                	jle    801006e6 <cgaputc+0x119>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
80100693:	a1 00 90 10 80       	mov    0x80109000,%eax
80100698:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
8010069e:	a1 00 90 10 80       	mov    0x80109000,%eax
801006a3:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
801006aa:	00 
801006ab:	89 54 24 04          	mov    %edx,0x4(%esp)
801006af:	89 04 24             	mov    %eax,(%esp)
801006b2:	e8 0a 4d 00 00       	call   801053c1 <memmove>
    pos -= 80;
801006b7:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801006bb:	b8 80 07 00 00       	mov    $0x780,%eax
801006c0:	2b 45 f4             	sub    -0xc(%ebp),%eax
801006c3:	01 c0                	add    %eax,%eax
801006c5:	8b 15 00 90 10 80    	mov    0x80109000,%edx
801006cb:	8b 4d f4             	mov    -0xc(%ebp),%ecx
801006ce:	01 c9                	add    %ecx,%ecx
801006d0:	01 ca                	add    %ecx,%edx
801006d2:	89 44 24 08          	mov    %eax,0x8(%esp)
801006d6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801006dd:	00 
801006de:	89 14 24             	mov    %edx,(%esp)
801006e1:	e8 08 4c 00 00       	call   801052ee <memset>
  }
  
  outb(CRTPORT, 14);
801006e6:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801006ed:	00 
801006ee:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801006f5:	e8 e0 fb ff ff       	call   801002da <outb>
  outb(CRTPORT+1, pos>>8);
801006fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801006fd:	c1 f8 08             	sar    $0x8,%eax
80100700:	0f b6 c0             	movzbl %al,%eax
80100703:	89 44 24 04          	mov    %eax,0x4(%esp)
80100707:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
8010070e:	e8 c7 fb ff ff       	call   801002da <outb>
  outb(CRTPORT, 15);
80100713:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
8010071a:	00 
8010071b:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100722:	e8 b3 fb ff ff       	call   801002da <outb>
  outb(CRTPORT+1, pos);
80100727:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010072a:	0f b6 c0             	movzbl %al,%eax
8010072d:	89 44 24 04          	mov    %eax,0x4(%esp)
80100731:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100738:	e8 9d fb ff ff       	call   801002da <outb>
  crt[pos] = ' ' | 0x0700;
8010073d:	a1 00 90 10 80       	mov    0x80109000,%eax
80100742:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100745:	01 d2                	add    %edx,%edx
80100747:	01 d0                	add    %edx,%eax
80100749:	66 c7 00 20 07       	movw   $0x720,(%eax)
}
8010074e:	c9                   	leave  
8010074f:	c3                   	ret    

80100750 <consputc>:

void
consputc(int c)
{
80100750:	55                   	push   %ebp
80100751:	89 e5                	mov    %esp,%ebp
80100753:	83 ec 18             	sub    $0x18,%esp
  if(panicked){
80100756:	a1 a0 b5 10 80       	mov    0x8010b5a0,%eax
8010075b:	85 c0                	test   %eax,%eax
8010075d:	74 07                	je     80100766 <consputc+0x16>
    cli();
8010075f:	e8 94 fb ff ff       	call   801002f8 <cli>
    for(;;)
      ;
80100764:	eb fe                	jmp    80100764 <consputc+0x14>
  }

  if(c == BACKSPACE){
80100766:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010076d:	75 26                	jne    80100795 <consputc+0x45>
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010076f:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100776:	e8 96 65 00 00       	call   80106d11 <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 8a 65 00 00       	call   80106d11 <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 7e 65 00 00       	call   80106d11 <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 71 65 00 00       	call   80106d11 <uartputc>
  cgaputc(c);
801007a0:	8b 45 08             	mov    0x8(%ebp),%eax
801007a3:	89 04 24             	mov    %eax,(%esp)
801007a6:	e8 22 fe ff ff       	call   801005cd <cgaputc>
}
801007ab:	c9                   	leave  
801007ac:	c3                   	ret    

801007ad <consoleintr>:

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
801007ad:	55                   	push   %ebp
801007ae:	89 e5                	mov    %esp,%ebp
801007b0:	83 ec 28             	sub    $0x28,%esp
  int c;

  acquire(&input.lock);
801007b3:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
801007ba:	e8 e0 48 00 00       	call   8010509f <acquire>
  while((c = getc()) >= 0){
801007bf:	e9 41 01 00 00       	jmp    80100905 <consoleintr+0x158>
    switch(c){
801007c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801007c7:	83 f8 10             	cmp    $0x10,%eax
801007ca:	74 1e                	je     801007ea <consoleintr+0x3d>
801007cc:	83 f8 10             	cmp    $0x10,%eax
801007cf:	7f 0a                	jg     801007db <consoleintr+0x2e>
801007d1:	83 f8 08             	cmp    $0x8,%eax
801007d4:	74 68                	je     8010083e <consoleintr+0x91>
801007d6:	e9 94 00 00 00       	jmp    8010086f <consoleintr+0xc2>
801007db:	83 f8 15             	cmp    $0x15,%eax
801007de:	74 2f                	je     8010080f <consoleintr+0x62>
801007e0:	83 f8 7f             	cmp    $0x7f,%eax
801007e3:	74 59                	je     8010083e <consoleintr+0x91>
801007e5:	e9 85 00 00 00       	jmp    8010086f <consoleintr+0xc2>
    case C('P'):  // Process listing.
      procdump();
801007ea:	e8 12 47 00 00       	call   80104f01 <procdump>
      break;
801007ef:	e9 11 01 00 00       	jmp    80100905 <consoleintr+0x158>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
801007f4:	a1 3c 08 11 80       	mov    0x8011083c,%eax
801007f9:	83 e8 01             	sub    $0x1,%eax
801007fc:	a3 3c 08 11 80       	mov    %eax,0x8011083c
        consputc(BACKSPACE);
80100801:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100808:	e8 43 ff ff ff       	call   80100750 <consputc>
8010080d:	eb 01                	jmp    80100810 <consoleintr+0x63>
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
8010080f:	90                   	nop
80100810:	8b 15 3c 08 11 80    	mov    0x8011083c,%edx
80100816:	a1 38 08 11 80       	mov    0x80110838,%eax
8010081b:	39 c2                	cmp    %eax,%edx
8010081d:	0f 84 db 00 00 00    	je     801008fe <consoleintr+0x151>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100823:	a1 3c 08 11 80       	mov    0x8011083c,%eax
80100828:	83 e8 01             	sub    $0x1,%eax
8010082b:	83 e0 7f             	and    $0x7f,%eax
8010082e:	0f b6 80 b4 07 11 80 	movzbl -0x7feef84c(%eax),%eax
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100835:	3c 0a                	cmp    $0xa,%al
80100837:	75 bb                	jne    801007f4 <consoleintr+0x47>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100839:	e9 c0 00 00 00       	jmp    801008fe <consoleintr+0x151>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
8010083e:	8b 15 3c 08 11 80    	mov    0x8011083c,%edx
80100844:	a1 38 08 11 80       	mov    0x80110838,%eax
80100849:	39 c2                	cmp    %eax,%edx
8010084b:	0f 84 b0 00 00 00    	je     80100901 <consoleintr+0x154>
        input.e--;
80100851:	a1 3c 08 11 80       	mov    0x8011083c,%eax
80100856:	83 e8 01             	sub    $0x1,%eax
80100859:	a3 3c 08 11 80       	mov    %eax,0x8011083c
        consputc(BACKSPACE);
8010085e:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100865:	e8 e6 fe ff ff       	call   80100750 <consputc>
      }
      break;
8010086a:	e9 92 00 00 00       	jmp    80100901 <consoleintr+0x154>
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
8010086f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100873:	0f 84 8b 00 00 00    	je     80100904 <consoleintr+0x157>
80100879:	8b 15 3c 08 11 80    	mov    0x8011083c,%edx
8010087f:	a1 34 08 11 80       	mov    0x80110834,%eax
80100884:	89 d1                	mov    %edx,%ecx
80100886:	29 c1                	sub    %eax,%ecx
80100888:	89 c8                	mov    %ecx,%eax
8010088a:	83 f8 7f             	cmp    $0x7f,%eax
8010088d:	77 75                	ja     80100904 <consoleintr+0x157>
        c = (c == '\r') ? '\n' : c;
8010088f:	83 7d f4 0d          	cmpl   $0xd,-0xc(%ebp)
80100893:	74 05                	je     8010089a <consoleintr+0xed>
80100895:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100898:	eb 05                	jmp    8010089f <consoleintr+0xf2>
8010089a:	b8 0a 00 00 00       	mov    $0xa,%eax
8010089f:	89 45 f4             	mov    %eax,-0xc(%ebp)
        input.buf[input.e++ % INPUT_BUF] = c;
801008a2:	a1 3c 08 11 80       	mov    0x8011083c,%eax
801008a7:	89 c1                	mov    %eax,%ecx
801008a9:	83 e1 7f             	and    $0x7f,%ecx
801008ac:	8b 55 f4             	mov    -0xc(%ebp),%edx
801008af:	88 91 b4 07 11 80    	mov    %dl,-0x7feef84c(%ecx)
801008b5:	83 c0 01             	add    $0x1,%eax
801008b8:	a3 3c 08 11 80       	mov    %eax,0x8011083c
        consputc(c);
801008bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008c0:	89 04 24             	mov    %eax,(%esp)
801008c3:	e8 88 fe ff ff       	call   80100750 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801008c8:	83 7d f4 0a          	cmpl   $0xa,-0xc(%ebp)
801008cc:	74 18                	je     801008e6 <consoleintr+0x139>
801008ce:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
801008d2:	74 12                	je     801008e6 <consoleintr+0x139>
801008d4:	a1 3c 08 11 80       	mov    0x8011083c,%eax
801008d9:	8b 15 34 08 11 80    	mov    0x80110834,%edx
801008df:	83 ea 80             	sub    $0xffffff80,%edx
801008e2:	39 d0                	cmp    %edx,%eax
801008e4:	75 1e                	jne    80100904 <consoleintr+0x157>
          input.w = input.e;
801008e6:	a1 3c 08 11 80       	mov    0x8011083c,%eax
801008eb:	a3 38 08 11 80       	mov    %eax,0x80110838
          wakeup(&input.r);
801008f0:	c7 04 24 34 08 11 80 	movl   $0x80110834,(%esp)
801008f7:	e8 5c 45 00 00       	call   80104e58 <wakeup>
        }
      }
      break;
801008fc:	eb 06                	jmp    80100904 <consoleintr+0x157>
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
801008fe:	90                   	nop
801008ff:	eb 04                	jmp    80100905 <consoleintr+0x158>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100901:	90                   	nop
80100902:	eb 01                	jmp    80100905 <consoleintr+0x158>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
          input.w = input.e;
          wakeup(&input.r);
        }
      }
      break;
80100904:	90                   	nop
consoleintr(int (*getc)(void))
{
  int c;

  acquire(&input.lock);
  while((c = getc()) >= 0){
80100905:	8b 45 08             	mov    0x8(%ebp),%eax
80100908:	ff d0                	call   *%eax
8010090a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010090d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100911:	0f 89 ad fe ff ff    	jns    801007c4 <consoleintr+0x17>
        }
      }
      break;
    }
  }
  release(&input.lock);
80100917:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
8010091e:	e8 de 47 00 00       	call   80105101 <release>
}
80100923:	c9                   	leave  
80100924:	c3                   	ret    

80100925 <consoleread>:

int
consoleread(struct inode *ip, char *dst, int n)
{
80100925:	55                   	push   %ebp
80100926:	89 e5                	mov    %esp,%ebp
80100928:	83 ec 28             	sub    $0x28,%esp
  uint target;
  int c;

  iunlock(ip);
8010092b:	8b 45 08             	mov    0x8(%ebp),%eax
8010092e:	89 04 24             	mov    %eax,(%esp)
80100931:	e8 b8 10 00 00       	call   801019ee <iunlock>
  target = n;
80100936:	8b 45 10             	mov    0x10(%ebp),%eax
80100939:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
8010093c:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
80100943:	e8 57 47 00 00       	call   8010509f <acquire>
  while(n > 0){
80100948:	e9 ab 00 00 00       	jmp    801009f8 <consoleread+0xd3>
    while(input.r == input.w){
      if(proc->killed){
8010094d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100953:	8b 80 48 02 00 00    	mov    0x248(%eax),%eax
80100959:	85 c0                	test   %eax,%eax
8010095b:	74 21                	je     8010097e <consoleread+0x59>
        release(&input.lock);
8010095d:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
80100964:	e8 98 47 00 00       	call   80105101 <release>
        ilock(ip);
80100969:	8b 45 08             	mov    0x8(%ebp),%eax
8010096c:	89 04 24             	mov    %eax,(%esp)
8010096f:	e8 2c 0f 00 00       	call   801018a0 <ilock>
        return -1;
80100974:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100979:	e9 a9 00 00 00       	jmp    80100a27 <consoleread+0x102>
      }
      sleep(&input.r, &input.lock);
8010097e:	c7 44 24 04 80 07 11 	movl   $0x80110780,0x4(%esp)
80100985:	80 
80100986:	c7 04 24 34 08 11 80 	movl   $0x80110834,(%esp)
8010098d:	e8 b7 43 00 00       	call   80104d49 <sleep>
80100992:	eb 01                	jmp    80100995 <consoleread+0x70>

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
80100994:	90                   	nop
80100995:	8b 15 34 08 11 80    	mov    0x80110834,%edx
8010099b:	a1 38 08 11 80       	mov    0x80110838,%eax
801009a0:	39 c2                	cmp    %eax,%edx
801009a2:	74 a9                	je     8010094d <consoleread+0x28>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
801009a4:	a1 34 08 11 80       	mov    0x80110834,%eax
801009a9:	89 c2                	mov    %eax,%edx
801009ab:	83 e2 7f             	and    $0x7f,%edx
801009ae:	0f b6 92 b4 07 11 80 	movzbl -0x7feef84c(%edx),%edx
801009b5:	0f be d2             	movsbl %dl,%edx
801009b8:	89 55 f0             	mov    %edx,-0x10(%ebp)
801009bb:	83 c0 01             	add    $0x1,%eax
801009be:	a3 34 08 11 80       	mov    %eax,0x80110834
    if(c == C('D')){  // EOF
801009c3:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
801009c7:	75 17                	jne    801009e0 <consoleread+0xbb>
      if(n < target){
801009c9:	8b 45 10             	mov    0x10(%ebp),%eax
801009cc:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801009cf:	73 2f                	jae    80100a00 <consoleread+0xdb>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
801009d1:	a1 34 08 11 80       	mov    0x80110834,%eax
801009d6:	83 e8 01             	sub    $0x1,%eax
801009d9:	a3 34 08 11 80       	mov    %eax,0x80110834
      }
      break;
801009de:	eb 20                	jmp    80100a00 <consoleread+0xdb>
    }
    *dst++ = c;
801009e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801009e3:	89 c2                	mov    %eax,%edx
801009e5:	8b 45 0c             	mov    0xc(%ebp),%eax
801009e8:	88 10                	mov    %dl,(%eax)
801009ea:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
    --n;
801009ee:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
    if(c == '\n')
801009f2:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
801009f6:	74 0b                	je     80100a03 <consoleread+0xde>
  int c;

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
801009f8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801009fc:	7f 96                	jg     80100994 <consoleread+0x6f>
801009fe:	eb 04                	jmp    80100a04 <consoleread+0xdf>
      if(n < target){
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
      }
      break;
80100a00:	90                   	nop
80100a01:	eb 01                	jmp    80100a04 <consoleread+0xdf>
    }
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
80100a03:	90                   	nop
  }
  release(&input.lock);
80100a04:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
80100a0b:	e8 f1 46 00 00       	call   80105101 <release>
  ilock(ip);
80100a10:	8b 45 08             	mov    0x8(%ebp),%eax
80100a13:	89 04 24             	mov    %eax,(%esp)
80100a16:	e8 85 0e 00 00       	call   801018a0 <ilock>

  return target - n;
80100a1b:	8b 45 10             	mov    0x10(%ebp),%eax
80100a1e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a21:	89 d1                	mov    %edx,%ecx
80100a23:	29 c1                	sub    %eax,%ecx
80100a25:	89 c8                	mov    %ecx,%eax
}
80100a27:	c9                   	leave  
80100a28:	c3                   	ret    

80100a29 <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
80100a29:	55                   	push   %ebp
80100a2a:	89 e5                	mov    %esp,%ebp
80100a2c:	83 ec 28             	sub    $0x28,%esp
  int i;

  iunlock(ip);
80100a2f:	8b 45 08             	mov    0x8(%ebp),%eax
80100a32:	89 04 24             	mov    %eax,(%esp)
80100a35:	e8 b4 0f 00 00       	call   801019ee <iunlock>
  acquire(&cons.lock);
80100a3a:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a41:	e8 59 46 00 00       	call   8010509f <acquire>
  for(i = 0; i < n; i++)
80100a46:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100a4d:	eb 1d                	jmp    80100a6c <consolewrite+0x43>
    consputc(buf[i] & 0xff);
80100a4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100a52:	03 45 0c             	add    0xc(%ebp),%eax
80100a55:	0f b6 00             	movzbl (%eax),%eax
80100a58:	0f be c0             	movsbl %al,%eax
80100a5b:	25 ff 00 00 00       	and    $0xff,%eax
80100a60:	89 04 24             	mov    %eax,(%esp)
80100a63:	e8 e8 fc ff ff       	call   80100750 <consputc>
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
80100a68:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100a6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100a6f:	3b 45 10             	cmp    0x10(%ebp),%eax
80100a72:	7c db                	jl     80100a4f <consolewrite+0x26>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
80100a74:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a7b:	e8 81 46 00 00       	call   80105101 <release>
  ilock(ip);
80100a80:	8b 45 08             	mov    0x8(%ebp),%eax
80100a83:	89 04 24             	mov    %eax,(%esp)
80100a86:	e8 15 0e 00 00       	call   801018a0 <ilock>

  return n;
80100a8b:	8b 45 10             	mov    0x10(%ebp),%eax
}
80100a8e:	c9                   	leave  
80100a8f:	c3                   	ret    

80100a90 <consoleinit>:

void
consoleinit(void)
{
80100a90:	55                   	push   %ebp
80100a91:	89 e5                	mov    %esp,%ebp
80100a93:	83 ec 18             	sub    $0x18,%esp
  initlock(&cons.lock, "console");
80100a96:	c7 44 24 04 0b 87 10 	movl   $0x8010870b,0x4(%esp)
80100a9d:	80 
80100a9e:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100aa5:	e8 d4 45 00 00       	call   8010507e <initlock>
  initlock(&input.lock, "input");
80100aaa:	c7 44 24 04 13 87 10 	movl   $0x80108713,0x4(%esp)
80100ab1:	80 
80100ab2:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
80100ab9:	e8 c0 45 00 00       	call   8010507e <initlock>

  devsw[CONSOLE].write = consolewrite;
80100abe:	c7 05 ec 11 11 80 29 	movl   $0x80100a29,0x801111ec
80100ac5:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ac8:	c7 05 e8 11 11 80 25 	movl   $0x80100925,0x801111e8
80100acf:	09 10 80 
  cons.locking = 1;
80100ad2:	c7 05 f4 b5 10 80 01 	movl   $0x1,0x8010b5f4
80100ad9:	00 00 00 

  picenable(IRQ_KBD);
80100adc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ae3:	e8 61 33 00 00       	call   80103e49 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ae8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100aef:	00 
80100af0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100af7:	e8 b6 1e 00 00       	call   801029b2 <ioapicenable>
}
80100afc:	c9                   	leave  
80100afd:	c3                   	ret    
	...

80100b00 <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
80100b00:	55                   	push   %ebp
80100b01:	89 e5                	mov    %esp,%ebp
80100b03:	81 ec 38 01 00 00    	sub    $0x138,%esp
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;

  begin_op();
80100b09:	e8 83 29 00 00       	call   80103491 <begin_op>
  if((ip = namei(path)) == 0){
80100b0e:	8b 45 08             	mov    0x8(%ebp),%eax
80100b11:	89 04 24             	mov    %eax,(%esp)
80100b14:	e8 2c 19 00 00       	call   80102445 <namei>
80100b19:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b1c:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b20:	75 0f                	jne    80100b31 <exec+0x31>
    end_op();
80100b22:	e8 eb 29 00 00       	call   80103512 <end_op>
    return -1;
80100b27:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b2c:	e9 02 04 00 00       	jmp    80100f33 <exec+0x433>
  }
  ilock(ip);
80100b31:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b34:	89 04 24             	mov    %eax,(%esp)
80100b37:	e8 64 0d 00 00       	call   801018a0 <ilock>
  
  struct thread *t;
  for(t = proc->threads; t < &proc->threads[NTHREAD]; t++){
80100b3c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100b42:	83 c0 48             	add    $0x48,%eax
80100b45:	89 45 d0             	mov    %eax,-0x30(%ebp)
80100b48:	eb 04                	jmp    80100b4e <exec+0x4e>
80100b4a:	83 45 d0 20          	addl   $0x20,-0x30(%ebp)
80100b4e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100b54:	05 48 02 00 00       	add    $0x248,%eax
80100b59:	3b 45 d0             	cmp    -0x30(%ebp),%eax
80100b5c:	77 ec                	ja     80100b4a <exec+0x4a>
	// t->killed = 1; //uncomment once global proc changes to global thread, so I dont kill myself
  }
  
  pgdir = 0;
80100b5e:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
80100b65:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
80100b6c:	00 
80100b6d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100b74:	00 
80100b75:	8d 85 08 ff ff ff    	lea    -0xf8(%ebp),%eax
80100b7b:	89 44 24 04          	mov    %eax,0x4(%esp)
80100b7f:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b82:	89 04 24             	mov    %eax,(%esp)
80100b85:	e8 0c 12 00 00       	call   80101d96 <readi>
80100b8a:	83 f8 33             	cmp    $0x33,%eax
80100b8d:	0f 86 55 03 00 00    	jbe    80100ee8 <exec+0x3e8>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100b93:	8b 85 08 ff ff ff    	mov    -0xf8(%ebp),%eax
80100b99:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b9e:	0f 85 47 03 00 00    	jne    80100eeb <exec+0x3eb>
    goto bad;

  if((pgdir = setupkvm()) == 0)
80100ba4:	e8 ac 72 00 00       	call   80107e55 <setupkvm>
80100ba9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100bac:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100bb0:	0f 84 38 03 00 00    	je     80100eee <exec+0x3ee>
    goto bad;

  // Load program into memory.
  sz = 0;
80100bb6:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100bbd:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100bc4:	8b 85 24 ff ff ff    	mov    -0xdc(%ebp),%eax
80100bca:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100bcd:	e9 c5 00 00 00       	jmp    80100c97 <exec+0x197>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100bd2:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100bd5:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
80100bdc:	00 
80100bdd:	89 44 24 08          	mov    %eax,0x8(%esp)
80100be1:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
80100be7:	89 44 24 04          	mov    %eax,0x4(%esp)
80100beb:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100bee:	89 04 24             	mov    %eax,(%esp)
80100bf1:	e8 a0 11 00 00       	call   80101d96 <readi>
80100bf6:	83 f8 20             	cmp    $0x20,%eax
80100bf9:	0f 85 f2 02 00 00    	jne    80100ef1 <exec+0x3f1>
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
80100bff:	8b 85 e8 fe ff ff    	mov    -0x118(%ebp),%eax
80100c05:	83 f8 01             	cmp    $0x1,%eax
80100c08:	75 7f                	jne    80100c89 <exec+0x189>
      continue;
    if(ph.memsz < ph.filesz)
80100c0a:	8b 95 fc fe ff ff    	mov    -0x104(%ebp),%edx
80100c10:	8b 85 f8 fe ff ff    	mov    -0x108(%ebp),%eax
80100c16:	39 c2                	cmp    %eax,%edx
80100c18:	0f 82 d6 02 00 00    	jb     80100ef4 <exec+0x3f4>
      goto bad;
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100c1e:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80100c24:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80100c2a:	01 d0                	add    %edx,%eax
80100c2c:	89 44 24 08          	mov    %eax,0x8(%esp)
80100c30:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c33:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c37:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c3a:	89 04 24             	mov    %eax,(%esp)
80100c3d:	e8 e5 75 00 00       	call   80108227 <allocuvm>
80100c42:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100c45:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100c49:	0f 84 a8 02 00 00    	je     80100ef7 <exec+0x3f7>
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100c4f:	8b 8d f8 fe ff ff    	mov    -0x108(%ebp),%ecx
80100c55:	8b 95 ec fe ff ff    	mov    -0x114(%ebp),%edx
80100c5b:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
80100c61:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80100c65:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100c69:	8b 55 d8             	mov    -0x28(%ebp),%edx
80100c6c:	89 54 24 08          	mov    %edx,0x8(%esp)
80100c70:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c74:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c77:	89 04 24             	mov    %eax,(%esp)
80100c7a:	e8 b9 74 00 00       	call   80108138 <loaduvm>
80100c7f:	85 c0                	test   %eax,%eax
80100c81:	0f 88 73 02 00 00    	js     80100efa <exec+0x3fa>
80100c87:	eb 01                	jmp    80100c8a <exec+0x18a>
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
      continue;
80100c89:	90                   	nop
  if((pgdir = setupkvm()) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100c8a:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100c8e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100c91:	83 c0 20             	add    $0x20,%eax
80100c94:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100c97:	0f b7 85 34 ff ff ff 	movzwl -0xcc(%ebp),%eax
80100c9e:	0f b7 c0             	movzwl %ax,%eax
80100ca1:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100ca4:	0f 8f 28 ff ff ff    	jg     80100bd2 <exec+0xd2>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
80100caa:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100cad:	89 04 24             	mov    %eax,(%esp)
80100cb0:	e8 6f 0e 00 00       	call   80101b24 <iunlockput>
  end_op();
80100cb5:	e8 58 28 00 00       	call   80103512 <end_op>
  ip = 0;
80100cba:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100cc1:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cc4:	05 ff 0f 00 00       	add    $0xfff,%eax
80100cc9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100cce:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100cd1:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cd4:	05 00 20 00 00       	add    $0x2000,%eax
80100cd9:	89 44 24 08          	mov    %eax,0x8(%esp)
80100cdd:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100ce0:	89 44 24 04          	mov    %eax,0x4(%esp)
80100ce4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100ce7:	89 04 24             	mov    %eax,(%esp)
80100cea:	e8 38 75 00 00       	call   80108227 <allocuvm>
80100cef:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100cf2:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100cf6:	0f 84 01 02 00 00    	je     80100efd <exec+0x3fd>
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100cfc:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cff:	2d 00 20 00 00       	sub    $0x2000,%eax
80100d04:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d08:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d0b:	89 04 24             	mov    %eax,(%esp)
80100d0e:	e8 38 77 00 00       	call   8010844b <clearpteu>
  sp = sz;
80100d13:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d16:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100d19:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100d20:	e9 81 00 00 00       	jmp    80100da6 <exec+0x2a6>
    if(argc >= MAXARG)
80100d25:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100d29:	0f 87 d1 01 00 00    	ja     80100f00 <exec+0x400>
      goto bad;
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100d2f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d32:	c1 e0 02             	shl    $0x2,%eax
80100d35:	03 45 0c             	add    0xc(%ebp),%eax
80100d38:	8b 00                	mov    (%eax),%eax
80100d3a:	89 04 24             	mov    %eax,(%esp)
80100d3d:	e8 2a 48 00 00       	call   8010556c <strlen>
80100d42:	f7 d0                	not    %eax
80100d44:	03 45 dc             	add    -0x24(%ebp),%eax
80100d47:	83 e0 fc             	and    $0xfffffffc,%eax
80100d4a:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100d4d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d50:	c1 e0 02             	shl    $0x2,%eax
80100d53:	03 45 0c             	add    0xc(%ebp),%eax
80100d56:	8b 00                	mov    (%eax),%eax
80100d58:	89 04 24             	mov    %eax,(%esp)
80100d5b:	e8 0c 48 00 00       	call   8010556c <strlen>
80100d60:	83 c0 01             	add    $0x1,%eax
80100d63:	89 c2                	mov    %eax,%edx
80100d65:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d68:	c1 e0 02             	shl    $0x2,%eax
80100d6b:	03 45 0c             	add    0xc(%ebp),%eax
80100d6e:	8b 00                	mov    (%eax),%eax
80100d70:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100d74:	89 44 24 08          	mov    %eax,0x8(%esp)
80100d78:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d7b:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d7f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d82:	89 04 24             	mov    %eax,(%esp)
80100d85:	e8 86 78 00 00       	call   80108610 <copyout>
80100d8a:	85 c0                	test   %eax,%eax
80100d8c:	0f 88 71 01 00 00    	js     80100f03 <exec+0x403>
      goto bad;
    ustack[3+argc] = sp;
80100d92:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d95:	8d 50 03             	lea    0x3(%eax),%edx
80100d98:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d9b:	89 84 95 3c ff ff ff 	mov    %eax,-0xc4(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100da2:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100da6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100da9:	c1 e0 02             	shl    $0x2,%eax
80100dac:	03 45 0c             	add    0xc(%ebp),%eax
80100daf:	8b 00                	mov    (%eax),%eax
80100db1:	85 c0                	test   %eax,%eax
80100db3:	0f 85 6c ff ff ff    	jne    80100d25 <exec+0x225>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
80100db9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dbc:	83 c0 03             	add    $0x3,%eax
80100dbf:	c7 84 85 3c ff ff ff 	movl   $0x0,-0xc4(%ebp,%eax,4)
80100dc6:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100dca:	c7 85 3c ff ff ff ff 	movl   $0xffffffff,-0xc4(%ebp)
80100dd1:	ff ff ff 
  ustack[1] = argc;
80100dd4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dd7:	89 85 40 ff ff ff    	mov    %eax,-0xc0(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100ddd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100de0:	83 c0 01             	add    $0x1,%eax
80100de3:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100dea:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100ded:	29 d0                	sub    %edx,%eax
80100def:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)

  sp -= (3+argc+1) * 4;
80100df5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100df8:	83 c0 04             	add    $0x4,%eax
80100dfb:	c1 e0 02             	shl    $0x2,%eax
80100dfe:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100e01:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e04:	83 c0 04             	add    $0x4,%eax
80100e07:	c1 e0 02             	shl    $0x2,%eax
80100e0a:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100e0e:	8d 85 3c ff ff ff    	lea    -0xc4(%ebp),%eax
80100e14:	89 44 24 08          	mov    %eax,0x8(%esp)
80100e18:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e1b:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e1f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e22:	89 04 24             	mov    %eax,(%esp)
80100e25:	e8 e6 77 00 00       	call   80108610 <copyout>
80100e2a:	85 c0                	test   %eax,%eax
80100e2c:	0f 88 d4 00 00 00    	js     80100f06 <exec+0x406>
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e32:	8b 45 08             	mov    0x8(%ebp),%eax
80100e35:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100e38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e3b:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100e3e:	eb 17                	jmp    80100e57 <exec+0x357>
    if(*s == '/')
80100e40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e43:	0f b6 00             	movzbl (%eax),%eax
80100e46:	3c 2f                	cmp    $0x2f,%al
80100e48:	75 09                	jne    80100e53 <exec+0x353>
      last = s+1;
80100e4a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e4d:	83 c0 01             	add    $0x1,%eax
80100e50:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e53:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100e57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e5a:	0f b6 00             	movzbl (%eax),%eax
80100e5d:	84 c0                	test   %al,%al
80100e5f:	75 df                	jne    80100e40 <exec+0x340>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80100e61:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e67:	8d 90 90 02 00 00    	lea    0x290(%eax),%edx
80100e6d:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80100e74:	00 
80100e75:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100e78:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e7c:	89 14 24             	mov    %edx,(%esp)
80100e7f:	e8 9a 46 00 00       	call   8010551e <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
80100e84:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e8a:	8b 40 04             	mov    0x4(%eax),%eax
80100e8d:	89 45 cc             	mov    %eax,-0x34(%ebp)
  proc->pgdir = pgdir;
80100e90:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e96:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100e99:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
80100e9c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ea2:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100ea5:	89 10                	mov    %edx,(%eax)
  proc->threads->tf->eip = elf.entry;  // main
80100ea7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ead:	8b 40 58             	mov    0x58(%eax),%eax
80100eb0:	8b 95 20 ff ff ff    	mov    -0xe0(%ebp),%edx
80100eb6:	89 50 38             	mov    %edx,0x38(%eax)
  proc->threads->tf->esp = sp;
80100eb9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ebf:	8b 40 58             	mov    0x58(%eax),%eax
80100ec2:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100ec5:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(proc);
80100ec8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ece:	89 04 24             	mov    %eax,(%esp)
80100ed1:	e8 70 70 00 00       	call   80107f46 <switchuvm>
  freevm(oldpgdir);
80100ed6:	8b 45 cc             	mov    -0x34(%ebp),%eax
80100ed9:	89 04 24             	mov    %eax,(%esp)
80100edc:	e8 dc 74 00 00       	call   801083bd <freevm>
  return 0;
80100ee1:	b8 00 00 00 00       	mov    $0x0,%eax
80100ee6:	eb 4b                	jmp    80100f33 <exec+0x433>
  
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
    goto bad;
80100ee8:	90                   	nop
80100ee9:	eb 1c                	jmp    80100f07 <exec+0x407>
  if(elf.magic != ELF_MAGIC)
    goto bad;
80100eeb:	90                   	nop
80100eec:	eb 19                	jmp    80100f07 <exec+0x407>

  if((pgdir = setupkvm()) == 0)
    goto bad;
80100eee:	90                   	nop
80100eef:	eb 16                	jmp    80100f07 <exec+0x407>

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
80100ef1:	90                   	nop
80100ef2:	eb 13                	jmp    80100f07 <exec+0x407>
    if(ph.type != ELF_PROG_LOAD)
      continue;
    if(ph.memsz < ph.filesz)
      goto bad;
80100ef4:	90                   	nop
80100ef5:	eb 10                	jmp    80100f07 <exec+0x407>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
80100ef7:	90                   	nop
80100ef8:	eb 0d                	jmp    80100f07 <exec+0x407>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
80100efa:	90                   	nop
80100efb:	eb 0a                	jmp    80100f07 <exec+0x407>

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
    goto bad;
80100efd:	90                   	nop
80100efe:	eb 07                	jmp    80100f07 <exec+0x407>
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
    if(argc >= MAXARG)
      goto bad;
80100f00:	90                   	nop
80100f01:	eb 04                	jmp    80100f07 <exec+0x407>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
80100f03:	90                   	nop
80100f04:	eb 01                	jmp    80100f07 <exec+0x407>
  ustack[1] = argc;
  ustack[2] = sp - (argc+1)*4;  // argv pointer

  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;
80100f06:	90                   	nop
  switchuvm(proc);
  freevm(oldpgdir);
  return 0;

 bad:
  if(pgdir)
80100f07:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100f0b:	74 0b                	je     80100f18 <exec+0x418>
    freevm(pgdir);
80100f0d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100f10:	89 04 24             	mov    %eax,(%esp)
80100f13:	e8 a5 74 00 00       	call   801083bd <freevm>
  if(ip){
80100f18:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100f1c:	74 10                	je     80100f2e <exec+0x42e>
    iunlockput(ip);
80100f1e:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100f21:	89 04 24             	mov    %eax,(%esp)
80100f24:	e8 fb 0b 00 00       	call   80101b24 <iunlockput>
    end_op();
80100f29:	e8 e4 25 00 00       	call   80103512 <end_op>
  }
  return -1;
80100f2e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100f33:	c9                   	leave  
80100f34:	c3                   	ret    
80100f35:	00 00                	add    %al,(%eax)
	...

80100f38 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100f38:	55                   	push   %ebp
80100f39:	89 e5                	mov    %esp,%ebp
80100f3b:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
80100f3e:	c7 44 24 04 19 87 10 	movl   $0x80108719,0x4(%esp)
80100f45:	80 
80100f46:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100f4d:	e8 2c 41 00 00       	call   8010507e <initlock>
}
80100f52:	c9                   	leave  
80100f53:	c3                   	ret    

80100f54 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100f54:	55                   	push   %ebp
80100f55:	89 e5                	mov    %esp,%ebp
80100f57:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
80100f5a:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100f61:	e8 39 41 00 00       	call   8010509f <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f66:	c7 45 f4 74 08 11 80 	movl   $0x80110874,-0xc(%ebp)
80100f6d:	eb 29                	jmp    80100f98 <filealloc+0x44>
    if(f->ref == 0){
80100f6f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f72:	8b 40 04             	mov    0x4(%eax),%eax
80100f75:	85 c0                	test   %eax,%eax
80100f77:	75 1b                	jne    80100f94 <filealloc+0x40>
      f->ref = 1;
80100f79:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f7c:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
80100f83:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100f8a:	e8 72 41 00 00       	call   80105101 <release>
      return f;
80100f8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f92:	eb 1e                	jmp    80100fb2 <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f94:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80100f98:	81 7d f4 d4 11 11 80 	cmpl   $0x801111d4,-0xc(%ebp)
80100f9f:	72 ce                	jb     80100f6f <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80100fa1:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100fa8:	e8 54 41 00 00       	call   80105101 <release>
  return 0;
80100fad:	b8 00 00 00 00       	mov    $0x0,%eax
}
80100fb2:	c9                   	leave  
80100fb3:	c3                   	ret    

80100fb4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100fb4:	55                   	push   %ebp
80100fb5:	89 e5                	mov    %esp,%ebp
80100fb7:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
80100fba:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100fc1:	e8 d9 40 00 00       	call   8010509f <acquire>
  if(f->ref < 1)
80100fc6:	8b 45 08             	mov    0x8(%ebp),%eax
80100fc9:	8b 40 04             	mov    0x4(%eax),%eax
80100fcc:	85 c0                	test   %eax,%eax
80100fce:	7f 0c                	jg     80100fdc <filedup+0x28>
    panic("filedup");
80100fd0:	c7 04 24 20 87 10 80 	movl   $0x80108720,(%esp)
80100fd7:	e8 61 f5 ff ff       	call   8010053d <panic>
  f->ref++;
80100fdc:	8b 45 08             	mov    0x8(%ebp),%eax
80100fdf:	8b 40 04             	mov    0x4(%eax),%eax
80100fe2:	8d 50 01             	lea    0x1(%eax),%edx
80100fe5:	8b 45 08             	mov    0x8(%ebp),%eax
80100fe8:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100feb:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100ff2:	e8 0a 41 00 00       	call   80105101 <release>
  return f;
80100ff7:	8b 45 08             	mov    0x8(%ebp),%eax
}
80100ffa:	c9                   	leave  
80100ffb:	c3                   	ret    

80100ffc <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100ffc:	55                   	push   %ebp
80100ffd:	89 e5                	mov    %esp,%ebp
80100fff:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
80101002:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80101009:	e8 91 40 00 00       	call   8010509f <acquire>
  if(f->ref < 1)
8010100e:	8b 45 08             	mov    0x8(%ebp),%eax
80101011:	8b 40 04             	mov    0x4(%eax),%eax
80101014:	85 c0                	test   %eax,%eax
80101016:	7f 0c                	jg     80101024 <fileclose+0x28>
    panic("fileclose");
80101018:	c7 04 24 28 87 10 80 	movl   $0x80108728,(%esp)
8010101f:	e8 19 f5 ff ff       	call   8010053d <panic>
  if(--f->ref > 0){
80101024:	8b 45 08             	mov    0x8(%ebp),%eax
80101027:	8b 40 04             	mov    0x4(%eax),%eax
8010102a:	8d 50 ff             	lea    -0x1(%eax),%edx
8010102d:	8b 45 08             	mov    0x8(%ebp),%eax
80101030:	89 50 04             	mov    %edx,0x4(%eax)
80101033:	8b 45 08             	mov    0x8(%ebp),%eax
80101036:	8b 40 04             	mov    0x4(%eax),%eax
80101039:	85 c0                	test   %eax,%eax
8010103b:	7e 11                	jle    8010104e <fileclose+0x52>
    release(&ftable.lock);
8010103d:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80101044:	e8 b8 40 00 00       	call   80105101 <release>
    return;
80101049:	e9 82 00 00 00       	jmp    801010d0 <fileclose+0xd4>
  }
  ff = *f;
8010104e:	8b 45 08             	mov    0x8(%ebp),%eax
80101051:	8b 10                	mov    (%eax),%edx
80101053:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101056:	8b 50 04             	mov    0x4(%eax),%edx
80101059:	89 55 e4             	mov    %edx,-0x1c(%ebp)
8010105c:	8b 50 08             	mov    0x8(%eax),%edx
8010105f:	89 55 e8             	mov    %edx,-0x18(%ebp)
80101062:	8b 50 0c             	mov    0xc(%eax),%edx
80101065:	89 55 ec             	mov    %edx,-0x14(%ebp)
80101068:	8b 50 10             	mov    0x10(%eax),%edx
8010106b:	89 55 f0             	mov    %edx,-0x10(%ebp)
8010106e:	8b 40 14             	mov    0x14(%eax),%eax
80101071:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
80101074:	8b 45 08             	mov    0x8(%ebp),%eax
80101077:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
8010107e:	8b 45 08             	mov    0x8(%ebp),%eax
80101081:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
80101087:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
8010108e:	e8 6e 40 00 00       	call   80105101 <release>
  
  if(ff.type == FD_PIPE)
80101093:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101096:	83 f8 01             	cmp    $0x1,%eax
80101099:	75 18                	jne    801010b3 <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
8010109b:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
8010109f:	0f be d0             	movsbl %al,%edx
801010a2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801010a5:	89 54 24 04          	mov    %edx,0x4(%esp)
801010a9:	89 04 24             	mov    %eax,(%esp)
801010ac:	e8 52 30 00 00       	call   80104103 <pipeclose>
801010b1:	eb 1d                	jmp    801010d0 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
801010b3:	8b 45 e0             	mov    -0x20(%ebp),%eax
801010b6:	83 f8 02             	cmp    $0x2,%eax
801010b9:	75 15                	jne    801010d0 <fileclose+0xd4>
    begin_op();
801010bb:	e8 d1 23 00 00       	call   80103491 <begin_op>
    iput(ff.ip);
801010c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801010c3:	89 04 24             	mov    %eax,(%esp)
801010c6:	e8 88 09 00 00       	call   80101a53 <iput>
    end_op();
801010cb:	e8 42 24 00 00       	call   80103512 <end_op>
  }
}
801010d0:	c9                   	leave  
801010d1:	c3                   	ret    

801010d2 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
801010d2:	55                   	push   %ebp
801010d3:	89 e5                	mov    %esp,%ebp
801010d5:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
801010d8:	8b 45 08             	mov    0x8(%ebp),%eax
801010db:	8b 00                	mov    (%eax),%eax
801010dd:	83 f8 02             	cmp    $0x2,%eax
801010e0:	75 38                	jne    8010111a <filestat+0x48>
    ilock(f->ip);
801010e2:	8b 45 08             	mov    0x8(%ebp),%eax
801010e5:	8b 40 10             	mov    0x10(%eax),%eax
801010e8:	89 04 24             	mov    %eax,(%esp)
801010eb:	e8 b0 07 00 00       	call   801018a0 <ilock>
    stati(f->ip, st);
801010f0:	8b 45 08             	mov    0x8(%ebp),%eax
801010f3:	8b 40 10             	mov    0x10(%eax),%eax
801010f6:	8b 55 0c             	mov    0xc(%ebp),%edx
801010f9:	89 54 24 04          	mov    %edx,0x4(%esp)
801010fd:	89 04 24             	mov    %eax,(%esp)
80101100:	e8 4c 0c 00 00       	call   80101d51 <stati>
    iunlock(f->ip);
80101105:	8b 45 08             	mov    0x8(%ebp),%eax
80101108:	8b 40 10             	mov    0x10(%eax),%eax
8010110b:	89 04 24             	mov    %eax,(%esp)
8010110e:	e8 db 08 00 00       	call   801019ee <iunlock>
    return 0;
80101113:	b8 00 00 00 00       	mov    $0x0,%eax
80101118:	eb 05                	jmp    8010111f <filestat+0x4d>
  }
  return -1;
8010111a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010111f:	c9                   	leave  
80101120:	c3                   	ret    

80101121 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
80101121:	55                   	push   %ebp
80101122:	89 e5                	mov    %esp,%ebp
80101124:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
80101127:	8b 45 08             	mov    0x8(%ebp),%eax
8010112a:	0f b6 40 08          	movzbl 0x8(%eax),%eax
8010112e:	84 c0                	test   %al,%al
80101130:	75 0a                	jne    8010113c <fileread+0x1b>
    return -1;
80101132:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101137:	e9 9f 00 00 00       	jmp    801011db <fileread+0xba>
  if(f->type == FD_PIPE)
8010113c:	8b 45 08             	mov    0x8(%ebp),%eax
8010113f:	8b 00                	mov    (%eax),%eax
80101141:	83 f8 01             	cmp    $0x1,%eax
80101144:	75 1e                	jne    80101164 <fileread+0x43>
    return piperead(f->pipe, addr, n);
80101146:	8b 45 08             	mov    0x8(%ebp),%eax
80101149:	8b 40 0c             	mov    0xc(%eax),%eax
8010114c:	8b 55 10             	mov    0x10(%ebp),%edx
8010114f:	89 54 24 08          	mov    %edx,0x8(%esp)
80101153:	8b 55 0c             	mov    0xc(%ebp),%edx
80101156:	89 54 24 04          	mov    %edx,0x4(%esp)
8010115a:	89 04 24             	mov    %eax,(%esp)
8010115d:	e8 26 31 00 00       	call   80104288 <piperead>
80101162:	eb 77                	jmp    801011db <fileread+0xba>
  if(f->type == FD_INODE){
80101164:	8b 45 08             	mov    0x8(%ebp),%eax
80101167:	8b 00                	mov    (%eax),%eax
80101169:	83 f8 02             	cmp    $0x2,%eax
8010116c:	75 61                	jne    801011cf <fileread+0xae>
    ilock(f->ip);
8010116e:	8b 45 08             	mov    0x8(%ebp),%eax
80101171:	8b 40 10             	mov    0x10(%eax),%eax
80101174:	89 04 24             	mov    %eax,(%esp)
80101177:	e8 24 07 00 00       	call   801018a0 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
8010117c:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010117f:	8b 45 08             	mov    0x8(%ebp),%eax
80101182:	8b 50 14             	mov    0x14(%eax),%edx
80101185:	8b 45 08             	mov    0x8(%ebp),%eax
80101188:	8b 40 10             	mov    0x10(%eax),%eax
8010118b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010118f:	89 54 24 08          	mov    %edx,0x8(%esp)
80101193:	8b 55 0c             	mov    0xc(%ebp),%edx
80101196:	89 54 24 04          	mov    %edx,0x4(%esp)
8010119a:	89 04 24             	mov    %eax,(%esp)
8010119d:	e8 f4 0b 00 00       	call   80101d96 <readi>
801011a2:	89 45 f4             	mov    %eax,-0xc(%ebp)
801011a5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801011a9:	7e 11                	jle    801011bc <fileread+0x9b>
      f->off += r;
801011ab:	8b 45 08             	mov    0x8(%ebp),%eax
801011ae:	8b 50 14             	mov    0x14(%eax),%edx
801011b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801011b4:	01 c2                	add    %eax,%edx
801011b6:	8b 45 08             	mov    0x8(%ebp),%eax
801011b9:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
801011bc:	8b 45 08             	mov    0x8(%ebp),%eax
801011bf:	8b 40 10             	mov    0x10(%eax),%eax
801011c2:	89 04 24             	mov    %eax,(%esp)
801011c5:	e8 24 08 00 00       	call   801019ee <iunlock>
    return r;
801011ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801011cd:	eb 0c                	jmp    801011db <fileread+0xba>
  }
  panic("fileread");
801011cf:	c7 04 24 32 87 10 80 	movl   $0x80108732,(%esp)
801011d6:	e8 62 f3 ff ff       	call   8010053d <panic>
}
801011db:	c9                   	leave  
801011dc:	c3                   	ret    

801011dd <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
801011dd:	55                   	push   %ebp
801011de:	89 e5                	mov    %esp,%ebp
801011e0:	53                   	push   %ebx
801011e1:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
801011e4:	8b 45 08             	mov    0x8(%ebp),%eax
801011e7:	0f b6 40 09          	movzbl 0x9(%eax),%eax
801011eb:	84 c0                	test   %al,%al
801011ed:	75 0a                	jne    801011f9 <filewrite+0x1c>
    return -1;
801011ef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801011f4:	e9 23 01 00 00       	jmp    8010131c <filewrite+0x13f>
  if(f->type == FD_PIPE)
801011f9:	8b 45 08             	mov    0x8(%ebp),%eax
801011fc:	8b 00                	mov    (%eax),%eax
801011fe:	83 f8 01             	cmp    $0x1,%eax
80101201:	75 21                	jne    80101224 <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
80101203:	8b 45 08             	mov    0x8(%ebp),%eax
80101206:	8b 40 0c             	mov    0xc(%eax),%eax
80101209:	8b 55 10             	mov    0x10(%ebp),%edx
8010120c:	89 54 24 08          	mov    %edx,0x8(%esp)
80101210:	8b 55 0c             	mov    0xc(%ebp),%edx
80101213:	89 54 24 04          	mov    %edx,0x4(%esp)
80101217:	89 04 24             	mov    %eax,(%esp)
8010121a:	e8 76 2f 00 00       	call   80104195 <pipewrite>
8010121f:	e9 f8 00 00 00       	jmp    8010131c <filewrite+0x13f>
  if(f->type == FD_INODE){
80101224:	8b 45 08             	mov    0x8(%ebp),%eax
80101227:	8b 00                	mov    (%eax),%eax
80101229:	83 f8 02             	cmp    $0x2,%eax
8010122c:	0f 85 de 00 00 00    	jne    80101310 <filewrite+0x133>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
80101232:	c7 45 ec 00 1a 00 00 	movl   $0x1a00,-0x14(%ebp)
    int i = 0;
80101239:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
80101240:	e9 a8 00 00 00       	jmp    801012ed <filewrite+0x110>
      int n1 = n - i;
80101245:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101248:	8b 55 10             	mov    0x10(%ebp),%edx
8010124b:	89 d1                	mov    %edx,%ecx
8010124d:	29 c1                	sub    %eax,%ecx
8010124f:	89 c8                	mov    %ecx,%eax
80101251:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
80101254:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101257:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010125a:	7e 06                	jle    80101262 <filewrite+0x85>
        n1 = max;
8010125c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010125f:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_op();
80101262:	e8 2a 22 00 00       	call   80103491 <begin_op>
      ilock(f->ip);
80101267:	8b 45 08             	mov    0x8(%ebp),%eax
8010126a:	8b 40 10             	mov    0x10(%eax),%eax
8010126d:	89 04 24             	mov    %eax,(%esp)
80101270:	e8 2b 06 00 00       	call   801018a0 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80101275:	8b 5d f0             	mov    -0x10(%ebp),%ebx
80101278:	8b 45 08             	mov    0x8(%ebp),%eax
8010127b:	8b 48 14             	mov    0x14(%eax),%ecx
8010127e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101281:	89 c2                	mov    %eax,%edx
80101283:	03 55 0c             	add    0xc(%ebp),%edx
80101286:	8b 45 08             	mov    0x8(%ebp),%eax
80101289:	8b 40 10             	mov    0x10(%eax),%eax
8010128c:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80101290:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80101294:	89 54 24 04          	mov    %edx,0x4(%esp)
80101298:	89 04 24             	mov    %eax,(%esp)
8010129b:	e8 61 0c 00 00       	call   80101f01 <writei>
801012a0:	89 45 e8             	mov    %eax,-0x18(%ebp)
801012a3:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801012a7:	7e 11                	jle    801012ba <filewrite+0xdd>
        f->off += r;
801012a9:	8b 45 08             	mov    0x8(%ebp),%eax
801012ac:	8b 50 14             	mov    0x14(%eax),%edx
801012af:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012b2:	01 c2                	add    %eax,%edx
801012b4:	8b 45 08             	mov    0x8(%ebp),%eax
801012b7:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
801012ba:	8b 45 08             	mov    0x8(%ebp),%eax
801012bd:	8b 40 10             	mov    0x10(%eax),%eax
801012c0:	89 04 24             	mov    %eax,(%esp)
801012c3:	e8 26 07 00 00       	call   801019ee <iunlock>
      end_op();
801012c8:	e8 45 22 00 00       	call   80103512 <end_op>

      if(r < 0)
801012cd:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801012d1:	78 28                	js     801012fb <filewrite+0x11e>
        break;
      if(r != n1)
801012d3:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012d6:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012d9:	74 0c                	je     801012e7 <filewrite+0x10a>
        panic("short filewrite");
801012db:	c7 04 24 3b 87 10 80 	movl   $0x8010873b,(%esp)
801012e2:	e8 56 f2 ff ff       	call   8010053d <panic>
      i += r;
801012e7:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012ea:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
801012ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012f0:	3b 45 10             	cmp    0x10(%ebp),%eax
801012f3:	0f 8c 4c ff ff ff    	jl     80101245 <filewrite+0x68>
801012f9:	eb 01                	jmp    801012fc <filewrite+0x11f>
        f->off += r;
      iunlock(f->ip);
      end_op();

      if(r < 0)
        break;
801012fb:	90                   	nop
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
801012fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012ff:	3b 45 10             	cmp    0x10(%ebp),%eax
80101302:	75 05                	jne    80101309 <filewrite+0x12c>
80101304:	8b 45 10             	mov    0x10(%ebp),%eax
80101307:	eb 05                	jmp    8010130e <filewrite+0x131>
80101309:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010130e:	eb 0c                	jmp    8010131c <filewrite+0x13f>
  }
  panic("filewrite");
80101310:	c7 04 24 4b 87 10 80 	movl   $0x8010874b,(%esp)
80101317:	e8 21 f2 ff ff       	call   8010053d <panic>
}
8010131c:	83 c4 24             	add    $0x24,%esp
8010131f:	5b                   	pop    %ebx
80101320:	5d                   	pop    %ebp
80101321:	c3                   	ret    
	...

80101324 <readsb>:
static void itrunc(struct inode*);

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
80101324:	55                   	push   %ebp
80101325:	89 e5                	mov    %esp,%ebp
80101327:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
8010132a:	8b 45 08             	mov    0x8(%ebp),%eax
8010132d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80101334:	00 
80101335:	89 04 24             	mov    %eax,(%esp)
80101338:	e8 69 ee ff ff       	call   801001a6 <bread>
8010133d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
80101340:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101343:	83 c0 18             	add    $0x18,%eax
80101346:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010134d:	00 
8010134e:	89 44 24 04          	mov    %eax,0x4(%esp)
80101352:	8b 45 0c             	mov    0xc(%ebp),%eax
80101355:	89 04 24             	mov    %eax,(%esp)
80101358:	e8 64 40 00 00       	call   801053c1 <memmove>
  brelse(bp);
8010135d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101360:	89 04 24             	mov    %eax,(%esp)
80101363:	e8 af ee ff ff       	call   80100217 <brelse>
}
80101368:	c9                   	leave  
80101369:	c3                   	ret    

8010136a <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
8010136a:	55                   	push   %ebp
8010136b:	89 e5                	mov    %esp,%ebp
8010136d:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
80101370:	8b 55 0c             	mov    0xc(%ebp),%edx
80101373:	8b 45 08             	mov    0x8(%ebp),%eax
80101376:	89 54 24 04          	mov    %edx,0x4(%esp)
8010137a:	89 04 24             	mov    %eax,(%esp)
8010137d:	e8 24 ee ff ff       	call   801001a6 <bread>
80101382:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
80101385:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101388:	83 c0 18             	add    $0x18,%eax
8010138b:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80101392:	00 
80101393:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010139a:	00 
8010139b:	89 04 24             	mov    %eax,(%esp)
8010139e:	e8 4b 3f 00 00       	call   801052ee <memset>
  log_write(bp);
801013a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013a6:	89 04 24             	mov    %eax,(%esp)
801013a9:	e8 e8 22 00 00       	call   80103696 <log_write>
  brelse(bp);
801013ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013b1:	89 04 24             	mov    %eax,(%esp)
801013b4:	e8 5e ee ff ff       	call   80100217 <brelse>
}
801013b9:	c9                   	leave  
801013ba:	c3                   	ret    

801013bb <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
801013bb:	55                   	push   %ebp
801013bc:	89 e5                	mov    %esp,%ebp
801013be:	53                   	push   %ebx
801013bf:	83 ec 34             	sub    $0x34,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
801013c2:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
801013c9:	8b 45 08             	mov    0x8(%ebp),%eax
801013cc:	8d 55 d8             	lea    -0x28(%ebp),%edx
801013cf:	89 54 24 04          	mov    %edx,0x4(%esp)
801013d3:	89 04 24             	mov    %eax,(%esp)
801013d6:	e8 49 ff ff ff       	call   80101324 <readsb>
  for(b = 0; b < sb.size; b += BPB){
801013db:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801013e2:	e9 11 01 00 00       	jmp    801014f8 <balloc+0x13d>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
801013e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013ea:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
801013f0:	85 c0                	test   %eax,%eax
801013f2:	0f 48 c2             	cmovs  %edx,%eax
801013f5:	c1 f8 0c             	sar    $0xc,%eax
801013f8:	8b 55 e0             	mov    -0x20(%ebp),%edx
801013fb:	c1 ea 03             	shr    $0x3,%edx
801013fe:	01 d0                	add    %edx,%eax
80101400:	83 c0 03             	add    $0x3,%eax
80101403:	89 44 24 04          	mov    %eax,0x4(%esp)
80101407:	8b 45 08             	mov    0x8(%ebp),%eax
8010140a:	89 04 24             	mov    %eax,(%esp)
8010140d:	e8 94 ed ff ff       	call   801001a6 <bread>
80101412:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101415:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010141c:	e9 a7 00 00 00       	jmp    801014c8 <balloc+0x10d>
      m = 1 << (bi % 8);
80101421:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101424:	89 c2                	mov    %eax,%edx
80101426:	c1 fa 1f             	sar    $0x1f,%edx
80101429:	c1 ea 1d             	shr    $0x1d,%edx
8010142c:	01 d0                	add    %edx,%eax
8010142e:	83 e0 07             	and    $0x7,%eax
80101431:	29 d0                	sub    %edx,%eax
80101433:	ba 01 00 00 00       	mov    $0x1,%edx
80101438:	89 d3                	mov    %edx,%ebx
8010143a:	89 c1                	mov    %eax,%ecx
8010143c:	d3 e3                	shl    %cl,%ebx
8010143e:	89 d8                	mov    %ebx,%eax
80101440:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
80101443:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101446:	8d 50 07             	lea    0x7(%eax),%edx
80101449:	85 c0                	test   %eax,%eax
8010144b:	0f 48 c2             	cmovs  %edx,%eax
8010144e:	c1 f8 03             	sar    $0x3,%eax
80101451:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101454:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101459:	0f b6 c0             	movzbl %al,%eax
8010145c:	23 45 e8             	and    -0x18(%ebp),%eax
8010145f:	85 c0                	test   %eax,%eax
80101461:	75 61                	jne    801014c4 <balloc+0x109>
        bp->data[bi/8] |= m;  // Mark block in use.
80101463:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101466:	8d 50 07             	lea    0x7(%eax),%edx
80101469:	85 c0                	test   %eax,%eax
8010146b:	0f 48 c2             	cmovs  %edx,%eax
8010146e:	c1 f8 03             	sar    $0x3,%eax
80101471:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101474:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101479:	89 d1                	mov    %edx,%ecx
8010147b:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010147e:	09 ca                	or     %ecx,%edx
80101480:	89 d1                	mov    %edx,%ecx
80101482:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101485:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
80101489:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010148c:	89 04 24             	mov    %eax,(%esp)
8010148f:	e8 02 22 00 00       	call   80103696 <log_write>
        brelse(bp);
80101494:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101497:	89 04 24             	mov    %eax,(%esp)
8010149a:	e8 78 ed ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
8010149f:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014a2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014a5:	01 c2                	add    %eax,%edx
801014a7:	8b 45 08             	mov    0x8(%ebp),%eax
801014aa:	89 54 24 04          	mov    %edx,0x4(%esp)
801014ae:	89 04 24             	mov    %eax,(%esp)
801014b1:	e8 b4 fe ff ff       	call   8010136a <bzero>
        return b + bi;
801014b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014b9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014bc:	01 d0                	add    %edx,%eax
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
}
801014be:	83 c4 34             	add    $0x34,%esp
801014c1:	5b                   	pop    %ebx
801014c2:	5d                   	pop    %ebp
801014c3:	c3                   	ret    

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801014c4:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801014c8:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
801014cf:	7f 15                	jg     801014e6 <balloc+0x12b>
801014d1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014d4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014d7:	01 d0                	add    %edx,%eax
801014d9:	89 c2                	mov    %eax,%edx
801014db:	8b 45 d8             	mov    -0x28(%ebp),%eax
801014de:	39 c2                	cmp    %eax,%edx
801014e0:	0f 82 3b ff ff ff    	jb     80101421 <balloc+0x66>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
801014e6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801014e9:	89 04 24             	mov    %eax,(%esp)
801014ec:	e8 26 ed ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
801014f1:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801014f8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014fb:	8b 45 d8             	mov    -0x28(%ebp),%eax
801014fe:	39 c2                	cmp    %eax,%edx
80101500:	0f 82 e1 fe ff ff    	jb     801013e7 <balloc+0x2c>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
80101506:	c7 04 24 55 87 10 80 	movl   $0x80108755,(%esp)
8010150d:	e8 2b f0 ff ff       	call   8010053d <panic>

80101512 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
80101512:	55                   	push   %ebp
80101513:	89 e5                	mov    %esp,%ebp
80101515:	53                   	push   %ebx
80101516:	83 ec 34             	sub    $0x34,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
80101519:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010151c:	89 44 24 04          	mov    %eax,0x4(%esp)
80101520:	8b 45 08             	mov    0x8(%ebp),%eax
80101523:	89 04 24             	mov    %eax,(%esp)
80101526:	e8 f9 fd ff ff       	call   80101324 <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
8010152b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010152e:	89 c2                	mov    %eax,%edx
80101530:	c1 ea 0c             	shr    $0xc,%edx
80101533:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101536:	c1 e8 03             	shr    $0x3,%eax
80101539:	01 d0                	add    %edx,%eax
8010153b:	8d 50 03             	lea    0x3(%eax),%edx
8010153e:	8b 45 08             	mov    0x8(%ebp),%eax
80101541:	89 54 24 04          	mov    %edx,0x4(%esp)
80101545:	89 04 24             	mov    %eax,(%esp)
80101548:	e8 59 ec ff ff       	call   801001a6 <bread>
8010154d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
80101550:	8b 45 0c             	mov    0xc(%ebp),%eax
80101553:	25 ff 0f 00 00       	and    $0xfff,%eax
80101558:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
8010155b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010155e:	89 c2                	mov    %eax,%edx
80101560:	c1 fa 1f             	sar    $0x1f,%edx
80101563:	c1 ea 1d             	shr    $0x1d,%edx
80101566:	01 d0                	add    %edx,%eax
80101568:	83 e0 07             	and    $0x7,%eax
8010156b:	29 d0                	sub    %edx,%eax
8010156d:	ba 01 00 00 00       	mov    $0x1,%edx
80101572:	89 d3                	mov    %edx,%ebx
80101574:	89 c1                	mov    %eax,%ecx
80101576:	d3 e3                	shl    %cl,%ebx
80101578:	89 d8                	mov    %ebx,%eax
8010157a:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
8010157d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101580:	8d 50 07             	lea    0x7(%eax),%edx
80101583:	85 c0                	test   %eax,%eax
80101585:	0f 48 c2             	cmovs  %edx,%eax
80101588:	c1 f8 03             	sar    $0x3,%eax
8010158b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010158e:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101593:	0f b6 c0             	movzbl %al,%eax
80101596:	23 45 ec             	and    -0x14(%ebp),%eax
80101599:	85 c0                	test   %eax,%eax
8010159b:	75 0c                	jne    801015a9 <bfree+0x97>
    panic("freeing free block");
8010159d:	c7 04 24 6b 87 10 80 	movl   $0x8010876b,(%esp)
801015a4:	e8 94 ef ff ff       	call   8010053d <panic>
  bp->data[bi/8] &= ~m;
801015a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801015ac:	8d 50 07             	lea    0x7(%eax),%edx
801015af:	85 c0                	test   %eax,%eax
801015b1:	0f 48 c2             	cmovs  %edx,%eax
801015b4:	c1 f8 03             	sar    $0x3,%eax
801015b7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015ba:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
801015bf:	8b 4d ec             	mov    -0x14(%ebp),%ecx
801015c2:	f7 d1                	not    %ecx
801015c4:	21 ca                	and    %ecx,%edx
801015c6:	89 d1                	mov    %edx,%ecx
801015c8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015cb:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
801015cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015d2:	89 04 24             	mov    %eax,(%esp)
801015d5:	e8 bc 20 00 00       	call   80103696 <log_write>
  brelse(bp);
801015da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015dd:	89 04 24             	mov    %eax,(%esp)
801015e0:	e8 32 ec ff ff       	call   80100217 <brelse>
}
801015e5:	83 c4 34             	add    $0x34,%esp
801015e8:	5b                   	pop    %ebx
801015e9:	5d                   	pop    %ebp
801015ea:	c3                   	ret    

801015eb <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
801015eb:	55                   	push   %ebp
801015ec:	89 e5                	mov    %esp,%ebp
801015ee:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
801015f1:	c7 44 24 04 7e 87 10 	movl   $0x8010877e,0x4(%esp)
801015f8:	80 
801015f9:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101600:	e8 79 3a 00 00       	call   8010507e <initlock>
}
80101605:	c9                   	leave  
80101606:	c3                   	ret    

80101607 <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
80101607:	55                   	push   %ebp
80101608:	89 e5                	mov    %esp,%ebp
8010160a:	83 ec 48             	sub    $0x48,%esp
8010160d:	8b 45 0c             	mov    0xc(%ebp),%eax
80101610:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
80101614:	8b 45 08             	mov    0x8(%ebp),%eax
80101617:	8d 55 dc             	lea    -0x24(%ebp),%edx
8010161a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010161e:	89 04 24             	mov    %eax,(%esp)
80101621:	e8 fe fc ff ff       	call   80101324 <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
80101626:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
8010162d:	e9 98 00 00 00       	jmp    801016ca <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
80101632:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101635:	c1 e8 03             	shr    $0x3,%eax
80101638:	83 c0 02             	add    $0x2,%eax
8010163b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010163f:	8b 45 08             	mov    0x8(%ebp),%eax
80101642:	89 04 24             	mov    %eax,(%esp)
80101645:	e8 5c eb ff ff       	call   801001a6 <bread>
8010164a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
8010164d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101650:	8d 50 18             	lea    0x18(%eax),%edx
80101653:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101656:	83 e0 07             	and    $0x7,%eax
80101659:	c1 e0 06             	shl    $0x6,%eax
8010165c:	01 d0                	add    %edx,%eax
8010165e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
80101661:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101664:	0f b7 00             	movzwl (%eax),%eax
80101667:	66 85 c0             	test   %ax,%ax
8010166a:	75 4f                	jne    801016bb <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
8010166c:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
80101673:	00 
80101674:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010167b:	00 
8010167c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010167f:	89 04 24             	mov    %eax,(%esp)
80101682:	e8 67 3c 00 00       	call   801052ee <memset>
      dip->type = type;
80101687:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010168a:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
8010168e:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80101691:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101694:	89 04 24             	mov    %eax,(%esp)
80101697:	e8 fa 1f 00 00       	call   80103696 <log_write>
      brelse(bp);
8010169c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010169f:	89 04 24             	mov    %eax,(%esp)
801016a2:	e8 70 eb ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
801016a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016aa:	89 44 24 04          	mov    %eax,0x4(%esp)
801016ae:	8b 45 08             	mov    0x8(%ebp),%eax
801016b1:	89 04 24             	mov    %eax,(%esp)
801016b4:	e8 e3 00 00 00       	call   8010179c <iget>
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
}
801016b9:	c9                   	leave  
801016ba:	c3                   	ret    
      dip->type = type;
      log_write(bp);   // mark it allocated on the disk
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
801016bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016be:	89 04 24             	mov    %eax,(%esp)
801016c1:	e8 51 eb ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
801016c6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801016ca:	8b 55 f4             	mov    -0xc(%ebp),%edx
801016cd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801016d0:	39 c2                	cmp    %eax,%edx
801016d2:	0f 82 5a ff ff ff    	jb     80101632 <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
801016d8:	c7 04 24 85 87 10 80 	movl   $0x80108785,(%esp)
801016df:	e8 59 ee ff ff       	call   8010053d <panic>

801016e4 <iupdate>:
}

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
801016e4:	55                   	push   %ebp
801016e5:	89 e5                	mov    %esp,%ebp
801016e7:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
801016ea:	8b 45 08             	mov    0x8(%ebp),%eax
801016ed:	8b 40 04             	mov    0x4(%eax),%eax
801016f0:	c1 e8 03             	shr    $0x3,%eax
801016f3:	8d 50 02             	lea    0x2(%eax),%edx
801016f6:	8b 45 08             	mov    0x8(%ebp),%eax
801016f9:	8b 00                	mov    (%eax),%eax
801016fb:	89 54 24 04          	mov    %edx,0x4(%esp)
801016ff:	89 04 24             	mov    %eax,(%esp)
80101702:	e8 9f ea ff ff       	call   801001a6 <bread>
80101707:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
8010170a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010170d:	8d 50 18             	lea    0x18(%eax),%edx
80101710:	8b 45 08             	mov    0x8(%ebp),%eax
80101713:	8b 40 04             	mov    0x4(%eax),%eax
80101716:	83 e0 07             	and    $0x7,%eax
80101719:	c1 e0 06             	shl    $0x6,%eax
8010171c:	01 d0                	add    %edx,%eax
8010171e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
80101721:	8b 45 08             	mov    0x8(%ebp),%eax
80101724:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101728:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010172b:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
8010172e:	8b 45 08             	mov    0x8(%ebp),%eax
80101731:	0f b7 50 12          	movzwl 0x12(%eax),%edx
80101735:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101738:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
8010173c:	8b 45 08             	mov    0x8(%ebp),%eax
8010173f:	0f b7 50 14          	movzwl 0x14(%eax),%edx
80101743:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101746:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
8010174a:	8b 45 08             	mov    0x8(%ebp),%eax
8010174d:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101751:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101754:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
80101758:	8b 45 08             	mov    0x8(%ebp),%eax
8010175b:	8b 50 18             	mov    0x18(%eax),%edx
8010175e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101761:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
80101764:	8b 45 08             	mov    0x8(%ebp),%eax
80101767:	8d 50 1c             	lea    0x1c(%eax),%edx
8010176a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010176d:	83 c0 0c             	add    $0xc,%eax
80101770:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101777:	00 
80101778:	89 54 24 04          	mov    %edx,0x4(%esp)
8010177c:	89 04 24             	mov    %eax,(%esp)
8010177f:	e8 3d 3c 00 00       	call   801053c1 <memmove>
  log_write(bp);
80101784:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101787:	89 04 24             	mov    %eax,(%esp)
8010178a:	e8 07 1f 00 00       	call   80103696 <log_write>
  brelse(bp);
8010178f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101792:	89 04 24             	mov    %eax,(%esp)
80101795:	e8 7d ea ff ff       	call   80100217 <brelse>
}
8010179a:	c9                   	leave  
8010179b:	c3                   	ret    

8010179c <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
8010179c:	55                   	push   %ebp
8010179d:	89 e5                	mov    %esp,%ebp
8010179f:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
801017a2:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
801017a9:	e8 f1 38 00 00       	call   8010509f <acquire>

  // Is the inode already cached?
  empty = 0;
801017ae:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801017b5:	c7 45 f4 74 12 11 80 	movl   $0x80111274,-0xc(%ebp)
801017bc:	eb 59                	jmp    80101817 <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
801017be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017c1:	8b 40 08             	mov    0x8(%eax),%eax
801017c4:	85 c0                	test   %eax,%eax
801017c6:	7e 35                	jle    801017fd <iget+0x61>
801017c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017cb:	8b 00                	mov    (%eax),%eax
801017cd:	3b 45 08             	cmp    0x8(%ebp),%eax
801017d0:	75 2b                	jne    801017fd <iget+0x61>
801017d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017d5:	8b 40 04             	mov    0x4(%eax),%eax
801017d8:	3b 45 0c             	cmp    0xc(%ebp),%eax
801017db:	75 20                	jne    801017fd <iget+0x61>
      ip->ref++;
801017dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017e0:	8b 40 08             	mov    0x8(%eax),%eax
801017e3:	8d 50 01             	lea    0x1(%eax),%edx
801017e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017e9:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
801017ec:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
801017f3:	e8 09 39 00 00       	call   80105101 <release>
      return ip;
801017f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017fb:	eb 6f                	jmp    8010186c <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801017fd:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101801:	75 10                	jne    80101813 <iget+0x77>
80101803:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101806:	8b 40 08             	mov    0x8(%eax),%eax
80101809:	85 c0                	test   %eax,%eax
8010180b:	75 06                	jne    80101813 <iget+0x77>
      empty = ip;
8010180d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101810:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101813:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
80101817:	81 7d f4 14 22 11 80 	cmpl   $0x80112214,-0xc(%ebp)
8010181e:	72 9e                	jb     801017be <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
80101820:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101824:	75 0c                	jne    80101832 <iget+0x96>
    panic("iget: no inodes");
80101826:	c7 04 24 97 87 10 80 	movl   $0x80108797,(%esp)
8010182d:	e8 0b ed ff ff       	call   8010053d <panic>

  ip = empty;
80101832:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101835:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
80101838:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010183b:	8b 55 08             	mov    0x8(%ebp),%edx
8010183e:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
80101840:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101843:	8b 55 0c             	mov    0xc(%ebp),%edx
80101846:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
80101849:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010184c:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
80101853:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101856:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
8010185d:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101864:	e8 98 38 00 00       	call   80105101 <release>

  return ip;
80101869:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010186c:	c9                   	leave  
8010186d:	c3                   	ret    

8010186e <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
8010186e:	55                   	push   %ebp
8010186f:	89 e5                	mov    %esp,%ebp
80101871:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101874:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
8010187b:	e8 1f 38 00 00       	call   8010509f <acquire>
  ip->ref++;
80101880:	8b 45 08             	mov    0x8(%ebp),%eax
80101883:	8b 40 08             	mov    0x8(%eax),%eax
80101886:	8d 50 01             	lea    0x1(%eax),%edx
80101889:	8b 45 08             	mov    0x8(%ebp),%eax
8010188c:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
8010188f:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101896:	e8 66 38 00 00       	call   80105101 <release>
  return ip;
8010189b:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010189e:	c9                   	leave  
8010189f:	c3                   	ret    

801018a0 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
801018a0:	55                   	push   %ebp
801018a1:	89 e5                	mov    %esp,%ebp
801018a3:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
801018a6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801018aa:	74 0a                	je     801018b6 <ilock+0x16>
801018ac:	8b 45 08             	mov    0x8(%ebp),%eax
801018af:	8b 40 08             	mov    0x8(%eax),%eax
801018b2:	85 c0                	test   %eax,%eax
801018b4:	7f 0c                	jg     801018c2 <ilock+0x22>
    panic("ilock");
801018b6:	c7 04 24 a7 87 10 80 	movl   $0x801087a7,(%esp)
801018bd:	e8 7b ec ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
801018c2:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
801018c9:	e8 d1 37 00 00       	call   8010509f <acquire>
  while(ip->flags & I_BUSY)
801018ce:	eb 13                	jmp    801018e3 <ilock+0x43>
    sleep(ip, &icache.lock);
801018d0:	c7 44 24 04 40 12 11 	movl   $0x80111240,0x4(%esp)
801018d7:	80 
801018d8:	8b 45 08             	mov    0x8(%ebp),%eax
801018db:	89 04 24             	mov    %eax,(%esp)
801018de:	e8 66 34 00 00       	call   80104d49 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
801018e3:	8b 45 08             	mov    0x8(%ebp),%eax
801018e6:	8b 40 0c             	mov    0xc(%eax),%eax
801018e9:	83 e0 01             	and    $0x1,%eax
801018ec:	84 c0                	test   %al,%al
801018ee:	75 e0                	jne    801018d0 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
801018f0:	8b 45 08             	mov    0x8(%ebp),%eax
801018f3:	8b 40 0c             	mov    0xc(%eax),%eax
801018f6:	89 c2                	mov    %eax,%edx
801018f8:	83 ca 01             	or     $0x1,%edx
801018fb:	8b 45 08             	mov    0x8(%ebp),%eax
801018fe:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
80101901:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101908:	e8 f4 37 00 00       	call   80105101 <release>

  if(!(ip->flags & I_VALID)){
8010190d:	8b 45 08             	mov    0x8(%ebp),%eax
80101910:	8b 40 0c             	mov    0xc(%eax),%eax
80101913:	83 e0 02             	and    $0x2,%eax
80101916:	85 c0                	test   %eax,%eax
80101918:	0f 85 ce 00 00 00    	jne    801019ec <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
8010191e:	8b 45 08             	mov    0x8(%ebp),%eax
80101921:	8b 40 04             	mov    0x4(%eax),%eax
80101924:	c1 e8 03             	shr    $0x3,%eax
80101927:	8d 50 02             	lea    0x2(%eax),%edx
8010192a:	8b 45 08             	mov    0x8(%ebp),%eax
8010192d:	8b 00                	mov    (%eax),%eax
8010192f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101933:	89 04 24             	mov    %eax,(%esp)
80101936:	e8 6b e8 ff ff       	call   801001a6 <bread>
8010193b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
8010193e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101941:	8d 50 18             	lea    0x18(%eax),%edx
80101944:	8b 45 08             	mov    0x8(%ebp),%eax
80101947:	8b 40 04             	mov    0x4(%eax),%eax
8010194a:	83 e0 07             	and    $0x7,%eax
8010194d:	c1 e0 06             	shl    $0x6,%eax
80101950:	01 d0                	add    %edx,%eax
80101952:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
80101955:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101958:	0f b7 10             	movzwl (%eax),%edx
8010195b:	8b 45 08             	mov    0x8(%ebp),%eax
8010195e:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
80101962:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101965:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101969:	8b 45 08             	mov    0x8(%ebp),%eax
8010196c:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
80101970:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101973:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101977:	8b 45 08             	mov    0x8(%ebp),%eax
8010197a:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
8010197e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101981:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101985:	8b 45 08             	mov    0x8(%ebp),%eax
80101988:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
8010198c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010198f:	8b 50 08             	mov    0x8(%eax),%edx
80101992:	8b 45 08             	mov    0x8(%ebp),%eax
80101995:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101998:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010199b:	8d 50 0c             	lea    0xc(%eax),%edx
8010199e:	8b 45 08             	mov    0x8(%ebp),%eax
801019a1:	83 c0 1c             	add    $0x1c,%eax
801019a4:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
801019ab:	00 
801019ac:	89 54 24 04          	mov    %edx,0x4(%esp)
801019b0:	89 04 24             	mov    %eax,(%esp)
801019b3:	e8 09 3a 00 00       	call   801053c1 <memmove>
    brelse(bp);
801019b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019bb:	89 04 24             	mov    %eax,(%esp)
801019be:	e8 54 e8 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
801019c3:	8b 45 08             	mov    0x8(%ebp),%eax
801019c6:	8b 40 0c             	mov    0xc(%eax),%eax
801019c9:	89 c2                	mov    %eax,%edx
801019cb:	83 ca 02             	or     $0x2,%edx
801019ce:	8b 45 08             	mov    0x8(%ebp),%eax
801019d1:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
801019d4:	8b 45 08             	mov    0x8(%ebp),%eax
801019d7:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801019db:	66 85 c0             	test   %ax,%ax
801019de:	75 0c                	jne    801019ec <ilock+0x14c>
      panic("ilock: no type");
801019e0:	c7 04 24 ad 87 10 80 	movl   $0x801087ad,(%esp)
801019e7:	e8 51 eb ff ff       	call   8010053d <panic>
  }
}
801019ec:	c9                   	leave  
801019ed:	c3                   	ret    

801019ee <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
801019ee:	55                   	push   %ebp
801019ef:	89 e5                	mov    %esp,%ebp
801019f1:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
801019f4:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801019f8:	74 17                	je     80101a11 <iunlock+0x23>
801019fa:	8b 45 08             	mov    0x8(%ebp),%eax
801019fd:	8b 40 0c             	mov    0xc(%eax),%eax
80101a00:	83 e0 01             	and    $0x1,%eax
80101a03:	85 c0                	test   %eax,%eax
80101a05:	74 0a                	je     80101a11 <iunlock+0x23>
80101a07:	8b 45 08             	mov    0x8(%ebp),%eax
80101a0a:	8b 40 08             	mov    0x8(%eax),%eax
80101a0d:	85 c0                	test   %eax,%eax
80101a0f:	7f 0c                	jg     80101a1d <iunlock+0x2f>
    panic("iunlock");
80101a11:	c7 04 24 bc 87 10 80 	movl   $0x801087bc,(%esp)
80101a18:	e8 20 eb ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
80101a1d:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101a24:	e8 76 36 00 00       	call   8010509f <acquire>
  ip->flags &= ~I_BUSY;
80101a29:	8b 45 08             	mov    0x8(%ebp),%eax
80101a2c:	8b 40 0c             	mov    0xc(%eax),%eax
80101a2f:	89 c2                	mov    %eax,%edx
80101a31:	83 e2 fe             	and    $0xfffffffe,%edx
80101a34:	8b 45 08             	mov    0x8(%ebp),%eax
80101a37:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80101a3a:	8b 45 08             	mov    0x8(%ebp),%eax
80101a3d:	89 04 24             	mov    %eax,(%esp)
80101a40:	e8 13 34 00 00       	call   80104e58 <wakeup>
  release(&icache.lock);
80101a45:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101a4c:	e8 b0 36 00 00       	call   80105101 <release>
}
80101a51:	c9                   	leave  
80101a52:	c3                   	ret    

80101a53 <iput>:
// to it, free the inode (and its content) on disk.
// All calls to iput() must be inside a transaction in
// case it has to free the inode.
void
iput(struct inode *ip)
{
80101a53:	55                   	push   %ebp
80101a54:	89 e5                	mov    %esp,%ebp
80101a56:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101a59:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101a60:	e8 3a 36 00 00       	call   8010509f <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80101a65:	8b 45 08             	mov    0x8(%ebp),%eax
80101a68:	8b 40 08             	mov    0x8(%eax),%eax
80101a6b:	83 f8 01             	cmp    $0x1,%eax
80101a6e:	0f 85 93 00 00 00    	jne    80101b07 <iput+0xb4>
80101a74:	8b 45 08             	mov    0x8(%ebp),%eax
80101a77:	8b 40 0c             	mov    0xc(%eax),%eax
80101a7a:	83 e0 02             	and    $0x2,%eax
80101a7d:	85 c0                	test   %eax,%eax
80101a7f:	0f 84 82 00 00 00    	je     80101b07 <iput+0xb4>
80101a85:	8b 45 08             	mov    0x8(%ebp),%eax
80101a88:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80101a8c:	66 85 c0             	test   %ax,%ax
80101a8f:	75 76                	jne    80101b07 <iput+0xb4>
    // inode has no links and no other references: truncate and free.
    if(ip->flags & I_BUSY)
80101a91:	8b 45 08             	mov    0x8(%ebp),%eax
80101a94:	8b 40 0c             	mov    0xc(%eax),%eax
80101a97:	83 e0 01             	and    $0x1,%eax
80101a9a:	84 c0                	test   %al,%al
80101a9c:	74 0c                	je     80101aaa <iput+0x57>
      panic("iput busy");
80101a9e:	c7 04 24 c4 87 10 80 	movl   $0x801087c4,(%esp)
80101aa5:	e8 93 ea ff ff       	call   8010053d <panic>
    ip->flags |= I_BUSY;
80101aaa:	8b 45 08             	mov    0x8(%ebp),%eax
80101aad:	8b 40 0c             	mov    0xc(%eax),%eax
80101ab0:	89 c2                	mov    %eax,%edx
80101ab2:	83 ca 01             	or     $0x1,%edx
80101ab5:	8b 45 08             	mov    0x8(%ebp),%eax
80101ab8:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101abb:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101ac2:	e8 3a 36 00 00       	call   80105101 <release>
    itrunc(ip);
80101ac7:	8b 45 08             	mov    0x8(%ebp),%eax
80101aca:	89 04 24             	mov    %eax,(%esp)
80101acd:	e8 72 01 00 00       	call   80101c44 <itrunc>
    ip->type = 0;
80101ad2:	8b 45 08             	mov    0x8(%ebp),%eax
80101ad5:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80101adb:	8b 45 08             	mov    0x8(%ebp),%eax
80101ade:	89 04 24             	mov    %eax,(%esp)
80101ae1:	e8 fe fb ff ff       	call   801016e4 <iupdate>
    acquire(&icache.lock);
80101ae6:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101aed:	e8 ad 35 00 00       	call   8010509f <acquire>
    ip->flags = 0;
80101af2:	8b 45 08             	mov    0x8(%ebp),%eax
80101af5:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101afc:	8b 45 08             	mov    0x8(%ebp),%eax
80101aff:	89 04 24             	mov    %eax,(%esp)
80101b02:	e8 51 33 00 00       	call   80104e58 <wakeup>
  }
  ip->ref--;
80101b07:	8b 45 08             	mov    0x8(%ebp),%eax
80101b0a:	8b 40 08             	mov    0x8(%eax),%eax
80101b0d:	8d 50 ff             	lea    -0x1(%eax),%edx
80101b10:	8b 45 08             	mov    0x8(%ebp),%eax
80101b13:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101b16:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101b1d:	e8 df 35 00 00       	call   80105101 <release>
}
80101b22:	c9                   	leave  
80101b23:	c3                   	ret    

80101b24 <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101b24:	55                   	push   %ebp
80101b25:	89 e5                	mov    %esp,%ebp
80101b27:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101b2a:	8b 45 08             	mov    0x8(%ebp),%eax
80101b2d:	89 04 24             	mov    %eax,(%esp)
80101b30:	e8 b9 fe ff ff       	call   801019ee <iunlock>
  iput(ip);
80101b35:	8b 45 08             	mov    0x8(%ebp),%eax
80101b38:	89 04 24             	mov    %eax,(%esp)
80101b3b:	e8 13 ff ff ff       	call   80101a53 <iput>
}
80101b40:	c9                   	leave  
80101b41:	c3                   	ret    

80101b42 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101b42:	55                   	push   %ebp
80101b43:	89 e5                	mov    %esp,%ebp
80101b45:	53                   	push   %ebx
80101b46:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101b49:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101b4d:	77 3e                	ja     80101b8d <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80101b4f:	8b 45 08             	mov    0x8(%ebp),%eax
80101b52:	8b 55 0c             	mov    0xc(%ebp),%edx
80101b55:	83 c2 04             	add    $0x4,%edx
80101b58:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101b5c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b5f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101b63:	75 20                	jne    80101b85 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101b65:	8b 45 08             	mov    0x8(%ebp),%eax
80101b68:	8b 00                	mov    (%eax),%eax
80101b6a:	89 04 24             	mov    %eax,(%esp)
80101b6d:	e8 49 f8 ff ff       	call   801013bb <balloc>
80101b72:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b75:	8b 45 08             	mov    0x8(%ebp),%eax
80101b78:	8b 55 0c             	mov    0xc(%ebp),%edx
80101b7b:	8d 4a 04             	lea    0x4(%edx),%ecx
80101b7e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b81:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101b85:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b88:	e9 b1 00 00 00       	jmp    80101c3e <bmap+0xfc>
  }
  bn -= NDIRECT;
80101b8d:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101b91:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101b95:	0f 87 97 00 00 00    	ja     80101c32 <bmap+0xf0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101b9b:	8b 45 08             	mov    0x8(%ebp),%eax
80101b9e:	8b 40 4c             	mov    0x4c(%eax),%eax
80101ba1:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101ba4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101ba8:	75 19                	jne    80101bc3 <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101baa:	8b 45 08             	mov    0x8(%ebp),%eax
80101bad:	8b 00                	mov    (%eax),%eax
80101baf:	89 04 24             	mov    %eax,(%esp)
80101bb2:	e8 04 f8 ff ff       	call   801013bb <balloc>
80101bb7:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bba:	8b 45 08             	mov    0x8(%ebp),%eax
80101bbd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101bc0:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80101bc3:	8b 45 08             	mov    0x8(%ebp),%eax
80101bc6:	8b 00                	mov    (%eax),%eax
80101bc8:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101bcb:	89 54 24 04          	mov    %edx,0x4(%esp)
80101bcf:	89 04 24             	mov    %eax,(%esp)
80101bd2:	e8 cf e5 ff ff       	call   801001a6 <bread>
80101bd7:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101bda:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101bdd:	83 c0 18             	add    $0x18,%eax
80101be0:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101be3:	8b 45 0c             	mov    0xc(%ebp),%eax
80101be6:	c1 e0 02             	shl    $0x2,%eax
80101be9:	03 45 ec             	add    -0x14(%ebp),%eax
80101bec:	8b 00                	mov    (%eax),%eax
80101bee:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bf1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101bf5:	75 2b                	jne    80101c22 <bmap+0xe0>
      a[bn] = addr = balloc(ip->dev);
80101bf7:	8b 45 0c             	mov    0xc(%ebp),%eax
80101bfa:	c1 e0 02             	shl    $0x2,%eax
80101bfd:	89 c3                	mov    %eax,%ebx
80101bff:	03 5d ec             	add    -0x14(%ebp),%ebx
80101c02:	8b 45 08             	mov    0x8(%ebp),%eax
80101c05:	8b 00                	mov    (%eax),%eax
80101c07:	89 04 24             	mov    %eax,(%esp)
80101c0a:	e8 ac f7 ff ff       	call   801013bb <balloc>
80101c0f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c12:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c15:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101c17:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c1a:	89 04 24             	mov    %eax,(%esp)
80101c1d:	e8 74 1a 00 00       	call   80103696 <log_write>
    }
    brelse(bp);
80101c22:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c25:	89 04 24             	mov    %eax,(%esp)
80101c28:	e8 ea e5 ff ff       	call   80100217 <brelse>
    return addr;
80101c2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c30:	eb 0c                	jmp    80101c3e <bmap+0xfc>
  }

  panic("bmap: out of range");
80101c32:	c7 04 24 ce 87 10 80 	movl   $0x801087ce,(%esp)
80101c39:	e8 ff e8 ff ff       	call   8010053d <panic>
}
80101c3e:	83 c4 24             	add    $0x24,%esp
80101c41:	5b                   	pop    %ebx
80101c42:	5d                   	pop    %ebp
80101c43:	c3                   	ret    

80101c44 <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101c44:	55                   	push   %ebp
80101c45:	89 e5                	mov    %esp,%ebp
80101c47:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101c4a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101c51:	eb 44                	jmp    80101c97 <itrunc+0x53>
    if(ip->addrs[i]){
80101c53:	8b 45 08             	mov    0x8(%ebp),%eax
80101c56:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c59:	83 c2 04             	add    $0x4,%edx
80101c5c:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101c60:	85 c0                	test   %eax,%eax
80101c62:	74 2f                	je     80101c93 <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80101c64:	8b 45 08             	mov    0x8(%ebp),%eax
80101c67:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c6a:	83 c2 04             	add    $0x4,%edx
80101c6d:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101c71:	8b 45 08             	mov    0x8(%ebp),%eax
80101c74:	8b 00                	mov    (%eax),%eax
80101c76:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c7a:	89 04 24             	mov    %eax,(%esp)
80101c7d:	e8 90 f8 ff ff       	call   80101512 <bfree>
      ip->addrs[i] = 0;
80101c82:	8b 45 08             	mov    0x8(%ebp),%eax
80101c85:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c88:	83 c2 04             	add    $0x4,%edx
80101c8b:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101c92:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101c93:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101c97:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101c9b:	7e b6                	jle    80101c53 <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80101c9d:	8b 45 08             	mov    0x8(%ebp),%eax
80101ca0:	8b 40 4c             	mov    0x4c(%eax),%eax
80101ca3:	85 c0                	test   %eax,%eax
80101ca5:	0f 84 8f 00 00 00    	je     80101d3a <itrunc+0xf6>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101cab:	8b 45 08             	mov    0x8(%ebp),%eax
80101cae:	8b 50 4c             	mov    0x4c(%eax),%edx
80101cb1:	8b 45 08             	mov    0x8(%ebp),%eax
80101cb4:	8b 00                	mov    (%eax),%eax
80101cb6:	89 54 24 04          	mov    %edx,0x4(%esp)
80101cba:	89 04 24             	mov    %eax,(%esp)
80101cbd:	e8 e4 e4 ff ff       	call   801001a6 <bread>
80101cc2:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101cc5:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101cc8:	83 c0 18             	add    $0x18,%eax
80101ccb:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101cce:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101cd5:	eb 2f                	jmp    80101d06 <itrunc+0xc2>
      if(a[j])
80101cd7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cda:	c1 e0 02             	shl    $0x2,%eax
80101cdd:	03 45 e8             	add    -0x18(%ebp),%eax
80101ce0:	8b 00                	mov    (%eax),%eax
80101ce2:	85 c0                	test   %eax,%eax
80101ce4:	74 1c                	je     80101d02 <itrunc+0xbe>
        bfree(ip->dev, a[j]);
80101ce6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ce9:	c1 e0 02             	shl    $0x2,%eax
80101cec:	03 45 e8             	add    -0x18(%ebp),%eax
80101cef:	8b 10                	mov    (%eax),%edx
80101cf1:	8b 45 08             	mov    0x8(%ebp),%eax
80101cf4:	8b 00                	mov    (%eax),%eax
80101cf6:	89 54 24 04          	mov    %edx,0x4(%esp)
80101cfa:	89 04 24             	mov    %eax,(%esp)
80101cfd:	e8 10 f8 ff ff       	call   80101512 <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80101d02:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101d06:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d09:	83 f8 7f             	cmp    $0x7f,%eax
80101d0c:	76 c9                	jbe    80101cd7 <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80101d0e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d11:	89 04 24             	mov    %eax,(%esp)
80101d14:	e8 fe e4 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101d19:	8b 45 08             	mov    0x8(%ebp),%eax
80101d1c:	8b 50 4c             	mov    0x4c(%eax),%edx
80101d1f:	8b 45 08             	mov    0x8(%ebp),%eax
80101d22:	8b 00                	mov    (%eax),%eax
80101d24:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d28:	89 04 24             	mov    %eax,(%esp)
80101d2b:	e8 e2 f7 ff ff       	call   80101512 <bfree>
    ip->addrs[NDIRECT] = 0;
80101d30:	8b 45 08             	mov    0x8(%ebp),%eax
80101d33:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80101d3a:	8b 45 08             	mov    0x8(%ebp),%eax
80101d3d:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80101d44:	8b 45 08             	mov    0x8(%ebp),%eax
80101d47:	89 04 24             	mov    %eax,(%esp)
80101d4a:	e8 95 f9 ff ff       	call   801016e4 <iupdate>
}
80101d4f:	c9                   	leave  
80101d50:	c3                   	ret    

80101d51 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80101d51:	55                   	push   %ebp
80101d52:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101d54:	8b 45 08             	mov    0x8(%ebp),%eax
80101d57:	8b 00                	mov    (%eax),%eax
80101d59:	89 c2                	mov    %eax,%edx
80101d5b:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d5e:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101d61:	8b 45 08             	mov    0x8(%ebp),%eax
80101d64:	8b 50 04             	mov    0x4(%eax),%edx
80101d67:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d6a:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101d6d:	8b 45 08             	mov    0x8(%ebp),%eax
80101d70:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101d74:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d77:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101d7a:	8b 45 08             	mov    0x8(%ebp),%eax
80101d7d:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101d81:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d84:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101d88:	8b 45 08             	mov    0x8(%ebp),%eax
80101d8b:	8b 50 18             	mov    0x18(%eax),%edx
80101d8e:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d91:	89 50 10             	mov    %edx,0x10(%eax)
}
80101d94:	5d                   	pop    %ebp
80101d95:	c3                   	ret    

80101d96 <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101d96:	55                   	push   %ebp
80101d97:	89 e5                	mov    %esp,%ebp
80101d99:	53                   	push   %ebx
80101d9a:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101d9d:	8b 45 08             	mov    0x8(%ebp),%eax
80101da0:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101da4:	66 83 f8 03          	cmp    $0x3,%ax
80101da8:	75 60                	jne    80101e0a <readi+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101daa:	8b 45 08             	mov    0x8(%ebp),%eax
80101dad:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101db1:	66 85 c0             	test   %ax,%ax
80101db4:	78 20                	js     80101dd6 <readi+0x40>
80101db6:	8b 45 08             	mov    0x8(%ebp),%eax
80101db9:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101dbd:	66 83 f8 09          	cmp    $0x9,%ax
80101dc1:	7f 13                	jg     80101dd6 <readi+0x40>
80101dc3:	8b 45 08             	mov    0x8(%ebp),%eax
80101dc6:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101dca:	98                   	cwtl   
80101dcb:	8b 04 c5 e0 11 11 80 	mov    -0x7feeee20(,%eax,8),%eax
80101dd2:	85 c0                	test   %eax,%eax
80101dd4:	75 0a                	jne    80101de0 <readi+0x4a>
      return -1;
80101dd6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101ddb:	e9 1b 01 00 00       	jmp    80101efb <readi+0x165>
    return devsw[ip->major].read(ip, dst, n);
80101de0:	8b 45 08             	mov    0x8(%ebp),%eax
80101de3:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101de7:	98                   	cwtl   
80101de8:	8b 14 c5 e0 11 11 80 	mov    -0x7feeee20(,%eax,8),%edx
80101def:	8b 45 14             	mov    0x14(%ebp),%eax
80101df2:	89 44 24 08          	mov    %eax,0x8(%esp)
80101df6:	8b 45 0c             	mov    0xc(%ebp),%eax
80101df9:	89 44 24 04          	mov    %eax,0x4(%esp)
80101dfd:	8b 45 08             	mov    0x8(%ebp),%eax
80101e00:	89 04 24             	mov    %eax,(%esp)
80101e03:	ff d2                	call   *%edx
80101e05:	e9 f1 00 00 00       	jmp    80101efb <readi+0x165>
  }

  if(off > ip->size || off + n < off)
80101e0a:	8b 45 08             	mov    0x8(%ebp),%eax
80101e0d:	8b 40 18             	mov    0x18(%eax),%eax
80101e10:	3b 45 10             	cmp    0x10(%ebp),%eax
80101e13:	72 0d                	jb     80101e22 <readi+0x8c>
80101e15:	8b 45 14             	mov    0x14(%ebp),%eax
80101e18:	8b 55 10             	mov    0x10(%ebp),%edx
80101e1b:	01 d0                	add    %edx,%eax
80101e1d:	3b 45 10             	cmp    0x10(%ebp),%eax
80101e20:	73 0a                	jae    80101e2c <readi+0x96>
    return -1;
80101e22:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101e27:	e9 cf 00 00 00       	jmp    80101efb <readi+0x165>
  if(off + n > ip->size)
80101e2c:	8b 45 14             	mov    0x14(%ebp),%eax
80101e2f:	8b 55 10             	mov    0x10(%ebp),%edx
80101e32:	01 c2                	add    %eax,%edx
80101e34:	8b 45 08             	mov    0x8(%ebp),%eax
80101e37:	8b 40 18             	mov    0x18(%eax),%eax
80101e3a:	39 c2                	cmp    %eax,%edx
80101e3c:	76 0c                	jbe    80101e4a <readi+0xb4>
    n = ip->size - off;
80101e3e:	8b 45 08             	mov    0x8(%ebp),%eax
80101e41:	8b 40 18             	mov    0x18(%eax),%eax
80101e44:	2b 45 10             	sub    0x10(%ebp),%eax
80101e47:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101e4a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101e51:	e9 96 00 00 00       	jmp    80101eec <readi+0x156>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101e56:	8b 45 10             	mov    0x10(%ebp),%eax
80101e59:	c1 e8 09             	shr    $0x9,%eax
80101e5c:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e60:	8b 45 08             	mov    0x8(%ebp),%eax
80101e63:	89 04 24             	mov    %eax,(%esp)
80101e66:	e8 d7 fc ff ff       	call   80101b42 <bmap>
80101e6b:	8b 55 08             	mov    0x8(%ebp),%edx
80101e6e:	8b 12                	mov    (%edx),%edx
80101e70:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e74:	89 14 24             	mov    %edx,(%esp)
80101e77:	e8 2a e3 ff ff       	call   801001a6 <bread>
80101e7c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101e7f:	8b 45 10             	mov    0x10(%ebp),%eax
80101e82:	89 c2                	mov    %eax,%edx
80101e84:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80101e8a:	b8 00 02 00 00       	mov    $0x200,%eax
80101e8f:	89 c1                	mov    %eax,%ecx
80101e91:	29 d1                	sub    %edx,%ecx
80101e93:	89 ca                	mov    %ecx,%edx
80101e95:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e98:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101e9b:	89 cb                	mov    %ecx,%ebx
80101e9d:	29 c3                	sub    %eax,%ebx
80101e9f:	89 d8                	mov    %ebx,%eax
80101ea1:	39 c2                	cmp    %eax,%edx
80101ea3:	0f 46 c2             	cmovbe %edx,%eax
80101ea6:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80101ea9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101eac:	8d 50 18             	lea    0x18(%eax),%edx
80101eaf:	8b 45 10             	mov    0x10(%ebp),%eax
80101eb2:	25 ff 01 00 00       	and    $0x1ff,%eax
80101eb7:	01 c2                	add    %eax,%edx
80101eb9:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ebc:	89 44 24 08          	mov    %eax,0x8(%esp)
80101ec0:	89 54 24 04          	mov    %edx,0x4(%esp)
80101ec4:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ec7:	89 04 24             	mov    %eax,(%esp)
80101eca:	e8 f2 34 00 00       	call   801053c1 <memmove>
    brelse(bp);
80101ecf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ed2:	89 04 24             	mov    %eax,(%esp)
80101ed5:	e8 3d e3 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101eda:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101edd:	01 45 f4             	add    %eax,-0xc(%ebp)
80101ee0:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ee3:	01 45 10             	add    %eax,0x10(%ebp)
80101ee6:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ee9:	01 45 0c             	add    %eax,0xc(%ebp)
80101eec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101eef:	3b 45 14             	cmp    0x14(%ebp),%eax
80101ef2:	0f 82 5e ff ff ff    	jb     80101e56 <readi+0xc0>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80101ef8:	8b 45 14             	mov    0x14(%ebp),%eax
}
80101efb:	83 c4 24             	add    $0x24,%esp
80101efe:	5b                   	pop    %ebx
80101eff:	5d                   	pop    %ebp
80101f00:	c3                   	ret    

80101f01 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80101f01:	55                   	push   %ebp
80101f02:	89 e5                	mov    %esp,%ebp
80101f04:	53                   	push   %ebx
80101f05:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101f08:	8b 45 08             	mov    0x8(%ebp),%eax
80101f0b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101f0f:	66 83 f8 03          	cmp    $0x3,%ax
80101f13:	75 60                	jne    80101f75 <writei+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80101f15:	8b 45 08             	mov    0x8(%ebp),%eax
80101f18:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f1c:	66 85 c0             	test   %ax,%ax
80101f1f:	78 20                	js     80101f41 <writei+0x40>
80101f21:	8b 45 08             	mov    0x8(%ebp),%eax
80101f24:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f28:	66 83 f8 09          	cmp    $0x9,%ax
80101f2c:	7f 13                	jg     80101f41 <writei+0x40>
80101f2e:	8b 45 08             	mov    0x8(%ebp),%eax
80101f31:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f35:	98                   	cwtl   
80101f36:	8b 04 c5 e4 11 11 80 	mov    -0x7feeee1c(,%eax,8),%eax
80101f3d:	85 c0                	test   %eax,%eax
80101f3f:	75 0a                	jne    80101f4b <writei+0x4a>
      return -1;
80101f41:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f46:	e9 46 01 00 00       	jmp    80102091 <writei+0x190>
    return devsw[ip->major].write(ip, src, n);
80101f4b:	8b 45 08             	mov    0x8(%ebp),%eax
80101f4e:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f52:	98                   	cwtl   
80101f53:	8b 14 c5 e4 11 11 80 	mov    -0x7feeee1c(,%eax,8),%edx
80101f5a:	8b 45 14             	mov    0x14(%ebp),%eax
80101f5d:	89 44 24 08          	mov    %eax,0x8(%esp)
80101f61:	8b 45 0c             	mov    0xc(%ebp),%eax
80101f64:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f68:	8b 45 08             	mov    0x8(%ebp),%eax
80101f6b:	89 04 24             	mov    %eax,(%esp)
80101f6e:	ff d2                	call   *%edx
80101f70:	e9 1c 01 00 00       	jmp    80102091 <writei+0x190>
  }

  if(off > ip->size || off + n < off)
80101f75:	8b 45 08             	mov    0x8(%ebp),%eax
80101f78:	8b 40 18             	mov    0x18(%eax),%eax
80101f7b:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f7e:	72 0d                	jb     80101f8d <writei+0x8c>
80101f80:	8b 45 14             	mov    0x14(%ebp),%eax
80101f83:	8b 55 10             	mov    0x10(%ebp),%edx
80101f86:	01 d0                	add    %edx,%eax
80101f88:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f8b:	73 0a                	jae    80101f97 <writei+0x96>
    return -1;
80101f8d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f92:	e9 fa 00 00 00       	jmp    80102091 <writei+0x190>
  if(off + n > MAXFILE*BSIZE)
80101f97:	8b 45 14             	mov    0x14(%ebp),%eax
80101f9a:	8b 55 10             	mov    0x10(%ebp),%edx
80101f9d:	01 d0                	add    %edx,%eax
80101f9f:	3d 00 18 01 00       	cmp    $0x11800,%eax
80101fa4:	76 0a                	jbe    80101fb0 <writei+0xaf>
    return -1;
80101fa6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101fab:	e9 e1 00 00 00       	jmp    80102091 <writei+0x190>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80101fb0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101fb7:	e9 a1 00 00 00       	jmp    8010205d <writei+0x15c>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101fbc:	8b 45 10             	mov    0x10(%ebp),%eax
80101fbf:	c1 e8 09             	shr    $0x9,%eax
80101fc2:	89 44 24 04          	mov    %eax,0x4(%esp)
80101fc6:	8b 45 08             	mov    0x8(%ebp),%eax
80101fc9:	89 04 24             	mov    %eax,(%esp)
80101fcc:	e8 71 fb ff ff       	call   80101b42 <bmap>
80101fd1:	8b 55 08             	mov    0x8(%ebp),%edx
80101fd4:	8b 12                	mov    (%edx),%edx
80101fd6:	89 44 24 04          	mov    %eax,0x4(%esp)
80101fda:	89 14 24             	mov    %edx,(%esp)
80101fdd:	e8 c4 e1 ff ff       	call   801001a6 <bread>
80101fe2:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101fe5:	8b 45 10             	mov    0x10(%ebp),%eax
80101fe8:	89 c2                	mov    %eax,%edx
80101fea:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80101ff0:	b8 00 02 00 00       	mov    $0x200,%eax
80101ff5:	89 c1                	mov    %eax,%ecx
80101ff7:	29 d1                	sub    %edx,%ecx
80101ff9:	89 ca                	mov    %ecx,%edx
80101ffb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ffe:	8b 4d 14             	mov    0x14(%ebp),%ecx
80102001:	89 cb                	mov    %ecx,%ebx
80102003:	29 c3                	sub    %eax,%ebx
80102005:	89 d8                	mov    %ebx,%eax
80102007:	39 c2                	cmp    %eax,%edx
80102009:	0f 46 c2             	cmovbe %edx,%eax
8010200c:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
8010200f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102012:	8d 50 18             	lea    0x18(%eax),%edx
80102015:	8b 45 10             	mov    0x10(%ebp),%eax
80102018:	25 ff 01 00 00       	and    $0x1ff,%eax
8010201d:	01 c2                	add    %eax,%edx
8010201f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102022:	89 44 24 08          	mov    %eax,0x8(%esp)
80102026:	8b 45 0c             	mov    0xc(%ebp),%eax
80102029:	89 44 24 04          	mov    %eax,0x4(%esp)
8010202d:	89 14 24             	mov    %edx,(%esp)
80102030:	e8 8c 33 00 00       	call   801053c1 <memmove>
    log_write(bp);
80102035:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102038:	89 04 24             	mov    %eax,(%esp)
8010203b:	e8 56 16 00 00       	call   80103696 <log_write>
    brelse(bp);
80102040:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102043:	89 04 24             	mov    %eax,(%esp)
80102046:	e8 cc e1 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
8010204b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010204e:	01 45 f4             	add    %eax,-0xc(%ebp)
80102051:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102054:	01 45 10             	add    %eax,0x10(%ebp)
80102057:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010205a:	01 45 0c             	add    %eax,0xc(%ebp)
8010205d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102060:	3b 45 14             	cmp    0x14(%ebp),%eax
80102063:	0f 82 53 ff ff ff    	jb     80101fbc <writei+0xbb>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
80102069:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010206d:	74 1f                	je     8010208e <writei+0x18d>
8010206f:	8b 45 08             	mov    0x8(%ebp),%eax
80102072:	8b 40 18             	mov    0x18(%eax),%eax
80102075:	3b 45 10             	cmp    0x10(%ebp),%eax
80102078:	73 14                	jae    8010208e <writei+0x18d>
    ip->size = off;
8010207a:	8b 45 08             	mov    0x8(%ebp),%eax
8010207d:	8b 55 10             	mov    0x10(%ebp),%edx
80102080:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
80102083:	8b 45 08             	mov    0x8(%ebp),%eax
80102086:	89 04 24             	mov    %eax,(%esp)
80102089:	e8 56 f6 ff ff       	call   801016e4 <iupdate>
  }
  return n;
8010208e:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102091:	83 c4 24             	add    $0x24,%esp
80102094:	5b                   	pop    %ebx
80102095:	5d                   	pop    %ebp
80102096:	c3                   	ret    

80102097 <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
80102097:	55                   	push   %ebp
80102098:	89 e5                	mov    %esp,%ebp
8010209a:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
8010209d:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801020a4:	00 
801020a5:	8b 45 0c             	mov    0xc(%ebp),%eax
801020a8:	89 44 24 04          	mov    %eax,0x4(%esp)
801020ac:	8b 45 08             	mov    0x8(%ebp),%eax
801020af:	89 04 24             	mov    %eax,(%esp)
801020b2:	e8 ae 33 00 00       	call   80105465 <strncmp>
}
801020b7:	c9                   	leave  
801020b8:	c3                   	ret    

801020b9 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
801020b9:	55                   	push   %ebp
801020ba:	89 e5                	mov    %esp,%ebp
801020bc:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
801020bf:	8b 45 08             	mov    0x8(%ebp),%eax
801020c2:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801020c6:	66 83 f8 01          	cmp    $0x1,%ax
801020ca:	74 0c                	je     801020d8 <dirlookup+0x1f>
    panic("dirlookup not DIR");
801020cc:	c7 04 24 e1 87 10 80 	movl   $0x801087e1,(%esp)
801020d3:	e8 65 e4 ff ff       	call   8010053d <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
801020d8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801020df:	e9 87 00 00 00       	jmp    8010216b <dirlookup+0xb2>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801020e4:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801020eb:	00 
801020ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801020ef:	89 44 24 08          	mov    %eax,0x8(%esp)
801020f3:	8d 45 e0             	lea    -0x20(%ebp),%eax
801020f6:	89 44 24 04          	mov    %eax,0x4(%esp)
801020fa:	8b 45 08             	mov    0x8(%ebp),%eax
801020fd:	89 04 24             	mov    %eax,(%esp)
80102100:	e8 91 fc ff ff       	call   80101d96 <readi>
80102105:	83 f8 10             	cmp    $0x10,%eax
80102108:	74 0c                	je     80102116 <dirlookup+0x5d>
      panic("dirlink read");
8010210a:	c7 04 24 f3 87 10 80 	movl   $0x801087f3,(%esp)
80102111:	e8 27 e4 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
80102116:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010211a:	66 85 c0             	test   %ax,%ax
8010211d:	74 47                	je     80102166 <dirlookup+0xad>
      continue;
    if(namecmp(name, de.name) == 0){
8010211f:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102122:	83 c0 02             	add    $0x2,%eax
80102125:	89 44 24 04          	mov    %eax,0x4(%esp)
80102129:	8b 45 0c             	mov    0xc(%ebp),%eax
8010212c:	89 04 24             	mov    %eax,(%esp)
8010212f:	e8 63 ff ff ff       	call   80102097 <namecmp>
80102134:	85 c0                	test   %eax,%eax
80102136:	75 2f                	jne    80102167 <dirlookup+0xae>
      // entry matches path element
      if(poff)
80102138:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010213c:	74 08                	je     80102146 <dirlookup+0x8d>
        *poff = off;
8010213e:	8b 45 10             	mov    0x10(%ebp),%eax
80102141:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102144:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
80102146:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010214a:	0f b7 c0             	movzwl %ax,%eax
8010214d:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
80102150:	8b 45 08             	mov    0x8(%ebp),%eax
80102153:	8b 00                	mov    (%eax),%eax
80102155:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102158:	89 54 24 04          	mov    %edx,0x4(%esp)
8010215c:	89 04 24             	mov    %eax,(%esp)
8010215f:	e8 38 f6 ff ff       	call   8010179c <iget>
80102164:	eb 19                	jmp    8010217f <dirlookup+0xc6>

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      continue;
80102166:	90                   	nop
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
80102167:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
8010216b:	8b 45 08             	mov    0x8(%ebp),%eax
8010216e:	8b 40 18             	mov    0x18(%eax),%eax
80102171:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80102174:	0f 87 6a ff ff ff    	ja     801020e4 <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
8010217a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010217f:	c9                   	leave  
80102180:	c3                   	ret    

80102181 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
80102181:	55                   	push   %ebp
80102182:	89 e5                	mov    %esp,%ebp
80102184:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
80102187:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010218e:	00 
8010218f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102192:	89 44 24 04          	mov    %eax,0x4(%esp)
80102196:	8b 45 08             	mov    0x8(%ebp),%eax
80102199:	89 04 24             	mov    %eax,(%esp)
8010219c:	e8 18 ff ff ff       	call   801020b9 <dirlookup>
801021a1:	89 45 f0             	mov    %eax,-0x10(%ebp)
801021a4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801021a8:	74 15                	je     801021bf <dirlink+0x3e>
    iput(ip);
801021aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021ad:	89 04 24             	mov    %eax,(%esp)
801021b0:	e8 9e f8 ff ff       	call   80101a53 <iput>
    return -1;
801021b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801021ba:	e9 b8 00 00 00       	jmp    80102277 <dirlink+0xf6>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801021bf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801021c6:	eb 44                	jmp    8010220c <dirlink+0x8b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801021c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021cb:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801021d2:	00 
801021d3:	89 44 24 08          	mov    %eax,0x8(%esp)
801021d7:	8d 45 e0             	lea    -0x20(%ebp),%eax
801021da:	89 44 24 04          	mov    %eax,0x4(%esp)
801021de:	8b 45 08             	mov    0x8(%ebp),%eax
801021e1:	89 04 24             	mov    %eax,(%esp)
801021e4:	e8 ad fb ff ff       	call   80101d96 <readi>
801021e9:	83 f8 10             	cmp    $0x10,%eax
801021ec:	74 0c                	je     801021fa <dirlink+0x79>
      panic("dirlink read");
801021ee:	c7 04 24 f3 87 10 80 	movl   $0x801087f3,(%esp)
801021f5:	e8 43 e3 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
801021fa:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801021fe:	66 85 c0             	test   %ax,%ax
80102201:	74 18                	je     8010221b <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102203:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102206:	83 c0 10             	add    $0x10,%eax
80102209:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010220c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010220f:	8b 45 08             	mov    0x8(%ebp),%eax
80102212:	8b 40 18             	mov    0x18(%eax),%eax
80102215:	39 c2                	cmp    %eax,%edx
80102217:	72 af                	jb     801021c8 <dirlink+0x47>
80102219:	eb 01                	jmp    8010221c <dirlink+0x9b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
8010221b:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
8010221c:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102223:	00 
80102224:	8b 45 0c             	mov    0xc(%ebp),%eax
80102227:	89 44 24 04          	mov    %eax,0x4(%esp)
8010222b:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010222e:	83 c0 02             	add    $0x2,%eax
80102231:	89 04 24             	mov    %eax,(%esp)
80102234:	e8 84 32 00 00       	call   801054bd <strncpy>
  de.inum = inum;
80102239:	8b 45 10             	mov    0x10(%ebp),%eax
8010223c:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102240:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102243:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010224a:	00 
8010224b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010224f:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102252:	89 44 24 04          	mov    %eax,0x4(%esp)
80102256:	8b 45 08             	mov    0x8(%ebp),%eax
80102259:	89 04 24             	mov    %eax,(%esp)
8010225c:	e8 a0 fc ff ff       	call   80101f01 <writei>
80102261:	83 f8 10             	cmp    $0x10,%eax
80102264:	74 0c                	je     80102272 <dirlink+0xf1>
    panic("dirlink");
80102266:	c7 04 24 00 88 10 80 	movl   $0x80108800,(%esp)
8010226d:	e8 cb e2 ff ff       	call   8010053d <panic>
  
  return 0;
80102272:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102277:	c9                   	leave  
80102278:	c3                   	ret    

80102279 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80102279:	55                   	push   %ebp
8010227a:	89 e5                	mov    %esp,%ebp
8010227c:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
8010227f:	eb 04                	jmp    80102285 <skipelem+0xc>
    path++;
80102281:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
80102285:	8b 45 08             	mov    0x8(%ebp),%eax
80102288:	0f b6 00             	movzbl (%eax),%eax
8010228b:	3c 2f                	cmp    $0x2f,%al
8010228d:	74 f2                	je     80102281 <skipelem+0x8>
    path++;
  if(*path == 0)
8010228f:	8b 45 08             	mov    0x8(%ebp),%eax
80102292:	0f b6 00             	movzbl (%eax),%eax
80102295:	84 c0                	test   %al,%al
80102297:	75 0a                	jne    801022a3 <skipelem+0x2a>
    return 0;
80102299:	b8 00 00 00 00       	mov    $0x0,%eax
8010229e:	e9 86 00 00 00       	jmp    80102329 <skipelem+0xb0>
  s = path;
801022a3:	8b 45 08             	mov    0x8(%ebp),%eax
801022a6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
801022a9:	eb 04                	jmp    801022af <skipelem+0x36>
    path++;
801022ab:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
801022af:	8b 45 08             	mov    0x8(%ebp),%eax
801022b2:	0f b6 00             	movzbl (%eax),%eax
801022b5:	3c 2f                	cmp    $0x2f,%al
801022b7:	74 0a                	je     801022c3 <skipelem+0x4a>
801022b9:	8b 45 08             	mov    0x8(%ebp),%eax
801022bc:	0f b6 00             	movzbl (%eax),%eax
801022bf:	84 c0                	test   %al,%al
801022c1:	75 e8                	jne    801022ab <skipelem+0x32>
    path++;
  len = path - s;
801022c3:	8b 55 08             	mov    0x8(%ebp),%edx
801022c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022c9:	89 d1                	mov    %edx,%ecx
801022cb:	29 c1                	sub    %eax,%ecx
801022cd:	89 c8                	mov    %ecx,%eax
801022cf:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
801022d2:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
801022d6:	7e 1c                	jle    801022f4 <skipelem+0x7b>
    memmove(name, s, DIRSIZ);
801022d8:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801022df:	00 
801022e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022e3:	89 44 24 04          	mov    %eax,0x4(%esp)
801022e7:	8b 45 0c             	mov    0xc(%ebp),%eax
801022ea:	89 04 24             	mov    %eax,(%esp)
801022ed:	e8 cf 30 00 00       	call   801053c1 <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801022f2:	eb 28                	jmp    8010231c <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
801022f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022f7:	89 44 24 08          	mov    %eax,0x8(%esp)
801022fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022fe:	89 44 24 04          	mov    %eax,0x4(%esp)
80102302:	8b 45 0c             	mov    0xc(%ebp),%eax
80102305:	89 04 24             	mov    %eax,(%esp)
80102308:	e8 b4 30 00 00       	call   801053c1 <memmove>
    name[len] = 0;
8010230d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102310:	03 45 0c             	add    0xc(%ebp),%eax
80102313:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
80102316:	eb 04                	jmp    8010231c <skipelem+0xa3>
    path++;
80102318:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
8010231c:	8b 45 08             	mov    0x8(%ebp),%eax
8010231f:	0f b6 00             	movzbl (%eax),%eax
80102322:	3c 2f                	cmp    $0x2f,%al
80102324:	74 f2                	je     80102318 <skipelem+0x9f>
    path++;
  return path;
80102326:	8b 45 08             	mov    0x8(%ebp),%eax
}
80102329:	c9                   	leave  
8010232a:	c3                   	ret    

8010232b <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
8010232b:	55                   	push   %ebp
8010232c:	89 e5                	mov    %esp,%ebp
8010232e:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
80102331:	8b 45 08             	mov    0x8(%ebp),%eax
80102334:	0f b6 00             	movzbl (%eax),%eax
80102337:	3c 2f                	cmp    $0x2f,%al
80102339:	75 1c                	jne    80102357 <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
8010233b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102342:	00 
80102343:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010234a:	e8 4d f4 ff ff       	call   8010179c <iget>
8010234f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102352:	e9 b2 00 00 00       	jmp    80102409 <namex+0xde>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
80102357:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010235d:	8b 80 8c 02 00 00    	mov    0x28c(%eax),%eax
80102363:	89 04 24             	mov    %eax,(%esp)
80102366:	e8 03 f5 ff ff       	call   8010186e <idup>
8010236b:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
8010236e:	e9 96 00 00 00       	jmp    80102409 <namex+0xde>
    ilock(ip);
80102373:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102376:	89 04 24             	mov    %eax,(%esp)
80102379:	e8 22 f5 ff ff       	call   801018a0 <ilock>
    if(ip->type != T_DIR){
8010237e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102381:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102385:	66 83 f8 01          	cmp    $0x1,%ax
80102389:	74 15                	je     801023a0 <namex+0x75>
      iunlockput(ip);
8010238b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010238e:	89 04 24             	mov    %eax,(%esp)
80102391:	e8 8e f7 ff ff       	call   80101b24 <iunlockput>
      return 0;
80102396:	b8 00 00 00 00       	mov    $0x0,%eax
8010239b:	e9 a3 00 00 00       	jmp    80102443 <namex+0x118>
    }
    if(nameiparent && *path == '\0'){
801023a0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801023a4:	74 1d                	je     801023c3 <namex+0x98>
801023a6:	8b 45 08             	mov    0x8(%ebp),%eax
801023a9:	0f b6 00             	movzbl (%eax),%eax
801023ac:	84 c0                	test   %al,%al
801023ae:	75 13                	jne    801023c3 <namex+0x98>
      // Stop one level early.
      iunlock(ip);
801023b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023b3:	89 04 24             	mov    %eax,(%esp)
801023b6:	e8 33 f6 ff ff       	call   801019ee <iunlock>
      return ip;
801023bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023be:	e9 80 00 00 00       	jmp    80102443 <namex+0x118>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
801023c3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801023ca:	00 
801023cb:	8b 45 10             	mov    0x10(%ebp),%eax
801023ce:	89 44 24 04          	mov    %eax,0x4(%esp)
801023d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023d5:	89 04 24             	mov    %eax,(%esp)
801023d8:	e8 dc fc ff ff       	call   801020b9 <dirlookup>
801023dd:	89 45 f0             	mov    %eax,-0x10(%ebp)
801023e0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801023e4:	75 12                	jne    801023f8 <namex+0xcd>
      iunlockput(ip);
801023e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023e9:	89 04 24             	mov    %eax,(%esp)
801023ec:	e8 33 f7 ff ff       	call   80101b24 <iunlockput>
      return 0;
801023f1:	b8 00 00 00 00       	mov    $0x0,%eax
801023f6:	eb 4b                	jmp    80102443 <namex+0x118>
    }
    iunlockput(ip);
801023f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023fb:	89 04 24             	mov    %eax,(%esp)
801023fe:	e8 21 f7 ff ff       	call   80101b24 <iunlockput>
    ip = next;
80102403:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102406:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102409:	8b 45 10             	mov    0x10(%ebp),%eax
8010240c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102410:	8b 45 08             	mov    0x8(%ebp),%eax
80102413:	89 04 24             	mov    %eax,(%esp)
80102416:	e8 5e fe ff ff       	call   80102279 <skipelem>
8010241b:	89 45 08             	mov    %eax,0x8(%ebp)
8010241e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102422:	0f 85 4b ff ff ff    	jne    80102373 <namex+0x48>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
80102428:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010242c:	74 12                	je     80102440 <namex+0x115>
    iput(ip);
8010242e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102431:	89 04 24             	mov    %eax,(%esp)
80102434:	e8 1a f6 ff ff       	call   80101a53 <iput>
    return 0;
80102439:	b8 00 00 00 00       	mov    $0x0,%eax
8010243e:	eb 03                	jmp    80102443 <namex+0x118>
  }
  return ip;
80102440:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102443:	c9                   	leave  
80102444:	c3                   	ret    

80102445 <namei>:

struct inode*
namei(char *path)
{
80102445:	55                   	push   %ebp
80102446:	89 e5                	mov    %esp,%ebp
80102448:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
8010244b:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010244e:	89 44 24 08          	mov    %eax,0x8(%esp)
80102452:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102459:	00 
8010245a:	8b 45 08             	mov    0x8(%ebp),%eax
8010245d:	89 04 24             	mov    %eax,(%esp)
80102460:	e8 c6 fe ff ff       	call   8010232b <namex>
}
80102465:	c9                   	leave  
80102466:	c3                   	ret    

80102467 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80102467:	55                   	push   %ebp
80102468:	89 e5                	mov    %esp,%ebp
8010246a:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
8010246d:	8b 45 0c             	mov    0xc(%ebp),%eax
80102470:	89 44 24 08          	mov    %eax,0x8(%esp)
80102474:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010247b:	00 
8010247c:	8b 45 08             	mov    0x8(%ebp),%eax
8010247f:	89 04 24             	mov    %eax,(%esp)
80102482:	e8 a4 fe ff ff       	call   8010232b <namex>
}
80102487:	c9                   	leave  
80102488:	c3                   	ret    
80102489:	00 00                	add    %al,(%eax)
	...

8010248c <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010248c:	55                   	push   %ebp
8010248d:	89 e5                	mov    %esp,%ebp
8010248f:	53                   	push   %ebx
80102490:	83 ec 14             	sub    $0x14,%esp
80102493:	8b 45 08             	mov    0x8(%ebp),%eax
80102496:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010249a:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
8010249e:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801024a2:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801024a6:	ec                   	in     (%dx),%al
801024a7:	89 c3                	mov    %eax,%ebx
801024a9:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801024ac:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801024b0:	83 c4 14             	add    $0x14,%esp
801024b3:	5b                   	pop    %ebx
801024b4:	5d                   	pop    %ebp
801024b5:	c3                   	ret    

801024b6 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
801024b6:	55                   	push   %ebp
801024b7:	89 e5                	mov    %esp,%ebp
801024b9:	57                   	push   %edi
801024ba:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
801024bb:	8b 55 08             	mov    0x8(%ebp),%edx
801024be:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801024c1:	8b 45 10             	mov    0x10(%ebp),%eax
801024c4:	89 cb                	mov    %ecx,%ebx
801024c6:	89 df                	mov    %ebx,%edi
801024c8:	89 c1                	mov    %eax,%ecx
801024ca:	fc                   	cld    
801024cb:	f3 6d                	rep insl (%dx),%es:(%edi)
801024cd:	89 c8                	mov    %ecx,%eax
801024cf:	89 fb                	mov    %edi,%ebx
801024d1:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801024d4:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
801024d7:	5b                   	pop    %ebx
801024d8:	5f                   	pop    %edi
801024d9:	5d                   	pop    %ebp
801024da:	c3                   	ret    

801024db <outb>:

static inline void
outb(ushort port, uchar data)
{
801024db:	55                   	push   %ebp
801024dc:	89 e5                	mov    %esp,%ebp
801024de:	83 ec 08             	sub    $0x8,%esp
801024e1:	8b 55 08             	mov    0x8(%ebp),%edx
801024e4:	8b 45 0c             	mov    0xc(%ebp),%eax
801024e7:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801024eb:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801024ee:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801024f2:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801024f6:	ee                   	out    %al,(%dx)
}
801024f7:	c9                   	leave  
801024f8:	c3                   	ret    

801024f9 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
801024f9:	55                   	push   %ebp
801024fa:	89 e5                	mov    %esp,%ebp
801024fc:	56                   	push   %esi
801024fd:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
801024fe:	8b 55 08             	mov    0x8(%ebp),%edx
80102501:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102504:	8b 45 10             	mov    0x10(%ebp),%eax
80102507:	89 cb                	mov    %ecx,%ebx
80102509:	89 de                	mov    %ebx,%esi
8010250b:	89 c1                	mov    %eax,%ecx
8010250d:	fc                   	cld    
8010250e:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80102510:	89 c8                	mov    %ecx,%eax
80102512:	89 f3                	mov    %esi,%ebx
80102514:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102517:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
8010251a:	5b                   	pop    %ebx
8010251b:	5e                   	pop    %esi
8010251c:	5d                   	pop    %ebp
8010251d:	c3                   	ret    

8010251e <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
8010251e:	55                   	push   %ebp
8010251f:	89 e5                	mov    %esp,%ebp
80102521:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
80102524:	90                   	nop
80102525:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010252c:	e8 5b ff ff ff       	call   8010248c <inb>
80102531:	0f b6 c0             	movzbl %al,%eax
80102534:	89 45 fc             	mov    %eax,-0x4(%ebp)
80102537:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010253a:	25 c0 00 00 00       	and    $0xc0,%eax
8010253f:	83 f8 40             	cmp    $0x40,%eax
80102542:	75 e1                	jne    80102525 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102544:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102548:	74 11                	je     8010255b <idewait+0x3d>
8010254a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010254d:	83 e0 21             	and    $0x21,%eax
80102550:	85 c0                	test   %eax,%eax
80102552:	74 07                	je     8010255b <idewait+0x3d>
    return -1;
80102554:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102559:	eb 05                	jmp    80102560 <idewait+0x42>
  return 0;
8010255b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102560:	c9                   	leave  
80102561:	c3                   	ret    

80102562 <ideinit>:

void
ideinit(void)
{
80102562:	55                   	push   %ebp
80102563:	89 e5                	mov    %esp,%ebp
80102565:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
80102568:	c7 44 24 04 08 88 10 	movl   $0x80108808,0x4(%esp)
8010256f:	80 
80102570:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102577:	e8 02 2b 00 00       	call   8010507e <initlock>
  picenable(IRQ_IDE);
8010257c:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102583:	e8 c1 18 00 00       	call   80103e49 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102588:	a1 40 29 11 80       	mov    0x80112940,%eax
8010258d:	83 e8 01             	sub    $0x1,%eax
80102590:	89 44 24 04          	mov    %eax,0x4(%esp)
80102594:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
8010259b:	e8 12 04 00 00       	call   801029b2 <ioapicenable>
  idewait(0);
801025a0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801025a7:	e8 72 ff ff ff       	call   8010251e <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
801025ac:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
801025b3:	00 
801025b4:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801025bb:	e8 1b ff ff ff       	call   801024db <outb>
  for(i=0; i<1000; i++){
801025c0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801025c7:	eb 20                	jmp    801025e9 <ideinit+0x87>
    if(inb(0x1f7) != 0){
801025c9:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801025d0:	e8 b7 fe ff ff       	call   8010248c <inb>
801025d5:	84 c0                	test   %al,%al
801025d7:	74 0c                	je     801025e5 <ideinit+0x83>
      havedisk1 = 1;
801025d9:	c7 05 38 b6 10 80 01 	movl   $0x1,0x8010b638
801025e0:	00 00 00 
      break;
801025e3:	eb 0d                	jmp    801025f2 <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
801025e5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801025e9:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
801025f0:	7e d7                	jle    801025c9 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
801025f2:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
801025f9:	00 
801025fa:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102601:	e8 d5 fe ff ff       	call   801024db <outb>
}
80102606:	c9                   	leave  
80102607:	c3                   	ret    

80102608 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80102608:	55                   	push   %ebp
80102609:	89 e5                	mov    %esp,%ebp
8010260b:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
8010260e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102612:	75 0c                	jne    80102620 <idestart+0x18>
    panic("idestart");
80102614:	c7 04 24 0c 88 10 80 	movl   $0x8010880c,(%esp)
8010261b:	e8 1d df ff ff       	call   8010053d <panic>

  idewait(0);
80102620:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102627:	e8 f2 fe ff ff       	call   8010251e <idewait>
  outb(0x3f6, 0);  // generate interrupt
8010262c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102633:	00 
80102634:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
8010263b:	e8 9b fe ff ff       	call   801024db <outb>
  outb(0x1f2, 1);  // number of sectors
80102640:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102647:	00 
80102648:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
8010264f:	e8 87 fe ff ff       	call   801024db <outb>
  outb(0x1f3, b->sector & 0xff);
80102654:	8b 45 08             	mov    0x8(%ebp),%eax
80102657:	8b 40 08             	mov    0x8(%eax),%eax
8010265a:	0f b6 c0             	movzbl %al,%eax
8010265d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102661:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80102668:	e8 6e fe ff ff       	call   801024db <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
8010266d:	8b 45 08             	mov    0x8(%ebp),%eax
80102670:	8b 40 08             	mov    0x8(%eax),%eax
80102673:	c1 e8 08             	shr    $0x8,%eax
80102676:	0f b6 c0             	movzbl %al,%eax
80102679:	89 44 24 04          	mov    %eax,0x4(%esp)
8010267d:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102684:	e8 52 fe ff ff       	call   801024db <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
80102689:	8b 45 08             	mov    0x8(%ebp),%eax
8010268c:	8b 40 08             	mov    0x8(%eax),%eax
8010268f:	c1 e8 10             	shr    $0x10,%eax
80102692:	0f b6 c0             	movzbl %al,%eax
80102695:	89 44 24 04          	mov    %eax,0x4(%esp)
80102699:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
801026a0:	e8 36 fe ff ff       	call   801024db <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
801026a5:	8b 45 08             	mov    0x8(%ebp),%eax
801026a8:	8b 40 04             	mov    0x4(%eax),%eax
801026ab:	83 e0 01             	and    $0x1,%eax
801026ae:	89 c2                	mov    %eax,%edx
801026b0:	c1 e2 04             	shl    $0x4,%edx
801026b3:	8b 45 08             	mov    0x8(%ebp),%eax
801026b6:	8b 40 08             	mov    0x8(%eax),%eax
801026b9:	c1 e8 18             	shr    $0x18,%eax
801026bc:	83 e0 0f             	and    $0xf,%eax
801026bf:	09 d0                	or     %edx,%eax
801026c1:	83 c8 e0             	or     $0xffffffe0,%eax
801026c4:	0f b6 c0             	movzbl %al,%eax
801026c7:	89 44 24 04          	mov    %eax,0x4(%esp)
801026cb:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801026d2:	e8 04 fe ff ff       	call   801024db <outb>
  if(b->flags & B_DIRTY){
801026d7:	8b 45 08             	mov    0x8(%ebp),%eax
801026da:	8b 00                	mov    (%eax),%eax
801026dc:	83 e0 04             	and    $0x4,%eax
801026df:	85 c0                	test   %eax,%eax
801026e1:	74 34                	je     80102717 <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
801026e3:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
801026ea:	00 
801026eb:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801026f2:	e8 e4 fd ff ff       	call   801024db <outb>
    outsl(0x1f0, b->data, 512/4);
801026f7:	8b 45 08             	mov    0x8(%ebp),%eax
801026fa:	83 c0 18             	add    $0x18,%eax
801026fd:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102704:	00 
80102705:	89 44 24 04          	mov    %eax,0x4(%esp)
80102709:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102710:	e8 e4 fd ff ff       	call   801024f9 <outsl>
80102715:	eb 14                	jmp    8010272b <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
80102717:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
8010271e:	00 
8010271f:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102726:	e8 b0 fd ff ff       	call   801024db <outb>
  }
}
8010272b:	c9                   	leave  
8010272c:	c3                   	ret    

8010272d <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
8010272d:	55                   	push   %ebp
8010272e:	89 e5                	mov    %esp,%ebp
80102730:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80102733:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
8010273a:	e8 60 29 00 00       	call   8010509f <acquire>
  if((b = idequeue) == 0){
8010273f:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102744:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102747:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010274b:	75 11                	jne    8010275e <ideintr+0x31>
    release(&idelock);
8010274d:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102754:	e8 a8 29 00 00       	call   80105101 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80102759:	e9 90 00 00 00       	jmp    801027ee <ideintr+0xc1>
  }
  idequeue = b->qnext;
8010275e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102761:	8b 40 14             	mov    0x14(%eax),%eax
80102764:	a3 34 b6 10 80       	mov    %eax,0x8010b634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80102769:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010276c:	8b 00                	mov    (%eax),%eax
8010276e:	83 e0 04             	and    $0x4,%eax
80102771:	85 c0                	test   %eax,%eax
80102773:	75 2e                	jne    801027a3 <ideintr+0x76>
80102775:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010277c:	e8 9d fd ff ff       	call   8010251e <idewait>
80102781:	85 c0                	test   %eax,%eax
80102783:	78 1e                	js     801027a3 <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
80102785:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102788:	83 c0 18             	add    $0x18,%eax
8010278b:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102792:	00 
80102793:	89 44 24 04          	mov    %eax,0x4(%esp)
80102797:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
8010279e:	e8 13 fd ff ff       	call   801024b6 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
801027a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027a6:	8b 00                	mov    (%eax),%eax
801027a8:	89 c2                	mov    %eax,%edx
801027aa:	83 ca 02             	or     $0x2,%edx
801027ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027b0:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
801027b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027b5:	8b 00                	mov    (%eax),%eax
801027b7:	89 c2                	mov    %eax,%edx
801027b9:	83 e2 fb             	and    $0xfffffffb,%edx
801027bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027bf:	89 10                	mov    %edx,(%eax)
  wakeup(b);
801027c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027c4:	89 04 24             	mov    %eax,(%esp)
801027c7:	e8 8c 26 00 00       	call   80104e58 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
801027cc:	a1 34 b6 10 80       	mov    0x8010b634,%eax
801027d1:	85 c0                	test   %eax,%eax
801027d3:	74 0d                	je     801027e2 <ideintr+0xb5>
    idestart(idequeue);
801027d5:	a1 34 b6 10 80       	mov    0x8010b634,%eax
801027da:	89 04 24             	mov    %eax,(%esp)
801027dd:	e8 26 fe ff ff       	call   80102608 <idestart>

  release(&idelock);
801027e2:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801027e9:	e8 13 29 00 00       	call   80105101 <release>
}
801027ee:	c9                   	leave  
801027ef:	c3                   	ret    

801027f0 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
801027f0:	55                   	push   %ebp
801027f1:	89 e5                	mov    %esp,%ebp
801027f3:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
801027f6:	8b 45 08             	mov    0x8(%ebp),%eax
801027f9:	8b 00                	mov    (%eax),%eax
801027fb:	83 e0 01             	and    $0x1,%eax
801027fe:	85 c0                	test   %eax,%eax
80102800:	75 0c                	jne    8010280e <iderw+0x1e>
    panic("iderw: buf not busy");
80102802:	c7 04 24 15 88 10 80 	movl   $0x80108815,(%esp)
80102809:	e8 2f dd ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
8010280e:	8b 45 08             	mov    0x8(%ebp),%eax
80102811:	8b 00                	mov    (%eax),%eax
80102813:	83 e0 06             	and    $0x6,%eax
80102816:	83 f8 02             	cmp    $0x2,%eax
80102819:	75 0c                	jne    80102827 <iderw+0x37>
    panic("iderw: nothing to do");
8010281b:	c7 04 24 29 88 10 80 	movl   $0x80108829,(%esp)
80102822:	e8 16 dd ff ff       	call   8010053d <panic>
  if(b->dev != 0 && !havedisk1)
80102827:	8b 45 08             	mov    0x8(%ebp),%eax
8010282a:	8b 40 04             	mov    0x4(%eax),%eax
8010282d:	85 c0                	test   %eax,%eax
8010282f:	74 15                	je     80102846 <iderw+0x56>
80102831:	a1 38 b6 10 80       	mov    0x8010b638,%eax
80102836:	85 c0                	test   %eax,%eax
80102838:	75 0c                	jne    80102846 <iderw+0x56>
    panic("iderw: ide disk 1 not present");
8010283a:	c7 04 24 3e 88 10 80 	movl   $0x8010883e,(%esp)
80102841:	e8 f7 dc ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC:acquire-lock
80102846:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
8010284d:	e8 4d 28 00 00       	call   8010509f <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80102852:	8b 45 08             	mov    0x8(%ebp),%eax
80102855:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
8010285c:	c7 45 f4 34 b6 10 80 	movl   $0x8010b634,-0xc(%ebp)
80102863:	eb 0b                	jmp    80102870 <iderw+0x80>
80102865:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102868:	8b 00                	mov    (%eax),%eax
8010286a:	83 c0 14             	add    $0x14,%eax
8010286d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102870:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102873:	8b 00                	mov    (%eax),%eax
80102875:	85 c0                	test   %eax,%eax
80102877:	75 ec                	jne    80102865 <iderw+0x75>
    ;
  *pp = b;
80102879:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010287c:	8b 55 08             	mov    0x8(%ebp),%edx
8010287f:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80102881:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102886:	3b 45 08             	cmp    0x8(%ebp),%eax
80102889:	75 22                	jne    801028ad <iderw+0xbd>
    idestart(b);
8010288b:	8b 45 08             	mov    0x8(%ebp),%eax
8010288e:	89 04 24             	mov    %eax,(%esp)
80102891:	e8 72 fd ff ff       	call   80102608 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102896:	eb 15                	jmp    801028ad <iderw+0xbd>
    sleep(b, &idelock);
80102898:	c7 44 24 04 00 b6 10 	movl   $0x8010b600,0x4(%esp)
8010289f:	80 
801028a0:	8b 45 08             	mov    0x8(%ebp),%eax
801028a3:	89 04 24             	mov    %eax,(%esp)
801028a6:	e8 9e 24 00 00       	call   80104d49 <sleep>
801028ab:	eb 01                	jmp    801028ae <iderw+0xbe>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
801028ad:	90                   	nop
801028ae:	8b 45 08             	mov    0x8(%ebp),%eax
801028b1:	8b 00                	mov    (%eax),%eax
801028b3:	83 e0 06             	and    $0x6,%eax
801028b6:	83 f8 02             	cmp    $0x2,%eax
801028b9:	75 dd                	jne    80102898 <iderw+0xa8>
    sleep(b, &idelock);
  }

  release(&idelock);
801028bb:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801028c2:	e8 3a 28 00 00       	call   80105101 <release>
}
801028c7:	c9                   	leave  
801028c8:	c3                   	ret    
801028c9:	00 00                	add    %al,(%eax)
	...

801028cc <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
801028cc:	55                   	push   %ebp
801028cd:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
801028cf:	a1 14 22 11 80       	mov    0x80112214,%eax
801028d4:	8b 55 08             	mov    0x8(%ebp),%edx
801028d7:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
801028d9:	a1 14 22 11 80       	mov    0x80112214,%eax
801028de:	8b 40 10             	mov    0x10(%eax),%eax
}
801028e1:	5d                   	pop    %ebp
801028e2:	c3                   	ret    

801028e3 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
801028e3:	55                   	push   %ebp
801028e4:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
801028e6:	a1 14 22 11 80       	mov    0x80112214,%eax
801028eb:	8b 55 08             	mov    0x8(%ebp),%edx
801028ee:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
801028f0:	a1 14 22 11 80       	mov    0x80112214,%eax
801028f5:	8b 55 0c             	mov    0xc(%ebp),%edx
801028f8:	89 50 10             	mov    %edx,0x10(%eax)
}
801028fb:	5d                   	pop    %ebp
801028fc:	c3                   	ret    

801028fd <ioapicinit>:

void
ioapicinit(void)
{
801028fd:	55                   	push   %ebp
801028fe:	89 e5                	mov    %esp,%ebp
80102900:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80102903:	a1 44 23 11 80       	mov    0x80112344,%eax
80102908:	85 c0                	test   %eax,%eax
8010290a:	0f 84 9f 00 00 00    	je     801029af <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
80102910:	c7 05 14 22 11 80 00 	movl   $0xfec00000,0x80112214
80102917:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
8010291a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102921:	e8 a6 ff ff ff       	call   801028cc <ioapicread>
80102926:	c1 e8 10             	shr    $0x10,%eax
80102929:	25 ff 00 00 00       	and    $0xff,%eax
8010292e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80102931:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102938:	e8 8f ff ff ff       	call   801028cc <ioapicread>
8010293d:	c1 e8 18             	shr    $0x18,%eax
80102940:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80102943:	0f b6 05 40 23 11 80 	movzbl 0x80112340,%eax
8010294a:	0f b6 c0             	movzbl %al,%eax
8010294d:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102950:	74 0c                	je     8010295e <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80102952:	c7 04 24 5c 88 10 80 	movl   $0x8010885c,(%esp)
80102959:	e8 43 da ff ff       	call   801003a1 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
8010295e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102965:	eb 3e                	jmp    801029a5 <ioapicinit+0xa8>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80102967:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010296a:	83 c0 20             	add    $0x20,%eax
8010296d:	0d 00 00 01 00       	or     $0x10000,%eax
80102972:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102975:	83 c2 08             	add    $0x8,%edx
80102978:	01 d2                	add    %edx,%edx
8010297a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010297e:	89 14 24             	mov    %edx,(%esp)
80102981:	e8 5d ff ff ff       	call   801028e3 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80102986:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102989:	83 c0 08             	add    $0x8,%eax
8010298c:	01 c0                	add    %eax,%eax
8010298e:	83 c0 01             	add    $0x1,%eax
80102991:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102998:	00 
80102999:	89 04 24             	mov    %eax,(%esp)
8010299c:	e8 42 ff ff ff       	call   801028e3 <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
801029a1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801029a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029a8:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801029ab:	7e ba                	jle    80102967 <ioapicinit+0x6a>
801029ad:	eb 01                	jmp    801029b0 <ioapicinit+0xb3>
ioapicinit(void)
{
  int i, id, maxintr;

  if(!ismp)
    return;
801029af:	90                   	nop
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
801029b0:	c9                   	leave  
801029b1:	c3                   	ret    

801029b2 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
801029b2:	55                   	push   %ebp
801029b3:	89 e5                	mov    %esp,%ebp
801029b5:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
801029b8:	a1 44 23 11 80       	mov    0x80112344,%eax
801029bd:	85 c0                	test   %eax,%eax
801029bf:	74 39                	je     801029fa <ioapicenable+0x48>
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
801029c1:	8b 45 08             	mov    0x8(%ebp),%eax
801029c4:	83 c0 20             	add    $0x20,%eax
801029c7:	8b 55 08             	mov    0x8(%ebp),%edx
801029ca:	83 c2 08             	add    $0x8,%edx
801029cd:	01 d2                	add    %edx,%edx
801029cf:	89 44 24 04          	mov    %eax,0x4(%esp)
801029d3:	89 14 24             	mov    %edx,(%esp)
801029d6:	e8 08 ff ff ff       	call   801028e3 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
801029db:	8b 45 0c             	mov    0xc(%ebp),%eax
801029de:	c1 e0 18             	shl    $0x18,%eax
801029e1:	8b 55 08             	mov    0x8(%ebp),%edx
801029e4:	83 c2 08             	add    $0x8,%edx
801029e7:	01 d2                	add    %edx,%edx
801029e9:	83 c2 01             	add    $0x1,%edx
801029ec:	89 44 24 04          	mov    %eax,0x4(%esp)
801029f0:	89 14 24             	mov    %edx,(%esp)
801029f3:	e8 eb fe ff ff       	call   801028e3 <ioapicwrite>
801029f8:	eb 01                	jmp    801029fb <ioapicenable+0x49>

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
    return;
801029fa:	90                   	nop
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
801029fb:	c9                   	leave  
801029fc:	c3                   	ret    
801029fd:	00 00                	add    %al,(%eax)
	...

80102a00 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80102a00:	55                   	push   %ebp
80102a01:	89 e5                	mov    %esp,%ebp
80102a03:	8b 45 08             	mov    0x8(%ebp),%eax
80102a06:	05 00 00 00 80       	add    $0x80000000,%eax
80102a0b:	5d                   	pop    %ebp
80102a0c:	c3                   	ret    

80102a0d <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80102a0d:	55                   	push   %ebp
80102a0e:	89 e5                	mov    %esp,%ebp
80102a10:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80102a13:	c7 44 24 04 8e 88 10 	movl   $0x8010888e,0x4(%esp)
80102a1a:	80 
80102a1b:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102a22:	e8 57 26 00 00       	call   8010507e <initlock>
  kmem.use_lock = 0;
80102a27:	c7 05 54 22 11 80 00 	movl   $0x0,0x80112254
80102a2e:	00 00 00 
  freerange(vstart, vend);
80102a31:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a34:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a38:	8b 45 08             	mov    0x8(%ebp),%eax
80102a3b:	89 04 24             	mov    %eax,(%esp)
80102a3e:	e8 26 00 00 00       	call   80102a69 <freerange>
}
80102a43:	c9                   	leave  
80102a44:	c3                   	ret    

80102a45 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102a45:	55                   	push   %ebp
80102a46:	89 e5                	mov    %esp,%ebp
80102a48:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80102a4b:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a4e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a52:	8b 45 08             	mov    0x8(%ebp),%eax
80102a55:	89 04 24             	mov    %eax,(%esp)
80102a58:	e8 0c 00 00 00       	call   80102a69 <freerange>
  kmem.use_lock = 1;
80102a5d:	c7 05 54 22 11 80 01 	movl   $0x1,0x80112254
80102a64:	00 00 00 
}
80102a67:	c9                   	leave  
80102a68:	c3                   	ret    

80102a69 <freerange>:

void
freerange(void *vstart, void *vend)
{
80102a69:	55                   	push   %ebp
80102a6a:	89 e5                	mov    %esp,%ebp
80102a6c:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102a6f:	8b 45 08             	mov    0x8(%ebp),%eax
80102a72:	05 ff 0f 00 00       	add    $0xfff,%eax
80102a77:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102a7c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102a7f:	eb 12                	jmp    80102a93 <freerange+0x2a>
    kfree(p);
80102a81:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a84:	89 04 24             	mov    %eax,(%esp)
80102a87:	e8 16 00 00 00       	call   80102aa2 <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102a8c:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102a93:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a96:	05 00 10 00 00       	add    $0x1000,%eax
80102a9b:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102a9e:	76 e1                	jbe    80102a81 <freerange+0x18>
    kfree(p);
}
80102aa0:	c9                   	leave  
80102aa1:	c3                   	ret    

80102aa2 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102aa2:	55                   	push   %ebp
80102aa3:	89 e5                	mov    %esp,%ebp
80102aa5:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80102aa8:	8b 45 08             	mov    0x8(%ebp),%eax
80102aab:	25 ff 0f 00 00       	and    $0xfff,%eax
80102ab0:	85 c0                	test   %eax,%eax
80102ab2:	75 1b                	jne    80102acf <kfree+0x2d>
80102ab4:	81 7d 08 3c db 11 80 	cmpl   $0x8011db3c,0x8(%ebp)
80102abb:	72 12                	jb     80102acf <kfree+0x2d>
80102abd:	8b 45 08             	mov    0x8(%ebp),%eax
80102ac0:	89 04 24             	mov    %eax,(%esp)
80102ac3:	e8 38 ff ff ff       	call   80102a00 <v2p>
80102ac8:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102acd:	76 0c                	jbe    80102adb <kfree+0x39>
    panic("kfree");
80102acf:	c7 04 24 93 88 10 80 	movl   $0x80108893,(%esp)
80102ad6:	e8 62 da ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102adb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102ae2:	00 
80102ae3:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102aea:	00 
80102aeb:	8b 45 08             	mov    0x8(%ebp),%eax
80102aee:	89 04 24             	mov    %eax,(%esp)
80102af1:	e8 f8 27 00 00       	call   801052ee <memset>

  if(kmem.use_lock)
80102af6:	a1 54 22 11 80       	mov    0x80112254,%eax
80102afb:	85 c0                	test   %eax,%eax
80102afd:	74 0c                	je     80102b0b <kfree+0x69>
    acquire(&kmem.lock);
80102aff:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102b06:	e8 94 25 00 00       	call   8010509f <acquire>
  r = (struct run*)v;
80102b0b:	8b 45 08             	mov    0x8(%ebp),%eax
80102b0e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102b11:	8b 15 58 22 11 80    	mov    0x80112258,%edx
80102b17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b1a:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102b1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b1f:	a3 58 22 11 80       	mov    %eax,0x80112258
  if(kmem.use_lock)
80102b24:	a1 54 22 11 80       	mov    0x80112254,%eax
80102b29:	85 c0                	test   %eax,%eax
80102b2b:	74 0c                	je     80102b39 <kfree+0x97>
    release(&kmem.lock);
80102b2d:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102b34:	e8 c8 25 00 00       	call   80105101 <release>
}
80102b39:	c9                   	leave  
80102b3a:	c3                   	ret    

80102b3b <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102b3b:	55                   	push   %ebp
80102b3c:	89 e5                	mov    %esp,%ebp
80102b3e:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80102b41:	a1 54 22 11 80       	mov    0x80112254,%eax
80102b46:	85 c0                	test   %eax,%eax
80102b48:	74 0c                	je     80102b56 <kalloc+0x1b>
    acquire(&kmem.lock);
80102b4a:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102b51:	e8 49 25 00 00       	call   8010509f <acquire>
  r = kmem.freelist;
80102b56:	a1 58 22 11 80       	mov    0x80112258,%eax
80102b5b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102b5e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102b62:	74 0a                	je     80102b6e <kalloc+0x33>
    kmem.freelist = r->next;
80102b64:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b67:	8b 00                	mov    (%eax),%eax
80102b69:	a3 58 22 11 80       	mov    %eax,0x80112258
  if(kmem.use_lock)
80102b6e:	a1 54 22 11 80       	mov    0x80112254,%eax
80102b73:	85 c0                	test   %eax,%eax
80102b75:	74 0c                	je     80102b83 <kalloc+0x48>
    release(&kmem.lock);
80102b77:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102b7e:	e8 7e 25 00 00       	call   80105101 <release>
  return (char*)r;
80102b83:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102b86:	c9                   	leave  
80102b87:	c3                   	ret    

80102b88 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102b88:	55                   	push   %ebp
80102b89:	89 e5                	mov    %esp,%ebp
80102b8b:	53                   	push   %ebx
80102b8c:	83 ec 14             	sub    $0x14,%esp
80102b8f:	8b 45 08             	mov    0x8(%ebp),%eax
80102b92:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102b96:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80102b9a:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80102b9e:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80102ba2:	ec                   	in     (%dx),%al
80102ba3:	89 c3                	mov    %eax,%ebx
80102ba5:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80102ba8:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80102bac:	83 c4 14             	add    $0x14,%esp
80102baf:	5b                   	pop    %ebx
80102bb0:	5d                   	pop    %ebp
80102bb1:	c3                   	ret    

80102bb2 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102bb2:	55                   	push   %ebp
80102bb3:	89 e5                	mov    %esp,%ebp
80102bb5:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102bb8:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102bbf:	e8 c4 ff ff ff       	call   80102b88 <inb>
80102bc4:	0f b6 c0             	movzbl %al,%eax
80102bc7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102bca:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102bcd:	83 e0 01             	and    $0x1,%eax
80102bd0:	85 c0                	test   %eax,%eax
80102bd2:	75 0a                	jne    80102bde <kbdgetc+0x2c>
    return -1;
80102bd4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102bd9:	e9 23 01 00 00       	jmp    80102d01 <kbdgetc+0x14f>
  data = inb(KBDATAP);
80102bde:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80102be5:	e8 9e ff ff ff       	call   80102b88 <inb>
80102bea:	0f b6 c0             	movzbl %al,%eax
80102bed:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102bf0:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102bf7:	75 17                	jne    80102c10 <kbdgetc+0x5e>
    shift |= E0ESC;
80102bf9:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102bfe:	83 c8 40             	or     $0x40,%eax
80102c01:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102c06:	b8 00 00 00 00       	mov    $0x0,%eax
80102c0b:	e9 f1 00 00 00       	jmp    80102d01 <kbdgetc+0x14f>
  } else if(data & 0x80){
80102c10:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c13:	25 80 00 00 00       	and    $0x80,%eax
80102c18:	85 c0                	test   %eax,%eax
80102c1a:	74 45                	je     80102c61 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102c1c:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c21:	83 e0 40             	and    $0x40,%eax
80102c24:	85 c0                	test   %eax,%eax
80102c26:	75 08                	jne    80102c30 <kbdgetc+0x7e>
80102c28:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c2b:	83 e0 7f             	and    $0x7f,%eax
80102c2e:	eb 03                	jmp    80102c33 <kbdgetc+0x81>
80102c30:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c33:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102c36:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c39:	05 20 90 10 80       	add    $0x80109020,%eax
80102c3e:	0f b6 00             	movzbl (%eax),%eax
80102c41:	83 c8 40             	or     $0x40,%eax
80102c44:	0f b6 c0             	movzbl %al,%eax
80102c47:	f7 d0                	not    %eax
80102c49:	89 c2                	mov    %eax,%edx
80102c4b:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c50:	21 d0                	and    %edx,%eax
80102c52:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102c57:	b8 00 00 00 00       	mov    $0x0,%eax
80102c5c:	e9 a0 00 00 00       	jmp    80102d01 <kbdgetc+0x14f>
  } else if(shift & E0ESC){
80102c61:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c66:	83 e0 40             	and    $0x40,%eax
80102c69:	85 c0                	test   %eax,%eax
80102c6b:	74 14                	je     80102c81 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102c6d:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102c74:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c79:	83 e0 bf             	and    $0xffffffbf,%eax
80102c7c:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  }

  shift |= shiftcode[data];
80102c81:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c84:	05 20 90 10 80       	add    $0x80109020,%eax
80102c89:	0f b6 00             	movzbl (%eax),%eax
80102c8c:	0f b6 d0             	movzbl %al,%edx
80102c8f:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c94:	09 d0                	or     %edx,%eax
80102c96:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  shift ^= togglecode[data];
80102c9b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c9e:	05 20 91 10 80       	add    $0x80109120,%eax
80102ca3:	0f b6 00             	movzbl (%eax),%eax
80102ca6:	0f b6 d0             	movzbl %al,%edx
80102ca9:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102cae:	31 d0                	xor    %edx,%eax
80102cb0:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  c = charcode[shift & (CTL | SHIFT)][data];
80102cb5:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102cba:	83 e0 03             	and    $0x3,%eax
80102cbd:	8b 04 85 20 95 10 80 	mov    -0x7fef6ae0(,%eax,4),%eax
80102cc4:	03 45 fc             	add    -0x4(%ebp),%eax
80102cc7:	0f b6 00             	movzbl (%eax),%eax
80102cca:	0f b6 c0             	movzbl %al,%eax
80102ccd:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102cd0:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102cd5:	83 e0 08             	and    $0x8,%eax
80102cd8:	85 c0                	test   %eax,%eax
80102cda:	74 22                	je     80102cfe <kbdgetc+0x14c>
    if('a' <= c && c <= 'z')
80102cdc:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102ce0:	76 0c                	jbe    80102cee <kbdgetc+0x13c>
80102ce2:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102ce6:	77 06                	ja     80102cee <kbdgetc+0x13c>
      c += 'A' - 'a';
80102ce8:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102cec:	eb 10                	jmp    80102cfe <kbdgetc+0x14c>
    else if('A' <= c && c <= 'Z')
80102cee:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102cf2:	76 0a                	jbe    80102cfe <kbdgetc+0x14c>
80102cf4:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102cf8:	77 04                	ja     80102cfe <kbdgetc+0x14c>
      c += 'a' - 'A';
80102cfa:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102cfe:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102d01:	c9                   	leave  
80102d02:	c3                   	ret    

80102d03 <kbdintr>:

void
kbdintr(void)
{
80102d03:	55                   	push   %ebp
80102d04:	89 e5                	mov    %esp,%ebp
80102d06:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80102d09:	c7 04 24 b2 2b 10 80 	movl   $0x80102bb2,(%esp)
80102d10:	e8 98 da ff ff       	call   801007ad <consoleintr>
}
80102d15:	c9                   	leave  
80102d16:	c3                   	ret    
	...

80102d18 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102d18:	55                   	push   %ebp
80102d19:	89 e5                	mov    %esp,%ebp
80102d1b:	53                   	push   %ebx
80102d1c:	83 ec 14             	sub    $0x14,%esp
80102d1f:	8b 45 08             	mov    0x8(%ebp),%eax
80102d22:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102d26:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80102d2a:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80102d2e:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80102d32:	ec                   	in     (%dx),%al
80102d33:	89 c3                	mov    %eax,%ebx
80102d35:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80102d38:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80102d3c:	83 c4 14             	add    $0x14,%esp
80102d3f:	5b                   	pop    %ebx
80102d40:	5d                   	pop    %ebp
80102d41:	c3                   	ret    

80102d42 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80102d42:	55                   	push   %ebp
80102d43:	89 e5                	mov    %esp,%ebp
80102d45:	83 ec 08             	sub    $0x8,%esp
80102d48:	8b 55 08             	mov    0x8(%ebp),%edx
80102d4b:	8b 45 0c             	mov    0xc(%ebp),%eax
80102d4e:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102d52:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102d55:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102d59:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102d5d:	ee                   	out    %al,(%dx)
}
80102d5e:	c9                   	leave  
80102d5f:	c3                   	ret    

80102d60 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80102d60:	55                   	push   %ebp
80102d61:	89 e5                	mov    %esp,%ebp
80102d63:	53                   	push   %ebx
80102d64:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80102d67:	9c                   	pushf  
80102d68:	5b                   	pop    %ebx
80102d69:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80102d6c:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102d6f:	83 c4 10             	add    $0x10,%esp
80102d72:	5b                   	pop    %ebx
80102d73:	5d                   	pop    %ebp
80102d74:	c3                   	ret    

80102d75 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102d75:	55                   	push   %ebp
80102d76:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102d78:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102d7d:	8b 55 08             	mov    0x8(%ebp),%edx
80102d80:	c1 e2 02             	shl    $0x2,%edx
80102d83:	01 c2                	add    %eax,%edx
80102d85:	8b 45 0c             	mov    0xc(%ebp),%eax
80102d88:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102d8a:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102d8f:	83 c0 20             	add    $0x20,%eax
80102d92:	8b 00                	mov    (%eax),%eax
}
80102d94:	5d                   	pop    %ebp
80102d95:	c3                   	ret    

80102d96 <lapicinit>:
//PAGEBREAK!

void
lapicinit(void)
{
80102d96:	55                   	push   %ebp
80102d97:	89 e5                	mov    %esp,%ebp
80102d99:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80102d9c:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102da1:	85 c0                	test   %eax,%eax
80102da3:	0f 84 47 01 00 00    	je     80102ef0 <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102da9:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80102db0:	00 
80102db1:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80102db8:	e8 b8 ff ff ff       	call   80102d75 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102dbd:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80102dc4:	00 
80102dc5:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80102dcc:	e8 a4 ff ff ff       	call   80102d75 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102dd1:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80102dd8:	00 
80102dd9:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102de0:	e8 90 ff ff ff       	call   80102d75 <lapicw>
  lapicw(TICR, 10000000); 
80102de5:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80102dec:	00 
80102ded:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80102df4:	e8 7c ff ff ff       	call   80102d75 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80102df9:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102e00:	00 
80102e01:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80102e08:	e8 68 ff ff ff       	call   80102d75 <lapicw>
  lapicw(LINT1, MASKED);
80102e0d:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102e14:	00 
80102e15:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80102e1c:	e8 54 ff ff ff       	call   80102d75 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102e21:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102e26:	83 c0 30             	add    $0x30,%eax
80102e29:	8b 00                	mov    (%eax),%eax
80102e2b:	c1 e8 10             	shr    $0x10,%eax
80102e2e:	25 ff 00 00 00       	and    $0xff,%eax
80102e33:	83 f8 03             	cmp    $0x3,%eax
80102e36:	76 14                	jbe    80102e4c <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
80102e38:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102e3f:	00 
80102e40:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80102e47:	e8 29 ff ff ff       	call   80102d75 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102e4c:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80102e53:	00 
80102e54:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80102e5b:	e8 15 ff ff ff       	call   80102d75 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80102e60:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e67:	00 
80102e68:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102e6f:	e8 01 ff ff ff       	call   80102d75 <lapicw>
  lapicw(ESR, 0);
80102e74:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e7b:	00 
80102e7c:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102e83:	e8 ed fe ff ff       	call   80102d75 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80102e88:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e8f:	00 
80102e90:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102e97:	e8 d9 fe ff ff       	call   80102d75 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80102e9c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102ea3:	00 
80102ea4:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102eab:	e8 c5 fe ff ff       	call   80102d75 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102eb0:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80102eb7:	00 
80102eb8:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102ebf:	e8 b1 fe ff ff       	call   80102d75 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102ec4:	90                   	nop
80102ec5:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102eca:	05 00 03 00 00       	add    $0x300,%eax
80102ecf:	8b 00                	mov    (%eax),%eax
80102ed1:	25 00 10 00 00       	and    $0x1000,%eax
80102ed6:	85 c0                	test   %eax,%eax
80102ed8:	75 eb                	jne    80102ec5 <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80102eda:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102ee1:	00 
80102ee2:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80102ee9:	e8 87 fe ff ff       	call   80102d75 <lapicw>
80102eee:	eb 01                	jmp    80102ef1 <lapicinit+0x15b>

void
lapicinit(void)
{
  if(!lapic) 
    return;
80102ef0:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
80102ef1:	c9                   	leave  
80102ef2:	c3                   	ret    

80102ef3 <cpunum>:

int
cpunum(void)
{
80102ef3:	55                   	push   %ebp
80102ef4:	89 e5                	mov    %esp,%ebp
80102ef6:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80102ef9:	e8 62 fe ff ff       	call   80102d60 <readeflags>
80102efe:	25 00 02 00 00       	and    $0x200,%eax
80102f03:	85 c0                	test   %eax,%eax
80102f05:	74 29                	je     80102f30 <cpunum+0x3d>
    static int n;
    if(n++ == 0)
80102f07:	a1 40 b6 10 80       	mov    0x8010b640,%eax
80102f0c:	85 c0                	test   %eax,%eax
80102f0e:	0f 94 c2             	sete   %dl
80102f11:	83 c0 01             	add    $0x1,%eax
80102f14:	a3 40 b6 10 80       	mov    %eax,0x8010b640
80102f19:	84 d2                	test   %dl,%dl
80102f1b:	74 13                	je     80102f30 <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
80102f1d:	8b 45 04             	mov    0x4(%ebp),%eax
80102f20:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f24:	c7 04 24 9c 88 10 80 	movl   $0x8010889c,(%esp)
80102f2b:	e8 71 d4 ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80102f30:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102f35:	85 c0                	test   %eax,%eax
80102f37:	74 0f                	je     80102f48 <cpunum+0x55>
    return lapic[ID]>>24;
80102f39:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102f3e:	83 c0 20             	add    $0x20,%eax
80102f41:	8b 00                	mov    (%eax),%eax
80102f43:	c1 e8 18             	shr    $0x18,%eax
80102f46:	eb 05                	jmp    80102f4d <cpunum+0x5a>
  return 0;
80102f48:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102f4d:	c9                   	leave  
80102f4e:	c3                   	ret    

80102f4f <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80102f4f:	55                   	push   %ebp
80102f50:	89 e5                	mov    %esp,%ebp
80102f52:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80102f55:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102f5a:	85 c0                	test   %eax,%eax
80102f5c:	74 14                	je     80102f72 <lapiceoi+0x23>
    lapicw(EOI, 0);
80102f5e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f65:	00 
80102f66:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102f6d:	e8 03 fe ff ff       	call   80102d75 <lapicw>
}
80102f72:	c9                   	leave  
80102f73:	c3                   	ret    

80102f74 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80102f74:	55                   	push   %ebp
80102f75:	89 e5                	mov    %esp,%ebp
}
80102f77:	5d                   	pop    %ebp
80102f78:	c3                   	ret    

80102f79 <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
80102f79:	55                   	push   %ebp
80102f7a:	89 e5                	mov    %esp,%ebp
80102f7c:	83 ec 1c             	sub    $0x1c,%esp
80102f7f:	8b 45 08             	mov    0x8(%ebp),%eax
80102f82:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
80102f85:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80102f8c:	00 
80102f8d:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80102f94:	e8 a9 fd ff ff       	call   80102d42 <outb>
  outb(CMOS_PORT+1, 0x0A);
80102f99:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80102fa0:	00 
80102fa1:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80102fa8:	e8 95 fd ff ff       	call   80102d42 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80102fad:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80102fb4:	8b 45 f8             	mov    -0x8(%ebp),%eax
80102fb7:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80102fbc:	8b 45 f8             	mov    -0x8(%ebp),%eax
80102fbf:	8d 50 02             	lea    0x2(%eax),%edx
80102fc2:	8b 45 0c             	mov    0xc(%ebp),%eax
80102fc5:	c1 e8 04             	shr    $0x4,%eax
80102fc8:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80102fcb:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80102fcf:	c1 e0 18             	shl    $0x18,%eax
80102fd2:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fd6:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102fdd:	e8 93 fd ff ff       	call   80102d75 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80102fe2:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80102fe9:	00 
80102fea:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102ff1:	e8 7f fd ff ff       	call   80102d75 <lapicw>
  microdelay(200);
80102ff6:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102ffd:	e8 72 ff ff ff       	call   80102f74 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80103002:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
80103009:	00 
8010300a:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103011:	e8 5f fd ff ff       	call   80102d75 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80103016:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
8010301d:	e8 52 ff ff ff       	call   80102f74 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103022:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103029:	eb 40                	jmp    8010306b <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
8010302b:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
8010302f:	c1 e0 18             	shl    $0x18,%eax
80103032:	89 44 24 04          	mov    %eax,0x4(%esp)
80103036:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010303d:	e8 33 fd ff ff       	call   80102d75 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80103042:	8b 45 0c             	mov    0xc(%ebp),%eax
80103045:	c1 e8 0c             	shr    $0xc,%eax
80103048:	80 cc 06             	or     $0x6,%ah
8010304b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010304f:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103056:	e8 1a fd ff ff       	call   80102d75 <lapicw>
    microdelay(200);
8010305b:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103062:	e8 0d ff ff ff       	call   80102f74 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103067:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010306b:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
8010306f:	7e ba                	jle    8010302b <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
80103071:	c9                   	leave  
80103072:	c3                   	ret    

80103073 <cmos_read>:
#define DAY     0x07
#define MONTH   0x08
#define YEAR    0x09

static uint cmos_read(uint reg)
{
80103073:	55                   	push   %ebp
80103074:	89 e5                	mov    %esp,%ebp
80103076:	83 ec 08             	sub    $0x8,%esp
  outb(CMOS_PORT,  reg);
80103079:	8b 45 08             	mov    0x8(%ebp),%eax
8010307c:	0f b6 c0             	movzbl %al,%eax
8010307f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103083:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
8010308a:	e8 b3 fc ff ff       	call   80102d42 <outb>
  microdelay(200);
8010308f:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103096:	e8 d9 fe ff ff       	call   80102f74 <microdelay>

  return inb(CMOS_RETURN);
8010309b:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801030a2:	e8 71 fc ff ff       	call   80102d18 <inb>
801030a7:	0f b6 c0             	movzbl %al,%eax
}
801030aa:	c9                   	leave  
801030ab:	c3                   	ret    

801030ac <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
801030ac:	55                   	push   %ebp
801030ad:	89 e5                	mov    %esp,%ebp
801030af:	83 ec 04             	sub    $0x4,%esp
  r->second = cmos_read(SECS);
801030b2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801030b9:	e8 b5 ff ff ff       	call   80103073 <cmos_read>
801030be:	8b 55 08             	mov    0x8(%ebp),%edx
801030c1:	89 02                	mov    %eax,(%edx)
  r->minute = cmos_read(MINS);
801030c3:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801030ca:	e8 a4 ff ff ff       	call   80103073 <cmos_read>
801030cf:	8b 55 08             	mov    0x8(%ebp),%edx
801030d2:	89 42 04             	mov    %eax,0x4(%edx)
  r->hour   = cmos_read(HOURS);
801030d5:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801030dc:	e8 92 ff ff ff       	call   80103073 <cmos_read>
801030e1:	8b 55 08             	mov    0x8(%ebp),%edx
801030e4:	89 42 08             	mov    %eax,0x8(%edx)
  r->day    = cmos_read(DAY);
801030e7:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
801030ee:	e8 80 ff ff ff       	call   80103073 <cmos_read>
801030f3:	8b 55 08             	mov    0x8(%ebp),%edx
801030f6:	89 42 0c             	mov    %eax,0xc(%edx)
  r->month  = cmos_read(MONTH);
801030f9:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80103100:	e8 6e ff ff ff       	call   80103073 <cmos_read>
80103105:	8b 55 08             	mov    0x8(%ebp),%edx
80103108:	89 42 10             	mov    %eax,0x10(%edx)
  r->year   = cmos_read(YEAR);
8010310b:	c7 04 24 09 00 00 00 	movl   $0x9,(%esp)
80103112:	e8 5c ff ff ff       	call   80103073 <cmos_read>
80103117:	8b 55 08             	mov    0x8(%ebp),%edx
8010311a:	89 42 14             	mov    %eax,0x14(%edx)
}
8010311d:	c9                   	leave  
8010311e:	c3                   	ret    

8010311f <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
8010311f:	55                   	push   %ebp
80103120:	89 e5                	mov    %esp,%ebp
80103122:	83 ec 58             	sub    $0x58,%esp
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
80103125:	c7 04 24 0b 00 00 00 	movl   $0xb,(%esp)
8010312c:	e8 42 ff ff ff       	call   80103073 <cmos_read>
80103131:	89 45 f4             	mov    %eax,-0xc(%ebp)

  bcd = (sb & (1 << 2)) == 0;
80103134:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103137:	83 e0 04             	and    $0x4,%eax
8010313a:	85 c0                	test   %eax,%eax
8010313c:	0f 94 c0             	sete   %al
8010313f:	0f b6 c0             	movzbl %al,%eax
80103142:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103145:	eb 01                	jmp    80103148 <cmostime+0x29>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
    fill_rtcdate(&t2);
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
80103147:	90                   	nop

  bcd = (sb & (1 << 2)) == 0;

  // make sure CMOS doesn't modify time while we read it
  for (;;) {
    fill_rtcdate(&t1);
80103148:	8d 45 d8             	lea    -0x28(%ebp),%eax
8010314b:	89 04 24             	mov    %eax,(%esp)
8010314e:	e8 59 ff ff ff       	call   801030ac <fill_rtcdate>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
80103153:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
8010315a:	e8 14 ff ff ff       	call   80103073 <cmos_read>
8010315f:	25 80 00 00 00       	and    $0x80,%eax
80103164:	85 c0                	test   %eax,%eax
80103166:	75 2b                	jne    80103193 <cmostime+0x74>
        continue;
    fill_rtcdate(&t2);
80103168:	8d 45 c0             	lea    -0x40(%ebp),%eax
8010316b:	89 04 24             	mov    %eax,(%esp)
8010316e:	e8 39 ff ff ff       	call   801030ac <fill_rtcdate>
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
80103173:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
8010317a:	00 
8010317b:	8d 45 c0             	lea    -0x40(%ebp),%eax
8010317e:	89 44 24 04          	mov    %eax,0x4(%esp)
80103182:	8d 45 d8             	lea    -0x28(%ebp),%eax
80103185:	89 04 24             	mov    %eax,(%esp)
80103188:	e8 d8 21 00 00       	call   80105365 <memcmp>
8010318d:	85 c0                	test   %eax,%eax
8010318f:	75 b6                	jne    80103147 <cmostime+0x28>
      break;
80103191:	eb 03                	jmp    80103196 <cmostime+0x77>

  // make sure CMOS doesn't modify time while we read it
  for (;;) {
    fill_rtcdate(&t1);
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
80103193:	90                   	nop
    fill_rtcdate(&t2);
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
80103194:	eb b1                	jmp    80103147 <cmostime+0x28>

  // convert
  if (bcd) {
80103196:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010319a:	0f 84 a8 00 00 00    	je     80103248 <cmostime+0x129>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
801031a0:	8b 45 d8             	mov    -0x28(%ebp),%eax
801031a3:	89 c2                	mov    %eax,%edx
801031a5:	c1 ea 04             	shr    $0x4,%edx
801031a8:	89 d0                	mov    %edx,%eax
801031aa:	c1 e0 02             	shl    $0x2,%eax
801031ad:	01 d0                	add    %edx,%eax
801031af:	01 c0                	add    %eax,%eax
801031b1:	8b 55 d8             	mov    -0x28(%ebp),%edx
801031b4:	83 e2 0f             	and    $0xf,%edx
801031b7:	01 d0                	add    %edx,%eax
801031b9:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(minute);
801031bc:	8b 45 dc             	mov    -0x24(%ebp),%eax
801031bf:	89 c2                	mov    %eax,%edx
801031c1:	c1 ea 04             	shr    $0x4,%edx
801031c4:	89 d0                	mov    %edx,%eax
801031c6:	c1 e0 02             	shl    $0x2,%eax
801031c9:	01 d0                	add    %edx,%eax
801031cb:	01 c0                	add    %eax,%eax
801031cd:	8b 55 dc             	mov    -0x24(%ebp),%edx
801031d0:	83 e2 0f             	and    $0xf,%edx
801031d3:	01 d0                	add    %edx,%eax
801031d5:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(hour  );
801031d8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801031db:	89 c2                	mov    %eax,%edx
801031dd:	c1 ea 04             	shr    $0x4,%edx
801031e0:	89 d0                	mov    %edx,%eax
801031e2:	c1 e0 02             	shl    $0x2,%eax
801031e5:	01 d0                	add    %edx,%eax
801031e7:	01 c0                	add    %eax,%eax
801031e9:	8b 55 e0             	mov    -0x20(%ebp),%edx
801031ec:	83 e2 0f             	and    $0xf,%edx
801031ef:	01 d0                	add    %edx,%eax
801031f1:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(day   );
801031f4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801031f7:	89 c2                	mov    %eax,%edx
801031f9:	c1 ea 04             	shr    $0x4,%edx
801031fc:	89 d0                	mov    %edx,%eax
801031fe:	c1 e0 02             	shl    $0x2,%eax
80103201:	01 d0                	add    %edx,%eax
80103203:	01 c0                	add    %eax,%eax
80103205:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103208:	83 e2 0f             	and    $0xf,%edx
8010320b:	01 d0                	add    %edx,%eax
8010320d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    CONV(month );
80103210:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103213:	89 c2                	mov    %eax,%edx
80103215:	c1 ea 04             	shr    $0x4,%edx
80103218:	89 d0                	mov    %edx,%eax
8010321a:	c1 e0 02             	shl    $0x2,%eax
8010321d:	01 d0                	add    %edx,%eax
8010321f:	01 c0                	add    %eax,%eax
80103221:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103224:	83 e2 0f             	and    $0xf,%edx
80103227:	01 d0                	add    %edx,%eax
80103229:	89 45 e8             	mov    %eax,-0x18(%ebp)
    CONV(year  );
8010322c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010322f:	89 c2                	mov    %eax,%edx
80103231:	c1 ea 04             	shr    $0x4,%edx
80103234:	89 d0                	mov    %edx,%eax
80103236:	c1 e0 02             	shl    $0x2,%eax
80103239:	01 d0                	add    %edx,%eax
8010323b:	01 c0                	add    %eax,%eax
8010323d:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103240:	83 e2 0f             	and    $0xf,%edx
80103243:	01 d0                	add    %edx,%eax
80103245:	89 45 ec             	mov    %eax,-0x14(%ebp)
#undef     CONV
  }

  *r = t1;
80103248:	8b 45 08             	mov    0x8(%ebp),%eax
8010324b:	8b 55 d8             	mov    -0x28(%ebp),%edx
8010324e:	89 10                	mov    %edx,(%eax)
80103250:	8b 55 dc             	mov    -0x24(%ebp),%edx
80103253:	89 50 04             	mov    %edx,0x4(%eax)
80103256:	8b 55 e0             	mov    -0x20(%ebp),%edx
80103259:	89 50 08             	mov    %edx,0x8(%eax)
8010325c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010325f:	89 50 0c             	mov    %edx,0xc(%eax)
80103262:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103265:	89 50 10             	mov    %edx,0x10(%eax)
80103268:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010326b:	89 50 14             	mov    %edx,0x14(%eax)
  r->year += 2000;
8010326e:	8b 45 08             	mov    0x8(%ebp),%eax
80103271:	8b 40 14             	mov    0x14(%eax),%eax
80103274:	8d 90 d0 07 00 00    	lea    0x7d0(%eax),%edx
8010327a:	8b 45 08             	mov    0x8(%ebp),%eax
8010327d:	89 50 14             	mov    %edx,0x14(%eax)
}
80103280:	c9                   	leave  
80103281:	c3                   	ret    
	...

80103284 <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(void)
{
80103284:	55                   	push   %ebp
80103285:	89 e5                	mov    %esp,%ebp
80103287:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
8010328a:	c7 44 24 04 c8 88 10 	movl   $0x801088c8,0x4(%esp)
80103291:	80 
80103292:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103299:	e8 e0 1d 00 00       	call   8010507e <initlock>
  readsb(ROOTDEV, &sb);
8010329e:	8d 45 e8             	lea    -0x18(%ebp),%eax
801032a1:	89 44 24 04          	mov    %eax,0x4(%esp)
801032a5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801032ac:	e8 73 e0 ff ff       	call   80101324 <readsb>
  log.start = sb.size - sb.nlog;
801032b1:	8b 55 e8             	mov    -0x18(%ebp),%edx
801032b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032b7:	89 d1                	mov    %edx,%ecx
801032b9:	29 c1                	sub    %eax,%ecx
801032bb:	89 c8                	mov    %ecx,%eax
801032bd:	a3 94 22 11 80       	mov    %eax,0x80112294
  log.size = sb.nlog;
801032c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032c5:	a3 98 22 11 80       	mov    %eax,0x80112298
  log.dev = ROOTDEV;
801032ca:	c7 05 a4 22 11 80 01 	movl   $0x1,0x801122a4
801032d1:	00 00 00 
  recover_from_log();
801032d4:	e8 97 01 00 00       	call   80103470 <recover_from_log>
}
801032d9:	c9                   	leave  
801032da:	c3                   	ret    

801032db <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
801032db:	55                   	push   %ebp
801032dc:	89 e5                	mov    %esp,%ebp
801032de:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801032e1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801032e8:	e9 89 00 00 00       	jmp    80103376 <install_trans+0x9b>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801032ed:	a1 94 22 11 80       	mov    0x80112294,%eax
801032f2:	03 45 f4             	add    -0xc(%ebp),%eax
801032f5:	83 c0 01             	add    $0x1,%eax
801032f8:	89 c2                	mov    %eax,%edx
801032fa:	a1 a4 22 11 80       	mov    0x801122a4,%eax
801032ff:	89 54 24 04          	mov    %edx,0x4(%esp)
80103303:	89 04 24             	mov    %eax,(%esp)
80103306:	e8 9b ce ff ff       	call   801001a6 <bread>
8010330b:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
8010330e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103311:	83 c0 10             	add    $0x10,%eax
80103314:	8b 04 85 6c 22 11 80 	mov    -0x7feedd94(,%eax,4),%eax
8010331b:	89 c2                	mov    %eax,%edx
8010331d:	a1 a4 22 11 80       	mov    0x801122a4,%eax
80103322:	89 54 24 04          	mov    %edx,0x4(%esp)
80103326:	89 04 24             	mov    %eax,(%esp)
80103329:	e8 78 ce ff ff       	call   801001a6 <bread>
8010332e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80103331:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103334:	8d 50 18             	lea    0x18(%eax),%edx
80103337:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010333a:	83 c0 18             	add    $0x18,%eax
8010333d:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103344:	00 
80103345:	89 54 24 04          	mov    %edx,0x4(%esp)
80103349:	89 04 24             	mov    %eax,(%esp)
8010334c:	e8 70 20 00 00       	call   801053c1 <memmove>
    bwrite(dbuf);  // write dst to disk
80103351:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103354:	89 04 24             	mov    %eax,(%esp)
80103357:	e8 81 ce ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
8010335c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010335f:	89 04 24             	mov    %eax,(%esp)
80103362:	e8 b0 ce ff ff       	call   80100217 <brelse>
    brelse(dbuf);
80103367:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010336a:	89 04 24             	mov    %eax,(%esp)
8010336d:	e8 a5 ce ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103372:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103376:	a1 a8 22 11 80       	mov    0x801122a8,%eax
8010337b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010337e:	0f 8f 69 ff ff ff    	jg     801032ed <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80103384:	c9                   	leave  
80103385:	c3                   	ret    

80103386 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103386:	55                   	push   %ebp
80103387:	89 e5                	mov    %esp,%ebp
80103389:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
8010338c:	a1 94 22 11 80       	mov    0x80112294,%eax
80103391:	89 c2                	mov    %eax,%edx
80103393:	a1 a4 22 11 80       	mov    0x801122a4,%eax
80103398:	89 54 24 04          	mov    %edx,0x4(%esp)
8010339c:	89 04 24             	mov    %eax,(%esp)
8010339f:	e8 02 ce ff ff       	call   801001a6 <bread>
801033a4:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
801033a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033aa:	83 c0 18             	add    $0x18,%eax
801033ad:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
801033b0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801033b3:	8b 00                	mov    (%eax),%eax
801033b5:	a3 a8 22 11 80       	mov    %eax,0x801122a8
  for (i = 0; i < log.lh.n; i++) {
801033ba:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801033c1:	eb 1b                	jmp    801033de <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
801033c3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801033c6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801033c9:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
801033cd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801033d0:	83 c2 10             	add    $0x10,%edx
801033d3:	89 04 95 6c 22 11 80 	mov    %eax,-0x7feedd94(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
801033da:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801033de:	a1 a8 22 11 80       	mov    0x801122a8,%eax
801033e3:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801033e6:	7f db                	jg     801033c3 <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
801033e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033eb:	89 04 24             	mov    %eax,(%esp)
801033ee:	e8 24 ce ff ff       	call   80100217 <brelse>
}
801033f3:	c9                   	leave  
801033f4:	c3                   	ret    

801033f5 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
801033f5:	55                   	push   %ebp
801033f6:	89 e5                	mov    %esp,%ebp
801033f8:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
801033fb:	a1 94 22 11 80       	mov    0x80112294,%eax
80103400:	89 c2                	mov    %eax,%edx
80103402:	a1 a4 22 11 80       	mov    0x801122a4,%eax
80103407:	89 54 24 04          	mov    %edx,0x4(%esp)
8010340b:	89 04 24             	mov    %eax,(%esp)
8010340e:	e8 93 cd ff ff       	call   801001a6 <bread>
80103413:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
80103416:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103419:	83 c0 18             	add    $0x18,%eax
8010341c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
8010341f:	8b 15 a8 22 11 80    	mov    0x801122a8,%edx
80103425:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103428:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
8010342a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103431:	eb 1b                	jmp    8010344e <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
80103433:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103436:	83 c0 10             	add    $0x10,%eax
80103439:	8b 0c 85 6c 22 11 80 	mov    -0x7feedd94(,%eax,4),%ecx
80103440:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103443:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103446:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
8010344a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010344e:	a1 a8 22 11 80       	mov    0x801122a8,%eax
80103453:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103456:	7f db                	jg     80103433 <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
80103458:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010345b:	89 04 24             	mov    %eax,(%esp)
8010345e:	e8 7a cd ff ff       	call   801001dd <bwrite>
  brelse(buf);
80103463:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103466:	89 04 24             	mov    %eax,(%esp)
80103469:	e8 a9 cd ff ff       	call   80100217 <brelse>
}
8010346e:	c9                   	leave  
8010346f:	c3                   	ret    

80103470 <recover_from_log>:

static void
recover_from_log(void)
{
80103470:	55                   	push   %ebp
80103471:	89 e5                	mov    %esp,%ebp
80103473:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80103476:	e8 0b ff ff ff       	call   80103386 <read_head>
  install_trans(); // if committed, copy from log to disk
8010347b:	e8 5b fe ff ff       	call   801032db <install_trans>
  log.lh.n = 0;
80103480:	c7 05 a8 22 11 80 00 	movl   $0x0,0x801122a8
80103487:	00 00 00 
  write_head(); // clear the log
8010348a:	e8 66 ff ff ff       	call   801033f5 <write_head>
}
8010348f:	c9                   	leave  
80103490:	c3                   	ret    

80103491 <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
80103491:	55                   	push   %ebp
80103492:	89 e5                	mov    %esp,%ebp
80103494:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103497:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
8010349e:	e8 fc 1b 00 00       	call   8010509f <acquire>
  while(1){
    if(log.committing){
801034a3:	a1 a0 22 11 80       	mov    0x801122a0,%eax
801034a8:	85 c0                	test   %eax,%eax
801034aa:	74 16                	je     801034c2 <begin_op+0x31>
      sleep(&log, &log.lock);
801034ac:	c7 44 24 04 60 22 11 	movl   $0x80112260,0x4(%esp)
801034b3:	80 
801034b4:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
801034bb:	e8 89 18 00 00       	call   80104d49 <sleep>
    } else {
      log.outstanding += 1;
      release(&log.lock);
      break;
    }
  }
801034c0:	eb e1                	jmp    801034a3 <begin_op+0x12>
{
  acquire(&log.lock);
  while(1){
    if(log.committing){
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
801034c2:	8b 0d a8 22 11 80    	mov    0x801122a8,%ecx
801034c8:	a1 9c 22 11 80       	mov    0x8011229c,%eax
801034cd:	8d 50 01             	lea    0x1(%eax),%edx
801034d0:	89 d0                	mov    %edx,%eax
801034d2:	c1 e0 02             	shl    $0x2,%eax
801034d5:	01 d0                	add    %edx,%eax
801034d7:	01 c0                	add    %eax,%eax
801034d9:	01 c8                	add    %ecx,%eax
801034db:	83 f8 1e             	cmp    $0x1e,%eax
801034de:	7e 16                	jle    801034f6 <begin_op+0x65>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
801034e0:	c7 44 24 04 60 22 11 	movl   $0x80112260,0x4(%esp)
801034e7:	80 
801034e8:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
801034ef:	e8 55 18 00 00       	call   80104d49 <sleep>
    } else {
      log.outstanding += 1;
      release(&log.lock);
      break;
    }
  }
801034f4:	eb ad                	jmp    801034a3 <begin_op+0x12>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    } else {
      log.outstanding += 1;
801034f6:	a1 9c 22 11 80       	mov    0x8011229c,%eax
801034fb:	83 c0 01             	add    $0x1,%eax
801034fe:	a3 9c 22 11 80       	mov    %eax,0x8011229c
      release(&log.lock);
80103503:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
8010350a:	e8 f2 1b 00 00       	call   80105101 <release>
      break;
8010350f:	90                   	nop
    }
  }
}
80103510:	c9                   	leave  
80103511:	c3                   	ret    

80103512 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
80103512:	55                   	push   %ebp
80103513:	89 e5                	mov    %esp,%ebp
80103515:	83 ec 28             	sub    $0x28,%esp
  int do_commit = 0;
80103518:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&log.lock);
8010351f:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103526:	e8 74 1b 00 00       	call   8010509f <acquire>
  log.outstanding -= 1;
8010352b:	a1 9c 22 11 80       	mov    0x8011229c,%eax
80103530:	83 e8 01             	sub    $0x1,%eax
80103533:	a3 9c 22 11 80       	mov    %eax,0x8011229c
  if(log.committing)
80103538:	a1 a0 22 11 80       	mov    0x801122a0,%eax
8010353d:	85 c0                	test   %eax,%eax
8010353f:	74 0c                	je     8010354d <end_op+0x3b>
    panic("log.committing");
80103541:	c7 04 24 cc 88 10 80 	movl   $0x801088cc,(%esp)
80103548:	e8 f0 cf ff ff       	call   8010053d <panic>
  if(log.outstanding == 0){
8010354d:	a1 9c 22 11 80       	mov    0x8011229c,%eax
80103552:	85 c0                	test   %eax,%eax
80103554:	75 13                	jne    80103569 <end_op+0x57>
    do_commit = 1;
80103556:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    log.committing = 1;
8010355d:	c7 05 a0 22 11 80 01 	movl   $0x1,0x801122a0
80103564:	00 00 00 
80103567:	eb 0c                	jmp    80103575 <end_op+0x63>
  } else {
    // begin_op() may be waiting for log space.
    wakeup(&log);
80103569:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103570:	e8 e3 18 00 00       	call   80104e58 <wakeup>
  }
  release(&log.lock);
80103575:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
8010357c:	e8 80 1b 00 00       	call   80105101 <release>

  if(do_commit){
80103581:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103585:	74 33                	je     801035ba <end_op+0xa8>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
80103587:	e8 db 00 00 00       	call   80103667 <commit>
    acquire(&log.lock);
8010358c:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103593:	e8 07 1b 00 00       	call   8010509f <acquire>
    log.committing = 0;
80103598:	c7 05 a0 22 11 80 00 	movl   $0x0,0x801122a0
8010359f:	00 00 00 
    wakeup(&log);
801035a2:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
801035a9:	e8 aa 18 00 00       	call   80104e58 <wakeup>
    release(&log.lock);
801035ae:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
801035b5:	e8 47 1b 00 00       	call   80105101 <release>
  }
}
801035ba:	c9                   	leave  
801035bb:	c3                   	ret    

801035bc <write_log>:

// Copy modified blocks from cache to log.
static void 
write_log(void)
{
801035bc:	55                   	push   %ebp
801035bd:	89 e5                	mov    %esp,%ebp
801035bf:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801035c2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801035c9:	e9 89 00 00 00       	jmp    80103657 <write_log+0x9b>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
801035ce:	a1 94 22 11 80       	mov    0x80112294,%eax
801035d3:	03 45 f4             	add    -0xc(%ebp),%eax
801035d6:	83 c0 01             	add    $0x1,%eax
801035d9:	89 c2                	mov    %eax,%edx
801035db:	a1 a4 22 11 80       	mov    0x801122a4,%eax
801035e0:	89 54 24 04          	mov    %edx,0x4(%esp)
801035e4:	89 04 24             	mov    %eax,(%esp)
801035e7:	e8 ba cb ff ff       	call   801001a6 <bread>
801035ec:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *from = bread(log.dev, log.lh.sector[tail]); // cache block
801035ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035f2:	83 c0 10             	add    $0x10,%eax
801035f5:	8b 04 85 6c 22 11 80 	mov    -0x7feedd94(,%eax,4),%eax
801035fc:	89 c2                	mov    %eax,%edx
801035fe:	a1 a4 22 11 80       	mov    0x801122a4,%eax
80103603:	89 54 24 04          	mov    %edx,0x4(%esp)
80103607:	89 04 24             	mov    %eax,(%esp)
8010360a:	e8 97 cb ff ff       	call   801001a6 <bread>
8010360f:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(to->data, from->data, BSIZE);
80103612:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103615:	8d 50 18             	lea    0x18(%eax),%edx
80103618:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010361b:	83 c0 18             	add    $0x18,%eax
8010361e:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103625:	00 
80103626:	89 54 24 04          	mov    %edx,0x4(%esp)
8010362a:	89 04 24             	mov    %eax,(%esp)
8010362d:	e8 8f 1d 00 00       	call   801053c1 <memmove>
    bwrite(to);  // write the log
80103632:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103635:	89 04 24             	mov    %eax,(%esp)
80103638:	e8 a0 cb ff ff       	call   801001dd <bwrite>
    brelse(from); 
8010363d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103640:	89 04 24             	mov    %eax,(%esp)
80103643:	e8 cf cb ff ff       	call   80100217 <brelse>
    brelse(to);
80103648:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010364b:	89 04 24             	mov    %eax,(%esp)
8010364e:	e8 c4 cb ff ff       	call   80100217 <brelse>
static void 
write_log(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103653:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103657:	a1 a8 22 11 80       	mov    0x801122a8,%eax
8010365c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010365f:	0f 8f 69 ff ff ff    	jg     801035ce <write_log+0x12>
    memmove(to->data, from->data, BSIZE);
    bwrite(to);  // write the log
    brelse(from); 
    brelse(to);
  }
}
80103665:	c9                   	leave  
80103666:	c3                   	ret    

80103667 <commit>:

static void
commit()
{
80103667:	55                   	push   %ebp
80103668:	89 e5                	mov    %esp,%ebp
8010366a:	83 ec 08             	sub    $0x8,%esp
  if (log.lh.n > 0) {
8010366d:	a1 a8 22 11 80       	mov    0x801122a8,%eax
80103672:	85 c0                	test   %eax,%eax
80103674:	7e 1e                	jle    80103694 <commit+0x2d>
    write_log();     // Write modified blocks from cache to log
80103676:	e8 41 ff ff ff       	call   801035bc <write_log>
    write_head();    // Write header to disk -- the real commit
8010367b:	e8 75 fd ff ff       	call   801033f5 <write_head>
    install_trans(); // Now install writes to home locations
80103680:	e8 56 fc ff ff       	call   801032db <install_trans>
    log.lh.n = 0; 
80103685:	c7 05 a8 22 11 80 00 	movl   $0x0,0x801122a8
8010368c:	00 00 00 
    write_head();    // Erase the transaction from the log
8010368f:	e8 61 fd ff ff       	call   801033f5 <write_head>
  }
}
80103694:	c9                   	leave  
80103695:	c3                   	ret    

80103696 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103696:	55                   	push   %ebp
80103697:	89 e5                	mov    %esp,%ebp
80103699:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
8010369c:	a1 a8 22 11 80       	mov    0x801122a8,%eax
801036a1:	83 f8 1d             	cmp    $0x1d,%eax
801036a4:	7f 12                	jg     801036b8 <log_write+0x22>
801036a6:	a1 a8 22 11 80       	mov    0x801122a8,%eax
801036ab:	8b 15 98 22 11 80    	mov    0x80112298,%edx
801036b1:	83 ea 01             	sub    $0x1,%edx
801036b4:	39 d0                	cmp    %edx,%eax
801036b6:	7c 0c                	jl     801036c4 <log_write+0x2e>
    panic("too big a transaction");
801036b8:	c7 04 24 db 88 10 80 	movl   $0x801088db,(%esp)
801036bf:	e8 79 ce ff ff       	call   8010053d <panic>
  if (log.outstanding < 1)
801036c4:	a1 9c 22 11 80       	mov    0x8011229c,%eax
801036c9:	85 c0                	test   %eax,%eax
801036cb:	7f 0c                	jg     801036d9 <log_write+0x43>
    panic("log_write outside of trans");
801036cd:	c7 04 24 f1 88 10 80 	movl   $0x801088f1,(%esp)
801036d4:	e8 64 ce ff ff       	call   8010053d <panic>

  acquire(&log.lock);
801036d9:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
801036e0:	e8 ba 19 00 00       	call   8010509f <acquire>
  for (i = 0; i < log.lh.n; i++) {
801036e5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801036ec:	eb 1d                	jmp    8010370b <log_write+0x75>
    if (log.lh.sector[i] == b->sector)   // log absorbtion
801036ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036f1:	83 c0 10             	add    $0x10,%eax
801036f4:	8b 04 85 6c 22 11 80 	mov    -0x7feedd94(,%eax,4),%eax
801036fb:	89 c2                	mov    %eax,%edx
801036fd:	8b 45 08             	mov    0x8(%ebp),%eax
80103700:	8b 40 08             	mov    0x8(%eax),%eax
80103703:	39 c2                	cmp    %eax,%edx
80103705:	74 10                	je     80103717 <log_write+0x81>
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
80103707:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010370b:	a1 a8 22 11 80       	mov    0x801122a8,%eax
80103710:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103713:	7f d9                	jg     801036ee <log_write+0x58>
80103715:	eb 01                	jmp    80103718 <log_write+0x82>
    if (log.lh.sector[i] == b->sector)   // log absorbtion
      break;
80103717:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
80103718:	8b 45 08             	mov    0x8(%ebp),%eax
8010371b:	8b 40 08             	mov    0x8(%eax),%eax
8010371e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103721:	83 c2 10             	add    $0x10,%edx
80103724:	89 04 95 6c 22 11 80 	mov    %eax,-0x7feedd94(,%edx,4)
  if (i == log.lh.n)
8010372b:	a1 a8 22 11 80       	mov    0x801122a8,%eax
80103730:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103733:	75 0d                	jne    80103742 <log_write+0xac>
    log.lh.n++;
80103735:	a1 a8 22 11 80       	mov    0x801122a8,%eax
8010373a:	83 c0 01             	add    $0x1,%eax
8010373d:	a3 a8 22 11 80       	mov    %eax,0x801122a8
  b->flags |= B_DIRTY; // prevent eviction
80103742:	8b 45 08             	mov    0x8(%ebp),%eax
80103745:	8b 00                	mov    (%eax),%eax
80103747:	89 c2                	mov    %eax,%edx
80103749:	83 ca 04             	or     $0x4,%edx
8010374c:	8b 45 08             	mov    0x8(%ebp),%eax
8010374f:	89 10                	mov    %edx,(%eax)
  release(&log.lock);
80103751:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103758:	e8 a4 19 00 00       	call   80105101 <release>
}
8010375d:	c9                   	leave  
8010375e:	c3                   	ret    
	...

80103760 <v2p>:
80103760:	55                   	push   %ebp
80103761:	89 e5                	mov    %esp,%ebp
80103763:	8b 45 08             	mov    0x8(%ebp),%eax
80103766:	05 00 00 00 80       	add    $0x80000000,%eax
8010376b:	5d                   	pop    %ebp
8010376c:	c3                   	ret    

8010376d <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
8010376d:	55                   	push   %ebp
8010376e:	89 e5                	mov    %esp,%ebp
80103770:	8b 45 08             	mov    0x8(%ebp),%eax
80103773:	05 00 00 00 80       	add    $0x80000000,%eax
80103778:	5d                   	pop    %ebp
80103779:	c3                   	ret    

8010377a <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
8010377a:	55                   	push   %ebp
8010377b:	89 e5                	mov    %esp,%ebp
8010377d:	53                   	push   %ebx
8010377e:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80103781:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103784:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80103787:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
8010378a:	89 c3                	mov    %eax,%ebx
8010378c:	89 d8                	mov    %ebx,%eax
8010378e:	f0 87 02             	lock xchg %eax,(%edx)
80103791:	89 c3                	mov    %eax,%ebx
80103793:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103796:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103799:	83 c4 10             	add    $0x10,%esp
8010379c:	5b                   	pop    %ebx
8010379d:	5d                   	pop    %ebp
8010379e:	c3                   	ret    

8010379f <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
8010379f:	55                   	push   %ebp
801037a0:	89 e5                	mov    %esp,%ebp
801037a2:	83 e4 f0             	and    $0xfffffff0,%esp
801037a5:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
801037a8:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
801037af:	80 
801037b0:	c7 04 24 3c db 11 80 	movl   $0x8011db3c,(%esp)
801037b7:	e8 51 f2 ff ff       	call   80102a0d <kinit1>
  kvmalloc();      // kernel page table
801037bc:	e8 51 47 00 00       	call   80107f12 <kvmalloc>
  mpinit();        // collect info about this machine
801037c1:	e8 53 04 00 00       	call   80103c19 <mpinit>
  lapicinit();
801037c6:	e8 cb f5 ff ff       	call   80102d96 <lapicinit>
  seginit();       // set up segments
801037cb:	e8 e5 40 00 00       	call   801078b5 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
801037d0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801037d6:	0f b6 00             	movzbl (%eax),%eax
801037d9:	0f b6 c0             	movzbl %al,%eax
801037dc:	89 44 24 04          	mov    %eax,0x4(%esp)
801037e0:	c7 04 24 0c 89 10 80 	movl   $0x8010890c,(%esp)
801037e7:	e8 b5 cb ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
801037ec:	e8 8d 06 00 00       	call   80103e7e <picinit>
  ioapicinit();    // another interrupt controller
801037f1:	e8 07 f1 ff ff       	call   801028fd <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
801037f6:	e8 95 d2 ff ff       	call   80100a90 <consoleinit>
  uartinit();      // serial port
801037fb:	e8 00 34 00 00       	call   80106c00 <uartinit>
  pinit();         // process table
80103800:	e8 96 0b 00 00       	call   8010439b <pinit>
  tvinit();        // trap vectors
80103805:	e8 85 2f 00 00       	call   8010678f <tvinit>
  binit();         // buffer cache
8010380a:	e8 25 c8 ff ff       	call   80100034 <binit>
  fileinit();      // file table
8010380f:	e8 24 d7 ff ff       	call   80100f38 <fileinit>
  iinit();         // inode cache
80103814:	e8 d2 dd ff ff       	call   801015eb <iinit>
  ideinit();       // disk
80103819:	e8 44 ed ff ff       	call   80102562 <ideinit>
  if(!ismp)
8010381e:	a1 44 23 11 80       	mov    0x80112344,%eax
80103823:	85 c0                	test   %eax,%eax
80103825:	75 05                	jne    8010382c <main+0x8d>
    timerinit();   // uniprocessor timer
80103827:	e8 a6 2e 00 00       	call   801066d2 <timerinit>
  startothers();   // start other processors
8010382c:	e8 7f 00 00 00       	call   801038b0 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80103831:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103838:	8e 
80103839:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103840:	e8 00 f2 ff ff       	call   80102a45 <kinit2>
  userinit();      // first user process
80103845:	e8 a7 0c 00 00       	call   801044f1 <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
8010384a:	e8 1a 00 00 00       	call   80103869 <mpmain>

8010384f <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
8010384f:	55                   	push   %ebp
80103850:	89 e5                	mov    %esp,%ebp
80103852:	83 ec 08             	sub    $0x8,%esp
  switchkvm(); 
80103855:	e8 cf 46 00 00       	call   80107f29 <switchkvm>
  seginit();
8010385a:	e8 56 40 00 00       	call   801078b5 <seginit>
  lapicinit();
8010385f:	e8 32 f5 ff ff       	call   80102d96 <lapicinit>
  mpmain();
80103864:	e8 00 00 00 00       	call   80103869 <mpmain>

80103869 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103869:	55                   	push   %ebp
8010386a:	89 e5                	mov    %esp,%ebp
8010386c:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
8010386f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103875:	0f b6 00             	movzbl (%eax),%eax
80103878:	0f b6 c0             	movzbl %al,%eax
8010387b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010387f:	c7 04 24 23 89 10 80 	movl   $0x80108923,(%esp)
80103886:	e8 16 cb ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
8010388b:	e8 73 30 00 00       	call   80106903 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103890:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103896:	05 a8 00 00 00       	add    $0xa8,%eax
8010389b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801038a2:	00 
801038a3:	89 04 24             	mov    %eax,(%esp)
801038a6:	e8 cf fe ff ff       	call   8010377a <xchg>
  scheduler();     // start running processes
801038ab:	e8 bf 12 00 00       	call   80104b6f <scheduler>

801038b0 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
801038b0:	55                   	push   %ebp
801038b1:	89 e5                	mov    %esp,%ebp
801038b3:	53                   	push   %ebx
801038b4:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
801038b7:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
801038be:	e8 aa fe ff ff       	call   8010376d <p2v>
801038c3:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
801038c6:	b8 8a 00 00 00       	mov    $0x8a,%eax
801038cb:	89 44 24 08          	mov    %eax,0x8(%esp)
801038cf:	c7 44 24 04 0c b5 10 	movl   $0x8010b50c,0x4(%esp)
801038d6:	80 
801038d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038da:	89 04 24             	mov    %eax,(%esp)
801038dd:	e8 df 1a 00 00       	call   801053c1 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
801038e2:	c7 45 f4 60 23 11 80 	movl   $0x80112360,-0xc(%ebp)
801038e9:	e9 86 00 00 00       	jmp    80103974 <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
801038ee:	e8 00 f6 ff ff       	call   80102ef3 <cpunum>
801038f3:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801038f9:	05 60 23 11 80       	add    $0x80112360,%eax
801038fe:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103901:	74 69                	je     8010396c <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80103903:	e8 33 f2 ff ff       	call   80102b3b <kalloc>
80103908:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
8010390b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010390e:	83 e8 04             	sub    $0x4,%eax
80103911:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103914:	81 c2 00 10 00 00    	add    $0x1000,%edx
8010391a:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
8010391c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010391f:	83 e8 08             	sub    $0x8,%eax
80103922:	c7 00 4f 38 10 80    	movl   $0x8010384f,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80103928:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010392b:	8d 58 f4             	lea    -0xc(%eax),%ebx
8010392e:	c7 04 24 00 a0 10 80 	movl   $0x8010a000,(%esp)
80103935:	e8 26 fe ff ff       	call   80103760 <v2p>
8010393a:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
8010393c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010393f:	89 04 24             	mov    %eax,(%esp)
80103942:	e8 19 fe ff ff       	call   80103760 <v2p>
80103947:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010394a:	0f b6 12             	movzbl (%edx),%edx
8010394d:	0f b6 d2             	movzbl %dl,%edx
80103950:	89 44 24 04          	mov    %eax,0x4(%esp)
80103954:	89 14 24             	mov    %edx,(%esp)
80103957:	e8 1d f6 ff ff       	call   80102f79 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
8010395c:	90                   	nop
8010395d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103960:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80103966:	85 c0                	test   %eax,%eax
80103968:	74 f3                	je     8010395d <startothers+0xad>
8010396a:	eb 01                	jmp    8010396d <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
8010396c:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
8010396d:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80103974:	a1 40 29 11 80       	mov    0x80112940,%eax
80103979:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
8010397f:	05 60 23 11 80       	add    $0x80112360,%eax
80103984:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103987:	0f 87 61 ff ff ff    	ja     801038ee <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
8010398d:	83 c4 24             	add    $0x24,%esp
80103990:	5b                   	pop    %ebx
80103991:	5d                   	pop    %ebp
80103992:	c3                   	ret    
	...

80103994 <p2v>:
80103994:	55                   	push   %ebp
80103995:	89 e5                	mov    %esp,%ebp
80103997:	8b 45 08             	mov    0x8(%ebp),%eax
8010399a:	05 00 00 00 80       	add    $0x80000000,%eax
8010399f:	5d                   	pop    %ebp
801039a0:	c3                   	ret    

801039a1 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801039a1:	55                   	push   %ebp
801039a2:	89 e5                	mov    %esp,%ebp
801039a4:	53                   	push   %ebx
801039a5:	83 ec 14             	sub    $0x14,%esp
801039a8:	8b 45 08             	mov    0x8(%ebp),%eax
801039ab:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801039af:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801039b3:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801039b7:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801039bb:	ec                   	in     (%dx),%al
801039bc:	89 c3                	mov    %eax,%ebx
801039be:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801039c1:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801039c5:	83 c4 14             	add    $0x14,%esp
801039c8:	5b                   	pop    %ebx
801039c9:	5d                   	pop    %ebp
801039ca:	c3                   	ret    

801039cb <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801039cb:	55                   	push   %ebp
801039cc:	89 e5                	mov    %esp,%ebp
801039ce:	83 ec 08             	sub    $0x8,%esp
801039d1:	8b 55 08             	mov    0x8(%ebp),%edx
801039d4:	8b 45 0c             	mov    0xc(%ebp),%eax
801039d7:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801039db:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801039de:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801039e2:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801039e6:	ee                   	out    %al,(%dx)
}
801039e7:	c9                   	leave  
801039e8:	c3                   	ret    

801039e9 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
801039e9:	55                   	push   %ebp
801039ea:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
801039ec:	a1 44 b6 10 80       	mov    0x8010b644,%eax
801039f1:	89 c2                	mov    %eax,%edx
801039f3:	b8 60 23 11 80       	mov    $0x80112360,%eax
801039f8:	89 d1                	mov    %edx,%ecx
801039fa:	29 c1                	sub    %eax,%ecx
801039fc:	89 c8                	mov    %ecx,%eax
801039fe:	c1 f8 02             	sar    $0x2,%eax
80103a01:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80103a07:	5d                   	pop    %ebp
80103a08:	c3                   	ret    

80103a09 <sum>:

static uchar
sum(uchar *addr, int len)
{
80103a09:	55                   	push   %ebp
80103a0a:	89 e5                	mov    %esp,%ebp
80103a0c:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
80103a0f:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80103a16:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103a1d:	eb 13                	jmp    80103a32 <sum+0x29>
    sum += addr[i];
80103a1f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103a22:	03 45 08             	add    0x8(%ebp),%eax
80103a25:	0f b6 00             	movzbl (%eax),%eax
80103a28:	0f b6 c0             	movzbl %al,%eax
80103a2b:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
80103a2e:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103a32:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103a35:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103a38:	7c e5                	jl     80103a1f <sum+0x16>
    sum += addr[i];
  return sum;
80103a3a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103a3d:	c9                   	leave  
80103a3e:	c3                   	ret    

80103a3f <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80103a3f:	55                   	push   %ebp
80103a40:	89 e5                	mov    %esp,%ebp
80103a42:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80103a45:	8b 45 08             	mov    0x8(%ebp),%eax
80103a48:	89 04 24             	mov    %eax,(%esp)
80103a4b:	e8 44 ff ff ff       	call   80103994 <p2v>
80103a50:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80103a53:	8b 45 0c             	mov    0xc(%ebp),%eax
80103a56:	03 45 f0             	add    -0x10(%ebp),%eax
80103a59:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80103a5c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a5f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103a62:	eb 3f                	jmp    80103aa3 <mpsearch1+0x64>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80103a64:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103a6b:	00 
80103a6c:	c7 44 24 04 34 89 10 	movl   $0x80108934,0x4(%esp)
80103a73:	80 
80103a74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a77:	89 04 24             	mov    %eax,(%esp)
80103a7a:	e8 e6 18 00 00       	call   80105365 <memcmp>
80103a7f:	85 c0                	test   %eax,%eax
80103a81:	75 1c                	jne    80103a9f <mpsearch1+0x60>
80103a83:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80103a8a:	00 
80103a8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a8e:	89 04 24             	mov    %eax,(%esp)
80103a91:	e8 73 ff ff ff       	call   80103a09 <sum>
80103a96:	84 c0                	test   %al,%al
80103a98:	75 05                	jne    80103a9f <mpsearch1+0x60>
      return (struct mp*)p;
80103a9a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a9d:	eb 11                	jmp    80103ab0 <mpsearch1+0x71>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80103a9f:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103aa3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103aa6:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103aa9:	72 b9                	jb     80103a64 <mpsearch1+0x25>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
80103aab:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103ab0:	c9                   	leave  
80103ab1:	c3                   	ret    

80103ab2 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103ab2:	55                   	push   %ebp
80103ab3:	89 e5                	mov    %esp,%ebp
80103ab5:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103ab8:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80103abf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ac2:	83 c0 0f             	add    $0xf,%eax
80103ac5:	0f b6 00             	movzbl (%eax),%eax
80103ac8:	0f b6 c0             	movzbl %al,%eax
80103acb:	89 c2                	mov    %eax,%edx
80103acd:	c1 e2 08             	shl    $0x8,%edx
80103ad0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ad3:	83 c0 0e             	add    $0xe,%eax
80103ad6:	0f b6 00             	movzbl (%eax),%eax
80103ad9:	0f b6 c0             	movzbl %al,%eax
80103adc:	09 d0                	or     %edx,%eax
80103ade:	c1 e0 04             	shl    $0x4,%eax
80103ae1:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103ae4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103ae8:	74 21                	je     80103b0b <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80103aea:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103af1:	00 
80103af2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103af5:	89 04 24             	mov    %eax,(%esp)
80103af8:	e8 42 ff ff ff       	call   80103a3f <mpsearch1>
80103afd:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103b00:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103b04:	74 50                	je     80103b56 <mpsearch+0xa4>
      return mp;
80103b06:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b09:	eb 5f                	jmp    80103b6a <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80103b0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b0e:	83 c0 14             	add    $0x14,%eax
80103b11:	0f b6 00             	movzbl (%eax),%eax
80103b14:	0f b6 c0             	movzbl %al,%eax
80103b17:	89 c2                	mov    %eax,%edx
80103b19:	c1 e2 08             	shl    $0x8,%edx
80103b1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b1f:	83 c0 13             	add    $0x13,%eax
80103b22:	0f b6 00             	movzbl (%eax),%eax
80103b25:	0f b6 c0             	movzbl %al,%eax
80103b28:	09 d0                	or     %edx,%eax
80103b2a:	c1 e0 0a             	shl    $0xa,%eax
80103b2d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80103b30:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b33:	2d 00 04 00 00       	sub    $0x400,%eax
80103b38:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103b3f:	00 
80103b40:	89 04 24             	mov    %eax,(%esp)
80103b43:	e8 f7 fe ff ff       	call   80103a3f <mpsearch1>
80103b48:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103b4b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103b4f:	74 05                	je     80103b56 <mpsearch+0xa4>
      return mp;
80103b51:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b54:	eb 14                	jmp    80103b6a <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80103b56:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103b5d:	00 
80103b5e:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80103b65:	e8 d5 fe ff ff       	call   80103a3f <mpsearch1>
}
80103b6a:	c9                   	leave  
80103b6b:	c3                   	ret    

80103b6c <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80103b6c:	55                   	push   %ebp
80103b6d:	89 e5                	mov    %esp,%ebp
80103b6f:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80103b72:	e8 3b ff ff ff       	call   80103ab2 <mpsearch>
80103b77:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103b7a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103b7e:	74 0a                	je     80103b8a <mpconfig+0x1e>
80103b80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b83:	8b 40 04             	mov    0x4(%eax),%eax
80103b86:	85 c0                	test   %eax,%eax
80103b88:	75 0a                	jne    80103b94 <mpconfig+0x28>
    return 0;
80103b8a:	b8 00 00 00 00       	mov    $0x0,%eax
80103b8f:	e9 83 00 00 00       	jmp    80103c17 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80103b94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b97:	8b 40 04             	mov    0x4(%eax),%eax
80103b9a:	89 04 24             	mov    %eax,(%esp)
80103b9d:	e8 f2 fd ff ff       	call   80103994 <p2v>
80103ba2:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103ba5:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103bac:	00 
80103bad:	c7 44 24 04 39 89 10 	movl   $0x80108939,0x4(%esp)
80103bb4:	80 
80103bb5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bb8:	89 04 24             	mov    %eax,(%esp)
80103bbb:	e8 a5 17 00 00       	call   80105365 <memcmp>
80103bc0:	85 c0                	test   %eax,%eax
80103bc2:	74 07                	je     80103bcb <mpconfig+0x5f>
    return 0;
80103bc4:	b8 00 00 00 00       	mov    $0x0,%eax
80103bc9:	eb 4c                	jmp    80103c17 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
80103bcb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bce:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103bd2:	3c 01                	cmp    $0x1,%al
80103bd4:	74 12                	je     80103be8 <mpconfig+0x7c>
80103bd6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bd9:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103bdd:	3c 04                	cmp    $0x4,%al
80103bdf:	74 07                	je     80103be8 <mpconfig+0x7c>
    return 0;
80103be1:	b8 00 00 00 00       	mov    $0x0,%eax
80103be6:	eb 2f                	jmp    80103c17 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80103be8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103beb:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103bef:	0f b7 c0             	movzwl %ax,%eax
80103bf2:	89 44 24 04          	mov    %eax,0x4(%esp)
80103bf6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bf9:	89 04 24             	mov    %eax,(%esp)
80103bfc:	e8 08 fe ff ff       	call   80103a09 <sum>
80103c01:	84 c0                	test   %al,%al
80103c03:	74 07                	je     80103c0c <mpconfig+0xa0>
    return 0;
80103c05:	b8 00 00 00 00       	mov    $0x0,%eax
80103c0a:	eb 0b                	jmp    80103c17 <mpconfig+0xab>
  *pmp = mp;
80103c0c:	8b 45 08             	mov    0x8(%ebp),%eax
80103c0f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103c12:	89 10                	mov    %edx,(%eax)
  return conf;
80103c14:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80103c17:	c9                   	leave  
80103c18:	c3                   	ret    

80103c19 <mpinit>:

void
mpinit(void)
{
80103c19:	55                   	push   %ebp
80103c1a:	89 e5                	mov    %esp,%ebp
80103c1c:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80103c1f:	c7 05 44 b6 10 80 60 	movl   $0x80112360,0x8010b644
80103c26:	23 11 80 
  if((conf = mpconfig(&mp)) == 0)
80103c29:	8d 45 e0             	lea    -0x20(%ebp),%eax
80103c2c:	89 04 24             	mov    %eax,(%esp)
80103c2f:	e8 38 ff ff ff       	call   80103b6c <mpconfig>
80103c34:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103c37:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103c3b:	0f 84 9c 01 00 00    	je     80103ddd <mpinit+0x1c4>
    return;
  ismp = 1;
80103c41:	c7 05 44 23 11 80 01 	movl   $0x1,0x80112344
80103c48:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80103c4b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c4e:	8b 40 24             	mov    0x24(%eax),%eax
80103c51:	a3 5c 22 11 80       	mov    %eax,0x8011225c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103c56:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c59:	83 c0 2c             	add    $0x2c,%eax
80103c5c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103c5f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c62:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103c66:	0f b7 c0             	movzwl %ax,%eax
80103c69:	03 45 f0             	add    -0x10(%ebp),%eax
80103c6c:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103c6f:	e9 f4 00 00 00       	jmp    80103d68 <mpinit+0x14f>
    switch(*p){
80103c74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c77:	0f b6 00             	movzbl (%eax),%eax
80103c7a:	0f b6 c0             	movzbl %al,%eax
80103c7d:	83 f8 04             	cmp    $0x4,%eax
80103c80:	0f 87 bf 00 00 00    	ja     80103d45 <mpinit+0x12c>
80103c86:	8b 04 85 7c 89 10 80 	mov    -0x7fef7684(,%eax,4),%eax
80103c8d:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103c8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c92:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80103c95:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103c98:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103c9c:	0f b6 d0             	movzbl %al,%edx
80103c9f:	a1 40 29 11 80       	mov    0x80112940,%eax
80103ca4:	39 c2                	cmp    %eax,%edx
80103ca6:	74 2d                	je     80103cd5 <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80103ca8:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103cab:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103caf:	0f b6 d0             	movzbl %al,%edx
80103cb2:	a1 40 29 11 80       	mov    0x80112940,%eax
80103cb7:	89 54 24 08          	mov    %edx,0x8(%esp)
80103cbb:	89 44 24 04          	mov    %eax,0x4(%esp)
80103cbf:	c7 04 24 3e 89 10 80 	movl   $0x8010893e,(%esp)
80103cc6:	e8 d6 c6 ff ff       	call   801003a1 <cprintf>
        ismp = 0;
80103ccb:	c7 05 44 23 11 80 00 	movl   $0x0,0x80112344
80103cd2:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80103cd5:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103cd8:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80103cdc:	0f b6 c0             	movzbl %al,%eax
80103cdf:	83 e0 02             	and    $0x2,%eax
80103ce2:	85 c0                	test   %eax,%eax
80103ce4:	74 15                	je     80103cfb <mpinit+0xe2>
        bcpu = &cpus[ncpu];
80103ce6:	a1 40 29 11 80       	mov    0x80112940,%eax
80103ceb:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103cf1:	05 60 23 11 80       	add    $0x80112360,%eax
80103cf6:	a3 44 b6 10 80       	mov    %eax,0x8010b644
      cpus[ncpu].id = ncpu;
80103cfb:	8b 15 40 29 11 80    	mov    0x80112940,%edx
80103d01:	a1 40 29 11 80       	mov    0x80112940,%eax
80103d06:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80103d0c:	81 c2 60 23 11 80    	add    $0x80112360,%edx
80103d12:	88 02                	mov    %al,(%edx)
      ncpu++;
80103d14:	a1 40 29 11 80       	mov    0x80112940,%eax
80103d19:	83 c0 01             	add    $0x1,%eax
80103d1c:	a3 40 29 11 80       	mov    %eax,0x80112940
      p += sizeof(struct mpproc);
80103d21:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80103d25:	eb 41                	jmp    80103d68 <mpinit+0x14f>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80103d27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d2a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80103d2d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103d30:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103d34:	a2 40 23 11 80       	mov    %al,0x80112340
      p += sizeof(struct mpioapic);
80103d39:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103d3d:	eb 29                	jmp    80103d68 <mpinit+0x14f>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103d3f:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103d43:	eb 23                	jmp    80103d68 <mpinit+0x14f>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80103d45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d48:	0f b6 00             	movzbl (%eax),%eax
80103d4b:	0f b6 c0             	movzbl %al,%eax
80103d4e:	89 44 24 04          	mov    %eax,0x4(%esp)
80103d52:	c7 04 24 5c 89 10 80 	movl   $0x8010895c,(%esp)
80103d59:	e8 43 c6 ff ff       	call   801003a1 <cprintf>
      ismp = 0;
80103d5e:	c7 05 44 23 11 80 00 	movl   $0x0,0x80112344
80103d65:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103d68:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d6b:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103d6e:	0f 82 00 ff ff ff    	jb     80103c74 <mpinit+0x5b>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80103d74:	a1 44 23 11 80       	mov    0x80112344,%eax
80103d79:	85 c0                	test   %eax,%eax
80103d7b:	75 1d                	jne    80103d9a <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80103d7d:	c7 05 40 29 11 80 01 	movl   $0x1,0x80112940
80103d84:	00 00 00 
    lapic = 0;
80103d87:	c7 05 5c 22 11 80 00 	movl   $0x0,0x8011225c
80103d8e:	00 00 00 
    ioapicid = 0;
80103d91:	c6 05 40 23 11 80 00 	movb   $0x0,0x80112340
    return;
80103d98:	eb 44                	jmp    80103dde <mpinit+0x1c5>
  }

  if(mp->imcrp){
80103d9a:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103d9d:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103da1:	84 c0                	test   %al,%al
80103da3:	74 39                	je     80103dde <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103da5:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80103dac:	00 
80103dad:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80103db4:	e8 12 fc ff ff       	call   801039cb <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103db9:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103dc0:	e8 dc fb ff ff       	call   801039a1 <inb>
80103dc5:	83 c8 01             	or     $0x1,%eax
80103dc8:	0f b6 c0             	movzbl %al,%eax
80103dcb:	89 44 24 04          	mov    %eax,0x4(%esp)
80103dcf:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103dd6:	e8 f0 fb ff ff       	call   801039cb <outb>
80103ddb:	eb 01                	jmp    80103dde <mpinit+0x1c5>
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
80103ddd:	90                   	nop
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
80103dde:	c9                   	leave  
80103ddf:	c3                   	ret    

80103de0 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103de0:	55                   	push   %ebp
80103de1:	89 e5                	mov    %esp,%ebp
80103de3:	83 ec 08             	sub    $0x8,%esp
80103de6:	8b 55 08             	mov    0x8(%ebp),%edx
80103de9:	8b 45 0c             	mov    0xc(%ebp),%eax
80103dec:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103df0:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103df3:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103df7:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103dfb:	ee                   	out    %al,(%dx)
}
80103dfc:	c9                   	leave  
80103dfd:	c3                   	ret    

80103dfe <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80103dfe:	55                   	push   %ebp
80103dff:	89 e5                	mov    %esp,%ebp
80103e01:	83 ec 0c             	sub    $0xc,%esp
80103e04:	8b 45 08             	mov    0x8(%ebp),%eax
80103e07:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80103e0b:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103e0f:	66 a3 00 b0 10 80    	mov    %ax,0x8010b000
  outb(IO_PIC1+1, mask);
80103e15:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103e19:	0f b6 c0             	movzbl %al,%eax
80103e1c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e20:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103e27:	e8 b4 ff ff ff       	call   80103de0 <outb>
  outb(IO_PIC2+1, mask >> 8);
80103e2c:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103e30:	66 c1 e8 08          	shr    $0x8,%ax
80103e34:	0f b6 c0             	movzbl %al,%eax
80103e37:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e3b:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103e42:	e8 99 ff ff ff       	call   80103de0 <outb>
}
80103e47:	c9                   	leave  
80103e48:	c3                   	ret    

80103e49 <picenable>:

void
picenable(int irq)
{
80103e49:	55                   	push   %ebp
80103e4a:	89 e5                	mov    %esp,%ebp
80103e4c:	53                   	push   %ebx
80103e4d:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80103e50:	8b 45 08             	mov    0x8(%ebp),%eax
80103e53:	ba 01 00 00 00       	mov    $0x1,%edx
80103e58:	89 d3                	mov    %edx,%ebx
80103e5a:	89 c1                	mov    %eax,%ecx
80103e5c:	d3 e3                	shl    %cl,%ebx
80103e5e:	89 d8                	mov    %ebx,%eax
80103e60:	89 c2                	mov    %eax,%edx
80103e62:	f7 d2                	not    %edx
80103e64:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103e6b:	21 d0                	and    %edx,%eax
80103e6d:	0f b7 c0             	movzwl %ax,%eax
80103e70:	89 04 24             	mov    %eax,(%esp)
80103e73:	e8 86 ff ff ff       	call   80103dfe <picsetmask>
}
80103e78:	83 c4 04             	add    $0x4,%esp
80103e7b:	5b                   	pop    %ebx
80103e7c:	5d                   	pop    %ebp
80103e7d:	c3                   	ret    

80103e7e <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80103e7e:	55                   	push   %ebp
80103e7f:	89 e5                	mov    %esp,%ebp
80103e81:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80103e84:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103e8b:	00 
80103e8c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103e93:	e8 48 ff ff ff       	call   80103de0 <outb>
  outb(IO_PIC2+1, 0xFF);
80103e98:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103e9f:	00 
80103ea0:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103ea7:	e8 34 ff ff ff       	call   80103de0 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80103eac:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103eb3:	00 
80103eb4:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103ebb:	e8 20 ff ff ff       	call   80103de0 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80103ec0:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80103ec7:	00 
80103ec8:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103ecf:	e8 0c ff ff ff       	call   80103de0 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80103ed4:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80103edb:	00 
80103edc:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103ee3:	e8 f8 fe ff ff       	call   80103de0 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80103ee8:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103eef:	00 
80103ef0:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103ef7:	e8 e4 fe ff ff       	call   80103de0 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80103efc:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103f03:	00 
80103f04:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103f0b:	e8 d0 fe ff ff       	call   80103de0 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80103f10:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80103f17:	00 
80103f18:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103f1f:	e8 bc fe ff ff       	call   80103de0 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80103f24:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80103f2b:	00 
80103f2c:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103f33:	e8 a8 fe ff ff       	call   80103de0 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80103f38:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103f3f:	00 
80103f40:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103f47:	e8 94 fe ff ff       	call   80103de0 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80103f4c:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103f53:	00 
80103f54:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103f5b:	e8 80 fe ff ff       	call   80103de0 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80103f60:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103f67:	00 
80103f68:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103f6f:	e8 6c fe ff ff       	call   80103de0 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80103f74:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103f7b:	00 
80103f7c:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103f83:	e8 58 fe ff ff       	call   80103de0 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80103f88:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103f8f:	00 
80103f90:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103f97:	e8 44 fe ff ff       	call   80103de0 <outb>

  if(irqmask != 0xFFFF)
80103f9c:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103fa3:	66 83 f8 ff          	cmp    $0xffff,%ax
80103fa7:	74 12                	je     80103fbb <picinit+0x13d>
    picsetmask(irqmask);
80103fa9:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103fb0:	0f b7 c0             	movzwl %ax,%eax
80103fb3:	89 04 24             	mov    %eax,(%esp)
80103fb6:	e8 43 fe ff ff       	call   80103dfe <picsetmask>
}
80103fbb:	c9                   	leave  
80103fbc:	c3                   	ret    
80103fbd:	00 00                	add    %al,(%eax)
	...

80103fc0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80103fc0:	55                   	push   %ebp
80103fc1:	89 e5                	mov    %esp,%ebp
80103fc3:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80103fc6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80103fcd:	8b 45 0c             	mov    0xc(%ebp),%eax
80103fd0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80103fd6:	8b 45 0c             	mov    0xc(%ebp),%eax
80103fd9:	8b 10                	mov    (%eax),%edx
80103fdb:	8b 45 08             	mov    0x8(%ebp),%eax
80103fde:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80103fe0:	e8 6f cf ff ff       	call   80100f54 <filealloc>
80103fe5:	8b 55 08             	mov    0x8(%ebp),%edx
80103fe8:	89 02                	mov    %eax,(%edx)
80103fea:	8b 45 08             	mov    0x8(%ebp),%eax
80103fed:	8b 00                	mov    (%eax),%eax
80103fef:	85 c0                	test   %eax,%eax
80103ff1:	0f 84 c8 00 00 00    	je     801040bf <pipealloc+0xff>
80103ff7:	e8 58 cf ff ff       	call   80100f54 <filealloc>
80103ffc:	8b 55 0c             	mov    0xc(%ebp),%edx
80103fff:	89 02                	mov    %eax,(%edx)
80104001:	8b 45 0c             	mov    0xc(%ebp),%eax
80104004:	8b 00                	mov    (%eax),%eax
80104006:	85 c0                	test   %eax,%eax
80104008:	0f 84 b1 00 00 00    	je     801040bf <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
8010400e:	e8 28 eb ff ff       	call   80102b3b <kalloc>
80104013:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104016:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010401a:	0f 84 9e 00 00 00    	je     801040be <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
80104020:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104023:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
8010402a:	00 00 00 
  p->writeopen = 1;
8010402d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104030:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80104037:	00 00 00 
  p->nwrite = 0;
8010403a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010403d:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80104044:	00 00 00 
  p->nread = 0;
80104047:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010404a:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80104051:	00 00 00 
  initlock(&p->lock, "pipe");
80104054:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104057:	c7 44 24 04 90 89 10 	movl   $0x80108990,0x4(%esp)
8010405e:	80 
8010405f:	89 04 24             	mov    %eax,(%esp)
80104062:	e8 17 10 00 00       	call   8010507e <initlock>
  (*f0)->type = FD_PIPE;
80104067:	8b 45 08             	mov    0x8(%ebp),%eax
8010406a:	8b 00                	mov    (%eax),%eax
8010406c:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80104072:	8b 45 08             	mov    0x8(%ebp),%eax
80104075:	8b 00                	mov    (%eax),%eax
80104077:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
8010407b:	8b 45 08             	mov    0x8(%ebp),%eax
8010407e:	8b 00                	mov    (%eax),%eax
80104080:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80104084:	8b 45 08             	mov    0x8(%ebp),%eax
80104087:	8b 00                	mov    (%eax),%eax
80104089:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010408c:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
8010408f:	8b 45 0c             	mov    0xc(%ebp),%eax
80104092:	8b 00                	mov    (%eax),%eax
80104094:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
8010409a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010409d:	8b 00                	mov    (%eax),%eax
8010409f:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
801040a3:	8b 45 0c             	mov    0xc(%ebp),%eax
801040a6:	8b 00                	mov    (%eax),%eax
801040a8:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
801040ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801040af:	8b 00                	mov    (%eax),%eax
801040b1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801040b4:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
801040b7:	b8 00 00 00 00       	mov    $0x0,%eax
801040bc:	eb 43                	jmp    80104101 <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
801040be:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
801040bf:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801040c3:	74 0b                	je     801040d0 <pipealloc+0x110>
    kfree((char*)p);
801040c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040c8:	89 04 24             	mov    %eax,(%esp)
801040cb:	e8 d2 e9 ff ff       	call   80102aa2 <kfree>
  if(*f0)
801040d0:	8b 45 08             	mov    0x8(%ebp),%eax
801040d3:	8b 00                	mov    (%eax),%eax
801040d5:	85 c0                	test   %eax,%eax
801040d7:	74 0d                	je     801040e6 <pipealloc+0x126>
    fileclose(*f0);
801040d9:	8b 45 08             	mov    0x8(%ebp),%eax
801040dc:	8b 00                	mov    (%eax),%eax
801040de:	89 04 24             	mov    %eax,(%esp)
801040e1:	e8 16 cf ff ff       	call   80100ffc <fileclose>
  if(*f1)
801040e6:	8b 45 0c             	mov    0xc(%ebp),%eax
801040e9:	8b 00                	mov    (%eax),%eax
801040eb:	85 c0                	test   %eax,%eax
801040ed:	74 0d                	je     801040fc <pipealloc+0x13c>
    fileclose(*f1);
801040ef:	8b 45 0c             	mov    0xc(%ebp),%eax
801040f2:	8b 00                	mov    (%eax),%eax
801040f4:	89 04 24             	mov    %eax,(%esp)
801040f7:	e8 00 cf ff ff       	call   80100ffc <fileclose>
  return -1;
801040fc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104101:	c9                   	leave  
80104102:	c3                   	ret    

80104103 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80104103:	55                   	push   %ebp
80104104:	89 e5                	mov    %esp,%ebp
80104106:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80104109:	8b 45 08             	mov    0x8(%ebp),%eax
8010410c:	89 04 24             	mov    %eax,(%esp)
8010410f:	e8 8b 0f 00 00       	call   8010509f <acquire>
  if(writable){
80104114:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104118:	74 1f                	je     80104139 <pipeclose+0x36>
    p->writeopen = 0;
8010411a:	8b 45 08             	mov    0x8(%ebp),%eax
8010411d:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80104124:	00 00 00 
    wakeup(&p->nread);
80104127:	8b 45 08             	mov    0x8(%ebp),%eax
8010412a:	05 34 02 00 00       	add    $0x234,%eax
8010412f:	89 04 24             	mov    %eax,(%esp)
80104132:	e8 21 0d 00 00       	call   80104e58 <wakeup>
80104137:	eb 1d                	jmp    80104156 <pipeclose+0x53>
  } else {
    p->readopen = 0;
80104139:	8b 45 08             	mov    0x8(%ebp),%eax
8010413c:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80104143:	00 00 00 
    wakeup(&p->nwrite);
80104146:	8b 45 08             	mov    0x8(%ebp),%eax
80104149:	05 38 02 00 00       	add    $0x238,%eax
8010414e:	89 04 24             	mov    %eax,(%esp)
80104151:	e8 02 0d 00 00       	call   80104e58 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80104156:	8b 45 08             	mov    0x8(%ebp),%eax
80104159:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
8010415f:	85 c0                	test   %eax,%eax
80104161:	75 25                	jne    80104188 <pipeclose+0x85>
80104163:	8b 45 08             	mov    0x8(%ebp),%eax
80104166:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
8010416c:	85 c0                	test   %eax,%eax
8010416e:	75 18                	jne    80104188 <pipeclose+0x85>
    release(&p->lock);
80104170:	8b 45 08             	mov    0x8(%ebp),%eax
80104173:	89 04 24             	mov    %eax,(%esp)
80104176:	e8 86 0f 00 00       	call   80105101 <release>
    kfree((char*)p);
8010417b:	8b 45 08             	mov    0x8(%ebp),%eax
8010417e:	89 04 24             	mov    %eax,(%esp)
80104181:	e8 1c e9 ff ff       	call   80102aa2 <kfree>
80104186:	eb 0b                	jmp    80104193 <pipeclose+0x90>
  } else
    release(&p->lock);
80104188:	8b 45 08             	mov    0x8(%ebp),%eax
8010418b:	89 04 24             	mov    %eax,(%esp)
8010418e:	e8 6e 0f 00 00       	call   80105101 <release>
}
80104193:	c9                   	leave  
80104194:	c3                   	ret    

80104195 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80104195:	55                   	push   %ebp
80104196:	89 e5                	mov    %esp,%ebp
80104198:	53                   	push   %ebx
80104199:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
8010419c:	8b 45 08             	mov    0x8(%ebp),%eax
8010419f:	89 04 24             	mov    %eax,(%esp)
801041a2:	e8 f8 0e 00 00       	call   8010509f <acquire>
  for(i = 0; i < n; i++){
801041a7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801041ae:	e9 a9 00 00 00       	jmp    8010425c <pipewrite+0xc7>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
801041b3:	8b 45 08             	mov    0x8(%ebp),%eax
801041b6:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801041bc:	85 c0                	test   %eax,%eax
801041be:	74 10                	je     801041d0 <pipewrite+0x3b>
801041c0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801041c6:	8b 80 48 02 00 00    	mov    0x248(%eax),%eax
801041cc:	85 c0                	test   %eax,%eax
801041ce:	74 15                	je     801041e5 <pipewrite+0x50>
        release(&p->lock);
801041d0:	8b 45 08             	mov    0x8(%ebp),%eax
801041d3:	89 04 24             	mov    %eax,(%esp)
801041d6:	e8 26 0f 00 00       	call   80105101 <release>
        return -1;
801041db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801041e0:	e9 9d 00 00 00       	jmp    80104282 <pipewrite+0xed>
      }
      wakeup(&p->nread);
801041e5:	8b 45 08             	mov    0x8(%ebp),%eax
801041e8:	05 34 02 00 00       	add    $0x234,%eax
801041ed:	89 04 24             	mov    %eax,(%esp)
801041f0:	e8 63 0c 00 00       	call   80104e58 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
801041f5:	8b 45 08             	mov    0x8(%ebp),%eax
801041f8:	8b 55 08             	mov    0x8(%ebp),%edx
801041fb:	81 c2 38 02 00 00    	add    $0x238,%edx
80104201:	89 44 24 04          	mov    %eax,0x4(%esp)
80104205:	89 14 24             	mov    %edx,(%esp)
80104208:	e8 3c 0b 00 00       	call   80104d49 <sleep>
8010420d:	eb 01                	jmp    80104210 <pipewrite+0x7b>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
8010420f:	90                   	nop
80104210:	8b 45 08             	mov    0x8(%ebp),%eax
80104213:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80104219:	8b 45 08             	mov    0x8(%ebp),%eax
8010421c:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104222:	05 00 02 00 00       	add    $0x200,%eax
80104227:	39 c2                	cmp    %eax,%edx
80104229:	74 88                	je     801041b3 <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
8010422b:	8b 45 08             	mov    0x8(%ebp),%eax
8010422e:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104234:	89 c3                	mov    %eax,%ebx
80104236:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
8010423c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010423f:	03 55 0c             	add    0xc(%ebp),%edx
80104242:	0f b6 0a             	movzbl (%edx),%ecx
80104245:	8b 55 08             	mov    0x8(%ebp),%edx
80104248:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
8010424c:	8d 50 01             	lea    0x1(%eax),%edx
8010424f:	8b 45 08             	mov    0x8(%ebp),%eax
80104252:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80104258:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010425c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010425f:	3b 45 10             	cmp    0x10(%ebp),%eax
80104262:	7c ab                	jl     8010420f <pipewrite+0x7a>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80104264:	8b 45 08             	mov    0x8(%ebp),%eax
80104267:	05 34 02 00 00       	add    $0x234,%eax
8010426c:	89 04 24             	mov    %eax,(%esp)
8010426f:	e8 e4 0b 00 00       	call   80104e58 <wakeup>
  release(&p->lock);
80104274:	8b 45 08             	mov    0x8(%ebp),%eax
80104277:	89 04 24             	mov    %eax,(%esp)
8010427a:	e8 82 0e 00 00       	call   80105101 <release>
  return n;
8010427f:	8b 45 10             	mov    0x10(%ebp),%eax
}
80104282:	83 c4 24             	add    $0x24,%esp
80104285:	5b                   	pop    %ebx
80104286:	5d                   	pop    %ebp
80104287:	c3                   	ret    

80104288 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80104288:	55                   	push   %ebp
80104289:	89 e5                	mov    %esp,%ebp
8010428b:	53                   	push   %ebx
8010428c:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
8010428f:	8b 45 08             	mov    0x8(%ebp),%eax
80104292:	89 04 24             	mov    %eax,(%esp)
80104295:	e8 05 0e 00 00       	call   8010509f <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010429a:	eb 3d                	jmp    801042d9 <piperead+0x51>
    if(proc->killed){
8010429c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801042a2:	8b 80 48 02 00 00    	mov    0x248(%eax),%eax
801042a8:	85 c0                	test   %eax,%eax
801042aa:	74 15                	je     801042c1 <piperead+0x39>
      release(&p->lock);
801042ac:	8b 45 08             	mov    0x8(%ebp),%eax
801042af:	89 04 24             	mov    %eax,(%esp)
801042b2:	e8 4a 0e 00 00       	call   80105101 <release>
      return -1;
801042b7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801042bc:	e9 b6 00 00 00       	jmp    80104377 <piperead+0xef>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801042c1:	8b 45 08             	mov    0x8(%ebp),%eax
801042c4:	8b 55 08             	mov    0x8(%ebp),%edx
801042c7:	81 c2 34 02 00 00    	add    $0x234,%edx
801042cd:	89 44 24 04          	mov    %eax,0x4(%esp)
801042d1:	89 14 24             	mov    %edx,(%esp)
801042d4:	e8 70 0a 00 00       	call   80104d49 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801042d9:	8b 45 08             	mov    0x8(%ebp),%eax
801042dc:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801042e2:	8b 45 08             	mov    0x8(%ebp),%eax
801042e5:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801042eb:	39 c2                	cmp    %eax,%edx
801042ed:	75 0d                	jne    801042fc <piperead+0x74>
801042ef:	8b 45 08             	mov    0x8(%ebp),%eax
801042f2:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801042f8:	85 c0                	test   %eax,%eax
801042fa:	75 a0                	jne    8010429c <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801042fc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104303:	eb 49                	jmp    8010434e <piperead+0xc6>
    if(p->nread == p->nwrite)
80104305:	8b 45 08             	mov    0x8(%ebp),%eax
80104308:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
8010430e:	8b 45 08             	mov    0x8(%ebp),%eax
80104311:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104317:	39 c2                	cmp    %eax,%edx
80104319:	74 3d                	je     80104358 <piperead+0xd0>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
8010431b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010431e:	89 c2                	mov    %eax,%edx
80104320:	03 55 0c             	add    0xc(%ebp),%edx
80104323:	8b 45 08             	mov    0x8(%ebp),%eax
80104326:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
8010432c:	89 c3                	mov    %eax,%ebx
8010432e:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80104334:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104337:	0f b6 4c 19 34       	movzbl 0x34(%ecx,%ebx,1),%ecx
8010433c:	88 0a                	mov    %cl,(%edx)
8010433e:	8d 50 01             	lea    0x1(%eax),%edx
80104341:	8b 45 08             	mov    0x8(%ebp),%eax
80104344:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010434a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010434e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104351:	3b 45 10             	cmp    0x10(%ebp),%eax
80104354:	7c af                	jl     80104305 <piperead+0x7d>
80104356:	eb 01                	jmp    80104359 <piperead+0xd1>
    if(p->nread == p->nwrite)
      break;
80104358:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80104359:	8b 45 08             	mov    0x8(%ebp),%eax
8010435c:	05 38 02 00 00       	add    $0x238,%eax
80104361:	89 04 24             	mov    %eax,(%esp)
80104364:	e8 ef 0a 00 00       	call   80104e58 <wakeup>
  release(&p->lock);
80104369:	8b 45 08             	mov    0x8(%ebp),%eax
8010436c:	89 04 24             	mov    %eax,(%esp)
8010436f:	e8 8d 0d 00 00       	call   80105101 <release>
  return i;
80104374:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104377:	83 c4 24             	add    $0x24,%esp
8010437a:	5b                   	pop    %ebx
8010437b:	5d                   	pop    %ebp
8010437c:	c3                   	ret    
8010437d:	00 00                	add    %al,(%eax)
	...

80104380 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104380:	55                   	push   %ebp
80104381:	89 e5                	mov    %esp,%ebp
80104383:	53                   	push   %ebx
80104384:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104387:	9c                   	pushf  
80104388:	5b                   	pop    %ebx
80104389:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
8010438c:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010438f:	83 c4 10             	add    $0x10,%esp
80104392:	5b                   	pop    %ebx
80104393:	5d                   	pop    %ebp
80104394:	c3                   	ret    

80104395 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80104395:	55                   	push   %ebp
80104396:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104398:	fb                   	sti    
}
80104399:	5d                   	pop    %ebp
8010439a:	c3                   	ret    

8010439b <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
8010439b:	55                   	push   %ebp
8010439c:	89 e5                	mov    %esp,%ebp
8010439e:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
801043a1:	c7 44 24 04 95 89 10 	movl   $0x80108995,0x4(%esp)
801043a8:	80 
801043a9:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
801043b0:	e8 c9 0c 00 00       	call   8010507e <initlock>
}
801043b5:	c9                   	leave  
801043b6:	c3                   	ret    

801043b7 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
801043b7:	55                   	push   %ebp
801043b8:	89 e5                	mov    %esp,%ebp
801043ba:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  struct thread *t;
  char *sp;

  acquire(&ptable.lock);
801043bd:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
801043c4:	e8 d6 0c 00 00       	call   8010509f <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801043c9:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
801043d0:	eb 11                	jmp    801043e3 <allocproc+0x2c>
    if(p->state == UNUSED)
801043d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043d5:	8b 40 08             	mov    0x8(%eax),%eax
801043d8:	85 c0                	test   %eax,%eax
801043da:	74 26                	je     80104402 <allocproc+0x4b>
  struct proc *p;
  struct thread *t;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801043dc:	81 45 f4 a4 02 00 00 	addl   $0x2a4,-0xc(%ebp)
801043e3:	81 7d f4 94 d2 11 80 	cmpl   $0x8011d294,-0xc(%ebp)
801043ea:	72 e6                	jb     801043d2 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
801043ec:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
801043f3:	e8 09 0d 00 00       	call   80105101 <release>
  return 0;
801043f8:	b8 00 00 00 00       	mov    $0x0,%eax
801043fd:	e9 ed 00 00 00       	jmp    801044ef <allocproc+0x138>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
80104402:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
80104403:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104406:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  p->pid = nextpid++;
8010440d:	a1 04 b0 10 80       	mov    0x8010b004,%eax
80104412:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104415:	89 42 0c             	mov    %eax,0xc(%edx)
80104418:	83 c0 01             	add    $0x1,%eax
8010441b:	a3 04 b0 10 80       	mov    %eax,0x8010b004
  release(&ptable.lock);
80104420:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104427:	e8 d5 0c 00 00       	call   80105101 <release>

  t = p->threads; // the first thread struct
8010442c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010442f:	83 c0 48             	add    $0x48,%eax
80104432:	89 45 f0             	mov    %eax,-0x10(%ebp)
  t->tid = nexttid++;
80104435:	a1 08 b0 10 80       	mov    0x8010b008,%eax
8010443a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010443d:	89 02                	mov    %eax,(%edx)
8010443f:	83 c0 01             	add    $0x1,%eax
80104442:	a3 08 b0 10 80       	mov    %eax,0x8010b008
  t->parent = p;
80104447:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010444a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010444d:	89 50 04             	mov    %edx,0x4(%eax)
  t->chan = 0;
80104450:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104453:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  t->killed = 0;
8010445a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010445d:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  
  // Allocate kernel stack.
  if((t->kstack = kalloc()) == 0){
80104464:	e8 d2 e6 ff ff       	call   80102b3b <kalloc>
80104469:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010446c:	89 42 08             	mov    %eax,0x8(%edx)
8010446f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104472:	8b 40 08             	mov    0x8(%eax),%eax
80104475:	85 c0                	test   %eax,%eax
80104477:	75 11                	jne    8010448a <allocproc+0xd3>
    p->state = UNUSED;
80104479:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010447c:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    return 0;
80104483:	b8 00 00 00 00       	mov    $0x0,%eax
80104488:	eb 65                	jmp    801044ef <allocproc+0x138>
  }
  sp = t->kstack + KSTACKSIZE;
8010448a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010448d:	8b 40 08             	mov    0x8(%eax),%eax
80104490:	05 00 10 00 00       	add    $0x1000,%eax
80104495:	89 45 ec             	mov    %eax,-0x14(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *t->tf;
80104498:	83 6d ec 4c          	subl   $0x4c,-0x14(%ebp)
  t->tf = (struct trapframe*)sp;
8010449c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010449f:	8b 55 ec             	mov    -0x14(%ebp),%edx
801044a2:	89 50 10             	mov    %edx,0x10(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
801044a5:	83 6d ec 04          	subl   $0x4,-0x14(%ebp)
  *(uint*)sp = (uint)trapret;
801044a9:	ba 44 67 10 80       	mov    $0x80106744,%edx
801044ae:	8b 45 ec             	mov    -0x14(%ebp),%eax
801044b1:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *t->context;
801044b3:	83 6d ec 14          	subl   $0x14,-0x14(%ebp)
  t->context = (struct context*)sp;
801044b7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801044ba:	8b 55 ec             	mov    -0x14(%ebp),%edx
801044bd:	89 50 14             	mov    %edx,0x14(%eax)
  memset(t->context, 0, sizeof *t->context);
801044c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801044c3:	8b 40 14             	mov    0x14(%eax),%eax
801044c6:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801044cd:	00 
801044ce:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801044d5:	00 
801044d6:	89 04 24             	mov    %eax,(%esp)
801044d9:	e8 10 0e 00 00       	call   801052ee <memset>
  t->context->eip = (uint)forkret;
801044de:	8b 45 f0             	mov    -0x10(%ebp),%eax
801044e1:	8b 40 14             	mov    0x14(%eax),%eax
801044e4:	ba 1d 4d 10 80       	mov    $0x80104d1d,%edx
801044e9:	89 50 10             	mov    %edx,0x10(%eax)
  
  return p;
801044ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801044ef:	c9                   	leave  
801044f0:	c3                   	ret    

801044f1 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
801044f1:	55                   	push   %ebp
801044f2:	89 e5                	mov    %esp,%ebp
801044f4:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
801044f7:	e8 bb fe ff ff       	call   801043b7 <allocproc>
801044fc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
801044ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104502:	a3 48 b6 10 80       	mov    %eax,0x8010b648
  if((p->pgdir = setupkvm()) == 0)
80104507:	e8 49 39 00 00       	call   80107e55 <setupkvm>
8010450c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010450f:	89 42 04             	mov    %eax,0x4(%edx)
80104512:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104515:	8b 40 04             	mov    0x4(%eax),%eax
80104518:	85 c0                	test   %eax,%eax
8010451a:	75 0c                	jne    80104528 <userinit+0x37>
    panic("userinit: out of memory?");
8010451c:	c7 04 24 9c 89 10 80 	movl   $0x8010899c,(%esp)
80104523:	e8 15 c0 ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104528:	ba 2c 00 00 00       	mov    $0x2c,%edx
8010452d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104530:	8b 40 04             	mov    0x4(%eax),%eax
80104533:	89 54 24 08          	mov    %edx,0x8(%esp)
80104537:	c7 44 24 04 e0 b4 10 	movl   $0x8010b4e0,0x4(%esp)
8010453e:	80 
8010453f:	89 04 24             	mov    %eax,(%esp)
80104542:	e8 66 3b 00 00       	call   801080ad <inituvm>
  p->sz = PGSIZE;
80104547:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010454a:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->threads->tf, 0, sizeof(*p->threads->tf));
80104550:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104553:	8b 40 58             	mov    0x58(%eax),%eax
80104556:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
8010455d:	00 
8010455e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104565:	00 
80104566:	89 04 24             	mov    %eax,(%esp)
80104569:	e8 80 0d 00 00       	call   801052ee <memset>
  p->threads->tf->cs = (SEG_UCODE << 3) | DPL_USER;
8010456e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104571:	8b 40 58             	mov    0x58(%eax),%eax
80104574:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->threads->tf->ds = (SEG_UDATA << 3) | DPL_USER;
8010457a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010457d:	8b 40 58             	mov    0x58(%eax),%eax
80104580:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->threads->tf->es = p->threads->tf->ds;
80104586:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104589:	8b 40 58             	mov    0x58(%eax),%eax
8010458c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010458f:	8b 52 58             	mov    0x58(%edx),%edx
80104592:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104596:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->threads->tf->ss = p->threads->tf->ds;
8010459a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010459d:	8b 40 58             	mov    0x58(%eax),%eax
801045a0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801045a3:	8b 52 58             	mov    0x58(%edx),%edx
801045a6:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801045aa:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->threads->tf->eflags = FL_IF;
801045ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045b1:	8b 40 58             	mov    0x58(%eax),%eax
801045b4:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->threads->tf->esp = PGSIZE;
801045bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045be:	8b 40 58             	mov    0x58(%eax),%eax
801045c1:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->threads->tf->eip = 0;  // beginning of initcode.S
801045c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045cb:	8b 40 58             	mov    0x58(%eax),%eax
801045ce:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
801045d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045d8:	05 90 02 00 00       	add    $0x290,%eax
801045dd:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801045e4:	00 
801045e5:	c7 44 24 04 b5 89 10 	movl   $0x801089b5,0x4(%esp)
801045ec:	80 
801045ed:	89 04 24             	mov    %eax,(%esp)
801045f0:	e8 29 0f 00 00       	call   8010551e <safestrcpy>
  p->cwd = namei("/");
801045f5:	c7 04 24 be 89 10 80 	movl   $0x801089be,(%esp)
801045fc:	e8 44 de ff ff       	call   80102445 <namei>
80104601:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104604:	89 82 8c 02 00 00    	mov    %eax,0x28c(%edx)
  
  initlock(&p->lock, "init");
8010460a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010460d:	83 c0 14             	add    $0x14,%eax
80104610:	c7 44 24 04 c0 89 10 	movl   $0x801089c0,0x4(%esp)
80104617:	80 
80104618:	89 04 24             	mov    %eax,(%esp)
8010461b:	e8 5e 0a 00 00       	call   8010507e <initlock>

  p->state = RUNNABLE;
80104620:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104623:	c7 40 08 03 00 00 00 	movl   $0x3,0x8(%eax)
  p->threads->state = T_RUNNABLE;
8010462a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010462d:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
}
80104634:	c9                   	leave  
80104635:	c3                   	ret    

80104636 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104636:	55                   	push   %ebp
80104637:	89 e5                	mov    %esp,%ebp
80104639:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  acquire(&proc->lock);
8010463c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104642:	83 c0 14             	add    $0x14,%eax
80104645:	89 04 24             	mov    %eax,(%esp)
80104648:	e8 52 0a 00 00       	call   8010509f <acquire>

  sz = proc->sz;
8010464d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104653:	8b 00                	mov    (%eax),%eax
80104655:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104658:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010465c:	7e 34                	jle    80104692 <growproc+0x5c>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
8010465e:	8b 45 08             	mov    0x8(%ebp),%eax
80104661:	89 c2                	mov    %eax,%edx
80104663:	03 55 f4             	add    -0xc(%ebp),%edx
80104666:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010466c:	8b 40 04             	mov    0x4(%eax),%eax
8010466f:	89 54 24 08          	mov    %edx,0x8(%esp)
80104673:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104676:	89 54 24 04          	mov    %edx,0x4(%esp)
8010467a:	89 04 24             	mov    %eax,(%esp)
8010467d:	e8 a5 3b 00 00       	call   80108227 <allocuvm>
80104682:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104685:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104689:	75 41                	jne    801046cc <growproc+0x96>
      return -1;
8010468b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104690:	eb 69                	jmp    801046fb <growproc+0xc5>
  } else if(n < 0){
80104692:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104696:	79 34                	jns    801046cc <growproc+0x96>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
80104698:	8b 45 08             	mov    0x8(%ebp),%eax
8010469b:	89 c2                	mov    %eax,%edx
8010469d:	03 55 f4             	add    -0xc(%ebp),%edx
801046a0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046a6:	8b 40 04             	mov    0x4(%eax),%eax
801046a9:	89 54 24 08          	mov    %edx,0x8(%esp)
801046ad:	8b 55 f4             	mov    -0xc(%ebp),%edx
801046b0:	89 54 24 04          	mov    %edx,0x4(%esp)
801046b4:	89 04 24             	mov    %eax,(%esp)
801046b7:	e8 45 3c 00 00       	call   80108301 <deallocuvm>
801046bc:	89 45 f4             	mov    %eax,-0xc(%ebp)
801046bf:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801046c3:	75 07                	jne    801046cc <growproc+0x96>
      return -1;
801046c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046ca:	eb 2f                	jmp    801046fb <growproc+0xc5>
  }
  proc->sz = sz;
801046cc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046d2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801046d5:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
801046d7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046dd:	89 04 24             	mov    %eax,(%esp)
801046e0:	e8 61 38 00 00       	call   80107f46 <switchuvm>
  
  release(&proc->lock);
801046e5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046eb:	83 c0 14             	add    $0x14,%eax
801046ee:	89 04 24             	mov    %eax,(%esp)
801046f1:	e8 0b 0a 00 00       	call   80105101 <release>
  return 0;
801046f6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801046fb:	c9                   	leave  
801046fc:	c3                   	ret    

801046fd <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
801046fd:	55                   	push   %ebp
801046fe:	89 e5                	mov    %esp,%ebp
80104700:	57                   	push   %edi
80104701:	56                   	push   %esi
80104702:	53                   	push   %ebx
80104703:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104706:	e8 ac fc ff ff       	call   801043b7 <allocproc>
8010470b:	89 45 e0             	mov    %eax,-0x20(%ebp)
8010470e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104712:	75 0a                	jne    8010471e <fork+0x21>
    return -1;
80104714:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104719:	e9 8b 01 00 00       	jmp    801048a9 <fork+0x1ac>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
8010471e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104724:	8b 10                	mov    (%eax),%edx
80104726:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010472c:	8b 40 04             	mov    0x4(%eax),%eax
8010472f:	89 54 24 04          	mov    %edx,0x4(%esp)
80104733:	89 04 24             	mov    %eax,(%esp)
80104736:	e8 56 3d 00 00       	call   80108491 <copyuvm>
8010473b:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010473e:	89 42 04             	mov    %eax,0x4(%edx)
80104741:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104744:	8b 40 04             	mov    0x4(%eax),%eax
80104747:	85 c0                	test   %eax,%eax
80104749:	75 2c                	jne    80104777 <fork+0x7a>
    kfree(np->threads->kstack);	// the alloced process only has one thread
8010474b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010474e:	8b 40 50             	mov    0x50(%eax),%eax
80104751:	89 04 24             	mov    %eax,(%esp)
80104754:	e8 49 e3 ff ff       	call   80102aa2 <kfree>
    np->threads->kstack = 0;
80104759:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010475c:	c7 40 50 00 00 00 00 	movl   $0x0,0x50(%eax)
    np->state = UNUSED;
80104763:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104766:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    return -1;
8010476d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104772:	e9 32 01 00 00       	jmp    801048a9 <fork+0x1ac>
  }
  np->sz = proc->sz;
80104777:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010477d:	8b 10                	mov    (%eax),%edx
8010477f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104782:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80104784:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010478b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010478e:	89 50 10             	mov    %edx,0x10(%eax)
  *np->threads->tf = *proc->threads->tf;
80104791:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104794:	8b 50 58             	mov    0x58(%eax),%edx
80104797:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010479d:	8b 40 58             	mov    0x58(%eax),%eax
801047a0:	89 c3                	mov    %eax,%ebx
801047a2:	b8 13 00 00 00       	mov    $0x13,%eax
801047a7:	89 d7                	mov    %edx,%edi
801047a9:	89 de                	mov    %ebx,%esi
801047ab:	89 c1                	mov    %eax,%ecx
801047ad:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->threads->tf->eax = 0;
801047af:	8b 45 e0             	mov    -0x20(%ebp),%eax
801047b2:	8b 40 58             	mov    0x58(%eax),%eax
801047b5:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
801047bc:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801047c3:	eb 46                	jmp    8010480b <fork+0x10e>
    if(proc->ofile[i])
801047c5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047cb:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801047ce:	81 c2 90 00 00 00    	add    $0x90,%edx
801047d4:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801047d8:	85 c0                	test   %eax,%eax
801047da:	74 2b                	je     80104807 <fork+0x10a>
      np->ofile[i] = filedup(proc->ofile[i]);
801047dc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047e2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801047e5:	81 c2 90 00 00 00    	add    $0x90,%edx
801047eb:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801047ef:	89 04 24             	mov    %eax,(%esp)
801047f2:	e8 bd c7 ff ff       	call   80100fb4 <filedup>
801047f7:	8b 55 e0             	mov    -0x20(%ebp),%edx
801047fa:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801047fd:	81 c1 90 00 00 00    	add    $0x90,%ecx
80104803:	89 44 8a 0c          	mov    %eax,0xc(%edx,%ecx,4)
  *np->threads->tf = *proc->threads->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->threads->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80104807:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
8010480b:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
8010480f:	7e b4                	jle    801047c5 <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
80104811:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104817:	8b 80 8c 02 00 00    	mov    0x28c(%eax),%eax
8010481d:	89 04 24             	mov    %eax,(%esp)
80104820:	e8 49 d0 ff ff       	call   8010186e <idup>
80104825:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104828:	89 82 8c 02 00 00    	mov    %eax,0x28c(%edx)

  safestrcpy(np->name, proc->name, sizeof(proc->name));
8010482e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104834:	8d 90 90 02 00 00    	lea    0x290(%eax),%edx
8010483a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010483d:	05 90 02 00 00       	add    $0x290,%eax
80104842:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104849:	00 
8010484a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010484e:	89 04 24             	mov    %eax,(%esp)
80104851:	e8 c8 0c 00 00       	call   8010551e <safestrcpy>
 
  pid = np->pid;
80104856:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104859:	8b 40 0c             	mov    0xc(%eax),%eax
8010485c:	89 45 dc             	mov    %eax,-0x24(%ebp)
  initlock(&np->lock, np->name);
8010485f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104862:	8d 90 90 02 00 00    	lea    0x290(%eax),%edx
80104868:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010486b:	83 c0 14             	add    $0x14,%eax
8010486e:	89 54 24 04          	mov    %edx,0x4(%esp)
80104872:	89 04 24             	mov    %eax,(%esp)
80104875:	e8 04 08 00 00       	call   8010507e <initlock>

  // lock to force the compiler to emit the np->state write last.
  acquire(&ptable.lock);
8010487a:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104881:	e8 19 08 00 00       	call   8010509f <acquire>
  np->state = RUNNABLE;
80104886:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104889:	c7 40 08 03 00 00 00 	movl   $0x3,0x8(%eax)
  np->threads->state = T_RUNNABLE;
80104890:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104893:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
  release(&ptable.lock);
8010489a:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
801048a1:	e8 5b 08 00 00       	call   80105101 <release>
  
  return pid;
801048a6:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
801048a9:	83 c4 2c             	add    $0x2c,%esp
801048ac:	5b                   	pop    %ebx
801048ad:	5e                   	pop    %esi
801048ae:	5f                   	pop    %edi
801048af:	5d                   	pop    %ebp
801048b0:	c3                   	ret    

801048b1 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
801048b1:	55                   	push   %ebp
801048b2:	89 e5                	mov    %esp,%ebp
801048b4:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
801048b7:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801048be:	a1 48 b6 10 80       	mov    0x8010b648,%eax
801048c3:	39 c2                	cmp    %eax,%edx
801048c5:	75 0c                	jne    801048d3 <exit+0x22>
    panic("init exiting");
801048c7:	c7 04 24 c5 89 10 80 	movl   $0x801089c5,(%esp)
801048ce:	e8 6a bc ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
801048d3:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801048da:	eb 4d                	jmp    80104929 <exit+0x78>
    if(proc->ofile[fd]){
801048dc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048e2:	8b 55 f0             	mov    -0x10(%ebp),%edx
801048e5:	81 c2 90 00 00 00    	add    $0x90,%edx
801048eb:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801048ef:	85 c0                	test   %eax,%eax
801048f1:	74 32                	je     80104925 <exit+0x74>
      fileclose(proc->ofile[fd]);
801048f3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048f9:	8b 55 f0             	mov    -0x10(%ebp),%edx
801048fc:	81 c2 90 00 00 00    	add    $0x90,%edx
80104902:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80104906:	89 04 24             	mov    %eax,(%esp)
80104909:	e8 ee c6 ff ff       	call   80100ffc <fileclose>
      proc->ofile[fd] = 0;
8010490e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104914:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104917:	81 c2 90 00 00 00    	add    $0x90,%edx
8010491d:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80104924:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104925:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104929:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
8010492d:	7e ad                	jle    801048dc <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  begin_op();
8010492f:	e8 5d eb ff ff       	call   80103491 <begin_op>
  iput(proc->cwd);
80104934:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010493a:	8b 80 8c 02 00 00    	mov    0x28c(%eax),%eax
80104940:	89 04 24             	mov    %eax,(%esp)
80104943:	e8 0b d1 ff ff       	call   80101a53 <iput>
  end_op();
80104948:	e8 c5 eb ff ff       	call   80103512 <end_op>
  proc->cwd = 0;
8010494d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104953:	c7 80 8c 02 00 00 00 	movl   $0x0,0x28c(%eax)
8010495a:	00 00 00 

  acquire(&ptable.lock);
8010495d:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104964:	e8 36 07 00 00       	call   8010509f <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
80104969:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010496f:	8b 40 10             	mov    0x10(%eax),%eax
80104972:	89 04 24             	mov    %eax,(%esp)
80104975:	e8 77 04 00 00       	call   80104df1 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010497a:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
80104981:	eb 3b                	jmp    801049be <exit+0x10d>
    if(p->parent == proc){
80104983:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104986:	8b 50 10             	mov    0x10(%eax),%edx
80104989:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010498f:	39 c2                	cmp    %eax,%edx
80104991:	75 24                	jne    801049b7 <exit+0x106>
      p->parent = initproc;
80104993:	8b 15 48 b6 10 80    	mov    0x8010b648,%edx
80104999:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010499c:	89 50 10             	mov    %edx,0x10(%eax)
      if(p->state == ZOMBIE)
8010499f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049a2:	8b 40 08             	mov    0x8(%eax),%eax
801049a5:	83 f8 05             	cmp    $0x5,%eax
801049a8:	75 0d                	jne    801049b7 <exit+0x106>
        wakeup1(initproc);
801049aa:	a1 48 b6 10 80       	mov    0x8010b648,%eax
801049af:	89 04 24             	mov    %eax,(%esp)
801049b2:	e8 3a 04 00 00       	call   80104df1 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801049b7:	81 45 f4 a4 02 00 00 	addl   $0x2a4,-0xc(%ebp)
801049be:	81 7d f4 94 d2 11 80 	cmpl   $0x8011d294,-0xc(%ebp)
801049c5:	72 bc                	jb     80104983 <exit+0xd2>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
801049c7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049cd:	c7 40 08 05 00 00 00 	movl   $0x5,0x8(%eax)
  sched();
801049d4:	e8 60 02 00 00       	call   80104c39 <sched>
  panic("zombie exit");
801049d9:	c7 04 24 d2 89 10 80 	movl   $0x801089d2,(%esp)
801049e0:	e8 58 bb ff ff       	call   8010053d <panic>

801049e5 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
801049e5:	55                   	push   %ebp
801049e6:	89 e5                	mov    %esp,%ebp
801049e8:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  struct thread *t;
  int havekids, pid;

  acquire(&ptable.lock);
801049eb:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
801049f2:	e8 a8 06 00 00       	call   8010509f <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
801049f7:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801049fe:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
80104a05:	e9 12 01 00 00       	jmp    80104b1c <wait+0x137>
      if(p->parent != proc)
80104a0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a0d:	8b 50 10             	mov    0x10(%eax),%edx
80104a10:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a16:	39 c2                	cmp    %eax,%edx
80104a18:	0f 85 f6 00 00 00    	jne    80104b14 <wait+0x12f>
        continue;
      havekids = 1;
80104a1e:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
      if(p->state == ZOMBIE){
80104a25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a28:	8b 40 08             	mov    0x8(%eax),%eax
80104a2b:	83 f8 05             	cmp    $0x5,%eax
80104a2e:	0f 85 e1 00 00 00    	jne    80104b15 <wait+0x130>
        // Found one.
        pid = p->pid;
80104a34:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a37:	8b 40 0c             	mov    0xc(%eax),%eax
80104a3a:	89 45 e8             	mov    %eax,-0x18(%ebp)
		for(t = p->threads; t < &p->threads[NTHREAD]; t++){
80104a3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a40:	83 c0 48             	add    $0x48,%eax
80104a43:	89 45 f0             	mov    %eax,-0x10(%ebp)
80104a46:	eb 6b                	jmp    80104ab3 <wait+0xce>
			if (t->state != T_FREE){
80104a48:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a4b:	8b 40 0c             	mov    0xc(%eax),%eax
80104a4e:	85 c0                	test   %eax,%eax
80104a50:	74 5d                	je     80104aaf <wait+0xca>
				kfree(p->threads->kstack);
80104a52:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a55:	8b 40 50             	mov    0x50(%eax),%eax
80104a58:	89 04 24             	mov    %eax,(%esp)
80104a5b:	e8 42 e0 ff ff       	call   80102aa2 <kfree>
				t->kstack = 0;
80104a60:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a63:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
				t->tid = 0;
80104a6a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a6d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
				t->parent = 0;
80104a73:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a76:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
				t->tf = 0;
80104a7d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a80:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
				t->context = 0;
80104a87:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a8a:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
				t->chan = 0;
80104a91:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a94:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
				t->killed = 0;
80104a9b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a9e:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
				t->state = T_FREE;
80104aa5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104aa8:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        continue;
      havekids = 1;
      if(p->state == ZOMBIE){
        // Found one.
        pid = p->pid;
		for(t = p->threads; t < &p->threads[NTHREAD]; t++){
80104aaf:	83 45 f0 20          	addl   $0x20,-0x10(%ebp)
80104ab3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ab6:	05 48 02 00 00       	add    $0x248,%eax
80104abb:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80104abe:	77 88                	ja     80104a48 <wait+0x63>
				t->chan = 0;
				t->killed = 0;
				t->state = T_FREE;
			}
		}
        freevm(p->pgdir);
80104ac0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ac3:	8b 40 04             	mov    0x4(%eax),%eax
80104ac6:	89 04 24             	mov    %eax,(%esp)
80104ac9:	e8 ef 38 00 00       	call   801083bd <freevm>
        p->state = UNUSED;
80104ace:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ad1:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        p->pid = 0;
80104ad8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104adb:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->parent = 0;
80104ae2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ae5:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->name[0] = 0;
80104aec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aef:	c6 80 90 02 00 00 00 	movb   $0x0,0x290(%eax)
        p->killed = 0;
80104af6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104af9:	c7 80 48 02 00 00 00 	movl   $0x0,0x248(%eax)
80104b00:	00 00 00 
        release(&ptable.lock);
80104b03:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104b0a:	e8 f2 05 00 00       	call   80105101 <release>
        return pid;
80104b0f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104b12:	eb 59                	jmp    80104b6d <wait+0x188>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
80104b14:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b15:	81 45 f4 a4 02 00 00 	addl   $0x2a4,-0xc(%ebp)
80104b1c:	81 7d f4 94 d2 11 80 	cmpl   $0x8011d294,-0xc(%ebp)
80104b23:	0f 82 e1 fe ff ff    	jb     80104a0a <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80104b29:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104b2d:	74 10                	je     80104b3f <wait+0x15a>
80104b2f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b35:	8b 80 48 02 00 00    	mov    0x248(%eax),%eax
80104b3b:	85 c0                	test   %eax,%eax
80104b3d:	74 13                	je     80104b52 <wait+0x16d>
      release(&ptable.lock);
80104b3f:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104b46:	e8 b6 05 00 00       	call   80105101 <release>
      return -1;
80104b4b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b50:	eb 1b                	jmp    80104b6d <wait+0x188>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80104b52:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b58:	c7 44 24 04 60 29 11 	movl   $0x80112960,0x4(%esp)
80104b5f:	80 
80104b60:	89 04 24             	mov    %eax,(%esp)
80104b63:	e8 e1 01 00 00       	call   80104d49 <sleep>
  }
80104b68:	e9 8a fe ff ff       	jmp    801049f7 <wait+0x12>
}
80104b6d:	c9                   	leave  
80104b6e:	c3                   	ret    

80104b6f <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80104b6f:	55                   	push   %ebp
80104b70:	89 e5                	mov    %esp,%ebp
80104b72:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  struct thread *t;

  for(;;){
    // Enable interrupts on this processor.
    sti();
80104b75:	e8 1b f8 ff ff       	call   80104395 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80104b7a:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104b81:	e8 19 05 00 00       	call   8010509f <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b86:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
80104b8d:	e9 89 00 00 00       	jmp    80104c1b <scheduler+0xac>
		if (p->state != RUNNABLE){
80104b92:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b95:	8b 40 08             	mov    0x8(%eax),%eax
80104b98:	83 f8 03             	cmp    $0x3,%eax
80104b9b:	75 76                	jne    80104c13 <scheduler+0xa4>
			continue;
		}
		for(t = p->threads; t < &p->threads[NTHREAD]; t++){
80104b9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ba0:	83 c0 48             	add    $0x48,%eax
80104ba3:	89 45 f0             	mov    %eax,-0x10(%ebp)
80104ba6:	eb 5c                	jmp    80104c04 <scheduler+0x95>
			if (t->state != T_RUNNABLE){
80104ba8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bab:	8b 40 0c             	mov    0xc(%eax),%eax
80104bae:	83 f8 02             	cmp    $0x2,%eax
80104bb1:	75 4c                	jne    80104bff <scheduler+0x90>
			}
			
			// Switch to chosen process.  It is the process's job
			// to release ptable.lock and then reacquire it
			// before jumping back to us.
			proc = p;
80104bb3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bb6:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
			switchuvm(p);
80104bbc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bbf:	89 04 24             	mov    %eax,(%esp)
80104bc2:	e8 7f 33 00 00       	call   80107f46 <switchuvm>
			t->state = T_RUNNING;
80104bc7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bca:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
			swtch(&cpu->scheduler, t->context);
80104bd1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bd4:	8b 40 14             	mov    0x14(%eax),%eax
80104bd7:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104bde:	83 c2 04             	add    $0x4,%edx
80104be1:	89 44 24 04          	mov    %eax,0x4(%esp)
80104be5:	89 14 24             	mov    %edx,(%esp)
80104be8:	e8 a7 09 00 00       	call   80105594 <swtch>
			switchkvm();
80104bed:	e8 37 33 00 00       	call   80107f29 <switchkvm>

			// Process is done running for now.
			// It should have changed its p->state before coming back.
			proc = 0;
80104bf2:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80104bf9:	00 00 00 00 
80104bfd:	eb 01                	jmp    80104c00 <scheduler+0x91>
		if (p->state != RUNNABLE){
			continue;
		}
		for(t = p->threads; t < &p->threads[NTHREAD]; t++){
			if (t->state != T_RUNNABLE){
				continue;
80104bff:	90                   	nop
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
		if (p->state != RUNNABLE){
			continue;
		}
		for(t = p->threads; t < &p->threads[NTHREAD]; t++){
80104c00:	83 45 f0 20          	addl   $0x20,-0x10(%ebp)
80104c04:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c07:	05 48 02 00 00       	add    $0x248,%eax
80104c0c:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80104c0f:	77 97                	ja     80104ba8 <scheduler+0x39>
80104c11:	eb 01                	jmp    80104c14 <scheduler+0xa5>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
		if (p->state != RUNNABLE){
			continue;
80104c13:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104c14:	81 45 f4 a4 02 00 00 	addl   $0x2a4,-0xc(%ebp)
80104c1b:	81 7d f4 94 d2 11 80 	cmpl   $0x8011d294,-0xc(%ebp)
80104c22:	0f 82 6a ff ff ff    	jb     80104b92 <scheduler+0x23>
			// Process is done running for now.
			// It should have changed its p->state before coming back.
			proc = 0;
		}
    }
    release(&ptable.lock);
80104c28:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104c2f:	e8 cd 04 00 00       	call   80105101 <release>

  }
80104c34:	e9 3c ff ff ff       	jmp    80104b75 <scheduler+0x6>

80104c39 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80104c39:	55                   	push   %ebp
80104c3a:	89 e5                	mov    %esp,%ebp
80104c3c:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80104c3f:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104c46:	e8 72 05 00 00       	call   801051bd <holding>
80104c4b:	85 c0                	test   %eax,%eax
80104c4d:	75 0c                	jne    80104c5b <sched+0x22>
    panic("sched ptable.lock");
80104c4f:	c7 04 24 de 89 10 80 	movl   $0x801089de,(%esp)
80104c56:	e8 e2 b8 ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
80104c5b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104c61:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104c67:	83 f8 01             	cmp    $0x1,%eax
80104c6a:	74 0c                	je     80104c78 <sched+0x3f>
    panic("sched locks");
80104c6c:	c7 04 24 f0 89 10 80 	movl   $0x801089f0,(%esp)
80104c73:	e8 c5 b8 ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
80104c78:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c7e:	8b 40 08             	mov    0x8(%eax),%eax
80104c81:	83 f8 04             	cmp    $0x4,%eax
80104c84:	75 0c                	jne    80104c92 <sched+0x59>
    panic("sched running");
80104c86:	c7 04 24 fc 89 10 80 	movl   $0x801089fc,(%esp)
80104c8d:	e8 ab b8 ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
80104c92:	e8 e9 f6 ff ff       	call   80104380 <readeflags>
80104c97:	25 00 02 00 00       	and    $0x200,%eax
80104c9c:	85 c0                	test   %eax,%eax
80104c9e:	74 0c                	je     80104cac <sched+0x73>
    panic("sched interruptible");
80104ca0:	c7 04 24 0a 8a 10 80 	movl   $0x80108a0a,(%esp)
80104ca7:	e8 91 b8 ff ff       	call   8010053d <panic>
  intena = cpu->intena;
80104cac:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104cb2:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104cb8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->threads->context, cpu->scheduler);
80104cbb:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104cc1:	8b 40 04             	mov    0x4(%eax),%eax
80104cc4:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104ccb:	83 c2 5c             	add    $0x5c,%edx
80104cce:	89 44 24 04          	mov    %eax,0x4(%esp)
80104cd2:	89 14 24             	mov    %edx,(%esp)
80104cd5:	e8 ba 08 00 00       	call   80105594 <swtch>
  cpu->intena = intena;
80104cda:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104ce0:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ce3:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104ce9:	c9                   	leave  
80104cea:	c3                   	ret    

80104ceb <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80104ceb:	55                   	push   %ebp
80104cec:	89 e5                	mov    %esp,%ebp
80104cee:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80104cf1:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104cf8:	e8 a2 03 00 00       	call   8010509f <acquire>
  proc->state = RUNNABLE;
80104cfd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d03:	c7 40 08 03 00 00 00 	movl   $0x3,0x8(%eax)
  sched();
80104d0a:	e8 2a ff ff ff       	call   80104c39 <sched>
  release(&ptable.lock);
80104d0f:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104d16:	e8 e6 03 00 00       	call   80105101 <release>
}
80104d1b:	c9                   	leave  
80104d1c:	c3                   	ret    

80104d1d <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80104d1d:	55                   	push   %ebp
80104d1e:	89 e5                	mov    %esp,%ebp
80104d20:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80104d23:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104d2a:	e8 d2 03 00 00       	call   80105101 <release>

  if (first) {
80104d2f:	a1 24 b0 10 80       	mov    0x8010b024,%eax
80104d34:	85 c0                	test   %eax,%eax
80104d36:	74 0f                	je     80104d47 <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80104d38:	c7 05 24 b0 10 80 00 	movl   $0x0,0x8010b024
80104d3f:	00 00 00 
    initlog();
80104d42:	e8 3d e5 ff ff       	call   80103284 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80104d47:	c9                   	leave  
80104d48:	c3                   	ret    

80104d49 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80104d49:	55                   	push   %ebp
80104d4a:	89 e5                	mov    %esp,%ebp
80104d4c:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80104d4f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d55:	85 c0                	test   %eax,%eax
80104d57:	75 0c                	jne    80104d65 <sleep+0x1c>
    panic("sleep");
80104d59:	c7 04 24 1e 8a 10 80 	movl   $0x80108a1e,(%esp)
80104d60:	e8 d8 b7 ff ff       	call   8010053d <panic>

  if(lk == 0)
80104d65:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104d69:	75 0c                	jne    80104d77 <sleep+0x2e>
    panic("sleep without lk");
80104d6b:	c7 04 24 24 8a 10 80 	movl   $0x80108a24,(%esp)
80104d72:	e8 c6 b7 ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80104d77:	81 7d 0c 60 29 11 80 	cmpl   $0x80112960,0xc(%ebp)
80104d7e:	74 17                	je     80104d97 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80104d80:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104d87:	e8 13 03 00 00       	call   8010509f <acquire>
    release(lk);
80104d8c:	8b 45 0c             	mov    0xc(%ebp),%eax
80104d8f:	89 04 24             	mov    %eax,(%esp)
80104d92:	e8 6a 03 00 00       	call   80105101 <release>
  }

  // Go to sleep.
  proc->threads->chan = chan;
80104d97:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d9d:	8b 55 08             	mov    0x8(%ebp),%edx
80104da0:	89 50 60             	mov    %edx,0x60(%eax)
  proc->state = SLEEPING;
80104da3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104da9:	c7 40 08 02 00 00 00 	movl   $0x2,0x8(%eax)
  proc->threads->state = T_SLEEPING;
80104db0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104db6:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
  sched();
80104dbd:	e8 77 fe ff ff       	call   80104c39 <sched>

  // Tidy up.
  proc->threads->chan = 0;
80104dc2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104dc8:	c7 40 60 00 00 00 00 	movl   $0x0,0x60(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80104dcf:	81 7d 0c 60 29 11 80 	cmpl   $0x80112960,0xc(%ebp)
80104dd6:	74 17                	je     80104def <sleep+0xa6>
    release(&ptable.lock);
80104dd8:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104ddf:	e8 1d 03 00 00       	call   80105101 <release>
    acquire(lk);
80104de4:	8b 45 0c             	mov    0xc(%ebp),%eax
80104de7:	89 04 24             	mov    %eax,(%esp)
80104dea:	e8 b0 02 00 00       	call   8010509f <acquire>
  }
}
80104def:	c9                   	leave  
80104df0:	c3                   	ret    

80104df1 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104df1:	55                   	push   %ebp
80104df2:	89 e5                	mov    %esp,%ebp
80104df4:	83 ec 10             	sub    $0x10,%esp
	struct proc *p;
	struct thread *t;

	for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104df7:	c7 45 fc 94 29 11 80 	movl   $0x80112994,-0x4(%ebp)
80104dfe:	eb 4d                	jmp    80104e4d <wakeup1+0x5c>
		if(p->state == SLEEPING){
80104e00:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104e03:	8b 40 08             	mov    0x8(%eax),%eax
80104e06:	83 f8 02             	cmp    $0x2,%eax
80104e09:	75 3b                	jne    80104e46 <wakeup1+0x55>
			for(t = p->threads; t < &p->threads[NTHREAD]; t++){
80104e0b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104e0e:	83 c0 48             	add    $0x48,%eax
80104e11:	89 45 f8             	mov    %eax,-0x8(%ebp)
80104e14:	eb 23                	jmp    80104e39 <wakeup1+0x48>
				if(t->chan == chan){
80104e16:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104e19:	8b 40 18             	mov    0x18(%eax),%eax
80104e1c:	3b 45 08             	cmp    0x8(%ebp),%eax
80104e1f:	75 14                	jne    80104e35 <wakeup1+0x44>
					t->state = T_RUNNABLE;
80104e21:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104e24:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
					p->state = RUNNABLE;
80104e2b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104e2e:	c7 40 08 03 00 00 00 	movl   $0x3,0x8(%eax)
	struct proc *p;
	struct thread *t;

	for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
		if(p->state == SLEEPING){
			for(t = p->threads; t < &p->threads[NTHREAD]; t++){
80104e35:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
80104e39:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104e3c:	05 48 02 00 00       	add    $0x248,%eax
80104e41:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80104e44:	77 d0                	ja     80104e16 <wakeup1+0x25>
wakeup1(void *chan)
{
	struct proc *p;
	struct thread *t;

	for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104e46:	81 45 fc a4 02 00 00 	addl   $0x2a4,-0x4(%ebp)
80104e4d:	81 7d fc 94 d2 11 80 	cmpl   $0x8011d294,-0x4(%ebp)
80104e54:	72 aa                	jb     80104e00 <wakeup1+0xf>
					p->state = RUNNABLE;
				}
			}
		}
	}
}
80104e56:	c9                   	leave  
80104e57:	c3                   	ret    

80104e58 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80104e58:	55                   	push   %ebp
80104e59:	89 e5                	mov    %esp,%ebp
80104e5b:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80104e5e:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104e65:	e8 35 02 00 00       	call   8010509f <acquire>
  wakeup1(chan);
80104e6a:	8b 45 08             	mov    0x8(%ebp),%eax
80104e6d:	89 04 24             	mov    %eax,(%esp)
80104e70:	e8 7c ff ff ff       	call   80104df1 <wakeup1>
  release(&ptable.lock);
80104e75:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104e7c:	e8 80 02 00 00       	call   80105101 <release>
}
80104e81:	c9                   	leave  
80104e82:	c3                   	ret    

80104e83 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104e83:	55                   	push   %ebp
80104e84:	89 e5                	mov    %esp,%ebp
80104e86:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80104e89:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104e90:	e8 0a 02 00 00       	call   8010509f <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104e95:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
80104e9c:	eb 47                	jmp    80104ee5 <kill+0x62>
    if(p->pid == pid){
80104e9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ea1:	8b 40 0c             	mov    0xc(%eax),%eax
80104ea4:	3b 45 08             	cmp    0x8(%ebp),%eax
80104ea7:	75 35                	jne    80104ede <kill+0x5b>
      p->killed = 1;
80104ea9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104eac:	c7 80 48 02 00 00 01 	movl   $0x1,0x248(%eax)
80104eb3:	00 00 00 
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104eb6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104eb9:	8b 40 08             	mov    0x8(%eax),%eax
80104ebc:	83 f8 02             	cmp    $0x2,%eax
80104ebf:	75 0a                	jne    80104ecb <kill+0x48>
        p->state = RUNNABLE;
80104ec1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ec4:	c7 40 08 03 00 00 00 	movl   $0x3,0x8(%eax)
      release(&ptable.lock);
80104ecb:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104ed2:	e8 2a 02 00 00       	call   80105101 <release>
      return 0;
80104ed7:	b8 00 00 00 00       	mov    $0x0,%eax
80104edc:	eb 21                	jmp    80104eff <kill+0x7c>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104ede:	81 45 f4 a4 02 00 00 	addl   $0x2a4,-0xc(%ebp)
80104ee5:	81 7d f4 94 d2 11 80 	cmpl   $0x8011d294,-0xc(%ebp)
80104eec:	72 b0                	jb     80104e9e <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80104eee:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104ef5:	e8 07 02 00 00       	call   80105101 <release>
  return -1;
80104efa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104eff:	c9                   	leave  
80104f00:	c3                   	ret    

80104f01 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104f01:	55                   	push   %ebp
80104f02:	89 e5                	mov    %esp,%ebp
80104f04:	83 ec 58             	sub    $0x58,%esp
  struct proc *p;
  struct thread *t;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104f07:	c7 45 f0 94 29 11 80 	movl   $0x80112994,-0x10(%ebp)
80104f0e:	e9 14 01 00 00       	jmp    80105027 <procdump+0x126>
    if(p->state == UNUSED)
80104f13:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f16:	8b 40 08             	mov    0x8(%eax),%eax
80104f19:	85 c0                	test   %eax,%eax
80104f1b:	0f 84 fe 00 00 00    	je     8010501f <procdump+0x11e>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80104f21:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f24:	8b 40 08             	mov    0x8(%eax),%eax
80104f27:	83 f8 05             	cmp    $0x5,%eax
80104f2a:	77 23                	ja     80104f4f <procdump+0x4e>
80104f2c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f2f:	8b 40 08             	mov    0x8(%eax),%eax
80104f32:	8b 04 85 0c b0 10 80 	mov    -0x7fef4ff4(,%eax,4),%eax
80104f39:	85 c0                	test   %eax,%eax
80104f3b:	74 12                	je     80104f4f <procdump+0x4e>
      state = states[p->state];
80104f3d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f40:	8b 40 08             	mov    0x8(%eax),%eax
80104f43:	8b 04 85 0c b0 10 80 	mov    -0x7fef4ff4(,%eax,4),%eax
80104f4a:	89 45 e8             	mov    %eax,-0x18(%ebp)
80104f4d:	eb 07                	jmp    80104f56 <procdump+0x55>
    else
      state = "???";
80104f4f:	c7 45 e8 35 8a 10 80 	movl   $0x80108a35,-0x18(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80104f56:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f59:	8d 90 90 02 00 00    	lea    0x290(%eax),%edx
80104f5f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f62:	8b 40 0c             	mov    0xc(%eax),%eax
80104f65:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104f69:	8b 55 e8             	mov    -0x18(%ebp),%edx
80104f6c:	89 54 24 08          	mov    %edx,0x8(%esp)
80104f70:	89 44 24 04          	mov    %eax,0x4(%esp)
80104f74:	c7 04 24 39 8a 10 80 	movl   $0x80108a39,(%esp)
80104f7b:	e8 21 b4 ff ff       	call   801003a1 <cprintf>
	if(p->state == SLEEPING){
80104f80:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f83:	8b 40 08             	mov    0x8(%eax),%eax
80104f86:	83 f8 02             	cmp    $0x2,%eax
80104f89:	0f 85 82 00 00 00    	jne    80105011 <procdump+0x110>
		for(t = p->threads; t < &p->threads[NTHREAD]; t++){
80104f8f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f92:	83 c0 48             	add    $0x48,%eax
80104f95:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104f98:	eb 6a                	jmp    80105004 <procdump+0x103>
			if(t->state != T_FREE){
80104f9a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104f9d:	8b 40 0c             	mov    0xc(%eax),%eax
80104fa0:	85 c0                	test   %eax,%eax
80104fa2:	74 5c                	je     80105000 <procdump+0xff>
				getcallerpcs((uint*)t->context->ebp+2, pc);
80104fa4:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104fa7:	8b 40 14             	mov    0x14(%eax),%eax
80104faa:	8b 40 0c             	mov    0xc(%eax),%eax
80104fad:	83 c0 08             	add    $0x8,%eax
80104fb0:	8d 55 c0             	lea    -0x40(%ebp),%edx
80104fb3:	89 54 24 04          	mov    %edx,0x4(%esp)
80104fb7:	89 04 24             	mov    %eax,(%esp)
80104fba:	e8 91 01 00 00       	call   80105150 <getcallerpcs>
			    for(i=0; i<10 && pc[i] != 0; i++){
80104fbf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104fc6:	eb 1b                	jmp    80104fe3 <procdump+0xe2>
					cprintf(" %p", pc[i]);
80104fc8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fcb:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
80104fcf:	89 44 24 04          	mov    %eax,0x4(%esp)
80104fd3:	c7 04 24 42 8a 10 80 	movl   $0x80108a42,(%esp)
80104fda:	e8 c2 b3 ff ff       	call   801003a1 <cprintf>
    cprintf("%d %s %s", p->pid, state, p->name);
	if(p->state == SLEEPING){
		for(t = p->threads; t < &p->threads[NTHREAD]; t++){
			if(t->state != T_FREE){
				getcallerpcs((uint*)t->context->ebp+2, pc);
			    for(i=0; i<10 && pc[i] != 0; i++){
80104fdf:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104fe3:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80104fe7:	7f 0b                	jg     80104ff4 <procdump+0xf3>
80104fe9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fec:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
80104ff0:	85 c0                	test   %eax,%eax
80104ff2:	75 d4                	jne    80104fc8 <procdump+0xc7>
					cprintf(" %p", pc[i]);
				}
				cprintf("\n");
80104ff4:	c7 04 24 46 8a 10 80 	movl   $0x80108a46,(%esp)
80104ffb:	e8 a1 b3 ff ff       	call   801003a1 <cprintf>
      state = states[p->state];
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
	if(p->state == SLEEPING){
		for(t = p->threads; t < &p->threads[NTHREAD]; t++){
80105000:	83 45 ec 20          	addl   $0x20,-0x14(%ebp)
80105004:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105007:	05 48 02 00 00       	add    $0x248,%eax
8010500c:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010500f:	77 89                	ja     80104f9a <procdump+0x99>
				}
				cprintf("\n");
			}
		}
    }
    cprintf("\n");
80105011:	c7 04 24 46 8a 10 80 	movl   $0x80108a46,(%esp)
80105018:	e8 84 b3 ff ff       	call   801003a1 <cprintf>
8010501d:	eb 01                	jmp    80105020 <procdump+0x11f>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
8010501f:	90                   	nop
  struct proc *p;
  struct thread *t;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105020:	81 45 f0 a4 02 00 00 	addl   $0x2a4,-0x10(%ebp)
80105027:	81 7d f0 94 d2 11 80 	cmpl   $0x8011d294,-0x10(%ebp)
8010502e:	0f 82 df fe ff ff    	jb     80104f13 <procdump+0x12>
			}
		}
    }
    cprintf("\n");
  }
}
80105034:	c9                   	leave  
80105035:	c3                   	ret    
	...

80105038 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80105038:	55                   	push   %ebp
80105039:	89 e5                	mov    %esp,%ebp
8010503b:	53                   	push   %ebx
8010503c:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010503f:	9c                   	pushf  
80105040:	5b                   	pop    %ebx
80105041:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80105044:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105047:	83 c4 10             	add    $0x10,%esp
8010504a:	5b                   	pop    %ebx
8010504b:	5d                   	pop    %ebp
8010504c:	c3                   	ret    

8010504d <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
8010504d:	55                   	push   %ebp
8010504e:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80105050:	fa                   	cli    
}
80105051:	5d                   	pop    %ebp
80105052:	c3                   	ret    

80105053 <sti>:

static inline void
sti(void)
{
80105053:	55                   	push   %ebp
80105054:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105056:	fb                   	sti    
}
80105057:	5d                   	pop    %ebp
80105058:	c3                   	ret    

80105059 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80105059:	55                   	push   %ebp
8010505a:	89 e5                	mov    %esp,%ebp
8010505c:	53                   	push   %ebx
8010505d:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80105060:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105063:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80105066:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105069:	89 c3                	mov    %eax,%ebx
8010506b:	89 d8                	mov    %ebx,%eax
8010506d:	f0 87 02             	lock xchg %eax,(%edx)
80105070:	89 c3                	mov    %eax,%ebx
80105072:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80105075:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105078:	83 c4 10             	add    $0x10,%esp
8010507b:	5b                   	pop    %ebx
8010507c:	5d                   	pop    %ebp
8010507d:	c3                   	ret    

8010507e <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
8010507e:	55                   	push   %ebp
8010507f:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105081:	8b 45 08             	mov    0x8(%ebp),%eax
80105084:	8b 55 0c             	mov    0xc(%ebp),%edx
80105087:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
8010508a:	8b 45 08             	mov    0x8(%ebp),%eax
8010508d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105093:	8b 45 08             	mov    0x8(%ebp),%eax
80105096:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
8010509d:	5d                   	pop    %ebp
8010509e:	c3                   	ret    

8010509f <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
8010509f:	55                   	push   %ebp
801050a0:	89 e5                	mov    %esp,%ebp
801050a2:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
801050a5:	e8 3d 01 00 00       	call   801051e7 <pushcli>
  if(holding(lk))
801050aa:	8b 45 08             	mov    0x8(%ebp),%eax
801050ad:	89 04 24             	mov    %eax,(%esp)
801050b0:	e8 08 01 00 00       	call   801051bd <holding>
801050b5:	85 c0                	test   %eax,%eax
801050b7:	74 0c                	je     801050c5 <acquire+0x26>
    panic("acquire");
801050b9:	c7 04 24 72 8a 10 80 	movl   $0x80108a72,(%esp)
801050c0:	e8 78 b4 ff ff       	call   8010053d <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
801050c5:	90                   	nop
801050c6:	8b 45 08             	mov    0x8(%ebp),%eax
801050c9:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801050d0:	00 
801050d1:	89 04 24             	mov    %eax,(%esp)
801050d4:	e8 80 ff ff ff       	call   80105059 <xchg>
801050d9:	85 c0                	test   %eax,%eax
801050db:	75 e9                	jne    801050c6 <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
801050dd:	8b 45 08             	mov    0x8(%ebp),%eax
801050e0:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801050e7:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
801050ea:	8b 45 08             	mov    0x8(%ebp),%eax
801050ed:	83 c0 0c             	add    $0xc,%eax
801050f0:	89 44 24 04          	mov    %eax,0x4(%esp)
801050f4:	8d 45 08             	lea    0x8(%ebp),%eax
801050f7:	89 04 24             	mov    %eax,(%esp)
801050fa:	e8 51 00 00 00       	call   80105150 <getcallerpcs>
}
801050ff:	c9                   	leave  
80105100:	c3                   	ret    

80105101 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105101:	55                   	push   %ebp
80105102:	89 e5                	mov    %esp,%ebp
80105104:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105107:	8b 45 08             	mov    0x8(%ebp),%eax
8010510a:	89 04 24             	mov    %eax,(%esp)
8010510d:	e8 ab 00 00 00       	call   801051bd <holding>
80105112:	85 c0                	test   %eax,%eax
80105114:	75 0c                	jne    80105122 <release+0x21>
    panic("release");
80105116:	c7 04 24 7a 8a 10 80 	movl   $0x80108a7a,(%esp)
8010511d:	e8 1b b4 ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
80105122:	8b 45 08             	mov    0x8(%ebp),%eax
80105125:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
8010512c:	8b 45 08             	mov    0x8(%ebp),%eax
8010512f:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105136:	8b 45 08             	mov    0x8(%ebp),%eax
80105139:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105140:	00 
80105141:	89 04 24             	mov    %eax,(%esp)
80105144:	e8 10 ff ff ff       	call   80105059 <xchg>

  popcli();
80105149:	e8 e1 00 00 00       	call   8010522f <popcli>
}
8010514e:	c9                   	leave  
8010514f:	c3                   	ret    

80105150 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105150:	55                   	push   %ebp
80105151:	89 e5                	mov    %esp,%ebp
80105153:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80105156:	8b 45 08             	mov    0x8(%ebp),%eax
80105159:	83 e8 08             	sub    $0x8,%eax
8010515c:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
8010515f:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80105166:	eb 32                	jmp    8010519a <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105168:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
8010516c:	74 47                	je     801051b5 <getcallerpcs+0x65>
8010516e:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105175:	76 3e                	jbe    801051b5 <getcallerpcs+0x65>
80105177:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
8010517b:	74 38                	je     801051b5 <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
8010517d:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105180:	c1 e0 02             	shl    $0x2,%eax
80105183:	03 45 0c             	add    0xc(%ebp),%eax
80105186:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105189:	8b 52 04             	mov    0x4(%edx),%edx
8010518c:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
8010518e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105191:	8b 00                	mov    (%eax),%eax
80105193:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105196:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
8010519a:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
8010519e:	7e c8                	jle    80105168 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
801051a0:	eb 13                	jmp    801051b5 <getcallerpcs+0x65>
    pcs[i] = 0;
801051a2:	8b 45 f8             	mov    -0x8(%ebp),%eax
801051a5:	c1 e0 02             	shl    $0x2,%eax
801051a8:	03 45 0c             	add    0xc(%ebp),%eax
801051ab:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
801051b1:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801051b5:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
801051b9:	7e e7                	jle    801051a2 <getcallerpcs+0x52>
    pcs[i] = 0;
}
801051bb:	c9                   	leave  
801051bc:	c3                   	ret    

801051bd <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
801051bd:	55                   	push   %ebp
801051be:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
801051c0:	8b 45 08             	mov    0x8(%ebp),%eax
801051c3:	8b 00                	mov    (%eax),%eax
801051c5:	85 c0                	test   %eax,%eax
801051c7:	74 17                	je     801051e0 <holding+0x23>
801051c9:	8b 45 08             	mov    0x8(%ebp),%eax
801051cc:	8b 50 08             	mov    0x8(%eax),%edx
801051cf:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801051d5:	39 c2                	cmp    %eax,%edx
801051d7:	75 07                	jne    801051e0 <holding+0x23>
801051d9:	b8 01 00 00 00       	mov    $0x1,%eax
801051de:	eb 05                	jmp    801051e5 <holding+0x28>
801051e0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801051e5:	5d                   	pop    %ebp
801051e6:	c3                   	ret    

801051e7 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
801051e7:	55                   	push   %ebp
801051e8:	89 e5                	mov    %esp,%ebp
801051ea:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
801051ed:	e8 46 fe ff ff       	call   80105038 <readeflags>
801051f2:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
801051f5:	e8 53 fe ff ff       	call   8010504d <cli>
  if(cpu->ncli++ == 0)
801051fa:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105200:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105206:	85 d2                	test   %edx,%edx
80105208:	0f 94 c1             	sete   %cl
8010520b:	83 c2 01             	add    $0x1,%edx
8010520e:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105214:	84 c9                	test   %cl,%cl
80105216:	74 15                	je     8010522d <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
80105218:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010521e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105221:	81 e2 00 02 00 00    	and    $0x200,%edx
80105227:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
8010522d:	c9                   	leave  
8010522e:	c3                   	ret    

8010522f <popcli>:

void
popcli(void)
{
8010522f:	55                   	push   %ebp
80105230:	89 e5                	mov    %esp,%ebp
80105232:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80105235:	e8 fe fd ff ff       	call   80105038 <readeflags>
8010523a:	25 00 02 00 00       	and    $0x200,%eax
8010523f:	85 c0                	test   %eax,%eax
80105241:	74 0c                	je     8010524f <popcli+0x20>
    panic("popcli - interruptible");
80105243:	c7 04 24 82 8a 10 80 	movl   $0x80108a82,(%esp)
8010524a:	e8 ee b2 ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
8010524f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105255:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
8010525b:	83 ea 01             	sub    $0x1,%edx
8010525e:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105264:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
8010526a:	85 c0                	test   %eax,%eax
8010526c:	79 0c                	jns    8010527a <popcli+0x4b>
    panic("popcli");
8010526e:	c7 04 24 99 8a 10 80 	movl   $0x80108a99,(%esp)
80105275:	e8 c3 b2 ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
8010527a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105280:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105286:	85 c0                	test   %eax,%eax
80105288:	75 15                	jne    8010529f <popcli+0x70>
8010528a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105290:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105296:	85 c0                	test   %eax,%eax
80105298:	74 05                	je     8010529f <popcli+0x70>
    sti();
8010529a:	e8 b4 fd ff ff       	call   80105053 <sti>
}
8010529f:	c9                   	leave  
801052a0:	c3                   	ret    
801052a1:	00 00                	add    %al,(%eax)
	...

801052a4 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
801052a4:	55                   	push   %ebp
801052a5:	89 e5                	mov    %esp,%ebp
801052a7:	57                   	push   %edi
801052a8:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
801052a9:	8b 4d 08             	mov    0x8(%ebp),%ecx
801052ac:	8b 55 10             	mov    0x10(%ebp),%edx
801052af:	8b 45 0c             	mov    0xc(%ebp),%eax
801052b2:	89 cb                	mov    %ecx,%ebx
801052b4:	89 df                	mov    %ebx,%edi
801052b6:	89 d1                	mov    %edx,%ecx
801052b8:	fc                   	cld    
801052b9:	f3 aa                	rep stos %al,%es:(%edi)
801052bb:	89 ca                	mov    %ecx,%edx
801052bd:	89 fb                	mov    %edi,%ebx
801052bf:	89 5d 08             	mov    %ebx,0x8(%ebp)
801052c2:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
801052c5:	5b                   	pop    %ebx
801052c6:	5f                   	pop    %edi
801052c7:	5d                   	pop    %ebp
801052c8:	c3                   	ret    

801052c9 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
801052c9:	55                   	push   %ebp
801052ca:	89 e5                	mov    %esp,%ebp
801052cc:	57                   	push   %edi
801052cd:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
801052ce:	8b 4d 08             	mov    0x8(%ebp),%ecx
801052d1:	8b 55 10             	mov    0x10(%ebp),%edx
801052d4:	8b 45 0c             	mov    0xc(%ebp),%eax
801052d7:	89 cb                	mov    %ecx,%ebx
801052d9:	89 df                	mov    %ebx,%edi
801052db:	89 d1                	mov    %edx,%ecx
801052dd:	fc                   	cld    
801052de:	f3 ab                	rep stos %eax,%es:(%edi)
801052e0:	89 ca                	mov    %ecx,%edx
801052e2:	89 fb                	mov    %edi,%ebx
801052e4:	89 5d 08             	mov    %ebx,0x8(%ebp)
801052e7:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
801052ea:	5b                   	pop    %ebx
801052eb:	5f                   	pop    %edi
801052ec:	5d                   	pop    %ebp
801052ed:	c3                   	ret    

801052ee <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
801052ee:	55                   	push   %ebp
801052ef:	89 e5                	mov    %esp,%ebp
801052f1:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
801052f4:	8b 45 08             	mov    0x8(%ebp),%eax
801052f7:	83 e0 03             	and    $0x3,%eax
801052fa:	85 c0                	test   %eax,%eax
801052fc:	75 49                	jne    80105347 <memset+0x59>
801052fe:	8b 45 10             	mov    0x10(%ebp),%eax
80105301:	83 e0 03             	and    $0x3,%eax
80105304:	85 c0                	test   %eax,%eax
80105306:	75 3f                	jne    80105347 <memset+0x59>
    c &= 0xFF;
80105308:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
8010530f:	8b 45 10             	mov    0x10(%ebp),%eax
80105312:	c1 e8 02             	shr    $0x2,%eax
80105315:	89 c2                	mov    %eax,%edx
80105317:	8b 45 0c             	mov    0xc(%ebp),%eax
8010531a:	89 c1                	mov    %eax,%ecx
8010531c:	c1 e1 18             	shl    $0x18,%ecx
8010531f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105322:	c1 e0 10             	shl    $0x10,%eax
80105325:	09 c1                	or     %eax,%ecx
80105327:	8b 45 0c             	mov    0xc(%ebp),%eax
8010532a:	c1 e0 08             	shl    $0x8,%eax
8010532d:	09 c8                	or     %ecx,%eax
8010532f:	0b 45 0c             	or     0xc(%ebp),%eax
80105332:	89 54 24 08          	mov    %edx,0x8(%esp)
80105336:	89 44 24 04          	mov    %eax,0x4(%esp)
8010533a:	8b 45 08             	mov    0x8(%ebp),%eax
8010533d:	89 04 24             	mov    %eax,(%esp)
80105340:	e8 84 ff ff ff       	call   801052c9 <stosl>
80105345:	eb 19                	jmp    80105360 <memset+0x72>
  } else
    stosb(dst, c, n);
80105347:	8b 45 10             	mov    0x10(%ebp),%eax
8010534a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010534e:	8b 45 0c             	mov    0xc(%ebp),%eax
80105351:	89 44 24 04          	mov    %eax,0x4(%esp)
80105355:	8b 45 08             	mov    0x8(%ebp),%eax
80105358:	89 04 24             	mov    %eax,(%esp)
8010535b:	e8 44 ff ff ff       	call   801052a4 <stosb>
  return dst;
80105360:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105363:	c9                   	leave  
80105364:	c3                   	ret    

80105365 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105365:	55                   	push   %ebp
80105366:	89 e5                	mov    %esp,%ebp
80105368:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
8010536b:	8b 45 08             	mov    0x8(%ebp),%eax
8010536e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105371:	8b 45 0c             	mov    0xc(%ebp),%eax
80105374:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105377:	eb 32                	jmp    801053ab <memcmp+0x46>
    if(*s1 != *s2)
80105379:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010537c:	0f b6 10             	movzbl (%eax),%edx
8010537f:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105382:	0f b6 00             	movzbl (%eax),%eax
80105385:	38 c2                	cmp    %al,%dl
80105387:	74 1a                	je     801053a3 <memcmp+0x3e>
      return *s1 - *s2;
80105389:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010538c:	0f b6 00             	movzbl (%eax),%eax
8010538f:	0f b6 d0             	movzbl %al,%edx
80105392:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105395:	0f b6 00             	movzbl (%eax),%eax
80105398:	0f b6 c0             	movzbl %al,%eax
8010539b:	89 d1                	mov    %edx,%ecx
8010539d:	29 c1                	sub    %eax,%ecx
8010539f:	89 c8                	mov    %ecx,%eax
801053a1:	eb 1c                	jmp    801053bf <memcmp+0x5a>
    s1++, s2++;
801053a3:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801053a7:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
801053ab:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801053af:	0f 95 c0             	setne  %al
801053b2:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801053b6:	84 c0                	test   %al,%al
801053b8:	75 bf                	jne    80105379 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
801053ba:	b8 00 00 00 00       	mov    $0x0,%eax
}
801053bf:	c9                   	leave  
801053c0:	c3                   	ret    

801053c1 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
801053c1:	55                   	push   %ebp
801053c2:	89 e5                	mov    %esp,%ebp
801053c4:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
801053c7:	8b 45 0c             	mov    0xc(%ebp),%eax
801053ca:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
801053cd:	8b 45 08             	mov    0x8(%ebp),%eax
801053d0:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
801053d3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801053d6:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801053d9:	73 54                	jae    8010542f <memmove+0x6e>
801053db:	8b 45 10             	mov    0x10(%ebp),%eax
801053de:	8b 55 fc             	mov    -0x4(%ebp),%edx
801053e1:	01 d0                	add    %edx,%eax
801053e3:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801053e6:	76 47                	jbe    8010542f <memmove+0x6e>
    s += n;
801053e8:	8b 45 10             	mov    0x10(%ebp),%eax
801053eb:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
801053ee:	8b 45 10             	mov    0x10(%ebp),%eax
801053f1:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
801053f4:	eb 13                	jmp    80105409 <memmove+0x48>
      *--d = *--s;
801053f6:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
801053fa:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
801053fe:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105401:	0f b6 10             	movzbl (%eax),%edx
80105404:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105407:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105409:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010540d:	0f 95 c0             	setne  %al
80105410:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105414:	84 c0                	test   %al,%al
80105416:	75 de                	jne    801053f6 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105418:	eb 25                	jmp    8010543f <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
8010541a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010541d:	0f b6 10             	movzbl (%eax),%edx
80105420:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105423:	88 10                	mov    %dl,(%eax)
80105425:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105429:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010542d:	eb 01                	jmp    80105430 <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
8010542f:	90                   	nop
80105430:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105434:	0f 95 c0             	setne  %al
80105437:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010543b:	84 c0                	test   %al,%al
8010543d:	75 db                	jne    8010541a <memmove+0x59>
      *d++ = *s++;

  return dst;
8010543f:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105442:	c9                   	leave  
80105443:	c3                   	ret    

80105444 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105444:	55                   	push   %ebp
80105445:	89 e5                	mov    %esp,%ebp
80105447:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
8010544a:	8b 45 10             	mov    0x10(%ebp),%eax
8010544d:	89 44 24 08          	mov    %eax,0x8(%esp)
80105451:	8b 45 0c             	mov    0xc(%ebp),%eax
80105454:	89 44 24 04          	mov    %eax,0x4(%esp)
80105458:	8b 45 08             	mov    0x8(%ebp),%eax
8010545b:	89 04 24             	mov    %eax,(%esp)
8010545e:	e8 5e ff ff ff       	call   801053c1 <memmove>
}
80105463:	c9                   	leave  
80105464:	c3                   	ret    

80105465 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105465:	55                   	push   %ebp
80105466:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105468:	eb 0c                	jmp    80105476 <strncmp+0x11>
    n--, p++, q++;
8010546a:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010546e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105472:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105476:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010547a:	74 1a                	je     80105496 <strncmp+0x31>
8010547c:	8b 45 08             	mov    0x8(%ebp),%eax
8010547f:	0f b6 00             	movzbl (%eax),%eax
80105482:	84 c0                	test   %al,%al
80105484:	74 10                	je     80105496 <strncmp+0x31>
80105486:	8b 45 08             	mov    0x8(%ebp),%eax
80105489:	0f b6 10             	movzbl (%eax),%edx
8010548c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010548f:	0f b6 00             	movzbl (%eax),%eax
80105492:	38 c2                	cmp    %al,%dl
80105494:	74 d4                	je     8010546a <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105496:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010549a:	75 07                	jne    801054a3 <strncmp+0x3e>
    return 0;
8010549c:	b8 00 00 00 00       	mov    $0x0,%eax
801054a1:	eb 18                	jmp    801054bb <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
801054a3:	8b 45 08             	mov    0x8(%ebp),%eax
801054a6:	0f b6 00             	movzbl (%eax),%eax
801054a9:	0f b6 d0             	movzbl %al,%edx
801054ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801054af:	0f b6 00             	movzbl (%eax),%eax
801054b2:	0f b6 c0             	movzbl %al,%eax
801054b5:	89 d1                	mov    %edx,%ecx
801054b7:	29 c1                	sub    %eax,%ecx
801054b9:	89 c8                	mov    %ecx,%eax
}
801054bb:	5d                   	pop    %ebp
801054bc:	c3                   	ret    

801054bd <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
801054bd:	55                   	push   %ebp
801054be:	89 e5                	mov    %esp,%ebp
801054c0:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
801054c3:	8b 45 08             	mov    0x8(%ebp),%eax
801054c6:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
801054c9:	90                   	nop
801054ca:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801054ce:	0f 9f c0             	setg   %al
801054d1:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801054d5:	84 c0                	test   %al,%al
801054d7:	74 30                	je     80105509 <strncpy+0x4c>
801054d9:	8b 45 0c             	mov    0xc(%ebp),%eax
801054dc:	0f b6 10             	movzbl (%eax),%edx
801054df:	8b 45 08             	mov    0x8(%ebp),%eax
801054e2:	88 10                	mov    %dl,(%eax)
801054e4:	8b 45 08             	mov    0x8(%ebp),%eax
801054e7:	0f b6 00             	movzbl (%eax),%eax
801054ea:	84 c0                	test   %al,%al
801054ec:	0f 95 c0             	setne  %al
801054ef:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801054f3:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
801054f7:	84 c0                	test   %al,%al
801054f9:	75 cf                	jne    801054ca <strncpy+0xd>
    ;
  while(n-- > 0)
801054fb:	eb 0c                	jmp    80105509 <strncpy+0x4c>
    *s++ = 0;
801054fd:	8b 45 08             	mov    0x8(%ebp),%eax
80105500:	c6 00 00             	movb   $0x0,(%eax)
80105503:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105507:	eb 01                	jmp    8010550a <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105509:	90                   	nop
8010550a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010550e:	0f 9f c0             	setg   %al
80105511:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105515:	84 c0                	test   %al,%al
80105517:	75 e4                	jne    801054fd <strncpy+0x40>
    *s++ = 0;
  return os;
80105519:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010551c:	c9                   	leave  
8010551d:	c3                   	ret    

8010551e <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
8010551e:	55                   	push   %ebp
8010551f:	89 e5                	mov    %esp,%ebp
80105521:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105524:	8b 45 08             	mov    0x8(%ebp),%eax
80105527:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
8010552a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010552e:	7f 05                	jg     80105535 <safestrcpy+0x17>
    return os;
80105530:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105533:	eb 35                	jmp    8010556a <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
80105535:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105539:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010553d:	7e 22                	jle    80105561 <safestrcpy+0x43>
8010553f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105542:	0f b6 10             	movzbl (%eax),%edx
80105545:	8b 45 08             	mov    0x8(%ebp),%eax
80105548:	88 10                	mov    %dl,(%eax)
8010554a:	8b 45 08             	mov    0x8(%ebp),%eax
8010554d:	0f b6 00             	movzbl (%eax),%eax
80105550:	84 c0                	test   %al,%al
80105552:	0f 95 c0             	setne  %al
80105555:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105559:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
8010555d:	84 c0                	test   %al,%al
8010555f:	75 d4                	jne    80105535 <safestrcpy+0x17>
    ;
  *s = 0;
80105561:	8b 45 08             	mov    0x8(%ebp),%eax
80105564:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105567:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010556a:	c9                   	leave  
8010556b:	c3                   	ret    

8010556c <strlen>:

int
strlen(const char *s)
{
8010556c:	55                   	push   %ebp
8010556d:	89 e5                	mov    %esp,%ebp
8010556f:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105572:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105579:	eb 04                	jmp    8010557f <strlen+0x13>
8010557b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010557f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105582:	03 45 08             	add    0x8(%ebp),%eax
80105585:	0f b6 00             	movzbl (%eax),%eax
80105588:	84 c0                	test   %al,%al
8010558a:	75 ef                	jne    8010557b <strlen+0xf>
    ;
  return n;
8010558c:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010558f:	c9                   	leave  
80105590:	c3                   	ret    
80105591:	00 00                	add    %al,(%eax)
	...

80105594 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105594:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105598:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
8010559c:	55                   	push   %ebp
  pushl %ebx
8010559d:	53                   	push   %ebx
  pushl %esi
8010559e:	56                   	push   %esi
  pushl %edi
8010559f:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
801055a0:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
801055a2:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
801055a4:	5f                   	pop    %edi
  popl %esi
801055a5:	5e                   	pop    %esi
  popl %ebx
801055a6:	5b                   	pop    %ebx
  popl %ebp
801055a7:	5d                   	pop    %ebp
  ret
801055a8:	c3                   	ret    
801055a9:	00 00                	add    %al,(%eax)
	...

801055ac <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
801055ac:	55                   	push   %ebp
801055ad:	89 e5                	mov    %esp,%ebp
  if(addr >= proc->sz || addr+4 > proc->sz)
801055af:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055b5:	8b 00                	mov    (%eax),%eax
801055b7:	3b 45 08             	cmp    0x8(%ebp),%eax
801055ba:	76 12                	jbe    801055ce <fetchint+0x22>
801055bc:	8b 45 08             	mov    0x8(%ebp),%eax
801055bf:	8d 50 04             	lea    0x4(%eax),%edx
801055c2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055c8:	8b 00                	mov    (%eax),%eax
801055ca:	39 c2                	cmp    %eax,%edx
801055cc:	76 07                	jbe    801055d5 <fetchint+0x29>
    return -1;
801055ce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055d3:	eb 0f                	jmp    801055e4 <fetchint+0x38>
  *ip = *(int*)(addr);
801055d5:	8b 45 08             	mov    0x8(%ebp),%eax
801055d8:	8b 10                	mov    (%eax),%edx
801055da:	8b 45 0c             	mov    0xc(%ebp),%eax
801055dd:	89 10                	mov    %edx,(%eax)
  return 0;
801055df:	b8 00 00 00 00       	mov    $0x0,%eax
}
801055e4:	5d                   	pop    %ebp
801055e5:	c3                   	ret    

801055e6 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
801055e6:	55                   	push   %ebp
801055e7:	89 e5                	mov    %esp,%ebp
801055e9:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= proc->sz)
801055ec:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055f2:	8b 00                	mov    (%eax),%eax
801055f4:	3b 45 08             	cmp    0x8(%ebp),%eax
801055f7:	77 07                	ja     80105600 <fetchstr+0x1a>
    return -1;
801055f9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055fe:	eb 48                	jmp    80105648 <fetchstr+0x62>
  *pp = (char*)addr;
80105600:	8b 55 08             	mov    0x8(%ebp),%edx
80105603:	8b 45 0c             	mov    0xc(%ebp),%eax
80105606:	89 10                	mov    %edx,(%eax)
  ep = (char*)proc->sz;
80105608:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010560e:	8b 00                	mov    (%eax),%eax
80105610:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105613:	8b 45 0c             	mov    0xc(%ebp),%eax
80105616:	8b 00                	mov    (%eax),%eax
80105618:	89 45 fc             	mov    %eax,-0x4(%ebp)
8010561b:	eb 1e                	jmp    8010563b <fetchstr+0x55>
    if(*s == 0)
8010561d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105620:	0f b6 00             	movzbl (%eax),%eax
80105623:	84 c0                	test   %al,%al
80105625:	75 10                	jne    80105637 <fetchstr+0x51>
      return s - *pp;
80105627:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010562a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010562d:	8b 00                	mov    (%eax),%eax
8010562f:	89 d1                	mov    %edx,%ecx
80105631:	29 c1                	sub    %eax,%ecx
80105633:	89 c8                	mov    %ecx,%eax
80105635:	eb 11                	jmp    80105648 <fetchstr+0x62>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
80105637:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010563b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010563e:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105641:	72 da                	jb     8010561d <fetchstr+0x37>
    if(*s == 0)
      return s - *pp;
  return -1;
80105643:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105648:	c9                   	leave  
80105649:	c3                   	ret    

8010564a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
8010564a:	55                   	push   %ebp
8010564b:	89 e5                	mov    %esp,%ebp
8010564d:	83 ec 08             	sub    $0x8,%esp
  return fetchint(proc->threads->tf->esp + 4 + 4*n, ip);
80105650:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105656:	8b 40 58             	mov    0x58(%eax),%eax
80105659:	8b 50 44             	mov    0x44(%eax),%edx
8010565c:	8b 45 08             	mov    0x8(%ebp),%eax
8010565f:	c1 e0 02             	shl    $0x2,%eax
80105662:	01 d0                	add    %edx,%eax
80105664:	8d 50 04             	lea    0x4(%eax),%edx
80105667:	8b 45 0c             	mov    0xc(%ebp),%eax
8010566a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010566e:	89 14 24             	mov    %edx,(%esp)
80105671:	e8 36 ff ff ff       	call   801055ac <fetchint>
}
80105676:	c9                   	leave  
80105677:	c3                   	ret    

80105678 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80105678:	55                   	push   %ebp
80105679:	89 e5                	mov    %esp,%ebp
8010567b:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
8010567e:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105681:	89 44 24 04          	mov    %eax,0x4(%esp)
80105685:	8b 45 08             	mov    0x8(%ebp),%eax
80105688:	89 04 24             	mov    %eax,(%esp)
8010568b:	e8 ba ff ff ff       	call   8010564a <argint>
80105690:	85 c0                	test   %eax,%eax
80105692:	79 07                	jns    8010569b <argptr+0x23>
    return -1;
80105694:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105699:	eb 3d                	jmp    801056d8 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
8010569b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010569e:	89 c2                	mov    %eax,%edx
801056a0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056a6:	8b 00                	mov    (%eax),%eax
801056a8:	39 c2                	cmp    %eax,%edx
801056aa:	73 16                	jae    801056c2 <argptr+0x4a>
801056ac:	8b 45 fc             	mov    -0x4(%ebp),%eax
801056af:	89 c2                	mov    %eax,%edx
801056b1:	8b 45 10             	mov    0x10(%ebp),%eax
801056b4:	01 c2                	add    %eax,%edx
801056b6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056bc:	8b 00                	mov    (%eax),%eax
801056be:	39 c2                	cmp    %eax,%edx
801056c0:	76 07                	jbe    801056c9 <argptr+0x51>
    return -1;
801056c2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801056c7:	eb 0f                	jmp    801056d8 <argptr+0x60>
  *pp = (char*)i;
801056c9:	8b 45 fc             	mov    -0x4(%ebp),%eax
801056cc:	89 c2                	mov    %eax,%edx
801056ce:	8b 45 0c             	mov    0xc(%ebp),%eax
801056d1:	89 10                	mov    %edx,(%eax)
  return 0;
801056d3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801056d8:	c9                   	leave  
801056d9:	c3                   	ret    

801056da <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
801056da:	55                   	push   %ebp
801056db:	89 e5                	mov    %esp,%ebp
801056dd:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
801056e0:	8d 45 fc             	lea    -0x4(%ebp),%eax
801056e3:	89 44 24 04          	mov    %eax,0x4(%esp)
801056e7:	8b 45 08             	mov    0x8(%ebp),%eax
801056ea:	89 04 24             	mov    %eax,(%esp)
801056ed:	e8 58 ff ff ff       	call   8010564a <argint>
801056f2:	85 c0                	test   %eax,%eax
801056f4:	79 07                	jns    801056fd <argstr+0x23>
    return -1;
801056f6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801056fb:	eb 12                	jmp    8010570f <argstr+0x35>
  return fetchstr(addr, pp);
801056fd:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105700:	8b 55 0c             	mov    0xc(%ebp),%edx
80105703:	89 54 24 04          	mov    %edx,0x4(%esp)
80105707:	89 04 24             	mov    %eax,(%esp)
8010570a:	e8 d7 fe ff ff       	call   801055e6 <fetchstr>
}
8010570f:	c9                   	leave  
80105710:	c3                   	ret    

80105711 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
80105711:	55                   	push   %ebp
80105712:	89 e5                	mov    %esp,%ebp
80105714:	53                   	push   %ebx
80105715:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->threads->tf->eax;
80105718:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010571e:	8b 40 58             	mov    0x58(%eax),%eax
80105721:	8b 40 1c             	mov    0x1c(%eax),%eax
80105724:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80105727:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010572b:	7e 30                	jle    8010575d <syscall+0x4c>
8010572d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105730:	83 f8 15             	cmp    $0x15,%eax
80105733:	77 28                	ja     8010575d <syscall+0x4c>
80105735:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105738:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
8010573f:	85 c0                	test   %eax,%eax
80105741:	74 1a                	je     8010575d <syscall+0x4c>
    proc->threads->tf->eax = syscalls[num]();
80105743:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105749:	8b 58 58             	mov    0x58(%eax),%ebx
8010574c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010574f:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
80105756:	ff d0                	call   *%eax
80105758:	89 43 1c             	mov    %eax,0x1c(%ebx)
8010575b:	eb 40                	jmp    8010579d <syscall+0x8c>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
8010575d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105763:	8d 88 90 02 00 00    	lea    0x290(%eax),%ecx
80105769:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

  num = proc->threads->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->threads->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
8010576f:	8b 40 0c             	mov    0xc(%eax),%eax
80105772:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105775:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105779:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010577d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105781:	c7 04 24 a0 8a 10 80 	movl   $0x80108aa0,(%esp)
80105788:	e8 14 ac ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->threads->tf->eax = -1;
8010578d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105793:	8b 40 58             	mov    0x58(%eax),%eax
80105796:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
8010579d:	83 c4 24             	add    $0x24,%esp
801057a0:	5b                   	pop    %ebx
801057a1:	5d                   	pop    %ebp
801057a2:	c3                   	ret    
	...

801057a4 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
801057a4:	55                   	push   %ebp
801057a5:	89 e5                	mov    %esp,%ebp
801057a7:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
801057aa:	8d 45 f0             	lea    -0x10(%ebp),%eax
801057ad:	89 44 24 04          	mov    %eax,0x4(%esp)
801057b1:	8b 45 08             	mov    0x8(%ebp),%eax
801057b4:	89 04 24             	mov    %eax,(%esp)
801057b7:	e8 8e fe ff ff       	call   8010564a <argint>
801057bc:	85 c0                	test   %eax,%eax
801057be:	79 07                	jns    801057c7 <argfd+0x23>
    return -1;
801057c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801057c5:	eb 53                	jmp    8010581a <argfd+0x76>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
801057c7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057ca:	85 c0                	test   %eax,%eax
801057cc:	78 24                	js     801057f2 <argfd+0x4e>
801057ce:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057d1:	83 f8 0f             	cmp    $0xf,%eax
801057d4:	7f 1c                	jg     801057f2 <argfd+0x4e>
801057d6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057dc:	8b 55 f0             	mov    -0x10(%ebp),%edx
801057df:	81 c2 90 00 00 00    	add    $0x90,%edx
801057e5:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801057e9:	89 45 f4             	mov    %eax,-0xc(%ebp)
801057ec:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801057f0:	75 07                	jne    801057f9 <argfd+0x55>
    return -1;
801057f2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801057f7:	eb 21                	jmp    8010581a <argfd+0x76>
  if(pfd)
801057f9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801057fd:	74 08                	je     80105807 <argfd+0x63>
    *pfd = fd;
801057ff:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105802:	8b 45 0c             	mov    0xc(%ebp),%eax
80105805:	89 10                	mov    %edx,(%eax)
  if(pf)
80105807:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010580b:	74 08                	je     80105815 <argfd+0x71>
    *pf = f;
8010580d:	8b 45 10             	mov    0x10(%ebp),%eax
80105810:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105813:	89 10                	mov    %edx,(%eax)
  return 0;
80105815:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010581a:	c9                   	leave  
8010581b:	c3                   	ret    

8010581c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
8010581c:	55                   	push   %ebp
8010581d:	89 e5                	mov    %esp,%ebp
8010581f:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105822:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105829:	eb 36                	jmp    80105861 <fdalloc+0x45>
    if(proc->ofile[fd] == 0){
8010582b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105831:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105834:	81 c2 90 00 00 00    	add    $0x90,%edx
8010583a:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
8010583e:	85 c0                	test   %eax,%eax
80105840:	75 1b                	jne    8010585d <fdalloc+0x41>
      proc->ofile[fd] = f;
80105842:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105848:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010584b:	8d 8a 90 00 00 00    	lea    0x90(%edx),%ecx
80105851:	8b 55 08             	mov    0x8(%ebp),%edx
80105854:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
      return fd;
80105858:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010585b:	eb 0f                	jmp    8010586c <fdalloc+0x50>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
8010585d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105861:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80105865:	7e c4                	jle    8010582b <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80105867:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010586c:	c9                   	leave  
8010586d:	c3                   	ret    

8010586e <sys_dup>:

int
sys_dup(void)
{
8010586e:	55                   	push   %ebp
8010586f:	89 e5                	mov    %esp,%ebp
80105871:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80105874:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105877:	89 44 24 08          	mov    %eax,0x8(%esp)
8010587b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105882:	00 
80105883:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010588a:	e8 15 ff ff ff       	call   801057a4 <argfd>
8010588f:	85 c0                	test   %eax,%eax
80105891:	79 07                	jns    8010589a <sys_dup+0x2c>
    return -1;
80105893:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105898:	eb 29                	jmp    801058c3 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
8010589a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010589d:	89 04 24             	mov    %eax,(%esp)
801058a0:	e8 77 ff ff ff       	call   8010581c <fdalloc>
801058a5:	89 45 f4             	mov    %eax,-0xc(%ebp)
801058a8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801058ac:	79 07                	jns    801058b5 <sys_dup+0x47>
    return -1;
801058ae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801058b3:	eb 0e                	jmp    801058c3 <sys_dup+0x55>
  filedup(f);
801058b5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801058b8:	89 04 24             	mov    %eax,(%esp)
801058bb:	e8 f4 b6 ff ff       	call   80100fb4 <filedup>
  return fd;
801058c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801058c3:	c9                   	leave  
801058c4:	c3                   	ret    

801058c5 <sys_read>:

int
sys_read(void)
{
801058c5:	55                   	push   %ebp
801058c6:	89 e5                	mov    %esp,%ebp
801058c8:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801058cb:	8d 45 f4             	lea    -0xc(%ebp),%eax
801058ce:	89 44 24 08          	mov    %eax,0x8(%esp)
801058d2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801058d9:	00 
801058da:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801058e1:	e8 be fe ff ff       	call   801057a4 <argfd>
801058e6:	85 c0                	test   %eax,%eax
801058e8:	78 35                	js     8010591f <sys_read+0x5a>
801058ea:	8d 45 f0             	lea    -0x10(%ebp),%eax
801058ed:	89 44 24 04          	mov    %eax,0x4(%esp)
801058f1:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801058f8:	e8 4d fd ff ff       	call   8010564a <argint>
801058fd:	85 c0                	test   %eax,%eax
801058ff:	78 1e                	js     8010591f <sys_read+0x5a>
80105901:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105904:	89 44 24 08          	mov    %eax,0x8(%esp)
80105908:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010590b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010590f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105916:	e8 5d fd ff ff       	call   80105678 <argptr>
8010591b:	85 c0                	test   %eax,%eax
8010591d:	79 07                	jns    80105926 <sys_read+0x61>
    return -1;
8010591f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105924:	eb 19                	jmp    8010593f <sys_read+0x7a>
  return fileread(f, p, n);
80105926:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105929:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010592c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010592f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105933:	89 54 24 04          	mov    %edx,0x4(%esp)
80105937:	89 04 24             	mov    %eax,(%esp)
8010593a:	e8 e2 b7 ff ff       	call   80101121 <fileread>
}
8010593f:	c9                   	leave  
80105940:	c3                   	ret    

80105941 <sys_write>:

int
sys_write(void)
{
80105941:	55                   	push   %ebp
80105942:	89 e5                	mov    %esp,%ebp
80105944:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105947:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010594a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010594e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105955:	00 
80105956:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010595d:	e8 42 fe ff ff       	call   801057a4 <argfd>
80105962:	85 c0                	test   %eax,%eax
80105964:	78 35                	js     8010599b <sys_write+0x5a>
80105966:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105969:	89 44 24 04          	mov    %eax,0x4(%esp)
8010596d:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105974:	e8 d1 fc ff ff       	call   8010564a <argint>
80105979:	85 c0                	test   %eax,%eax
8010597b:	78 1e                	js     8010599b <sys_write+0x5a>
8010597d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105980:	89 44 24 08          	mov    %eax,0x8(%esp)
80105984:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105987:	89 44 24 04          	mov    %eax,0x4(%esp)
8010598b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105992:	e8 e1 fc ff ff       	call   80105678 <argptr>
80105997:	85 c0                	test   %eax,%eax
80105999:	79 07                	jns    801059a2 <sys_write+0x61>
    return -1;
8010599b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801059a0:	eb 19                	jmp    801059bb <sys_write+0x7a>
  return filewrite(f, p, n);
801059a2:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801059a5:	8b 55 ec             	mov    -0x14(%ebp),%edx
801059a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059ab:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801059af:	89 54 24 04          	mov    %edx,0x4(%esp)
801059b3:	89 04 24             	mov    %eax,(%esp)
801059b6:	e8 22 b8 ff ff       	call   801011dd <filewrite>
}
801059bb:	c9                   	leave  
801059bc:	c3                   	ret    

801059bd <sys_close>:

int
sys_close(void)
{
801059bd:	55                   	push   %ebp
801059be:	89 e5                	mov    %esp,%ebp
801059c0:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
801059c3:	8d 45 f0             	lea    -0x10(%ebp),%eax
801059c6:	89 44 24 08          	mov    %eax,0x8(%esp)
801059ca:	8d 45 f4             	lea    -0xc(%ebp),%eax
801059cd:	89 44 24 04          	mov    %eax,0x4(%esp)
801059d1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801059d8:	e8 c7 fd ff ff       	call   801057a4 <argfd>
801059dd:	85 c0                	test   %eax,%eax
801059df:	79 07                	jns    801059e8 <sys_close+0x2b>
    return -1;
801059e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801059e6:	eb 27                	jmp    80105a0f <sys_close+0x52>
  proc->ofile[fd] = 0;
801059e8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801059ee:	8b 55 f4             	mov    -0xc(%ebp),%edx
801059f1:	81 c2 90 00 00 00    	add    $0x90,%edx
801059f7:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
801059fe:	00 
  fileclose(f);
801059ff:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a02:	89 04 24             	mov    %eax,(%esp)
80105a05:	e8 f2 b5 ff ff       	call   80100ffc <fileclose>
  return 0;
80105a0a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105a0f:	c9                   	leave  
80105a10:	c3                   	ret    

80105a11 <sys_fstat>:

int
sys_fstat(void)
{
80105a11:	55                   	push   %ebp
80105a12:	89 e5                	mov    %esp,%ebp
80105a14:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80105a17:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105a1a:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a1e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105a25:	00 
80105a26:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105a2d:	e8 72 fd ff ff       	call   801057a4 <argfd>
80105a32:	85 c0                	test   %eax,%eax
80105a34:	78 1f                	js     80105a55 <sys_fstat+0x44>
80105a36:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80105a3d:	00 
80105a3e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105a41:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a45:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105a4c:	e8 27 fc ff ff       	call   80105678 <argptr>
80105a51:	85 c0                	test   %eax,%eax
80105a53:	79 07                	jns    80105a5c <sys_fstat+0x4b>
    return -1;
80105a55:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a5a:	eb 12                	jmp    80105a6e <sys_fstat+0x5d>
  return filestat(f, st);
80105a5c:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105a5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a62:	89 54 24 04          	mov    %edx,0x4(%esp)
80105a66:	89 04 24             	mov    %eax,(%esp)
80105a69:	e8 64 b6 ff ff       	call   801010d2 <filestat>
}
80105a6e:	c9                   	leave  
80105a6f:	c3                   	ret    

80105a70 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80105a70:	55                   	push   %ebp
80105a71:	89 e5                	mov    %esp,%ebp
80105a73:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80105a76:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105a79:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a7d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105a84:	e8 51 fc ff ff       	call   801056da <argstr>
80105a89:	85 c0                	test   %eax,%eax
80105a8b:	78 17                	js     80105aa4 <sys_link+0x34>
80105a8d:	8d 45 dc             	lea    -0x24(%ebp),%eax
80105a90:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a94:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105a9b:	e8 3a fc ff ff       	call   801056da <argstr>
80105aa0:	85 c0                	test   %eax,%eax
80105aa2:	79 0a                	jns    80105aae <sys_link+0x3e>
    return -1;
80105aa4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105aa9:	e9 41 01 00 00       	jmp    80105bef <sys_link+0x17f>

  begin_op();
80105aae:	e8 de d9 ff ff       	call   80103491 <begin_op>
  if((ip = namei(old)) == 0){
80105ab3:	8b 45 d8             	mov    -0x28(%ebp),%eax
80105ab6:	89 04 24             	mov    %eax,(%esp)
80105ab9:	e8 87 c9 ff ff       	call   80102445 <namei>
80105abe:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105ac1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105ac5:	75 0f                	jne    80105ad6 <sys_link+0x66>
    end_op();
80105ac7:	e8 46 da ff ff       	call   80103512 <end_op>
    return -1;
80105acc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ad1:	e9 19 01 00 00       	jmp    80105bef <sys_link+0x17f>
  }

  ilock(ip);
80105ad6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ad9:	89 04 24             	mov    %eax,(%esp)
80105adc:	e8 bf bd ff ff       	call   801018a0 <ilock>
  if(ip->type == T_DIR){
80105ae1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ae4:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105ae8:	66 83 f8 01          	cmp    $0x1,%ax
80105aec:	75 1a                	jne    80105b08 <sys_link+0x98>
    iunlockput(ip);
80105aee:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105af1:	89 04 24             	mov    %eax,(%esp)
80105af4:	e8 2b c0 ff ff       	call   80101b24 <iunlockput>
    end_op();
80105af9:	e8 14 da ff ff       	call   80103512 <end_op>
    return -1;
80105afe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b03:	e9 e7 00 00 00       	jmp    80105bef <sys_link+0x17f>
  }

  ip->nlink++;
80105b08:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b0b:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105b0f:	8d 50 01             	lea    0x1(%eax),%edx
80105b12:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b15:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105b19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b1c:	89 04 24             	mov    %eax,(%esp)
80105b1f:	e8 c0 bb ff ff       	call   801016e4 <iupdate>
  iunlock(ip);
80105b24:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b27:	89 04 24             	mov    %eax,(%esp)
80105b2a:	e8 bf be ff ff       	call   801019ee <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80105b2f:	8b 45 dc             	mov    -0x24(%ebp),%eax
80105b32:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80105b35:	89 54 24 04          	mov    %edx,0x4(%esp)
80105b39:	89 04 24             	mov    %eax,(%esp)
80105b3c:	e8 26 c9 ff ff       	call   80102467 <nameiparent>
80105b41:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105b44:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105b48:	74 68                	je     80105bb2 <sys_link+0x142>
    goto bad;
  ilock(dp);
80105b4a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b4d:	89 04 24             	mov    %eax,(%esp)
80105b50:	e8 4b bd ff ff       	call   801018a0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80105b55:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b58:	8b 10                	mov    (%eax),%edx
80105b5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b5d:	8b 00                	mov    (%eax),%eax
80105b5f:	39 c2                	cmp    %eax,%edx
80105b61:	75 20                	jne    80105b83 <sys_link+0x113>
80105b63:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b66:	8b 40 04             	mov    0x4(%eax),%eax
80105b69:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b6d:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80105b70:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b74:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b77:	89 04 24             	mov    %eax,(%esp)
80105b7a:	e8 02 c6 ff ff       	call   80102181 <dirlink>
80105b7f:	85 c0                	test   %eax,%eax
80105b81:	79 0d                	jns    80105b90 <sys_link+0x120>
    iunlockput(dp);
80105b83:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b86:	89 04 24             	mov    %eax,(%esp)
80105b89:	e8 96 bf ff ff       	call   80101b24 <iunlockput>
    goto bad;
80105b8e:	eb 23                	jmp    80105bb3 <sys_link+0x143>
  }
  iunlockput(dp);
80105b90:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b93:	89 04 24             	mov    %eax,(%esp)
80105b96:	e8 89 bf ff ff       	call   80101b24 <iunlockput>
  iput(ip);
80105b9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b9e:	89 04 24             	mov    %eax,(%esp)
80105ba1:	e8 ad be ff ff       	call   80101a53 <iput>

  end_op();
80105ba6:	e8 67 d9 ff ff       	call   80103512 <end_op>

  return 0;
80105bab:	b8 00 00 00 00       	mov    $0x0,%eax
80105bb0:	eb 3d                	jmp    80105bef <sys_link+0x17f>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
80105bb2:	90                   	nop
  end_op();

  return 0;

bad:
  ilock(ip);
80105bb3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bb6:	89 04 24             	mov    %eax,(%esp)
80105bb9:	e8 e2 bc ff ff       	call   801018a0 <ilock>
  ip->nlink--;
80105bbe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bc1:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105bc5:	8d 50 ff             	lea    -0x1(%eax),%edx
80105bc8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bcb:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105bcf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bd2:	89 04 24             	mov    %eax,(%esp)
80105bd5:	e8 0a bb ff ff       	call   801016e4 <iupdate>
  iunlockput(ip);
80105bda:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bdd:	89 04 24             	mov    %eax,(%esp)
80105be0:	e8 3f bf ff ff       	call   80101b24 <iunlockput>
  end_op();
80105be5:	e8 28 d9 ff ff       	call   80103512 <end_op>
  return -1;
80105bea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105bef:	c9                   	leave  
80105bf0:	c3                   	ret    

80105bf1 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80105bf1:	55                   	push   %ebp
80105bf2:	89 e5                	mov    %esp,%ebp
80105bf4:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105bf7:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80105bfe:	eb 4b                	jmp    80105c4b <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105c00:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c03:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105c0a:	00 
80105c0b:	89 44 24 08          	mov    %eax,0x8(%esp)
80105c0f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105c12:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c16:	8b 45 08             	mov    0x8(%ebp),%eax
80105c19:	89 04 24             	mov    %eax,(%esp)
80105c1c:	e8 75 c1 ff ff       	call   80101d96 <readi>
80105c21:	83 f8 10             	cmp    $0x10,%eax
80105c24:	74 0c                	je     80105c32 <isdirempty+0x41>
      panic("isdirempty: readi");
80105c26:	c7 04 24 bc 8a 10 80 	movl   $0x80108abc,(%esp)
80105c2d:	e8 0b a9 ff ff       	call   8010053d <panic>
    if(de.inum != 0)
80105c32:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80105c36:	66 85 c0             	test   %ax,%ax
80105c39:	74 07                	je     80105c42 <isdirempty+0x51>
      return 0;
80105c3b:	b8 00 00 00 00       	mov    $0x0,%eax
80105c40:	eb 1b                	jmp    80105c5d <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105c42:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c45:	83 c0 10             	add    $0x10,%eax
80105c48:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105c4b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105c4e:	8b 45 08             	mov    0x8(%ebp),%eax
80105c51:	8b 40 18             	mov    0x18(%eax),%eax
80105c54:	39 c2                	cmp    %eax,%edx
80105c56:	72 a8                	jb     80105c00 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80105c58:	b8 01 00 00 00       	mov    $0x1,%eax
}
80105c5d:	c9                   	leave  
80105c5e:	c3                   	ret    

80105c5f <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80105c5f:	55                   	push   %ebp
80105c60:	89 e5                	mov    %esp,%ebp
80105c62:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80105c65:	8d 45 cc             	lea    -0x34(%ebp),%eax
80105c68:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c6c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105c73:	e8 62 fa ff ff       	call   801056da <argstr>
80105c78:	85 c0                	test   %eax,%eax
80105c7a:	79 0a                	jns    80105c86 <sys_unlink+0x27>
    return -1;
80105c7c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c81:	e9 af 01 00 00       	jmp    80105e35 <sys_unlink+0x1d6>

  begin_op();
80105c86:	e8 06 d8 ff ff       	call   80103491 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80105c8b:	8b 45 cc             	mov    -0x34(%ebp),%eax
80105c8e:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80105c91:	89 54 24 04          	mov    %edx,0x4(%esp)
80105c95:	89 04 24             	mov    %eax,(%esp)
80105c98:	e8 ca c7 ff ff       	call   80102467 <nameiparent>
80105c9d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105ca0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105ca4:	75 0f                	jne    80105cb5 <sys_unlink+0x56>
    end_op();
80105ca6:	e8 67 d8 ff ff       	call   80103512 <end_op>
    return -1;
80105cab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105cb0:	e9 80 01 00 00       	jmp    80105e35 <sys_unlink+0x1d6>
  }

  ilock(dp);
80105cb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cb8:	89 04 24             	mov    %eax,(%esp)
80105cbb:	e8 e0 bb ff ff       	call   801018a0 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80105cc0:	c7 44 24 04 ce 8a 10 	movl   $0x80108ace,0x4(%esp)
80105cc7:	80 
80105cc8:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105ccb:	89 04 24             	mov    %eax,(%esp)
80105cce:	e8 c4 c3 ff ff       	call   80102097 <namecmp>
80105cd3:	85 c0                	test   %eax,%eax
80105cd5:	0f 84 45 01 00 00    	je     80105e20 <sys_unlink+0x1c1>
80105cdb:	c7 44 24 04 d0 8a 10 	movl   $0x80108ad0,0x4(%esp)
80105ce2:	80 
80105ce3:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105ce6:	89 04 24             	mov    %eax,(%esp)
80105ce9:	e8 a9 c3 ff ff       	call   80102097 <namecmp>
80105cee:	85 c0                	test   %eax,%eax
80105cf0:	0f 84 2a 01 00 00    	je     80105e20 <sys_unlink+0x1c1>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80105cf6:	8d 45 c8             	lea    -0x38(%ebp),%eax
80105cf9:	89 44 24 08          	mov    %eax,0x8(%esp)
80105cfd:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105d00:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d04:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d07:	89 04 24             	mov    %eax,(%esp)
80105d0a:	e8 aa c3 ff ff       	call   801020b9 <dirlookup>
80105d0f:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105d12:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105d16:	0f 84 03 01 00 00    	je     80105e1f <sys_unlink+0x1c0>
    goto bad;
  ilock(ip);
80105d1c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d1f:	89 04 24             	mov    %eax,(%esp)
80105d22:	e8 79 bb ff ff       	call   801018a0 <ilock>

  if(ip->nlink < 1)
80105d27:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d2a:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105d2e:	66 85 c0             	test   %ax,%ax
80105d31:	7f 0c                	jg     80105d3f <sys_unlink+0xe0>
    panic("unlink: nlink < 1");
80105d33:	c7 04 24 d3 8a 10 80 	movl   $0x80108ad3,(%esp)
80105d3a:	e8 fe a7 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80105d3f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d42:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105d46:	66 83 f8 01          	cmp    $0x1,%ax
80105d4a:	75 1f                	jne    80105d6b <sys_unlink+0x10c>
80105d4c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d4f:	89 04 24             	mov    %eax,(%esp)
80105d52:	e8 9a fe ff ff       	call   80105bf1 <isdirempty>
80105d57:	85 c0                	test   %eax,%eax
80105d59:	75 10                	jne    80105d6b <sys_unlink+0x10c>
    iunlockput(ip);
80105d5b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d5e:	89 04 24             	mov    %eax,(%esp)
80105d61:	e8 be bd ff ff       	call   80101b24 <iunlockput>
    goto bad;
80105d66:	e9 b5 00 00 00       	jmp    80105e20 <sys_unlink+0x1c1>
  }

  memset(&de, 0, sizeof(de));
80105d6b:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105d72:	00 
80105d73:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105d7a:	00 
80105d7b:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105d7e:	89 04 24             	mov    %eax,(%esp)
80105d81:	e8 68 f5 ff ff       	call   801052ee <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105d86:	8b 45 c8             	mov    -0x38(%ebp),%eax
80105d89:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105d90:	00 
80105d91:	89 44 24 08          	mov    %eax,0x8(%esp)
80105d95:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105d98:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d9c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d9f:	89 04 24             	mov    %eax,(%esp)
80105da2:	e8 5a c1 ff ff       	call   80101f01 <writei>
80105da7:	83 f8 10             	cmp    $0x10,%eax
80105daa:	74 0c                	je     80105db8 <sys_unlink+0x159>
    panic("unlink: writei");
80105dac:	c7 04 24 e5 8a 10 80 	movl   $0x80108ae5,(%esp)
80105db3:	e8 85 a7 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
80105db8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dbb:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105dbf:	66 83 f8 01          	cmp    $0x1,%ax
80105dc3:	75 1c                	jne    80105de1 <sys_unlink+0x182>
    dp->nlink--;
80105dc5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dc8:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105dcc:	8d 50 ff             	lea    -0x1(%eax),%edx
80105dcf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dd2:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105dd6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dd9:	89 04 24             	mov    %eax,(%esp)
80105ddc:	e8 03 b9 ff ff       	call   801016e4 <iupdate>
  }
  iunlockput(dp);
80105de1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105de4:	89 04 24             	mov    %eax,(%esp)
80105de7:	e8 38 bd ff ff       	call   80101b24 <iunlockput>

  ip->nlink--;
80105dec:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105def:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105df3:	8d 50 ff             	lea    -0x1(%eax),%edx
80105df6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105df9:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105dfd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e00:	89 04 24             	mov    %eax,(%esp)
80105e03:	e8 dc b8 ff ff       	call   801016e4 <iupdate>
  iunlockput(ip);
80105e08:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e0b:	89 04 24             	mov    %eax,(%esp)
80105e0e:	e8 11 bd ff ff       	call   80101b24 <iunlockput>

  end_op();
80105e13:	e8 fa d6 ff ff       	call   80103512 <end_op>

  return 0;
80105e18:	b8 00 00 00 00       	mov    $0x0,%eax
80105e1d:	eb 16                	jmp    80105e35 <sys_unlink+0x1d6>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80105e1f:	90                   	nop
  end_op();

  return 0;

bad:
  iunlockput(dp);
80105e20:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e23:	89 04 24             	mov    %eax,(%esp)
80105e26:	e8 f9 bc ff ff       	call   80101b24 <iunlockput>
  end_op();
80105e2b:	e8 e2 d6 ff ff       	call   80103512 <end_op>
  return -1;
80105e30:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105e35:	c9                   	leave  
80105e36:	c3                   	ret    

80105e37 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80105e37:	55                   	push   %ebp
80105e38:	89 e5                	mov    %esp,%ebp
80105e3a:	83 ec 48             	sub    $0x48,%esp
80105e3d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105e40:	8b 55 10             	mov    0x10(%ebp),%edx
80105e43:	8b 45 14             	mov    0x14(%ebp),%eax
80105e46:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80105e4a:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80105e4e:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80105e52:	8d 45 de             	lea    -0x22(%ebp),%eax
80105e55:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e59:	8b 45 08             	mov    0x8(%ebp),%eax
80105e5c:	89 04 24             	mov    %eax,(%esp)
80105e5f:	e8 03 c6 ff ff       	call   80102467 <nameiparent>
80105e64:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105e67:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105e6b:	75 0a                	jne    80105e77 <create+0x40>
    return 0;
80105e6d:	b8 00 00 00 00       	mov    $0x0,%eax
80105e72:	e9 7e 01 00 00       	jmp    80105ff5 <create+0x1be>
  ilock(dp);
80105e77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e7a:	89 04 24             	mov    %eax,(%esp)
80105e7d:	e8 1e ba ff ff       	call   801018a0 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80105e82:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105e85:	89 44 24 08          	mov    %eax,0x8(%esp)
80105e89:	8d 45 de             	lea    -0x22(%ebp),%eax
80105e8c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e90:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e93:	89 04 24             	mov    %eax,(%esp)
80105e96:	e8 1e c2 ff ff       	call   801020b9 <dirlookup>
80105e9b:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105e9e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105ea2:	74 47                	je     80105eeb <create+0xb4>
    iunlockput(dp);
80105ea4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ea7:	89 04 24             	mov    %eax,(%esp)
80105eaa:	e8 75 bc ff ff       	call   80101b24 <iunlockput>
    ilock(ip);
80105eaf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105eb2:	89 04 24             	mov    %eax,(%esp)
80105eb5:	e8 e6 b9 ff ff       	call   801018a0 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80105eba:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80105ebf:	75 15                	jne    80105ed6 <create+0x9f>
80105ec1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ec4:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105ec8:	66 83 f8 02          	cmp    $0x2,%ax
80105ecc:	75 08                	jne    80105ed6 <create+0x9f>
      return ip;
80105ece:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ed1:	e9 1f 01 00 00       	jmp    80105ff5 <create+0x1be>
    iunlockput(ip);
80105ed6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ed9:	89 04 24             	mov    %eax,(%esp)
80105edc:	e8 43 bc ff ff       	call   80101b24 <iunlockput>
    return 0;
80105ee1:	b8 00 00 00 00       	mov    $0x0,%eax
80105ee6:	e9 0a 01 00 00       	jmp    80105ff5 <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80105eeb:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80105eef:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ef2:	8b 00                	mov    (%eax),%eax
80105ef4:	89 54 24 04          	mov    %edx,0x4(%esp)
80105ef8:	89 04 24             	mov    %eax,(%esp)
80105efb:	e8 07 b7 ff ff       	call   80101607 <ialloc>
80105f00:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105f03:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105f07:	75 0c                	jne    80105f15 <create+0xde>
    panic("create: ialloc");
80105f09:	c7 04 24 f4 8a 10 80 	movl   $0x80108af4,(%esp)
80105f10:	e8 28 a6 ff ff       	call   8010053d <panic>

  ilock(ip);
80105f15:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f18:	89 04 24             	mov    %eax,(%esp)
80105f1b:	e8 80 b9 ff ff       	call   801018a0 <ilock>
  ip->major = major;
80105f20:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f23:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80105f27:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80105f2b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f2e:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80105f32:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80105f36:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f39:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80105f3f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f42:	89 04 24             	mov    %eax,(%esp)
80105f45:	e8 9a b7 ff ff       	call   801016e4 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80105f4a:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80105f4f:	75 6a                	jne    80105fbb <create+0x184>
    dp->nlink++;  // for ".."
80105f51:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f54:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105f58:	8d 50 01             	lea    0x1(%eax),%edx
80105f5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f5e:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105f62:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f65:	89 04 24             	mov    %eax,(%esp)
80105f68:	e8 77 b7 ff ff       	call   801016e4 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80105f6d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f70:	8b 40 04             	mov    0x4(%eax),%eax
80105f73:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f77:	c7 44 24 04 ce 8a 10 	movl   $0x80108ace,0x4(%esp)
80105f7e:	80 
80105f7f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f82:	89 04 24             	mov    %eax,(%esp)
80105f85:	e8 f7 c1 ff ff       	call   80102181 <dirlink>
80105f8a:	85 c0                	test   %eax,%eax
80105f8c:	78 21                	js     80105faf <create+0x178>
80105f8e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f91:	8b 40 04             	mov    0x4(%eax),%eax
80105f94:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f98:	c7 44 24 04 d0 8a 10 	movl   $0x80108ad0,0x4(%esp)
80105f9f:	80 
80105fa0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fa3:	89 04 24             	mov    %eax,(%esp)
80105fa6:	e8 d6 c1 ff ff       	call   80102181 <dirlink>
80105fab:	85 c0                	test   %eax,%eax
80105fad:	79 0c                	jns    80105fbb <create+0x184>
      panic("create dots");
80105faf:	c7 04 24 03 8b 10 80 	movl   $0x80108b03,(%esp)
80105fb6:	e8 82 a5 ff ff       	call   8010053d <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80105fbb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fbe:	8b 40 04             	mov    0x4(%eax),%eax
80105fc1:	89 44 24 08          	mov    %eax,0x8(%esp)
80105fc5:	8d 45 de             	lea    -0x22(%ebp),%eax
80105fc8:	89 44 24 04          	mov    %eax,0x4(%esp)
80105fcc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fcf:	89 04 24             	mov    %eax,(%esp)
80105fd2:	e8 aa c1 ff ff       	call   80102181 <dirlink>
80105fd7:	85 c0                	test   %eax,%eax
80105fd9:	79 0c                	jns    80105fe7 <create+0x1b0>
    panic("create: dirlink");
80105fdb:	c7 04 24 0f 8b 10 80 	movl   $0x80108b0f,(%esp)
80105fe2:	e8 56 a5 ff ff       	call   8010053d <panic>

  iunlockput(dp);
80105fe7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fea:	89 04 24             	mov    %eax,(%esp)
80105fed:	e8 32 bb ff ff       	call   80101b24 <iunlockput>

  return ip;
80105ff2:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80105ff5:	c9                   	leave  
80105ff6:	c3                   	ret    

80105ff7 <sys_open>:

int
sys_open(void)
{
80105ff7:	55                   	push   %ebp
80105ff8:	89 e5                	mov    %esp,%ebp
80105ffa:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80105ffd:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106000:	89 44 24 04          	mov    %eax,0x4(%esp)
80106004:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010600b:	e8 ca f6 ff ff       	call   801056da <argstr>
80106010:	85 c0                	test   %eax,%eax
80106012:	78 17                	js     8010602b <sys_open+0x34>
80106014:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106017:	89 44 24 04          	mov    %eax,0x4(%esp)
8010601b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106022:	e8 23 f6 ff ff       	call   8010564a <argint>
80106027:	85 c0                	test   %eax,%eax
80106029:	79 0a                	jns    80106035 <sys_open+0x3e>
    return -1;
8010602b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106030:	e9 5a 01 00 00       	jmp    8010618f <sys_open+0x198>

  begin_op();
80106035:	e8 57 d4 ff ff       	call   80103491 <begin_op>

  if(omode & O_CREATE){
8010603a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010603d:	25 00 02 00 00       	and    $0x200,%eax
80106042:	85 c0                	test   %eax,%eax
80106044:	74 3b                	je     80106081 <sys_open+0x8a>
    ip = create(path, T_FILE, 0, 0);
80106046:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106049:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106050:	00 
80106051:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106058:	00 
80106059:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106060:	00 
80106061:	89 04 24             	mov    %eax,(%esp)
80106064:	e8 ce fd ff ff       	call   80105e37 <create>
80106069:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
8010606c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106070:	75 6b                	jne    801060dd <sys_open+0xe6>
      end_op();
80106072:	e8 9b d4 ff ff       	call   80103512 <end_op>
      return -1;
80106077:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010607c:	e9 0e 01 00 00       	jmp    8010618f <sys_open+0x198>
    }
  } else {
    if((ip = namei(path)) == 0){
80106081:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106084:	89 04 24             	mov    %eax,(%esp)
80106087:	e8 b9 c3 ff ff       	call   80102445 <namei>
8010608c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010608f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106093:	75 0f                	jne    801060a4 <sys_open+0xad>
      end_op();
80106095:	e8 78 d4 ff ff       	call   80103512 <end_op>
      return -1;
8010609a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010609f:	e9 eb 00 00 00       	jmp    8010618f <sys_open+0x198>
    }
    ilock(ip);
801060a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060a7:	89 04 24             	mov    %eax,(%esp)
801060aa:	e8 f1 b7 ff ff       	call   801018a0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
801060af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060b2:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801060b6:	66 83 f8 01          	cmp    $0x1,%ax
801060ba:	75 21                	jne    801060dd <sys_open+0xe6>
801060bc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801060bf:	85 c0                	test   %eax,%eax
801060c1:	74 1a                	je     801060dd <sys_open+0xe6>
      iunlockput(ip);
801060c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060c6:	89 04 24             	mov    %eax,(%esp)
801060c9:	e8 56 ba ff ff       	call   80101b24 <iunlockput>
      end_op();
801060ce:	e8 3f d4 ff ff       	call   80103512 <end_op>
      return -1;
801060d3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060d8:	e9 b2 00 00 00       	jmp    8010618f <sys_open+0x198>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
801060dd:	e8 72 ae ff ff       	call   80100f54 <filealloc>
801060e2:	89 45 f0             	mov    %eax,-0x10(%ebp)
801060e5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801060e9:	74 14                	je     801060ff <sys_open+0x108>
801060eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060ee:	89 04 24             	mov    %eax,(%esp)
801060f1:	e8 26 f7 ff ff       	call   8010581c <fdalloc>
801060f6:	89 45 ec             	mov    %eax,-0x14(%ebp)
801060f9:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801060fd:	79 28                	jns    80106127 <sys_open+0x130>
    if(f)
801060ff:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106103:	74 0b                	je     80106110 <sys_open+0x119>
      fileclose(f);
80106105:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106108:	89 04 24             	mov    %eax,(%esp)
8010610b:	e8 ec ae ff ff       	call   80100ffc <fileclose>
    iunlockput(ip);
80106110:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106113:	89 04 24             	mov    %eax,(%esp)
80106116:	e8 09 ba ff ff       	call   80101b24 <iunlockput>
    end_op();
8010611b:	e8 f2 d3 ff ff       	call   80103512 <end_op>
    return -1;
80106120:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106125:	eb 68                	jmp    8010618f <sys_open+0x198>
  }
  iunlock(ip);
80106127:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010612a:	89 04 24             	mov    %eax,(%esp)
8010612d:	e8 bc b8 ff ff       	call   801019ee <iunlock>
  end_op();
80106132:	e8 db d3 ff ff       	call   80103512 <end_op>

  f->type = FD_INODE;
80106137:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010613a:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106140:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106143:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106146:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106149:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010614c:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106153:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106156:	83 e0 01             	and    $0x1,%eax
80106159:	85 c0                	test   %eax,%eax
8010615b:	0f 94 c2             	sete   %dl
8010615e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106161:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106164:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106167:	83 e0 01             	and    $0x1,%eax
8010616a:	84 c0                	test   %al,%al
8010616c:	75 0a                	jne    80106178 <sys_open+0x181>
8010616e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106171:	83 e0 02             	and    $0x2,%eax
80106174:	85 c0                	test   %eax,%eax
80106176:	74 07                	je     8010617f <sys_open+0x188>
80106178:	b8 01 00 00 00       	mov    $0x1,%eax
8010617d:	eb 05                	jmp    80106184 <sys_open+0x18d>
8010617f:	b8 00 00 00 00       	mov    $0x0,%eax
80106184:	89 c2                	mov    %eax,%edx
80106186:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106189:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
8010618c:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
8010618f:	c9                   	leave  
80106190:	c3                   	ret    

80106191 <sys_mkdir>:

int
sys_mkdir(void)
{
80106191:	55                   	push   %ebp
80106192:	89 e5                	mov    %esp,%ebp
80106194:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80106197:	e8 f5 d2 ff ff       	call   80103491 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
8010619c:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010619f:	89 44 24 04          	mov    %eax,0x4(%esp)
801061a3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801061aa:	e8 2b f5 ff ff       	call   801056da <argstr>
801061af:	85 c0                	test   %eax,%eax
801061b1:	78 2c                	js     801061df <sys_mkdir+0x4e>
801061b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061b6:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801061bd:	00 
801061be:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801061c5:	00 
801061c6:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801061cd:	00 
801061ce:	89 04 24             	mov    %eax,(%esp)
801061d1:	e8 61 fc ff ff       	call   80105e37 <create>
801061d6:	89 45 f4             	mov    %eax,-0xc(%ebp)
801061d9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801061dd:	75 0c                	jne    801061eb <sys_mkdir+0x5a>
    end_op();
801061df:	e8 2e d3 ff ff       	call   80103512 <end_op>
    return -1;
801061e4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061e9:	eb 15                	jmp    80106200 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
801061eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061ee:	89 04 24             	mov    %eax,(%esp)
801061f1:	e8 2e b9 ff ff       	call   80101b24 <iunlockput>
  end_op();
801061f6:	e8 17 d3 ff ff       	call   80103512 <end_op>
  return 0;
801061fb:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106200:	c9                   	leave  
80106201:	c3                   	ret    

80106202 <sys_mknod>:

int
sys_mknod(void)
{
80106202:	55                   	push   %ebp
80106203:	89 e5                	mov    %esp,%ebp
80106205:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_op();
80106208:	e8 84 d2 ff ff       	call   80103491 <begin_op>
  if((len=argstr(0, &path)) < 0 ||
8010620d:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106210:	89 44 24 04          	mov    %eax,0x4(%esp)
80106214:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010621b:	e8 ba f4 ff ff       	call   801056da <argstr>
80106220:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106223:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106227:	78 5e                	js     80106287 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80106229:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010622c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106230:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106237:	e8 0e f4 ff ff       	call   8010564a <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
8010623c:	85 c0                	test   %eax,%eax
8010623e:	78 47                	js     80106287 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106240:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106243:	89 44 24 04          	mov    %eax,0x4(%esp)
80106247:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010624e:	e8 f7 f3 ff ff       	call   8010564a <argint>
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80106253:	85 c0                	test   %eax,%eax
80106255:	78 30                	js     80106287 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80106257:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010625a:	0f bf c8             	movswl %ax,%ecx
8010625d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106260:	0f bf d0             	movswl %ax,%edx
80106263:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106266:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010626a:	89 54 24 08          	mov    %edx,0x8(%esp)
8010626e:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106275:	00 
80106276:	89 04 24             	mov    %eax,(%esp)
80106279:	e8 b9 fb ff ff       	call   80105e37 <create>
8010627e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106281:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106285:	75 0c                	jne    80106293 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
80106287:	e8 86 d2 ff ff       	call   80103512 <end_op>
    return -1;
8010628c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106291:	eb 15                	jmp    801062a8 <sys_mknod+0xa6>
  }
  iunlockput(ip);
80106293:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106296:	89 04 24             	mov    %eax,(%esp)
80106299:	e8 86 b8 ff ff       	call   80101b24 <iunlockput>
  end_op();
8010629e:	e8 6f d2 ff ff       	call   80103512 <end_op>
  return 0;
801062a3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801062a8:	c9                   	leave  
801062a9:	c3                   	ret    

801062aa <sys_chdir>:

int
sys_chdir(void)
{
801062aa:	55                   	push   %ebp
801062ab:	89 e5                	mov    %esp,%ebp
801062ad:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
801062b0:	e8 dc d1 ff ff       	call   80103491 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
801062b5:	8d 45 f0             	lea    -0x10(%ebp),%eax
801062b8:	89 44 24 04          	mov    %eax,0x4(%esp)
801062bc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801062c3:	e8 12 f4 ff ff       	call   801056da <argstr>
801062c8:	85 c0                	test   %eax,%eax
801062ca:	78 14                	js     801062e0 <sys_chdir+0x36>
801062cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062cf:	89 04 24             	mov    %eax,(%esp)
801062d2:	e8 6e c1 ff ff       	call   80102445 <namei>
801062d7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801062da:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801062de:	75 0c                	jne    801062ec <sys_chdir+0x42>
    end_op();
801062e0:	e8 2d d2 ff ff       	call   80103512 <end_op>
    return -1;
801062e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062ea:	eb 67                	jmp    80106353 <sys_chdir+0xa9>
  }
  ilock(ip);
801062ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062ef:	89 04 24             	mov    %eax,(%esp)
801062f2:	e8 a9 b5 ff ff       	call   801018a0 <ilock>
  if(ip->type != T_DIR){
801062f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062fa:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801062fe:	66 83 f8 01          	cmp    $0x1,%ax
80106302:	74 17                	je     8010631b <sys_chdir+0x71>
    iunlockput(ip);
80106304:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106307:	89 04 24             	mov    %eax,(%esp)
8010630a:	e8 15 b8 ff ff       	call   80101b24 <iunlockput>
    end_op();
8010630f:	e8 fe d1 ff ff       	call   80103512 <end_op>
    return -1;
80106314:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106319:	eb 38                	jmp    80106353 <sys_chdir+0xa9>
  }
  iunlock(ip);
8010631b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010631e:	89 04 24             	mov    %eax,(%esp)
80106321:	e8 c8 b6 ff ff       	call   801019ee <iunlock>
  iput(proc->cwd);
80106326:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010632c:	8b 80 8c 02 00 00    	mov    0x28c(%eax),%eax
80106332:	89 04 24             	mov    %eax,(%esp)
80106335:	e8 19 b7 ff ff       	call   80101a53 <iput>
  end_op();
8010633a:	e8 d3 d1 ff ff       	call   80103512 <end_op>
  proc->cwd = ip;
8010633f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106345:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106348:	89 90 8c 02 00 00    	mov    %edx,0x28c(%eax)
  return 0;
8010634e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106353:	c9                   	leave  
80106354:	c3                   	ret    

80106355 <sys_exec>:

int
sys_exec(void)
{
80106355:	55                   	push   %ebp
80106356:	89 e5                	mov    %esp,%ebp
80106358:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
8010635e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106361:	89 44 24 04          	mov    %eax,0x4(%esp)
80106365:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010636c:	e8 69 f3 ff ff       	call   801056da <argstr>
80106371:	85 c0                	test   %eax,%eax
80106373:	78 1a                	js     8010638f <sys_exec+0x3a>
80106375:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
8010637b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010637f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106386:	e8 bf f2 ff ff       	call   8010564a <argint>
8010638b:	85 c0                	test   %eax,%eax
8010638d:	79 0a                	jns    80106399 <sys_exec+0x44>
    return -1;
8010638f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106394:	e9 cc 00 00 00       	jmp    80106465 <sys_exec+0x110>
  }
  memset(argv, 0, sizeof(argv));
80106399:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801063a0:	00 
801063a1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801063a8:	00 
801063a9:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
801063af:	89 04 24             	mov    %eax,(%esp)
801063b2:	e8 37 ef ff ff       	call   801052ee <memset>
  for(i=0;; i++){
801063b7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
801063be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063c1:	83 f8 1f             	cmp    $0x1f,%eax
801063c4:	76 0a                	jbe    801063d0 <sys_exec+0x7b>
      return -1;
801063c6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063cb:	e9 95 00 00 00       	jmp    80106465 <sys_exec+0x110>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
801063d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063d3:	c1 e0 02             	shl    $0x2,%eax
801063d6:	89 c2                	mov    %eax,%edx
801063d8:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
801063de:	01 c2                	add    %eax,%edx
801063e0:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
801063e6:	89 44 24 04          	mov    %eax,0x4(%esp)
801063ea:	89 14 24             	mov    %edx,(%esp)
801063ed:	e8 ba f1 ff ff       	call   801055ac <fetchint>
801063f2:	85 c0                	test   %eax,%eax
801063f4:	79 07                	jns    801063fd <sys_exec+0xa8>
      return -1;
801063f6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063fb:	eb 68                	jmp    80106465 <sys_exec+0x110>
    if(uarg == 0){
801063fd:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106403:	85 c0                	test   %eax,%eax
80106405:	75 26                	jne    8010642d <sys_exec+0xd8>
      argv[i] = 0;
80106407:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010640a:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106411:	00 00 00 00 
      break;
80106415:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106416:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106419:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
8010641f:	89 54 24 04          	mov    %edx,0x4(%esp)
80106423:	89 04 24             	mov    %eax,(%esp)
80106426:	e8 d5 a6 ff ff       	call   80100b00 <exec>
8010642b:	eb 38                	jmp    80106465 <sys_exec+0x110>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
8010642d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106430:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80106437:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
8010643d:	01 c2                	add    %eax,%edx
8010643f:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106445:	89 54 24 04          	mov    %edx,0x4(%esp)
80106449:	89 04 24             	mov    %eax,(%esp)
8010644c:	e8 95 f1 ff ff       	call   801055e6 <fetchstr>
80106451:	85 c0                	test   %eax,%eax
80106453:	79 07                	jns    8010645c <sys_exec+0x107>
      return -1;
80106455:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010645a:	eb 09                	jmp    80106465 <sys_exec+0x110>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
8010645c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
80106460:	e9 59 ff ff ff       	jmp    801063be <sys_exec+0x69>
  return exec(path, argv);
}
80106465:	c9                   	leave  
80106466:	c3                   	ret    

80106467 <sys_pipe>:

int
sys_pipe(void)
{
80106467:	55                   	push   %ebp
80106468:	89 e5                	mov    %esp,%ebp
8010646a:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
8010646d:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80106474:	00 
80106475:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106478:	89 44 24 04          	mov    %eax,0x4(%esp)
8010647c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106483:	e8 f0 f1 ff ff       	call   80105678 <argptr>
80106488:	85 c0                	test   %eax,%eax
8010648a:	79 0a                	jns    80106496 <sys_pipe+0x2f>
    return -1;
8010648c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106491:	e9 a1 00 00 00       	jmp    80106537 <sys_pipe+0xd0>
  if(pipealloc(&rf, &wf) < 0)
80106496:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106499:	89 44 24 04          	mov    %eax,0x4(%esp)
8010649d:	8d 45 e8             	lea    -0x18(%ebp),%eax
801064a0:	89 04 24             	mov    %eax,(%esp)
801064a3:	e8 18 db ff ff       	call   80103fc0 <pipealloc>
801064a8:	85 c0                	test   %eax,%eax
801064aa:	79 0a                	jns    801064b6 <sys_pipe+0x4f>
    return -1;
801064ac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064b1:	e9 81 00 00 00       	jmp    80106537 <sys_pipe+0xd0>
  fd0 = -1;
801064b6:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
801064bd:	8b 45 e8             	mov    -0x18(%ebp),%eax
801064c0:	89 04 24             	mov    %eax,(%esp)
801064c3:	e8 54 f3 ff ff       	call   8010581c <fdalloc>
801064c8:	89 45 f4             	mov    %eax,-0xc(%ebp)
801064cb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801064cf:	78 14                	js     801064e5 <sys_pipe+0x7e>
801064d1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801064d4:	89 04 24             	mov    %eax,(%esp)
801064d7:	e8 40 f3 ff ff       	call   8010581c <fdalloc>
801064dc:	89 45 f0             	mov    %eax,-0x10(%ebp)
801064df:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801064e3:	79 3a                	jns    8010651f <sys_pipe+0xb8>
    if(fd0 >= 0)
801064e5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801064e9:	78 17                	js     80106502 <sys_pipe+0x9b>
      proc->ofile[fd0] = 0;
801064eb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064f1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801064f4:	81 c2 90 00 00 00    	add    $0x90,%edx
801064fa:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80106501:	00 
    fileclose(rf);
80106502:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106505:	89 04 24             	mov    %eax,(%esp)
80106508:	e8 ef aa ff ff       	call   80100ffc <fileclose>
    fileclose(wf);
8010650d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106510:	89 04 24             	mov    %eax,(%esp)
80106513:	e8 e4 aa ff ff       	call   80100ffc <fileclose>
    return -1;
80106518:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010651d:	eb 18                	jmp    80106537 <sys_pipe+0xd0>
  }
  fd[0] = fd0;
8010651f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106522:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106525:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80106527:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010652a:	8d 50 04             	lea    0x4(%eax),%edx
8010652d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106530:	89 02                	mov    %eax,(%edx)
  return 0;
80106532:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106537:	c9                   	leave  
80106538:	c3                   	ret    
80106539:	00 00                	add    %al,(%eax)
	...

8010653c <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
8010653c:	55                   	push   %ebp
8010653d:	89 e5                	mov    %esp,%ebp
8010653f:	83 ec 08             	sub    $0x8,%esp
  return fork();
80106542:	e8 b6 e1 ff ff       	call   801046fd <fork>
}
80106547:	c9                   	leave  
80106548:	c3                   	ret    

80106549 <sys_exit>:

int
sys_exit(void)
{
80106549:	55                   	push   %ebp
8010654a:	89 e5                	mov    %esp,%ebp
8010654c:	83 ec 08             	sub    $0x8,%esp
  exit();
8010654f:	e8 5d e3 ff ff       	call   801048b1 <exit>
  return 0;  // not reached
80106554:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106559:	c9                   	leave  
8010655a:	c3                   	ret    

8010655b <sys_wait>:

int
sys_wait(void)
{
8010655b:	55                   	push   %ebp
8010655c:	89 e5                	mov    %esp,%ebp
8010655e:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106561:	e8 7f e4 ff ff       	call   801049e5 <wait>
}
80106566:	c9                   	leave  
80106567:	c3                   	ret    

80106568 <sys_kill>:

int
sys_kill(void)
{
80106568:	55                   	push   %ebp
80106569:	89 e5                	mov    %esp,%ebp
8010656b:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
8010656e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106571:	89 44 24 04          	mov    %eax,0x4(%esp)
80106575:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010657c:	e8 c9 f0 ff ff       	call   8010564a <argint>
80106581:	85 c0                	test   %eax,%eax
80106583:	79 07                	jns    8010658c <sys_kill+0x24>
    return -1;
80106585:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010658a:	eb 0b                	jmp    80106597 <sys_kill+0x2f>
  return kill(pid);
8010658c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010658f:	89 04 24             	mov    %eax,(%esp)
80106592:	e8 ec e8 ff ff       	call   80104e83 <kill>
}
80106597:	c9                   	leave  
80106598:	c3                   	ret    

80106599 <sys_getpid>:

int
sys_getpid(void)
{
80106599:	55                   	push   %ebp
8010659a:	89 e5                	mov    %esp,%ebp
  return proc->pid;
8010659c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801065a2:	8b 40 0c             	mov    0xc(%eax),%eax
}
801065a5:	5d                   	pop    %ebp
801065a6:	c3                   	ret    

801065a7 <sys_sbrk>:

int
sys_sbrk(void)
{
801065a7:	55                   	push   %ebp
801065a8:	89 e5                	mov    %esp,%ebp
801065aa:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
801065ad:	8d 45 f0             	lea    -0x10(%ebp),%eax
801065b0:	89 44 24 04          	mov    %eax,0x4(%esp)
801065b4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801065bb:	e8 8a f0 ff ff       	call   8010564a <argint>
801065c0:	85 c0                	test   %eax,%eax
801065c2:	79 07                	jns    801065cb <sys_sbrk+0x24>
    return -1;
801065c4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065c9:	eb 24                	jmp    801065ef <sys_sbrk+0x48>
  addr = proc->sz;
801065cb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801065d1:	8b 00                	mov    (%eax),%eax
801065d3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
801065d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065d9:	89 04 24             	mov    %eax,(%esp)
801065dc:	e8 55 e0 ff ff       	call   80104636 <growproc>
801065e1:	85 c0                	test   %eax,%eax
801065e3:	79 07                	jns    801065ec <sys_sbrk+0x45>
    return -1;
801065e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065ea:	eb 03                	jmp    801065ef <sys_sbrk+0x48>
  return addr;
801065ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801065ef:	c9                   	leave  
801065f0:	c3                   	ret    

801065f1 <sys_sleep>:

int
sys_sleep(void)
{
801065f1:	55                   	push   %ebp
801065f2:	89 e5                	mov    %esp,%ebp
801065f4:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
801065f7:	8d 45 f0             	lea    -0x10(%ebp),%eax
801065fa:	89 44 24 04          	mov    %eax,0x4(%esp)
801065fe:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106605:	e8 40 f0 ff ff       	call   8010564a <argint>
8010660a:	85 c0                	test   %eax,%eax
8010660c:	79 07                	jns    80106615 <sys_sleep+0x24>
    return -1;
8010660e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106613:	eb 6f                	jmp    80106684 <sys_sleep+0x93>
  acquire(&tickslock);
80106615:	c7 04 24 a0 d2 11 80 	movl   $0x8011d2a0,(%esp)
8010661c:	e8 7e ea ff ff       	call   8010509f <acquire>
  ticks0 = ticks;
80106621:	a1 e0 da 11 80       	mov    0x8011dae0,%eax
80106626:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80106629:	eb 37                	jmp    80106662 <sys_sleep+0x71>
    if(proc->killed){
8010662b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106631:	8b 80 48 02 00 00    	mov    0x248(%eax),%eax
80106637:	85 c0                	test   %eax,%eax
80106639:	74 13                	je     8010664e <sys_sleep+0x5d>
      release(&tickslock);
8010663b:	c7 04 24 a0 d2 11 80 	movl   $0x8011d2a0,(%esp)
80106642:	e8 ba ea ff ff       	call   80105101 <release>
      return -1;
80106647:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010664c:	eb 36                	jmp    80106684 <sys_sleep+0x93>
    }
    sleep(&ticks, &tickslock);
8010664e:	c7 44 24 04 a0 d2 11 	movl   $0x8011d2a0,0x4(%esp)
80106655:	80 
80106656:	c7 04 24 e0 da 11 80 	movl   $0x8011dae0,(%esp)
8010665d:	e8 e7 e6 ff ff       	call   80104d49 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80106662:	a1 e0 da 11 80       	mov    0x8011dae0,%eax
80106667:	89 c2                	mov    %eax,%edx
80106669:	2b 55 f4             	sub    -0xc(%ebp),%edx
8010666c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010666f:	39 c2                	cmp    %eax,%edx
80106671:	72 b8                	jb     8010662b <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106673:	c7 04 24 a0 d2 11 80 	movl   $0x8011d2a0,(%esp)
8010667a:	e8 82 ea ff ff       	call   80105101 <release>
  return 0;
8010667f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106684:	c9                   	leave  
80106685:	c3                   	ret    

80106686 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106686:	55                   	push   %ebp
80106687:	89 e5                	mov    %esp,%ebp
80106689:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
8010668c:	c7 04 24 a0 d2 11 80 	movl   $0x8011d2a0,(%esp)
80106693:	e8 07 ea ff ff       	call   8010509f <acquire>
  xticks = ticks;
80106698:	a1 e0 da 11 80       	mov    0x8011dae0,%eax
8010669d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
801066a0:	c7 04 24 a0 d2 11 80 	movl   $0x8011d2a0,(%esp)
801066a7:	e8 55 ea ff ff       	call   80105101 <release>
  return xticks;
801066ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801066af:	c9                   	leave  
801066b0:	c3                   	ret    
801066b1:	00 00                	add    %al,(%eax)
	...

801066b4 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801066b4:	55                   	push   %ebp
801066b5:	89 e5                	mov    %esp,%ebp
801066b7:	83 ec 08             	sub    $0x8,%esp
801066ba:	8b 55 08             	mov    0x8(%ebp),%edx
801066bd:	8b 45 0c             	mov    0xc(%ebp),%eax
801066c0:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801066c4:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801066c7:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801066cb:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801066cf:	ee                   	out    %al,(%dx)
}
801066d0:	c9                   	leave  
801066d1:	c3                   	ret    

801066d2 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
801066d2:	55                   	push   %ebp
801066d3:	89 e5                	mov    %esp,%ebp
801066d5:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
801066d8:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
801066df:	00 
801066e0:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
801066e7:	e8 c8 ff ff ff       	call   801066b4 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
801066ec:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
801066f3:	00 
801066f4:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
801066fb:	e8 b4 ff ff ff       	call   801066b4 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80106700:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80106707:	00 
80106708:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010670f:	e8 a0 ff ff ff       	call   801066b4 <outb>
  picenable(IRQ_TIMER);
80106714:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010671b:	e8 29 d7 ff ff       	call   80103e49 <picenable>
}
80106720:	c9                   	leave  
80106721:	c3                   	ret    
	...

80106724 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106724:	1e                   	push   %ds
  pushl %es
80106725:	06                   	push   %es
  pushl %fs
80106726:	0f a0                	push   %fs
  pushl %gs
80106728:	0f a8                	push   %gs
  pushal
8010672a:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
8010672b:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
8010672f:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80106731:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80106733:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80106737:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80106739:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
8010673b:	54                   	push   %esp
  call trap
8010673c:	e8 de 01 00 00       	call   8010691f <trap>
  addl $4, %esp
80106741:	83 c4 04             	add    $0x4,%esp

80106744 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106744:	61                   	popa   
  popl %gs
80106745:	0f a9                	pop    %gs
  popl %fs
80106747:	0f a1                	pop    %fs
  popl %es
80106749:	07                   	pop    %es
  popl %ds
8010674a:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
8010674b:	83 c4 08             	add    $0x8,%esp
  iret
8010674e:	cf                   	iret   
	...

80106750 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80106750:	55                   	push   %ebp
80106751:	89 e5                	mov    %esp,%ebp
80106753:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80106756:	8b 45 0c             	mov    0xc(%ebp),%eax
80106759:	83 e8 01             	sub    $0x1,%eax
8010675c:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80106760:	8b 45 08             	mov    0x8(%ebp),%eax
80106763:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80106767:	8b 45 08             	mov    0x8(%ebp),%eax
8010676a:	c1 e8 10             	shr    $0x10,%eax
8010676d:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80106771:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106774:	0f 01 18             	lidtl  (%eax)
}
80106777:	c9                   	leave  
80106778:	c3                   	ret    

80106779 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80106779:	55                   	push   %ebp
8010677a:	89 e5                	mov    %esp,%ebp
8010677c:	53                   	push   %ebx
8010677d:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80106780:	0f 20 d3             	mov    %cr2,%ebx
80106783:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
80106786:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80106789:	83 c4 10             	add    $0x10,%esp
8010678c:	5b                   	pop    %ebx
8010678d:	5d                   	pop    %ebp
8010678e:	c3                   	ret    

8010678f <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
8010678f:	55                   	push   %ebp
80106790:	89 e5                	mov    %esp,%ebp
80106792:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80106795:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010679c:	e9 c3 00 00 00       	jmp    80106864 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
801067a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067a4:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
801067ab:	89 c2                	mov    %eax,%edx
801067ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067b0:	66 89 14 c5 e0 d2 11 	mov    %dx,-0x7fee2d20(,%eax,8)
801067b7:	80 
801067b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067bb:	66 c7 04 c5 e2 d2 11 	movw   $0x8,-0x7fee2d1e(,%eax,8)
801067c2:	80 08 00 
801067c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067c8:	0f b6 14 c5 e4 d2 11 	movzbl -0x7fee2d1c(,%eax,8),%edx
801067cf:	80 
801067d0:	83 e2 e0             	and    $0xffffffe0,%edx
801067d3:	88 14 c5 e4 d2 11 80 	mov    %dl,-0x7fee2d1c(,%eax,8)
801067da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067dd:	0f b6 14 c5 e4 d2 11 	movzbl -0x7fee2d1c(,%eax,8),%edx
801067e4:	80 
801067e5:	83 e2 1f             	and    $0x1f,%edx
801067e8:	88 14 c5 e4 d2 11 80 	mov    %dl,-0x7fee2d1c(,%eax,8)
801067ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067f2:	0f b6 14 c5 e5 d2 11 	movzbl -0x7fee2d1b(,%eax,8),%edx
801067f9:	80 
801067fa:	83 e2 f0             	and    $0xfffffff0,%edx
801067fd:	83 ca 0e             	or     $0xe,%edx
80106800:	88 14 c5 e5 d2 11 80 	mov    %dl,-0x7fee2d1b(,%eax,8)
80106807:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010680a:	0f b6 14 c5 e5 d2 11 	movzbl -0x7fee2d1b(,%eax,8),%edx
80106811:	80 
80106812:	83 e2 ef             	and    $0xffffffef,%edx
80106815:	88 14 c5 e5 d2 11 80 	mov    %dl,-0x7fee2d1b(,%eax,8)
8010681c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010681f:	0f b6 14 c5 e5 d2 11 	movzbl -0x7fee2d1b(,%eax,8),%edx
80106826:	80 
80106827:	83 e2 9f             	and    $0xffffff9f,%edx
8010682a:	88 14 c5 e5 d2 11 80 	mov    %dl,-0x7fee2d1b(,%eax,8)
80106831:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106834:	0f b6 14 c5 e5 d2 11 	movzbl -0x7fee2d1b(,%eax,8),%edx
8010683b:	80 
8010683c:	83 ca 80             	or     $0xffffff80,%edx
8010683f:	88 14 c5 e5 d2 11 80 	mov    %dl,-0x7fee2d1b(,%eax,8)
80106846:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106849:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
80106850:	c1 e8 10             	shr    $0x10,%eax
80106853:	89 c2                	mov    %eax,%edx
80106855:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106858:	66 89 14 c5 e6 d2 11 	mov    %dx,-0x7fee2d1a(,%eax,8)
8010685f:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106860:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106864:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
8010686b:	0f 8e 30 ff ff ff    	jle    801067a1 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80106871:	a1 98 b1 10 80       	mov    0x8010b198,%eax
80106876:	66 a3 e0 d4 11 80    	mov    %ax,0x8011d4e0
8010687c:	66 c7 05 e2 d4 11 80 	movw   $0x8,0x8011d4e2
80106883:	08 00 
80106885:	0f b6 05 e4 d4 11 80 	movzbl 0x8011d4e4,%eax
8010688c:	83 e0 e0             	and    $0xffffffe0,%eax
8010688f:	a2 e4 d4 11 80       	mov    %al,0x8011d4e4
80106894:	0f b6 05 e4 d4 11 80 	movzbl 0x8011d4e4,%eax
8010689b:	83 e0 1f             	and    $0x1f,%eax
8010689e:	a2 e4 d4 11 80       	mov    %al,0x8011d4e4
801068a3:	0f b6 05 e5 d4 11 80 	movzbl 0x8011d4e5,%eax
801068aa:	83 c8 0f             	or     $0xf,%eax
801068ad:	a2 e5 d4 11 80       	mov    %al,0x8011d4e5
801068b2:	0f b6 05 e5 d4 11 80 	movzbl 0x8011d4e5,%eax
801068b9:	83 e0 ef             	and    $0xffffffef,%eax
801068bc:	a2 e5 d4 11 80       	mov    %al,0x8011d4e5
801068c1:	0f b6 05 e5 d4 11 80 	movzbl 0x8011d4e5,%eax
801068c8:	83 c8 60             	or     $0x60,%eax
801068cb:	a2 e5 d4 11 80       	mov    %al,0x8011d4e5
801068d0:	0f b6 05 e5 d4 11 80 	movzbl 0x8011d4e5,%eax
801068d7:	83 c8 80             	or     $0xffffff80,%eax
801068da:	a2 e5 d4 11 80       	mov    %al,0x8011d4e5
801068df:	a1 98 b1 10 80       	mov    0x8010b198,%eax
801068e4:	c1 e8 10             	shr    $0x10,%eax
801068e7:	66 a3 e6 d4 11 80    	mov    %ax,0x8011d4e6
  
  initlock(&tickslock, "time");
801068ed:	c7 44 24 04 20 8b 10 	movl   $0x80108b20,0x4(%esp)
801068f4:	80 
801068f5:	c7 04 24 a0 d2 11 80 	movl   $0x8011d2a0,(%esp)
801068fc:	e8 7d e7 ff ff       	call   8010507e <initlock>
}
80106901:	c9                   	leave  
80106902:	c3                   	ret    

80106903 <idtinit>:

void
idtinit(void)
{
80106903:	55                   	push   %ebp
80106904:	89 e5                	mov    %esp,%ebp
80106906:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80106909:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80106910:	00 
80106911:	c7 04 24 e0 d2 11 80 	movl   $0x8011d2e0,(%esp)
80106918:	e8 33 fe ff ff       	call   80106750 <lidt>
}
8010691d:	c9                   	leave  
8010691e:	c3                   	ret    

8010691f <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
8010691f:	55                   	push   %ebp
80106920:	89 e5                	mov    %esp,%ebp
80106922:	57                   	push   %edi
80106923:	56                   	push   %esi
80106924:	53                   	push   %ebx
80106925:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80106928:	8b 45 08             	mov    0x8(%ebp),%eax
8010692b:	8b 40 30             	mov    0x30(%eax),%eax
8010692e:	83 f8 40             	cmp    $0x40,%eax
80106931:	75 44                	jne    80106977 <trap+0x58>
    if(proc->killed)
80106933:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106939:	8b 80 48 02 00 00    	mov    0x248(%eax),%eax
8010693f:	85 c0                	test   %eax,%eax
80106941:	74 05                	je     80106948 <trap+0x29>
      exit();
80106943:	e8 69 df ff ff       	call   801048b1 <exit>
    proc->threads->tf = tf;
80106948:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010694e:	8b 55 08             	mov    0x8(%ebp),%edx
80106951:	89 50 58             	mov    %edx,0x58(%eax)
    syscall();
80106954:	e8 b8 ed ff ff       	call   80105711 <syscall>
    if(proc->killed)
80106959:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010695f:	8b 80 48 02 00 00    	mov    0x248(%eax),%eax
80106965:	85 c0                	test   %eax,%eax
80106967:	0f 84 3f 02 00 00    	je     80106bac <trap+0x28d>
      exit();
8010696d:	e8 3f df ff ff       	call   801048b1 <exit>
    return;
80106972:	e9 35 02 00 00       	jmp    80106bac <trap+0x28d>
  }

  switch(tf->trapno){
80106977:	8b 45 08             	mov    0x8(%ebp),%eax
8010697a:	8b 40 30             	mov    0x30(%eax),%eax
8010697d:	83 e8 20             	sub    $0x20,%eax
80106980:	83 f8 1f             	cmp    $0x1f,%eax
80106983:	0f 87 bc 00 00 00    	ja     80106a45 <trap+0x126>
80106989:	8b 04 85 c8 8b 10 80 	mov    -0x7fef7438(,%eax,4),%eax
80106990:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
80106992:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106998:	0f b6 00             	movzbl (%eax),%eax
8010699b:	84 c0                	test   %al,%al
8010699d:	75 31                	jne    801069d0 <trap+0xb1>
      acquire(&tickslock);
8010699f:	c7 04 24 a0 d2 11 80 	movl   $0x8011d2a0,(%esp)
801069a6:	e8 f4 e6 ff ff       	call   8010509f <acquire>
      ticks++;
801069ab:	a1 e0 da 11 80       	mov    0x8011dae0,%eax
801069b0:	83 c0 01             	add    $0x1,%eax
801069b3:	a3 e0 da 11 80       	mov    %eax,0x8011dae0
      wakeup(&ticks);
801069b8:	c7 04 24 e0 da 11 80 	movl   $0x8011dae0,(%esp)
801069bf:	e8 94 e4 ff ff       	call   80104e58 <wakeup>
      release(&tickslock);
801069c4:	c7 04 24 a0 d2 11 80 	movl   $0x8011d2a0,(%esp)
801069cb:	e8 31 e7 ff ff       	call   80105101 <release>
    }
    lapiceoi();
801069d0:	e8 7a c5 ff ff       	call   80102f4f <lapiceoi>
    break;
801069d5:	e9 46 01 00 00       	jmp    80106b20 <trap+0x201>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
801069da:	e8 4e bd ff ff       	call   8010272d <ideintr>
    lapiceoi();
801069df:	e8 6b c5 ff ff       	call   80102f4f <lapiceoi>
    break;
801069e4:	e9 37 01 00 00       	jmp    80106b20 <trap+0x201>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
801069e9:	e8 15 c3 ff ff       	call   80102d03 <kbdintr>
    lapiceoi();
801069ee:	e8 5c c5 ff ff       	call   80102f4f <lapiceoi>
    break;
801069f3:	e9 28 01 00 00       	jmp    80106b20 <trap+0x201>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
801069f8:	e8 b7 03 00 00       	call   80106db4 <uartintr>
    lapiceoi();
801069fd:	e8 4d c5 ff ff       	call   80102f4f <lapiceoi>
    break;
80106a02:	e9 19 01 00 00       	jmp    80106b20 <trap+0x201>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
80106a07:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106a0a:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80106a0d:	8b 45 08             	mov    0x8(%ebp),%eax
80106a10:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106a14:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80106a17:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106a1d:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106a20:	0f b6 c0             	movzbl %al,%eax
80106a23:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106a27:	89 54 24 08          	mov    %edx,0x8(%esp)
80106a2b:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a2f:	c7 04 24 28 8b 10 80 	movl   $0x80108b28,(%esp)
80106a36:	e8 66 99 ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80106a3b:	e8 0f c5 ff ff       	call   80102f4f <lapiceoi>
    break;
80106a40:	e9 db 00 00 00       	jmp    80106b20 <trap+0x201>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80106a45:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a4b:	85 c0                	test   %eax,%eax
80106a4d:	74 11                	je     80106a60 <trap+0x141>
80106a4f:	8b 45 08             	mov    0x8(%ebp),%eax
80106a52:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106a56:	0f b7 c0             	movzwl %ax,%eax
80106a59:	83 e0 03             	and    $0x3,%eax
80106a5c:	85 c0                	test   %eax,%eax
80106a5e:	75 46                	jne    80106aa6 <trap+0x187>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106a60:	e8 14 fd ff ff       	call   80106779 <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
80106a65:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106a68:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80106a6b:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80106a72:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106a75:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
80106a78:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106a7b:	8b 52 30             	mov    0x30(%edx),%edx
80106a7e:	89 44 24 10          	mov    %eax,0x10(%esp)
80106a82:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80106a86:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106a8a:	89 54 24 04          	mov    %edx,0x4(%esp)
80106a8e:	c7 04 24 4c 8b 10 80 	movl   $0x80108b4c,(%esp)
80106a95:	e8 07 99 ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80106a9a:	c7 04 24 7e 8b 10 80 	movl   $0x80108b7e,(%esp)
80106aa1:	e8 97 9a ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106aa6:	e8 ce fc ff ff       	call   80106779 <rcr2>
80106aab:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106aad:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106ab0:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106ab3:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106ab9:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106abc:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106abf:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106ac2:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106ac5:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106ac8:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106acb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106ad1:	05 90 02 00 00       	add    $0x290,%eax
80106ad6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106ad9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106adf:	8b 40 0c             	mov    0xc(%eax),%eax
80106ae2:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80106ae6:	89 7c 24 18          	mov    %edi,0x18(%esp)
80106aea:	89 74 24 14          	mov    %esi,0x14(%esp)
80106aee:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80106af2:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106af6:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80106af9:	89 54 24 08          	mov    %edx,0x8(%esp)
80106afd:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b01:	c7 04 24 84 8b 10 80 	movl   $0x80108b84,(%esp)
80106b08:	e8 94 98 ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80106b0d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b13:	c7 80 48 02 00 00 01 	movl   $0x1,0x248(%eax)
80106b1a:	00 00 00 
80106b1d:	eb 01                	jmp    80106b20 <trap+0x201>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80106b1f:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106b20:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b26:	85 c0                	test   %eax,%eax
80106b28:	74 27                	je     80106b51 <trap+0x232>
80106b2a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b30:	8b 80 48 02 00 00    	mov    0x248(%eax),%eax
80106b36:	85 c0                	test   %eax,%eax
80106b38:	74 17                	je     80106b51 <trap+0x232>
80106b3a:	8b 45 08             	mov    0x8(%ebp),%eax
80106b3d:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106b41:	0f b7 c0             	movzwl %ax,%eax
80106b44:	83 e0 03             	and    $0x3,%eax
80106b47:	83 f8 03             	cmp    $0x3,%eax
80106b4a:	75 05                	jne    80106b51 <trap+0x232>
    exit();
80106b4c:	e8 60 dd ff ff       	call   801048b1 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80106b51:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b57:	85 c0                	test   %eax,%eax
80106b59:	74 1e                	je     80106b79 <trap+0x25a>
80106b5b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b61:	8b 40 08             	mov    0x8(%eax),%eax
80106b64:	83 f8 04             	cmp    $0x4,%eax
80106b67:	75 10                	jne    80106b79 <trap+0x25a>
80106b69:	8b 45 08             	mov    0x8(%ebp),%eax
80106b6c:	8b 40 30             	mov    0x30(%eax),%eax
80106b6f:	83 f8 20             	cmp    $0x20,%eax
80106b72:	75 05                	jne    80106b79 <trap+0x25a>
    yield();
80106b74:	e8 72 e1 ff ff       	call   80104ceb <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106b79:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b7f:	85 c0                	test   %eax,%eax
80106b81:	74 2a                	je     80106bad <trap+0x28e>
80106b83:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b89:	8b 80 48 02 00 00    	mov    0x248(%eax),%eax
80106b8f:	85 c0                	test   %eax,%eax
80106b91:	74 1a                	je     80106bad <trap+0x28e>
80106b93:	8b 45 08             	mov    0x8(%ebp),%eax
80106b96:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106b9a:	0f b7 c0             	movzwl %ax,%eax
80106b9d:	83 e0 03             	and    $0x3,%eax
80106ba0:	83 f8 03             	cmp    $0x3,%eax
80106ba3:	75 08                	jne    80106bad <trap+0x28e>
    exit();
80106ba5:	e8 07 dd ff ff       	call   801048b1 <exit>
80106baa:	eb 01                	jmp    80106bad <trap+0x28e>
      exit();
    proc->threads->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
80106bac:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
80106bad:	83 c4 3c             	add    $0x3c,%esp
80106bb0:	5b                   	pop    %ebx
80106bb1:	5e                   	pop    %esi
80106bb2:	5f                   	pop    %edi
80106bb3:	5d                   	pop    %ebp
80106bb4:	c3                   	ret    
80106bb5:	00 00                	add    %al,(%eax)
	...

80106bb8 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80106bb8:	55                   	push   %ebp
80106bb9:	89 e5                	mov    %esp,%ebp
80106bbb:	53                   	push   %ebx
80106bbc:	83 ec 14             	sub    $0x14,%esp
80106bbf:	8b 45 08             	mov    0x8(%ebp),%eax
80106bc2:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80106bc6:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80106bca:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80106bce:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80106bd2:	ec                   	in     (%dx),%al
80106bd3:	89 c3                	mov    %eax,%ebx
80106bd5:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80106bd8:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80106bdc:	83 c4 14             	add    $0x14,%esp
80106bdf:	5b                   	pop    %ebx
80106be0:	5d                   	pop    %ebp
80106be1:	c3                   	ret    

80106be2 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106be2:	55                   	push   %ebp
80106be3:	89 e5                	mov    %esp,%ebp
80106be5:	83 ec 08             	sub    $0x8,%esp
80106be8:	8b 55 08             	mov    0x8(%ebp),%edx
80106beb:	8b 45 0c             	mov    0xc(%ebp),%eax
80106bee:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106bf2:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106bf5:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106bf9:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106bfd:	ee                   	out    %al,(%dx)
}
80106bfe:	c9                   	leave  
80106bff:	c3                   	ret    

80106c00 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80106c00:	55                   	push   %ebp
80106c01:	89 e5                	mov    %esp,%ebp
80106c03:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80106c06:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106c0d:	00 
80106c0e:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106c15:	e8 c8 ff ff ff       	call   80106be2 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80106c1a:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80106c21:	00 
80106c22:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106c29:	e8 b4 ff ff ff       	call   80106be2 <outb>
  outb(COM1+0, 115200/9600);
80106c2e:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80106c35:	00 
80106c36:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106c3d:	e8 a0 ff ff ff       	call   80106be2 <outb>
  outb(COM1+1, 0);
80106c42:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106c49:	00 
80106c4a:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106c51:	e8 8c ff ff ff       	call   80106be2 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80106c56:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106c5d:	00 
80106c5e:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106c65:	e8 78 ff ff ff       	call   80106be2 <outb>
  outb(COM1+4, 0);
80106c6a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106c71:	00 
80106c72:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80106c79:	e8 64 ff ff ff       	call   80106be2 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80106c7e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106c85:	00 
80106c86:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106c8d:	e8 50 ff ff ff       	call   80106be2 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80106c92:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106c99:	e8 1a ff ff ff       	call   80106bb8 <inb>
80106c9e:	3c ff                	cmp    $0xff,%al
80106ca0:	74 6c                	je     80106d0e <uartinit+0x10e>
    return;
  uart = 1;
80106ca2:	c7 05 4c b6 10 80 01 	movl   $0x1,0x8010b64c
80106ca9:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80106cac:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106cb3:	e8 00 ff ff ff       	call   80106bb8 <inb>
  inb(COM1+0);
80106cb8:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106cbf:	e8 f4 fe ff ff       	call   80106bb8 <inb>
  picenable(IRQ_COM1);
80106cc4:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106ccb:	e8 79 d1 ff ff       	call   80103e49 <picenable>
  ioapicenable(IRQ_COM1, 0);
80106cd0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106cd7:	00 
80106cd8:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106cdf:	e8 ce bc ff ff       	call   801029b2 <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106ce4:	c7 45 f4 48 8c 10 80 	movl   $0x80108c48,-0xc(%ebp)
80106ceb:	eb 15                	jmp    80106d02 <uartinit+0x102>
    uartputc(*p);
80106ced:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106cf0:	0f b6 00             	movzbl (%eax),%eax
80106cf3:	0f be c0             	movsbl %al,%eax
80106cf6:	89 04 24             	mov    %eax,(%esp)
80106cf9:	e8 13 00 00 00       	call   80106d11 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106cfe:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106d02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d05:	0f b6 00             	movzbl (%eax),%eax
80106d08:	84 c0                	test   %al,%al
80106d0a:	75 e1                	jne    80106ced <uartinit+0xed>
80106d0c:	eb 01                	jmp    80106d0f <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
80106d0e:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
80106d0f:	c9                   	leave  
80106d10:	c3                   	ret    

80106d11 <uartputc>:

void
uartputc(int c)
{
80106d11:	55                   	push   %ebp
80106d12:	89 e5                	mov    %esp,%ebp
80106d14:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80106d17:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
80106d1c:	85 c0                	test   %eax,%eax
80106d1e:	74 4d                	je     80106d6d <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106d20:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106d27:	eb 10                	jmp    80106d39 <uartputc+0x28>
    microdelay(10);
80106d29:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80106d30:	e8 3f c2 ff ff       	call   80102f74 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106d35:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106d39:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80106d3d:	7f 16                	jg     80106d55 <uartputc+0x44>
80106d3f:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106d46:	e8 6d fe ff ff       	call   80106bb8 <inb>
80106d4b:	0f b6 c0             	movzbl %al,%eax
80106d4e:	83 e0 20             	and    $0x20,%eax
80106d51:	85 c0                	test   %eax,%eax
80106d53:	74 d4                	je     80106d29 <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80106d55:	8b 45 08             	mov    0x8(%ebp),%eax
80106d58:	0f b6 c0             	movzbl %al,%eax
80106d5b:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d5f:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106d66:	e8 77 fe ff ff       	call   80106be2 <outb>
80106d6b:	eb 01                	jmp    80106d6e <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80106d6d:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
80106d6e:	c9                   	leave  
80106d6f:	c3                   	ret    

80106d70 <uartgetc>:

static int
uartgetc(void)
{
80106d70:	55                   	push   %ebp
80106d71:	89 e5                	mov    %esp,%ebp
80106d73:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80106d76:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
80106d7b:	85 c0                	test   %eax,%eax
80106d7d:	75 07                	jne    80106d86 <uartgetc+0x16>
    return -1;
80106d7f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d84:	eb 2c                	jmp    80106db2 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80106d86:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106d8d:	e8 26 fe ff ff       	call   80106bb8 <inb>
80106d92:	0f b6 c0             	movzbl %al,%eax
80106d95:	83 e0 01             	and    $0x1,%eax
80106d98:	85 c0                	test   %eax,%eax
80106d9a:	75 07                	jne    80106da3 <uartgetc+0x33>
    return -1;
80106d9c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106da1:	eb 0f                	jmp    80106db2 <uartgetc+0x42>
  return inb(COM1+0);
80106da3:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106daa:	e8 09 fe ff ff       	call   80106bb8 <inb>
80106daf:	0f b6 c0             	movzbl %al,%eax
}
80106db2:	c9                   	leave  
80106db3:	c3                   	ret    

80106db4 <uartintr>:

void
uartintr(void)
{
80106db4:	55                   	push   %ebp
80106db5:	89 e5                	mov    %esp,%ebp
80106db7:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80106dba:	c7 04 24 70 6d 10 80 	movl   $0x80106d70,(%esp)
80106dc1:	e8 e7 99 ff ff       	call   801007ad <consoleintr>
}
80106dc6:	c9                   	leave  
80106dc7:	c3                   	ret    

80106dc8 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80106dc8:	6a 00                	push   $0x0
  pushl $0
80106dca:	6a 00                	push   $0x0
  jmp alltraps
80106dcc:	e9 53 f9 ff ff       	jmp    80106724 <alltraps>

80106dd1 <vector1>:
.globl vector1
vector1:
  pushl $0
80106dd1:	6a 00                	push   $0x0
  pushl $1
80106dd3:	6a 01                	push   $0x1
  jmp alltraps
80106dd5:	e9 4a f9 ff ff       	jmp    80106724 <alltraps>

80106dda <vector2>:
.globl vector2
vector2:
  pushl $0
80106dda:	6a 00                	push   $0x0
  pushl $2
80106ddc:	6a 02                	push   $0x2
  jmp alltraps
80106dde:	e9 41 f9 ff ff       	jmp    80106724 <alltraps>

80106de3 <vector3>:
.globl vector3
vector3:
  pushl $0
80106de3:	6a 00                	push   $0x0
  pushl $3
80106de5:	6a 03                	push   $0x3
  jmp alltraps
80106de7:	e9 38 f9 ff ff       	jmp    80106724 <alltraps>

80106dec <vector4>:
.globl vector4
vector4:
  pushl $0
80106dec:	6a 00                	push   $0x0
  pushl $4
80106dee:	6a 04                	push   $0x4
  jmp alltraps
80106df0:	e9 2f f9 ff ff       	jmp    80106724 <alltraps>

80106df5 <vector5>:
.globl vector5
vector5:
  pushl $0
80106df5:	6a 00                	push   $0x0
  pushl $5
80106df7:	6a 05                	push   $0x5
  jmp alltraps
80106df9:	e9 26 f9 ff ff       	jmp    80106724 <alltraps>

80106dfe <vector6>:
.globl vector6
vector6:
  pushl $0
80106dfe:	6a 00                	push   $0x0
  pushl $6
80106e00:	6a 06                	push   $0x6
  jmp alltraps
80106e02:	e9 1d f9 ff ff       	jmp    80106724 <alltraps>

80106e07 <vector7>:
.globl vector7
vector7:
  pushl $0
80106e07:	6a 00                	push   $0x0
  pushl $7
80106e09:	6a 07                	push   $0x7
  jmp alltraps
80106e0b:	e9 14 f9 ff ff       	jmp    80106724 <alltraps>

80106e10 <vector8>:
.globl vector8
vector8:
  pushl $8
80106e10:	6a 08                	push   $0x8
  jmp alltraps
80106e12:	e9 0d f9 ff ff       	jmp    80106724 <alltraps>

80106e17 <vector9>:
.globl vector9
vector9:
  pushl $0
80106e17:	6a 00                	push   $0x0
  pushl $9
80106e19:	6a 09                	push   $0x9
  jmp alltraps
80106e1b:	e9 04 f9 ff ff       	jmp    80106724 <alltraps>

80106e20 <vector10>:
.globl vector10
vector10:
  pushl $10
80106e20:	6a 0a                	push   $0xa
  jmp alltraps
80106e22:	e9 fd f8 ff ff       	jmp    80106724 <alltraps>

80106e27 <vector11>:
.globl vector11
vector11:
  pushl $11
80106e27:	6a 0b                	push   $0xb
  jmp alltraps
80106e29:	e9 f6 f8 ff ff       	jmp    80106724 <alltraps>

80106e2e <vector12>:
.globl vector12
vector12:
  pushl $12
80106e2e:	6a 0c                	push   $0xc
  jmp alltraps
80106e30:	e9 ef f8 ff ff       	jmp    80106724 <alltraps>

80106e35 <vector13>:
.globl vector13
vector13:
  pushl $13
80106e35:	6a 0d                	push   $0xd
  jmp alltraps
80106e37:	e9 e8 f8 ff ff       	jmp    80106724 <alltraps>

80106e3c <vector14>:
.globl vector14
vector14:
  pushl $14
80106e3c:	6a 0e                	push   $0xe
  jmp alltraps
80106e3e:	e9 e1 f8 ff ff       	jmp    80106724 <alltraps>

80106e43 <vector15>:
.globl vector15
vector15:
  pushl $0
80106e43:	6a 00                	push   $0x0
  pushl $15
80106e45:	6a 0f                	push   $0xf
  jmp alltraps
80106e47:	e9 d8 f8 ff ff       	jmp    80106724 <alltraps>

80106e4c <vector16>:
.globl vector16
vector16:
  pushl $0
80106e4c:	6a 00                	push   $0x0
  pushl $16
80106e4e:	6a 10                	push   $0x10
  jmp alltraps
80106e50:	e9 cf f8 ff ff       	jmp    80106724 <alltraps>

80106e55 <vector17>:
.globl vector17
vector17:
  pushl $17
80106e55:	6a 11                	push   $0x11
  jmp alltraps
80106e57:	e9 c8 f8 ff ff       	jmp    80106724 <alltraps>

80106e5c <vector18>:
.globl vector18
vector18:
  pushl $0
80106e5c:	6a 00                	push   $0x0
  pushl $18
80106e5e:	6a 12                	push   $0x12
  jmp alltraps
80106e60:	e9 bf f8 ff ff       	jmp    80106724 <alltraps>

80106e65 <vector19>:
.globl vector19
vector19:
  pushl $0
80106e65:	6a 00                	push   $0x0
  pushl $19
80106e67:	6a 13                	push   $0x13
  jmp alltraps
80106e69:	e9 b6 f8 ff ff       	jmp    80106724 <alltraps>

80106e6e <vector20>:
.globl vector20
vector20:
  pushl $0
80106e6e:	6a 00                	push   $0x0
  pushl $20
80106e70:	6a 14                	push   $0x14
  jmp alltraps
80106e72:	e9 ad f8 ff ff       	jmp    80106724 <alltraps>

80106e77 <vector21>:
.globl vector21
vector21:
  pushl $0
80106e77:	6a 00                	push   $0x0
  pushl $21
80106e79:	6a 15                	push   $0x15
  jmp alltraps
80106e7b:	e9 a4 f8 ff ff       	jmp    80106724 <alltraps>

80106e80 <vector22>:
.globl vector22
vector22:
  pushl $0
80106e80:	6a 00                	push   $0x0
  pushl $22
80106e82:	6a 16                	push   $0x16
  jmp alltraps
80106e84:	e9 9b f8 ff ff       	jmp    80106724 <alltraps>

80106e89 <vector23>:
.globl vector23
vector23:
  pushl $0
80106e89:	6a 00                	push   $0x0
  pushl $23
80106e8b:	6a 17                	push   $0x17
  jmp alltraps
80106e8d:	e9 92 f8 ff ff       	jmp    80106724 <alltraps>

80106e92 <vector24>:
.globl vector24
vector24:
  pushl $0
80106e92:	6a 00                	push   $0x0
  pushl $24
80106e94:	6a 18                	push   $0x18
  jmp alltraps
80106e96:	e9 89 f8 ff ff       	jmp    80106724 <alltraps>

80106e9b <vector25>:
.globl vector25
vector25:
  pushl $0
80106e9b:	6a 00                	push   $0x0
  pushl $25
80106e9d:	6a 19                	push   $0x19
  jmp alltraps
80106e9f:	e9 80 f8 ff ff       	jmp    80106724 <alltraps>

80106ea4 <vector26>:
.globl vector26
vector26:
  pushl $0
80106ea4:	6a 00                	push   $0x0
  pushl $26
80106ea6:	6a 1a                	push   $0x1a
  jmp alltraps
80106ea8:	e9 77 f8 ff ff       	jmp    80106724 <alltraps>

80106ead <vector27>:
.globl vector27
vector27:
  pushl $0
80106ead:	6a 00                	push   $0x0
  pushl $27
80106eaf:	6a 1b                	push   $0x1b
  jmp alltraps
80106eb1:	e9 6e f8 ff ff       	jmp    80106724 <alltraps>

80106eb6 <vector28>:
.globl vector28
vector28:
  pushl $0
80106eb6:	6a 00                	push   $0x0
  pushl $28
80106eb8:	6a 1c                	push   $0x1c
  jmp alltraps
80106eba:	e9 65 f8 ff ff       	jmp    80106724 <alltraps>

80106ebf <vector29>:
.globl vector29
vector29:
  pushl $0
80106ebf:	6a 00                	push   $0x0
  pushl $29
80106ec1:	6a 1d                	push   $0x1d
  jmp alltraps
80106ec3:	e9 5c f8 ff ff       	jmp    80106724 <alltraps>

80106ec8 <vector30>:
.globl vector30
vector30:
  pushl $0
80106ec8:	6a 00                	push   $0x0
  pushl $30
80106eca:	6a 1e                	push   $0x1e
  jmp alltraps
80106ecc:	e9 53 f8 ff ff       	jmp    80106724 <alltraps>

80106ed1 <vector31>:
.globl vector31
vector31:
  pushl $0
80106ed1:	6a 00                	push   $0x0
  pushl $31
80106ed3:	6a 1f                	push   $0x1f
  jmp alltraps
80106ed5:	e9 4a f8 ff ff       	jmp    80106724 <alltraps>

80106eda <vector32>:
.globl vector32
vector32:
  pushl $0
80106eda:	6a 00                	push   $0x0
  pushl $32
80106edc:	6a 20                	push   $0x20
  jmp alltraps
80106ede:	e9 41 f8 ff ff       	jmp    80106724 <alltraps>

80106ee3 <vector33>:
.globl vector33
vector33:
  pushl $0
80106ee3:	6a 00                	push   $0x0
  pushl $33
80106ee5:	6a 21                	push   $0x21
  jmp alltraps
80106ee7:	e9 38 f8 ff ff       	jmp    80106724 <alltraps>

80106eec <vector34>:
.globl vector34
vector34:
  pushl $0
80106eec:	6a 00                	push   $0x0
  pushl $34
80106eee:	6a 22                	push   $0x22
  jmp alltraps
80106ef0:	e9 2f f8 ff ff       	jmp    80106724 <alltraps>

80106ef5 <vector35>:
.globl vector35
vector35:
  pushl $0
80106ef5:	6a 00                	push   $0x0
  pushl $35
80106ef7:	6a 23                	push   $0x23
  jmp alltraps
80106ef9:	e9 26 f8 ff ff       	jmp    80106724 <alltraps>

80106efe <vector36>:
.globl vector36
vector36:
  pushl $0
80106efe:	6a 00                	push   $0x0
  pushl $36
80106f00:	6a 24                	push   $0x24
  jmp alltraps
80106f02:	e9 1d f8 ff ff       	jmp    80106724 <alltraps>

80106f07 <vector37>:
.globl vector37
vector37:
  pushl $0
80106f07:	6a 00                	push   $0x0
  pushl $37
80106f09:	6a 25                	push   $0x25
  jmp alltraps
80106f0b:	e9 14 f8 ff ff       	jmp    80106724 <alltraps>

80106f10 <vector38>:
.globl vector38
vector38:
  pushl $0
80106f10:	6a 00                	push   $0x0
  pushl $38
80106f12:	6a 26                	push   $0x26
  jmp alltraps
80106f14:	e9 0b f8 ff ff       	jmp    80106724 <alltraps>

80106f19 <vector39>:
.globl vector39
vector39:
  pushl $0
80106f19:	6a 00                	push   $0x0
  pushl $39
80106f1b:	6a 27                	push   $0x27
  jmp alltraps
80106f1d:	e9 02 f8 ff ff       	jmp    80106724 <alltraps>

80106f22 <vector40>:
.globl vector40
vector40:
  pushl $0
80106f22:	6a 00                	push   $0x0
  pushl $40
80106f24:	6a 28                	push   $0x28
  jmp alltraps
80106f26:	e9 f9 f7 ff ff       	jmp    80106724 <alltraps>

80106f2b <vector41>:
.globl vector41
vector41:
  pushl $0
80106f2b:	6a 00                	push   $0x0
  pushl $41
80106f2d:	6a 29                	push   $0x29
  jmp alltraps
80106f2f:	e9 f0 f7 ff ff       	jmp    80106724 <alltraps>

80106f34 <vector42>:
.globl vector42
vector42:
  pushl $0
80106f34:	6a 00                	push   $0x0
  pushl $42
80106f36:	6a 2a                	push   $0x2a
  jmp alltraps
80106f38:	e9 e7 f7 ff ff       	jmp    80106724 <alltraps>

80106f3d <vector43>:
.globl vector43
vector43:
  pushl $0
80106f3d:	6a 00                	push   $0x0
  pushl $43
80106f3f:	6a 2b                	push   $0x2b
  jmp alltraps
80106f41:	e9 de f7 ff ff       	jmp    80106724 <alltraps>

80106f46 <vector44>:
.globl vector44
vector44:
  pushl $0
80106f46:	6a 00                	push   $0x0
  pushl $44
80106f48:	6a 2c                	push   $0x2c
  jmp alltraps
80106f4a:	e9 d5 f7 ff ff       	jmp    80106724 <alltraps>

80106f4f <vector45>:
.globl vector45
vector45:
  pushl $0
80106f4f:	6a 00                	push   $0x0
  pushl $45
80106f51:	6a 2d                	push   $0x2d
  jmp alltraps
80106f53:	e9 cc f7 ff ff       	jmp    80106724 <alltraps>

80106f58 <vector46>:
.globl vector46
vector46:
  pushl $0
80106f58:	6a 00                	push   $0x0
  pushl $46
80106f5a:	6a 2e                	push   $0x2e
  jmp alltraps
80106f5c:	e9 c3 f7 ff ff       	jmp    80106724 <alltraps>

80106f61 <vector47>:
.globl vector47
vector47:
  pushl $0
80106f61:	6a 00                	push   $0x0
  pushl $47
80106f63:	6a 2f                	push   $0x2f
  jmp alltraps
80106f65:	e9 ba f7 ff ff       	jmp    80106724 <alltraps>

80106f6a <vector48>:
.globl vector48
vector48:
  pushl $0
80106f6a:	6a 00                	push   $0x0
  pushl $48
80106f6c:	6a 30                	push   $0x30
  jmp alltraps
80106f6e:	e9 b1 f7 ff ff       	jmp    80106724 <alltraps>

80106f73 <vector49>:
.globl vector49
vector49:
  pushl $0
80106f73:	6a 00                	push   $0x0
  pushl $49
80106f75:	6a 31                	push   $0x31
  jmp alltraps
80106f77:	e9 a8 f7 ff ff       	jmp    80106724 <alltraps>

80106f7c <vector50>:
.globl vector50
vector50:
  pushl $0
80106f7c:	6a 00                	push   $0x0
  pushl $50
80106f7e:	6a 32                	push   $0x32
  jmp alltraps
80106f80:	e9 9f f7 ff ff       	jmp    80106724 <alltraps>

80106f85 <vector51>:
.globl vector51
vector51:
  pushl $0
80106f85:	6a 00                	push   $0x0
  pushl $51
80106f87:	6a 33                	push   $0x33
  jmp alltraps
80106f89:	e9 96 f7 ff ff       	jmp    80106724 <alltraps>

80106f8e <vector52>:
.globl vector52
vector52:
  pushl $0
80106f8e:	6a 00                	push   $0x0
  pushl $52
80106f90:	6a 34                	push   $0x34
  jmp alltraps
80106f92:	e9 8d f7 ff ff       	jmp    80106724 <alltraps>

80106f97 <vector53>:
.globl vector53
vector53:
  pushl $0
80106f97:	6a 00                	push   $0x0
  pushl $53
80106f99:	6a 35                	push   $0x35
  jmp alltraps
80106f9b:	e9 84 f7 ff ff       	jmp    80106724 <alltraps>

80106fa0 <vector54>:
.globl vector54
vector54:
  pushl $0
80106fa0:	6a 00                	push   $0x0
  pushl $54
80106fa2:	6a 36                	push   $0x36
  jmp alltraps
80106fa4:	e9 7b f7 ff ff       	jmp    80106724 <alltraps>

80106fa9 <vector55>:
.globl vector55
vector55:
  pushl $0
80106fa9:	6a 00                	push   $0x0
  pushl $55
80106fab:	6a 37                	push   $0x37
  jmp alltraps
80106fad:	e9 72 f7 ff ff       	jmp    80106724 <alltraps>

80106fb2 <vector56>:
.globl vector56
vector56:
  pushl $0
80106fb2:	6a 00                	push   $0x0
  pushl $56
80106fb4:	6a 38                	push   $0x38
  jmp alltraps
80106fb6:	e9 69 f7 ff ff       	jmp    80106724 <alltraps>

80106fbb <vector57>:
.globl vector57
vector57:
  pushl $0
80106fbb:	6a 00                	push   $0x0
  pushl $57
80106fbd:	6a 39                	push   $0x39
  jmp alltraps
80106fbf:	e9 60 f7 ff ff       	jmp    80106724 <alltraps>

80106fc4 <vector58>:
.globl vector58
vector58:
  pushl $0
80106fc4:	6a 00                	push   $0x0
  pushl $58
80106fc6:	6a 3a                	push   $0x3a
  jmp alltraps
80106fc8:	e9 57 f7 ff ff       	jmp    80106724 <alltraps>

80106fcd <vector59>:
.globl vector59
vector59:
  pushl $0
80106fcd:	6a 00                	push   $0x0
  pushl $59
80106fcf:	6a 3b                	push   $0x3b
  jmp alltraps
80106fd1:	e9 4e f7 ff ff       	jmp    80106724 <alltraps>

80106fd6 <vector60>:
.globl vector60
vector60:
  pushl $0
80106fd6:	6a 00                	push   $0x0
  pushl $60
80106fd8:	6a 3c                	push   $0x3c
  jmp alltraps
80106fda:	e9 45 f7 ff ff       	jmp    80106724 <alltraps>

80106fdf <vector61>:
.globl vector61
vector61:
  pushl $0
80106fdf:	6a 00                	push   $0x0
  pushl $61
80106fe1:	6a 3d                	push   $0x3d
  jmp alltraps
80106fe3:	e9 3c f7 ff ff       	jmp    80106724 <alltraps>

80106fe8 <vector62>:
.globl vector62
vector62:
  pushl $0
80106fe8:	6a 00                	push   $0x0
  pushl $62
80106fea:	6a 3e                	push   $0x3e
  jmp alltraps
80106fec:	e9 33 f7 ff ff       	jmp    80106724 <alltraps>

80106ff1 <vector63>:
.globl vector63
vector63:
  pushl $0
80106ff1:	6a 00                	push   $0x0
  pushl $63
80106ff3:	6a 3f                	push   $0x3f
  jmp alltraps
80106ff5:	e9 2a f7 ff ff       	jmp    80106724 <alltraps>

80106ffa <vector64>:
.globl vector64
vector64:
  pushl $0
80106ffa:	6a 00                	push   $0x0
  pushl $64
80106ffc:	6a 40                	push   $0x40
  jmp alltraps
80106ffe:	e9 21 f7 ff ff       	jmp    80106724 <alltraps>

80107003 <vector65>:
.globl vector65
vector65:
  pushl $0
80107003:	6a 00                	push   $0x0
  pushl $65
80107005:	6a 41                	push   $0x41
  jmp alltraps
80107007:	e9 18 f7 ff ff       	jmp    80106724 <alltraps>

8010700c <vector66>:
.globl vector66
vector66:
  pushl $0
8010700c:	6a 00                	push   $0x0
  pushl $66
8010700e:	6a 42                	push   $0x42
  jmp alltraps
80107010:	e9 0f f7 ff ff       	jmp    80106724 <alltraps>

80107015 <vector67>:
.globl vector67
vector67:
  pushl $0
80107015:	6a 00                	push   $0x0
  pushl $67
80107017:	6a 43                	push   $0x43
  jmp alltraps
80107019:	e9 06 f7 ff ff       	jmp    80106724 <alltraps>

8010701e <vector68>:
.globl vector68
vector68:
  pushl $0
8010701e:	6a 00                	push   $0x0
  pushl $68
80107020:	6a 44                	push   $0x44
  jmp alltraps
80107022:	e9 fd f6 ff ff       	jmp    80106724 <alltraps>

80107027 <vector69>:
.globl vector69
vector69:
  pushl $0
80107027:	6a 00                	push   $0x0
  pushl $69
80107029:	6a 45                	push   $0x45
  jmp alltraps
8010702b:	e9 f4 f6 ff ff       	jmp    80106724 <alltraps>

80107030 <vector70>:
.globl vector70
vector70:
  pushl $0
80107030:	6a 00                	push   $0x0
  pushl $70
80107032:	6a 46                	push   $0x46
  jmp alltraps
80107034:	e9 eb f6 ff ff       	jmp    80106724 <alltraps>

80107039 <vector71>:
.globl vector71
vector71:
  pushl $0
80107039:	6a 00                	push   $0x0
  pushl $71
8010703b:	6a 47                	push   $0x47
  jmp alltraps
8010703d:	e9 e2 f6 ff ff       	jmp    80106724 <alltraps>

80107042 <vector72>:
.globl vector72
vector72:
  pushl $0
80107042:	6a 00                	push   $0x0
  pushl $72
80107044:	6a 48                	push   $0x48
  jmp alltraps
80107046:	e9 d9 f6 ff ff       	jmp    80106724 <alltraps>

8010704b <vector73>:
.globl vector73
vector73:
  pushl $0
8010704b:	6a 00                	push   $0x0
  pushl $73
8010704d:	6a 49                	push   $0x49
  jmp alltraps
8010704f:	e9 d0 f6 ff ff       	jmp    80106724 <alltraps>

80107054 <vector74>:
.globl vector74
vector74:
  pushl $0
80107054:	6a 00                	push   $0x0
  pushl $74
80107056:	6a 4a                	push   $0x4a
  jmp alltraps
80107058:	e9 c7 f6 ff ff       	jmp    80106724 <alltraps>

8010705d <vector75>:
.globl vector75
vector75:
  pushl $0
8010705d:	6a 00                	push   $0x0
  pushl $75
8010705f:	6a 4b                	push   $0x4b
  jmp alltraps
80107061:	e9 be f6 ff ff       	jmp    80106724 <alltraps>

80107066 <vector76>:
.globl vector76
vector76:
  pushl $0
80107066:	6a 00                	push   $0x0
  pushl $76
80107068:	6a 4c                	push   $0x4c
  jmp alltraps
8010706a:	e9 b5 f6 ff ff       	jmp    80106724 <alltraps>

8010706f <vector77>:
.globl vector77
vector77:
  pushl $0
8010706f:	6a 00                	push   $0x0
  pushl $77
80107071:	6a 4d                	push   $0x4d
  jmp alltraps
80107073:	e9 ac f6 ff ff       	jmp    80106724 <alltraps>

80107078 <vector78>:
.globl vector78
vector78:
  pushl $0
80107078:	6a 00                	push   $0x0
  pushl $78
8010707a:	6a 4e                	push   $0x4e
  jmp alltraps
8010707c:	e9 a3 f6 ff ff       	jmp    80106724 <alltraps>

80107081 <vector79>:
.globl vector79
vector79:
  pushl $0
80107081:	6a 00                	push   $0x0
  pushl $79
80107083:	6a 4f                	push   $0x4f
  jmp alltraps
80107085:	e9 9a f6 ff ff       	jmp    80106724 <alltraps>

8010708a <vector80>:
.globl vector80
vector80:
  pushl $0
8010708a:	6a 00                	push   $0x0
  pushl $80
8010708c:	6a 50                	push   $0x50
  jmp alltraps
8010708e:	e9 91 f6 ff ff       	jmp    80106724 <alltraps>

80107093 <vector81>:
.globl vector81
vector81:
  pushl $0
80107093:	6a 00                	push   $0x0
  pushl $81
80107095:	6a 51                	push   $0x51
  jmp alltraps
80107097:	e9 88 f6 ff ff       	jmp    80106724 <alltraps>

8010709c <vector82>:
.globl vector82
vector82:
  pushl $0
8010709c:	6a 00                	push   $0x0
  pushl $82
8010709e:	6a 52                	push   $0x52
  jmp alltraps
801070a0:	e9 7f f6 ff ff       	jmp    80106724 <alltraps>

801070a5 <vector83>:
.globl vector83
vector83:
  pushl $0
801070a5:	6a 00                	push   $0x0
  pushl $83
801070a7:	6a 53                	push   $0x53
  jmp alltraps
801070a9:	e9 76 f6 ff ff       	jmp    80106724 <alltraps>

801070ae <vector84>:
.globl vector84
vector84:
  pushl $0
801070ae:	6a 00                	push   $0x0
  pushl $84
801070b0:	6a 54                	push   $0x54
  jmp alltraps
801070b2:	e9 6d f6 ff ff       	jmp    80106724 <alltraps>

801070b7 <vector85>:
.globl vector85
vector85:
  pushl $0
801070b7:	6a 00                	push   $0x0
  pushl $85
801070b9:	6a 55                	push   $0x55
  jmp alltraps
801070bb:	e9 64 f6 ff ff       	jmp    80106724 <alltraps>

801070c0 <vector86>:
.globl vector86
vector86:
  pushl $0
801070c0:	6a 00                	push   $0x0
  pushl $86
801070c2:	6a 56                	push   $0x56
  jmp alltraps
801070c4:	e9 5b f6 ff ff       	jmp    80106724 <alltraps>

801070c9 <vector87>:
.globl vector87
vector87:
  pushl $0
801070c9:	6a 00                	push   $0x0
  pushl $87
801070cb:	6a 57                	push   $0x57
  jmp alltraps
801070cd:	e9 52 f6 ff ff       	jmp    80106724 <alltraps>

801070d2 <vector88>:
.globl vector88
vector88:
  pushl $0
801070d2:	6a 00                	push   $0x0
  pushl $88
801070d4:	6a 58                	push   $0x58
  jmp alltraps
801070d6:	e9 49 f6 ff ff       	jmp    80106724 <alltraps>

801070db <vector89>:
.globl vector89
vector89:
  pushl $0
801070db:	6a 00                	push   $0x0
  pushl $89
801070dd:	6a 59                	push   $0x59
  jmp alltraps
801070df:	e9 40 f6 ff ff       	jmp    80106724 <alltraps>

801070e4 <vector90>:
.globl vector90
vector90:
  pushl $0
801070e4:	6a 00                	push   $0x0
  pushl $90
801070e6:	6a 5a                	push   $0x5a
  jmp alltraps
801070e8:	e9 37 f6 ff ff       	jmp    80106724 <alltraps>

801070ed <vector91>:
.globl vector91
vector91:
  pushl $0
801070ed:	6a 00                	push   $0x0
  pushl $91
801070ef:	6a 5b                	push   $0x5b
  jmp alltraps
801070f1:	e9 2e f6 ff ff       	jmp    80106724 <alltraps>

801070f6 <vector92>:
.globl vector92
vector92:
  pushl $0
801070f6:	6a 00                	push   $0x0
  pushl $92
801070f8:	6a 5c                	push   $0x5c
  jmp alltraps
801070fa:	e9 25 f6 ff ff       	jmp    80106724 <alltraps>

801070ff <vector93>:
.globl vector93
vector93:
  pushl $0
801070ff:	6a 00                	push   $0x0
  pushl $93
80107101:	6a 5d                	push   $0x5d
  jmp alltraps
80107103:	e9 1c f6 ff ff       	jmp    80106724 <alltraps>

80107108 <vector94>:
.globl vector94
vector94:
  pushl $0
80107108:	6a 00                	push   $0x0
  pushl $94
8010710a:	6a 5e                	push   $0x5e
  jmp alltraps
8010710c:	e9 13 f6 ff ff       	jmp    80106724 <alltraps>

80107111 <vector95>:
.globl vector95
vector95:
  pushl $0
80107111:	6a 00                	push   $0x0
  pushl $95
80107113:	6a 5f                	push   $0x5f
  jmp alltraps
80107115:	e9 0a f6 ff ff       	jmp    80106724 <alltraps>

8010711a <vector96>:
.globl vector96
vector96:
  pushl $0
8010711a:	6a 00                	push   $0x0
  pushl $96
8010711c:	6a 60                	push   $0x60
  jmp alltraps
8010711e:	e9 01 f6 ff ff       	jmp    80106724 <alltraps>

80107123 <vector97>:
.globl vector97
vector97:
  pushl $0
80107123:	6a 00                	push   $0x0
  pushl $97
80107125:	6a 61                	push   $0x61
  jmp alltraps
80107127:	e9 f8 f5 ff ff       	jmp    80106724 <alltraps>

8010712c <vector98>:
.globl vector98
vector98:
  pushl $0
8010712c:	6a 00                	push   $0x0
  pushl $98
8010712e:	6a 62                	push   $0x62
  jmp alltraps
80107130:	e9 ef f5 ff ff       	jmp    80106724 <alltraps>

80107135 <vector99>:
.globl vector99
vector99:
  pushl $0
80107135:	6a 00                	push   $0x0
  pushl $99
80107137:	6a 63                	push   $0x63
  jmp alltraps
80107139:	e9 e6 f5 ff ff       	jmp    80106724 <alltraps>

8010713e <vector100>:
.globl vector100
vector100:
  pushl $0
8010713e:	6a 00                	push   $0x0
  pushl $100
80107140:	6a 64                	push   $0x64
  jmp alltraps
80107142:	e9 dd f5 ff ff       	jmp    80106724 <alltraps>

80107147 <vector101>:
.globl vector101
vector101:
  pushl $0
80107147:	6a 00                	push   $0x0
  pushl $101
80107149:	6a 65                	push   $0x65
  jmp alltraps
8010714b:	e9 d4 f5 ff ff       	jmp    80106724 <alltraps>

80107150 <vector102>:
.globl vector102
vector102:
  pushl $0
80107150:	6a 00                	push   $0x0
  pushl $102
80107152:	6a 66                	push   $0x66
  jmp alltraps
80107154:	e9 cb f5 ff ff       	jmp    80106724 <alltraps>

80107159 <vector103>:
.globl vector103
vector103:
  pushl $0
80107159:	6a 00                	push   $0x0
  pushl $103
8010715b:	6a 67                	push   $0x67
  jmp alltraps
8010715d:	e9 c2 f5 ff ff       	jmp    80106724 <alltraps>

80107162 <vector104>:
.globl vector104
vector104:
  pushl $0
80107162:	6a 00                	push   $0x0
  pushl $104
80107164:	6a 68                	push   $0x68
  jmp alltraps
80107166:	e9 b9 f5 ff ff       	jmp    80106724 <alltraps>

8010716b <vector105>:
.globl vector105
vector105:
  pushl $0
8010716b:	6a 00                	push   $0x0
  pushl $105
8010716d:	6a 69                	push   $0x69
  jmp alltraps
8010716f:	e9 b0 f5 ff ff       	jmp    80106724 <alltraps>

80107174 <vector106>:
.globl vector106
vector106:
  pushl $0
80107174:	6a 00                	push   $0x0
  pushl $106
80107176:	6a 6a                	push   $0x6a
  jmp alltraps
80107178:	e9 a7 f5 ff ff       	jmp    80106724 <alltraps>

8010717d <vector107>:
.globl vector107
vector107:
  pushl $0
8010717d:	6a 00                	push   $0x0
  pushl $107
8010717f:	6a 6b                	push   $0x6b
  jmp alltraps
80107181:	e9 9e f5 ff ff       	jmp    80106724 <alltraps>

80107186 <vector108>:
.globl vector108
vector108:
  pushl $0
80107186:	6a 00                	push   $0x0
  pushl $108
80107188:	6a 6c                	push   $0x6c
  jmp alltraps
8010718a:	e9 95 f5 ff ff       	jmp    80106724 <alltraps>

8010718f <vector109>:
.globl vector109
vector109:
  pushl $0
8010718f:	6a 00                	push   $0x0
  pushl $109
80107191:	6a 6d                	push   $0x6d
  jmp alltraps
80107193:	e9 8c f5 ff ff       	jmp    80106724 <alltraps>

80107198 <vector110>:
.globl vector110
vector110:
  pushl $0
80107198:	6a 00                	push   $0x0
  pushl $110
8010719a:	6a 6e                	push   $0x6e
  jmp alltraps
8010719c:	e9 83 f5 ff ff       	jmp    80106724 <alltraps>

801071a1 <vector111>:
.globl vector111
vector111:
  pushl $0
801071a1:	6a 00                	push   $0x0
  pushl $111
801071a3:	6a 6f                	push   $0x6f
  jmp alltraps
801071a5:	e9 7a f5 ff ff       	jmp    80106724 <alltraps>

801071aa <vector112>:
.globl vector112
vector112:
  pushl $0
801071aa:	6a 00                	push   $0x0
  pushl $112
801071ac:	6a 70                	push   $0x70
  jmp alltraps
801071ae:	e9 71 f5 ff ff       	jmp    80106724 <alltraps>

801071b3 <vector113>:
.globl vector113
vector113:
  pushl $0
801071b3:	6a 00                	push   $0x0
  pushl $113
801071b5:	6a 71                	push   $0x71
  jmp alltraps
801071b7:	e9 68 f5 ff ff       	jmp    80106724 <alltraps>

801071bc <vector114>:
.globl vector114
vector114:
  pushl $0
801071bc:	6a 00                	push   $0x0
  pushl $114
801071be:	6a 72                	push   $0x72
  jmp alltraps
801071c0:	e9 5f f5 ff ff       	jmp    80106724 <alltraps>

801071c5 <vector115>:
.globl vector115
vector115:
  pushl $0
801071c5:	6a 00                	push   $0x0
  pushl $115
801071c7:	6a 73                	push   $0x73
  jmp alltraps
801071c9:	e9 56 f5 ff ff       	jmp    80106724 <alltraps>

801071ce <vector116>:
.globl vector116
vector116:
  pushl $0
801071ce:	6a 00                	push   $0x0
  pushl $116
801071d0:	6a 74                	push   $0x74
  jmp alltraps
801071d2:	e9 4d f5 ff ff       	jmp    80106724 <alltraps>

801071d7 <vector117>:
.globl vector117
vector117:
  pushl $0
801071d7:	6a 00                	push   $0x0
  pushl $117
801071d9:	6a 75                	push   $0x75
  jmp alltraps
801071db:	e9 44 f5 ff ff       	jmp    80106724 <alltraps>

801071e0 <vector118>:
.globl vector118
vector118:
  pushl $0
801071e0:	6a 00                	push   $0x0
  pushl $118
801071e2:	6a 76                	push   $0x76
  jmp alltraps
801071e4:	e9 3b f5 ff ff       	jmp    80106724 <alltraps>

801071e9 <vector119>:
.globl vector119
vector119:
  pushl $0
801071e9:	6a 00                	push   $0x0
  pushl $119
801071eb:	6a 77                	push   $0x77
  jmp alltraps
801071ed:	e9 32 f5 ff ff       	jmp    80106724 <alltraps>

801071f2 <vector120>:
.globl vector120
vector120:
  pushl $0
801071f2:	6a 00                	push   $0x0
  pushl $120
801071f4:	6a 78                	push   $0x78
  jmp alltraps
801071f6:	e9 29 f5 ff ff       	jmp    80106724 <alltraps>

801071fb <vector121>:
.globl vector121
vector121:
  pushl $0
801071fb:	6a 00                	push   $0x0
  pushl $121
801071fd:	6a 79                	push   $0x79
  jmp alltraps
801071ff:	e9 20 f5 ff ff       	jmp    80106724 <alltraps>

80107204 <vector122>:
.globl vector122
vector122:
  pushl $0
80107204:	6a 00                	push   $0x0
  pushl $122
80107206:	6a 7a                	push   $0x7a
  jmp alltraps
80107208:	e9 17 f5 ff ff       	jmp    80106724 <alltraps>

8010720d <vector123>:
.globl vector123
vector123:
  pushl $0
8010720d:	6a 00                	push   $0x0
  pushl $123
8010720f:	6a 7b                	push   $0x7b
  jmp alltraps
80107211:	e9 0e f5 ff ff       	jmp    80106724 <alltraps>

80107216 <vector124>:
.globl vector124
vector124:
  pushl $0
80107216:	6a 00                	push   $0x0
  pushl $124
80107218:	6a 7c                	push   $0x7c
  jmp alltraps
8010721a:	e9 05 f5 ff ff       	jmp    80106724 <alltraps>

8010721f <vector125>:
.globl vector125
vector125:
  pushl $0
8010721f:	6a 00                	push   $0x0
  pushl $125
80107221:	6a 7d                	push   $0x7d
  jmp alltraps
80107223:	e9 fc f4 ff ff       	jmp    80106724 <alltraps>

80107228 <vector126>:
.globl vector126
vector126:
  pushl $0
80107228:	6a 00                	push   $0x0
  pushl $126
8010722a:	6a 7e                	push   $0x7e
  jmp alltraps
8010722c:	e9 f3 f4 ff ff       	jmp    80106724 <alltraps>

80107231 <vector127>:
.globl vector127
vector127:
  pushl $0
80107231:	6a 00                	push   $0x0
  pushl $127
80107233:	6a 7f                	push   $0x7f
  jmp alltraps
80107235:	e9 ea f4 ff ff       	jmp    80106724 <alltraps>

8010723a <vector128>:
.globl vector128
vector128:
  pushl $0
8010723a:	6a 00                	push   $0x0
  pushl $128
8010723c:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80107241:	e9 de f4 ff ff       	jmp    80106724 <alltraps>

80107246 <vector129>:
.globl vector129
vector129:
  pushl $0
80107246:	6a 00                	push   $0x0
  pushl $129
80107248:	68 81 00 00 00       	push   $0x81
  jmp alltraps
8010724d:	e9 d2 f4 ff ff       	jmp    80106724 <alltraps>

80107252 <vector130>:
.globl vector130
vector130:
  pushl $0
80107252:	6a 00                	push   $0x0
  pushl $130
80107254:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80107259:	e9 c6 f4 ff ff       	jmp    80106724 <alltraps>

8010725e <vector131>:
.globl vector131
vector131:
  pushl $0
8010725e:	6a 00                	push   $0x0
  pushl $131
80107260:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80107265:	e9 ba f4 ff ff       	jmp    80106724 <alltraps>

8010726a <vector132>:
.globl vector132
vector132:
  pushl $0
8010726a:	6a 00                	push   $0x0
  pushl $132
8010726c:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80107271:	e9 ae f4 ff ff       	jmp    80106724 <alltraps>

80107276 <vector133>:
.globl vector133
vector133:
  pushl $0
80107276:	6a 00                	push   $0x0
  pushl $133
80107278:	68 85 00 00 00       	push   $0x85
  jmp alltraps
8010727d:	e9 a2 f4 ff ff       	jmp    80106724 <alltraps>

80107282 <vector134>:
.globl vector134
vector134:
  pushl $0
80107282:	6a 00                	push   $0x0
  pushl $134
80107284:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80107289:	e9 96 f4 ff ff       	jmp    80106724 <alltraps>

8010728e <vector135>:
.globl vector135
vector135:
  pushl $0
8010728e:	6a 00                	push   $0x0
  pushl $135
80107290:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80107295:	e9 8a f4 ff ff       	jmp    80106724 <alltraps>

8010729a <vector136>:
.globl vector136
vector136:
  pushl $0
8010729a:	6a 00                	push   $0x0
  pushl $136
8010729c:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801072a1:	e9 7e f4 ff ff       	jmp    80106724 <alltraps>

801072a6 <vector137>:
.globl vector137
vector137:
  pushl $0
801072a6:	6a 00                	push   $0x0
  pushl $137
801072a8:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801072ad:	e9 72 f4 ff ff       	jmp    80106724 <alltraps>

801072b2 <vector138>:
.globl vector138
vector138:
  pushl $0
801072b2:	6a 00                	push   $0x0
  pushl $138
801072b4:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801072b9:	e9 66 f4 ff ff       	jmp    80106724 <alltraps>

801072be <vector139>:
.globl vector139
vector139:
  pushl $0
801072be:	6a 00                	push   $0x0
  pushl $139
801072c0:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801072c5:	e9 5a f4 ff ff       	jmp    80106724 <alltraps>

801072ca <vector140>:
.globl vector140
vector140:
  pushl $0
801072ca:	6a 00                	push   $0x0
  pushl $140
801072cc:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801072d1:	e9 4e f4 ff ff       	jmp    80106724 <alltraps>

801072d6 <vector141>:
.globl vector141
vector141:
  pushl $0
801072d6:	6a 00                	push   $0x0
  pushl $141
801072d8:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
801072dd:	e9 42 f4 ff ff       	jmp    80106724 <alltraps>

801072e2 <vector142>:
.globl vector142
vector142:
  pushl $0
801072e2:	6a 00                	push   $0x0
  pushl $142
801072e4:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
801072e9:	e9 36 f4 ff ff       	jmp    80106724 <alltraps>

801072ee <vector143>:
.globl vector143
vector143:
  pushl $0
801072ee:	6a 00                	push   $0x0
  pushl $143
801072f0:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
801072f5:	e9 2a f4 ff ff       	jmp    80106724 <alltraps>

801072fa <vector144>:
.globl vector144
vector144:
  pushl $0
801072fa:	6a 00                	push   $0x0
  pushl $144
801072fc:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80107301:	e9 1e f4 ff ff       	jmp    80106724 <alltraps>

80107306 <vector145>:
.globl vector145
vector145:
  pushl $0
80107306:	6a 00                	push   $0x0
  pushl $145
80107308:	68 91 00 00 00       	push   $0x91
  jmp alltraps
8010730d:	e9 12 f4 ff ff       	jmp    80106724 <alltraps>

80107312 <vector146>:
.globl vector146
vector146:
  pushl $0
80107312:	6a 00                	push   $0x0
  pushl $146
80107314:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80107319:	e9 06 f4 ff ff       	jmp    80106724 <alltraps>

8010731e <vector147>:
.globl vector147
vector147:
  pushl $0
8010731e:	6a 00                	push   $0x0
  pushl $147
80107320:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80107325:	e9 fa f3 ff ff       	jmp    80106724 <alltraps>

8010732a <vector148>:
.globl vector148
vector148:
  pushl $0
8010732a:	6a 00                	push   $0x0
  pushl $148
8010732c:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80107331:	e9 ee f3 ff ff       	jmp    80106724 <alltraps>

80107336 <vector149>:
.globl vector149
vector149:
  pushl $0
80107336:	6a 00                	push   $0x0
  pushl $149
80107338:	68 95 00 00 00       	push   $0x95
  jmp alltraps
8010733d:	e9 e2 f3 ff ff       	jmp    80106724 <alltraps>

80107342 <vector150>:
.globl vector150
vector150:
  pushl $0
80107342:	6a 00                	push   $0x0
  pushl $150
80107344:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80107349:	e9 d6 f3 ff ff       	jmp    80106724 <alltraps>

8010734e <vector151>:
.globl vector151
vector151:
  pushl $0
8010734e:	6a 00                	push   $0x0
  pushl $151
80107350:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80107355:	e9 ca f3 ff ff       	jmp    80106724 <alltraps>

8010735a <vector152>:
.globl vector152
vector152:
  pushl $0
8010735a:	6a 00                	push   $0x0
  pushl $152
8010735c:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107361:	e9 be f3 ff ff       	jmp    80106724 <alltraps>

80107366 <vector153>:
.globl vector153
vector153:
  pushl $0
80107366:	6a 00                	push   $0x0
  pushl $153
80107368:	68 99 00 00 00       	push   $0x99
  jmp alltraps
8010736d:	e9 b2 f3 ff ff       	jmp    80106724 <alltraps>

80107372 <vector154>:
.globl vector154
vector154:
  pushl $0
80107372:	6a 00                	push   $0x0
  pushl $154
80107374:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80107379:	e9 a6 f3 ff ff       	jmp    80106724 <alltraps>

8010737e <vector155>:
.globl vector155
vector155:
  pushl $0
8010737e:	6a 00                	push   $0x0
  pushl $155
80107380:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107385:	e9 9a f3 ff ff       	jmp    80106724 <alltraps>

8010738a <vector156>:
.globl vector156
vector156:
  pushl $0
8010738a:	6a 00                	push   $0x0
  pushl $156
8010738c:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107391:	e9 8e f3 ff ff       	jmp    80106724 <alltraps>

80107396 <vector157>:
.globl vector157
vector157:
  pushl $0
80107396:	6a 00                	push   $0x0
  pushl $157
80107398:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
8010739d:	e9 82 f3 ff ff       	jmp    80106724 <alltraps>

801073a2 <vector158>:
.globl vector158
vector158:
  pushl $0
801073a2:	6a 00                	push   $0x0
  pushl $158
801073a4:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
801073a9:	e9 76 f3 ff ff       	jmp    80106724 <alltraps>

801073ae <vector159>:
.globl vector159
vector159:
  pushl $0
801073ae:	6a 00                	push   $0x0
  pushl $159
801073b0:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
801073b5:	e9 6a f3 ff ff       	jmp    80106724 <alltraps>

801073ba <vector160>:
.globl vector160
vector160:
  pushl $0
801073ba:	6a 00                	push   $0x0
  pushl $160
801073bc:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
801073c1:	e9 5e f3 ff ff       	jmp    80106724 <alltraps>

801073c6 <vector161>:
.globl vector161
vector161:
  pushl $0
801073c6:	6a 00                	push   $0x0
  pushl $161
801073c8:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
801073cd:	e9 52 f3 ff ff       	jmp    80106724 <alltraps>

801073d2 <vector162>:
.globl vector162
vector162:
  pushl $0
801073d2:	6a 00                	push   $0x0
  pushl $162
801073d4:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
801073d9:	e9 46 f3 ff ff       	jmp    80106724 <alltraps>

801073de <vector163>:
.globl vector163
vector163:
  pushl $0
801073de:	6a 00                	push   $0x0
  pushl $163
801073e0:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
801073e5:	e9 3a f3 ff ff       	jmp    80106724 <alltraps>

801073ea <vector164>:
.globl vector164
vector164:
  pushl $0
801073ea:	6a 00                	push   $0x0
  pushl $164
801073ec:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
801073f1:	e9 2e f3 ff ff       	jmp    80106724 <alltraps>

801073f6 <vector165>:
.globl vector165
vector165:
  pushl $0
801073f6:	6a 00                	push   $0x0
  pushl $165
801073f8:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
801073fd:	e9 22 f3 ff ff       	jmp    80106724 <alltraps>

80107402 <vector166>:
.globl vector166
vector166:
  pushl $0
80107402:	6a 00                	push   $0x0
  pushl $166
80107404:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107409:	e9 16 f3 ff ff       	jmp    80106724 <alltraps>

8010740e <vector167>:
.globl vector167
vector167:
  pushl $0
8010740e:	6a 00                	push   $0x0
  pushl $167
80107410:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107415:	e9 0a f3 ff ff       	jmp    80106724 <alltraps>

8010741a <vector168>:
.globl vector168
vector168:
  pushl $0
8010741a:	6a 00                	push   $0x0
  pushl $168
8010741c:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107421:	e9 fe f2 ff ff       	jmp    80106724 <alltraps>

80107426 <vector169>:
.globl vector169
vector169:
  pushl $0
80107426:	6a 00                	push   $0x0
  pushl $169
80107428:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
8010742d:	e9 f2 f2 ff ff       	jmp    80106724 <alltraps>

80107432 <vector170>:
.globl vector170
vector170:
  pushl $0
80107432:	6a 00                	push   $0x0
  pushl $170
80107434:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107439:	e9 e6 f2 ff ff       	jmp    80106724 <alltraps>

8010743e <vector171>:
.globl vector171
vector171:
  pushl $0
8010743e:	6a 00                	push   $0x0
  pushl $171
80107440:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107445:	e9 da f2 ff ff       	jmp    80106724 <alltraps>

8010744a <vector172>:
.globl vector172
vector172:
  pushl $0
8010744a:	6a 00                	push   $0x0
  pushl $172
8010744c:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107451:	e9 ce f2 ff ff       	jmp    80106724 <alltraps>

80107456 <vector173>:
.globl vector173
vector173:
  pushl $0
80107456:	6a 00                	push   $0x0
  pushl $173
80107458:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
8010745d:	e9 c2 f2 ff ff       	jmp    80106724 <alltraps>

80107462 <vector174>:
.globl vector174
vector174:
  pushl $0
80107462:	6a 00                	push   $0x0
  pushl $174
80107464:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107469:	e9 b6 f2 ff ff       	jmp    80106724 <alltraps>

8010746e <vector175>:
.globl vector175
vector175:
  pushl $0
8010746e:	6a 00                	push   $0x0
  pushl $175
80107470:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107475:	e9 aa f2 ff ff       	jmp    80106724 <alltraps>

8010747a <vector176>:
.globl vector176
vector176:
  pushl $0
8010747a:	6a 00                	push   $0x0
  pushl $176
8010747c:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107481:	e9 9e f2 ff ff       	jmp    80106724 <alltraps>

80107486 <vector177>:
.globl vector177
vector177:
  pushl $0
80107486:	6a 00                	push   $0x0
  pushl $177
80107488:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
8010748d:	e9 92 f2 ff ff       	jmp    80106724 <alltraps>

80107492 <vector178>:
.globl vector178
vector178:
  pushl $0
80107492:	6a 00                	push   $0x0
  pushl $178
80107494:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107499:	e9 86 f2 ff ff       	jmp    80106724 <alltraps>

8010749e <vector179>:
.globl vector179
vector179:
  pushl $0
8010749e:	6a 00                	push   $0x0
  pushl $179
801074a0:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
801074a5:	e9 7a f2 ff ff       	jmp    80106724 <alltraps>

801074aa <vector180>:
.globl vector180
vector180:
  pushl $0
801074aa:	6a 00                	push   $0x0
  pushl $180
801074ac:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
801074b1:	e9 6e f2 ff ff       	jmp    80106724 <alltraps>

801074b6 <vector181>:
.globl vector181
vector181:
  pushl $0
801074b6:	6a 00                	push   $0x0
  pushl $181
801074b8:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
801074bd:	e9 62 f2 ff ff       	jmp    80106724 <alltraps>

801074c2 <vector182>:
.globl vector182
vector182:
  pushl $0
801074c2:	6a 00                	push   $0x0
  pushl $182
801074c4:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
801074c9:	e9 56 f2 ff ff       	jmp    80106724 <alltraps>

801074ce <vector183>:
.globl vector183
vector183:
  pushl $0
801074ce:	6a 00                	push   $0x0
  pushl $183
801074d0:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
801074d5:	e9 4a f2 ff ff       	jmp    80106724 <alltraps>

801074da <vector184>:
.globl vector184
vector184:
  pushl $0
801074da:	6a 00                	push   $0x0
  pushl $184
801074dc:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
801074e1:	e9 3e f2 ff ff       	jmp    80106724 <alltraps>

801074e6 <vector185>:
.globl vector185
vector185:
  pushl $0
801074e6:	6a 00                	push   $0x0
  pushl $185
801074e8:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
801074ed:	e9 32 f2 ff ff       	jmp    80106724 <alltraps>

801074f2 <vector186>:
.globl vector186
vector186:
  pushl $0
801074f2:	6a 00                	push   $0x0
  pushl $186
801074f4:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
801074f9:	e9 26 f2 ff ff       	jmp    80106724 <alltraps>

801074fe <vector187>:
.globl vector187
vector187:
  pushl $0
801074fe:	6a 00                	push   $0x0
  pushl $187
80107500:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107505:	e9 1a f2 ff ff       	jmp    80106724 <alltraps>

8010750a <vector188>:
.globl vector188
vector188:
  pushl $0
8010750a:	6a 00                	push   $0x0
  pushl $188
8010750c:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80107511:	e9 0e f2 ff ff       	jmp    80106724 <alltraps>

80107516 <vector189>:
.globl vector189
vector189:
  pushl $0
80107516:	6a 00                	push   $0x0
  pushl $189
80107518:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
8010751d:	e9 02 f2 ff ff       	jmp    80106724 <alltraps>

80107522 <vector190>:
.globl vector190
vector190:
  pushl $0
80107522:	6a 00                	push   $0x0
  pushl $190
80107524:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80107529:	e9 f6 f1 ff ff       	jmp    80106724 <alltraps>

8010752e <vector191>:
.globl vector191
vector191:
  pushl $0
8010752e:	6a 00                	push   $0x0
  pushl $191
80107530:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107535:	e9 ea f1 ff ff       	jmp    80106724 <alltraps>

8010753a <vector192>:
.globl vector192
vector192:
  pushl $0
8010753a:	6a 00                	push   $0x0
  pushl $192
8010753c:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107541:	e9 de f1 ff ff       	jmp    80106724 <alltraps>

80107546 <vector193>:
.globl vector193
vector193:
  pushl $0
80107546:	6a 00                	push   $0x0
  pushl $193
80107548:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
8010754d:	e9 d2 f1 ff ff       	jmp    80106724 <alltraps>

80107552 <vector194>:
.globl vector194
vector194:
  pushl $0
80107552:	6a 00                	push   $0x0
  pushl $194
80107554:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80107559:	e9 c6 f1 ff ff       	jmp    80106724 <alltraps>

8010755e <vector195>:
.globl vector195
vector195:
  pushl $0
8010755e:	6a 00                	push   $0x0
  pushl $195
80107560:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107565:	e9 ba f1 ff ff       	jmp    80106724 <alltraps>

8010756a <vector196>:
.globl vector196
vector196:
  pushl $0
8010756a:	6a 00                	push   $0x0
  pushl $196
8010756c:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107571:	e9 ae f1 ff ff       	jmp    80106724 <alltraps>

80107576 <vector197>:
.globl vector197
vector197:
  pushl $0
80107576:	6a 00                	push   $0x0
  pushl $197
80107578:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
8010757d:	e9 a2 f1 ff ff       	jmp    80106724 <alltraps>

80107582 <vector198>:
.globl vector198
vector198:
  pushl $0
80107582:	6a 00                	push   $0x0
  pushl $198
80107584:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80107589:	e9 96 f1 ff ff       	jmp    80106724 <alltraps>

8010758e <vector199>:
.globl vector199
vector199:
  pushl $0
8010758e:	6a 00                	push   $0x0
  pushl $199
80107590:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107595:	e9 8a f1 ff ff       	jmp    80106724 <alltraps>

8010759a <vector200>:
.globl vector200
vector200:
  pushl $0
8010759a:	6a 00                	push   $0x0
  pushl $200
8010759c:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
801075a1:	e9 7e f1 ff ff       	jmp    80106724 <alltraps>

801075a6 <vector201>:
.globl vector201
vector201:
  pushl $0
801075a6:	6a 00                	push   $0x0
  pushl $201
801075a8:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
801075ad:	e9 72 f1 ff ff       	jmp    80106724 <alltraps>

801075b2 <vector202>:
.globl vector202
vector202:
  pushl $0
801075b2:	6a 00                	push   $0x0
  pushl $202
801075b4:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
801075b9:	e9 66 f1 ff ff       	jmp    80106724 <alltraps>

801075be <vector203>:
.globl vector203
vector203:
  pushl $0
801075be:	6a 00                	push   $0x0
  pushl $203
801075c0:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
801075c5:	e9 5a f1 ff ff       	jmp    80106724 <alltraps>

801075ca <vector204>:
.globl vector204
vector204:
  pushl $0
801075ca:	6a 00                	push   $0x0
  pushl $204
801075cc:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
801075d1:	e9 4e f1 ff ff       	jmp    80106724 <alltraps>

801075d6 <vector205>:
.globl vector205
vector205:
  pushl $0
801075d6:	6a 00                	push   $0x0
  pushl $205
801075d8:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
801075dd:	e9 42 f1 ff ff       	jmp    80106724 <alltraps>

801075e2 <vector206>:
.globl vector206
vector206:
  pushl $0
801075e2:	6a 00                	push   $0x0
  pushl $206
801075e4:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
801075e9:	e9 36 f1 ff ff       	jmp    80106724 <alltraps>

801075ee <vector207>:
.globl vector207
vector207:
  pushl $0
801075ee:	6a 00                	push   $0x0
  pushl $207
801075f0:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
801075f5:	e9 2a f1 ff ff       	jmp    80106724 <alltraps>

801075fa <vector208>:
.globl vector208
vector208:
  pushl $0
801075fa:	6a 00                	push   $0x0
  pushl $208
801075fc:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80107601:	e9 1e f1 ff ff       	jmp    80106724 <alltraps>

80107606 <vector209>:
.globl vector209
vector209:
  pushl $0
80107606:	6a 00                	push   $0x0
  pushl $209
80107608:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
8010760d:	e9 12 f1 ff ff       	jmp    80106724 <alltraps>

80107612 <vector210>:
.globl vector210
vector210:
  pushl $0
80107612:	6a 00                	push   $0x0
  pushl $210
80107614:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80107619:	e9 06 f1 ff ff       	jmp    80106724 <alltraps>

8010761e <vector211>:
.globl vector211
vector211:
  pushl $0
8010761e:	6a 00                	push   $0x0
  pushl $211
80107620:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107625:	e9 fa f0 ff ff       	jmp    80106724 <alltraps>

8010762a <vector212>:
.globl vector212
vector212:
  pushl $0
8010762a:	6a 00                	push   $0x0
  pushl $212
8010762c:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107631:	e9 ee f0 ff ff       	jmp    80106724 <alltraps>

80107636 <vector213>:
.globl vector213
vector213:
  pushl $0
80107636:	6a 00                	push   $0x0
  pushl $213
80107638:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
8010763d:	e9 e2 f0 ff ff       	jmp    80106724 <alltraps>

80107642 <vector214>:
.globl vector214
vector214:
  pushl $0
80107642:	6a 00                	push   $0x0
  pushl $214
80107644:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80107649:	e9 d6 f0 ff ff       	jmp    80106724 <alltraps>

8010764e <vector215>:
.globl vector215
vector215:
  pushl $0
8010764e:	6a 00                	push   $0x0
  pushl $215
80107650:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107655:	e9 ca f0 ff ff       	jmp    80106724 <alltraps>

8010765a <vector216>:
.globl vector216
vector216:
  pushl $0
8010765a:	6a 00                	push   $0x0
  pushl $216
8010765c:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107661:	e9 be f0 ff ff       	jmp    80106724 <alltraps>

80107666 <vector217>:
.globl vector217
vector217:
  pushl $0
80107666:	6a 00                	push   $0x0
  pushl $217
80107668:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
8010766d:	e9 b2 f0 ff ff       	jmp    80106724 <alltraps>

80107672 <vector218>:
.globl vector218
vector218:
  pushl $0
80107672:	6a 00                	push   $0x0
  pushl $218
80107674:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80107679:	e9 a6 f0 ff ff       	jmp    80106724 <alltraps>

8010767e <vector219>:
.globl vector219
vector219:
  pushl $0
8010767e:	6a 00                	push   $0x0
  pushl $219
80107680:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107685:	e9 9a f0 ff ff       	jmp    80106724 <alltraps>

8010768a <vector220>:
.globl vector220
vector220:
  pushl $0
8010768a:	6a 00                	push   $0x0
  pushl $220
8010768c:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80107691:	e9 8e f0 ff ff       	jmp    80106724 <alltraps>

80107696 <vector221>:
.globl vector221
vector221:
  pushl $0
80107696:	6a 00                	push   $0x0
  pushl $221
80107698:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
8010769d:	e9 82 f0 ff ff       	jmp    80106724 <alltraps>

801076a2 <vector222>:
.globl vector222
vector222:
  pushl $0
801076a2:	6a 00                	push   $0x0
  pushl $222
801076a4:	68 de 00 00 00       	push   $0xde
  jmp alltraps
801076a9:	e9 76 f0 ff ff       	jmp    80106724 <alltraps>

801076ae <vector223>:
.globl vector223
vector223:
  pushl $0
801076ae:	6a 00                	push   $0x0
  pushl $223
801076b0:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
801076b5:	e9 6a f0 ff ff       	jmp    80106724 <alltraps>

801076ba <vector224>:
.globl vector224
vector224:
  pushl $0
801076ba:	6a 00                	push   $0x0
  pushl $224
801076bc:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
801076c1:	e9 5e f0 ff ff       	jmp    80106724 <alltraps>

801076c6 <vector225>:
.globl vector225
vector225:
  pushl $0
801076c6:	6a 00                	push   $0x0
  pushl $225
801076c8:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
801076cd:	e9 52 f0 ff ff       	jmp    80106724 <alltraps>

801076d2 <vector226>:
.globl vector226
vector226:
  pushl $0
801076d2:	6a 00                	push   $0x0
  pushl $226
801076d4:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
801076d9:	e9 46 f0 ff ff       	jmp    80106724 <alltraps>

801076de <vector227>:
.globl vector227
vector227:
  pushl $0
801076de:	6a 00                	push   $0x0
  pushl $227
801076e0:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
801076e5:	e9 3a f0 ff ff       	jmp    80106724 <alltraps>

801076ea <vector228>:
.globl vector228
vector228:
  pushl $0
801076ea:	6a 00                	push   $0x0
  pushl $228
801076ec:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
801076f1:	e9 2e f0 ff ff       	jmp    80106724 <alltraps>

801076f6 <vector229>:
.globl vector229
vector229:
  pushl $0
801076f6:	6a 00                	push   $0x0
  pushl $229
801076f8:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
801076fd:	e9 22 f0 ff ff       	jmp    80106724 <alltraps>

80107702 <vector230>:
.globl vector230
vector230:
  pushl $0
80107702:	6a 00                	push   $0x0
  pushl $230
80107704:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80107709:	e9 16 f0 ff ff       	jmp    80106724 <alltraps>

8010770e <vector231>:
.globl vector231
vector231:
  pushl $0
8010770e:	6a 00                	push   $0x0
  pushl $231
80107710:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80107715:	e9 0a f0 ff ff       	jmp    80106724 <alltraps>

8010771a <vector232>:
.globl vector232
vector232:
  pushl $0
8010771a:	6a 00                	push   $0x0
  pushl $232
8010771c:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80107721:	e9 fe ef ff ff       	jmp    80106724 <alltraps>

80107726 <vector233>:
.globl vector233
vector233:
  pushl $0
80107726:	6a 00                	push   $0x0
  pushl $233
80107728:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
8010772d:	e9 f2 ef ff ff       	jmp    80106724 <alltraps>

80107732 <vector234>:
.globl vector234
vector234:
  pushl $0
80107732:	6a 00                	push   $0x0
  pushl $234
80107734:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80107739:	e9 e6 ef ff ff       	jmp    80106724 <alltraps>

8010773e <vector235>:
.globl vector235
vector235:
  pushl $0
8010773e:	6a 00                	push   $0x0
  pushl $235
80107740:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107745:	e9 da ef ff ff       	jmp    80106724 <alltraps>

8010774a <vector236>:
.globl vector236
vector236:
  pushl $0
8010774a:	6a 00                	push   $0x0
  pushl $236
8010774c:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80107751:	e9 ce ef ff ff       	jmp    80106724 <alltraps>

80107756 <vector237>:
.globl vector237
vector237:
  pushl $0
80107756:	6a 00                	push   $0x0
  pushl $237
80107758:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
8010775d:	e9 c2 ef ff ff       	jmp    80106724 <alltraps>

80107762 <vector238>:
.globl vector238
vector238:
  pushl $0
80107762:	6a 00                	push   $0x0
  pushl $238
80107764:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80107769:	e9 b6 ef ff ff       	jmp    80106724 <alltraps>

8010776e <vector239>:
.globl vector239
vector239:
  pushl $0
8010776e:	6a 00                	push   $0x0
  pushl $239
80107770:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107775:	e9 aa ef ff ff       	jmp    80106724 <alltraps>

8010777a <vector240>:
.globl vector240
vector240:
  pushl $0
8010777a:	6a 00                	push   $0x0
  pushl $240
8010777c:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80107781:	e9 9e ef ff ff       	jmp    80106724 <alltraps>

80107786 <vector241>:
.globl vector241
vector241:
  pushl $0
80107786:	6a 00                	push   $0x0
  pushl $241
80107788:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
8010778d:	e9 92 ef ff ff       	jmp    80106724 <alltraps>

80107792 <vector242>:
.globl vector242
vector242:
  pushl $0
80107792:	6a 00                	push   $0x0
  pushl $242
80107794:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80107799:	e9 86 ef ff ff       	jmp    80106724 <alltraps>

8010779e <vector243>:
.globl vector243
vector243:
  pushl $0
8010779e:	6a 00                	push   $0x0
  pushl $243
801077a0:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
801077a5:	e9 7a ef ff ff       	jmp    80106724 <alltraps>

801077aa <vector244>:
.globl vector244
vector244:
  pushl $0
801077aa:	6a 00                	push   $0x0
  pushl $244
801077ac:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
801077b1:	e9 6e ef ff ff       	jmp    80106724 <alltraps>

801077b6 <vector245>:
.globl vector245
vector245:
  pushl $0
801077b6:	6a 00                	push   $0x0
  pushl $245
801077b8:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
801077bd:	e9 62 ef ff ff       	jmp    80106724 <alltraps>

801077c2 <vector246>:
.globl vector246
vector246:
  pushl $0
801077c2:	6a 00                	push   $0x0
  pushl $246
801077c4:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
801077c9:	e9 56 ef ff ff       	jmp    80106724 <alltraps>

801077ce <vector247>:
.globl vector247
vector247:
  pushl $0
801077ce:	6a 00                	push   $0x0
  pushl $247
801077d0:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
801077d5:	e9 4a ef ff ff       	jmp    80106724 <alltraps>

801077da <vector248>:
.globl vector248
vector248:
  pushl $0
801077da:	6a 00                	push   $0x0
  pushl $248
801077dc:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
801077e1:	e9 3e ef ff ff       	jmp    80106724 <alltraps>

801077e6 <vector249>:
.globl vector249
vector249:
  pushl $0
801077e6:	6a 00                	push   $0x0
  pushl $249
801077e8:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
801077ed:	e9 32 ef ff ff       	jmp    80106724 <alltraps>

801077f2 <vector250>:
.globl vector250
vector250:
  pushl $0
801077f2:	6a 00                	push   $0x0
  pushl $250
801077f4:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
801077f9:	e9 26 ef ff ff       	jmp    80106724 <alltraps>

801077fe <vector251>:
.globl vector251
vector251:
  pushl $0
801077fe:	6a 00                	push   $0x0
  pushl $251
80107800:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80107805:	e9 1a ef ff ff       	jmp    80106724 <alltraps>

8010780a <vector252>:
.globl vector252
vector252:
  pushl $0
8010780a:	6a 00                	push   $0x0
  pushl $252
8010780c:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80107811:	e9 0e ef ff ff       	jmp    80106724 <alltraps>

80107816 <vector253>:
.globl vector253
vector253:
  pushl $0
80107816:	6a 00                	push   $0x0
  pushl $253
80107818:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
8010781d:	e9 02 ef ff ff       	jmp    80106724 <alltraps>

80107822 <vector254>:
.globl vector254
vector254:
  pushl $0
80107822:	6a 00                	push   $0x0
  pushl $254
80107824:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80107829:	e9 f6 ee ff ff       	jmp    80106724 <alltraps>

8010782e <vector255>:
.globl vector255
vector255:
  pushl $0
8010782e:	6a 00                	push   $0x0
  pushl $255
80107830:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107835:	e9 ea ee ff ff       	jmp    80106724 <alltraps>
	...

8010783c <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
8010783c:	55                   	push   %ebp
8010783d:	89 e5                	mov    %esp,%ebp
8010783f:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107842:	8b 45 0c             	mov    0xc(%ebp),%eax
80107845:	83 e8 01             	sub    $0x1,%eax
80107848:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
8010784c:	8b 45 08             	mov    0x8(%ebp),%eax
8010784f:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107853:	8b 45 08             	mov    0x8(%ebp),%eax
80107856:	c1 e8 10             	shr    $0x10,%eax
80107859:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
8010785d:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107860:	0f 01 10             	lgdtl  (%eax)
}
80107863:	c9                   	leave  
80107864:	c3                   	ret    

80107865 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107865:	55                   	push   %ebp
80107866:	89 e5                	mov    %esp,%ebp
80107868:	83 ec 04             	sub    $0x4,%esp
8010786b:	8b 45 08             	mov    0x8(%ebp),%eax
8010786e:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80107872:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107876:	0f 00 d8             	ltr    %ax
}
80107879:	c9                   	leave  
8010787a:	c3                   	ret    

8010787b <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
8010787b:	55                   	push   %ebp
8010787c:	89 e5                	mov    %esp,%ebp
8010787e:	83 ec 04             	sub    $0x4,%esp
80107881:	8b 45 08             	mov    0x8(%ebp),%eax
80107884:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80107888:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010788c:	8e e8                	mov    %eax,%gs
}
8010788e:	c9                   	leave  
8010788f:	c3                   	ret    

80107890 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80107890:	55                   	push   %ebp
80107891:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
80107893:	8b 45 08             	mov    0x8(%ebp),%eax
80107896:	0f 22 d8             	mov    %eax,%cr3
}
80107899:	5d                   	pop    %ebp
8010789a:	c3                   	ret    

8010789b <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
8010789b:	55                   	push   %ebp
8010789c:	89 e5                	mov    %esp,%ebp
8010789e:	8b 45 08             	mov    0x8(%ebp),%eax
801078a1:	05 00 00 00 80       	add    $0x80000000,%eax
801078a6:	5d                   	pop    %ebp
801078a7:	c3                   	ret    

801078a8 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801078a8:	55                   	push   %ebp
801078a9:	89 e5                	mov    %esp,%ebp
801078ab:	8b 45 08             	mov    0x8(%ebp),%eax
801078ae:	05 00 00 00 80       	add    $0x80000000,%eax
801078b3:	5d                   	pop    %ebp
801078b4:	c3                   	ret    

801078b5 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
801078b5:	55                   	push   %ebp
801078b6:	89 e5                	mov    %esp,%ebp
801078b8:	53                   	push   %ebx
801078b9:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
801078bc:	e8 32 b6 ff ff       	call   80102ef3 <cpunum>
801078c1:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801078c7:	05 60 23 11 80       	add    $0x80112360,%eax
801078cc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
801078cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078d2:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
801078d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078db:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
801078e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078e4:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
801078e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078eb:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801078ef:	83 e2 f0             	and    $0xfffffff0,%edx
801078f2:	83 ca 0a             	or     $0xa,%edx
801078f5:	88 50 7d             	mov    %dl,0x7d(%eax)
801078f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078fb:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801078ff:	83 ca 10             	or     $0x10,%edx
80107902:	88 50 7d             	mov    %dl,0x7d(%eax)
80107905:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107908:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010790c:	83 e2 9f             	and    $0xffffff9f,%edx
8010790f:	88 50 7d             	mov    %dl,0x7d(%eax)
80107912:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107915:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107919:	83 ca 80             	or     $0xffffff80,%edx
8010791c:	88 50 7d             	mov    %dl,0x7d(%eax)
8010791f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107922:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107926:	83 ca 0f             	or     $0xf,%edx
80107929:	88 50 7e             	mov    %dl,0x7e(%eax)
8010792c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010792f:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107933:	83 e2 ef             	and    $0xffffffef,%edx
80107936:	88 50 7e             	mov    %dl,0x7e(%eax)
80107939:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010793c:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107940:	83 e2 df             	and    $0xffffffdf,%edx
80107943:	88 50 7e             	mov    %dl,0x7e(%eax)
80107946:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107949:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010794d:	83 ca 40             	or     $0x40,%edx
80107950:	88 50 7e             	mov    %dl,0x7e(%eax)
80107953:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107956:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010795a:	83 ca 80             	or     $0xffffff80,%edx
8010795d:	88 50 7e             	mov    %dl,0x7e(%eax)
80107960:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107963:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80107967:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010796a:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80107971:	ff ff 
80107973:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107976:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
8010797d:	00 00 
8010797f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107982:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80107989:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010798c:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107993:	83 e2 f0             	and    $0xfffffff0,%edx
80107996:	83 ca 02             	or     $0x2,%edx
80107999:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010799f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079a2:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801079a9:	83 ca 10             	or     $0x10,%edx
801079ac:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801079b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079b5:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801079bc:	83 e2 9f             	and    $0xffffff9f,%edx
801079bf:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801079c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079c8:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801079cf:	83 ca 80             	or     $0xffffff80,%edx
801079d2:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801079d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079db:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801079e2:	83 ca 0f             	or     $0xf,%edx
801079e5:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801079eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079ee:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801079f5:	83 e2 ef             	and    $0xffffffef,%edx
801079f8:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801079fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a01:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107a08:	83 e2 df             	and    $0xffffffdf,%edx
80107a0b:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107a11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a14:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107a1b:	83 ca 40             	or     $0x40,%edx
80107a1e:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107a24:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a27:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107a2e:	83 ca 80             	or     $0xffffff80,%edx
80107a31:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107a37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a3a:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80107a41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a44:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80107a4b:	ff ff 
80107a4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a50:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80107a57:	00 00 
80107a59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a5c:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80107a63:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a66:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107a6d:	83 e2 f0             	and    $0xfffffff0,%edx
80107a70:	83 ca 0a             	or     $0xa,%edx
80107a73:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107a79:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a7c:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107a83:	83 ca 10             	or     $0x10,%edx
80107a86:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107a8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a8f:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107a96:	83 ca 60             	or     $0x60,%edx
80107a99:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107a9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aa2:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107aa9:	83 ca 80             	or     $0xffffff80,%edx
80107aac:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107ab2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ab5:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107abc:	83 ca 0f             	or     $0xf,%edx
80107abf:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107ac5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ac8:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107acf:	83 e2 ef             	and    $0xffffffef,%edx
80107ad2:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107ad8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107adb:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107ae2:	83 e2 df             	and    $0xffffffdf,%edx
80107ae5:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107aeb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aee:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107af5:	83 ca 40             	or     $0x40,%edx
80107af8:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107afe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b01:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107b08:	83 ca 80             	or     $0xffffff80,%edx
80107b0b:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107b11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b14:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80107b1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b1e:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80107b25:	ff ff 
80107b27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b2a:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80107b31:	00 00 
80107b33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b36:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80107b3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b40:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107b47:	83 e2 f0             	and    $0xfffffff0,%edx
80107b4a:	83 ca 02             	or     $0x2,%edx
80107b4d:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107b53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b56:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107b5d:	83 ca 10             	or     $0x10,%edx
80107b60:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107b66:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b69:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107b70:	83 ca 60             	or     $0x60,%edx
80107b73:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107b79:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b7c:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107b83:	83 ca 80             	or     $0xffffff80,%edx
80107b86:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107b8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b8f:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107b96:	83 ca 0f             	or     $0xf,%edx
80107b99:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107b9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ba2:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107ba9:	83 e2 ef             	and    $0xffffffef,%edx
80107bac:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107bb2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bb5:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107bbc:	83 e2 df             	and    $0xffffffdf,%edx
80107bbf:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107bc5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bc8:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107bcf:	83 ca 40             	or     $0x40,%edx
80107bd2:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107bd8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bdb:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107be2:	83 ca 80             	or     $0xffffff80,%edx
80107be5:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107beb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bee:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80107bf5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bf8:	05 b4 00 00 00       	add    $0xb4,%eax
80107bfd:	89 c3                	mov    %eax,%ebx
80107bff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c02:	05 b4 00 00 00       	add    $0xb4,%eax
80107c07:	c1 e8 10             	shr    $0x10,%eax
80107c0a:	89 c1                	mov    %eax,%ecx
80107c0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c0f:	05 b4 00 00 00       	add    $0xb4,%eax
80107c14:	c1 e8 18             	shr    $0x18,%eax
80107c17:	89 c2                	mov    %eax,%edx
80107c19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c1c:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80107c23:	00 00 
80107c25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c28:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80107c2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c32:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80107c38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c3b:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107c42:	83 e1 f0             	and    $0xfffffff0,%ecx
80107c45:	83 c9 02             	or     $0x2,%ecx
80107c48:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107c4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c51:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107c58:	83 c9 10             	or     $0x10,%ecx
80107c5b:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107c61:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c64:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107c6b:	83 e1 9f             	and    $0xffffff9f,%ecx
80107c6e:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107c74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c77:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107c7e:	83 c9 80             	or     $0xffffff80,%ecx
80107c81:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107c87:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c8a:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107c91:	83 e1 f0             	and    $0xfffffff0,%ecx
80107c94:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107c9a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c9d:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107ca4:	83 e1 ef             	and    $0xffffffef,%ecx
80107ca7:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107cad:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cb0:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107cb7:	83 e1 df             	and    $0xffffffdf,%ecx
80107cba:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107cc0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cc3:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107cca:	83 c9 40             	or     $0x40,%ecx
80107ccd:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107cd3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cd6:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107cdd:	83 c9 80             	or     $0xffffff80,%ecx
80107ce0:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107ce6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ce9:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80107cef:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cf2:	83 c0 70             	add    $0x70,%eax
80107cf5:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80107cfc:	00 
80107cfd:	89 04 24             	mov    %eax,(%esp)
80107d00:	e8 37 fb ff ff       	call   8010783c <lgdt>
  loadgs(SEG_KCPU << 3);
80107d05:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80107d0c:	e8 6a fb ff ff       	call   8010787b <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80107d11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d14:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80107d1a:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80107d21:	00 00 00 00 
}
80107d25:	83 c4 24             	add    $0x24,%esp
80107d28:	5b                   	pop    %ebx
80107d29:	5d                   	pop    %ebp
80107d2a:	c3                   	ret    

80107d2b <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80107d2b:	55                   	push   %ebp
80107d2c:	89 e5                	mov    %esp,%ebp
80107d2e:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80107d31:	8b 45 0c             	mov    0xc(%ebp),%eax
80107d34:	c1 e8 16             	shr    $0x16,%eax
80107d37:	c1 e0 02             	shl    $0x2,%eax
80107d3a:	03 45 08             	add    0x8(%ebp),%eax
80107d3d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80107d40:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107d43:	8b 00                	mov    (%eax),%eax
80107d45:	83 e0 01             	and    $0x1,%eax
80107d48:	84 c0                	test   %al,%al
80107d4a:	74 17                	je     80107d63 <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80107d4c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107d4f:	8b 00                	mov    (%eax),%eax
80107d51:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107d56:	89 04 24             	mov    %eax,(%esp)
80107d59:	e8 4a fb ff ff       	call   801078a8 <p2v>
80107d5e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107d61:	eb 4b                	jmp    80107dae <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80107d63:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80107d67:	74 0e                	je     80107d77 <walkpgdir+0x4c>
80107d69:	e8 cd ad ff ff       	call   80102b3b <kalloc>
80107d6e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107d71:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107d75:	75 07                	jne    80107d7e <walkpgdir+0x53>
      return 0;
80107d77:	b8 00 00 00 00       	mov    $0x0,%eax
80107d7c:	eb 41                	jmp    80107dbf <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80107d7e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107d85:	00 
80107d86:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107d8d:	00 
80107d8e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d91:	89 04 24             	mov    %eax,(%esp)
80107d94:	e8 55 d5 ff ff       	call   801052ee <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80107d99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d9c:	89 04 24             	mov    %eax,(%esp)
80107d9f:	e8 f7 fa ff ff       	call   8010789b <v2p>
80107da4:	89 c2                	mov    %eax,%edx
80107da6:	83 ca 07             	or     $0x7,%edx
80107da9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107dac:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80107dae:	8b 45 0c             	mov    0xc(%ebp),%eax
80107db1:	c1 e8 0c             	shr    $0xc,%eax
80107db4:	25 ff 03 00 00       	and    $0x3ff,%eax
80107db9:	c1 e0 02             	shl    $0x2,%eax
80107dbc:	03 45 f4             	add    -0xc(%ebp),%eax
}
80107dbf:	c9                   	leave  
80107dc0:	c3                   	ret    

80107dc1 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80107dc1:	55                   	push   %ebp
80107dc2:	89 e5                	mov    %esp,%ebp
80107dc4:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80107dc7:	8b 45 0c             	mov    0xc(%ebp),%eax
80107dca:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107dcf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80107dd2:	8b 45 0c             	mov    0xc(%ebp),%eax
80107dd5:	03 45 10             	add    0x10(%ebp),%eax
80107dd8:	83 e8 01             	sub    $0x1,%eax
80107ddb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107de0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80107de3:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80107dea:	00 
80107deb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dee:	89 44 24 04          	mov    %eax,0x4(%esp)
80107df2:	8b 45 08             	mov    0x8(%ebp),%eax
80107df5:	89 04 24             	mov    %eax,(%esp)
80107df8:	e8 2e ff ff ff       	call   80107d2b <walkpgdir>
80107dfd:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107e00:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107e04:	75 07                	jne    80107e0d <mappages+0x4c>
      return -1;
80107e06:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107e0b:	eb 46                	jmp    80107e53 <mappages+0x92>
    if(*pte & PTE_P)
80107e0d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107e10:	8b 00                	mov    (%eax),%eax
80107e12:	83 e0 01             	and    $0x1,%eax
80107e15:	84 c0                	test   %al,%al
80107e17:	74 0c                	je     80107e25 <mappages+0x64>
      panic("remap");
80107e19:	c7 04 24 50 8c 10 80 	movl   $0x80108c50,(%esp)
80107e20:	e8 18 87 ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
80107e25:	8b 45 18             	mov    0x18(%ebp),%eax
80107e28:	0b 45 14             	or     0x14(%ebp),%eax
80107e2b:	89 c2                	mov    %eax,%edx
80107e2d:	83 ca 01             	or     $0x1,%edx
80107e30:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107e33:	89 10                	mov    %edx,(%eax)
    if(a == last)
80107e35:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e38:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107e3b:	74 10                	je     80107e4d <mappages+0x8c>
      break;
    a += PGSIZE;
80107e3d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80107e44:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80107e4b:	eb 96                	jmp    80107de3 <mappages+0x22>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
80107e4d:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80107e4e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107e53:	c9                   	leave  
80107e54:	c3                   	ret    

80107e55 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
80107e55:	55                   	push   %ebp
80107e56:	89 e5                	mov    %esp,%ebp
80107e58:	53                   	push   %ebx
80107e59:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80107e5c:	e8 da ac ff ff       	call   80102b3b <kalloc>
80107e61:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107e64:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107e68:	75 0a                	jne    80107e74 <setupkvm+0x1f>
    return 0;
80107e6a:	b8 00 00 00 00       	mov    $0x0,%eax
80107e6f:	e9 98 00 00 00       	jmp    80107f0c <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80107e74:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107e7b:	00 
80107e7c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107e83:	00 
80107e84:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107e87:	89 04 24             	mov    %eax,(%esp)
80107e8a:	e8 5f d4 ff ff       	call   801052ee <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80107e8f:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80107e96:	e8 0d fa ff ff       	call   801078a8 <p2v>
80107e9b:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80107ea0:	76 0c                	jbe    80107eae <setupkvm+0x59>
    panic("PHYSTOP too high");
80107ea2:	c7 04 24 56 8c 10 80 	movl   $0x80108c56,(%esp)
80107ea9:	e8 8f 86 ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107eae:	c7 45 f4 a0 b4 10 80 	movl   $0x8010b4a0,-0xc(%ebp)
80107eb5:	eb 49                	jmp    80107f00 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
80107eb7:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80107eba:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
80107ebd:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80107ec0:	8b 50 04             	mov    0x4(%eax),%edx
80107ec3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ec6:	8b 58 08             	mov    0x8(%eax),%ebx
80107ec9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ecc:	8b 40 04             	mov    0x4(%eax),%eax
80107ecf:	29 c3                	sub    %eax,%ebx
80107ed1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ed4:	8b 00                	mov    (%eax),%eax
80107ed6:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80107eda:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107ede:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107ee2:	89 44 24 04          	mov    %eax,0x4(%esp)
80107ee6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107ee9:	89 04 24             	mov    %eax,(%esp)
80107eec:	e8 d0 fe ff ff       	call   80107dc1 <mappages>
80107ef1:	85 c0                	test   %eax,%eax
80107ef3:	79 07                	jns    80107efc <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80107ef5:	b8 00 00 00 00       	mov    $0x0,%eax
80107efa:	eb 10                	jmp    80107f0c <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107efc:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80107f00:	81 7d f4 e0 b4 10 80 	cmpl   $0x8010b4e0,-0xc(%ebp)
80107f07:	72 ae                	jb     80107eb7 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80107f09:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80107f0c:	83 c4 34             	add    $0x34,%esp
80107f0f:	5b                   	pop    %ebx
80107f10:	5d                   	pop    %ebp
80107f11:	c3                   	ret    

80107f12 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80107f12:	55                   	push   %ebp
80107f13:	89 e5                	mov    %esp,%ebp
80107f15:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80107f18:	e8 38 ff ff ff       	call   80107e55 <setupkvm>
80107f1d:	a3 38 db 11 80       	mov    %eax,0x8011db38
  switchkvm();
80107f22:	e8 02 00 00 00       	call   80107f29 <switchkvm>
}
80107f27:	c9                   	leave  
80107f28:	c3                   	ret    

80107f29 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80107f29:	55                   	push   %ebp
80107f2a:	89 e5                	mov    %esp,%ebp
80107f2c:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80107f2f:	a1 38 db 11 80       	mov    0x8011db38,%eax
80107f34:	89 04 24             	mov    %eax,(%esp)
80107f37:	e8 5f f9 ff ff       	call   8010789b <v2p>
80107f3c:	89 04 24             	mov    %eax,(%esp)
80107f3f:	e8 4c f9 ff ff       	call   80107890 <lcr3>
}
80107f44:	c9                   	leave  
80107f45:	c3                   	ret    

80107f46 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80107f46:	55                   	push   %ebp
80107f47:	89 e5                	mov    %esp,%ebp
80107f49:	53                   	push   %ebx
80107f4a:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80107f4d:	e8 95 d2 ff ff       	call   801051e7 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80107f52:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107f58:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107f5f:	83 c2 08             	add    $0x8,%edx
80107f62:	89 d3                	mov    %edx,%ebx
80107f64:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107f6b:	83 c2 08             	add    $0x8,%edx
80107f6e:	c1 ea 10             	shr    $0x10,%edx
80107f71:	89 d1                	mov    %edx,%ecx
80107f73:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107f7a:	83 c2 08             	add    $0x8,%edx
80107f7d:	c1 ea 18             	shr    $0x18,%edx
80107f80:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80107f87:	67 00 
80107f89:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80107f90:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80107f96:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107f9d:	83 e1 f0             	and    $0xfffffff0,%ecx
80107fa0:	83 c9 09             	or     $0x9,%ecx
80107fa3:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107fa9:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107fb0:	83 c9 10             	or     $0x10,%ecx
80107fb3:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107fb9:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107fc0:	83 e1 9f             	and    $0xffffff9f,%ecx
80107fc3:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107fc9:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107fd0:	83 c9 80             	or     $0xffffff80,%ecx
80107fd3:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107fd9:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107fe0:	83 e1 f0             	and    $0xfffffff0,%ecx
80107fe3:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107fe9:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107ff0:	83 e1 ef             	and    $0xffffffef,%ecx
80107ff3:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107ff9:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108000:	83 e1 df             	and    $0xffffffdf,%ecx
80108003:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108009:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108010:	83 c9 40             	or     $0x40,%ecx
80108013:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108019:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108020:	83 e1 7f             	and    $0x7f,%ecx
80108023:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108029:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
8010802f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108035:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
8010803c:	83 e2 ef             	and    $0xffffffef,%edx
8010803f:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80108045:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010804b:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->threads->kstack + KSTACKSIZE;
80108051:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108057:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010805e:	8b 52 50             	mov    0x50(%edx),%edx
80108061:	81 c2 00 10 00 00    	add    $0x1000,%edx
80108067:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
8010806a:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80108071:	e8 ef f7 ff ff       	call   80107865 <ltr>
  if(p->pgdir == 0)
80108076:	8b 45 08             	mov    0x8(%ebp),%eax
80108079:	8b 40 04             	mov    0x4(%eax),%eax
8010807c:	85 c0                	test   %eax,%eax
8010807e:	75 0c                	jne    8010808c <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80108080:	c7 04 24 67 8c 10 80 	movl   $0x80108c67,(%esp)
80108087:	e8 b1 84 ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
8010808c:	8b 45 08             	mov    0x8(%ebp),%eax
8010808f:	8b 40 04             	mov    0x4(%eax),%eax
80108092:	89 04 24             	mov    %eax,(%esp)
80108095:	e8 01 f8 ff ff       	call   8010789b <v2p>
8010809a:	89 04 24             	mov    %eax,(%esp)
8010809d:	e8 ee f7 ff ff       	call   80107890 <lcr3>
  popcli();
801080a2:	e8 88 d1 ff ff       	call   8010522f <popcli>
}
801080a7:	83 c4 14             	add    $0x14,%esp
801080aa:	5b                   	pop    %ebx
801080ab:	5d                   	pop    %ebp
801080ac:	c3                   	ret    

801080ad <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801080ad:	55                   	push   %ebp
801080ae:	89 e5                	mov    %esp,%ebp
801080b0:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
801080b3:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
801080ba:	76 0c                	jbe    801080c8 <inituvm+0x1b>
    panic("inituvm: more than a page");
801080bc:	c7 04 24 7b 8c 10 80 	movl   $0x80108c7b,(%esp)
801080c3:	e8 75 84 ff ff       	call   8010053d <panic>
  mem = kalloc();
801080c8:	e8 6e aa ff ff       	call   80102b3b <kalloc>
801080cd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
801080d0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801080d7:	00 
801080d8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801080df:	00 
801080e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080e3:	89 04 24             	mov    %eax,(%esp)
801080e6:	e8 03 d2 ff ff       	call   801052ee <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
801080eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080ee:	89 04 24             	mov    %eax,(%esp)
801080f1:	e8 a5 f7 ff ff       	call   8010789b <v2p>
801080f6:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801080fd:	00 
801080fe:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108102:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108109:	00 
8010810a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108111:	00 
80108112:	8b 45 08             	mov    0x8(%ebp),%eax
80108115:	89 04 24             	mov    %eax,(%esp)
80108118:	e8 a4 fc ff ff       	call   80107dc1 <mappages>
  memmove(mem, init, sz);
8010811d:	8b 45 10             	mov    0x10(%ebp),%eax
80108120:	89 44 24 08          	mov    %eax,0x8(%esp)
80108124:	8b 45 0c             	mov    0xc(%ebp),%eax
80108127:	89 44 24 04          	mov    %eax,0x4(%esp)
8010812b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010812e:	89 04 24             	mov    %eax,(%esp)
80108131:	e8 8b d2 ff ff       	call   801053c1 <memmove>
}
80108136:	c9                   	leave  
80108137:	c3                   	ret    

80108138 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80108138:	55                   	push   %ebp
80108139:	89 e5                	mov    %esp,%ebp
8010813b:	53                   	push   %ebx
8010813c:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
8010813f:	8b 45 0c             	mov    0xc(%ebp),%eax
80108142:	25 ff 0f 00 00       	and    $0xfff,%eax
80108147:	85 c0                	test   %eax,%eax
80108149:	74 0c                	je     80108157 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
8010814b:	c7 04 24 98 8c 10 80 	movl   $0x80108c98,(%esp)
80108152:	e8 e6 83 ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
80108157:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010815e:	e9 ad 00 00 00       	jmp    80108210 <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80108163:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108166:	8b 55 0c             	mov    0xc(%ebp),%edx
80108169:	01 d0                	add    %edx,%eax
8010816b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108172:	00 
80108173:	89 44 24 04          	mov    %eax,0x4(%esp)
80108177:	8b 45 08             	mov    0x8(%ebp),%eax
8010817a:	89 04 24             	mov    %eax,(%esp)
8010817d:	e8 a9 fb ff ff       	call   80107d2b <walkpgdir>
80108182:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108185:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108189:	75 0c                	jne    80108197 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
8010818b:	c7 04 24 bb 8c 10 80 	movl   $0x80108cbb,(%esp)
80108192:	e8 a6 83 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
80108197:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010819a:	8b 00                	mov    (%eax),%eax
8010819c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801081a1:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
801081a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081a7:	8b 55 18             	mov    0x18(%ebp),%edx
801081aa:	89 d1                	mov    %edx,%ecx
801081ac:	29 c1                	sub    %eax,%ecx
801081ae:	89 c8                	mov    %ecx,%eax
801081b0:	3d ff 0f 00 00       	cmp    $0xfff,%eax
801081b5:	77 11                	ja     801081c8 <loaduvm+0x90>
      n = sz - i;
801081b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081ba:	8b 55 18             	mov    0x18(%ebp),%edx
801081bd:	89 d1                	mov    %edx,%ecx
801081bf:	29 c1                	sub    %eax,%ecx
801081c1:	89 c8                	mov    %ecx,%eax
801081c3:	89 45 f0             	mov    %eax,-0x10(%ebp)
801081c6:	eb 07                	jmp    801081cf <loaduvm+0x97>
    else
      n = PGSIZE;
801081c8:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
801081cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081d2:	8b 55 14             	mov    0x14(%ebp),%edx
801081d5:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
801081d8:	8b 45 e8             	mov    -0x18(%ebp),%eax
801081db:	89 04 24             	mov    %eax,(%esp)
801081de:	e8 c5 f6 ff ff       	call   801078a8 <p2v>
801081e3:	8b 55 f0             	mov    -0x10(%ebp),%edx
801081e6:	89 54 24 0c          	mov    %edx,0xc(%esp)
801081ea:	89 5c 24 08          	mov    %ebx,0x8(%esp)
801081ee:	89 44 24 04          	mov    %eax,0x4(%esp)
801081f2:	8b 45 10             	mov    0x10(%ebp),%eax
801081f5:	89 04 24             	mov    %eax,(%esp)
801081f8:	e8 99 9b ff ff       	call   80101d96 <readi>
801081fd:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108200:	74 07                	je     80108209 <loaduvm+0xd1>
      return -1;
80108202:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108207:	eb 18                	jmp    80108221 <loaduvm+0xe9>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80108209:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108210:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108213:	3b 45 18             	cmp    0x18(%ebp),%eax
80108216:	0f 82 47 ff ff ff    	jb     80108163 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
8010821c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108221:	83 c4 24             	add    $0x24,%esp
80108224:	5b                   	pop    %ebx
80108225:	5d                   	pop    %ebp
80108226:	c3                   	ret    

80108227 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108227:	55                   	push   %ebp
80108228:	89 e5                	mov    %esp,%ebp
8010822a:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
8010822d:	8b 45 10             	mov    0x10(%ebp),%eax
80108230:	85 c0                	test   %eax,%eax
80108232:	79 0a                	jns    8010823e <allocuvm+0x17>
    return 0;
80108234:	b8 00 00 00 00       	mov    $0x0,%eax
80108239:	e9 c1 00 00 00       	jmp    801082ff <allocuvm+0xd8>
  if(newsz < oldsz)
8010823e:	8b 45 10             	mov    0x10(%ebp),%eax
80108241:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108244:	73 08                	jae    8010824e <allocuvm+0x27>
    return oldsz;
80108246:	8b 45 0c             	mov    0xc(%ebp),%eax
80108249:	e9 b1 00 00 00       	jmp    801082ff <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
8010824e:	8b 45 0c             	mov    0xc(%ebp),%eax
80108251:	05 ff 0f 00 00       	add    $0xfff,%eax
80108256:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010825b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
8010825e:	e9 8d 00 00 00       	jmp    801082f0 <allocuvm+0xc9>
    mem = kalloc();
80108263:	e8 d3 a8 ff ff       	call   80102b3b <kalloc>
80108268:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
8010826b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010826f:	75 2c                	jne    8010829d <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80108271:	c7 04 24 d9 8c 10 80 	movl   $0x80108cd9,(%esp)
80108278:	e8 24 81 ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
8010827d:	8b 45 0c             	mov    0xc(%ebp),%eax
80108280:	89 44 24 08          	mov    %eax,0x8(%esp)
80108284:	8b 45 10             	mov    0x10(%ebp),%eax
80108287:	89 44 24 04          	mov    %eax,0x4(%esp)
8010828b:	8b 45 08             	mov    0x8(%ebp),%eax
8010828e:	89 04 24             	mov    %eax,(%esp)
80108291:	e8 6b 00 00 00       	call   80108301 <deallocuvm>
      return 0;
80108296:	b8 00 00 00 00       	mov    $0x0,%eax
8010829b:	eb 62                	jmp    801082ff <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
8010829d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801082a4:	00 
801082a5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801082ac:	00 
801082ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
801082b0:	89 04 24             	mov    %eax,(%esp)
801082b3:	e8 36 d0 ff ff       	call   801052ee <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
801082b8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801082bb:	89 04 24             	mov    %eax,(%esp)
801082be:	e8 d8 f5 ff ff       	call   8010789b <v2p>
801082c3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801082c6:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801082cd:	00 
801082ce:	89 44 24 0c          	mov    %eax,0xc(%esp)
801082d2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801082d9:	00 
801082da:	89 54 24 04          	mov    %edx,0x4(%esp)
801082de:	8b 45 08             	mov    0x8(%ebp),%eax
801082e1:	89 04 24             	mov    %eax,(%esp)
801082e4:	e8 d8 fa ff ff       	call   80107dc1 <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
801082e9:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801082f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082f3:	3b 45 10             	cmp    0x10(%ebp),%eax
801082f6:	0f 82 67 ff ff ff    	jb     80108263 <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
801082fc:	8b 45 10             	mov    0x10(%ebp),%eax
}
801082ff:	c9                   	leave  
80108300:	c3                   	ret    

80108301 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108301:	55                   	push   %ebp
80108302:	89 e5                	mov    %esp,%ebp
80108304:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80108307:	8b 45 10             	mov    0x10(%ebp),%eax
8010830a:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010830d:	72 08                	jb     80108317 <deallocuvm+0x16>
    return oldsz;
8010830f:	8b 45 0c             	mov    0xc(%ebp),%eax
80108312:	e9 a4 00 00 00       	jmp    801083bb <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80108317:	8b 45 10             	mov    0x10(%ebp),%eax
8010831a:	05 ff 0f 00 00       	add    $0xfff,%eax
8010831f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108324:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80108327:	e9 80 00 00 00       	jmp    801083ac <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
8010832c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010832f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108336:	00 
80108337:	89 44 24 04          	mov    %eax,0x4(%esp)
8010833b:	8b 45 08             	mov    0x8(%ebp),%eax
8010833e:	89 04 24             	mov    %eax,(%esp)
80108341:	e8 e5 f9 ff ff       	call   80107d2b <walkpgdir>
80108346:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80108349:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010834d:	75 09                	jne    80108358 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
8010834f:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80108356:	eb 4d                	jmp    801083a5 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80108358:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010835b:	8b 00                	mov    (%eax),%eax
8010835d:	83 e0 01             	and    $0x1,%eax
80108360:	84 c0                	test   %al,%al
80108362:	74 41                	je     801083a5 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80108364:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108367:	8b 00                	mov    (%eax),%eax
80108369:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010836e:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80108371:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108375:	75 0c                	jne    80108383 <deallocuvm+0x82>
        panic("kfree");
80108377:	c7 04 24 f1 8c 10 80 	movl   $0x80108cf1,(%esp)
8010837e:	e8 ba 81 ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
80108383:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108386:	89 04 24             	mov    %eax,(%esp)
80108389:	e8 1a f5 ff ff       	call   801078a8 <p2v>
8010838e:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80108391:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108394:	89 04 24             	mov    %eax,(%esp)
80108397:	e8 06 a7 ff ff       	call   80102aa2 <kfree>
      *pte = 0;
8010839c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010839f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
801083a5:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801083ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083af:	3b 45 0c             	cmp    0xc(%ebp),%eax
801083b2:	0f 82 74 ff ff ff    	jb     8010832c <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
801083b8:	8b 45 10             	mov    0x10(%ebp),%eax
}
801083bb:	c9                   	leave  
801083bc:	c3                   	ret    

801083bd <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
801083bd:	55                   	push   %ebp
801083be:	89 e5                	mov    %esp,%ebp
801083c0:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
801083c3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801083c7:	75 0c                	jne    801083d5 <freevm+0x18>
    panic("freevm: no pgdir");
801083c9:	c7 04 24 f7 8c 10 80 	movl   $0x80108cf7,(%esp)
801083d0:	e8 68 81 ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
801083d5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801083dc:	00 
801083dd:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
801083e4:	80 
801083e5:	8b 45 08             	mov    0x8(%ebp),%eax
801083e8:	89 04 24             	mov    %eax,(%esp)
801083eb:	e8 11 ff ff ff       	call   80108301 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
801083f0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801083f7:	eb 3c                	jmp    80108435 <freevm+0x78>
    if(pgdir[i] & PTE_P){
801083f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083fc:	c1 e0 02             	shl    $0x2,%eax
801083ff:	03 45 08             	add    0x8(%ebp),%eax
80108402:	8b 00                	mov    (%eax),%eax
80108404:	83 e0 01             	and    $0x1,%eax
80108407:	84 c0                	test   %al,%al
80108409:	74 26                	je     80108431 <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
8010840b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010840e:	c1 e0 02             	shl    $0x2,%eax
80108411:	03 45 08             	add    0x8(%ebp),%eax
80108414:	8b 00                	mov    (%eax),%eax
80108416:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010841b:	89 04 24             	mov    %eax,(%esp)
8010841e:	e8 85 f4 ff ff       	call   801078a8 <p2v>
80108423:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108426:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108429:	89 04 24             	mov    %eax,(%esp)
8010842c:	e8 71 a6 ff ff       	call   80102aa2 <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80108431:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80108435:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
8010843c:	76 bb                	jbe    801083f9 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
8010843e:	8b 45 08             	mov    0x8(%ebp),%eax
80108441:	89 04 24             	mov    %eax,(%esp)
80108444:	e8 59 a6 ff ff       	call   80102aa2 <kfree>
}
80108449:	c9                   	leave  
8010844a:	c3                   	ret    

8010844b <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
8010844b:	55                   	push   %ebp
8010844c:	89 e5                	mov    %esp,%ebp
8010844e:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108451:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108458:	00 
80108459:	8b 45 0c             	mov    0xc(%ebp),%eax
8010845c:	89 44 24 04          	mov    %eax,0x4(%esp)
80108460:	8b 45 08             	mov    0x8(%ebp),%eax
80108463:	89 04 24             	mov    %eax,(%esp)
80108466:	e8 c0 f8 ff ff       	call   80107d2b <walkpgdir>
8010846b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
8010846e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108472:	75 0c                	jne    80108480 <clearpteu+0x35>
    panic("clearpteu");
80108474:	c7 04 24 08 8d 10 80 	movl   $0x80108d08,(%esp)
8010847b:	e8 bd 80 ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
80108480:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108483:	8b 00                	mov    (%eax),%eax
80108485:	89 c2                	mov    %eax,%edx
80108487:	83 e2 fb             	and    $0xfffffffb,%edx
8010848a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010848d:	89 10                	mov    %edx,(%eax)
}
8010848f:	c9                   	leave  
80108490:	c3                   	ret    

80108491 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80108491:	55                   	push   %ebp
80108492:	89 e5                	mov    %esp,%ebp
80108494:	53                   	push   %ebx
80108495:	83 ec 44             	sub    $0x44,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80108498:	e8 b8 f9 ff ff       	call   80107e55 <setupkvm>
8010849d:	89 45 f0             	mov    %eax,-0x10(%ebp)
801084a0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801084a4:	75 0a                	jne    801084b0 <copyuvm+0x1f>
    return 0;
801084a6:	b8 00 00 00 00       	mov    $0x0,%eax
801084ab:	e9 fd 00 00 00       	jmp    801085ad <copyuvm+0x11c>
  for(i = 0; i < sz; i += PGSIZE){
801084b0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801084b7:	e9 cc 00 00 00       	jmp    80108588 <copyuvm+0xf7>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801084bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084bf:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801084c6:	00 
801084c7:	89 44 24 04          	mov    %eax,0x4(%esp)
801084cb:	8b 45 08             	mov    0x8(%ebp),%eax
801084ce:	89 04 24             	mov    %eax,(%esp)
801084d1:	e8 55 f8 ff ff       	call   80107d2b <walkpgdir>
801084d6:	89 45 ec             	mov    %eax,-0x14(%ebp)
801084d9:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801084dd:	75 0c                	jne    801084eb <copyuvm+0x5a>
      panic("copyuvm: pte should exist");
801084df:	c7 04 24 12 8d 10 80 	movl   $0x80108d12,(%esp)
801084e6:	e8 52 80 ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
801084eb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801084ee:	8b 00                	mov    (%eax),%eax
801084f0:	83 e0 01             	and    $0x1,%eax
801084f3:	85 c0                	test   %eax,%eax
801084f5:	75 0c                	jne    80108503 <copyuvm+0x72>
      panic("copyuvm: page not present");
801084f7:	c7 04 24 2c 8d 10 80 	movl   $0x80108d2c,(%esp)
801084fe:	e8 3a 80 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
80108503:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108506:	8b 00                	mov    (%eax),%eax
80108508:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010850d:	89 45 e8             	mov    %eax,-0x18(%ebp)
    flags = PTE_FLAGS(*pte);
80108510:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108513:	8b 00                	mov    (%eax),%eax
80108515:	25 ff 0f 00 00       	and    $0xfff,%eax
8010851a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if((mem = kalloc()) == 0)
8010851d:	e8 19 a6 ff ff       	call   80102b3b <kalloc>
80108522:	89 45 e0             	mov    %eax,-0x20(%ebp)
80108525:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80108529:	74 6e                	je     80108599 <copyuvm+0x108>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
8010852b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010852e:	89 04 24             	mov    %eax,(%esp)
80108531:	e8 72 f3 ff ff       	call   801078a8 <p2v>
80108536:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010853d:	00 
8010853e:	89 44 24 04          	mov    %eax,0x4(%esp)
80108542:	8b 45 e0             	mov    -0x20(%ebp),%eax
80108545:	89 04 24             	mov    %eax,(%esp)
80108548:	e8 74 ce ff ff       	call   801053c1 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
8010854d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
80108550:	8b 45 e0             	mov    -0x20(%ebp),%eax
80108553:	89 04 24             	mov    %eax,(%esp)
80108556:	e8 40 f3 ff ff       	call   8010789b <v2p>
8010855b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010855e:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80108562:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108566:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010856d:	00 
8010856e:	89 54 24 04          	mov    %edx,0x4(%esp)
80108572:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108575:	89 04 24             	mov    %eax,(%esp)
80108578:	e8 44 f8 ff ff       	call   80107dc1 <mappages>
8010857d:	85 c0                	test   %eax,%eax
8010857f:	78 1b                	js     8010859c <copyuvm+0x10b>
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80108581:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108588:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010858b:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010858e:	0f 82 28 ff ff ff    	jb     801084bc <copyuvm+0x2b>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
      goto bad;
  }
  return d;
80108594:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108597:	eb 14                	jmp    801085ad <copyuvm+0x11c>
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    flags = PTE_FLAGS(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
80108599:	90                   	nop
8010859a:	eb 01                	jmp    8010859d <copyuvm+0x10c>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
      goto bad;
8010859c:	90                   	nop
  }
  return d;

bad:
  freevm(d);
8010859d:	8b 45 f0             	mov    -0x10(%ebp),%eax
801085a0:	89 04 24             	mov    %eax,(%esp)
801085a3:	e8 15 fe ff ff       	call   801083bd <freevm>
  return 0;
801085a8:	b8 00 00 00 00       	mov    $0x0,%eax
}
801085ad:	83 c4 44             	add    $0x44,%esp
801085b0:	5b                   	pop    %ebx
801085b1:	5d                   	pop    %ebp
801085b2:	c3                   	ret    

801085b3 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801085b3:	55                   	push   %ebp
801085b4:	89 e5                	mov    %esp,%ebp
801085b6:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801085b9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801085c0:	00 
801085c1:	8b 45 0c             	mov    0xc(%ebp),%eax
801085c4:	89 44 24 04          	mov    %eax,0x4(%esp)
801085c8:	8b 45 08             	mov    0x8(%ebp),%eax
801085cb:	89 04 24             	mov    %eax,(%esp)
801085ce:	e8 58 f7 ff ff       	call   80107d2b <walkpgdir>
801085d3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
801085d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085d9:	8b 00                	mov    (%eax),%eax
801085db:	83 e0 01             	and    $0x1,%eax
801085de:	85 c0                	test   %eax,%eax
801085e0:	75 07                	jne    801085e9 <uva2ka+0x36>
    return 0;
801085e2:	b8 00 00 00 00       	mov    $0x0,%eax
801085e7:	eb 25                	jmp    8010860e <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
801085e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085ec:	8b 00                	mov    (%eax),%eax
801085ee:	83 e0 04             	and    $0x4,%eax
801085f1:	85 c0                	test   %eax,%eax
801085f3:	75 07                	jne    801085fc <uva2ka+0x49>
    return 0;
801085f5:	b8 00 00 00 00       	mov    $0x0,%eax
801085fa:	eb 12                	jmp    8010860e <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
801085fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085ff:	8b 00                	mov    (%eax),%eax
80108601:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108606:	89 04 24             	mov    %eax,(%esp)
80108609:	e8 9a f2 ff ff       	call   801078a8 <p2v>
}
8010860e:	c9                   	leave  
8010860f:	c3                   	ret    

80108610 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80108610:	55                   	push   %ebp
80108611:	89 e5                	mov    %esp,%ebp
80108613:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80108616:	8b 45 10             	mov    0x10(%ebp),%eax
80108619:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
8010861c:	e9 8b 00 00 00       	jmp    801086ac <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
80108621:	8b 45 0c             	mov    0xc(%ebp),%eax
80108624:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108629:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
8010862c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010862f:	89 44 24 04          	mov    %eax,0x4(%esp)
80108633:	8b 45 08             	mov    0x8(%ebp),%eax
80108636:	89 04 24             	mov    %eax,(%esp)
80108639:	e8 75 ff ff ff       	call   801085b3 <uva2ka>
8010863e:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80108641:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108645:	75 07                	jne    8010864e <copyout+0x3e>
      return -1;
80108647:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010864c:	eb 6d                	jmp    801086bb <copyout+0xab>
    n = PGSIZE - (va - va0);
8010864e:	8b 45 0c             	mov    0xc(%ebp),%eax
80108651:	8b 55 ec             	mov    -0x14(%ebp),%edx
80108654:	89 d1                	mov    %edx,%ecx
80108656:	29 c1                	sub    %eax,%ecx
80108658:	89 c8                	mov    %ecx,%eax
8010865a:	05 00 10 00 00       	add    $0x1000,%eax
8010865f:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80108662:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108665:	3b 45 14             	cmp    0x14(%ebp),%eax
80108668:	76 06                	jbe    80108670 <copyout+0x60>
      n = len;
8010866a:	8b 45 14             	mov    0x14(%ebp),%eax
8010866d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80108670:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108673:	8b 55 0c             	mov    0xc(%ebp),%edx
80108676:	89 d1                	mov    %edx,%ecx
80108678:	29 c1                	sub    %eax,%ecx
8010867a:	89 c8                	mov    %ecx,%eax
8010867c:	03 45 e8             	add    -0x18(%ebp),%eax
8010867f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108682:	89 54 24 08          	mov    %edx,0x8(%esp)
80108686:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108689:	89 54 24 04          	mov    %edx,0x4(%esp)
8010868d:	89 04 24             	mov    %eax,(%esp)
80108690:	e8 2c cd ff ff       	call   801053c1 <memmove>
    len -= n;
80108695:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108698:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
8010869b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010869e:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
801086a1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801086a4:	05 00 10 00 00       	add    $0x1000,%eax
801086a9:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801086ac:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801086b0:	0f 85 6b ff ff ff    	jne    80108621 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
801086b6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801086bb:	c9                   	leave  
801086bc:	c3                   	ret    
