
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	9d010113          	addi	sp,sp,-1584 # 800089d0 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	83e70713          	addi	a4,a4,-1986 # 80008890 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	cec78793          	addi	a5,a5,-788 # 80005d50 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdcaff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de678793          	addi	a5,a5,-538 # 80000e94 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	4b0080e7          	jalr	1200(ra) # 800025dc <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	84450513          	addi	a0,a0,-1980 # 800109d0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	83448493          	addi	s1,s1,-1996 # 800109d0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	8c290913          	addi	s2,s2,-1854 # 80010a68 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
      if(killed(myproc())){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	916080e7          	jalr	-1770(ra) # 80001ada <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	25a080e7          	jalr	602(ra) # 80002426 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	fa4080e7          	jalr	-92(ra) # 8000217e <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
    cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	370080e7          	jalr	880(ra) # 80002586 <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
    dst++;
    80000222:	0a85                	addi	s5,s5,1
    --n;
    80000224:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00010517          	auipc	a0,0x10
    8000022e:	7a650513          	addi	a0,a0,1958 # 800109d0 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00010517          	auipc	a0,0x10
    80000244:	79050513          	addi	a0,a0,1936 # 800109d0 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a56080e7          	jalr	-1450(ra) # 80000c9e <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
      if(n < target){
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
        cons.r--;
    80000278:	00010717          	auipc	a4,0x10
    8000027c:	7ef72823          	sw	a5,2032(a4) # 80010a68 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	564080e7          	jalr	1380(ra) # 800007f6 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00010517          	auipc	a0,0x10
    800002d6:	6fe50513          	addi	a0,a0,1790 # 800109d0 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	910080e7          	jalr	-1776(ra) # 80000bea <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	33a080e7          	jalr	826(ra) # 80002632 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00010517          	auipc	a0,0x10
    80000304:	6d050513          	addi	a0,a0,1744 # 800109d0 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	996080e7          	jalr	-1642(ra) # 80000c9e <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000324:	00010717          	auipc	a4,0x10
    80000328:	6ac70713          	addi	a4,a4,1708 # 800109d0 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00010797          	auipc	a5,0x10
    80000352:	68278793          	addi	a5,a5,1666 # 800109d0 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00010797          	auipc	a5,0x10
    80000380:	6ec7a783          	lw	a5,1772(a5) # 80010a68 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00010717          	auipc	a4,0x10
    80000394:	64070713          	addi	a4,a4,1600 # 800109d0 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00010497          	auipc	s1,0x10
    800003a4:	63048493          	addi	s1,s1,1584 # 800109d0 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00010717          	auipc	a4,0x10
    800003e0:	5f470713          	addi	a4,a4,1524 # 800109d0 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00010717          	auipc	a4,0x10
    800003f6:	66f72f23          	sw	a5,1662(a4) # 80010a70 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00010797          	auipc	a5,0x10
    8000041c:	5b878793          	addi	a5,a5,1464 # 800109d0 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00010797          	auipc	a5,0x10
    80000440:	62c7a823          	sw	a2,1584(a5) # 80010a6c <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00010517          	auipc	a0,0x10
    80000448:	62450513          	addi	a0,a0,1572 # 80010a68 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	d96080e7          	jalr	-618(ra) # 800021e2 <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00010517          	auipc	a0,0x10
    8000046a:	56a50513          	addi	a0,a0,1386 # 800109d0 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00020797          	auipc	a5,0x20
    80000482:	6ea78793          	addi	a5,a5,1770 # 80020b68 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80008040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
    buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
    x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
    x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000544:	1101                	addi	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000550:	00010797          	auipc	a5,0x10
    80000554:	5407a023          	sw	zero,1344(a5) # 80010a90 <pr+0x18>
  printf("panic: ");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80008018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00008517          	auipc	a0,0x8
    80000576:	b5650513          	addi	a0,a0,-1194 # 800080c8 <digits+0x88>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	2cf72623          	sw	a5,716(a4) # 80008850 <panicked>
  for(;;)
    8000058c:	a001                	j	8000058c <panic+0x48>

000000008000058e <printf>:
{
    8000058e:	7131                	addi	sp,sp,-192
    80000590:	fc86                	sd	ra,120(sp)
    80000592:	f8a2                	sd	s0,112(sp)
    80000594:	f4a6                	sd	s1,104(sp)
    80000596:	f0ca                	sd	s2,96(sp)
    80000598:	ecce                	sd	s3,88(sp)
    8000059a:	e8d2                	sd	s4,80(sp)
    8000059c:	e4d6                	sd	s5,72(sp)
    8000059e:	e0da                	sd	s6,64(sp)
    800005a0:	fc5e                	sd	s7,56(sp)
    800005a2:	f862                	sd	s8,48(sp)
    800005a4:	f466                	sd	s9,40(sp)
    800005a6:	f06a                	sd	s10,32(sp)
    800005a8:	ec6e                	sd	s11,24(sp)
    800005aa:	0100                	addi	s0,sp,128
    800005ac:	8a2a                	mv	s4,a0
    800005ae:	e40c                	sd	a1,8(s0)
    800005b0:	e810                	sd	a2,16(s0)
    800005b2:	ec14                	sd	a3,24(s0)
    800005b4:	f018                	sd	a4,32(s0)
    800005b6:	f41c                	sd	a5,40(s0)
    800005b8:	03043823          	sd	a6,48(s0)
    800005bc:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c0:	00010d97          	auipc	s11,0x10
    800005c4:	4d0dad83          	lw	s11,1232(s11) # 80010a90 <pr+0x18>
  if(locking)
    800005c8:	020d9b63          	bnez	s11,800005fe <printf+0x70>
  if (fmt == 0)
    800005cc:	040a0263          	beqz	s4,80000610 <printf+0x82>
  va_start(ap, fmt);
    800005d0:	00840793          	addi	a5,s0,8
    800005d4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d8:	000a4503          	lbu	a0,0(s4)
    800005dc:	16050263          	beqz	a0,80000740 <printf+0x1b2>
    800005e0:	4481                	li	s1,0
    if(c != '%'){
    800005e2:	02500a93          	li	s5,37
    switch(c){
    800005e6:	07000b13          	li	s6,112
  consputc('x');
    800005ea:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ec:	00008b97          	auipc	s7,0x8
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80008040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00010517          	auipc	a0,0x10
    80000602:	47a50513          	addi	a0,a0,1146 # 80010a78 <pr>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	5e4080e7          	jalr	1508(ra) # 80000bea <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00008517          	auipc	a0,0x8
    80000614:	a1850513          	addi	a0,a0,-1512 # 80008028 <etext+0x28>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f2c080e7          	jalr	-212(ra) # 80000544 <panic>
      consputc(c);
    80000620:	00000097          	auipc	ra,0x0
    80000624:	c62080e7          	jalr	-926(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000628:	2485                	addiw	s1,s1,1
    8000062a:	009a07b3          	add	a5,s4,s1
    8000062e:	0007c503          	lbu	a0,0(a5)
    80000632:	10050763          	beqz	a0,80000740 <printf+0x1b2>
    if(c != '%'){
    80000636:	ff5515e3          	bne	a0,s5,80000620 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c783          	lbu	a5,0(a5)
    80000644:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000648:	cfe5                	beqz	a5,80000740 <printf+0x1b2>
    switch(c){
    8000064a:	05678a63          	beq	a5,s6,8000069e <printf+0x110>
    8000064e:	02fb7663          	bgeu	s6,a5,8000067a <printf+0xec>
    80000652:	09978963          	beq	a5,s9,800006e4 <printf+0x156>
    80000656:	07800713          	li	a4,120
    8000065a:	0ce79863          	bne	a5,a4,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	85ea                	mv	a1,s10
    8000066e:	4388                	lw	a0,0(a5)
    80000670:	00000097          	auipc	ra,0x0
    80000674:	e32080e7          	jalr	-462(ra) # 800004a2 <printint>
      break;
    80000678:	bf45                	j	80000628 <printf+0x9a>
    switch(c){
    8000067a:	0b578263          	beq	a5,s5,8000071e <printf+0x190>
    8000067e:	0b879663          	bne	a5,s8,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000682:	f8843783          	ld	a5,-120(s0)
    80000686:	00878713          	addi	a4,a5,8
    8000068a:	f8e43423          	sd	a4,-120(s0)
    8000068e:	4605                	li	a2,1
    80000690:	45a9                	li	a1,10
    80000692:	4388                	lw	a0,0(a5)
    80000694:	00000097          	auipc	ra,0x0
    80000698:	e0e080e7          	jalr	-498(ra) # 800004a2 <printint>
      break;
    8000069c:	b771                	j	80000628 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069e:	f8843783          	ld	a5,-120(s0)
    800006a2:	00878713          	addi	a4,a5,8
    800006a6:	f8e43423          	sd	a4,-120(s0)
    800006aa:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ae:	03000513          	li	a0,48
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bd0080e7          	jalr	-1072(ra) # 80000282 <consputc>
  consputc('x');
    800006ba:	07800513          	li	a0,120
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc4080e7          	jalr	-1084(ra) # 80000282 <consputc>
    800006c6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c8:	03c9d793          	srli	a5,s3,0x3c
    800006cc:	97de                	add	a5,a5,s7
    800006ce:	0007c503          	lbu	a0,0(a5)
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	bb0080e7          	jalr	-1104(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0915e3          	bnez	s2,800006c8 <printf+0x13a>
    800006e2:	b799                	j	80000628 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	0007b903          	ld	s2,0(a5)
    800006f4:	00090e63          	beqz	s2,80000710 <printf+0x182>
      for(; *s; s++)
    800006f8:	00094503          	lbu	a0,0(s2)
    800006fc:	d515                	beqz	a0,80000628 <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b84080e7          	jalr	-1148(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000706:	0905                	addi	s2,s2,1
    80000708:	00094503          	lbu	a0,0(s2)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x170>
    8000070e:	bf29                	j	80000628 <printf+0x9a>
        s = "(null)";
    80000710:	00008917          	auipc	s2,0x8
    80000714:	91090913          	addi	s2,s2,-1776 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x170>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b62080e7          	jalr	-1182(ra) # 80000282 <consputc>
      break;
    80000728:	b701                	j	80000628 <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b56080e7          	jalr	-1194(ra) # 80000282 <consputc>
      consputc(c);
    80000734:	854a                	mv	a0,s2
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b4c080e7          	jalr	-1204(ra) # 80000282 <consputc>
      break;
    8000073e:	b5ed                	j	80000628 <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1d4>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00010517          	auipc	a0,0x10
    80000766:	31650513          	addi	a0,a0,790 # 80010a78 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	534080e7          	jalr	1332(ra) # 80000c9e <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b6>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00010497          	auipc	s1,0x10
    80000782:	2fa48493          	addi	s1,s1,762 # 80010a78 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	3ca080e7          	jalr	970(ra) # 80000b5a <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00008597          	auipc	a1,0x8
    800007da:	88258593          	addi	a1,a1,-1918 # 80008058 <digits+0x18>
    800007de:	00010517          	auipc	a0,0x10
    800007e2:	2ba50513          	addi	a0,a0,698 # 80010a98 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	374080e7          	jalr	884(ra) # 80000b5a <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	39c080e7          	jalr	924(ra) # 80000b9e <push_off>

  if(panicked){
    8000080a:	00008797          	auipc	a5,0x8
    8000080e:	0467a783          	lw	a5,70(a5) # 80008850 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0ff7f793          	andi	a5,a5,255
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dbf5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f793          	andi	a5,s1,255
    8000082c:	10000737          	lui	a4,0x10000
    80000830:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	40a080e7          	jalr	1034(ra) # 80000c3e <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008717          	auipc	a4,0x8
    8000084a:	01273703          	ld	a4,18(a4) # 80008858 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	0127b783          	ld	a5,18(a5) # 80008860 <uart_tx_w>
    80000856:	06e78c63          	beq	a5,a4,800008ce <uartstart+0x88>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	228a0a13          	addi	s4,s4,552 # 80010a98 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	fe048493          	addi	s1,s1,-32 # 80008858 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	fe098993          	addi	s3,s3,-32 # 80008860 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	0ff7f793          	andi	a5,a5,255
    80000890:	0207f793          	andi	a5,a5,32
    80000894:	c785                	beqz	a5,800008bc <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f77793          	andi	a5,a4,31
    8000089a:	97d2                	add	a5,a5,s4
    8000089c:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008a0:	0705                	addi	a4,a4,1
    800008a2:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	93c080e7          	jalr	-1732(ra) # 800021e2 <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	6098                	ld	a4,0(s1)
    800008b4:	0009b783          	ld	a5,0(s3)
    800008b8:	fce798e3          	bne	a5,a4,80000888 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	1b650513          	addi	a0,a0,438 # 80010a98 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	f5e7a783          	lw	a5,-162(a5) # 80008850 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	f647b783          	ld	a5,-156(a5) # 80008860 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	f5473703          	ld	a4,-172(a4) # 80008858 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	188a0a13          	addi	s4,s4,392 # 80010a98 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	f4048493          	addi	s1,s1,-192 # 80008858 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	f4090913          	addi	s2,s2,-192 # 80008860 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00002097          	auipc	ra,0x2
    80000934:	84e080e7          	jalr	-1970(ra) # 8000217e <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	15248493          	addi	s1,s1,338 # 80010a98 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	f0f73323          	sd	a5,-250(a4) # 80008860 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	332080e7          	jalr	818(ra) # 80000c9e <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb91                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a4:	6422                	ld	s0,8(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfe5                	j	800009a4 <uartgetc+0x1e>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b8:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	fcc080e7          	jalr	-52(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c2:	00950763          	beq	a0,s1,800009d0 <uartintr+0x22>
      break;
    consoleintr(c);
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	8fe080e7          	jalr	-1794(ra) # 800002c4 <consoleintr>
  while(1){
    800009ce:	b7f5                	j	800009ba <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009d0:	00010497          	auipc	s1,0x10
    800009d4:	0c848493          	addi	s1,s1,200 # 80010a98 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	210080e7          	jalr	528(ra) # 80000bea <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	2b2080e7          	jalr	690(ra) # 80000c9e <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009fe:	1101                	addi	sp,sp,-32
    80000a00:	ec06                	sd	ra,24(sp)
    80000a02:	e822                	sd	s0,16(sp)
    80000a04:	e426                	sd	s1,8(sp)
    80000a06:	e04a                	sd	s2,0(sp)
    80000a08:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a0a:	03451793          	slli	a5,a0,0x34
    80000a0e:	ebb9                	bnez	a5,80000a64 <kfree+0x66>
    80000a10:	84aa                	mv	s1,a0
    80000a12:	00021797          	auipc	a5,0x21
    80000a16:	2ee78793          	addi	a5,a5,750 # 80021d00 <end>
    80000a1a:	04f56563          	bltu	a0,a5,80000a64 <kfree+0x66>
    80000a1e:	47c5                	li	a5,17
    80000a20:	07ee                	slli	a5,a5,0x1b
    80000a22:	04f57163          	bgeu	a0,a5,80000a64 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a26:	6605                	lui	a2,0x1
    80000a28:	4585                	li	a1,1
    80000a2a:	00000097          	auipc	ra,0x0
    80000a2e:	2bc080e7          	jalr	700(ra) # 80000ce6 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a32:	00010917          	auipc	s2,0x10
    80000a36:	09e90913          	addi	s2,s2,158 # 80010ad0 <kmem>
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	1ae080e7          	jalr	430(ra) # 80000bea <acquire>
  r->next = kmem.freelist;
    80000a44:	01893783          	ld	a5,24(s2)
    80000a48:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a4a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	24e080e7          	jalr	590(ra) # 80000c9e <release>
}
    80000a58:	60e2                	ld	ra,24(sp)
    80000a5a:	6442                	ld	s0,16(sp)
    80000a5c:	64a2                	ld	s1,8(sp)
    80000a5e:	6902                	ld	s2,0(sp)
    80000a60:	6105                	addi	sp,sp,32
    80000a62:	8082                	ret
    panic("kfree");
    80000a64:	00007517          	auipc	a0,0x7
    80000a68:	5fc50513          	addi	a0,a0,1532 # 80008060 <digits+0x20>
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	ad8080e7          	jalr	-1320(ra) # 80000544 <panic>

0000000080000a74 <freerange>:
{
    80000a74:	7179                	addi	sp,sp,-48
    80000a76:	f406                	sd	ra,40(sp)
    80000a78:	f022                	sd	s0,32(sp)
    80000a7a:	ec26                	sd	s1,24(sp)
    80000a7c:	e84a                	sd	s2,16(sp)
    80000a7e:	e44e                	sd	s3,8(sp)
    80000a80:	e052                	sd	s4,0(sp)
    80000a82:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a84:	6785                	lui	a5,0x1
    80000a86:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a8a:	94aa                	add	s1,s1,a0
    80000a8c:	757d                	lui	a0,0xfffff
    80000a8e:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94be                	add	s1,s1,a5
    80000a92:	0095ee63          	bltu	a1,s1,80000aae <freerange+0x3a>
    80000a96:	892e                	mv	s2,a1
    kfree(p);
    80000a98:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	6985                	lui	s3,0x1
    kfree(p);
    80000a9c:	01448533          	add	a0,s1,s4
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	f5e080e7          	jalr	-162(ra) # 800009fe <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa8:	94ce                	add	s1,s1,s3
    80000aaa:	fe9979e3          	bgeu	s2,s1,80000a9c <freerange+0x28>
}
    80000aae:	70a2                	ld	ra,40(sp)
    80000ab0:	7402                	ld	s0,32(sp)
    80000ab2:	64e2                	ld	s1,24(sp)
    80000ab4:	6942                	ld	s2,16(sp)
    80000ab6:	69a2                	ld	s3,8(sp)
    80000ab8:	6a02                	ld	s4,0(sp)
    80000aba:	6145                	addi	sp,sp,48
    80000abc:	8082                	ret

0000000080000abe <kinit>:
{
    80000abe:	1141                	addi	sp,sp,-16
    80000ac0:	e406                	sd	ra,8(sp)
    80000ac2:	e022                	sd	s0,0(sp)
    80000ac4:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac6:	00007597          	auipc	a1,0x7
    80000aca:	5a258593          	addi	a1,a1,1442 # 80008068 <digits+0x28>
    80000ace:	00010517          	auipc	a0,0x10
    80000ad2:	00250513          	addi	a0,a0,2 # 80010ad0 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00021517          	auipc	a0,0x21
    80000ae6:	21e50513          	addi	a0,a0,542 # 80021d00 <end>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	f8a080e7          	jalr	-118(ra) # 80000a74 <freerange>
}
    80000af2:	60a2                	ld	ra,8(sp)
    80000af4:	6402                	ld	s0,0(sp)
    80000af6:	0141                	addi	sp,sp,16
    80000af8:	8082                	ret

0000000080000afa <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afa:	1101                	addi	sp,sp,-32
    80000afc:	ec06                	sd	ra,24(sp)
    80000afe:	e822                	sd	s0,16(sp)
    80000b00:	e426                	sd	s1,8(sp)
    80000b02:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b04:	00010497          	auipc	s1,0x10
    80000b08:	fcc48493          	addi	s1,s1,-52 # 80010ad0 <kmem>
    80000b0c:	8526                	mv	a0,s1
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	0dc080e7          	jalr	220(ra) # 80000bea <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c885                	beqz	s1,80000b48 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00010517          	auipc	a0,0x10
    80000b20:	fb450513          	addi	a0,a0,-76 # 80010ad0 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	178080e7          	jalr	376(ra) # 80000c9e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2e:	6605                	lui	a2,0x1
    80000b30:	4595                	li	a1,5
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	1b2080e7          	jalr	434(ra) # 80000ce6 <memset>
  return (void*)r;
}
    80000b3c:	8526                	mv	a0,s1
    80000b3e:	60e2                	ld	ra,24(sp)
    80000b40:	6442                	ld	s0,16(sp)
    80000b42:	64a2                	ld	s1,8(sp)
    80000b44:	6105                	addi	sp,sp,32
    80000b46:	8082                	ret
  release(&kmem.lock);
    80000b48:	00010517          	auipc	a0,0x10
    80000b4c:	f8850513          	addi	a0,a0,-120 # 80010ad0 <kmem>
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	14e080e7          	jalr	334(ra) # 80000c9e <release>
  if(r)
    80000b58:	b7d5                	j	80000b3c <kalloc+0x42>

0000000080000b5a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b5a:	1141                	addi	sp,sp,-16
    80000b5c:	e422                	sd	s0,8(sp)
    80000b5e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b60:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b62:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b66:	00053823          	sd	zero,16(a0)
}
    80000b6a:	6422                	ld	s0,8(sp)
    80000b6c:	0141                	addi	sp,sp,16
    80000b6e:	8082                	ret

0000000080000b70 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b70:	411c                	lw	a5,0(a0)
    80000b72:	e399                	bnez	a5,80000b78 <holding+0x8>
    80000b74:	4501                	li	a0,0
  return r;
}
    80000b76:	8082                	ret
{
    80000b78:	1101                	addi	sp,sp,-32
    80000b7a:	ec06                	sd	ra,24(sp)
    80000b7c:	e822                	sd	s0,16(sp)
    80000b7e:	e426                	sd	s1,8(sp)
    80000b80:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b82:	6904                	ld	s1,16(a0)
    80000b84:	00001097          	auipc	ra,0x1
    80000b88:	f3a080e7          	jalr	-198(ra) # 80001abe <mycpu>
    80000b8c:	40a48533          	sub	a0,s1,a0
    80000b90:	00153513          	seqz	a0,a0
}
    80000b94:	60e2                	ld	ra,24(sp)
    80000b96:	6442                	ld	s0,16(sp)
    80000b98:	64a2                	ld	s1,8(sp)
    80000b9a:	6105                	addi	sp,sp,32
    80000b9c:	8082                	ret

0000000080000b9e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba8:	100024f3          	csrr	s1,sstatus
    80000bac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bb0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bb2:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb6:	00001097          	auipc	ra,0x1
    80000bba:	f08080e7          	jalr	-248(ra) # 80001abe <mycpu>
    80000bbe:	5d3c                	lw	a5,120(a0)
    80000bc0:	cf89                	beqz	a5,80000bda <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	efc080e7          	jalr	-260(ra) # 80001abe <mycpu>
    80000bca:	5d3c                	lw	a5,120(a0)
    80000bcc:	2785                	addiw	a5,a5,1
    80000bce:	dd3c                	sw	a5,120(a0)
}
    80000bd0:	60e2                	ld	ra,24(sp)
    80000bd2:	6442                	ld	s0,16(sp)
    80000bd4:	64a2                	ld	s1,8(sp)
    80000bd6:	6105                	addi	sp,sp,32
    80000bd8:	8082                	ret
    mycpu()->intena = old;
    80000bda:	00001097          	auipc	ra,0x1
    80000bde:	ee4080e7          	jalr	-284(ra) # 80001abe <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000be2:	8085                	srli	s1,s1,0x1
    80000be4:	8885                	andi	s1,s1,1
    80000be6:	dd64                	sw	s1,124(a0)
    80000be8:	bfe9                	j	80000bc2 <push_off+0x24>

0000000080000bea <acquire>:
{
    80000bea:	1101                	addi	sp,sp,-32
    80000bec:	ec06                	sd	ra,24(sp)
    80000bee:	e822                	sd	s0,16(sp)
    80000bf0:	e426                	sd	s1,8(sp)
    80000bf2:	1000                	addi	s0,sp,32
    80000bf4:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf6:	00000097          	auipc	ra,0x0
    80000bfa:	fa8080e7          	jalr	-88(ra) # 80000b9e <push_off>
  if(holding(lk))
    80000bfe:	8526                	mv	a0,s1
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	f70080e7          	jalr	-144(ra) # 80000b70 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c08:	4705                	li	a4,1
  if(holding(lk))
    80000c0a:	e115                	bnez	a0,80000c2e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c0c:	87ba                	mv	a5,a4
    80000c0e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c12:	2781                	sext.w	a5,a5
    80000c14:	ffe5                	bnez	a5,80000c0c <acquire+0x22>
  __sync_synchronize();
    80000c16:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c1a:	00001097          	auipc	ra,0x1
    80000c1e:	ea4080e7          	jalr	-348(ra) # 80001abe <mycpu>
    80000c22:	e888                	sd	a0,16(s1)
}
    80000c24:	60e2                	ld	ra,24(sp)
    80000c26:	6442                	ld	s0,16(sp)
    80000c28:	64a2                	ld	s1,8(sp)
    80000c2a:	6105                	addi	sp,sp,32
    80000c2c:	8082                	ret
    panic("acquire");
    80000c2e:	00007517          	auipc	a0,0x7
    80000c32:	44250513          	addi	a0,a0,1090 # 80008070 <digits+0x30>
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	90e080e7          	jalr	-1778(ra) # 80000544 <panic>

0000000080000c3e <pop_off>:

void
pop_off(void)
{
    80000c3e:	1141                	addi	sp,sp,-16
    80000c40:	e406                	sd	ra,8(sp)
    80000c42:	e022                	sd	s0,0(sp)
    80000c44:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c46:	00001097          	auipc	ra,0x1
    80000c4a:	e78080e7          	jalr	-392(ra) # 80001abe <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c4e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c54:	e78d                	bnez	a5,80000c7e <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c56:	5d3c                	lw	a5,120(a0)
    80000c58:	02f05b63          	blez	a5,80000c8e <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c5c:	37fd                	addiw	a5,a5,-1
    80000c5e:	0007871b          	sext.w	a4,a5
    80000c62:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c64:	eb09                	bnez	a4,80000c76 <pop_off+0x38>
    80000c66:	5d7c                	lw	a5,124(a0)
    80000c68:	c799                	beqz	a5,80000c76 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c6e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c72:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c76:	60a2                	ld	ra,8(sp)
    80000c78:	6402                	ld	s0,0(sp)
    80000c7a:	0141                	addi	sp,sp,16
    80000c7c:	8082                	ret
    panic("pop_off - interruptible");
    80000c7e:	00007517          	auipc	a0,0x7
    80000c82:	3fa50513          	addi	a0,a0,1018 # 80008078 <digits+0x38>
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	8be080e7          	jalr	-1858(ra) # 80000544 <panic>
    panic("pop_off");
    80000c8e:	00007517          	auipc	a0,0x7
    80000c92:	40250513          	addi	a0,a0,1026 # 80008090 <digits+0x50>
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	8ae080e7          	jalr	-1874(ra) # 80000544 <panic>

0000000080000c9e <release>:
{
    80000c9e:	1101                	addi	sp,sp,-32
    80000ca0:	ec06                	sd	ra,24(sp)
    80000ca2:	e822                	sd	s0,16(sp)
    80000ca4:	e426                	sd	s1,8(sp)
    80000ca6:	1000                	addi	s0,sp,32
    80000ca8:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	ec6080e7          	jalr	-314(ra) # 80000b70 <holding>
    80000cb2:	c115                	beqz	a0,80000cd6 <release+0x38>
  lk->cpu = 0;
    80000cb4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cbc:	0f50000f          	fence	iorw,ow
    80000cc0:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	f7a080e7          	jalr	-134(ra) # 80000c3e <pop_off>
}
    80000ccc:	60e2                	ld	ra,24(sp)
    80000cce:	6442                	ld	s0,16(sp)
    80000cd0:	64a2                	ld	s1,8(sp)
    80000cd2:	6105                	addi	sp,sp,32
    80000cd4:	8082                	ret
    panic("release");
    80000cd6:	00007517          	auipc	a0,0x7
    80000cda:	3c250513          	addi	a0,a0,962 # 80008098 <digits+0x58>
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	866080e7          	jalr	-1946(ra) # 80000544 <panic>

0000000080000ce6 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce6:	1141                	addi	sp,sp,-16
    80000ce8:	e422                	sd	s0,8(sp)
    80000cea:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cec:	ce09                	beqz	a2,80000d06 <memset+0x20>
    80000cee:	87aa                	mv	a5,a0
    80000cf0:	fff6071b          	addiw	a4,a2,-1
    80000cf4:	1702                	slli	a4,a4,0x20
    80000cf6:	9301                	srli	a4,a4,0x20
    80000cf8:	0705                	addi	a4,a4,1
    80000cfa:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cfc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d00:	0785                	addi	a5,a5,1
    80000d02:	fee79de3          	bne	a5,a4,80000cfc <memset+0x16>
  }
  return dst;
}
    80000d06:	6422                	ld	s0,8(sp)
    80000d08:	0141                	addi	sp,sp,16
    80000d0a:	8082                	ret

0000000080000d0c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d12:	ca05                	beqz	a2,80000d42 <memcmp+0x36>
    80000d14:	fff6069b          	addiw	a3,a2,-1
    80000d18:	1682                	slli	a3,a3,0x20
    80000d1a:	9281                	srli	a3,a3,0x20
    80000d1c:	0685                	addi	a3,a3,1
    80000d1e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d20:	00054783          	lbu	a5,0(a0)
    80000d24:	0005c703          	lbu	a4,0(a1)
    80000d28:	00e79863          	bne	a5,a4,80000d38 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d2c:	0505                	addi	a0,a0,1
    80000d2e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d30:	fed518e3          	bne	a0,a3,80000d20 <memcmp+0x14>
  }

  return 0;
    80000d34:	4501                	li	a0,0
    80000d36:	a019                	j	80000d3c <memcmp+0x30>
      return *s1 - *s2;
    80000d38:	40e7853b          	subw	a0,a5,a4
}
    80000d3c:	6422                	ld	s0,8(sp)
    80000d3e:	0141                	addi	sp,sp,16
    80000d40:	8082                	ret
  return 0;
    80000d42:	4501                	li	a0,0
    80000d44:	bfe5                	j	80000d3c <memcmp+0x30>

0000000080000d46 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d46:	1141                	addi	sp,sp,-16
    80000d48:	e422                	sd	s0,8(sp)
    80000d4a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d4c:	ca0d                	beqz	a2,80000d7e <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d4e:	00a5f963          	bgeu	a1,a0,80000d60 <memmove+0x1a>
    80000d52:	02061693          	slli	a3,a2,0x20
    80000d56:	9281                	srli	a3,a3,0x20
    80000d58:	00d58733          	add	a4,a1,a3
    80000d5c:	02e56463          	bltu	a0,a4,80000d84 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d60:	fff6079b          	addiw	a5,a2,-1
    80000d64:	1782                	slli	a5,a5,0x20
    80000d66:	9381                	srli	a5,a5,0x20
    80000d68:	0785                	addi	a5,a5,1
    80000d6a:	97ae                	add	a5,a5,a1
    80000d6c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d6e:	0585                	addi	a1,a1,1
    80000d70:	0705                	addi	a4,a4,1
    80000d72:	fff5c683          	lbu	a3,-1(a1)
    80000d76:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d7a:	fef59ae3          	bne	a1,a5,80000d6e <memmove+0x28>

  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret
    d += n;
    80000d84:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d86:	fff6079b          	addiw	a5,a2,-1
    80000d8a:	1782                	slli	a5,a5,0x20
    80000d8c:	9381                	srli	a5,a5,0x20
    80000d8e:	fff7c793          	not	a5,a5
    80000d92:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d94:	177d                	addi	a4,a4,-1
    80000d96:	16fd                	addi	a3,a3,-1
    80000d98:	00074603          	lbu	a2,0(a4)
    80000d9c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000da0:	fef71ae3          	bne	a4,a5,80000d94 <memmove+0x4e>
    80000da4:	bfe9                	j	80000d7e <memmove+0x38>

0000000080000da6 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da6:	1141                	addi	sp,sp,-16
    80000da8:	e406                	sd	ra,8(sp)
    80000daa:	e022                	sd	s0,0(sp)
    80000dac:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dae:	00000097          	auipc	ra,0x0
    80000db2:	f98080e7          	jalr	-104(ra) # 80000d46 <memmove>
}
    80000db6:	60a2                	ld	ra,8(sp)
    80000db8:	6402                	ld	s0,0(sp)
    80000dba:	0141                	addi	sp,sp,16
    80000dbc:	8082                	ret

0000000080000dbe <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dbe:	1141                	addi	sp,sp,-16
    80000dc0:	e422                	sd	s0,8(sp)
    80000dc2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dc4:	ce11                	beqz	a2,80000de0 <strncmp+0x22>
    80000dc6:	00054783          	lbu	a5,0(a0)
    80000dca:	cf89                	beqz	a5,80000de4 <strncmp+0x26>
    80000dcc:	0005c703          	lbu	a4,0(a1)
    80000dd0:	00f71a63          	bne	a4,a5,80000de4 <strncmp+0x26>
    n--, p++, q++;
    80000dd4:	367d                	addiw	a2,a2,-1
    80000dd6:	0505                	addi	a0,a0,1
    80000dd8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dda:	f675                	bnez	a2,80000dc6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ddc:	4501                	li	a0,0
    80000dde:	a809                	j	80000df0 <strncmp+0x32>
    80000de0:	4501                	li	a0,0
    80000de2:	a039                	j	80000df0 <strncmp+0x32>
  if(n == 0)
    80000de4:	ca09                	beqz	a2,80000df6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de6:	00054503          	lbu	a0,0(a0)
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	9d1d                	subw	a0,a0,a5
}
    80000df0:	6422                	ld	s0,8(sp)
    80000df2:	0141                	addi	sp,sp,16
    80000df4:	8082                	ret
    return 0;
    80000df6:	4501                	li	a0,0
    80000df8:	bfe5                	j	80000df0 <strncmp+0x32>

0000000080000dfa <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dfa:	1141                	addi	sp,sp,-16
    80000dfc:	e422                	sd	s0,8(sp)
    80000dfe:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e00:	872a                	mv	a4,a0
    80000e02:	8832                	mv	a6,a2
    80000e04:	367d                	addiw	a2,a2,-1
    80000e06:	01005963          	blez	a6,80000e18 <strncpy+0x1e>
    80000e0a:	0705                	addi	a4,a4,1
    80000e0c:	0005c783          	lbu	a5,0(a1)
    80000e10:	fef70fa3          	sb	a5,-1(a4)
    80000e14:	0585                	addi	a1,a1,1
    80000e16:	f7f5                	bnez	a5,80000e02 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e18:	00c05d63          	blez	a2,80000e32 <strncpy+0x38>
    80000e1c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e1e:	0685                	addi	a3,a3,1
    80000e20:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e24:	fff6c793          	not	a5,a3
    80000e28:	9fb9                	addw	a5,a5,a4
    80000e2a:	010787bb          	addw	a5,a5,a6
    80000e2e:	fef048e3          	bgtz	a5,80000e1e <strncpy+0x24>
  return os;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret

0000000080000e38 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e38:	1141                	addi	sp,sp,-16
    80000e3a:	e422                	sd	s0,8(sp)
    80000e3c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e3e:	02c05363          	blez	a2,80000e64 <safestrcpy+0x2c>
    80000e42:	fff6069b          	addiw	a3,a2,-1
    80000e46:	1682                	slli	a3,a3,0x20
    80000e48:	9281                	srli	a3,a3,0x20
    80000e4a:	96ae                	add	a3,a3,a1
    80000e4c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e4e:	00d58963          	beq	a1,a3,80000e60 <safestrcpy+0x28>
    80000e52:	0585                	addi	a1,a1,1
    80000e54:	0785                	addi	a5,a5,1
    80000e56:	fff5c703          	lbu	a4,-1(a1)
    80000e5a:	fee78fa3          	sb	a4,-1(a5)
    80000e5e:	fb65                	bnez	a4,80000e4e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e60:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret

0000000080000e6a <strlen>:

int
strlen(const char *s)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e70:	00054783          	lbu	a5,0(a0)
    80000e74:	cf91                	beqz	a5,80000e90 <strlen+0x26>
    80000e76:	0505                	addi	a0,a0,1
    80000e78:	87aa                	mv	a5,a0
    80000e7a:	4685                	li	a3,1
    80000e7c:	9e89                	subw	a3,a3,a0
    80000e7e:	00f6853b          	addw	a0,a3,a5
    80000e82:	0785                	addi	a5,a5,1
    80000e84:	fff7c703          	lbu	a4,-1(a5)
    80000e88:	fb7d                	bnez	a4,80000e7e <strlen+0x14>
    ;
  return n;
}
    80000e8a:	6422                	ld	s0,8(sp)
    80000e8c:	0141                	addi	sp,sp,16
    80000e8e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e90:	4501                	li	a0,0
    80000e92:	bfe5                	j	80000e8a <strlen+0x20>

0000000080000e94 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e406                	sd	ra,8(sp)
    80000e98:	e022                	sd	s0,0(sp)
    80000e9a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	c12080e7          	jalr	-1006(ra) # 80001aae <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea4:	00008717          	auipc	a4,0x8
    80000ea8:	9c470713          	addi	a4,a4,-1596 # 80008868 <started>
  if(cpuid() == 0){
    80000eac:	c139                	beqz	a0,80000ef2 <main+0x5e>
    while(started == 0)
    80000eae:	431c                	lw	a5,0(a4)
    80000eb0:	2781                	sext.w	a5,a5
    80000eb2:	dff5                	beqz	a5,80000eae <main+0x1a>
      ;
    __sync_synchronize();
    80000eb4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	bf6080e7          	jalr	-1034(ra) # 80001aae <cpuid>
    80000ec0:	85aa                	mv	a1,a0
    80000ec2:	00007517          	auipc	a0,0x7
    80000ec6:	1f650513          	addi	a0,a0,502 # 800080b8 <digits+0x78>
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	6c4080e7          	jalr	1732(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	0d8080e7          	jalr	216(ra) # 80000faa <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eda:	00002097          	auipc	ra,0x2
    80000ede:	898080e7          	jalr	-1896(ra) # 80002772 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	eae080e7          	jalr	-338(ra) # 80005d90 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	0e2080e7          	jalr	226(ra) # 80001fcc <scheduler>
    consoleinit();
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	564080e7          	jalr	1380(ra) # 80000456 <consoleinit>
    printfinit();
    80000efa:	00000097          	auipc	ra,0x0
    80000efe:	87a080e7          	jalr	-1926(ra) # 80000774 <printfinit>
    printf("\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	1c650513          	addi	a0,a0,454 # 800080c8 <digits+0x88>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	684080e7          	jalr	1668(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	18e50513          	addi	a0,a0,398 # 800080a0 <digits+0x60>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	674080e7          	jalr	1652(ra) # 8000058e <printf>
    printf("\n");
    80000f22:	00007517          	auipc	a0,0x7
    80000f26:	1a650513          	addi	a0,a0,422 # 800080c8 <digits+0x88>
    80000f2a:	fffff097          	auipc	ra,0xfffff
    80000f2e:	664080e7          	jalr	1636(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	b8c080e7          	jalr	-1140(ra) # 80000abe <kinit>
    kvminit();       // create kernel page table
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	388080e7          	jalr	904(ra) # 800012c2 <kvminit>
    kvminithart();   // turn on paging
    80000f42:	00000097          	auipc	ra,0x0
    80000f46:	068080e7          	jalr	104(ra) # 80000faa <kvminithart>
    procinit();      // process table
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	ab0080e7          	jalr	-1360(ra) # 800019fa <procinit>
    trapinit();      // trap vectors
    80000f52:	00001097          	auipc	ra,0x1
    80000f56:	7f8080e7          	jalr	2040(ra) # 8000274a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	818080e7          	jalr	-2024(ra) # 80002772 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	e18080e7          	jalr	-488(ra) # 80005d7a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	e26080e7          	jalr	-474(ra) # 80005d90 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	fca080e7          	jalr	-54(ra) # 80002f3c <binit>
    iinit();         // inode table
    80000f7a:	00002097          	auipc	ra,0x2
    80000f7e:	66e080e7          	jalr	1646(ra) # 800035e8 <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	60c080e7          	jalr	1548(ra) # 8000458e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	f0e080e7          	jalr	-242(ra) # 80005e98 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	e20080e7          	jalr	-480(ra) # 80001db2 <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	8cf72423          	sw	a5,-1848(a4) # 80008868 <started>
    80000fa8:	b789                	j	80000eea <main+0x56>

0000000080000faa <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000faa:	1141                	addi	sp,sp,-16
    80000fac:	e422                	sd	s0,8(sp)
    80000fae:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb0:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb4:	00008797          	auipc	a5,0x8
    80000fb8:	8bc7b783          	ld	a5,-1860(a5) # 80008870 <kernel_pagetable>
    80000fbc:	83b1                	srli	a5,a5,0xc
    80000fbe:	577d                	li	a4,-1
    80000fc0:	177e                	slli	a4,a4,0x3f
    80000fc2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc4:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fc8:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fcc:	6422                	ld	s0,8(sp)
    80000fce:	0141                	addi	sp,sp,16
    80000fd0:	8082                	ret

0000000080000fd2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd2:	7139                	addi	sp,sp,-64
    80000fd4:	fc06                	sd	ra,56(sp)
    80000fd6:	f822                	sd	s0,48(sp)
    80000fd8:	f426                	sd	s1,40(sp)
    80000fda:	f04a                	sd	s2,32(sp)
    80000fdc:	ec4e                	sd	s3,24(sp)
    80000fde:	e852                	sd	s4,16(sp)
    80000fe0:	e456                	sd	s5,8(sp)
    80000fe2:	e05a                	sd	s6,0(sp)
    80000fe4:	0080                	addi	s0,sp,64
    80000fe6:	84aa                	mv	s1,a0
    80000fe8:	89ae                	mv	s3,a1
    80000fea:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fec:	57fd                	li	a5,-1
    80000fee:	83e9                	srli	a5,a5,0x1a
    80000ff0:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff2:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff4:	04b7f263          	bgeu	a5,a1,80001038 <walk+0x66>
    panic("walk");
    80000ff8:	00007517          	auipc	a0,0x7
    80000ffc:	0d850513          	addi	a0,a0,216 # 800080d0 <digits+0x90>
    80001000:	fffff097          	auipc	ra,0xfffff
    80001004:	544080e7          	jalr	1348(ra) # 80000544 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001008:	060a8663          	beqz	s5,80001074 <walk+0xa2>
    8000100c:	00000097          	auipc	ra,0x0
    80001010:	aee080e7          	jalr	-1298(ra) # 80000afa <kalloc>
    80001014:	84aa                	mv	s1,a0
    80001016:	c529                	beqz	a0,80001060 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001018:	6605                	lui	a2,0x1
    8000101a:	4581                	li	a1,0
    8000101c:	00000097          	auipc	ra,0x0
    80001020:	cca080e7          	jalr	-822(ra) # 80000ce6 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001024:	00c4d793          	srli	a5,s1,0xc
    80001028:	07aa                	slli	a5,a5,0xa
    8000102a:	0017e793          	ori	a5,a5,1
    8000102e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001032:	3a5d                	addiw	s4,s4,-9
    80001034:	036a0063          	beq	s4,s6,80001054 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001038:	0149d933          	srl	s2,s3,s4
    8000103c:	1ff97913          	andi	s2,s2,511
    80001040:	090e                	slli	s2,s2,0x3
    80001042:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001044:	00093483          	ld	s1,0(s2)
    80001048:	0014f793          	andi	a5,s1,1
    8000104c:	dfd5                	beqz	a5,80001008 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104e:	80a9                	srli	s1,s1,0xa
    80001050:	04b2                	slli	s1,s1,0xc
    80001052:	b7c5                	j	80001032 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001054:	00c9d513          	srli	a0,s3,0xc
    80001058:	1ff57513          	andi	a0,a0,511
    8000105c:	050e                	slli	a0,a0,0x3
    8000105e:	9526                	add	a0,a0,s1
}
    80001060:	70e2                	ld	ra,56(sp)
    80001062:	7442                	ld	s0,48(sp)
    80001064:	74a2                	ld	s1,40(sp)
    80001066:	7902                	ld	s2,32(sp)
    80001068:	69e2                	ld	s3,24(sp)
    8000106a:	6a42                	ld	s4,16(sp)
    8000106c:	6aa2                	ld	s5,8(sp)
    8000106e:	6b02                	ld	s6,0(sp)
    80001070:	6121                	addi	sp,sp,64
    80001072:	8082                	ret
        return 0;
    80001074:	4501                	li	a0,0
    80001076:	b7ed                	j	80001060 <walk+0x8e>

0000000080001078 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001078:	715d                	addi	sp,sp,-80
    8000107a:	e486                	sd	ra,72(sp)
    8000107c:	e0a2                	sd	s0,64(sp)
    8000107e:	fc26                	sd	s1,56(sp)
    80001080:	f84a                	sd	s2,48(sp)
    80001082:	f44e                	sd	s3,40(sp)
    80001084:	f052                	sd	s4,32(sp)
    80001086:	ec56                	sd	s5,24(sp)
    80001088:	e85a                	sd	s6,16(sp)
    8000108a:	e45e                	sd	s7,8(sp)
    8000108c:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000108e:	c205                	beqz	a2,800010ae <mappages+0x36>
    80001090:	8aaa                	mv	s5,a0
    80001092:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001094:	77fd                	lui	a5,0xfffff
    80001096:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    8000109a:	15fd                	addi	a1,a1,-1
    8000109c:	00c589b3          	add	s3,a1,a2
    800010a0:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010a4:	8952                	mv	s2,s4
    800010a6:	41468a33          	sub	s4,a3,s4
      continue;
      //panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010aa:	6b85                	lui	s7,0x1
    800010ac:	a811                	j	800010c0 <mappages+0x48>
    panic("mappages: size");
    800010ae:	00007517          	auipc	a0,0x7
    800010b2:	02a50513          	addi	a0,a0,42 # 800080d8 <digits+0x98>
    800010b6:	fffff097          	auipc	ra,0xfffff
    800010ba:	48e080e7          	jalr	1166(ra) # 80000544 <panic>
    a += PGSIZE;
    800010be:	995e                	add	s2,s2,s7
    pa += PGSIZE;
    800010c0:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010c4:	4605                	li	a2,1
    800010c6:	85ca                	mv	a1,s2
    800010c8:	8556                	mv	a0,s5
    800010ca:	00000097          	auipc	ra,0x0
    800010ce:	f08080e7          	jalr	-248(ra) # 80000fd2 <walk>
    800010d2:	cd19                	beqz	a0,800010f0 <mappages+0x78>
    if(*pte & PTE_V) {
    800010d4:	611c                	ld	a5,0(a0)
    800010d6:	8b85                	andi	a5,a5,1
    800010d8:	eb85                	bnez	a5,80001108 <mappages+0x90>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010da:	80b1                	srli	s1,s1,0xc
    800010dc:	04aa                	slli	s1,s1,0xa
    800010de:	0164e4b3          	or	s1,s1,s6
    800010e2:	0014e493          	ori	s1,s1,1
    800010e6:	e104                	sd	s1,0(a0)
    if(a == last)
    800010e8:	fd391be3          	bne	s2,s3,800010be <mappages+0x46>
  }
  return 0;
    800010ec:	4501                	li	a0,0
    800010ee:	a011                	j	800010f2 <mappages+0x7a>
      return -1;
    800010f0:	557d                	li	a0,-1
}
    800010f2:	60a6                	ld	ra,72(sp)
    800010f4:	6406                	ld	s0,64(sp)
    800010f6:	74e2                	ld	s1,56(sp)
    800010f8:	7942                	ld	s2,48(sp)
    800010fa:	79a2                	ld	s3,40(sp)
    800010fc:	7a02                	ld	s4,32(sp)
    800010fe:	6ae2                	ld	s5,24(sp)
    80001100:	6b42                	ld	s6,16(sp)
    80001102:	6ba2                	ld	s7,8(sp)
    80001104:	6161                	addi	sp,sp,80
    80001106:	8082                	ret
      return -1;
    80001108:	557d                	li	a0,-1
    8000110a:	b7e5                	j	800010f2 <mappages+0x7a>

000000008000110c <walkaddr>:
   if(va >= MAXVA)
    8000110c:	57fd                	li	a5,-1
    8000110e:	83e9                	srli	a5,a5,0x1a
    80001110:	00b7f463          	bgeu	a5,a1,80001118 <walkaddr+0xc>
     return 0;
    80001114:	4501                	li	a0,0
}
    80001116:	8082                	ret
{
    80001118:	7179                	addi	sp,sp,-48
    8000111a:	f406                	sd	ra,40(sp)
    8000111c:	f022                	sd	s0,32(sp)
    8000111e:	ec26                	sd	s1,24(sp)
    80001120:	e84a                	sd	s2,16(sp)
    80001122:	e44e                	sd	s3,8(sp)
    80001124:	e052                	sd	s4,0(sp)
    80001126:	1800                	addi	s0,sp,48
    80001128:	89aa                	mv	s3,a0
    8000112a:	84ae                	mv	s1,a1
   pte = walk(pagetable, va, 0);
    8000112c:	4601                	li	a2,0
    8000112e:	00000097          	auipc	ra,0x0
    80001132:	ea4080e7          	jalr	-348(ra) # 80000fd2 <walk>
    80001136:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001138:	00001097          	auipc	ra,0x1
    8000113c:	9a2080e7          	jalr	-1630(ra) # 80001ada <myproc>
    80001140:	87aa                	mv	a5,a0
  if(pte == 0 || (*pte & PTE_V) == 0 || (*pte & PTE_U) == 0) {
    80001142:	00090863          	beqz	s2,80001152 <walkaddr+0x46>
    80001146:	00093703          	ld	a4,0(s2)
    8000114a:	8b45                	andi	a4,a4,17
    8000114c:	46c5                	li	a3,17
    8000114e:	04d70463          	beq	a4,a3,80001196 <walkaddr+0x8a>
    if ((va >= p->sz) || (va < p->trapframe->sp)){
    80001152:	67b8                	ld	a4,72(a5)
      return 0;
    80001154:	4501                	li	a0,0
    if ((va >= p->sz) || (va < p->trapframe->sp)){
    80001156:	04e4f463          	bgeu	s1,a4,8000119e <walkaddr+0x92>
    8000115a:	6fbc                	ld	a5,88(a5)
    8000115c:	7b9c                	ld	a5,48(a5)
    8000115e:	04f4e063          	bltu	s1,a5,8000119e <walkaddr+0x92>
    char *m = kalloc();
    80001162:	00000097          	auipc	ra,0x0
    80001166:	998080e7          	jalr	-1640(ra) # 80000afa <kalloc>
    8000116a:	8a2a                	mv	s4,a0
      return 0;
    8000116c:	4501                	li	a0,0
    if (m == 0){
    8000116e:	020a0863          	beqz	s4,8000119e <walkaddr+0x92>
    memset(m, 0, PGSIZE);
    80001172:	6605                	lui	a2,0x1
    80001174:	4581                	li	a1,0
    80001176:	8552                	mv	a0,s4
    80001178:	00000097          	auipc	ra,0x0
    8000117c:	b6e080e7          	jalr	-1170(ra) # 80000ce6 <memset>
    if(mappages(pagetable, PGROUNDDOWN(va), PGSIZE, (uint64)m, PTE_W|PTE_R|PTE_U) != 0) {
    80001180:	4759                	li	a4,22
    80001182:	86d2                	mv	a3,s4
    80001184:	6605                	lui	a2,0x1
    80001186:	75fd                	lui	a1,0xfffff
    80001188:	8de5                	and	a1,a1,s1
    8000118a:	854e                	mv	a0,s3
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	eec080e7          	jalr	-276(ra) # 80001078 <mappages>
    80001194:	ed09                	bnez	a0,800011ae <walkaddr+0xa2>
  pa = PTE2PA(*pte);
    80001196:	00093503          	ld	a0,0(s2)
    8000119a:	8129                	srli	a0,a0,0xa
    8000119c:	0532                	slli	a0,a0,0xc
}
    8000119e:	70a2                	ld	ra,40(sp)
    800011a0:	7402                	ld	s0,32(sp)
    800011a2:	64e2                	ld	s1,24(sp)
    800011a4:	6942                	ld	s2,16(sp)
    800011a6:	69a2                	ld	s3,8(sp)
    800011a8:	6a02                	ld	s4,0(sp)
    800011aa:	6145                	addi	sp,sp,48
    800011ac:	8082                	ret
      kfree(m);
    800011ae:	8552                	mv	a0,s4
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	84e080e7          	jalr	-1970(ra) # 800009fe <kfree>
      return 0;
    800011b8:	4501                	li	a0,0
    800011ba:	b7d5                	j	8000119e <walkaddr+0x92>

00000000800011bc <kvmmap>:
{
    800011bc:	1141                	addi	sp,sp,-16
    800011be:	e406                	sd	ra,8(sp)
    800011c0:	e022                	sd	s0,0(sp)
    800011c2:	0800                	addi	s0,sp,16
    800011c4:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011c6:	86b2                	mv	a3,a2
    800011c8:	863e                	mv	a2,a5
    800011ca:	00000097          	auipc	ra,0x0
    800011ce:	eae080e7          	jalr	-338(ra) # 80001078 <mappages>
    800011d2:	e509                	bnez	a0,800011dc <kvmmap+0x20>
}
    800011d4:	60a2                	ld	ra,8(sp)
    800011d6:	6402                	ld	s0,0(sp)
    800011d8:	0141                	addi	sp,sp,16
    800011da:	8082                	ret
    panic("kvmmap");
    800011dc:	00007517          	auipc	a0,0x7
    800011e0:	f0c50513          	addi	a0,a0,-244 # 800080e8 <digits+0xa8>
    800011e4:	fffff097          	auipc	ra,0xfffff
    800011e8:	360080e7          	jalr	864(ra) # 80000544 <panic>

00000000800011ec <kvmmake>:
{
    800011ec:	1101                	addi	sp,sp,-32
    800011ee:	ec06                	sd	ra,24(sp)
    800011f0:	e822                	sd	s0,16(sp)
    800011f2:	e426                	sd	s1,8(sp)
    800011f4:	e04a                	sd	s2,0(sp)
    800011f6:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011f8:	00000097          	auipc	ra,0x0
    800011fc:	902080e7          	jalr	-1790(ra) # 80000afa <kalloc>
    80001200:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001202:	6605                	lui	a2,0x1
    80001204:	4581                	li	a1,0
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	ae0080e7          	jalr	-1312(ra) # 80000ce6 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000120e:	4719                	li	a4,6
    80001210:	6685                	lui	a3,0x1
    80001212:	10000637          	lui	a2,0x10000
    80001216:	100005b7          	lui	a1,0x10000
    8000121a:	8526                	mv	a0,s1
    8000121c:	00000097          	auipc	ra,0x0
    80001220:	fa0080e7          	jalr	-96(ra) # 800011bc <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001224:	4719                	li	a4,6
    80001226:	6685                	lui	a3,0x1
    80001228:	10001637          	lui	a2,0x10001
    8000122c:	100015b7          	lui	a1,0x10001
    80001230:	8526                	mv	a0,s1
    80001232:	00000097          	auipc	ra,0x0
    80001236:	f8a080e7          	jalr	-118(ra) # 800011bc <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000123a:	4719                	li	a4,6
    8000123c:	004006b7          	lui	a3,0x400
    80001240:	0c000637          	lui	a2,0xc000
    80001244:	0c0005b7          	lui	a1,0xc000
    80001248:	8526                	mv	a0,s1
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	f72080e7          	jalr	-142(ra) # 800011bc <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001252:	00007917          	auipc	s2,0x7
    80001256:	dae90913          	addi	s2,s2,-594 # 80008000 <etext>
    8000125a:	4729                	li	a4,10
    8000125c:	80007697          	auipc	a3,0x80007
    80001260:	da468693          	addi	a3,a3,-604 # 8000 <_entry-0x7fff8000>
    80001264:	4605                	li	a2,1
    80001266:	067e                	slli	a2,a2,0x1f
    80001268:	85b2                	mv	a1,a2
    8000126a:	8526                	mv	a0,s1
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	f50080e7          	jalr	-176(ra) # 800011bc <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001274:	4719                	li	a4,6
    80001276:	46c5                	li	a3,17
    80001278:	06ee                	slli	a3,a3,0x1b
    8000127a:	412686b3          	sub	a3,a3,s2
    8000127e:	864a                	mv	a2,s2
    80001280:	85ca                	mv	a1,s2
    80001282:	8526                	mv	a0,s1
    80001284:	00000097          	auipc	ra,0x0
    80001288:	f38080e7          	jalr	-200(ra) # 800011bc <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000128c:	4729                	li	a4,10
    8000128e:	6685                	lui	a3,0x1
    80001290:	00006617          	auipc	a2,0x6
    80001294:	d7060613          	addi	a2,a2,-656 # 80007000 <_trampoline>
    80001298:	040005b7          	lui	a1,0x4000
    8000129c:	15fd                	addi	a1,a1,-1
    8000129e:	05b2                	slli	a1,a1,0xc
    800012a0:	8526                	mv	a0,s1
    800012a2:	00000097          	auipc	ra,0x0
    800012a6:	f1a080e7          	jalr	-230(ra) # 800011bc <kvmmap>
  proc_mapstacks(kpgtbl);
    800012aa:	8526                	mv	a0,s1
    800012ac:	00000097          	auipc	ra,0x0
    800012b0:	6b8080e7          	jalr	1720(ra) # 80001964 <proc_mapstacks>
}
    800012b4:	8526                	mv	a0,s1
    800012b6:	60e2                	ld	ra,24(sp)
    800012b8:	6442                	ld	s0,16(sp)
    800012ba:	64a2                	ld	s1,8(sp)
    800012bc:	6902                	ld	s2,0(sp)
    800012be:	6105                	addi	sp,sp,32
    800012c0:	8082                	ret

00000000800012c2 <kvminit>:
{
    800012c2:	1141                	addi	sp,sp,-16
    800012c4:	e406                	sd	ra,8(sp)
    800012c6:	e022                	sd	s0,0(sp)
    800012c8:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800012ca:	00000097          	auipc	ra,0x0
    800012ce:	f22080e7          	jalr	-222(ra) # 800011ec <kvmmake>
    800012d2:	00007797          	auipc	a5,0x7
    800012d6:	58a7bf23          	sd	a0,1438(a5) # 80008870 <kernel_pagetable>
}
    800012da:	60a2                	ld	ra,8(sp)
    800012dc:	6402                	ld	s0,0(sp)
    800012de:	0141                	addi	sp,sp,16
    800012e0:	8082                	ret

00000000800012e2 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012e2:	715d                	addi	sp,sp,-80
    800012e4:	e486                	sd	ra,72(sp)
    800012e6:	e0a2                	sd	s0,64(sp)
    800012e8:	fc26                	sd	s1,56(sp)
    800012ea:	f84a                	sd	s2,48(sp)
    800012ec:	f44e                	sd	s3,40(sp)
    800012ee:	f052                	sd	s4,32(sp)
    800012f0:	ec56                	sd	s5,24(sp)
    800012f2:	e85a                	sd	s6,16(sp)
    800012f4:	e45e                	sd	s7,8(sp)
    800012f6:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012f8:	03459793          	slli	a5,a1,0x34
    800012fc:	e795                	bnez	a5,80001328 <uvmunmap+0x46>
    800012fe:	8a2a                	mv	s4,a0
    80001300:	892e                	mv	s2,a1
    80001302:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001304:	0632                	slli	a2,a2,0xc
    80001306:	00b609b3          	add	s3,a2,a1
      continue;
      //panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      continue;
      //panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	6a85                	lui	s5,0x1
    8000130e:	0535e963          	bltu	a1,s3,80001360 <uvmunmap+0x7e>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001312:	60a6                	ld	ra,72(sp)
    80001314:	6406                	ld	s0,64(sp)
    80001316:	74e2                	ld	s1,56(sp)
    80001318:	7942                	ld	s2,48(sp)
    8000131a:	79a2                	ld	s3,40(sp)
    8000131c:	7a02                	ld	s4,32(sp)
    8000131e:	6ae2                	ld	s5,24(sp)
    80001320:	6b42                	ld	s6,16(sp)
    80001322:	6ba2                	ld	s7,8(sp)
    80001324:	6161                	addi	sp,sp,80
    80001326:	8082                	ret
    panic("uvmunmap: not aligned");
    80001328:	00007517          	auipc	a0,0x7
    8000132c:	dc850513          	addi	a0,a0,-568 # 800080f0 <digits+0xb0>
    80001330:	fffff097          	auipc	ra,0xfffff
    80001334:	214080e7          	jalr	532(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    80001338:	00007517          	auipc	a0,0x7
    8000133c:	dd050513          	addi	a0,a0,-560 # 80008108 <digits+0xc8>
    80001340:	fffff097          	auipc	ra,0xfffff
    80001344:	204080e7          	jalr	516(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    80001348:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    8000134a:	00c79513          	slli	a0,a5,0xc
    8000134e:	fffff097          	auipc	ra,0xfffff
    80001352:	6b0080e7          	jalr	1712(ra) # 800009fe <kfree>
    *pte = 0;
    80001356:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000135a:	9956                	add	s2,s2,s5
    8000135c:	fb397be3          	bgeu	s2,s3,80001312 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001360:	4601                	li	a2,0
    80001362:	85ca                	mv	a1,s2
    80001364:	8552                	mv	a0,s4
    80001366:	00000097          	auipc	ra,0x0
    8000136a:	c6c080e7          	jalr	-916(ra) # 80000fd2 <walk>
    8000136e:	84aa                	mv	s1,a0
    80001370:	d56d                	beqz	a0,8000135a <uvmunmap+0x78>
    if((*pte & PTE_V) == 0)
    80001372:	611c                	ld	a5,0(a0)
    80001374:	0017f713          	andi	a4,a5,1
    80001378:	d36d                	beqz	a4,8000135a <uvmunmap+0x78>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000137a:	3ff7f713          	andi	a4,a5,1023
    8000137e:	fb770de3          	beq	a4,s7,80001338 <uvmunmap+0x56>
    if(do_free){
    80001382:	fc0b0ae3          	beqz	s6,80001356 <uvmunmap+0x74>
    80001386:	b7c9                	j	80001348 <uvmunmap+0x66>

0000000080001388 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001388:	1101                	addi	sp,sp,-32
    8000138a:	ec06                	sd	ra,24(sp)
    8000138c:	e822                	sd	s0,16(sp)
    8000138e:	e426                	sd	s1,8(sp)
    80001390:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001392:	fffff097          	auipc	ra,0xfffff
    80001396:	768080e7          	jalr	1896(ra) # 80000afa <kalloc>
    8000139a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000139c:	c519                	beqz	a0,800013aa <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	00000097          	auipc	ra,0x0
    800013a6:	944080e7          	jalr	-1724(ra) # 80000ce6 <memset>
  return pagetable;
}
    800013aa:	8526                	mv	a0,s1
    800013ac:	60e2                	ld	ra,24(sp)
    800013ae:	6442                	ld	s0,16(sp)
    800013b0:	64a2                	ld	s1,8(sp)
    800013b2:	6105                	addi	sp,sp,32
    800013b4:	8082                	ret

00000000800013b6 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800013b6:	7179                	addi	sp,sp,-48
    800013b8:	f406                	sd	ra,40(sp)
    800013ba:	f022                	sd	s0,32(sp)
    800013bc:	ec26                	sd	s1,24(sp)
    800013be:	e84a                	sd	s2,16(sp)
    800013c0:	e44e                	sd	s3,8(sp)
    800013c2:	e052                	sd	s4,0(sp)
    800013c4:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013c6:	6785                	lui	a5,0x1
    800013c8:	04f67863          	bgeu	a2,a5,80001418 <uvmfirst+0x62>
    800013cc:	8a2a                	mv	s4,a0
    800013ce:	89ae                	mv	s3,a1
    800013d0:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	728080e7          	jalr	1832(ra) # 80000afa <kalloc>
    800013da:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013dc:	6605                	lui	a2,0x1
    800013de:	4581                	li	a1,0
    800013e0:	00000097          	auipc	ra,0x0
    800013e4:	906080e7          	jalr	-1786(ra) # 80000ce6 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013e8:	4779                	li	a4,30
    800013ea:	86ca                	mv	a3,s2
    800013ec:	6605                	lui	a2,0x1
    800013ee:	4581                	li	a1,0
    800013f0:	8552                	mv	a0,s4
    800013f2:	00000097          	auipc	ra,0x0
    800013f6:	c86080e7          	jalr	-890(ra) # 80001078 <mappages>
  memmove(mem, src, sz);
    800013fa:	8626                	mv	a2,s1
    800013fc:	85ce                	mv	a1,s3
    800013fe:	854a                	mv	a0,s2
    80001400:	00000097          	auipc	ra,0x0
    80001404:	946080e7          	jalr	-1722(ra) # 80000d46 <memmove>
}
    80001408:	70a2                	ld	ra,40(sp)
    8000140a:	7402                	ld	s0,32(sp)
    8000140c:	64e2                	ld	s1,24(sp)
    8000140e:	6942                	ld	s2,16(sp)
    80001410:	69a2                	ld	s3,8(sp)
    80001412:	6a02                	ld	s4,0(sp)
    80001414:	6145                	addi	sp,sp,48
    80001416:	8082                	ret
    panic("uvmfirst: more than a page");
    80001418:	00007517          	auipc	a0,0x7
    8000141c:	d0850513          	addi	a0,a0,-760 # 80008120 <digits+0xe0>
    80001420:	fffff097          	auipc	ra,0xfffff
    80001424:	124080e7          	jalr	292(ra) # 80000544 <panic>

0000000080001428 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001428:	1101                	addi	sp,sp,-32
    8000142a:	ec06                	sd	ra,24(sp)
    8000142c:	e822                	sd	s0,16(sp)
    8000142e:	e426                	sd	s1,8(sp)
    80001430:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001432:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001434:	00b67d63          	bgeu	a2,a1,8000144e <uvmdealloc+0x26>
    80001438:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000143a:	6785                	lui	a5,0x1
    8000143c:	17fd                	addi	a5,a5,-1
    8000143e:	00f60733          	add	a4,a2,a5
    80001442:	767d                	lui	a2,0xfffff
    80001444:	8f71                	and	a4,a4,a2
    80001446:	97ae                	add	a5,a5,a1
    80001448:	8ff1                	and	a5,a5,a2
    8000144a:	00f76863          	bltu	a4,a5,8000145a <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000144e:	8526                	mv	a0,s1
    80001450:	60e2                	ld	ra,24(sp)
    80001452:	6442                	ld	s0,16(sp)
    80001454:	64a2                	ld	s1,8(sp)
    80001456:	6105                	addi	sp,sp,32
    80001458:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000145a:	8f99                	sub	a5,a5,a4
    8000145c:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000145e:	4685                	li	a3,1
    80001460:	0007861b          	sext.w	a2,a5
    80001464:	85ba                	mv	a1,a4
    80001466:	00000097          	auipc	ra,0x0
    8000146a:	e7c080e7          	jalr	-388(ra) # 800012e2 <uvmunmap>
    8000146e:	b7c5                	j	8000144e <uvmdealloc+0x26>

0000000080001470 <uvmalloc>:
  if(newsz < oldsz)
    80001470:	0ab66563          	bltu	a2,a1,8000151a <uvmalloc+0xaa>
{
    80001474:	7139                	addi	sp,sp,-64
    80001476:	fc06                	sd	ra,56(sp)
    80001478:	f822                	sd	s0,48(sp)
    8000147a:	f426                	sd	s1,40(sp)
    8000147c:	f04a                	sd	s2,32(sp)
    8000147e:	ec4e                	sd	s3,24(sp)
    80001480:	e852                	sd	s4,16(sp)
    80001482:	e456                	sd	s5,8(sp)
    80001484:	e05a                	sd	s6,0(sp)
    80001486:	0080                	addi	s0,sp,64
    80001488:	8aaa                	mv	s5,a0
    8000148a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000148c:	6985                	lui	s3,0x1
    8000148e:	19fd                	addi	s3,s3,-1
    80001490:	95ce                	add	a1,a1,s3
    80001492:	79fd                	lui	s3,0xfffff
    80001494:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001498:	08c9f363          	bgeu	s3,a2,8000151e <uvmalloc+0xae>
    8000149c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000149e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800014a2:	fffff097          	auipc	ra,0xfffff
    800014a6:	658080e7          	jalr	1624(ra) # 80000afa <kalloc>
    800014aa:	84aa                	mv	s1,a0
    if(mem == 0){
    800014ac:	c51d                	beqz	a0,800014da <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800014ae:	6605                	lui	a2,0x1
    800014b0:	4581                	li	a1,0
    800014b2:	00000097          	auipc	ra,0x0
    800014b6:	834080e7          	jalr	-1996(ra) # 80000ce6 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014ba:	875a                	mv	a4,s6
    800014bc:	86a6                	mv	a3,s1
    800014be:	6605                	lui	a2,0x1
    800014c0:	85ca                	mv	a1,s2
    800014c2:	8556                	mv	a0,s5
    800014c4:	00000097          	auipc	ra,0x0
    800014c8:	bb4080e7          	jalr	-1100(ra) # 80001078 <mappages>
    800014cc:	e90d                	bnez	a0,800014fe <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014ce:	6785                	lui	a5,0x1
    800014d0:	993e                	add	s2,s2,a5
    800014d2:	fd4968e3          	bltu	s2,s4,800014a2 <uvmalloc+0x32>
  return newsz;
    800014d6:	8552                	mv	a0,s4
    800014d8:	a809                	j	800014ea <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800014da:	864e                	mv	a2,s3
    800014dc:	85ca                	mv	a1,s2
    800014de:	8556                	mv	a0,s5
    800014e0:	00000097          	auipc	ra,0x0
    800014e4:	f48080e7          	jalr	-184(ra) # 80001428 <uvmdealloc>
      return 0;
    800014e8:	4501                	li	a0,0
}
    800014ea:	70e2                	ld	ra,56(sp)
    800014ec:	7442                	ld	s0,48(sp)
    800014ee:	74a2                	ld	s1,40(sp)
    800014f0:	7902                	ld	s2,32(sp)
    800014f2:	69e2                	ld	s3,24(sp)
    800014f4:	6a42                	ld	s4,16(sp)
    800014f6:	6aa2                	ld	s5,8(sp)
    800014f8:	6b02                	ld	s6,0(sp)
    800014fa:	6121                	addi	sp,sp,64
    800014fc:	8082                	ret
      kfree(mem);
    800014fe:	8526                	mv	a0,s1
    80001500:	fffff097          	auipc	ra,0xfffff
    80001504:	4fe080e7          	jalr	1278(ra) # 800009fe <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001508:	864e                	mv	a2,s3
    8000150a:	85ca                	mv	a1,s2
    8000150c:	8556                	mv	a0,s5
    8000150e:	00000097          	auipc	ra,0x0
    80001512:	f1a080e7          	jalr	-230(ra) # 80001428 <uvmdealloc>
      return 0;
    80001516:	4501                	li	a0,0
    80001518:	bfc9                	j	800014ea <uvmalloc+0x7a>
    return oldsz;
    8000151a:	852e                	mv	a0,a1
}
    8000151c:	8082                	ret
  return newsz;
    8000151e:	8532                	mv	a0,a2
    80001520:	b7e9                	j	800014ea <uvmalloc+0x7a>

0000000080001522 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001522:	7179                	addi	sp,sp,-48
    80001524:	f406                	sd	ra,40(sp)
    80001526:	f022                	sd	s0,32(sp)
    80001528:	ec26                	sd	s1,24(sp)
    8000152a:	e84a                	sd	s2,16(sp)
    8000152c:	e44e                	sd	s3,8(sp)
    8000152e:	e052                	sd	s4,0(sp)
    80001530:	1800                	addi	s0,sp,48
    80001532:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001534:	84aa                	mv	s1,a0
    80001536:	6905                	lui	s2,0x1
    80001538:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000153a:	4985                	li	s3,1
    8000153c:	a821                	j	80001554 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000153e:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001540:	0532                	slli	a0,a0,0xc
    80001542:	00000097          	auipc	ra,0x0
    80001546:	fe0080e7          	jalr	-32(ra) # 80001522 <freewalk>
      pagetable[i] = 0;
    8000154a:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000154e:	04a1                	addi	s1,s1,8
    80001550:	03248163          	beq	s1,s2,80001572 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001554:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001556:	00f57793          	andi	a5,a0,15
    8000155a:	ff3782e3          	beq	a5,s3,8000153e <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000155e:	8905                	andi	a0,a0,1
    80001560:	d57d                	beqz	a0,8000154e <freewalk+0x2c>
      panic("freewalk: leaf");
    80001562:	00007517          	auipc	a0,0x7
    80001566:	bde50513          	addi	a0,a0,-1058 # 80008140 <digits+0x100>
    8000156a:	fffff097          	auipc	ra,0xfffff
    8000156e:	fda080e7          	jalr	-38(ra) # 80000544 <panic>
    }
  }
  kfree((void*)pagetable);
    80001572:	8552                	mv	a0,s4
    80001574:	fffff097          	auipc	ra,0xfffff
    80001578:	48a080e7          	jalr	1162(ra) # 800009fe <kfree>
}
    8000157c:	70a2                	ld	ra,40(sp)
    8000157e:	7402                	ld	s0,32(sp)
    80001580:	64e2                	ld	s1,24(sp)
    80001582:	6942                	ld	s2,16(sp)
    80001584:	69a2                	ld	s3,8(sp)
    80001586:	6a02                	ld	s4,0(sp)
    80001588:	6145                	addi	sp,sp,48
    8000158a:	8082                	ret

000000008000158c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000158c:	1101                	addi	sp,sp,-32
    8000158e:	ec06                	sd	ra,24(sp)
    80001590:	e822                	sd	s0,16(sp)
    80001592:	e426                	sd	s1,8(sp)
    80001594:	1000                	addi	s0,sp,32
    80001596:	84aa                	mv	s1,a0
  if(sz > 0)
    80001598:	e999                	bnez	a1,800015ae <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000159a:	8526                	mv	a0,s1
    8000159c:	00000097          	auipc	ra,0x0
    800015a0:	f86080e7          	jalr	-122(ra) # 80001522 <freewalk>
}
    800015a4:	60e2                	ld	ra,24(sp)
    800015a6:	6442                	ld	s0,16(sp)
    800015a8:	64a2                	ld	s1,8(sp)
    800015aa:	6105                	addi	sp,sp,32
    800015ac:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015ae:	6605                	lui	a2,0x1
    800015b0:	167d                	addi	a2,a2,-1
    800015b2:	962e                	add	a2,a2,a1
    800015b4:	4685                	li	a3,1
    800015b6:	8231                	srli	a2,a2,0xc
    800015b8:	4581                	li	a1,0
    800015ba:	00000097          	auipc	ra,0x0
    800015be:	d28080e7          	jalr	-728(ra) # 800012e2 <uvmunmap>
    800015c2:	bfe1                	j	8000159a <uvmfree+0xe>

00000000800015c4 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015c4:	ca4d                	beqz	a2,80001676 <uvmcopy+0xb2>
{
    800015c6:	715d                	addi	sp,sp,-80
    800015c8:	e486                	sd	ra,72(sp)
    800015ca:	e0a2                	sd	s0,64(sp)
    800015cc:	fc26                	sd	s1,56(sp)
    800015ce:	f84a                	sd	s2,48(sp)
    800015d0:	f44e                	sd	s3,40(sp)
    800015d2:	f052                	sd	s4,32(sp)
    800015d4:	ec56                	sd	s5,24(sp)
    800015d6:	e85a                	sd	s6,16(sp)
    800015d8:	e45e                	sd	s7,8(sp)
    800015da:	0880                	addi	s0,sp,80
    800015dc:	8aaa                	mv	s5,a0
    800015de:	8b2e                	mv	s6,a1
    800015e0:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015e2:	4481                	li	s1,0
    800015e4:	a029                	j	800015ee <uvmcopy+0x2a>
    800015e6:	6785                	lui	a5,0x1
    800015e8:	94be                	add	s1,s1,a5
    800015ea:	0744fa63          	bgeu	s1,s4,8000165e <uvmcopy+0x9a>
    if((pte = walk(old, i, 0)) == 0)
    800015ee:	4601                	li	a2,0
    800015f0:	85a6                	mv	a1,s1
    800015f2:	8556                	mv	a0,s5
    800015f4:	00000097          	auipc	ra,0x0
    800015f8:	9de080e7          	jalr	-1570(ra) # 80000fd2 <walk>
    800015fc:	d56d                	beqz	a0,800015e6 <uvmcopy+0x22>
      continue;
     // panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015fe:	6118                	ld	a4,0(a0)
    80001600:	00177793          	andi	a5,a4,1
    80001604:	d3ed                	beqz	a5,800015e6 <uvmcopy+0x22>
      continue;
    //  panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001606:	00a75593          	srli	a1,a4,0xa
    8000160a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000160e:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	4e8080e7          	jalr	1256(ra) # 80000afa <kalloc>
    8000161a:	89aa                	mv	s3,a0
    8000161c:	c515                	beqz	a0,80001648 <uvmcopy+0x84>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000161e:	6605                	lui	a2,0x1
    80001620:	85de                	mv	a1,s7
    80001622:	fffff097          	auipc	ra,0xfffff
    80001626:	724080e7          	jalr	1828(ra) # 80000d46 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000162a:	874a                	mv	a4,s2
    8000162c:	86ce                	mv	a3,s3
    8000162e:	6605                	lui	a2,0x1
    80001630:	85a6                	mv	a1,s1
    80001632:	855a                	mv	a0,s6
    80001634:	00000097          	auipc	ra,0x0
    80001638:	a44080e7          	jalr	-1468(ra) # 80001078 <mappages>
    8000163c:	d54d                	beqz	a0,800015e6 <uvmcopy+0x22>
      kfree(mem);
    8000163e:	854e                	mv	a0,s3
    80001640:	fffff097          	auipc	ra,0xfffff
    80001644:	3be080e7          	jalr	958(ra) # 800009fe <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001648:	4685                	li	a3,1
    8000164a:	00c4d613          	srli	a2,s1,0xc
    8000164e:	4581                	li	a1,0
    80001650:	855a                	mv	a0,s6
    80001652:	00000097          	auipc	ra,0x0
    80001656:	c90080e7          	jalr	-880(ra) # 800012e2 <uvmunmap>
  return -1;
    8000165a:	557d                	li	a0,-1
    8000165c:	a011                	j	80001660 <uvmcopy+0x9c>
  return 0;
    8000165e:	4501                	li	a0,0
}
    80001660:	60a6                	ld	ra,72(sp)
    80001662:	6406                	ld	s0,64(sp)
    80001664:	74e2                	ld	s1,56(sp)
    80001666:	7942                	ld	s2,48(sp)
    80001668:	79a2                	ld	s3,40(sp)
    8000166a:	7a02                	ld	s4,32(sp)
    8000166c:	6ae2                	ld	s5,24(sp)
    8000166e:	6b42                	ld	s6,16(sp)
    80001670:	6ba2                	ld	s7,8(sp)
    80001672:	6161                	addi	sp,sp,80
    80001674:	8082                	ret
  return 0;
    80001676:	4501                	li	a0,0
}
    80001678:	8082                	ret

000000008000167a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000167a:	1141                	addi	sp,sp,-16
    8000167c:	e406                	sd	ra,8(sp)
    8000167e:	e022                	sd	s0,0(sp)
    80001680:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001682:	4601                	li	a2,0
    80001684:	00000097          	auipc	ra,0x0
    80001688:	94e080e7          	jalr	-1714(ra) # 80000fd2 <walk>
  if(pte == 0)
    8000168c:	c901                	beqz	a0,8000169c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000168e:	611c                	ld	a5,0(a0)
    80001690:	9bbd                	andi	a5,a5,-17
    80001692:	e11c                	sd	a5,0(a0)
}
    80001694:	60a2                	ld	ra,8(sp)
    80001696:	6402                	ld	s0,0(sp)
    80001698:	0141                	addi	sp,sp,16
    8000169a:	8082                	ret
    panic("uvmclear");
    8000169c:	00007517          	auipc	a0,0x7
    800016a0:	ab450513          	addi	a0,a0,-1356 # 80008150 <digits+0x110>
    800016a4:	fffff097          	auipc	ra,0xfffff
    800016a8:	ea0080e7          	jalr	-352(ra) # 80000544 <panic>

00000000800016ac <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016ac:	c6bd                	beqz	a3,8000171a <copyout+0x6e>
{
    800016ae:	715d                	addi	sp,sp,-80
    800016b0:	e486                	sd	ra,72(sp)
    800016b2:	e0a2                	sd	s0,64(sp)
    800016b4:	fc26                	sd	s1,56(sp)
    800016b6:	f84a                	sd	s2,48(sp)
    800016b8:	f44e                	sd	s3,40(sp)
    800016ba:	f052                	sd	s4,32(sp)
    800016bc:	ec56                	sd	s5,24(sp)
    800016be:	e85a                	sd	s6,16(sp)
    800016c0:	e45e                	sd	s7,8(sp)
    800016c2:	e062                	sd	s8,0(sp)
    800016c4:	0880                	addi	s0,sp,80
    800016c6:	8b2a                	mv	s6,a0
    800016c8:	8c2e                	mv	s8,a1
    800016ca:	8a32                	mv	s4,a2
    800016cc:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016ce:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016d0:	6a85                	lui	s5,0x1
    800016d2:	a015                	j	800016f6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016d4:	9562                	add	a0,a0,s8
    800016d6:	0004861b          	sext.w	a2,s1
    800016da:	85d2                	mv	a1,s4
    800016dc:	41250533          	sub	a0,a0,s2
    800016e0:	fffff097          	auipc	ra,0xfffff
    800016e4:	666080e7          	jalr	1638(ra) # 80000d46 <memmove>

    len -= n;
    800016e8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ec:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ee:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016f2:	02098263          	beqz	s3,80001716 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016f6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016fa:	85ca                	mv	a1,s2
    800016fc:	855a                	mv	a0,s6
    800016fe:	00000097          	auipc	ra,0x0
    80001702:	a0e080e7          	jalr	-1522(ra) # 8000110c <walkaddr>
    if(pa0 == 0)
    80001706:	cd01                	beqz	a0,8000171e <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001708:	418904b3          	sub	s1,s2,s8
    8000170c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000170e:	fc99f3e3          	bgeu	s3,s1,800016d4 <copyout+0x28>
    80001712:	84ce                	mv	s1,s3
    80001714:	b7c1                	j	800016d4 <copyout+0x28>
  }
  return 0;
    80001716:	4501                	li	a0,0
    80001718:	a021                	j	80001720 <copyout+0x74>
    8000171a:	4501                	li	a0,0
}
    8000171c:	8082                	ret
      return -1;
    8000171e:	557d                	li	a0,-1
}
    80001720:	60a6                	ld	ra,72(sp)
    80001722:	6406                	ld	s0,64(sp)
    80001724:	74e2                	ld	s1,56(sp)
    80001726:	7942                	ld	s2,48(sp)
    80001728:	79a2                	ld	s3,40(sp)
    8000172a:	7a02                	ld	s4,32(sp)
    8000172c:	6ae2                	ld	s5,24(sp)
    8000172e:	6b42                	ld	s6,16(sp)
    80001730:	6ba2                	ld	s7,8(sp)
    80001732:	6c02                	ld	s8,0(sp)
    80001734:	6161                	addi	sp,sp,80
    80001736:	8082                	ret

0000000080001738 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001738:	c6bd                	beqz	a3,800017a6 <copyin+0x6e>
{
    8000173a:	715d                	addi	sp,sp,-80
    8000173c:	e486                	sd	ra,72(sp)
    8000173e:	e0a2                	sd	s0,64(sp)
    80001740:	fc26                	sd	s1,56(sp)
    80001742:	f84a                	sd	s2,48(sp)
    80001744:	f44e                	sd	s3,40(sp)
    80001746:	f052                	sd	s4,32(sp)
    80001748:	ec56                	sd	s5,24(sp)
    8000174a:	e85a                	sd	s6,16(sp)
    8000174c:	e45e                	sd	s7,8(sp)
    8000174e:	e062                	sd	s8,0(sp)
    80001750:	0880                	addi	s0,sp,80
    80001752:	8b2a                	mv	s6,a0
    80001754:	8a2e                	mv	s4,a1
    80001756:	8c32                	mv	s8,a2
    80001758:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000175a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000175c:	6a85                	lui	s5,0x1
    8000175e:	a015                	j	80001782 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001760:	9562                	add	a0,a0,s8
    80001762:	0004861b          	sext.w	a2,s1
    80001766:	412505b3          	sub	a1,a0,s2
    8000176a:	8552                	mv	a0,s4
    8000176c:	fffff097          	auipc	ra,0xfffff
    80001770:	5da080e7          	jalr	1498(ra) # 80000d46 <memmove>

    len -= n;
    80001774:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001778:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000177a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000177e:	02098263          	beqz	s3,800017a2 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001782:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001786:	85ca                	mv	a1,s2
    80001788:	855a                	mv	a0,s6
    8000178a:	00000097          	auipc	ra,0x0
    8000178e:	982080e7          	jalr	-1662(ra) # 8000110c <walkaddr>
    if(pa0 == 0)
    80001792:	cd01                	beqz	a0,800017aa <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001794:	418904b3          	sub	s1,s2,s8
    80001798:	94d6                	add	s1,s1,s5
    if(n > len)
    8000179a:	fc99f3e3          	bgeu	s3,s1,80001760 <copyin+0x28>
    8000179e:	84ce                	mv	s1,s3
    800017a0:	b7c1                	j	80001760 <copyin+0x28>
  }
  return 0;
    800017a2:	4501                	li	a0,0
    800017a4:	a021                	j	800017ac <copyin+0x74>
    800017a6:	4501                	li	a0,0
}
    800017a8:	8082                	ret
      return -1;
    800017aa:	557d                	li	a0,-1
}
    800017ac:	60a6                	ld	ra,72(sp)
    800017ae:	6406                	ld	s0,64(sp)
    800017b0:	74e2                	ld	s1,56(sp)
    800017b2:	7942                	ld	s2,48(sp)
    800017b4:	79a2                	ld	s3,40(sp)
    800017b6:	7a02                	ld	s4,32(sp)
    800017b8:	6ae2                	ld	s5,24(sp)
    800017ba:	6b42                	ld	s6,16(sp)
    800017bc:	6ba2                	ld	s7,8(sp)
    800017be:	6c02                	ld	s8,0(sp)
    800017c0:	6161                	addi	sp,sp,80
    800017c2:	8082                	ret

00000000800017c4 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017c4:	c6c5                	beqz	a3,8000186c <copyinstr+0xa8>
{
    800017c6:	715d                	addi	sp,sp,-80
    800017c8:	e486                	sd	ra,72(sp)
    800017ca:	e0a2                	sd	s0,64(sp)
    800017cc:	fc26                	sd	s1,56(sp)
    800017ce:	f84a                	sd	s2,48(sp)
    800017d0:	f44e                	sd	s3,40(sp)
    800017d2:	f052                	sd	s4,32(sp)
    800017d4:	ec56                	sd	s5,24(sp)
    800017d6:	e85a                	sd	s6,16(sp)
    800017d8:	e45e                	sd	s7,8(sp)
    800017da:	0880                	addi	s0,sp,80
    800017dc:	8a2a                	mv	s4,a0
    800017de:	8b2e                	mv	s6,a1
    800017e0:	8bb2                	mv	s7,a2
    800017e2:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017e4:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017e6:	6985                	lui	s3,0x1
    800017e8:	a035                	j	80001814 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ea:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017ee:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017f0:	0017b793          	seqz	a5,a5
    800017f4:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017f8:	60a6                	ld	ra,72(sp)
    800017fa:	6406                	ld	s0,64(sp)
    800017fc:	74e2                	ld	s1,56(sp)
    800017fe:	7942                	ld	s2,48(sp)
    80001800:	79a2                	ld	s3,40(sp)
    80001802:	7a02                	ld	s4,32(sp)
    80001804:	6ae2                	ld	s5,24(sp)
    80001806:	6b42                	ld	s6,16(sp)
    80001808:	6ba2                	ld	s7,8(sp)
    8000180a:	6161                	addi	sp,sp,80
    8000180c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000180e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001812:	c8a9                	beqz	s1,80001864 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001814:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001818:	85ca                	mv	a1,s2
    8000181a:	8552                	mv	a0,s4
    8000181c:	00000097          	auipc	ra,0x0
    80001820:	8f0080e7          	jalr	-1808(ra) # 8000110c <walkaddr>
    if(pa0 == 0)
    80001824:	c131                	beqz	a0,80001868 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001826:	41790833          	sub	a6,s2,s7
    8000182a:	984e                	add	a6,a6,s3
    if(n > max)
    8000182c:	0104f363          	bgeu	s1,a6,80001832 <copyinstr+0x6e>
    80001830:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001832:	955e                	add	a0,a0,s7
    80001834:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001838:	fc080be3          	beqz	a6,8000180e <copyinstr+0x4a>
    8000183c:	985a                	add	a6,a6,s6
    8000183e:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001840:	41650633          	sub	a2,a0,s6
    80001844:	14fd                	addi	s1,s1,-1
    80001846:	9b26                	add	s6,s6,s1
    80001848:	00f60733          	add	a4,a2,a5
    8000184c:	00074703          	lbu	a4,0(a4)
    80001850:	df49                	beqz	a4,800017ea <copyinstr+0x26>
        *dst = *p;
    80001852:	00e78023          	sb	a4,0(a5)
      --max;
    80001856:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000185a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000185c:	ff0796e3          	bne	a5,a6,80001848 <copyinstr+0x84>
      dst++;
    80001860:	8b42                	mv	s6,a6
    80001862:	b775                	j	8000180e <copyinstr+0x4a>
    80001864:	4781                	li	a5,0
    80001866:	b769                	j	800017f0 <copyinstr+0x2c>
      return -1;
    80001868:	557d                	li	a0,-1
    8000186a:	b779                	j	800017f8 <copyinstr+0x34>
  int got_null = 0;
    8000186c:	4781                	li	a5,0
  if(got_null){
    8000186e:	0017b793          	seqz	a5,a5
    80001872:	40f00533          	neg	a0,a5
}
    80001876:	8082                	ret

0000000080001878 <printhelper>:

void printhelper(pagetable_t p, int depth){
    80001878:	7159                	addi	sp,sp,-112
    8000187a:	f486                	sd	ra,104(sp)
    8000187c:	f0a2                	sd	s0,96(sp)
    8000187e:	eca6                	sd	s1,88(sp)
    80001880:	e8ca                	sd	s2,80(sp)
    80001882:	e4ce                	sd	s3,72(sp)
    80001884:	e0d2                	sd	s4,64(sp)
    80001886:	fc56                	sd	s5,56(sp)
    80001888:	f85a                	sd	s6,48(sp)
    8000188a:	f45e                	sd	s7,40(sp)
    8000188c:	f062                	sd	s8,32(sp)
    8000188e:	ec66                	sd	s9,24(sp)
    80001890:	e86a                	sd	s10,16(sp)
    80001892:	e46e                	sd	s11,8(sp)
    80001894:	1880                	addi	s0,sp,112
    80001896:	8aae                	mv	s5,a1
  for (int i = 0; i < 512; i++){
    80001898:	8a2a                	mv	s4,a0
    8000189a:	4981                	li	s3,0
    pte_t pt = p[i];
    if (pt & PTE_V){
      for (int j = 0; j < depth; j++){
        printf(" ..");
      }
      printf("%d: pte %p pa %p\n", i, pt, PTE2PA(pt));
    8000189c:	00007c97          	auipc	s9,0x7
    800018a0:	8ccc8c93          	addi	s9,s9,-1844 # 80008168 <digits+0x128>
      for (int j = 0; j < depth; j++){
    800018a4:	4d01                	li	s10,0
        printf(" ..");
    800018a6:	00007b17          	auipc	s6,0x7
    800018aa:	8bab0b13          	addi	s6,s6,-1862 # 80008160 <digits+0x120>
    }
    if ((pt & PTE_V) && (pt & (PTE_R | PTE_W | PTE_X)) == 0){
    800018ae:	4c05                	li	s8,1
      printhelper((pagetable_t)PTE2PA(pt), depth + 1);
    800018b0:	00158d9b          	addiw	s11,a1,1
  for (int i = 0; i < 512; i++){
    800018b4:	20000b93          	li	s7,512
    800018b8:	a01d                	j	800018de <printhelper+0x66>
      printf("%d: pte %p pa %p\n", i, pt, PTE2PA(pt));
    800018ba:	00a95693          	srli	a3,s2,0xa
    800018be:	06b2                	slli	a3,a3,0xc
    800018c0:	864a                	mv	a2,s2
    800018c2:	85ce                	mv	a1,s3
    800018c4:	8566                	mv	a0,s9
    800018c6:	fffff097          	auipc	ra,0xfffff
    800018ca:	cc8080e7          	jalr	-824(ra) # 8000058e <printf>
    if ((pt & PTE_V) && (pt & (PTE_R | PTE_W | PTE_X)) == 0){
    800018ce:	00f97793          	andi	a5,s2,15
    800018d2:	03878763          	beq	a5,s8,80001900 <printhelper+0x88>
  for (int i = 0; i < 512; i++){
    800018d6:	2985                	addiw	s3,s3,1
    800018d8:	0a21                	addi	s4,s4,8
    800018da:	03798c63          	beq	s3,s7,80001912 <printhelper+0x9a>
    pte_t pt = p[i];
    800018de:	000a3903          	ld	s2,0(s4) # fffffffffffff000 <end+0xffffffff7ffdd300>
    if (pt & PTE_V){
    800018e2:	00197793          	andi	a5,s2,1
    800018e6:	d7e5                	beqz	a5,800018ce <printhelper+0x56>
      for (int j = 0; j < depth; j++){
    800018e8:	fd5059e3          	blez	s5,800018ba <printhelper+0x42>
    800018ec:	84ea                	mv	s1,s10
        printf(" ..");
    800018ee:	855a                	mv	a0,s6
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	c9e080e7          	jalr	-866(ra) # 8000058e <printf>
      for (int j = 0; j < depth; j++){
    800018f8:	2485                	addiw	s1,s1,1
    800018fa:	fe9a9ae3          	bne	s5,s1,800018ee <printhelper+0x76>
    800018fe:	bf75                	j	800018ba <printhelper+0x42>
      printhelper((pagetable_t)PTE2PA(pt), depth + 1);
    80001900:	00a95513          	srli	a0,s2,0xa
    80001904:	85ee                	mv	a1,s11
    80001906:	0532                	slli	a0,a0,0xc
    80001908:	00000097          	auipc	ra,0x0
    8000190c:	f70080e7          	jalr	-144(ra) # 80001878 <printhelper>
    80001910:	b7d9                	j	800018d6 <printhelper+0x5e>
    }
  }
}
    80001912:	70a6                	ld	ra,104(sp)
    80001914:	7406                	ld	s0,96(sp)
    80001916:	64e6                	ld	s1,88(sp)
    80001918:	6946                	ld	s2,80(sp)
    8000191a:	69a6                	ld	s3,72(sp)
    8000191c:	6a06                	ld	s4,64(sp)
    8000191e:	7ae2                	ld	s5,56(sp)
    80001920:	7b42                	ld	s6,48(sp)
    80001922:	7ba2                	ld	s7,40(sp)
    80001924:	7c02                	ld	s8,32(sp)
    80001926:	6ce2                	ld	s9,24(sp)
    80001928:	6d42                	ld	s10,16(sp)
    8000192a:	6da2                	ld	s11,8(sp)
    8000192c:	6165                	addi	sp,sp,112
    8000192e:	8082                	ret

0000000080001930 <vmprint>:

void vmprint(pagetable_t pagetable)
{
    80001930:	1101                	addi	sp,sp,-32
    80001932:	ec06                	sd	ra,24(sp)
    80001934:	e822                	sd	s0,16(sp)
    80001936:	e426                	sd	s1,8(sp)
    80001938:	1000                	addi	s0,sp,32
    8000193a:	84aa                	mv	s1,a0
  printf("page table %p\n", pagetable);
    8000193c:	85aa                	mv	a1,a0
    8000193e:	00007517          	auipc	a0,0x7
    80001942:	84250513          	addi	a0,a0,-1982 # 80008180 <digits+0x140>
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	c48080e7          	jalr	-952(ra) # 8000058e <printf>
  printhelper(pagetable, 1);
    8000194e:	4585                	li	a1,1
    80001950:	8526                	mv	a0,s1
    80001952:	00000097          	auipc	ra,0x0
    80001956:	f26080e7          	jalr	-218(ra) # 80001878 <printhelper>
}
    8000195a:	60e2                	ld	ra,24(sp)
    8000195c:	6442                	ld	s0,16(sp)
    8000195e:	64a2                	ld	s1,8(sp)
    80001960:	6105                	addi	sp,sp,32
    80001962:	8082                	ret

0000000080001964 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001964:	7139                	addi	sp,sp,-64
    80001966:	fc06                	sd	ra,56(sp)
    80001968:	f822                	sd	s0,48(sp)
    8000196a:	f426                	sd	s1,40(sp)
    8000196c:	f04a                	sd	s2,32(sp)
    8000196e:	ec4e                	sd	s3,24(sp)
    80001970:	e852                	sd	s4,16(sp)
    80001972:	e456                	sd	s5,8(sp)
    80001974:	e05a                	sd	s6,0(sp)
    80001976:	0080                	addi	s0,sp,64
    80001978:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197a:	0000f497          	auipc	s1,0xf
    8000197e:	5a648493          	addi	s1,s1,1446 # 80010f20 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001982:	8b26                	mv	s6,s1
    80001984:	00006a97          	auipc	s5,0x6
    80001988:	67ca8a93          	addi	s5,s5,1660 # 80008000 <etext>
    8000198c:	04000937          	lui	s2,0x4000
    80001990:	197d                	addi	s2,s2,-1
    80001992:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001994:	00015a17          	auipc	s4,0x15
    80001998:	f8ca0a13          	addi	s4,s4,-116 # 80016920 <tickslock>
    char *pa = kalloc();
    8000199c:	fffff097          	auipc	ra,0xfffff
    800019a0:	15e080e7          	jalr	350(ra) # 80000afa <kalloc>
    800019a4:	862a                	mv	a2,a0
    if(pa == 0)
    800019a6:	c131                	beqz	a0,800019ea <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800019a8:	416485b3          	sub	a1,s1,s6
    800019ac:	858d                	srai	a1,a1,0x3
    800019ae:	000ab783          	ld	a5,0(s5)
    800019b2:	02f585b3          	mul	a1,a1,a5
    800019b6:	2585                	addiw	a1,a1,1
    800019b8:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019bc:	4719                	li	a4,6
    800019be:	6685                	lui	a3,0x1
    800019c0:	40b905b3          	sub	a1,s2,a1
    800019c4:	854e                	mv	a0,s3
    800019c6:	fffff097          	auipc	ra,0xfffff
    800019ca:	7f6080e7          	jalr	2038(ra) # 800011bc <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ce:	16848493          	addi	s1,s1,360
    800019d2:	fd4495e3          	bne	s1,s4,8000199c <proc_mapstacks+0x38>
  }
}
    800019d6:	70e2                	ld	ra,56(sp)
    800019d8:	7442                	ld	s0,48(sp)
    800019da:	74a2                	ld	s1,40(sp)
    800019dc:	7902                	ld	s2,32(sp)
    800019de:	69e2                	ld	s3,24(sp)
    800019e0:	6a42                	ld	s4,16(sp)
    800019e2:	6aa2                	ld	s5,8(sp)
    800019e4:	6b02                	ld	s6,0(sp)
    800019e6:	6121                	addi	sp,sp,64
    800019e8:	8082                	ret
      panic("kalloc");
    800019ea:	00006517          	auipc	a0,0x6
    800019ee:	7a650513          	addi	a0,a0,1958 # 80008190 <digits+0x150>
    800019f2:	fffff097          	auipc	ra,0xfffff
    800019f6:	b52080e7          	jalr	-1198(ra) # 80000544 <panic>

00000000800019fa <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800019fa:	7139                	addi	sp,sp,-64
    800019fc:	fc06                	sd	ra,56(sp)
    800019fe:	f822                	sd	s0,48(sp)
    80001a00:	f426                	sd	s1,40(sp)
    80001a02:	f04a                	sd	s2,32(sp)
    80001a04:	ec4e                	sd	s3,24(sp)
    80001a06:	e852                	sd	s4,16(sp)
    80001a08:	e456                	sd	s5,8(sp)
    80001a0a:	e05a                	sd	s6,0(sp)
    80001a0c:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001a0e:	00006597          	auipc	a1,0x6
    80001a12:	78a58593          	addi	a1,a1,1930 # 80008198 <digits+0x158>
    80001a16:	0000f517          	auipc	a0,0xf
    80001a1a:	0da50513          	addi	a0,a0,218 # 80010af0 <pid_lock>
    80001a1e:	fffff097          	auipc	ra,0xfffff
    80001a22:	13c080e7          	jalr	316(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a26:	00006597          	auipc	a1,0x6
    80001a2a:	77a58593          	addi	a1,a1,1914 # 800081a0 <digits+0x160>
    80001a2e:	0000f517          	auipc	a0,0xf
    80001a32:	0da50513          	addi	a0,a0,218 # 80010b08 <wait_lock>
    80001a36:	fffff097          	auipc	ra,0xfffff
    80001a3a:	124080e7          	jalr	292(ra) # 80000b5a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a3e:	0000f497          	auipc	s1,0xf
    80001a42:	4e248493          	addi	s1,s1,1250 # 80010f20 <proc>
      initlock(&p->lock, "proc");
    80001a46:	00006b17          	auipc	s6,0x6
    80001a4a:	76ab0b13          	addi	s6,s6,1898 # 800081b0 <digits+0x170>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001a4e:	8aa6                	mv	s5,s1
    80001a50:	00006a17          	auipc	s4,0x6
    80001a54:	5b0a0a13          	addi	s4,s4,1456 # 80008000 <etext>
    80001a58:	04000937          	lui	s2,0x4000
    80001a5c:	197d                	addi	s2,s2,-1
    80001a5e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a60:	00015997          	auipc	s3,0x15
    80001a64:	ec098993          	addi	s3,s3,-320 # 80016920 <tickslock>
      initlock(&p->lock, "proc");
    80001a68:	85da                	mv	a1,s6
    80001a6a:	8526                	mv	a0,s1
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	0ee080e7          	jalr	238(ra) # 80000b5a <initlock>
      p->state = UNUSED;
    80001a74:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001a78:	415487b3          	sub	a5,s1,s5
    80001a7c:	878d                	srai	a5,a5,0x3
    80001a7e:	000a3703          	ld	a4,0(s4)
    80001a82:	02e787b3          	mul	a5,a5,a4
    80001a86:	2785                	addiw	a5,a5,1
    80001a88:	00d7979b          	slliw	a5,a5,0xd
    80001a8c:	40f907b3          	sub	a5,s2,a5
    80001a90:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a92:	16848493          	addi	s1,s1,360
    80001a96:	fd3499e3          	bne	s1,s3,80001a68 <procinit+0x6e>
  }
}
    80001a9a:	70e2                	ld	ra,56(sp)
    80001a9c:	7442                	ld	s0,48(sp)
    80001a9e:	74a2                	ld	s1,40(sp)
    80001aa0:	7902                	ld	s2,32(sp)
    80001aa2:	69e2                	ld	s3,24(sp)
    80001aa4:	6a42                	ld	s4,16(sp)
    80001aa6:	6aa2                	ld	s5,8(sp)
    80001aa8:	6b02                	ld	s6,0(sp)
    80001aaa:	6121                	addi	sp,sp,64
    80001aac:	8082                	ret

0000000080001aae <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001aae:	1141                	addi	sp,sp,-16
    80001ab0:	e422                	sd	s0,8(sp)
    80001ab2:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ab4:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001ab6:	2501                	sext.w	a0,a0
    80001ab8:	6422                	ld	s0,8(sp)
    80001aba:	0141                	addi	sp,sp,16
    80001abc:	8082                	ret

0000000080001abe <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001abe:	1141                	addi	sp,sp,-16
    80001ac0:	e422                	sd	s0,8(sp)
    80001ac2:	0800                	addi	s0,sp,16
    80001ac4:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001ac6:	2781                	sext.w	a5,a5
    80001ac8:	079e                	slli	a5,a5,0x7
  return c;
}
    80001aca:	0000f517          	auipc	a0,0xf
    80001ace:	05650513          	addi	a0,a0,86 # 80010b20 <cpus>
    80001ad2:	953e                	add	a0,a0,a5
    80001ad4:	6422                	ld	s0,8(sp)
    80001ad6:	0141                	addi	sp,sp,16
    80001ad8:	8082                	ret

0000000080001ada <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001ada:	1101                	addi	sp,sp,-32
    80001adc:	ec06                	sd	ra,24(sp)
    80001ade:	e822                	sd	s0,16(sp)
    80001ae0:	e426                	sd	s1,8(sp)
    80001ae2:	1000                	addi	s0,sp,32
  push_off();
    80001ae4:	fffff097          	auipc	ra,0xfffff
    80001ae8:	0ba080e7          	jalr	186(ra) # 80000b9e <push_off>
    80001aec:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001aee:	2781                	sext.w	a5,a5
    80001af0:	079e                	slli	a5,a5,0x7
    80001af2:	0000f717          	auipc	a4,0xf
    80001af6:	ffe70713          	addi	a4,a4,-2 # 80010af0 <pid_lock>
    80001afa:	97ba                	add	a5,a5,a4
    80001afc:	7b84                	ld	s1,48(a5)
  pop_off();
    80001afe:	fffff097          	auipc	ra,0xfffff
    80001b02:	140080e7          	jalr	320(ra) # 80000c3e <pop_off>
  return p;
}
    80001b06:	8526                	mv	a0,s1
    80001b08:	60e2                	ld	ra,24(sp)
    80001b0a:	6442                	ld	s0,16(sp)
    80001b0c:	64a2                	ld	s1,8(sp)
    80001b0e:	6105                	addi	sp,sp,32
    80001b10:	8082                	ret

0000000080001b12 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001b12:	1141                	addi	sp,sp,-16
    80001b14:	e406                	sd	ra,8(sp)
    80001b16:	e022                	sd	s0,0(sp)
    80001b18:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b1a:	00000097          	auipc	ra,0x0
    80001b1e:	fc0080e7          	jalr	-64(ra) # 80001ada <myproc>
    80001b22:	fffff097          	auipc	ra,0xfffff
    80001b26:	17c080e7          	jalr	380(ra) # 80000c9e <release>

  if (first) {
    80001b2a:	00007797          	auipc	a5,0x7
    80001b2e:	cd67a783          	lw	a5,-810(a5) # 80008800 <first.1680>
    80001b32:	eb89                	bnez	a5,80001b44 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b34:	00001097          	auipc	ra,0x1
    80001b38:	c56080e7          	jalr	-938(ra) # 8000278a <usertrapret>
}
    80001b3c:	60a2                	ld	ra,8(sp)
    80001b3e:	6402                	ld	s0,0(sp)
    80001b40:	0141                	addi	sp,sp,16
    80001b42:	8082                	ret
    first = 0;
    80001b44:	00007797          	auipc	a5,0x7
    80001b48:	ca07ae23          	sw	zero,-836(a5) # 80008800 <first.1680>
    fsinit(ROOTDEV);
    80001b4c:	4505                	li	a0,1
    80001b4e:	00002097          	auipc	ra,0x2
    80001b52:	a1a080e7          	jalr	-1510(ra) # 80003568 <fsinit>
    80001b56:	bff9                	j	80001b34 <forkret+0x22>

0000000080001b58 <allocpid>:
{
    80001b58:	1101                	addi	sp,sp,-32
    80001b5a:	ec06                	sd	ra,24(sp)
    80001b5c:	e822                	sd	s0,16(sp)
    80001b5e:	e426                	sd	s1,8(sp)
    80001b60:	e04a                	sd	s2,0(sp)
    80001b62:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b64:	0000f917          	auipc	s2,0xf
    80001b68:	f8c90913          	addi	s2,s2,-116 # 80010af0 <pid_lock>
    80001b6c:	854a                	mv	a0,s2
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	07c080e7          	jalr	124(ra) # 80000bea <acquire>
  pid = nextpid;
    80001b76:	00007797          	auipc	a5,0x7
    80001b7a:	c8e78793          	addi	a5,a5,-882 # 80008804 <nextpid>
    80001b7e:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b80:	0014871b          	addiw	a4,s1,1
    80001b84:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b86:	854a                	mv	a0,s2
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	116080e7          	jalr	278(ra) # 80000c9e <release>
}
    80001b90:	8526                	mv	a0,s1
    80001b92:	60e2                	ld	ra,24(sp)
    80001b94:	6442                	ld	s0,16(sp)
    80001b96:	64a2                	ld	s1,8(sp)
    80001b98:	6902                	ld	s2,0(sp)
    80001b9a:	6105                	addi	sp,sp,32
    80001b9c:	8082                	ret

0000000080001b9e <proc_pagetable>:
{
    80001b9e:	1101                	addi	sp,sp,-32
    80001ba0:	ec06                	sd	ra,24(sp)
    80001ba2:	e822                	sd	s0,16(sp)
    80001ba4:	e426                	sd	s1,8(sp)
    80001ba6:	e04a                	sd	s2,0(sp)
    80001ba8:	1000                	addi	s0,sp,32
    80001baa:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bac:	fffff097          	auipc	ra,0xfffff
    80001bb0:	7dc080e7          	jalr	2012(ra) # 80001388 <uvmcreate>
    80001bb4:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001bb6:	c121                	beqz	a0,80001bf6 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bb8:	4729                	li	a4,10
    80001bba:	00005697          	auipc	a3,0x5
    80001bbe:	44668693          	addi	a3,a3,1094 # 80007000 <_trampoline>
    80001bc2:	6605                	lui	a2,0x1
    80001bc4:	040005b7          	lui	a1,0x4000
    80001bc8:	15fd                	addi	a1,a1,-1
    80001bca:	05b2                	slli	a1,a1,0xc
    80001bcc:	fffff097          	auipc	ra,0xfffff
    80001bd0:	4ac080e7          	jalr	1196(ra) # 80001078 <mappages>
    80001bd4:	02054863          	bltz	a0,80001c04 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bd8:	4719                	li	a4,6
    80001bda:	05893683          	ld	a3,88(s2)
    80001bde:	6605                	lui	a2,0x1
    80001be0:	020005b7          	lui	a1,0x2000
    80001be4:	15fd                	addi	a1,a1,-1
    80001be6:	05b6                	slli	a1,a1,0xd
    80001be8:	8526                	mv	a0,s1
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	48e080e7          	jalr	1166(ra) # 80001078 <mappages>
    80001bf2:	02054163          	bltz	a0,80001c14 <proc_pagetable+0x76>
}
    80001bf6:	8526                	mv	a0,s1
    80001bf8:	60e2                	ld	ra,24(sp)
    80001bfa:	6442                	ld	s0,16(sp)
    80001bfc:	64a2                	ld	s1,8(sp)
    80001bfe:	6902                	ld	s2,0(sp)
    80001c00:	6105                	addi	sp,sp,32
    80001c02:	8082                	ret
    uvmfree(pagetable, 0);
    80001c04:	4581                	li	a1,0
    80001c06:	8526                	mv	a0,s1
    80001c08:	00000097          	auipc	ra,0x0
    80001c0c:	984080e7          	jalr	-1660(ra) # 8000158c <uvmfree>
    return 0;
    80001c10:	4481                	li	s1,0
    80001c12:	b7d5                	j	80001bf6 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c14:	4681                	li	a3,0
    80001c16:	4605                	li	a2,1
    80001c18:	040005b7          	lui	a1,0x4000
    80001c1c:	15fd                	addi	a1,a1,-1
    80001c1e:	05b2                	slli	a1,a1,0xc
    80001c20:	8526                	mv	a0,s1
    80001c22:	fffff097          	auipc	ra,0xfffff
    80001c26:	6c0080e7          	jalr	1728(ra) # 800012e2 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c2a:	4581                	li	a1,0
    80001c2c:	8526                	mv	a0,s1
    80001c2e:	00000097          	auipc	ra,0x0
    80001c32:	95e080e7          	jalr	-1698(ra) # 8000158c <uvmfree>
    return 0;
    80001c36:	4481                	li	s1,0
    80001c38:	bf7d                	j	80001bf6 <proc_pagetable+0x58>

0000000080001c3a <proc_freepagetable>:
{
    80001c3a:	1101                	addi	sp,sp,-32
    80001c3c:	ec06                	sd	ra,24(sp)
    80001c3e:	e822                	sd	s0,16(sp)
    80001c40:	e426                	sd	s1,8(sp)
    80001c42:	e04a                	sd	s2,0(sp)
    80001c44:	1000                	addi	s0,sp,32
    80001c46:	84aa                	mv	s1,a0
    80001c48:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c4a:	4681                	li	a3,0
    80001c4c:	4605                	li	a2,1
    80001c4e:	040005b7          	lui	a1,0x4000
    80001c52:	15fd                	addi	a1,a1,-1
    80001c54:	05b2                	slli	a1,a1,0xc
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	68c080e7          	jalr	1676(ra) # 800012e2 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c5e:	4681                	li	a3,0
    80001c60:	4605                	li	a2,1
    80001c62:	020005b7          	lui	a1,0x2000
    80001c66:	15fd                	addi	a1,a1,-1
    80001c68:	05b6                	slli	a1,a1,0xd
    80001c6a:	8526                	mv	a0,s1
    80001c6c:	fffff097          	auipc	ra,0xfffff
    80001c70:	676080e7          	jalr	1654(ra) # 800012e2 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c74:	85ca                	mv	a1,s2
    80001c76:	8526                	mv	a0,s1
    80001c78:	00000097          	auipc	ra,0x0
    80001c7c:	914080e7          	jalr	-1772(ra) # 8000158c <uvmfree>
}
    80001c80:	60e2                	ld	ra,24(sp)
    80001c82:	6442                	ld	s0,16(sp)
    80001c84:	64a2                	ld	s1,8(sp)
    80001c86:	6902                	ld	s2,0(sp)
    80001c88:	6105                	addi	sp,sp,32
    80001c8a:	8082                	ret

0000000080001c8c <freeproc>:
{
    80001c8c:	1101                	addi	sp,sp,-32
    80001c8e:	ec06                	sd	ra,24(sp)
    80001c90:	e822                	sd	s0,16(sp)
    80001c92:	e426                	sd	s1,8(sp)
    80001c94:	1000                	addi	s0,sp,32
    80001c96:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c98:	6d28                	ld	a0,88(a0)
    80001c9a:	c509                	beqz	a0,80001ca4 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c9c:	fffff097          	auipc	ra,0xfffff
    80001ca0:	d62080e7          	jalr	-670(ra) # 800009fe <kfree>
  p->trapframe = 0;
    80001ca4:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001ca8:	68a8                	ld	a0,80(s1)
    80001caa:	c511                	beqz	a0,80001cb6 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001cac:	64ac                	ld	a1,72(s1)
    80001cae:	00000097          	auipc	ra,0x0
    80001cb2:	f8c080e7          	jalr	-116(ra) # 80001c3a <proc_freepagetable>
  p->pagetable = 0;
    80001cb6:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cba:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cbe:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001cc2:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001cc6:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cca:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001cce:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001cd2:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001cd6:	0004ac23          	sw	zero,24(s1)
}
    80001cda:	60e2                	ld	ra,24(sp)
    80001cdc:	6442                	ld	s0,16(sp)
    80001cde:	64a2                	ld	s1,8(sp)
    80001ce0:	6105                	addi	sp,sp,32
    80001ce2:	8082                	ret

0000000080001ce4 <allocproc>:
{
    80001ce4:	1101                	addi	sp,sp,-32
    80001ce6:	ec06                	sd	ra,24(sp)
    80001ce8:	e822                	sd	s0,16(sp)
    80001cea:	e426                	sd	s1,8(sp)
    80001cec:	e04a                	sd	s2,0(sp)
    80001cee:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cf0:	0000f497          	auipc	s1,0xf
    80001cf4:	23048493          	addi	s1,s1,560 # 80010f20 <proc>
    80001cf8:	00015917          	auipc	s2,0x15
    80001cfc:	c2890913          	addi	s2,s2,-984 # 80016920 <tickslock>
    acquire(&p->lock);
    80001d00:	8526                	mv	a0,s1
    80001d02:	fffff097          	auipc	ra,0xfffff
    80001d06:	ee8080e7          	jalr	-280(ra) # 80000bea <acquire>
    if(p->state == UNUSED) {
    80001d0a:	4c9c                	lw	a5,24(s1)
    80001d0c:	cf81                	beqz	a5,80001d24 <allocproc+0x40>
      release(&p->lock);
    80001d0e:	8526                	mv	a0,s1
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	f8e080e7          	jalr	-114(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d18:	16848493          	addi	s1,s1,360
    80001d1c:	ff2492e3          	bne	s1,s2,80001d00 <allocproc+0x1c>
  return 0;
    80001d20:	4481                	li	s1,0
    80001d22:	a889                	j	80001d74 <allocproc+0x90>
  p->pid = allocpid();
    80001d24:	00000097          	auipc	ra,0x0
    80001d28:	e34080e7          	jalr	-460(ra) # 80001b58 <allocpid>
    80001d2c:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d2e:	4785                	li	a5,1
    80001d30:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d32:	fffff097          	auipc	ra,0xfffff
    80001d36:	dc8080e7          	jalr	-568(ra) # 80000afa <kalloc>
    80001d3a:	892a                	mv	s2,a0
    80001d3c:	eca8                	sd	a0,88(s1)
    80001d3e:	c131                	beqz	a0,80001d82 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001d40:	8526                	mv	a0,s1
    80001d42:	00000097          	auipc	ra,0x0
    80001d46:	e5c080e7          	jalr	-420(ra) # 80001b9e <proc_pagetable>
    80001d4a:	892a                	mv	s2,a0
    80001d4c:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d4e:	c531                	beqz	a0,80001d9a <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001d50:	07000613          	li	a2,112
    80001d54:	4581                	li	a1,0
    80001d56:	06048513          	addi	a0,s1,96
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	f8c080e7          	jalr	-116(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001d62:	00000797          	auipc	a5,0x0
    80001d66:	db078793          	addi	a5,a5,-592 # 80001b12 <forkret>
    80001d6a:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d6c:	60bc                	ld	a5,64(s1)
    80001d6e:	6705                	lui	a4,0x1
    80001d70:	97ba                	add	a5,a5,a4
    80001d72:	f4bc                	sd	a5,104(s1)
}
    80001d74:	8526                	mv	a0,s1
    80001d76:	60e2                	ld	ra,24(sp)
    80001d78:	6442                	ld	s0,16(sp)
    80001d7a:	64a2                	ld	s1,8(sp)
    80001d7c:	6902                	ld	s2,0(sp)
    80001d7e:	6105                	addi	sp,sp,32
    80001d80:	8082                	ret
    freeproc(p);
    80001d82:	8526                	mv	a0,s1
    80001d84:	00000097          	auipc	ra,0x0
    80001d88:	f08080e7          	jalr	-248(ra) # 80001c8c <freeproc>
    release(&p->lock);
    80001d8c:	8526                	mv	a0,s1
    80001d8e:	fffff097          	auipc	ra,0xfffff
    80001d92:	f10080e7          	jalr	-240(ra) # 80000c9e <release>
    return 0;
    80001d96:	84ca                	mv	s1,s2
    80001d98:	bff1                	j	80001d74 <allocproc+0x90>
    freeproc(p);
    80001d9a:	8526                	mv	a0,s1
    80001d9c:	00000097          	auipc	ra,0x0
    80001da0:	ef0080e7          	jalr	-272(ra) # 80001c8c <freeproc>
    release(&p->lock);
    80001da4:	8526                	mv	a0,s1
    80001da6:	fffff097          	auipc	ra,0xfffff
    80001daa:	ef8080e7          	jalr	-264(ra) # 80000c9e <release>
    return 0;
    80001dae:	84ca                	mv	s1,s2
    80001db0:	b7d1                	j	80001d74 <allocproc+0x90>

0000000080001db2 <userinit>:
{
    80001db2:	1101                	addi	sp,sp,-32
    80001db4:	ec06                	sd	ra,24(sp)
    80001db6:	e822                	sd	s0,16(sp)
    80001db8:	e426                	sd	s1,8(sp)
    80001dba:	1000                	addi	s0,sp,32
  p = allocproc();
    80001dbc:	00000097          	auipc	ra,0x0
    80001dc0:	f28080e7          	jalr	-216(ra) # 80001ce4 <allocproc>
    80001dc4:	84aa                	mv	s1,a0
  initproc = p;
    80001dc6:	00007797          	auipc	a5,0x7
    80001dca:	aaa7b923          	sd	a0,-1358(a5) # 80008878 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001dce:	03400613          	li	a2,52
    80001dd2:	00007597          	auipc	a1,0x7
    80001dd6:	a3e58593          	addi	a1,a1,-1474 # 80008810 <initcode>
    80001dda:	6928                	ld	a0,80(a0)
    80001ddc:	fffff097          	auipc	ra,0xfffff
    80001de0:	5da080e7          	jalr	1498(ra) # 800013b6 <uvmfirst>
  p->sz = PGSIZE;
    80001de4:	6785                	lui	a5,0x1
    80001de6:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001de8:	6cb8                	ld	a4,88(s1)
    80001dea:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001dee:	6cb8                	ld	a4,88(s1)
    80001df0:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001df2:	4641                	li	a2,16
    80001df4:	00006597          	auipc	a1,0x6
    80001df8:	3c458593          	addi	a1,a1,964 # 800081b8 <digits+0x178>
    80001dfc:	15848513          	addi	a0,s1,344
    80001e00:	fffff097          	auipc	ra,0xfffff
    80001e04:	038080e7          	jalr	56(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001e08:	00006517          	auipc	a0,0x6
    80001e0c:	3c050513          	addi	a0,a0,960 # 800081c8 <digits+0x188>
    80001e10:	00002097          	auipc	ra,0x2
    80001e14:	17a080e7          	jalr	378(ra) # 80003f8a <namei>
    80001e18:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e1c:	478d                	li	a5,3
    80001e1e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e20:	8526                	mv	a0,s1
    80001e22:	fffff097          	auipc	ra,0xfffff
    80001e26:	e7c080e7          	jalr	-388(ra) # 80000c9e <release>
}
    80001e2a:	60e2                	ld	ra,24(sp)
    80001e2c:	6442                	ld	s0,16(sp)
    80001e2e:	64a2                	ld	s1,8(sp)
    80001e30:	6105                	addi	sp,sp,32
    80001e32:	8082                	ret

0000000080001e34 <growproc>:
{
    80001e34:	1101                	addi	sp,sp,-32
    80001e36:	ec06                	sd	ra,24(sp)
    80001e38:	e822                	sd	s0,16(sp)
    80001e3a:	e426                	sd	s1,8(sp)
    80001e3c:	e04a                	sd	s2,0(sp)
    80001e3e:	1000                	addi	s0,sp,32
    80001e40:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001e42:	00000097          	auipc	ra,0x0
    80001e46:	c98080e7          	jalr	-872(ra) # 80001ada <myproc>
    80001e4a:	84aa                	mv	s1,a0
  sz = p->sz;
    80001e4c:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001e4e:	01204c63          	bgtz	s2,80001e66 <growproc+0x32>
  } else if(n < 0){
    80001e52:	02094663          	bltz	s2,80001e7e <growproc+0x4a>
  p->sz = sz;
    80001e56:	e4ac                	sd	a1,72(s1)
  return 0;
    80001e58:	4501                	li	a0,0
}
    80001e5a:	60e2                	ld	ra,24(sp)
    80001e5c:	6442                	ld	s0,16(sp)
    80001e5e:	64a2                	ld	s1,8(sp)
    80001e60:	6902                	ld	s2,0(sp)
    80001e62:	6105                	addi	sp,sp,32
    80001e64:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001e66:	4691                	li	a3,4
    80001e68:	00b90633          	add	a2,s2,a1
    80001e6c:	6928                	ld	a0,80(a0)
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	602080e7          	jalr	1538(ra) # 80001470 <uvmalloc>
    80001e76:	85aa                	mv	a1,a0
    80001e78:	fd79                	bnez	a0,80001e56 <growproc+0x22>
      return -1;
    80001e7a:	557d                	li	a0,-1
    80001e7c:	bff9                	j	80001e5a <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e7e:	00b90633          	add	a2,s2,a1
    80001e82:	6928                	ld	a0,80(a0)
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	5a4080e7          	jalr	1444(ra) # 80001428 <uvmdealloc>
    80001e8c:	85aa                	mv	a1,a0
    80001e8e:	b7e1                	j	80001e56 <growproc+0x22>

0000000080001e90 <fork>:
{
    80001e90:	7179                	addi	sp,sp,-48
    80001e92:	f406                	sd	ra,40(sp)
    80001e94:	f022                	sd	s0,32(sp)
    80001e96:	ec26                	sd	s1,24(sp)
    80001e98:	e84a                	sd	s2,16(sp)
    80001e9a:	e44e                	sd	s3,8(sp)
    80001e9c:	e052                	sd	s4,0(sp)
    80001e9e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ea0:	00000097          	auipc	ra,0x0
    80001ea4:	c3a080e7          	jalr	-966(ra) # 80001ada <myproc>
    80001ea8:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001eaa:	00000097          	auipc	ra,0x0
    80001eae:	e3a080e7          	jalr	-454(ra) # 80001ce4 <allocproc>
    80001eb2:	10050b63          	beqz	a0,80001fc8 <fork+0x138>
    80001eb6:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001eb8:	04893603          	ld	a2,72(s2)
    80001ebc:	692c                	ld	a1,80(a0)
    80001ebe:	05093503          	ld	a0,80(s2)
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	702080e7          	jalr	1794(ra) # 800015c4 <uvmcopy>
    80001eca:	04054663          	bltz	a0,80001f16 <fork+0x86>
  np->sz = p->sz;
    80001ece:	04893783          	ld	a5,72(s2)
    80001ed2:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001ed6:	05893683          	ld	a3,88(s2)
    80001eda:	87b6                	mv	a5,a3
    80001edc:	0589b703          	ld	a4,88(s3)
    80001ee0:	12068693          	addi	a3,a3,288
    80001ee4:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ee8:	6788                	ld	a0,8(a5)
    80001eea:	6b8c                	ld	a1,16(a5)
    80001eec:	6f90                	ld	a2,24(a5)
    80001eee:	01073023          	sd	a6,0(a4)
    80001ef2:	e708                	sd	a0,8(a4)
    80001ef4:	eb0c                	sd	a1,16(a4)
    80001ef6:	ef10                	sd	a2,24(a4)
    80001ef8:	02078793          	addi	a5,a5,32
    80001efc:	02070713          	addi	a4,a4,32
    80001f00:	fed792e3          	bne	a5,a3,80001ee4 <fork+0x54>
  np->trapframe->a0 = 0;
    80001f04:	0589b783          	ld	a5,88(s3)
    80001f08:	0607b823          	sd	zero,112(a5)
    80001f0c:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001f10:	15000a13          	li	s4,336
    80001f14:	a03d                	j	80001f42 <fork+0xb2>
    freeproc(np);
    80001f16:	854e                	mv	a0,s3
    80001f18:	00000097          	auipc	ra,0x0
    80001f1c:	d74080e7          	jalr	-652(ra) # 80001c8c <freeproc>
    release(&np->lock);
    80001f20:	854e                	mv	a0,s3
    80001f22:	fffff097          	auipc	ra,0xfffff
    80001f26:	d7c080e7          	jalr	-644(ra) # 80000c9e <release>
    return -1;
    80001f2a:	5a7d                	li	s4,-1
    80001f2c:	a069                	j	80001fb6 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f2e:	00002097          	auipc	ra,0x2
    80001f32:	6f2080e7          	jalr	1778(ra) # 80004620 <filedup>
    80001f36:	009987b3          	add	a5,s3,s1
    80001f3a:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f3c:	04a1                	addi	s1,s1,8
    80001f3e:	01448763          	beq	s1,s4,80001f4c <fork+0xbc>
    if(p->ofile[i])
    80001f42:	009907b3          	add	a5,s2,s1
    80001f46:	6388                	ld	a0,0(a5)
    80001f48:	f17d                	bnez	a0,80001f2e <fork+0x9e>
    80001f4a:	bfcd                	j	80001f3c <fork+0xac>
  np->cwd = idup(p->cwd);
    80001f4c:	15093503          	ld	a0,336(s2)
    80001f50:	00002097          	auipc	ra,0x2
    80001f54:	856080e7          	jalr	-1962(ra) # 800037a6 <idup>
    80001f58:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f5c:	4641                	li	a2,16
    80001f5e:	15890593          	addi	a1,s2,344
    80001f62:	15898513          	addi	a0,s3,344
    80001f66:	fffff097          	auipc	ra,0xfffff
    80001f6a:	ed2080e7          	jalr	-302(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    80001f6e:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001f72:	854e                	mv	a0,s3
    80001f74:	fffff097          	auipc	ra,0xfffff
    80001f78:	d2a080e7          	jalr	-726(ra) # 80000c9e <release>
  acquire(&wait_lock);
    80001f7c:	0000f497          	auipc	s1,0xf
    80001f80:	b8c48493          	addi	s1,s1,-1140 # 80010b08 <wait_lock>
    80001f84:	8526                	mv	a0,s1
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	c64080e7          	jalr	-924(ra) # 80000bea <acquire>
  np->parent = p;
    80001f8e:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001f92:	8526                	mv	a0,s1
    80001f94:	fffff097          	auipc	ra,0xfffff
    80001f98:	d0a080e7          	jalr	-758(ra) # 80000c9e <release>
  acquire(&np->lock);
    80001f9c:	854e                	mv	a0,s3
    80001f9e:	fffff097          	auipc	ra,0xfffff
    80001fa2:	c4c080e7          	jalr	-948(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    80001fa6:	478d                	li	a5,3
    80001fa8:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001fac:	854e                	mv	a0,s3
    80001fae:	fffff097          	auipc	ra,0xfffff
    80001fb2:	cf0080e7          	jalr	-784(ra) # 80000c9e <release>
}
    80001fb6:	8552                	mv	a0,s4
    80001fb8:	70a2                	ld	ra,40(sp)
    80001fba:	7402                	ld	s0,32(sp)
    80001fbc:	64e2                	ld	s1,24(sp)
    80001fbe:	6942                	ld	s2,16(sp)
    80001fc0:	69a2                	ld	s3,8(sp)
    80001fc2:	6a02                	ld	s4,0(sp)
    80001fc4:	6145                	addi	sp,sp,48
    80001fc6:	8082                	ret
    return -1;
    80001fc8:	5a7d                	li	s4,-1
    80001fca:	b7f5                	j	80001fb6 <fork+0x126>

0000000080001fcc <scheduler>:
{
    80001fcc:	7139                	addi	sp,sp,-64
    80001fce:	fc06                	sd	ra,56(sp)
    80001fd0:	f822                	sd	s0,48(sp)
    80001fd2:	f426                	sd	s1,40(sp)
    80001fd4:	f04a                	sd	s2,32(sp)
    80001fd6:	ec4e                	sd	s3,24(sp)
    80001fd8:	e852                	sd	s4,16(sp)
    80001fda:	e456                	sd	s5,8(sp)
    80001fdc:	e05a                	sd	s6,0(sp)
    80001fde:	0080                	addi	s0,sp,64
    80001fe0:	8792                	mv	a5,tp
  int id = r_tp();
    80001fe2:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fe4:	00779a93          	slli	s5,a5,0x7
    80001fe8:	0000f717          	auipc	a4,0xf
    80001fec:	b0870713          	addi	a4,a4,-1272 # 80010af0 <pid_lock>
    80001ff0:	9756                	add	a4,a4,s5
    80001ff2:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ff6:	0000f717          	auipc	a4,0xf
    80001ffa:	b3270713          	addi	a4,a4,-1230 # 80010b28 <cpus+0x8>
    80001ffe:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80002000:	498d                	li	s3,3
        p->state = RUNNING;
    80002002:	4b11                	li	s6,4
        c->proc = p;
    80002004:	079e                	slli	a5,a5,0x7
    80002006:	0000fa17          	auipc	s4,0xf
    8000200a:	aeaa0a13          	addi	s4,s4,-1302 # 80010af0 <pid_lock>
    8000200e:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002010:	00015917          	auipc	s2,0x15
    80002014:	91090913          	addi	s2,s2,-1776 # 80016920 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002018:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000201c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002020:	10079073          	csrw	sstatus,a5
    80002024:	0000f497          	auipc	s1,0xf
    80002028:	efc48493          	addi	s1,s1,-260 # 80010f20 <proc>
    8000202c:	a03d                	j	8000205a <scheduler+0x8e>
        p->state = RUNNING;
    8000202e:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002032:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002036:	06048593          	addi	a1,s1,96
    8000203a:	8556                	mv	a0,s5
    8000203c:	00000097          	auipc	ra,0x0
    80002040:	6a4080e7          	jalr	1700(ra) # 800026e0 <swtch>
        c->proc = 0;
    80002044:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80002048:	8526                	mv	a0,s1
    8000204a:	fffff097          	auipc	ra,0xfffff
    8000204e:	c54080e7          	jalr	-940(ra) # 80000c9e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002052:	16848493          	addi	s1,s1,360
    80002056:	fd2481e3          	beq	s1,s2,80002018 <scheduler+0x4c>
      acquire(&p->lock);
    8000205a:	8526                	mv	a0,s1
    8000205c:	fffff097          	auipc	ra,0xfffff
    80002060:	b8e080e7          	jalr	-1138(ra) # 80000bea <acquire>
      if(p->state == RUNNABLE) {
    80002064:	4c9c                	lw	a5,24(s1)
    80002066:	ff3791e3          	bne	a5,s3,80002048 <scheduler+0x7c>
    8000206a:	b7d1                	j	8000202e <scheduler+0x62>

000000008000206c <sched>:
{
    8000206c:	7179                	addi	sp,sp,-48
    8000206e:	f406                	sd	ra,40(sp)
    80002070:	f022                	sd	s0,32(sp)
    80002072:	ec26                	sd	s1,24(sp)
    80002074:	e84a                	sd	s2,16(sp)
    80002076:	e44e                	sd	s3,8(sp)
    80002078:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000207a:	00000097          	auipc	ra,0x0
    8000207e:	a60080e7          	jalr	-1440(ra) # 80001ada <myproc>
    80002082:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002084:	fffff097          	auipc	ra,0xfffff
    80002088:	aec080e7          	jalr	-1300(ra) # 80000b70 <holding>
    8000208c:	c93d                	beqz	a0,80002102 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000208e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002090:	2781                	sext.w	a5,a5
    80002092:	079e                	slli	a5,a5,0x7
    80002094:	0000f717          	auipc	a4,0xf
    80002098:	a5c70713          	addi	a4,a4,-1444 # 80010af0 <pid_lock>
    8000209c:	97ba                	add	a5,a5,a4
    8000209e:	0a87a703          	lw	a4,168(a5)
    800020a2:	4785                	li	a5,1
    800020a4:	06f71763          	bne	a4,a5,80002112 <sched+0xa6>
  if(p->state == RUNNING)
    800020a8:	4c98                	lw	a4,24(s1)
    800020aa:	4791                	li	a5,4
    800020ac:	06f70b63          	beq	a4,a5,80002122 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020b0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020b4:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020b6:	efb5                	bnez	a5,80002132 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020b8:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020ba:	0000f917          	auipc	s2,0xf
    800020be:	a3690913          	addi	s2,s2,-1482 # 80010af0 <pid_lock>
    800020c2:	2781                	sext.w	a5,a5
    800020c4:	079e                	slli	a5,a5,0x7
    800020c6:	97ca                	add	a5,a5,s2
    800020c8:	0ac7a983          	lw	s3,172(a5)
    800020cc:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020ce:	2781                	sext.w	a5,a5
    800020d0:	079e                	slli	a5,a5,0x7
    800020d2:	0000f597          	auipc	a1,0xf
    800020d6:	a5658593          	addi	a1,a1,-1450 # 80010b28 <cpus+0x8>
    800020da:	95be                	add	a1,a1,a5
    800020dc:	06048513          	addi	a0,s1,96
    800020e0:	00000097          	auipc	ra,0x0
    800020e4:	600080e7          	jalr	1536(ra) # 800026e0 <swtch>
    800020e8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020ea:	2781                	sext.w	a5,a5
    800020ec:	079e                	slli	a5,a5,0x7
    800020ee:	97ca                	add	a5,a5,s2
    800020f0:	0b37a623          	sw	s3,172(a5)
}
    800020f4:	70a2                	ld	ra,40(sp)
    800020f6:	7402                	ld	s0,32(sp)
    800020f8:	64e2                	ld	s1,24(sp)
    800020fa:	6942                	ld	s2,16(sp)
    800020fc:	69a2                	ld	s3,8(sp)
    800020fe:	6145                	addi	sp,sp,48
    80002100:	8082                	ret
    panic("sched p->lock");
    80002102:	00006517          	auipc	a0,0x6
    80002106:	0ce50513          	addi	a0,a0,206 # 800081d0 <digits+0x190>
    8000210a:	ffffe097          	auipc	ra,0xffffe
    8000210e:	43a080e7          	jalr	1082(ra) # 80000544 <panic>
    panic("sched locks");
    80002112:	00006517          	auipc	a0,0x6
    80002116:	0ce50513          	addi	a0,a0,206 # 800081e0 <digits+0x1a0>
    8000211a:	ffffe097          	auipc	ra,0xffffe
    8000211e:	42a080e7          	jalr	1066(ra) # 80000544 <panic>
    panic("sched running");
    80002122:	00006517          	auipc	a0,0x6
    80002126:	0ce50513          	addi	a0,a0,206 # 800081f0 <digits+0x1b0>
    8000212a:	ffffe097          	auipc	ra,0xffffe
    8000212e:	41a080e7          	jalr	1050(ra) # 80000544 <panic>
    panic("sched interruptible");
    80002132:	00006517          	auipc	a0,0x6
    80002136:	0ce50513          	addi	a0,a0,206 # 80008200 <digits+0x1c0>
    8000213a:	ffffe097          	auipc	ra,0xffffe
    8000213e:	40a080e7          	jalr	1034(ra) # 80000544 <panic>

0000000080002142 <yield>:
{
    80002142:	1101                	addi	sp,sp,-32
    80002144:	ec06                	sd	ra,24(sp)
    80002146:	e822                	sd	s0,16(sp)
    80002148:	e426                	sd	s1,8(sp)
    8000214a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000214c:	00000097          	auipc	ra,0x0
    80002150:	98e080e7          	jalr	-1650(ra) # 80001ada <myproc>
    80002154:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	a94080e7          	jalr	-1388(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    8000215e:	478d                	li	a5,3
    80002160:	cc9c                	sw	a5,24(s1)
  sched();
    80002162:	00000097          	auipc	ra,0x0
    80002166:	f0a080e7          	jalr	-246(ra) # 8000206c <sched>
  release(&p->lock);
    8000216a:	8526                	mv	a0,s1
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	b32080e7          	jalr	-1230(ra) # 80000c9e <release>
}
    80002174:	60e2                	ld	ra,24(sp)
    80002176:	6442                	ld	s0,16(sp)
    80002178:	64a2                	ld	s1,8(sp)
    8000217a:	6105                	addi	sp,sp,32
    8000217c:	8082                	ret

000000008000217e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000217e:	7179                	addi	sp,sp,-48
    80002180:	f406                	sd	ra,40(sp)
    80002182:	f022                	sd	s0,32(sp)
    80002184:	ec26                	sd	s1,24(sp)
    80002186:	e84a                	sd	s2,16(sp)
    80002188:	e44e                	sd	s3,8(sp)
    8000218a:	1800                	addi	s0,sp,48
    8000218c:	89aa                	mv	s3,a0
    8000218e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002190:	00000097          	auipc	ra,0x0
    80002194:	94a080e7          	jalr	-1718(ra) # 80001ada <myproc>
    80002198:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	a50080e7          	jalr	-1456(ra) # 80000bea <acquire>
  release(lk);
    800021a2:	854a                	mv	a0,s2
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	afa080e7          	jalr	-1286(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    800021ac:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021b0:	4789                	li	a5,2
    800021b2:	cc9c                	sw	a5,24(s1)

  sched();
    800021b4:	00000097          	auipc	ra,0x0
    800021b8:	eb8080e7          	jalr	-328(ra) # 8000206c <sched>

  // Tidy up.
  p->chan = 0;
    800021bc:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021c0:	8526                	mv	a0,s1
    800021c2:	fffff097          	auipc	ra,0xfffff
    800021c6:	adc080e7          	jalr	-1316(ra) # 80000c9e <release>
  acquire(lk);
    800021ca:	854a                	mv	a0,s2
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	a1e080e7          	jalr	-1506(ra) # 80000bea <acquire>
}
    800021d4:	70a2                	ld	ra,40(sp)
    800021d6:	7402                	ld	s0,32(sp)
    800021d8:	64e2                	ld	s1,24(sp)
    800021da:	6942                	ld	s2,16(sp)
    800021dc:	69a2                	ld	s3,8(sp)
    800021de:	6145                	addi	sp,sp,48
    800021e0:	8082                	ret

00000000800021e2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021e2:	7139                	addi	sp,sp,-64
    800021e4:	fc06                	sd	ra,56(sp)
    800021e6:	f822                	sd	s0,48(sp)
    800021e8:	f426                	sd	s1,40(sp)
    800021ea:	f04a                	sd	s2,32(sp)
    800021ec:	ec4e                	sd	s3,24(sp)
    800021ee:	e852                	sd	s4,16(sp)
    800021f0:	e456                	sd	s5,8(sp)
    800021f2:	0080                	addi	s0,sp,64
    800021f4:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021f6:	0000f497          	auipc	s1,0xf
    800021fa:	d2a48493          	addi	s1,s1,-726 # 80010f20 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800021fe:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002200:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002202:	00014917          	auipc	s2,0x14
    80002206:	71e90913          	addi	s2,s2,1822 # 80016920 <tickslock>
    8000220a:	a821                	j	80002222 <wakeup+0x40>
        p->state = RUNNABLE;
    8000220c:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002210:	8526                	mv	a0,s1
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	a8c080e7          	jalr	-1396(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000221a:	16848493          	addi	s1,s1,360
    8000221e:	03248463          	beq	s1,s2,80002246 <wakeup+0x64>
    if(p != myproc()){
    80002222:	00000097          	auipc	ra,0x0
    80002226:	8b8080e7          	jalr	-1864(ra) # 80001ada <myproc>
    8000222a:	fea488e3          	beq	s1,a0,8000221a <wakeup+0x38>
      acquire(&p->lock);
    8000222e:	8526                	mv	a0,s1
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	9ba080e7          	jalr	-1606(ra) # 80000bea <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002238:	4c9c                	lw	a5,24(s1)
    8000223a:	fd379be3          	bne	a5,s3,80002210 <wakeup+0x2e>
    8000223e:	709c                	ld	a5,32(s1)
    80002240:	fd4798e3          	bne	a5,s4,80002210 <wakeup+0x2e>
    80002244:	b7e1                	j	8000220c <wakeup+0x2a>
    }
  }
}
    80002246:	70e2                	ld	ra,56(sp)
    80002248:	7442                	ld	s0,48(sp)
    8000224a:	74a2                	ld	s1,40(sp)
    8000224c:	7902                	ld	s2,32(sp)
    8000224e:	69e2                	ld	s3,24(sp)
    80002250:	6a42                	ld	s4,16(sp)
    80002252:	6aa2                	ld	s5,8(sp)
    80002254:	6121                	addi	sp,sp,64
    80002256:	8082                	ret

0000000080002258 <reparent>:
{
    80002258:	7179                	addi	sp,sp,-48
    8000225a:	f406                	sd	ra,40(sp)
    8000225c:	f022                	sd	s0,32(sp)
    8000225e:	ec26                	sd	s1,24(sp)
    80002260:	e84a                	sd	s2,16(sp)
    80002262:	e44e                	sd	s3,8(sp)
    80002264:	e052                	sd	s4,0(sp)
    80002266:	1800                	addi	s0,sp,48
    80002268:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000226a:	0000f497          	auipc	s1,0xf
    8000226e:	cb648493          	addi	s1,s1,-842 # 80010f20 <proc>
      pp->parent = initproc;
    80002272:	00006a17          	auipc	s4,0x6
    80002276:	606a0a13          	addi	s4,s4,1542 # 80008878 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000227a:	00014997          	auipc	s3,0x14
    8000227e:	6a698993          	addi	s3,s3,1702 # 80016920 <tickslock>
    80002282:	a029                	j	8000228c <reparent+0x34>
    80002284:	16848493          	addi	s1,s1,360
    80002288:	01348d63          	beq	s1,s3,800022a2 <reparent+0x4a>
    if(pp->parent == p){
    8000228c:	7c9c                	ld	a5,56(s1)
    8000228e:	ff279be3          	bne	a5,s2,80002284 <reparent+0x2c>
      pp->parent = initproc;
    80002292:	000a3503          	ld	a0,0(s4)
    80002296:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002298:	00000097          	auipc	ra,0x0
    8000229c:	f4a080e7          	jalr	-182(ra) # 800021e2 <wakeup>
    800022a0:	b7d5                	j	80002284 <reparent+0x2c>
}
    800022a2:	70a2                	ld	ra,40(sp)
    800022a4:	7402                	ld	s0,32(sp)
    800022a6:	64e2                	ld	s1,24(sp)
    800022a8:	6942                	ld	s2,16(sp)
    800022aa:	69a2                	ld	s3,8(sp)
    800022ac:	6a02                	ld	s4,0(sp)
    800022ae:	6145                	addi	sp,sp,48
    800022b0:	8082                	ret

00000000800022b2 <exit>:
{
    800022b2:	7179                	addi	sp,sp,-48
    800022b4:	f406                	sd	ra,40(sp)
    800022b6:	f022                	sd	s0,32(sp)
    800022b8:	ec26                	sd	s1,24(sp)
    800022ba:	e84a                	sd	s2,16(sp)
    800022bc:	e44e                	sd	s3,8(sp)
    800022be:	e052                	sd	s4,0(sp)
    800022c0:	1800                	addi	s0,sp,48
    800022c2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022c4:	00000097          	auipc	ra,0x0
    800022c8:	816080e7          	jalr	-2026(ra) # 80001ada <myproc>
    800022cc:	89aa                	mv	s3,a0
  if(p == initproc)
    800022ce:	00006797          	auipc	a5,0x6
    800022d2:	5aa7b783          	ld	a5,1450(a5) # 80008878 <initproc>
    800022d6:	0d050493          	addi	s1,a0,208
    800022da:	15050913          	addi	s2,a0,336
    800022de:	02a79363          	bne	a5,a0,80002304 <exit+0x52>
    panic("init exiting");
    800022e2:	00006517          	auipc	a0,0x6
    800022e6:	f3650513          	addi	a0,a0,-202 # 80008218 <digits+0x1d8>
    800022ea:	ffffe097          	auipc	ra,0xffffe
    800022ee:	25a080e7          	jalr	602(ra) # 80000544 <panic>
      fileclose(f);
    800022f2:	00002097          	auipc	ra,0x2
    800022f6:	380080e7          	jalr	896(ra) # 80004672 <fileclose>
      p->ofile[fd] = 0;
    800022fa:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022fe:	04a1                	addi	s1,s1,8
    80002300:	01248563          	beq	s1,s2,8000230a <exit+0x58>
    if(p->ofile[fd]){
    80002304:	6088                	ld	a0,0(s1)
    80002306:	f575                	bnez	a0,800022f2 <exit+0x40>
    80002308:	bfdd                	j	800022fe <exit+0x4c>
  begin_op();
    8000230a:	00002097          	auipc	ra,0x2
    8000230e:	e9c080e7          	jalr	-356(ra) # 800041a6 <begin_op>
  iput(p->cwd);
    80002312:	1509b503          	ld	a0,336(s3)
    80002316:	00001097          	auipc	ra,0x1
    8000231a:	688080e7          	jalr	1672(ra) # 8000399e <iput>
  end_op();
    8000231e:	00002097          	auipc	ra,0x2
    80002322:	f08080e7          	jalr	-248(ra) # 80004226 <end_op>
  p->cwd = 0;
    80002326:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000232a:	0000e497          	auipc	s1,0xe
    8000232e:	7de48493          	addi	s1,s1,2014 # 80010b08 <wait_lock>
    80002332:	8526                	mv	a0,s1
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	8b6080e7          	jalr	-1866(ra) # 80000bea <acquire>
  reparent(p);
    8000233c:	854e                	mv	a0,s3
    8000233e:	00000097          	auipc	ra,0x0
    80002342:	f1a080e7          	jalr	-230(ra) # 80002258 <reparent>
  wakeup(p->parent);
    80002346:	0389b503          	ld	a0,56(s3)
    8000234a:	00000097          	auipc	ra,0x0
    8000234e:	e98080e7          	jalr	-360(ra) # 800021e2 <wakeup>
  acquire(&p->lock);
    80002352:	854e                	mv	a0,s3
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	896080e7          	jalr	-1898(ra) # 80000bea <acquire>
  p->xstate = status;
    8000235c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002360:	4795                	li	a5,5
    80002362:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002366:	8526                	mv	a0,s1
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	936080e7          	jalr	-1738(ra) # 80000c9e <release>
  sched();
    80002370:	00000097          	auipc	ra,0x0
    80002374:	cfc080e7          	jalr	-772(ra) # 8000206c <sched>
  panic("zombie exit");
    80002378:	00006517          	auipc	a0,0x6
    8000237c:	eb050513          	addi	a0,a0,-336 # 80008228 <digits+0x1e8>
    80002380:	ffffe097          	auipc	ra,0xffffe
    80002384:	1c4080e7          	jalr	452(ra) # 80000544 <panic>

0000000080002388 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002388:	7179                	addi	sp,sp,-48
    8000238a:	f406                	sd	ra,40(sp)
    8000238c:	f022                	sd	s0,32(sp)
    8000238e:	ec26                	sd	s1,24(sp)
    80002390:	e84a                	sd	s2,16(sp)
    80002392:	e44e                	sd	s3,8(sp)
    80002394:	1800                	addi	s0,sp,48
    80002396:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002398:	0000f497          	auipc	s1,0xf
    8000239c:	b8848493          	addi	s1,s1,-1144 # 80010f20 <proc>
    800023a0:	00014997          	auipc	s3,0x14
    800023a4:	58098993          	addi	s3,s3,1408 # 80016920 <tickslock>
    acquire(&p->lock);
    800023a8:	8526                	mv	a0,s1
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	840080e7          	jalr	-1984(ra) # 80000bea <acquire>
    if(p->pid == pid){
    800023b2:	589c                	lw	a5,48(s1)
    800023b4:	01278d63          	beq	a5,s2,800023ce <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023b8:	8526                	mv	a0,s1
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	8e4080e7          	jalr	-1820(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023c2:	16848493          	addi	s1,s1,360
    800023c6:	ff3491e3          	bne	s1,s3,800023a8 <kill+0x20>
  }
  return -1;
    800023ca:	557d                	li	a0,-1
    800023cc:	a829                	j	800023e6 <kill+0x5e>
      p->killed = 1;
    800023ce:	4785                	li	a5,1
    800023d0:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023d2:	4c98                	lw	a4,24(s1)
    800023d4:	4789                	li	a5,2
    800023d6:	00f70f63          	beq	a4,a5,800023f4 <kill+0x6c>
      release(&p->lock);
    800023da:	8526                	mv	a0,s1
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	8c2080e7          	jalr	-1854(ra) # 80000c9e <release>
      return 0;
    800023e4:	4501                	li	a0,0
}
    800023e6:	70a2                	ld	ra,40(sp)
    800023e8:	7402                	ld	s0,32(sp)
    800023ea:	64e2                	ld	s1,24(sp)
    800023ec:	6942                	ld	s2,16(sp)
    800023ee:	69a2                	ld	s3,8(sp)
    800023f0:	6145                	addi	sp,sp,48
    800023f2:	8082                	ret
        p->state = RUNNABLE;
    800023f4:	478d                	li	a5,3
    800023f6:	cc9c                	sw	a5,24(s1)
    800023f8:	b7cd                	j	800023da <kill+0x52>

00000000800023fa <setkilled>:

void
setkilled(struct proc *p)
{
    800023fa:	1101                	addi	sp,sp,-32
    800023fc:	ec06                	sd	ra,24(sp)
    800023fe:	e822                	sd	s0,16(sp)
    80002400:	e426                	sd	s1,8(sp)
    80002402:	1000                	addi	s0,sp,32
    80002404:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002406:	ffffe097          	auipc	ra,0xffffe
    8000240a:	7e4080e7          	jalr	2020(ra) # 80000bea <acquire>
  p->killed = 1;
    8000240e:	4785                	li	a5,1
    80002410:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002412:	8526                	mv	a0,s1
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	88a080e7          	jalr	-1910(ra) # 80000c9e <release>
}
    8000241c:	60e2                	ld	ra,24(sp)
    8000241e:	6442                	ld	s0,16(sp)
    80002420:	64a2                	ld	s1,8(sp)
    80002422:	6105                	addi	sp,sp,32
    80002424:	8082                	ret

0000000080002426 <killed>:

int
killed(struct proc *p)
{
    80002426:	1101                	addi	sp,sp,-32
    80002428:	ec06                	sd	ra,24(sp)
    8000242a:	e822                	sd	s0,16(sp)
    8000242c:	e426                	sd	s1,8(sp)
    8000242e:	e04a                	sd	s2,0(sp)
    80002430:	1000                	addi	s0,sp,32
    80002432:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002434:	ffffe097          	auipc	ra,0xffffe
    80002438:	7b6080e7          	jalr	1974(ra) # 80000bea <acquire>
  k = p->killed;
    8000243c:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002440:	8526                	mv	a0,s1
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	85c080e7          	jalr	-1956(ra) # 80000c9e <release>
  return k;
}
    8000244a:	854a                	mv	a0,s2
    8000244c:	60e2                	ld	ra,24(sp)
    8000244e:	6442                	ld	s0,16(sp)
    80002450:	64a2                	ld	s1,8(sp)
    80002452:	6902                	ld	s2,0(sp)
    80002454:	6105                	addi	sp,sp,32
    80002456:	8082                	ret

0000000080002458 <wait>:
{
    80002458:	715d                	addi	sp,sp,-80
    8000245a:	e486                	sd	ra,72(sp)
    8000245c:	e0a2                	sd	s0,64(sp)
    8000245e:	fc26                	sd	s1,56(sp)
    80002460:	f84a                	sd	s2,48(sp)
    80002462:	f44e                	sd	s3,40(sp)
    80002464:	f052                	sd	s4,32(sp)
    80002466:	ec56                	sd	s5,24(sp)
    80002468:	e85a                	sd	s6,16(sp)
    8000246a:	e45e                	sd	s7,8(sp)
    8000246c:	e062                	sd	s8,0(sp)
    8000246e:	0880                	addi	s0,sp,80
    80002470:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002472:	fffff097          	auipc	ra,0xfffff
    80002476:	668080e7          	jalr	1640(ra) # 80001ada <myproc>
    8000247a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000247c:	0000e517          	auipc	a0,0xe
    80002480:	68c50513          	addi	a0,a0,1676 # 80010b08 <wait_lock>
    80002484:	ffffe097          	auipc	ra,0xffffe
    80002488:	766080e7          	jalr	1894(ra) # 80000bea <acquire>
    havekids = 0;
    8000248c:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000248e:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002490:	00014997          	auipc	s3,0x14
    80002494:	49098993          	addi	s3,s3,1168 # 80016920 <tickslock>
        havekids = 1;
    80002498:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000249a:	0000ec17          	auipc	s8,0xe
    8000249e:	66ec0c13          	addi	s8,s8,1646 # 80010b08 <wait_lock>
    havekids = 0;
    800024a2:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024a4:	0000f497          	auipc	s1,0xf
    800024a8:	a7c48493          	addi	s1,s1,-1412 # 80010f20 <proc>
    800024ac:	a0bd                	j	8000251a <wait+0xc2>
          pid = pp->pid;
    800024ae:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800024b2:	000b0e63          	beqz	s6,800024ce <wait+0x76>
    800024b6:	4691                	li	a3,4
    800024b8:	02c48613          	addi	a2,s1,44
    800024bc:	85da                	mv	a1,s6
    800024be:	05093503          	ld	a0,80(s2)
    800024c2:	fffff097          	auipc	ra,0xfffff
    800024c6:	1ea080e7          	jalr	490(ra) # 800016ac <copyout>
    800024ca:	02054563          	bltz	a0,800024f4 <wait+0x9c>
          freeproc(pp);
    800024ce:	8526                	mv	a0,s1
    800024d0:	fffff097          	auipc	ra,0xfffff
    800024d4:	7bc080e7          	jalr	1980(ra) # 80001c8c <freeproc>
          release(&pp->lock);
    800024d8:	8526                	mv	a0,s1
    800024da:	ffffe097          	auipc	ra,0xffffe
    800024de:	7c4080e7          	jalr	1988(ra) # 80000c9e <release>
          release(&wait_lock);
    800024e2:	0000e517          	auipc	a0,0xe
    800024e6:	62650513          	addi	a0,a0,1574 # 80010b08 <wait_lock>
    800024ea:	ffffe097          	auipc	ra,0xffffe
    800024ee:	7b4080e7          	jalr	1972(ra) # 80000c9e <release>
          return pid;
    800024f2:	a0b5                	j	8000255e <wait+0x106>
            release(&pp->lock);
    800024f4:	8526                	mv	a0,s1
    800024f6:	ffffe097          	auipc	ra,0xffffe
    800024fa:	7a8080e7          	jalr	1960(ra) # 80000c9e <release>
            release(&wait_lock);
    800024fe:	0000e517          	auipc	a0,0xe
    80002502:	60a50513          	addi	a0,a0,1546 # 80010b08 <wait_lock>
    80002506:	ffffe097          	auipc	ra,0xffffe
    8000250a:	798080e7          	jalr	1944(ra) # 80000c9e <release>
            return -1;
    8000250e:	59fd                	li	s3,-1
    80002510:	a0b9                	j	8000255e <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002512:	16848493          	addi	s1,s1,360
    80002516:	03348463          	beq	s1,s3,8000253e <wait+0xe6>
      if(pp->parent == p){
    8000251a:	7c9c                	ld	a5,56(s1)
    8000251c:	ff279be3          	bne	a5,s2,80002512 <wait+0xba>
        acquire(&pp->lock);
    80002520:	8526                	mv	a0,s1
    80002522:	ffffe097          	auipc	ra,0xffffe
    80002526:	6c8080e7          	jalr	1736(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    8000252a:	4c9c                	lw	a5,24(s1)
    8000252c:	f94781e3          	beq	a5,s4,800024ae <wait+0x56>
        release(&pp->lock);
    80002530:	8526                	mv	a0,s1
    80002532:	ffffe097          	auipc	ra,0xffffe
    80002536:	76c080e7          	jalr	1900(ra) # 80000c9e <release>
        havekids = 1;
    8000253a:	8756                	mv	a4,s5
    8000253c:	bfd9                	j	80002512 <wait+0xba>
    if(!havekids || killed(p)){
    8000253e:	c719                	beqz	a4,8000254c <wait+0xf4>
    80002540:	854a                	mv	a0,s2
    80002542:	00000097          	auipc	ra,0x0
    80002546:	ee4080e7          	jalr	-284(ra) # 80002426 <killed>
    8000254a:	c51d                	beqz	a0,80002578 <wait+0x120>
      release(&wait_lock);
    8000254c:	0000e517          	auipc	a0,0xe
    80002550:	5bc50513          	addi	a0,a0,1468 # 80010b08 <wait_lock>
    80002554:	ffffe097          	auipc	ra,0xffffe
    80002558:	74a080e7          	jalr	1866(ra) # 80000c9e <release>
      return -1;
    8000255c:	59fd                	li	s3,-1
}
    8000255e:	854e                	mv	a0,s3
    80002560:	60a6                	ld	ra,72(sp)
    80002562:	6406                	ld	s0,64(sp)
    80002564:	74e2                	ld	s1,56(sp)
    80002566:	7942                	ld	s2,48(sp)
    80002568:	79a2                	ld	s3,40(sp)
    8000256a:	7a02                	ld	s4,32(sp)
    8000256c:	6ae2                	ld	s5,24(sp)
    8000256e:	6b42                	ld	s6,16(sp)
    80002570:	6ba2                	ld	s7,8(sp)
    80002572:	6c02                	ld	s8,0(sp)
    80002574:	6161                	addi	sp,sp,80
    80002576:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002578:	85e2                	mv	a1,s8
    8000257a:	854a                	mv	a0,s2
    8000257c:	00000097          	auipc	ra,0x0
    80002580:	c02080e7          	jalr	-1022(ra) # 8000217e <sleep>
    havekids = 0;
    80002584:	bf39                	j	800024a2 <wait+0x4a>

0000000080002586 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002586:	7179                	addi	sp,sp,-48
    80002588:	f406                	sd	ra,40(sp)
    8000258a:	f022                	sd	s0,32(sp)
    8000258c:	ec26                	sd	s1,24(sp)
    8000258e:	e84a                	sd	s2,16(sp)
    80002590:	e44e                	sd	s3,8(sp)
    80002592:	e052                	sd	s4,0(sp)
    80002594:	1800                	addi	s0,sp,48
    80002596:	84aa                	mv	s1,a0
    80002598:	892e                	mv	s2,a1
    8000259a:	89b2                	mv	s3,a2
    8000259c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000259e:	fffff097          	auipc	ra,0xfffff
    800025a2:	53c080e7          	jalr	1340(ra) # 80001ada <myproc>
  if(user_dst){
    800025a6:	c08d                	beqz	s1,800025c8 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800025a8:	86d2                	mv	a3,s4
    800025aa:	864e                	mv	a2,s3
    800025ac:	85ca                	mv	a1,s2
    800025ae:	6928                	ld	a0,80(a0)
    800025b0:	fffff097          	auipc	ra,0xfffff
    800025b4:	0fc080e7          	jalr	252(ra) # 800016ac <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800025b8:	70a2                	ld	ra,40(sp)
    800025ba:	7402                	ld	s0,32(sp)
    800025bc:	64e2                	ld	s1,24(sp)
    800025be:	6942                	ld	s2,16(sp)
    800025c0:	69a2                	ld	s3,8(sp)
    800025c2:	6a02                	ld	s4,0(sp)
    800025c4:	6145                	addi	sp,sp,48
    800025c6:	8082                	ret
    memmove((char *)dst, src, len);
    800025c8:	000a061b          	sext.w	a2,s4
    800025cc:	85ce                	mv	a1,s3
    800025ce:	854a                	mv	a0,s2
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	776080e7          	jalr	1910(ra) # 80000d46 <memmove>
    return 0;
    800025d8:	8526                	mv	a0,s1
    800025da:	bff9                	j	800025b8 <either_copyout+0x32>

00000000800025dc <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025dc:	7179                	addi	sp,sp,-48
    800025de:	f406                	sd	ra,40(sp)
    800025e0:	f022                	sd	s0,32(sp)
    800025e2:	ec26                	sd	s1,24(sp)
    800025e4:	e84a                	sd	s2,16(sp)
    800025e6:	e44e                	sd	s3,8(sp)
    800025e8:	e052                	sd	s4,0(sp)
    800025ea:	1800                	addi	s0,sp,48
    800025ec:	892a                	mv	s2,a0
    800025ee:	84ae                	mv	s1,a1
    800025f0:	89b2                	mv	s3,a2
    800025f2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025f4:	fffff097          	auipc	ra,0xfffff
    800025f8:	4e6080e7          	jalr	1254(ra) # 80001ada <myproc>
  if(user_src){
    800025fc:	c08d                	beqz	s1,8000261e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025fe:	86d2                	mv	a3,s4
    80002600:	864e                	mv	a2,s3
    80002602:	85ca                	mv	a1,s2
    80002604:	6928                	ld	a0,80(a0)
    80002606:	fffff097          	auipc	ra,0xfffff
    8000260a:	132080e7          	jalr	306(ra) # 80001738 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000260e:	70a2                	ld	ra,40(sp)
    80002610:	7402                	ld	s0,32(sp)
    80002612:	64e2                	ld	s1,24(sp)
    80002614:	6942                	ld	s2,16(sp)
    80002616:	69a2                	ld	s3,8(sp)
    80002618:	6a02                	ld	s4,0(sp)
    8000261a:	6145                	addi	sp,sp,48
    8000261c:	8082                	ret
    memmove(dst, (char*)src, len);
    8000261e:	000a061b          	sext.w	a2,s4
    80002622:	85ce                	mv	a1,s3
    80002624:	854a                	mv	a0,s2
    80002626:	ffffe097          	auipc	ra,0xffffe
    8000262a:	720080e7          	jalr	1824(ra) # 80000d46 <memmove>
    return 0;
    8000262e:	8526                	mv	a0,s1
    80002630:	bff9                	j	8000260e <either_copyin+0x32>

0000000080002632 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002632:	715d                	addi	sp,sp,-80
    80002634:	e486                	sd	ra,72(sp)
    80002636:	e0a2                	sd	s0,64(sp)
    80002638:	fc26                	sd	s1,56(sp)
    8000263a:	f84a                	sd	s2,48(sp)
    8000263c:	f44e                	sd	s3,40(sp)
    8000263e:	f052                	sd	s4,32(sp)
    80002640:	ec56                	sd	s5,24(sp)
    80002642:	e85a                	sd	s6,16(sp)
    80002644:	e45e                	sd	s7,8(sp)
    80002646:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002648:	00006517          	auipc	a0,0x6
    8000264c:	a8050513          	addi	a0,a0,-1408 # 800080c8 <digits+0x88>
    80002650:	ffffe097          	auipc	ra,0xffffe
    80002654:	f3e080e7          	jalr	-194(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002658:	0000f497          	auipc	s1,0xf
    8000265c:	a2048493          	addi	s1,s1,-1504 # 80011078 <proc+0x158>
    80002660:	00014917          	auipc	s2,0x14
    80002664:	41890913          	addi	s2,s2,1048 # 80016a78 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002668:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000266a:	00006997          	auipc	s3,0x6
    8000266e:	bce98993          	addi	s3,s3,-1074 # 80008238 <digits+0x1f8>
    printf("%d %s %s", p->pid, state, p->name);
    80002672:	00006a97          	auipc	s5,0x6
    80002676:	bcea8a93          	addi	s5,s5,-1074 # 80008240 <digits+0x200>
    printf("\n");
    8000267a:	00006a17          	auipc	s4,0x6
    8000267e:	a4ea0a13          	addi	s4,s4,-1458 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002682:	00006b97          	auipc	s7,0x6
    80002686:	bfeb8b93          	addi	s7,s7,-1026 # 80008280 <states.1724>
    8000268a:	a00d                	j	800026ac <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000268c:	ed86a583          	lw	a1,-296(a3)
    80002690:	8556                	mv	a0,s5
    80002692:	ffffe097          	auipc	ra,0xffffe
    80002696:	efc080e7          	jalr	-260(ra) # 8000058e <printf>
    printf("\n");
    8000269a:	8552                	mv	a0,s4
    8000269c:	ffffe097          	auipc	ra,0xffffe
    800026a0:	ef2080e7          	jalr	-270(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026a4:	16848493          	addi	s1,s1,360
    800026a8:	03248163          	beq	s1,s2,800026ca <procdump+0x98>
    if(p->state == UNUSED)
    800026ac:	86a6                	mv	a3,s1
    800026ae:	ec04a783          	lw	a5,-320(s1)
    800026b2:	dbed                	beqz	a5,800026a4 <procdump+0x72>
      state = "???";
    800026b4:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026b6:	fcfb6be3          	bltu	s6,a5,8000268c <procdump+0x5a>
    800026ba:	1782                	slli	a5,a5,0x20
    800026bc:	9381                	srli	a5,a5,0x20
    800026be:	078e                	slli	a5,a5,0x3
    800026c0:	97de                	add	a5,a5,s7
    800026c2:	6390                	ld	a2,0(a5)
    800026c4:	f661                	bnez	a2,8000268c <procdump+0x5a>
      state = "???";
    800026c6:	864e                	mv	a2,s3
    800026c8:	b7d1                	j	8000268c <procdump+0x5a>
  }
}
    800026ca:	60a6                	ld	ra,72(sp)
    800026cc:	6406                	ld	s0,64(sp)
    800026ce:	74e2                	ld	s1,56(sp)
    800026d0:	7942                	ld	s2,48(sp)
    800026d2:	79a2                	ld	s3,40(sp)
    800026d4:	7a02                	ld	s4,32(sp)
    800026d6:	6ae2                	ld	s5,24(sp)
    800026d8:	6b42                	ld	s6,16(sp)
    800026da:	6ba2                	ld	s7,8(sp)
    800026dc:	6161                	addi	sp,sp,80
    800026de:	8082                	ret

00000000800026e0 <swtch>:
    800026e0:	00153023          	sd	ra,0(a0)
    800026e4:	00253423          	sd	sp,8(a0)
    800026e8:	e900                	sd	s0,16(a0)
    800026ea:	ed04                	sd	s1,24(a0)
    800026ec:	03253023          	sd	s2,32(a0)
    800026f0:	03353423          	sd	s3,40(a0)
    800026f4:	03453823          	sd	s4,48(a0)
    800026f8:	03553c23          	sd	s5,56(a0)
    800026fc:	05653023          	sd	s6,64(a0)
    80002700:	05753423          	sd	s7,72(a0)
    80002704:	05853823          	sd	s8,80(a0)
    80002708:	05953c23          	sd	s9,88(a0)
    8000270c:	07a53023          	sd	s10,96(a0)
    80002710:	07b53423          	sd	s11,104(a0)
    80002714:	0005b083          	ld	ra,0(a1)
    80002718:	0085b103          	ld	sp,8(a1)
    8000271c:	6980                	ld	s0,16(a1)
    8000271e:	6d84                	ld	s1,24(a1)
    80002720:	0205b903          	ld	s2,32(a1)
    80002724:	0285b983          	ld	s3,40(a1)
    80002728:	0305ba03          	ld	s4,48(a1)
    8000272c:	0385ba83          	ld	s5,56(a1)
    80002730:	0405bb03          	ld	s6,64(a1)
    80002734:	0485bb83          	ld	s7,72(a1)
    80002738:	0505bc03          	ld	s8,80(a1)
    8000273c:	0585bc83          	ld	s9,88(a1)
    80002740:	0605bd03          	ld	s10,96(a1)
    80002744:	0685bd83          	ld	s11,104(a1)
    80002748:	8082                	ret

000000008000274a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000274a:	1141                	addi	sp,sp,-16
    8000274c:	e406                	sd	ra,8(sp)
    8000274e:	e022                	sd	s0,0(sp)
    80002750:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002752:	00006597          	auipc	a1,0x6
    80002756:	b5e58593          	addi	a1,a1,-1186 # 800082b0 <states.1724+0x30>
    8000275a:	00014517          	auipc	a0,0x14
    8000275e:	1c650513          	addi	a0,a0,454 # 80016920 <tickslock>
    80002762:	ffffe097          	auipc	ra,0xffffe
    80002766:	3f8080e7          	jalr	1016(ra) # 80000b5a <initlock>
}
    8000276a:	60a2                	ld	ra,8(sp)
    8000276c:	6402                	ld	s0,0(sp)
    8000276e:	0141                	addi	sp,sp,16
    80002770:	8082                	ret

0000000080002772 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002772:	1141                	addi	sp,sp,-16
    80002774:	e422                	sd	s0,8(sp)
    80002776:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002778:	00003797          	auipc	a5,0x3
    8000277c:	54878793          	addi	a5,a5,1352 # 80005cc0 <kernelvec>
    80002780:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002784:	6422                	ld	s0,8(sp)
    80002786:	0141                	addi	sp,sp,16
    80002788:	8082                	ret

000000008000278a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000278a:	1141                	addi	sp,sp,-16
    8000278c:	e406                	sd	ra,8(sp)
    8000278e:	e022                	sd	s0,0(sp)
    80002790:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002792:	fffff097          	auipc	ra,0xfffff
    80002796:	348080e7          	jalr	840(ra) # 80001ada <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000279a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000279e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027a0:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800027a4:	00005617          	auipc	a2,0x5
    800027a8:	85c60613          	addi	a2,a2,-1956 # 80007000 <_trampoline>
    800027ac:	00005697          	auipc	a3,0x5
    800027b0:	85468693          	addi	a3,a3,-1964 # 80007000 <_trampoline>
    800027b4:	8e91                	sub	a3,a3,a2
    800027b6:	040007b7          	lui	a5,0x4000
    800027ba:	17fd                	addi	a5,a5,-1
    800027bc:	07b2                	slli	a5,a5,0xc
    800027be:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027c0:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027c4:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027c6:	180026f3          	csrr	a3,satp
    800027ca:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027cc:	6d38                	ld	a4,88(a0)
    800027ce:	6134                	ld	a3,64(a0)
    800027d0:	6585                	lui	a1,0x1
    800027d2:	96ae                	add	a3,a3,a1
    800027d4:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027d6:	6d38                	ld	a4,88(a0)
    800027d8:	00000697          	auipc	a3,0x0
    800027dc:	13068693          	addi	a3,a3,304 # 80002908 <usertrap>
    800027e0:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027e2:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027e4:	8692                	mv	a3,tp
    800027e6:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027e8:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027ec:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027f0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027f4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027f8:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027fa:	6f18                	ld	a4,24(a4)
    800027fc:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002800:	6928                	ld	a0,80(a0)
    80002802:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002804:	00005717          	auipc	a4,0x5
    80002808:	89870713          	addi	a4,a4,-1896 # 8000709c <userret>
    8000280c:	8f11                	sub	a4,a4,a2
    8000280e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002810:	577d                	li	a4,-1
    80002812:	177e                	slli	a4,a4,0x3f
    80002814:	8d59                	or	a0,a0,a4
    80002816:	9782                	jalr	a5
}
    80002818:	60a2                	ld	ra,8(sp)
    8000281a:	6402                	ld	s0,0(sp)
    8000281c:	0141                	addi	sp,sp,16
    8000281e:	8082                	ret

0000000080002820 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002820:	1101                	addi	sp,sp,-32
    80002822:	ec06                	sd	ra,24(sp)
    80002824:	e822                	sd	s0,16(sp)
    80002826:	e426                	sd	s1,8(sp)
    80002828:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000282a:	00014497          	auipc	s1,0x14
    8000282e:	0f648493          	addi	s1,s1,246 # 80016920 <tickslock>
    80002832:	8526                	mv	a0,s1
    80002834:	ffffe097          	auipc	ra,0xffffe
    80002838:	3b6080e7          	jalr	950(ra) # 80000bea <acquire>
  ticks++;
    8000283c:	00006517          	auipc	a0,0x6
    80002840:	04450513          	addi	a0,a0,68 # 80008880 <ticks>
    80002844:	411c                	lw	a5,0(a0)
    80002846:	2785                	addiw	a5,a5,1
    80002848:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000284a:	00000097          	auipc	ra,0x0
    8000284e:	998080e7          	jalr	-1640(ra) # 800021e2 <wakeup>
  release(&tickslock);
    80002852:	8526                	mv	a0,s1
    80002854:	ffffe097          	auipc	ra,0xffffe
    80002858:	44a080e7          	jalr	1098(ra) # 80000c9e <release>
}
    8000285c:	60e2                	ld	ra,24(sp)
    8000285e:	6442                	ld	s0,16(sp)
    80002860:	64a2                	ld	s1,8(sp)
    80002862:	6105                	addi	sp,sp,32
    80002864:	8082                	ret

0000000080002866 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002866:	1101                	addi	sp,sp,-32
    80002868:	ec06                	sd	ra,24(sp)
    8000286a:	e822                	sd	s0,16(sp)
    8000286c:	e426                	sd	s1,8(sp)
    8000286e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002870:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002874:	00074d63          	bltz	a4,8000288e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002878:	57fd                	li	a5,-1
    8000287a:	17fe                	slli	a5,a5,0x3f
    8000287c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000287e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002880:	06f70363          	beq	a4,a5,800028e6 <devintr+0x80>
  }
}
    80002884:	60e2                	ld	ra,24(sp)
    80002886:	6442                	ld	s0,16(sp)
    80002888:	64a2                	ld	s1,8(sp)
    8000288a:	6105                	addi	sp,sp,32
    8000288c:	8082                	ret
     (scause & 0xff) == 9){
    8000288e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002892:	46a5                	li	a3,9
    80002894:	fed792e3          	bne	a5,a3,80002878 <devintr+0x12>
    int irq = plic_claim();
    80002898:	00003097          	auipc	ra,0x3
    8000289c:	530080e7          	jalr	1328(ra) # 80005dc8 <plic_claim>
    800028a0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028a2:	47a9                	li	a5,10
    800028a4:	02f50763          	beq	a0,a5,800028d2 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800028a8:	4785                	li	a5,1
    800028aa:	02f50963          	beq	a0,a5,800028dc <devintr+0x76>
    return 1;
    800028ae:	4505                	li	a0,1
    } else if(irq){
    800028b0:	d8f1                	beqz	s1,80002884 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800028b2:	85a6                	mv	a1,s1
    800028b4:	00006517          	auipc	a0,0x6
    800028b8:	a0450513          	addi	a0,a0,-1532 # 800082b8 <states.1724+0x38>
    800028bc:	ffffe097          	auipc	ra,0xffffe
    800028c0:	cd2080e7          	jalr	-814(ra) # 8000058e <printf>
      plic_complete(irq);
    800028c4:	8526                	mv	a0,s1
    800028c6:	00003097          	auipc	ra,0x3
    800028ca:	526080e7          	jalr	1318(ra) # 80005dec <plic_complete>
    return 1;
    800028ce:	4505                	li	a0,1
    800028d0:	bf55                	j	80002884 <devintr+0x1e>
      uartintr();
    800028d2:	ffffe097          	auipc	ra,0xffffe
    800028d6:	0dc080e7          	jalr	220(ra) # 800009ae <uartintr>
    800028da:	b7ed                	j	800028c4 <devintr+0x5e>
      virtio_disk_intr();
    800028dc:	00004097          	auipc	ra,0x4
    800028e0:	a3a080e7          	jalr	-1478(ra) # 80006316 <virtio_disk_intr>
    800028e4:	b7c5                	j	800028c4 <devintr+0x5e>
    if(cpuid() == 0){
    800028e6:	fffff097          	auipc	ra,0xfffff
    800028ea:	1c8080e7          	jalr	456(ra) # 80001aae <cpuid>
    800028ee:	c901                	beqz	a0,800028fe <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028f0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028f4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028f6:	14479073          	csrw	sip,a5
    return 2;
    800028fa:	4509                	li	a0,2
    800028fc:	b761                	j	80002884 <devintr+0x1e>
      clockintr();
    800028fe:	00000097          	auipc	ra,0x0
    80002902:	f22080e7          	jalr	-222(ra) # 80002820 <clockintr>
    80002906:	b7ed                	j	800028f0 <devintr+0x8a>

0000000080002908 <usertrap>:
{
    80002908:	7179                	addi	sp,sp,-48
    8000290a:	f406                	sd	ra,40(sp)
    8000290c:	f022                	sd	s0,32(sp)
    8000290e:	ec26                	sd	s1,24(sp)
    80002910:	e84a                	sd	s2,16(sp)
    80002912:	e44e                	sd	s3,8(sp)
    80002914:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002916:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000291a:	1007f793          	andi	a5,a5,256
    8000291e:	e3b5                	bnez	a5,80002982 <usertrap+0x7a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002920:	00003797          	auipc	a5,0x3
    80002924:	3a078793          	addi	a5,a5,928 # 80005cc0 <kernelvec>
    80002928:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000292c:	fffff097          	auipc	ra,0xfffff
    80002930:	1ae080e7          	jalr	430(ra) # 80001ada <myproc>
    80002934:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002936:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002938:	14102773          	csrr	a4,sepc
    8000293c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000293e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002942:	47a1                	li	a5,8
    80002944:	04f70763          	beq	a4,a5,80002992 <usertrap+0x8a>
  } else if((which_dev = devintr()) != 0){
    80002948:	00000097          	auipc	ra,0x0
    8000294c:	f1e080e7          	jalr	-226(ra) # 80002866 <devintr>
    80002950:	892a                	mv	s2,a0
    80002952:	10051a63          	bnez	a0,80002a66 <usertrap+0x15e>
    80002956:	14202773          	csrr	a4,scause
  } else if((r_scause() == 13) || (r_scause() == 15)){  
    8000295a:	47b5                	li	a5,13
    8000295c:	00f70763          	beq	a4,a5,8000296a <usertrap+0x62>
    80002960:	14202773          	csrr	a4,scause
    80002964:	47bd                	li	a5,15
    80002966:	0cf71363          	bne	a4,a5,80002a2c <usertrap+0x124>
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000296a:	14302973          	csrr	s2,stval
    if (v >= p->sz || v < p->trapframe->sp) {
    8000296e:	64bc                	ld	a5,72(s1)
    80002970:	00f97663          	bgeu	s2,a5,8000297c <usertrap+0x74>
    80002974:	6cbc                	ld	a5,88(s1)
    80002976:	7b9c                	ld	a5,48(a5)
    80002978:	06f97763          	bgeu	s2,a5,800029e6 <usertrap+0xde>
      p->killed = 1;
    8000297c:	4785                	li	a5,1
    8000297e:	d49c                	sw	a5,40(s1)
    80002980:	a825                	j	800029b8 <usertrap+0xb0>
    panic("usertrap: not from user mode");
    80002982:	00006517          	auipc	a0,0x6
    80002986:	95650513          	addi	a0,a0,-1706 # 800082d8 <states.1724+0x58>
    8000298a:	ffffe097          	auipc	ra,0xffffe
    8000298e:	bba080e7          	jalr	-1094(ra) # 80000544 <panic>
    if(killed(p))
    80002992:	00000097          	auipc	ra,0x0
    80002996:	a94080e7          	jalr	-1388(ra) # 80002426 <killed>
    8000299a:	e121                	bnez	a0,800029da <usertrap+0xd2>
    p->trapframe->epc += 4;
    8000299c:	6cb8                	ld	a4,88(s1)
    8000299e:	6f1c                	ld	a5,24(a4)
    800029a0:	0791                	addi	a5,a5,4
    800029a2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029a8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ac:	10079073          	csrw	sstatus,a5
    syscall();
    800029b0:	00000097          	auipc	ra,0x0
    800029b4:	32a080e7          	jalr	810(ra) # 80002cda <syscall>
  if(killed(p))
    800029b8:	8526                	mv	a0,s1
    800029ba:	00000097          	auipc	ra,0x0
    800029be:	a6c080e7          	jalr	-1428(ra) # 80002426 <killed>
    800029c2:	e94d                	bnez	a0,80002a74 <usertrap+0x16c>
  usertrapret();
    800029c4:	00000097          	auipc	ra,0x0
    800029c8:	dc6080e7          	jalr	-570(ra) # 8000278a <usertrapret>
}
    800029cc:	70a2                	ld	ra,40(sp)
    800029ce:	7402                	ld	s0,32(sp)
    800029d0:	64e2                	ld	s1,24(sp)
    800029d2:	6942                	ld	s2,16(sp)
    800029d4:	69a2                	ld	s3,8(sp)
    800029d6:	6145                	addi	sp,sp,48
    800029d8:	8082                	ret
      exit(-1);
    800029da:	557d                	li	a0,-1
    800029dc:	00000097          	auipc	ra,0x0
    800029e0:	8d6080e7          	jalr	-1834(ra) # 800022b2 <exit>
    800029e4:	bf65                	j	8000299c <usertrap+0x94>
        char *mem = kalloc();
    800029e6:	ffffe097          	auipc	ra,0xffffe
    800029ea:	114080e7          	jalr	276(ra) # 80000afa <kalloc>
    800029ee:	89aa                	mv	s3,a0
        if (mem == 0) {
    800029f0:	c91d                	beqz	a0,80002a26 <usertrap+0x11e>
          memset(mem, 0, PGSIZE);
    800029f2:	6605                	lui	a2,0x1
    800029f4:	4581                	li	a1,0
    800029f6:	ffffe097          	auipc	ra,0xffffe
    800029fa:	2f0080e7          	jalr	752(ra) # 80000ce6 <memset>
          if(mappages(p->pagetable, PGROUNDDOWN(v), PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_U) != 0) {
    800029fe:	4759                	li	a4,22
    80002a00:	86ce                	mv	a3,s3
    80002a02:	6605                	lui	a2,0x1
    80002a04:	75fd                	lui	a1,0xfffff
    80002a06:	00b975b3          	and	a1,s2,a1
    80002a0a:	68a8                	ld	a0,80(s1)
    80002a0c:	ffffe097          	auipc	ra,0xffffe
    80002a10:	66c080e7          	jalr	1644(ra) # 80001078 <mappages>
    80002a14:	d155                	beqz	a0,800029b8 <usertrap+0xb0>
            kfree(mem);
    80002a16:	854e                	mv	a0,s3
    80002a18:	ffffe097          	auipc	ra,0xffffe
    80002a1c:	fe6080e7          	jalr	-26(ra) # 800009fe <kfree>
            p->killed = 1;
    80002a20:	4785                	li	a5,1
    80002a22:	d49c                	sw	a5,40(s1)
    80002a24:	bf51                	j	800029b8 <usertrap+0xb0>
          p->killed = 1;
    80002a26:	4785                	li	a5,1
    80002a28:	d49c                	sw	a5,40(s1)
    80002a2a:	b779                	j	800029b8 <usertrap+0xb0>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a2c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a30:	5890                	lw	a2,48(s1)
    80002a32:	00006517          	auipc	a0,0x6
    80002a36:	8c650513          	addi	a0,a0,-1850 # 800082f8 <states.1724+0x78>
    80002a3a:	ffffe097          	auipc	ra,0xffffe
    80002a3e:	b54080e7          	jalr	-1196(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a42:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a46:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a4a:	00006517          	auipc	a0,0x6
    80002a4e:	8de50513          	addi	a0,a0,-1826 # 80008328 <states.1724+0xa8>
    80002a52:	ffffe097          	auipc	ra,0xffffe
    80002a56:	b3c080e7          	jalr	-1220(ra) # 8000058e <printf>
    setkilled(p);
    80002a5a:	8526                	mv	a0,s1
    80002a5c:	00000097          	auipc	ra,0x0
    80002a60:	99e080e7          	jalr	-1634(ra) # 800023fa <setkilled>
    80002a64:	bf91                	j	800029b8 <usertrap+0xb0>
  if(killed(p))
    80002a66:	8526                	mv	a0,s1
    80002a68:	00000097          	auipc	ra,0x0
    80002a6c:	9be080e7          	jalr	-1602(ra) # 80002426 <killed>
    80002a70:	c901                	beqz	a0,80002a80 <usertrap+0x178>
    80002a72:	a011                	j	80002a76 <usertrap+0x16e>
    80002a74:	4901                	li	s2,0
    exit(-1);
    80002a76:	557d                	li	a0,-1
    80002a78:	00000097          	auipc	ra,0x0
    80002a7c:	83a080e7          	jalr	-1990(ra) # 800022b2 <exit>
  if(which_dev == 2)
    80002a80:	4789                	li	a5,2
    80002a82:	f4f911e3          	bne	s2,a5,800029c4 <usertrap+0xbc>
    yield();
    80002a86:	fffff097          	auipc	ra,0xfffff
    80002a8a:	6bc080e7          	jalr	1724(ra) # 80002142 <yield>
    80002a8e:	bf1d                	j	800029c4 <usertrap+0xbc>

0000000080002a90 <kerneltrap>:
{
    80002a90:	7179                	addi	sp,sp,-48
    80002a92:	f406                	sd	ra,40(sp)
    80002a94:	f022                	sd	s0,32(sp)
    80002a96:	ec26                	sd	s1,24(sp)
    80002a98:	e84a                	sd	s2,16(sp)
    80002a9a:	e44e                	sd	s3,8(sp)
    80002a9c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a9e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aa2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aa6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002aaa:	1004f793          	andi	a5,s1,256
    80002aae:	cb85                	beqz	a5,80002ade <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ab0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ab4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002ab6:	ef85                	bnez	a5,80002aee <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ab8:	00000097          	auipc	ra,0x0
    80002abc:	dae080e7          	jalr	-594(ra) # 80002866 <devintr>
    80002ac0:	cd1d                	beqz	a0,80002afe <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ac2:	4789                	li	a5,2
    80002ac4:	06f50a63          	beq	a0,a5,80002b38 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ac8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002acc:	10049073          	csrw	sstatus,s1
}
    80002ad0:	70a2                	ld	ra,40(sp)
    80002ad2:	7402                	ld	s0,32(sp)
    80002ad4:	64e2                	ld	s1,24(sp)
    80002ad6:	6942                	ld	s2,16(sp)
    80002ad8:	69a2                	ld	s3,8(sp)
    80002ada:	6145                	addi	sp,sp,48
    80002adc:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ade:	00006517          	auipc	a0,0x6
    80002ae2:	86a50513          	addi	a0,a0,-1942 # 80008348 <states.1724+0xc8>
    80002ae6:	ffffe097          	auipc	ra,0xffffe
    80002aea:	a5e080e7          	jalr	-1442(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002aee:	00006517          	auipc	a0,0x6
    80002af2:	88250513          	addi	a0,a0,-1918 # 80008370 <states.1724+0xf0>
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	a4e080e7          	jalr	-1458(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002afe:	85ce                	mv	a1,s3
    80002b00:	00006517          	auipc	a0,0x6
    80002b04:	89050513          	addi	a0,a0,-1904 # 80008390 <states.1724+0x110>
    80002b08:	ffffe097          	auipc	ra,0xffffe
    80002b0c:	a86080e7          	jalr	-1402(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b10:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b14:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b18:	00006517          	auipc	a0,0x6
    80002b1c:	88850513          	addi	a0,a0,-1912 # 800083a0 <states.1724+0x120>
    80002b20:	ffffe097          	auipc	ra,0xffffe
    80002b24:	a6e080e7          	jalr	-1426(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002b28:	00006517          	auipc	a0,0x6
    80002b2c:	89050513          	addi	a0,a0,-1904 # 800083b8 <states.1724+0x138>
    80002b30:	ffffe097          	auipc	ra,0xffffe
    80002b34:	a14080e7          	jalr	-1516(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b38:	fffff097          	auipc	ra,0xfffff
    80002b3c:	fa2080e7          	jalr	-94(ra) # 80001ada <myproc>
    80002b40:	d541                	beqz	a0,80002ac8 <kerneltrap+0x38>
    80002b42:	fffff097          	auipc	ra,0xfffff
    80002b46:	f98080e7          	jalr	-104(ra) # 80001ada <myproc>
    80002b4a:	4d18                	lw	a4,24(a0)
    80002b4c:	4791                	li	a5,4
    80002b4e:	f6f71de3          	bne	a4,a5,80002ac8 <kerneltrap+0x38>
    yield();
    80002b52:	fffff097          	auipc	ra,0xfffff
    80002b56:	5f0080e7          	jalr	1520(ra) # 80002142 <yield>
    80002b5a:	b7bd                	j	80002ac8 <kerneltrap+0x38>

0000000080002b5c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b5c:	1101                	addi	sp,sp,-32
    80002b5e:	ec06                	sd	ra,24(sp)
    80002b60:	e822                	sd	s0,16(sp)
    80002b62:	e426                	sd	s1,8(sp)
    80002b64:	1000                	addi	s0,sp,32
    80002b66:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b68:	fffff097          	auipc	ra,0xfffff
    80002b6c:	f72080e7          	jalr	-142(ra) # 80001ada <myproc>
  switch (n) {
    80002b70:	4795                	li	a5,5
    80002b72:	0497e163          	bltu	a5,s1,80002bb4 <argraw+0x58>
    80002b76:	048a                	slli	s1,s1,0x2
    80002b78:	00006717          	auipc	a4,0x6
    80002b7c:	87870713          	addi	a4,a4,-1928 # 800083f0 <states.1724+0x170>
    80002b80:	94ba                	add	s1,s1,a4
    80002b82:	409c                	lw	a5,0(s1)
    80002b84:	97ba                	add	a5,a5,a4
    80002b86:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b88:	6d3c                	ld	a5,88(a0)
    80002b8a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b8c:	60e2                	ld	ra,24(sp)
    80002b8e:	6442                	ld	s0,16(sp)
    80002b90:	64a2                	ld	s1,8(sp)
    80002b92:	6105                	addi	sp,sp,32
    80002b94:	8082                	ret
    return p->trapframe->a1;
    80002b96:	6d3c                	ld	a5,88(a0)
    80002b98:	7fa8                	ld	a0,120(a5)
    80002b9a:	bfcd                	j	80002b8c <argraw+0x30>
    return p->trapframe->a2;
    80002b9c:	6d3c                	ld	a5,88(a0)
    80002b9e:	63c8                	ld	a0,128(a5)
    80002ba0:	b7f5                	j	80002b8c <argraw+0x30>
    return p->trapframe->a3;
    80002ba2:	6d3c                	ld	a5,88(a0)
    80002ba4:	67c8                	ld	a0,136(a5)
    80002ba6:	b7dd                	j	80002b8c <argraw+0x30>
    return p->trapframe->a4;
    80002ba8:	6d3c                	ld	a5,88(a0)
    80002baa:	6bc8                	ld	a0,144(a5)
    80002bac:	b7c5                	j	80002b8c <argraw+0x30>
    return p->trapframe->a5;
    80002bae:	6d3c                	ld	a5,88(a0)
    80002bb0:	6fc8                	ld	a0,152(a5)
    80002bb2:	bfe9                	j	80002b8c <argraw+0x30>
  panic("argraw");
    80002bb4:	00006517          	auipc	a0,0x6
    80002bb8:	81450513          	addi	a0,a0,-2028 # 800083c8 <states.1724+0x148>
    80002bbc:	ffffe097          	auipc	ra,0xffffe
    80002bc0:	988080e7          	jalr	-1656(ra) # 80000544 <panic>

0000000080002bc4 <fetchaddr>:
{
    80002bc4:	1101                	addi	sp,sp,-32
    80002bc6:	ec06                	sd	ra,24(sp)
    80002bc8:	e822                	sd	s0,16(sp)
    80002bca:	e426                	sd	s1,8(sp)
    80002bcc:	e04a                	sd	s2,0(sp)
    80002bce:	1000                	addi	s0,sp,32
    80002bd0:	84aa                	mv	s1,a0
    80002bd2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002bd4:	fffff097          	auipc	ra,0xfffff
    80002bd8:	f06080e7          	jalr	-250(ra) # 80001ada <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002bdc:	653c                	ld	a5,72(a0)
    80002bde:	02f4f863          	bgeu	s1,a5,80002c0e <fetchaddr+0x4a>
    80002be2:	00848713          	addi	a4,s1,8
    80002be6:	02e7e663          	bltu	a5,a4,80002c12 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002bea:	46a1                	li	a3,8
    80002bec:	8626                	mv	a2,s1
    80002bee:	85ca                	mv	a1,s2
    80002bf0:	6928                	ld	a0,80(a0)
    80002bf2:	fffff097          	auipc	ra,0xfffff
    80002bf6:	b46080e7          	jalr	-1210(ra) # 80001738 <copyin>
    80002bfa:	00a03533          	snez	a0,a0
    80002bfe:	40a00533          	neg	a0,a0
}
    80002c02:	60e2                	ld	ra,24(sp)
    80002c04:	6442                	ld	s0,16(sp)
    80002c06:	64a2                	ld	s1,8(sp)
    80002c08:	6902                	ld	s2,0(sp)
    80002c0a:	6105                	addi	sp,sp,32
    80002c0c:	8082                	ret
    return -1;
    80002c0e:	557d                	li	a0,-1
    80002c10:	bfcd                	j	80002c02 <fetchaddr+0x3e>
    80002c12:	557d                	li	a0,-1
    80002c14:	b7fd                	j	80002c02 <fetchaddr+0x3e>

0000000080002c16 <fetchstr>:
{
    80002c16:	7179                	addi	sp,sp,-48
    80002c18:	f406                	sd	ra,40(sp)
    80002c1a:	f022                	sd	s0,32(sp)
    80002c1c:	ec26                	sd	s1,24(sp)
    80002c1e:	e84a                	sd	s2,16(sp)
    80002c20:	e44e                	sd	s3,8(sp)
    80002c22:	1800                	addi	s0,sp,48
    80002c24:	892a                	mv	s2,a0
    80002c26:	84ae                	mv	s1,a1
    80002c28:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c2a:	fffff097          	auipc	ra,0xfffff
    80002c2e:	eb0080e7          	jalr	-336(ra) # 80001ada <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002c32:	86ce                	mv	a3,s3
    80002c34:	864a                	mv	a2,s2
    80002c36:	85a6                	mv	a1,s1
    80002c38:	6928                	ld	a0,80(a0)
    80002c3a:	fffff097          	auipc	ra,0xfffff
    80002c3e:	b8a080e7          	jalr	-1142(ra) # 800017c4 <copyinstr>
    80002c42:	00054e63          	bltz	a0,80002c5e <fetchstr+0x48>
  return strlen(buf);
    80002c46:	8526                	mv	a0,s1
    80002c48:	ffffe097          	auipc	ra,0xffffe
    80002c4c:	222080e7          	jalr	546(ra) # 80000e6a <strlen>
}
    80002c50:	70a2                	ld	ra,40(sp)
    80002c52:	7402                	ld	s0,32(sp)
    80002c54:	64e2                	ld	s1,24(sp)
    80002c56:	6942                	ld	s2,16(sp)
    80002c58:	69a2                	ld	s3,8(sp)
    80002c5a:	6145                	addi	sp,sp,48
    80002c5c:	8082                	ret
    return -1;
    80002c5e:	557d                	li	a0,-1
    80002c60:	bfc5                	j	80002c50 <fetchstr+0x3a>

0000000080002c62 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002c62:	1101                	addi	sp,sp,-32
    80002c64:	ec06                	sd	ra,24(sp)
    80002c66:	e822                	sd	s0,16(sp)
    80002c68:	e426                	sd	s1,8(sp)
    80002c6a:	1000                	addi	s0,sp,32
    80002c6c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c6e:	00000097          	auipc	ra,0x0
    80002c72:	eee080e7          	jalr	-274(ra) # 80002b5c <argraw>
    80002c76:	c088                	sw	a0,0(s1)
}
    80002c78:	60e2                	ld	ra,24(sp)
    80002c7a:	6442                	ld	s0,16(sp)
    80002c7c:	64a2                	ld	s1,8(sp)
    80002c7e:	6105                	addi	sp,sp,32
    80002c80:	8082                	ret

0000000080002c82 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002c82:	1101                	addi	sp,sp,-32
    80002c84:	ec06                	sd	ra,24(sp)
    80002c86:	e822                	sd	s0,16(sp)
    80002c88:	e426                	sd	s1,8(sp)
    80002c8a:	1000                	addi	s0,sp,32
    80002c8c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c8e:	00000097          	auipc	ra,0x0
    80002c92:	ece080e7          	jalr	-306(ra) # 80002b5c <argraw>
    80002c96:	e088                	sd	a0,0(s1)
}
    80002c98:	60e2                	ld	ra,24(sp)
    80002c9a:	6442                	ld	s0,16(sp)
    80002c9c:	64a2                	ld	s1,8(sp)
    80002c9e:	6105                	addi	sp,sp,32
    80002ca0:	8082                	ret

0000000080002ca2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ca2:	7179                	addi	sp,sp,-48
    80002ca4:	f406                	sd	ra,40(sp)
    80002ca6:	f022                	sd	s0,32(sp)
    80002ca8:	ec26                	sd	s1,24(sp)
    80002caa:	e84a                	sd	s2,16(sp)
    80002cac:	1800                	addi	s0,sp,48
    80002cae:	84ae                	mv	s1,a1
    80002cb0:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002cb2:	fd840593          	addi	a1,s0,-40
    80002cb6:	00000097          	auipc	ra,0x0
    80002cba:	fcc080e7          	jalr	-52(ra) # 80002c82 <argaddr>
  return fetchstr(addr, buf, max);
    80002cbe:	864a                	mv	a2,s2
    80002cc0:	85a6                	mv	a1,s1
    80002cc2:	fd843503          	ld	a0,-40(s0)
    80002cc6:	00000097          	auipc	ra,0x0
    80002cca:	f50080e7          	jalr	-176(ra) # 80002c16 <fetchstr>
}
    80002cce:	70a2                	ld	ra,40(sp)
    80002cd0:	7402                	ld	s0,32(sp)
    80002cd2:	64e2                	ld	s1,24(sp)
    80002cd4:	6942                	ld	s2,16(sp)
    80002cd6:	6145                	addi	sp,sp,48
    80002cd8:	8082                	ret

0000000080002cda <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002cda:	1101                	addi	sp,sp,-32
    80002cdc:	ec06                	sd	ra,24(sp)
    80002cde:	e822                	sd	s0,16(sp)
    80002ce0:	e426                	sd	s1,8(sp)
    80002ce2:	e04a                	sd	s2,0(sp)
    80002ce4:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002ce6:	fffff097          	auipc	ra,0xfffff
    80002cea:	df4080e7          	jalr	-524(ra) # 80001ada <myproc>
    80002cee:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002cf0:	05853903          	ld	s2,88(a0)
    80002cf4:	0a893783          	ld	a5,168(s2)
    80002cf8:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cfc:	37fd                	addiw	a5,a5,-1
    80002cfe:	4751                	li	a4,20
    80002d00:	00f76f63          	bltu	a4,a5,80002d1e <syscall+0x44>
    80002d04:	00369713          	slli	a4,a3,0x3
    80002d08:	00005797          	auipc	a5,0x5
    80002d0c:	70078793          	addi	a5,a5,1792 # 80008408 <syscalls>
    80002d10:	97ba                	add	a5,a5,a4
    80002d12:	639c                	ld	a5,0(a5)
    80002d14:	c789                	beqz	a5,80002d1e <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002d16:	9782                	jalr	a5
    80002d18:	06a93823          	sd	a0,112(s2)
    80002d1c:	a839                	j	80002d3a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d1e:	15848613          	addi	a2,s1,344
    80002d22:	588c                	lw	a1,48(s1)
    80002d24:	00005517          	auipc	a0,0x5
    80002d28:	6ac50513          	addi	a0,a0,1708 # 800083d0 <states.1724+0x150>
    80002d2c:	ffffe097          	auipc	ra,0xffffe
    80002d30:	862080e7          	jalr	-1950(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d34:	6cbc                	ld	a5,88(s1)
    80002d36:	577d                	li	a4,-1
    80002d38:	fbb8                	sd	a4,112(a5)
  }
}
    80002d3a:	60e2                	ld	ra,24(sp)
    80002d3c:	6442                	ld	s0,16(sp)
    80002d3e:	64a2                	ld	s1,8(sp)
    80002d40:	6902                	ld	s2,0(sp)
    80002d42:	6105                	addi	sp,sp,32
    80002d44:	8082                	ret

0000000080002d46 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d46:	1101                	addi	sp,sp,-32
    80002d48:	ec06                	sd	ra,24(sp)
    80002d4a:	e822                	sd	s0,16(sp)
    80002d4c:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002d4e:	fec40593          	addi	a1,s0,-20
    80002d52:	4501                	li	a0,0
    80002d54:	00000097          	auipc	ra,0x0
    80002d58:	f0e080e7          	jalr	-242(ra) # 80002c62 <argint>
  exit(n);
    80002d5c:	fec42503          	lw	a0,-20(s0)
    80002d60:	fffff097          	auipc	ra,0xfffff
    80002d64:	552080e7          	jalr	1362(ra) # 800022b2 <exit>
  return 0;  // not reached
}
    80002d68:	4501                	li	a0,0
    80002d6a:	60e2                	ld	ra,24(sp)
    80002d6c:	6442                	ld	s0,16(sp)
    80002d6e:	6105                	addi	sp,sp,32
    80002d70:	8082                	ret

0000000080002d72 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d72:	1141                	addi	sp,sp,-16
    80002d74:	e406                	sd	ra,8(sp)
    80002d76:	e022                	sd	s0,0(sp)
    80002d78:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d7a:	fffff097          	auipc	ra,0xfffff
    80002d7e:	d60080e7          	jalr	-672(ra) # 80001ada <myproc>
}
    80002d82:	5908                	lw	a0,48(a0)
    80002d84:	60a2                	ld	ra,8(sp)
    80002d86:	6402                	ld	s0,0(sp)
    80002d88:	0141                	addi	sp,sp,16
    80002d8a:	8082                	ret

0000000080002d8c <sys_fork>:

uint64
sys_fork(void)
{
    80002d8c:	1141                	addi	sp,sp,-16
    80002d8e:	e406                	sd	ra,8(sp)
    80002d90:	e022                	sd	s0,0(sp)
    80002d92:	0800                	addi	s0,sp,16
  return fork();
    80002d94:	fffff097          	auipc	ra,0xfffff
    80002d98:	0fc080e7          	jalr	252(ra) # 80001e90 <fork>
}
    80002d9c:	60a2                	ld	ra,8(sp)
    80002d9e:	6402                	ld	s0,0(sp)
    80002da0:	0141                	addi	sp,sp,16
    80002da2:	8082                	ret

0000000080002da4 <sys_wait>:

uint64
sys_wait(void)
{
    80002da4:	1101                	addi	sp,sp,-32
    80002da6:	ec06                	sd	ra,24(sp)
    80002da8:	e822                	sd	s0,16(sp)
    80002daa:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002dac:	fe840593          	addi	a1,s0,-24
    80002db0:	4501                	li	a0,0
    80002db2:	00000097          	auipc	ra,0x0
    80002db6:	ed0080e7          	jalr	-304(ra) # 80002c82 <argaddr>
  return wait(p);
    80002dba:	fe843503          	ld	a0,-24(s0)
    80002dbe:	fffff097          	auipc	ra,0xfffff
    80002dc2:	69a080e7          	jalr	1690(ra) # 80002458 <wait>
}
    80002dc6:	60e2                	ld	ra,24(sp)
    80002dc8:	6442                	ld	s0,16(sp)
    80002dca:	6105                	addi	sp,sp,32
    80002dcc:	8082                	ret

0000000080002dce <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002dce:	7179                	addi	sp,sp,-48
    80002dd0:	f406                	sd	ra,40(sp)
    80002dd2:	f022                	sd	s0,32(sp)
    80002dd4:	ec26                	sd	s1,24(sp)
    80002dd6:	1800                	addi	s0,sp,48
  //   return -1;
  // return addr;
  
  int addr;
  int n;
  argint(0, &n);
    80002dd8:	fdc40593          	addi	a1,s0,-36
    80002ddc:	4501                	li	a0,0
    80002dde:	00000097          	auipc	ra,0x0
    80002de2:	e84080e7          	jalr	-380(ra) # 80002c62 <argint>
  addr = myproc()->sz;
    80002de6:	fffff097          	auipc	ra,0xfffff
    80002dea:	cf4080e7          	jalr	-780(ra) # 80001ada <myproc>
    80002dee:	4524                	lw	s1,72(a0)
  if (n > 0) {
    80002df0:	fdc42503          	lw	a0,-36(s0)
    80002df4:	02a05163          	blez	a0,80002e16 <sys_sbrk+0x48>
    myproc()->sz += n;
    80002df8:	fffff097          	auipc	ra,0xfffff
    80002dfc:	ce2080e7          	jalr	-798(ra) # 80001ada <myproc>
    80002e00:	fdc42703          	lw	a4,-36(s0)
    80002e04:	653c                	ld	a5,72(a0)
    80002e06:	97ba                	add	a5,a5,a4
    80002e08:	e53c                	sd	a5,72(a0)
   } else {
      if(growproc(n) < 0){
       return -1;
      }
   }
  return addr;
    80002e0a:	8526                	mv	a0,s1
}
    80002e0c:	70a2                	ld	ra,40(sp)
    80002e0e:	7402                	ld	s0,32(sp)
    80002e10:	64e2                	ld	s1,24(sp)
    80002e12:	6145                	addi	sp,sp,48
    80002e14:	8082                	ret
      if(growproc(n) < 0){
    80002e16:	fffff097          	auipc	ra,0xfffff
    80002e1a:	01e080e7          	jalr	30(ra) # 80001e34 <growproc>
    80002e1e:	fe0556e3          	bgez	a0,80002e0a <sys_sbrk+0x3c>
       return -1;
    80002e22:	557d                	li	a0,-1
    80002e24:	b7e5                	j	80002e0c <sys_sbrk+0x3e>

0000000080002e26 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e26:	7139                	addi	sp,sp,-64
    80002e28:	fc06                	sd	ra,56(sp)
    80002e2a:	f822                	sd	s0,48(sp)
    80002e2c:	f426                	sd	s1,40(sp)
    80002e2e:	f04a                	sd	s2,32(sp)
    80002e30:	ec4e                	sd	s3,24(sp)
    80002e32:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002e34:	fcc40593          	addi	a1,s0,-52
    80002e38:	4501                	li	a0,0
    80002e3a:	00000097          	auipc	ra,0x0
    80002e3e:	e28080e7          	jalr	-472(ra) # 80002c62 <argint>
  acquire(&tickslock);
    80002e42:	00014517          	auipc	a0,0x14
    80002e46:	ade50513          	addi	a0,a0,-1314 # 80016920 <tickslock>
    80002e4a:	ffffe097          	auipc	ra,0xffffe
    80002e4e:	da0080e7          	jalr	-608(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002e52:	00006917          	auipc	s2,0x6
    80002e56:	a2e92903          	lw	s2,-1490(s2) # 80008880 <ticks>
  while(ticks - ticks0 < n){
    80002e5a:	fcc42783          	lw	a5,-52(s0)
    80002e5e:	cf9d                	beqz	a5,80002e9c <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e60:	00014997          	auipc	s3,0x14
    80002e64:	ac098993          	addi	s3,s3,-1344 # 80016920 <tickslock>
    80002e68:	00006497          	auipc	s1,0x6
    80002e6c:	a1848493          	addi	s1,s1,-1512 # 80008880 <ticks>
    if(killed(myproc())){
    80002e70:	fffff097          	auipc	ra,0xfffff
    80002e74:	c6a080e7          	jalr	-918(ra) # 80001ada <myproc>
    80002e78:	fffff097          	auipc	ra,0xfffff
    80002e7c:	5ae080e7          	jalr	1454(ra) # 80002426 <killed>
    80002e80:	ed15                	bnez	a0,80002ebc <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002e82:	85ce                	mv	a1,s3
    80002e84:	8526                	mv	a0,s1
    80002e86:	fffff097          	auipc	ra,0xfffff
    80002e8a:	2f8080e7          	jalr	760(ra) # 8000217e <sleep>
  while(ticks - ticks0 < n){
    80002e8e:	409c                	lw	a5,0(s1)
    80002e90:	412787bb          	subw	a5,a5,s2
    80002e94:	fcc42703          	lw	a4,-52(s0)
    80002e98:	fce7ece3          	bltu	a5,a4,80002e70 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002e9c:	00014517          	auipc	a0,0x14
    80002ea0:	a8450513          	addi	a0,a0,-1404 # 80016920 <tickslock>
    80002ea4:	ffffe097          	auipc	ra,0xffffe
    80002ea8:	dfa080e7          	jalr	-518(ra) # 80000c9e <release>
  return 0;
    80002eac:	4501                	li	a0,0
}
    80002eae:	70e2                	ld	ra,56(sp)
    80002eb0:	7442                	ld	s0,48(sp)
    80002eb2:	74a2                	ld	s1,40(sp)
    80002eb4:	7902                	ld	s2,32(sp)
    80002eb6:	69e2                	ld	s3,24(sp)
    80002eb8:	6121                	addi	sp,sp,64
    80002eba:	8082                	ret
      release(&tickslock);
    80002ebc:	00014517          	auipc	a0,0x14
    80002ec0:	a6450513          	addi	a0,a0,-1436 # 80016920 <tickslock>
    80002ec4:	ffffe097          	auipc	ra,0xffffe
    80002ec8:	dda080e7          	jalr	-550(ra) # 80000c9e <release>
      return -1;
    80002ecc:	557d                	li	a0,-1
    80002ece:	b7c5                	j	80002eae <sys_sleep+0x88>

0000000080002ed0 <sys_kill>:

uint64
sys_kill(void)
{
    80002ed0:	1101                	addi	sp,sp,-32
    80002ed2:	ec06                	sd	ra,24(sp)
    80002ed4:	e822                	sd	s0,16(sp)
    80002ed6:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002ed8:	fec40593          	addi	a1,s0,-20
    80002edc:	4501                	li	a0,0
    80002ede:	00000097          	auipc	ra,0x0
    80002ee2:	d84080e7          	jalr	-636(ra) # 80002c62 <argint>
  return kill(pid);
    80002ee6:	fec42503          	lw	a0,-20(s0)
    80002eea:	fffff097          	auipc	ra,0xfffff
    80002eee:	49e080e7          	jalr	1182(ra) # 80002388 <kill>
}
    80002ef2:	60e2                	ld	ra,24(sp)
    80002ef4:	6442                	ld	s0,16(sp)
    80002ef6:	6105                	addi	sp,sp,32
    80002ef8:	8082                	ret

0000000080002efa <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002efa:	1101                	addi	sp,sp,-32
    80002efc:	ec06                	sd	ra,24(sp)
    80002efe:	e822                	sd	s0,16(sp)
    80002f00:	e426                	sd	s1,8(sp)
    80002f02:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f04:	00014517          	auipc	a0,0x14
    80002f08:	a1c50513          	addi	a0,a0,-1508 # 80016920 <tickslock>
    80002f0c:	ffffe097          	auipc	ra,0xffffe
    80002f10:	cde080e7          	jalr	-802(ra) # 80000bea <acquire>
  xticks = ticks;
    80002f14:	00006497          	auipc	s1,0x6
    80002f18:	96c4a483          	lw	s1,-1684(s1) # 80008880 <ticks>
  release(&tickslock);
    80002f1c:	00014517          	auipc	a0,0x14
    80002f20:	a0450513          	addi	a0,a0,-1532 # 80016920 <tickslock>
    80002f24:	ffffe097          	auipc	ra,0xffffe
    80002f28:	d7a080e7          	jalr	-646(ra) # 80000c9e <release>
  return xticks;
}
    80002f2c:	02049513          	slli	a0,s1,0x20
    80002f30:	9101                	srli	a0,a0,0x20
    80002f32:	60e2                	ld	ra,24(sp)
    80002f34:	6442                	ld	s0,16(sp)
    80002f36:	64a2                	ld	s1,8(sp)
    80002f38:	6105                	addi	sp,sp,32
    80002f3a:	8082                	ret

0000000080002f3c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f3c:	7179                	addi	sp,sp,-48
    80002f3e:	f406                	sd	ra,40(sp)
    80002f40:	f022                	sd	s0,32(sp)
    80002f42:	ec26                	sd	s1,24(sp)
    80002f44:	e84a                	sd	s2,16(sp)
    80002f46:	e44e                	sd	s3,8(sp)
    80002f48:	e052                	sd	s4,0(sp)
    80002f4a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f4c:	00005597          	auipc	a1,0x5
    80002f50:	56c58593          	addi	a1,a1,1388 # 800084b8 <syscalls+0xb0>
    80002f54:	00014517          	auipc	a0,0x14
    80002f58:	9e450513          	addi	a0,a0,-1564 # 80016938 <bcache>
    80002f5c:	ffffe097          	auipc	ra,0xffffe
    80002f60:	bfe080e7          	jalr	-1026(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f64:	0001c797          	auipc	a5,0x1c
    80002f68:	9d478793          	addi	a5,a5,-1580 # 8001e938 <bcache+0x8000>
    80002f6c:	0001c717          	auipc	a4,0x1c
    80002f70:	c3470713          	addi	a4,a4,-972 # 8001eba0 <bcache+0x8268>
    80002f74:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f78:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f7c:	00014497          	auipc	s1,0x14
    80002f80:	9d448493          	addi	s1,s1,-1580 # 80016950 <bcache+0x18>
    b->next = bcache.head.next;
    80002f84:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f86:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f88:	00005a17          	auipc	s4,0x5
    80002f8c:	538a0a13          	addi	s4,s4,1336 # 800084c0 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002f90:	2b893783          	ld	a5,696(s2)
    80002f94:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f96:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f9a:	85d2                	mv	a1,s4
    80002f9c:	01048513          	addi	a0,s1,16
    80002fa0:	00001097          	auipc	ra,0x1
    80002fa4:	4c4080e7          	jalr	1220(ra) # 80004464 <initsleeplock>
    bcache.head.next->prev = b;
    80002fa8:	2b893783          	ld	a5,696(s2)
    80002fac:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002fae:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fb2:	45848493          	addi	s1,s1,1112
    80002fb6:	fd349de3          	bne	s1,s3,80002f90 <binit+0x54>
  }
}
    80002fba:	70a2                	ld	ra,40(sp)
    80002fbc:	7402                	ld	s0,32(sp)
    80002fbe:	64e2                	ld	s1,24(sp)
    80002fc0:	6942                	ld	s2,16(sp)
    80002fc2:	69a2                	ld	s3,8(sp)
    80002fc4:	6a02                	ld	s4,0(sp)
    80002fc6:	6145                	addi	sp,sp,48
    80002fc8:	8082                	ret

0000000080002fca <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fca:	7179                	addi	sp,sp,-48
    80002fcc:	f406                	sd	ra,40(sp)
    80002fce:	f022                	sd	s0,32(sp)
    80002fd0:	ec26                	sd	s1,24(sp)
    80002fd2:	e84a                	sd	s2,16(sp)
    80002fd4:	e44e                	sd	s3,8(sp)
    80002fd6:	1800                	addi	s0,sp,48
    80002fd8:	89aa                	mv	s3,a0
    80002fda:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fdc:	00014517          	auipc	a0,0x14
    80002fe0:	95c50513          	addi	a0,a0,-1700 # 80016938 <bcache>
    80002fe4:	ffffe097          	auipc	ra,0xffffe
    80002fe8:	c06080e7          	jalr	-1018(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fec:	0001c497          	auipc	s1,0x1c
    80002ff0:	c044b483          	ld	s1,-1020(s1) # 8001ebf0 <bcache+0x82b8>
    80002ff4:	0001c797          	auipc	a5,0x1c
    80002ff8:	bac78793          	addi	a5,a5,-1108 # 8001eba0 <bcache+0x8268>
    80002ffc:	02f48f63          	beq	s1,a5,8000303a <bread+0x70>
    80003000:	873e                	mv	a4,a5
    80003002:	a021                	j	8000300a <bread+0x40>
    80003004:	68a4                	ld	s1,80(s1)
    80003006:	02e48a63          	beq	s1,a4,8000303a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000300a:	449c                	lw	a5,8(s1)
    8000300c:	ff379ce3          	bne	a5,s3,80003004 <bread+0x3a>
    80003010:	44dc                	lw	a5,12(s1)
    80003012:	ff2799e3          	bne	a5,s2,80003004 <bread+0x3a>
      b->refcnt++;
    80003016:	40bc                	lw	a5,64(s1)
    80003018:	2785                	addiw	a5,a5,1
    8000301a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000301c:	00014517          	auipc	a0,0x14
    80003020:	91c50513          	addi	a0,a0,-1764 # 80016938 <bcache>
    80003024:	ffffe097          	auipc	ra,0xffffe
    80003028:	c7a080e7          	jalr	-902(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    8000302c:	01048513          	addi	a0,s1,16
    80003030:	00001097          	auipc	ra,0x1
    80003034:	46e080e7          	jalr	1134(ra) # 8000449e <acquiresleep>
      return b;
    80003038:	a8b9                	j	80003096 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000303a:	0001c497          	auipc	s1,0x1c
    8000303e:	bae4b483          	ld	s1,-1106(s1) # 8001ebe8 <bcache+0x82b0>
    80003042:	0001c797          	auipc	a5,0x1c
    80003046:	b5e78793          	addi	a5,a5,-1186 # 8001eba0 <bcache+0x8268>
    8000304a:	00f48863          	beq	s1,a5,8000305a <bread+0x90>
    8000304e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003050:	40bc                	lw	a5,64(s1)
    80003052:	cf81                	beqz	a5,8000306a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003054:	64a4                	ld	s1,72(s1)
    80003056:	fee49de3          	bne	s1,a4,80003050 <bread+0x86>
  panic("bget: no buffers");
    8000305a:	00005517          	auipc	a0,0x5
    8000305e:	46e50513          	addi	a0,a0,1134 # 800084c8 <syscalls+0xc0>
    80003062:	ffffd097          	auipc	ra,0xffffd
    80003066:	4e2080e7          	jalr	1250(ra) # 80000544 <panic>
      b->dev = dev;
    8000306a:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000306e:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003072:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003076:	4785                	li	a5,1
    80003078:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000307a:	00014517          	auipc	a0,0x14
    8000307e:	8be50513          	addi	a0,a0,-1858 # 80016938 <bcache>
    80003082:	ffffe097          	auipc	ra,0xffffe
    80003086:	c1c080e7          	jalr	-996(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    8000308a:	01048513          	addi	a0,s1,16
    8000308e:	00001097          	auipc	ra,0x1
    80003092:	410080e7          	jalr	1040(ra) # 8000449e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003096:	409c                	lw	a5,0(s1)
    80003098:	cb89                	beqz	a5,800030aa <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000309a:	8526                	mv	a0,s1
    8000309c:	70a2                	ld	ra,40(sp)
    8000309e:	7402                	ld	s0,32(sp)
    800030a0:	64e2                	ld	s1,24(sp)
    800030a2:	6942                	ld	s2,16(sp)
    800030a4:	69a2                	ld	s3,8(sp)
    800030a6:	6145                	addi	sp,sp,48
    800030a8:	8082                	ret
    virtio_disk_rw(b, 0);
    800030aa:	4581                	li	a1,0
    800030ac:	8526                	mv	a0,s1
    800030ae:	00003097          	auipc	ra,0x3
    800030b2:	fda080e7          	jalr	-38(ra) # 80006088 <virtio_disk_rw>
    b->valid = 1;
    800030b6:	4785                	li	a5,1
    800030b8:	c09c                	sw	a5,0(s1)
  return b;
    800030ba:	b7c5                	j	8000309a <bread+0xd0>

00000000800030bc <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030bc:	1101                	addi	sp,sp,-32
    800030be:	ec06                	sd	ra,24(sp)
    800030c0:	e822                	sd	s0,16(sp)
    800030c2:	e426                	sd	s1,8(sp)
    800030c4:	1000                	addi	s0,sp,32
    800030c6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030c8:	0541                	addi	a0,a0,16
    800030ca:	00001097          	auipc	ra,0x1
    800030ce:	46e080e7          	jalr	1134(ra) # 80004538 <holdingsleep>
    800030d2:	cd01                	beqz	a0,800030ea <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030d4:	4585                	li	a1,1
    800030d6:	8526                	mv	a0,s1
    800030d8:	00003097          	auipc	ra,0x3
    800030dc:	fb0080e7          	jalr	-80(ra) # 80006088 <virtio_disk_rw>
}
    800030e0:	60e2                	ld	ra,24(sp)
    800030e2:	6442                	ld	s0,16(sp)
    800030e4:	64a2                	ld	s1,8(sp)
    800030e6:	6105                	addi	sp,sp,32
    800030e8:	8082                	ret
    panic("bwrite");
    800030ea:	00005517          	auipc	a0,0x5
    800030ee:	3f650513          	addi	a0,a0,1014 # 800084e0 <syscalls+0xd8>
    800030f2:	ffffd097          	auipc	ra,0xffffd
    800030f6:	452080e7          	jalr	1106(ra) # 80000544 <panic>

00000000800030fa <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030fa:	1101                	addi	sp,sp,-32
    800030fc:	ec06                	sd	ra,24(sp)
    800030fe:	e822                	sd	s0,16(sp)
    80003100:	e426                	sd	s1,8(sp)
    80003102:	e04a                	sd	s2,0(sp)
    80003104:	1000                	addi	s0,sp,32
    80003106:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003108:	01050913          	addi	s2,a0,16
    8000310c:	854a                	mv	a0,s2
    8000310e:	00001097          	auipc	ra,0x1
    80003112:	42a080e7          	jalr	1066(ra) # 80004538 <holdingsleep>
    80003116:	c92d                	beqz	a0,80003188 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003118:	854a                	mv	a0,s2
    8000311a:	00001097          	auipc	ra,0x1
    8000311e:	3da080e7          	jalr	986(ra) # 800044f4 <releasesleep>

  acquire(&bcache.lock);
    80003122:	00014517          	auipc	a0,0x14
    80003126:	81650513          	addi	a0,a0,-2026 # 80016938 <bcache>
    8000312a:	ffffe097          	auipc	ra,0xffffe
    8000312e:	ac0080e7          	jalr	-1344(ra) # 80000bea <acquire>
  b->refcnt--;
    80003132:	40bc                	lw	a5,64(s1)
    80003134:	37fd                	addiw	a5,a5,-1
    80003136:	0007871b          	sext.w	a4,a5
    8000313a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000313c:	eb05                	bnez	a4,8000316c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000313e:	68bc                	ld	a5,80(s1)
    80003140:	64b8                	ld	a4,72(s1)
    80003142:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003144:	64bc                	ld	a5,72(s1)
    80003146:	68b8                	ld	a4,80(s1)
    80003148:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000314a:	0001b797          	auipc	a5,0x1b
    8000314e:	7ee78793          	addi	a5,a5,2030 # 8001e938 <bcache+0x8000>
    80003152:	2b87b703          	ld	a4,696(a5)
    80003156:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003158:	0001c717          	auipc	a4,0x1c
    8000315c:	a4870713          	addi	a4,a4,-1464 # 8001eba0 <bcache+0x8268>
    80003160:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003162:	2b87b703          	ld	a4,696(a5)
    80003166:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003168:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000316c:	00013517          	auipc	a0,0x13
    80003170:	7cc50513          	addi	a0,a0,1996 # 80016938 <bcache>
    80003174:	ffffe097          	auipc	ra,0xffffe
    80003178:	b2a080e7          	jalr	-1238(ra) # 80000c9e <release>
}
    8000317c:	60e2                	ld	ra,24(sp)
    8000317e:	6442                	ld	s0,16(sp)
    80003180:	64a2                	ld	s1,8(sp)
    80003182:	6902                	ld	s2,0(sp)
    80003184:	6105                	addi	sp,sp,32
    80003186:	8082                	ret
    panic("brelse");
    80003188:	00005517          	auipc	a0,0x5
    8000318c:	36050513          	addi	a0,a0,864 # 800084e8 <syscalls+0xe0>
    80003190:	ffffd097          	auipc	ra,0xffffd
    80003194:	3b4080e7          	jalr	948(ra) # 80000544 <panic>

0000000080003198 <bpin>:

void
bpin(struct buf *b) {
    80003198:	1101                	addi	sp,sp,-32
    8000319a:	ec06                	sd	ra,24(sp)
    8000319c:	e822                	sd	s0,16(sp)
    8000319e:	e426                	sd	s1,8(sp)
    800031a0:	1000                	addi	s0,sp,32
    800031a2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031a4:	00013517          	auipc	a0,0x13
    800031a8:	79450513          	addi	a0,a0,1940 # 80016938 <bcache>
    800031ac:	ffffe097          	auipc	ra,0xffffe
    800031b0:	a3e080e7          	jalr	-1474(ra) # 80000bea <acquire>
  b->refcnt++;
    800031b4:	40bc                	lw	a5,64(s1)
    800031b6:	2785                	addiw	a5,a5,1
    800031b8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031ba:	00013517          	auipc	a0,0x13
    800031be:	77e50513          	addi	a0,a0,1918 # 80016938 <bcache>
    800031c2:	ffffe097          	auipc	ra,0xffffe
    800031c6:	adc080e7          	jalr	-1316(ra) # 80000c9e <release>
}
    800031ca:	60e2                	ld	ra,24(sp)
    800031cc:	6442                	ld	s0,16(sp)
    800031ce:	64a2                	ld	s1,8(sp)
    800031d0:	6105                	addi	sp,sp,32
    800031d2:	8082                	ret

00000000800031d4 <bunpin>:

void
bunpin(struct buf *b) {
    800031d4:	1101                	addi	sp,sp,-32
    800031d6:	ec06                	sd	ra,24(sp)
    800031d8:	e822                	sd	s0,16(sp)
    800031da:	e426                	sd	s1,8(sp)
    800031dc:	1000                	addi	s0,sp,32
    800031de:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031e0:	00013517          	auipc	a0,0x13
    800031e4:	75850513          	addi	a0,a0,1880 # 80016938 <bcache>
    800031e8:	ffffe097          	auipc	ra,0xffffe
    800031ec:	a02080e7          	jalr	-1534(ra) # 80000bea <acquire>
  b->refcnt--;
    800031f0:	40bc                	lw	a5,64(s1)
    800031f2:	37fd                	addiw	a5,a5,-1
    800031f4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031f6:	00013517          	auipc	a0,0x13
    800031fa:	74250513          	addi	a0,a0,1858 # 80016938 <bcache>
    800031fe:	ffffe097          	auipc	ra,0xffffe
    80003202:	aa0080e7          	jalr	-1376(ra) # 80000c9e <release>
}
    80003206:	60e2                	ld	ra,24(sp)
    80003208:	6442                	ld	s0,16(sp)
    8000320a:	64a2                	ld	s1,8(sp)
    8000320c:	6105                	addi	sp,sp,32
    8000320e:	8082                	ret

0000000080003210 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003210:	1101                	addi	sp,sp,-32
    80003212:	ec06                	sd	ra,24(sp)
    80003214:	e822                	sd	s0,16(sp)
    80003216:	e426                	sd	s1,8(sp)
    80003218:	e04a                	sd	s2,0(sp)
    8000321a:	1000                	addi	s0,sp,32
    8000321c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000321e:	00d5d59b          	srliw	a1,a1,0xd
    80003222:	0001c797          	auipc	a5,0x1c
    80003226:	df27a783          	lw	a5,-526(a5) # 8001f014 <sb+0x1c>
    8000322a:	9dbd                	addw	a1,a1,a5
    8000322c:	00000097          	auipc	ra,0x0
    80003230:	d9e080e7          	jalr	-610(ra) # 80002fca <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003234:	0074f713          	andi	a4,s1,7
    80003238:	4785                	li	a5,1
    8000323a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000323e:	14ce                	slli	s1,s1,0x33
    80003240:	90d9                	srli	s1,s1,0x36
    80003242:	00950733          	add	a4,a0,s1
    80003246:	05874703          	lbu	a4,88(a4)
    8000324a:	00e7f6b3          	and	a3,a5,a4
    8000324e:	c69d                	beqz	a3,8000327c <bfree+0x6c>
    80003250:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003252:	94aa                	add	s1,s1,a0
    80003254:	fff7c793          	not	a5,a5
    80003258:	8ff9                	and	a5,a5,a4
    8000325a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000325e:	00001097          	auipc	ra,0x1
    80003262:	120080e7          	jalr	288(ra) # 8000437e <log_write>
  brelse(bp);
    80003266:	854a                	mv	a0,s2
    80003268:	00000097          	auipc	ra,0x0
    8000326c:	e92080e7          	jalr	-366(ra) # 800030fa <brelse>
}
    80003270:	60e2                	ld	ra,24(sp)
    80003272:	6442                	ld	s0,16(sp)
    80003274:	64a2                	ld	s1,8(sp)
    80003276:	6902                	ld	s2,0(sp)
    80003278:	6105                	addi	sp,sp,32
    8000327a:	8082                	ret
    panic("freeing free block");
    8000327c:	00005517          	auipc	a0,0x5
    80003280:	27450513          	addi	a0,a0,628 # 800084f0 <syscalls+0xe8>
    80003284:	ffffd097          	auipc	ra,0xffffd
    80003288:	2c0080e7          	jalr	704(ra) # 80000544 <panic>

000000008000328c <balloc>:
{
    8000328c:	711d                	addi	sp,sp,-96
    8000328e:	ec86                	sd	ra,88(sp)
    80003290:	e8a2                	sd	s0,80(sp)
    80003292:	e4a6                	sd	s1,72(sp)
    80003294:	e0ca                	sd	s2,64(sp)
    80003296:	fc4e                	sd	s3,56(sp)
    80003298:	f852                	sd	s4,48(sp)
    8000329a:	f456                	sd	s5,40(sp)
    8000329c:	f05a                	sd	s6,32(sp)
    8000329e:	ec5e                	sd	s7,24(sp)
    800032a0:	e862                	sd	s8,16(sp)
    800032a2:	e466                	sd	s9,8(sp)
    800032a4:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032a6:	0001c797          	auipc	a5,0x1c
    800032aa:	d567a783          	lw	a5,-682(a5) # 8001effc <sb+0x4>
    800032ae:	10078163          	beqz	a5,800033b0 <balloc+0x124>
    800032b2:	8baa                	mv	s7,a0
    800032b4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032b6:	0001cb17          	auipc	s6,0x1c
    800032ba:	d42b0b13          	addi	s6,s6,-702 # 8001eff8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032be:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032c0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032c2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032c4:	6c89                	lui	s9,0x2
    800032c6:	a061                	j	8000334e <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032c8:	974a                	add	a4,a4,s2
    800032ca:	8fd5                	or	a5,a5,a3
    800032cc:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032d0:	854a                	mv	a0,s2
    800032d2:	00001097          	auipc	ra,0x1
    800032d6:	0ac080e7          	jalr	172(ra) # 8000437e <log_write>
        brelse(bp);
    800032da:	854a                	mv	a0,s2
    800032dc:	00000097          	auipc	ra,0x0
    800032e0:	e1e080e7          	jalr	-482(ra) # 800030fa <brelse>
  bp = bread(dev, bno);
    800032e4:	85a6                	mv	a1,s1
    800032e6:	855e                	mv	a0,s7
    800032e8:	00000097          	auipc	ra,0x0
    800032ec:	ce2080e7          	jalr	-798(ra) # 80002fca <bread>
    800032f0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032f2:	40000613          	li	a2,1024
    800032f6:	4581                	li	a1,0
    800032f8:	05850513          	addi	a0,a0,88
    800032fc:	ffffe097          	auipc	ra,0xffffe
    80003300:	9ea080e7          	jalr	-1558(ra) # 80000ce6 <memset>
  log_write(bp);
    80003304:	854a                	mv	a0,s2
    80003306:	00001097          	auipc	ra,0x1
    8000330a:	078080e7          	jalr	120(ra) # 8000437e <log_write>
  brelse(bp);
    8000330e:	854a                	mv	a0,s2
    80003310:	00000097          	auipc	ra,0x0
    80003314:	dea080e7          	jalr	-534(ra) # 800030fa <brelse>
}
    80003318:	8526                	mv	a0,s1
    8000331a:	60e6                	ld	ra,88(sp)
    8000331c:	6446                	ld	s0,80(sp)
    8000331e:	64a6                	ld	s1,72(sp)
    80003320:	6906                	ld	s2,64(sp)
    80003322:	79e2                	ld	s3,56(sp)
    80003324:	7a42                	ld	s4,48(sp)
    80003326:	7aa2                	ld	s5,40(sp)
    80003328:	7b02                	ld	s6,32(sp)
    8000332a:	6be2                	ld	s7,24(sp)
    8000332c:	6c42                	ld	s8,16(sp)
    8000332e:	6ca2                	ld	s9,8(sp)
    80003330:	6125                	addi	sp,sp,96
    80003332:	8082                	ret
    brelse(bp);
    80003334:	854a                	mv	a0,s2
    80003336:	00000097          	auipc	ra,0x0
    8000333a:	dc4080e7          	jalr	-572(ra) # 800030fa <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000333e:	015c87bb          	addw	a5,s9,s5
    80003342:	00078a9b          	sext.w	s5,a5
    80003346:	004b2703          	lw	a4,4(s6)
    8000334a:	06eaf363          	bgeu	s5,a4,800033b0 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    8000334e:	41fad79b          	sraiw	a5,s5,0x1f
    80003352:	0137d79b          	srliw	a5,a5,0x13
    80003356:	015787bb          	addw	a5,a5,s5
    8000335a:	40d7d79b          	sraiw	a5,a5,0xd
    8000335e:	01cb2583          	lw	a1,28(s6)
    80003362:	9dbd                	addw	a1,a1,a5
    80003364:	855e                	mv	a0,s7
    80003366:	00000097          	auipc	ra,0x0
    8000336a:	c64080e7          	jalr	-924(ra) # 80002fca <bread>
    8000336e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003370:	004b2503          	lw	a0,4(s6)
    80003374:	000a849b          	sext.w	s1,s5
    80003378:	8662                	mv	a2,s8
    8000337a:	faa4fde3          	bgeu	s1,a0,80003334 <balloc+0xa8>
      m = 1 << (bi % 8);
    8000337e:	41f6579b          	sraiw	a5,a2,0x1f
    80003382:	01d7d69b          	srliw	a3,a5,0x1d
    80003386:	00c6873b          	addw	a4,a3,a2
    8000338a:	00777793          	andi	a5,a4,7
    8000338e:	9f95                	subw	a5,a5,a3
    80003390:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003394:	4037571b          	sraiw	a4,a4,0x3
    80003398:	00e906b3          	add	a3,s2,a4
    8000339c:	0586c683          	lbu	a3,88(a3)
    800033a0:	00d7f5b3          	and	a1,a5,a3
    800033a4:	d195                	beqz	a1,800032c8 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033a6:	2605                	addiw	a2,a2,1
    800033a8:	2485                	addiw	s1,s1,1
    800033aa:	fd4618e3          	bne	a2,s4,8000337a <balloc+0xee>
    800033ae:	b759                	j	80003334 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800033b0:	00005517          	auipc	a0,0x5
    800033b4:	15850513          	addi	a0,a0,344 # 80008508 <syscalls+0x100>
    800033b8:	ffffd097          	auipc	ra,0xffffd
    800033bc:	1d6080e7          	jalr	470(ra) # 8000058e <printf>
  return 0;
    800033c0:	4481                	li	s1,0
    800033c2:	bf99                	j	80003318 <balloc+0x8c>

00000000800033c4 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800033c4:	7179                	addi	sp,sp,-48
    800033c6:	f406                	sd	ra,40(sp)
    800033c8:	f022                	sd	s0,32(sp)
    800033ca:	ec26                	sd	s1,24(sp)
    800033cc:	e84a                	sd	s2,16(sp)
    800033ce:	e44e                	sd	s3,8(sp)
    800033d0:	e052                	sd	s4,0(sp)
    800033d2:	1800                	addi	s0,sp,48
    800033d4:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033d6:	47ad                	li	a5,11
    800033d8:	02b7e763          	bltu	a5,a1,80003406 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800033dc:	02059493          	slli	s1,a1,0x20
    800033e0:	9081                	srli	s1,s1,0x20
    800033e2:	048a                	slli	s1,s1,0x2
    800033e4:	94aa                	add	s1,s1,a0
    800033e6:	0504a903          	lw	s2,80(s1)
    800033ea:	06091e63          	bnez	s2,80003466 <bmap+0xa2>
      addr = balloc(ip->dev);
    800033ee:	4108                	lw	a0,0(a0)
    800033f0:	00000097          	auipc	ra,0x0
    800033f4:	e9c080e7          	jalr	-356(ra) # 8000328c <balloc>
    800033f8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033fc:	06090563          	beqz	s2,80003466 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003400:	0524a823          	sw	s2,80(s1)
    80003404:	a08d                	j	80003466 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003406:	ff45849b          	addiw	s1,a1,-12
    8000340a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000340e:	0ff00793          	li	a5,255
    80003412:	08e7e563          	bltu	a5,a4,8000349c <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003416:	08052903          	lw	s2,128(a0)
    8000341a:	00091d63          	bnez	s2,80003434 <bmap+0x70>
      addr = balloc(ip->dev);
    8000341e:	4108                	lw	a0,0(a0)
    80003420:	00000097          	auipc	ra,0x0
    80003424:	e6c080e7          	jalr	-404(ra) # 8000328c <balloc>
    80003428:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000342c:	02090d63          	beqz	s2,80003466 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003430:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003434:	85ca                	mv	a1,s2
    80003436:	0009a503          	lw	a0,0(s3)
    8000343a:	00000097          	auipc	ra,0x0
    8000343e:	b90080e7          	jalr	-1136(ra) # 80002fca <bread>
    80003442:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003444:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003448:	02049593          	slli	a1,s1,0x20
    8000344c:	9181                	srli	a1,a1,0x20
    8000344e:	058a                	slli	a1,a1,0x2
    80003450:	00b784b3          	add	s1,a5,a1
    80003454:	0004a903          	lw	s2,0(s1)
    80003458:	02090063          	beqz	s2,80003478 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000345c:	8552                	mv	a0,s4
    8000345e:	00000097          	auipc	ra,0x0
    80003462:	c9c080e7          	jalr	-868(ra) # 800030fa <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003466:	854a                	mv	a0,s2
    80003468:	70a2                	ld	ra,40(sp)
    8000346a:	7402                	ld	s0,32(sp)
    8000346c:	64e2                	ld	s1,24(sp)
    8000346e:	6942                	ld	s2,16(sp)
    80003470:	69a2                	ld	s3,8(sp)
    80003472:	6a02                	ld	s4,0(sp)
    80003474:	6145                	addi	sp,sp,48
    80003476:	8082                	ret
      addr = balloc(ip->dev);
    80003478:	0009a503          	lw	a0,0(s3)
    8000347c:	00000097          	auipc	ra,0x0
    80003480:	e10080e7          	jalr	-496(ra) # 8000328c <balloc>
    80003484:	0005091b          	sext.w	s2,a0
      if(addr){
    80003488:	fc090ae3          	beqz	s2,8000345c <bmap+0x98>
        a[bn] = addr;
    8000348c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003490:	8552                	mv	a0,s4
    80003492:	00001097          	auipc	ra,0x1
    80003496:	eec080e7          	jalr	-276(ra) # 8000437e <log_write>
    8000349a:	b7c9                	j	8000345c <bmap+0x98>
  panic("bmap: out of range");
    8000349c:	00005517          	auipc	a0,0x5
    800034a0:	08450513          	addi	a0,a0,132 # 80008520 <syscalls+0x118>
    800034a4:	ffffd097          	auipc	ra,0xffffd
    800034a8:	0a0080e7          	jalr	160(ra) # 80000544 <panic>

00000000800034ac <iget>:
{
    800034ac:	7179                	addi	sp,sp,-48
    800034ae:	f406                	sd	ra,40(sp)
    800034b0:	f022                	sd	s0,32(sp)
    800034b2:	ec26                	sd	s1,24(sp)
    800034b4:	e84a                	sd	s2,16(sp)
    800034b6:	e44e                	sd	s3,8(sp)
    800034b8:	e052                	sd	s4,0(sp)
    800034ba:	1800                	addi	s0,sp,48
    800034bc:	89aa                	mv	s3,a0
    800034be:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800034c0:	0001c517          	auipc	a0,0x1c
    800034c4:	b5850513          	addi	a0,a0,-1192 # 8001f018 <itable>
    800034c8:	ffffd097          	auipc	ra,0xffffd
    800034cc:	722080e7          	jalr	1826(ra) # 80000bea <acquire>
  empty = 0;
    800034d0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034d2:	0001c497          	auipc	s1,0x1c
    800034d6:	b5e48493          	addi	s1,s1,-1186 # 8001f030 <itable+0x18>
    800034da:	0001d697          	auipc	a3,0x1d
    800034de:	5e668693          	addi	a3,a3,1510 # 80020ac0 <log>
    800034e2:	a039                	j	800034f0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034e4:	02090b63          	beqz	s2,8000351a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034e8:	08848493          	addi	s1,s1,136
    800034ec:	02d48a63          	beq	s1,a3,80003520 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034f0:	449c                	lw	a5,8(s1)
    800034f2:	fef059e3          	blez	a5,800034e4 <iget+0x38>
    800034f6:	4098                	lw	a4,0(s1)
    800034f8:	ff3716e3          	bne	a4,s3,800034e4 <iget+0x38>
    800034fc:	40d8                	lw	a4,4(s1)
    800034fe:	ff4713e3          	bne	a4,s4,800034e4 <iget+0x38>
      ip->ref++;
    80003502:	2785                	addiw	a5,a5,1
    80003504:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003506:	0001c517          	auipc	a0,0x1c
    8000350a:	b1250513          	addi	a0,a0,-1262 # 8001f018 <itable>
    8000350e:	ffffd097          	auipc	ra,0xffffd
    80003512:	790080e7          	jalr	1936(ra) # 80000c9e <release>
      return ip;
    80003516:	8926                	mv	s2,s1
    80003518:	a03d                	j	80003546 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000351a:	f7f9                	bnez	a5,800034e8 <iget+0x3c>
    8000351c:	8926                	mv	s2,s1
    8000351e:	b7e9                	j	800034e8 <iget+0x3c>
  if(empty == 0)
    80003520:	02090c63          	beqz	s2,80003558 <iget+0xac>
  ip->dev = dev;
    80003524:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003528:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000352c:	4785                	li	a5,1
    8000352e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003532:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003536:	0001c517          	auipc	a0,0x1c
    8000353a:	ae250513          	addi	a0,a0,-1310 # 8001f018 <itable>
    8000353e:	ffffd097          	auipc	ra,0xffffd
    80003542:	760080e7          	jalr	1888(ra) # 80000c9e <release>
}
    80003546:	854a                	mv	a0,s2
    80003548:	70a2                	ld	ra,40(sp)
    8000354a:	7402                	ld	s0,32(sp)
    8000354c:	64e2                	ld	s1,24(sp)
    8000354e:	6942                	ld	s2,16(sp)
    80003550:	69a2                	ld	s3,8(sp)
    80003552:	6a02                	ld	s4,0(sp)
    80003554:	6145                	addi	sp,sp,48
    80003556:	8082                	ret
    panic("iget: no inodes");
    80003558:	00005517          	auipc	a0,0x5
    8000355c:	fe050513          	addi	a0,a0,-32 # 80008538 <syscalls+0x130>
    80003560:	ffffd097          	auipc	ra,0xffffd
    80003564:	fe4080e7          	jalr	-28(ra) # 80000544 <panic>

0000000080003568 <fsinit>:
fsinit(int dev) {
    80003568:	7179                	addi	sp,sp,-48
    8000356a:	f406                	sd	ra,40(sp)
    8000356c:	f022                	sd	s0,32(sp)
    8000356e:	ec26                	sd	s1,24(sp)
    80003570:	e84a                	sd	s2,16(sp)
    80003572:	e44e                	sd	s3,8(sp)
    80003574:	1800                	addi	s0,sp,48
    80003576:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003578:	4585                	li	a1,1
    8000357a:	00000097          	auipc	ra,0x0
    8000357e:	a50080e7          	jalr	-1456(ra) # 80002fca <bread>
    80003582:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003584:	0001c997          	auipc	s3,0x1c
    80003588:	a7498993          	addi	s3,s3,-1420 # 8001eff8 <sb>
    8000358c:	02000613          	li	a2,32
    80003590:	05850593          	addi	a1,a0,88
    80003594:	854e                	mv	a0,s3
    80003596:	ffffd097          	auipc	ra,0xffffd
    8000359a:	7b0080e7          	jalr	1968(ra) # 80000d46 <memmove>
  brelse(bp);
    8000359e:	8526                	mv	a0,s1
    800035a0:	00000097          	auipc	ra,0x0
    800035a4:	b5a080e7          	jalr	-1190(ra) # 800030fa <brelse>
  if(sb.magic != FSMAGIC)
    800035a8:	0009a703          	lw	a4,0(s3)
    800035ac:	102037b7          	lui	a5,0x10203
    800035b0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035b4:	02f71263          	bne	a4,a5,800035d8 <fsinit+0x70>
  initlog(dev, &sb);
    800035b8:	0001c597          	auipc	a1,0x1c
    800035bc:	a4058593          	addi	a1,a1,-1472 # 8001eff8 <sb>
    800035c0:	854a                	mv	a0,s2
    800035c2:	00001097          	auipc	ra,0x1
    800035c6:	b40080e7          	jalr	-1216(ra) # 80004102 <initlog>
}
    800035ca:	70a2                	ld	ra,40(sp)
    800035cc:	7402                	ld	s0,32(sp)
    800035ce:	64e2                	ld	s1,24(sp)
    800035d0:	6942                	ld	s2,16(sp)
    800035d2:	69a2                	ld	s3,8(sp)
    800035d4:	6145                	addi	sp,sp,48
    800035d6:	8082                	ret
    panic("invalid file system");
    800035d8:	00005517          	auipc	a0,0x5
    800035dc:	f7050513          	addi	a0,a0,-144 # 80008548 <syscalls+0x140>
    800035e0:	ffffd097          	auipc	ra,0xffffd
    800035e4:	f64080e7          	jalr	-156(ra) # 80000544 <panic>

00000000800035e8 <iinit>:
{
    800035e8:	7179                	addi	sp,sp,-48
    800035ea:	f406                	sd	ra,40(sp)
    800035ec:	f022                	sd	s0,32(sp)
    800035ee:	ec26                	sd	s1,24(sp)
    800035f0:	e84a                	sd	s2,16(sp)
    800035f2:	e44e                	sd	s3,8(sp)
    800035f4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035f6:	00005597          	auipc	a1,0x5
    800035fa:	f6a58593          	addi	a1,a1,-150 # 80008560 <syscalls+0x158>
    800035fe:	0001c517          	auipc	a0,0x1c
    80003602:	a1a50513          	addi	a0,a0,-1510 # 8001f018 <itable>
    80003606:	ffffd097          	auipc	ra,0xffffd
    8000360a:	554080e7          	jalr	1364(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    8000360e:	0001c497          	auipc	s1,0x1c
    80003612:	a3248493          	addi	s1,s1,-1486 # 8001f040 <itable+0x28>
    80003616:	0001d997          	auipc	s3,0x1d
    8000361a:	4ba98993          	addi	s3,s3,1210 # 80020ad0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000361e:	00005917          	auipc	s2,0x5
    80003622:	f4a90913          	addi	s2,s2,-182 # 80008568 <syscalls+0x160>
    80003626:	85ca                	mv	a1,s2
    80003628:	8526                	mv	a0,s1
    8000362a:	00001097          	auipc	ra,0x1
    8000362e:	e3a080e7          	jalr	-454(ra) # 80004464 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003632:	08848493          	addi	s1,s1,136
    80003636:	ff3498e3          	bne	s1,s3,80003626 <iinit+0x3e>
}
    8000363a:	70a2                	ld	ra,40(sp)
    8000363c:	7402                	ld	s0,32(sp)
    8000363e:	64e2                	ld	s1,24(sp)
    80003640:	6942                	ld	s2,16(sp)
    80003642:	69a2                	ld	s3,8(sp)
    80003644:	6145                	addi	sp,sp,48
    80003646:	8082                	ret

0000000080003648 <ialloc>:
{
    80003648:	715d                	addi	sp,sp,-80
    8000364a:	e486                	sd	ra,72(sp)
    8000364c:	e0a2                	sd	s0,64(sp)
    8000364e:	fc26                	sd	s1,56(sp)
    80003650:	f84a                	sd	s2,48(sp)
    80003652:	f44e                	sd	s3,40(sp)
    80003654:	f052                	sd	s4,32(sp)
    80003656:	ec56                	sd	s5,24(sp)
    80003658:	e85a                	sd	s6,16(sp)
    8000365a:	e45e                	sd	s7,8(sp)
    8000365c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000365e:	0001c717          	auipc	a4,0x1c
    80003662:	9a672703          	lw	a4,-1626(a4) # 8001f004 <sb+0xc>
    80003666:	4785                	li	a5,1
    80003668:	04e7fa63          	bgeu	a5,a4,800036bc <ialloc+0x74>
    8000366c:	8aaa                	mv	s5,a0
    8000366e:	8bae                	mv	s7,a1
    80003670:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003672:	0001ca17          	auipc	s4,0x1c
    80003676:	986a0a13          	addi	s4,s4,-1658 # 8001eff8 <sb>
    8000367a:	00048b1b          	sext.w	s6,s1
    8000367e:	0044d593          	srli	a1,s1,0x4
    80003682:	018a2783          	lw	a5,24(s4)
    80003686:	9dbd                	addw	a1,a1,a5
    80003688:	8556                	mv	a0,s5
    8000368a:	00000097          	auipc	ra,0x0
    8000368e:	940080e7          	jalr	-1728(ra) # 80002fca <bread>
    80003692:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003694:	05850993          	addi	s3,a0,88
    80003698:	00f4f793          	andi	a5,s1,15
    8000369c:	079a                	slli	a5,a5,0x6
    8000369e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036a0:	00099783          	lh	a5,0(s3)
    800036a4:	c3a1                	beqz	a5,800036e4 <ialloc+0x9c>
    brelse(bp);
    800036a6:	00000097          	auipc	ra,0x0
    800036aa:	a54080e7          	jalr	-1452(ra) # 800030fa <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036ae:	0485                	addi	s1,s1,1
    800036b0:	00ca2703          	lw	a4,12(s4)
    800036b4:	0004879b          	sext.w	a5,s1
    800036b8:	fce7e1e3          	bltu	a5,a4,8000367a <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800036bc:	00005517          	auipc	a0,0x5
    800036c0:	eb450513          	addi	a0,a0,-332 # 80008570 <syscalls+0x168>
    800036c4:	ffffd097          	auipc	ra,0xffffd
    800036c8:	eca080e7          	jalr	-310(ra) # 8000058e <printf>
  return 0;
    800036cc:	4501                	li	a0,0
}
    800036ce:	60a6                	ld	ra,72(sp)
    800036d0:	6406                	ld	s0,64(sp)
    800036d2:	74e2                	ld	s1,56(sp)
    800036d4:	7942                	ld	s2,48(sp)
    800036d6:	79a2                	ld	s3,40(sp)
    800036d8:	7a02                	ld	s4,32(sp)
    800036da:	6ae2                	ld	s5,24(sp)
    800036dc:	6b42                	ld	s6,16(sp)
    800036de:	6ba2                	ld	s7,8(sp)
    800036e0:	6161                	addi	sp,sp,80
    800036e2:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800036e4:	04000613          	li	a2,64
    800036e8:	4581                	li	a1,0
    800036ea:	854e                	mv	a0,s3
    800036ec:	ffffd097          	auipc	ra,0xffffd
    800036f0:	5fa080e7          	jalr	1530(ra) # 80000ce6 <memset>
      dip->type = type;
    800036f4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036f8:	854a                	mv	a0,s2
    800036fa:	00001097          	auipc	ra,0x1
    800036fe:	c84080e7          	jalr	-892(ra) # 8000437e <log_write>
      brelse(bp);
    80003702:	854a                	mv	a0,s2
    80003704:	00000097          	auipc	ra,0x0
    80003708:	9f6080e7          	jalr	-1546(ra) # 800030fa <brelse>
      return iget(dev, inum);
    8000370c:	85da                	mv	a1,s6
    8000370e:	8556                	mv	a0,s5
    80003710:	00000097          	auipc	ra,0x0
    80003714:	d9c080e7          	jalr	-612(ra) # 800034ac <iget>
    80003718:	bf5d                	j	800036ce <ialloc+0x86>

000000008000371a <iupdate>:
{
    8000371a:	1101                	addi	sp,sp,-32
    8000371c:	ec06                	sd	ra,24(sp)
    8000371e:	e822                	sd	s0,16(sp)
    80003720:	e426                	sd	s1,8(sp)
    80003722:	e04a                	sd	s2,0(sp)
    80003724:	1000                	addi	s0,sp,32
    80003726:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003728:	415c                	lw	a5,4(a0)
    8000372a:	0047d79b          	srliw	a5,a5,0x4
    8000372e:	0001c597          	auipc	a1,0x1c
    80003732:	8e25a583          	lw	a1,-1822(a1) # 8001f010 <sb+0x18>
    80003736:	9dbd                	addw	a1,a1,a5
    80003738:	4108                	lw	a0,0(a0)
    8000373a:	00000097          	auipc	ra,0x0
    8000373e:	890080e7          	jalr	-1904(ra) # 80002fca <bread>
    80003742:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003744:	05850793          	addi	a5,a0,88
    80003748:	40c8                	lw	a0,4(s1)
    8000374a:	893d                	andi	a0,a0,15
    8000374c:	051a                	slli	a0,a0,0x6
    8000374e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003750:	04449703          	lh	a4,68(s1)
    80003754:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003758:	04649703          	lh	a4,70(s1)
    8000375c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003760:	04849703          	lh	a4,72(s1)
    80003764:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003768:	04a49703          	lh	a4,74(s1)
    8000376c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003770:	44f8                	lw	a4,76(s1)
    80003772:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003774:	03400613          	li	a2,52
    80003778:	05048593          	addi	a1,s1,80
    8000377c:	0531                	addi	a0,a0,12
    8000377e:	ffffd097          	auipc	ra,0xffffd
    80003782:	5c8080e7          	jalr	1480(ra) # 80000d46 <memmove>
  log_write(bp);
    80003786:	854a                	mv	a0,s2
    80003788:	00001097          	auipc	ra,0x1
    8000378c:	bf6080e7          	jalr	-1034(ra) # 8000437e <log_write>
  brelse(bp);
    80003790:	854a                	mv	a0,s2
    80003792:	00000097          	auipc	ra,0x0
    80003796:	968080e7          	jalr	-1688(ra) # 800030fa <brelse>
}
    8000379a:	60e2                	ld	ra,24(sp)
    8000379c:	6442                	ld	s0,16(sp)
    8000379e:	64a2                	ld	s1,8(sp)
    800037a0:	6902                	ld	s2,0(sp)
    800037a2:	6105                	addi	sp,sp,32
    800037a4:	8082                	ret

00000000800037a6 <idup>:
{
    800037a6:	1101                	addi	sp,sp,-32
    800037a8:	ec06                	sd	ra,24(sp)
    800037aa:	e822                	sd	s0,16(sp)
    800037ac:	e426                	sd	s1,8(sp)
    800037ae:	1000                	addi	s0,sp,32
    800037b0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037b2:	0001c517          	auipc	a0,0x1c
    800037b6:	86650513          	addi	a0,a0,-1946 # 8001f018 <itable>
    800037ba:	ffffd097          	auipc	ra,0xffffd
    800037be:	430080e7          	jalr	1072(ra) # 80000bea <acquire>
  ip->ref++;
    800037c2:	449c                	lw	a5,8(s1)
    800037c4:	2785                	addiw	a5,a5,1
    800037c6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037c8:	0001c517          	auipc	a0,0x1c
    800037cc:	85050513          	addi	a0,a0,-1968 # 8001f018 <itable>
    800037d0:	ffffd097          	auipc	ra,0xffffd
    800037d4:	4ce080e7          	jalr	1230(ra) # 80000c9e <release>
}
    800037d8:	8526                	mv	a0,s1
    800037da:	60e2                	ld	ra,24(sp)
    800037dc:	6442                	ld	s0,16(sp)
    800037de:	64a2                	ld	s1,8(sp)
    800037e0:	6105                	addi	sp,sp,32
    800037e2:	8082                	ret

00000000800037e4 <ilock>:
{
    800037e4:	1101                	addi	sp,sp,-32
    800037e6:	ec06                	sd	ra,24(sp)
    800037e8:	e822                	sd	s0,16(sp)
    800037ea:	e426                	sd	s1,8(sp)
    800037ec:	e04a                	sd	s2,0(sp)
    800037ee:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037f0:	c115                	beqz	a0,80003814 <ilock+0x30>
    800037f2:	84aa                	mv	s1,a0
    800037f4:	451c                	lw	a5,8(a0)
    800037f6:	00f05f63          	blez	a5,80003814 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037fa:	0541                	addi	a0,a0,16
    800037fc:	00001097          	auipc	ra,0x1
    80003800:	ca2080e7          	jalr	-862(ra) # 8000449e <acquiresleep>
  if(ip->valid == 0){
    80003804:	40bc                	lw	a5,64(s1)
    80003806:	cf99                	beqz	a5,80003824 <ilock+0x40>
}
    80003808:	60e2                	ld	ra,24(sp)
    8000380a:	6442                	ld	s0,16(sp)
    8000380c:	64a2                	ld	s1,8(sp)
    8000380e:	6902                	ld	s2,0(sp)
    80003810:	6105                	addi	sp,sp,32
    80003812:	8082                	ret
    panic("ilock");
    80003814:	00005517          	auipc	a0,0x5
    80003818:	d7450513          	addi	a0,a0,-652 # 80008588 <syscalls+0x180>
    8000381c:	ffffd097          	auipc	ra,0xffffd
    80003820:	d28080e7          	jalr	-728(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003824:	40dc                	lw	a5,4(s1)
    80003826:	0047d79b          	srliw	a5,a5,0x4
    8000382a:	0001b597          	auipc	a1,0x1b
    8000382e:	7e65a583          	lw	a1,2022(a1) # 8001f010 <sb+0x18>
    80003832:	9dbd                	addw	a1,a1,a5
    80003834:	4088                	lw	a0,0(s1)
    80003836:	fffff097          	auipc	ra,0xfffff
    8000383a:	794080e7          	jalr	1940(ra) # 80002fca <bread>
    8000383e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003840:	05850593          	addi	a1,a0,88
    80003844:	40dc                	lw	a5,4(s1)
    80003846:	8bbd                	andi	a5,a5,15
    80003848:	079a                	slli	a5,a5,0x6
    8000384a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000384c:	00059783          	lh	a5,0(a1)
    80003850:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003854:	00259783          	lh	a5,2(a1)
    80003858:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000385c:	00459783          	lh	a5,4(a1)
    80003860:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003864:	00659783          	lh	a5,6(a1)
    80003868:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000386c:	459c                	lw	a5,8(a1)
    8000386e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003870:	03400613          	li	a2,52
    80003874:	05b1                	addi	a1,a1,12
    80003876:	05048513          	addi	a0,s1,80
    8000387a:	ffffd097          	auipc	ra,0xffffd
    8000387e:	4cc080e7          	jalr	1228(ra) # 80000d46 <memmove>
    brelse(bp);
    80003882:	854a                	mv	a0,s2
    80003884:	00000097          	auipc	ra,0x0
    80003888:	876080e7          	jalr	-1930(ra) # 800030fa <brelse>
    ip->valid = 1;
    8000388c:	4785                	li	a5,1
    8000388e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003890:	04449783          	lh	a5,68(s1)
    80003894:	fbb5                	bnez	a5,80003808 <ilock+0x24>
      panic("ilock: no type");
    80003896:	00005517          	auipc	a0,0x5
    8000389a:	cfa50513          	addi	a0,a0,-774 # 80008590 <syscalls+0x188>
    8000389e:	ffffd097          	auipc	ra,0xffffd
    800038a2:	ca6080e7          	jalr	-858(ra) # 80000544 <panic>

00000000800038a6 <iunlock>:
{
    800038a6:	1101                	addi	sp,sp,-32
    800038a8:	ec06                	sd	ra,24(sp)
    800038aa:	e822                	sd	s0,16(sp)
    800038ac:	e426                	sd	s1,8(sp)
    800038ae:	e04a                	sd	s2,0(sp)
    800038b0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038b2:	c905                	beqz	a0,800038e2 <iunlock+0x3c>
    800038b4:	84aa                	mv	s1,a0
    800038b6:	01050913          	addi	s2,a0,16
    800038ba:	854a                	mv	a0,s2
    800038bc:	00001097          	auipc	ra,0x1
    800038c0:	c7c080e7          	jalr	-900(ra) # 80004538 <holdingsleep>
    800038c4:	cd19                	beqz	a0,800038e2 <iunlock+0x3c>
    800038c6:	449c                	lw	a5,8(s1)
    800038c8:	00f05d63          	blez	a5,800038e2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038cc:	854a                	mv	a0,s2
    800038ce:	00001097          	auipc	ra,0x1
    800038d2:	c26080e7          	jalr	-986(ra) # 800044f4 <releasesleep>
}
    800038d6:	60e2                	ld	ra,24(sp)
    800038d8:	6442                	ld	s0,16(sp)
    800038da:	64a2                	ld	s1,8(sp)
    800038dc:	6902                	ld	s2,0(sp)
    800038de:	6105                	addi	sp,sp,32
    800038e0:	8082                	ret
    panic("iunlock");
    800038e2:	00005517          	auipc	a0,0x5
    800038e6:	cbe50513          	addi	a0,a0,-834 # 800085a0 <syscalls+0x198>
    800038ea:	ffffd097          	auipc	ra,0xffffd
    800038ee:	c5a080e7          	jalr	-934(ra) # 80000544 <panic>

00000000800038f2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038f2:	7179                	addi	sp,sp,-48
    800038f4:	f406                	sd	ra,40(sp)
    800038f6:	f022                	sd	s0,32(sp)
    800038f8:	ec26                	sd	s1,24(sp)
    800038fa:	e84a                	sd	s2,16(sp)
    800038fc:	e44e                	sd	s3,8(sp)
    800038fe:	e052                	sd	s4,0(sp)
    80003900:	1800                	addi	s0,sp,48
    80003902:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003904:	05050493          	addi	s1,a0,80
    80003908:	08050913          	addi	s2,a0,128
    8000390c:	a021                	j	80003914 <itrunc+0x22>
    8000390e:	0491                	addi	s1,s1,4
    80003910:	01248d63          	beq	s1,s2,8000392a <itrunc+0x38>
    if(ip->addrs[i]){
    80003914:	408c                	lw	a1,0(s1)
    80003916:	dde5                	beqz	a1,8000390e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003918:	0009a503          	lw	a0,0(s3)
    8000391c:	00000097          	auipc	ra,0x0
    80003920:	8f4080e7          	jalr	-1804(ra) # 80003210 <bfree>
      ip->addrs[i] = 0;
    80003924:	0004a023          	sw	zero,0(s1)
    80003928:	b7dd                	j	8000390e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000392a:	0809a583          	lw	a1,128(s3)
    8000392e:	e185                	bnez	a1,8000394e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003930:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003934:	854e                	mv	a0,s3
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	de4080e7          	jalr	-540(ra) # 8000371a <iupdate>
}
    8000393e:	70a2                	ld	ra,40(sp)
    80003940:	7402                	ld	s0,32(sp)
    80003942:	64e2                	ld	s1,24(sp)
    80003944:	6942                	ld	s2,16(sp)
    80003946:	69a2                	ld	s3,8(sp)
    80003948:	6a02                	ld	s4,0(sp)
    8000394a:	6145                	addi	sp,sp,48
    8000394c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000394e:	0009a503          	lw	a0,0(s3)
    80003952:	fffff097          	auipc	ra,0xfffff
    80003956:	678080e7          	jalr	1656(ra) # 80002fca <bread>
    8000395a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000395c:	05850493          	addi	s1,a0,88
    80003960:	45850913          	addi	s2,a0,1112
    80003964:	a811                	j	80003978 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003966:	0009a503          	lw	a0,0(s3)
    8000396a:	00000097          	auipc	ra,0x0
    8000396e:	8a6080e7          	jalr	-1882(ra) # 80003210 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003972:	0491                	addi	s1,s1,4
    80003974:	01248563          	beq	s1,s2,8000397e <itrunc+0x8c>
      if(a[j])
    80003978:	408c                	lw	a1,0(s1)
    8000397a:	dde5                	beqz	a1,80003972 <itrunc+0x80>
    8000397c:	b7ed                	j	80003966 <itrunc+0x74>
    brelse(bp);
    8000397e:	8552                	mv	a0,s4
    80003980:	fffff097          	auipc	ra,0xfffff
    80003984:	77a080e7          	jalr	1914(ra) # 800030fa <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003988:	0809a583          	lw	a1,128(s3)
    8000398c:	0009a503          	lw	a0,0(s3)
    80003990:	00000097          	auipc	ra,0x0
    80003994:	880080e7          	jalr	-1920(ra) # 80003210 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003998:	0809a023          	sw	zero,128(s3)
    8000399c:	bf51                	j	80003930 <itrunc+0x3e>

000000008000399e <iput>:
{
    8000399e:	1101                	addi	sp,sp,-32
    800039a0:	ec06                	sd	ra,24(sp)
    800039a2:	e822                	sd	s0,16(sp)
    800039a4:	e426                	sd	s1,8(sp)
    800039a6:	e04a                	sd	s2,0(sp)
    800039a8:	1000                	addi	s0,sp,32
    800039aa:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039ac:	0001b517          	auipc	a0,0x1b
    800039b0:	66c50513          	addi	a0,a0,1644 # 8001f018 <itable>
    800039b4:	ffffd097          	auipc	ra,0xffffd
    800039b8:	236080e7          	jalr	566(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039bc:	4498                	lw	a4,8(s1)
    800039be:	4785                	li	a5,1
    800039c0:	02f70363          	beq	a4,a5,800039e6 <iput+0x48>
  ip->ref--;
    800039c4:	449c                	lw	a5,8(s1)
    800039c6:	37fd                	addiw	a5,a5,-1
    800039c8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039ca:	0001b517          	auipc	a0,0x1b
    800039ce:	64e50513          	addi	a0,a0,1614 # 8001f018 <itable>
    800039d2:	ffffd097          	auipc	ra,0xffffd
    800039d6:	2cc080e7          	jalr	716(ra) # 80000c9e <release>
}
    800039da:	60e2                	ld	ra,24(sp)
    800039dc:	6442                	ld	s0,16(sp)
    800039de:	64a2                	ld	s1,8(sp)
    800039e0:	6902                	ld	s2,0(sp)
    800039e2:	6105                	addi	sp,sp,32
    800039e4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039e6:	40bc                	lw	a5,64(s1)
    800039e8:	dff1                	beqz	a5,800039c4 <iput+0x26>
    800039ea:	04a49783          	lh	a5,74(s1)
    800039ee:	fbf9                	bnez	a5,800039c4 <iput+0x26>
    acquiresleep(&ip->lock);
    800039f0:	01048913          	addi	s2,s1,16
    800039f4:	854a                	mv	a0,s2
    800039f6:	00001097          	auipc	ra,0x1
    800039fa:	aa8080e7          	jalr	-1368(ra) # 8000449e <acquiresleep>
    release(&itable.lock);
    800039fe:	0001b517          	auipc	a0,0x1b
    80003a02:	61a50513          	addi	a0,a0,1562 # 8001f018 <itable>
    80003a06:	ffffd097          	auipc	ra,0xffffd
    80003a0a:	298080e7          	jalr	664(ra) # 80000c9e <release>
    itrunc(ip);
    80003a0e:	8526                	mv	a0,s1
    80003a10:	00000097          	auipc	ra,0x0
    80003a14:	ee2080e7          	jalr	-286(ra) # 800038f2 <itrunc>
    ip->type = 0;
    80003a18:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a1c:	8526                	mv	a0,s1
    80003a1e:	00000097          	auipc	ra,0x0
    80003a22:	cfc080e7          	jalr	-772(ra) # 8000371a <iupdate>
    ip->valid = 0;
    80003a26:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a2a:	854a                	mv	a0,s2
    80003a2c:	00001097          	auipc	ra,0x1
    80003a30:	ac8080e7          	jalr	-1336(ra) # 800044f4 <releasesleep>
    acquire(&itable.lock);
    80003a34:	0001b517          	auipc	a0,0x1b
    80003a38:	5e450513          	addi	a0,a0,1508 # 8001f018 <itable>
    80003a3c:	ffffd097          	auipc	ra,0xffffd
    80003a40:	1ae080e7          	jalr	430(ra) # 80000bea <acquire>
    80003a44:	b741                	j	800039c4 <iput+0x26>

0000000080003a46 <iunlockput>:
{
    80003a46:	1101                	addi	sp,sp,-32
    80003a48:	ec06                	sd	ra,24(sp)
    80003a4a:	e822                	sd	s0,16(sp)
    80003a4c:	e426                	sd	s1,8(sp)
    80003a4e:	1000                	addi	s0,sp,32
    80003a50:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a52:	00000097          	auipc	ra,0x0
    80003a56:	e54080e7          	jalr	-428(ra) # 800038a6 <iunlock>
  iput(ip);
    80003a5a:	8526                	mv	a0,s1
    80003a5c:	00000097          	auipc	ra,0x0
    80003a60:	f42080e7          	jalr	-190(ra) # 8000399e <iput>
}
    80003a64:	60e2                	ld	ra,24(sp)
    80003a66:	6442                	ld	s0,16(sp)
    80003a68:	64a2                	ld	s1,8(sp)
    80003a6a:	6105                	addi	sp,sp,32
    80003a6c:	8082                	ret

0000000080003a6e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a6e:	1141                	addi	sp,sp,-16
    80003a70:	e422                	sd	s0,8(sp)
    80003a72:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a74:	411c                	lw	a5,0(a0)
    80003a76:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a78:	415c                	lw	a5,4(a0)
    80003a7a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a7c:	04451783          	lh	a5,68(a0)
    80003a80:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a84:	04a51783          	lh	a5,74(a0)
    80003a88:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a8c:	04c56783          	lwu	a5,76(a0)
    80003a90:	e99c                	sd	a5,16(a1)
}
    80003a92:	6422                	ld	s0,8(sp)
    80003a94:	0141                	addi	sp,sp,16
    80003a96:	8082                	ret

0000000080003a98 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a98:	457c                	lw	a5,76(a0)
    80003a9a:	0ed7e963          	bltu	a5,a3,80003b8c <readi+0xf4>
{
    80003a9e:	7159                	addi	sp,sp,-112
    80003aa0:	f486                	sd	ra,104(sp)
    80003aa2:	f0a2                	sd	s0,96(sp)
    80003aa4:	eca6                	sd	s1,88(sp)
    80003aa6:	e8ca                	sd	s2,80(sp)
    80003aa8:	e4ce                	sd	s3,72(sp)
    80003aaa:	e0d2                	sd	s4,64(sp)
    80003aac:	fc56                	sd	s5,56(sp)
    80003aae:	f85a                	sd	s6,48(sp)
    80003ab0:	f45e                	sd	s7,40(sp)
    80003ab2:	f062                	sd	s8,32(sp)
    80003ab4:	ec66                	sd	s9,24(sp)
    80003ab6:	e86a                	sd	s10,16(sp)
    80003ab8:	e46e                	sd	s11,8(sp)
    80003aba:	1880                	addi	s0,sp,112
    80003abc:	8b2a                	mv	s6,a0
    80003abe:	8bae                	mv	s7,a1
    80003ac0:	8a32                	mv	s4,a2
    80003ac2:	84b6                	mv	s1,a3
    80003ac4:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003ac6:	9f35                	addw	a4,a4,a3
    return 0;
    80003ac8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003aca:	0ad76063          	bltu	a4,a3,80003b6a <readi+0xd2>
  if(off + n > ip->size)
    80003ace:	00e7f463          	bgeu	a5,a4,80003ad6 <readi+0x3e>
    n = ip->size - off;
    80003ad2:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ad6:	0a0a8963          	beqz	s5,80003b88 <readi+0xf0>
    80003ada:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003adc:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ae0:	5c7d                	li	s8,-1
    80003ae2:	a82d                	j	80003b1c <readi+0x84>
    80003ae4:	020d1d93          	slli	s11,s10,0x20
    80003ae8:	020ddd93          	srli	s11,s11,0x20
    80003aec:	05890613          	addi	a2,s2,88
    80003af0:	86ee                	mv	a3,s11
    80003af2:	963a                	add	a2,a2,a4
    80003af4:	85d2                	mv	a1,s4
    80003af6:	855e                	mv	a0,s7
    80003af8:	fffff097          	auipc	ra,0xfffff
    80003afc:	a8e080e7          	jalr	-1394(ra) # 80002586 <either_copyout>
    80003b00:	05850d63          	beq	a0,s8,80003b5a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b04:	854a                	mv	a0,s2
    80003b06:	fffff097          	auipc	ra,0xfffff
    80003b0a:	5f4080e7          	jalr	1524(ra) # 800030fa <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b0e:	013d09bb          	addw	s3,s10,s3
    80003b12:	009d04bb          	addw	s1,s10,s1
    80003b16:	9a6e                	add	s4,s4,s11
    80003b18:	0559f763          	bgeu	s3,s5,80003b66 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003b1c:	00a4d59b          	srliw	a1,s1,0xa
    80003b20:	855a                	mv	a0,s6
    80003b22:	00000097          	auipc	ra,0x0
    80003b26:	8a2080e7          	jalr	-1886(ra) # 800033c4 <bmap>
    80003b2a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b2e:	cd85                	beqz	a1,80003b66 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003b30:	000b2503          	lw	a0,0(s6)
    80003b34:	fffff097          	auipc	ra,0xfffff
    80003b38:	496080e7          	jalr	1174(ra) # 80002fca <bread>
    80003b3c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b3e:	3ff4f713          	andi	a4,s1,1023
    80003b42:	40ec87bb          	subw	a5,s9,a4
    80003b46:	413a86bb          	subw	a3,s5,s3
    80003b4a:	8d3e                	mv	s10,a5
    80003b4c:	2781                	sext.w	a5,a5
    80003b4e:	0006861b          	sext.w	a2,a3
    80003b52:	f8f679e3          	bgeu	a2,a5,80003ae4 <readi+0x4c>
    80003b56:	8d36                	mv	s10,a3
    80003b58:	b771                	j	80003ae4 <readi+0x4c>
      brelse(bp);
    80003b5a:	854a                	mv	a0,s2
    80003b5c:	fffff097          	auipc	ra,0xfffff
    80003b60:	59e080e7          	jalr	1438(ra) # 800030fa <brelse>
      tot = -1;
    80003b64:	59fd                	li	s3,-1
  }
  return tot;
    80003b66:	0009851b          	sext.w	a0,s3
}
    80003b6a:	70a6                	ld	ra,104(sp)
    80003b6c:	7406                	ld	s0,96(sp)
    80003b6e:	64e6                	ld	s1,88(sp)
    80003b70:	6946                	ld	s2,80(sp)
    80003b72:	69a6                	ld	s3,72(sp)
    80003b74:	6a06                	ld	s4,64(sp)
    80003b76:	7ae2                	ld	s5,56(sp)
    80003b78:	7b42                	ld	s6,48(sp)
    80003b7a:	7ba2                	ld	s7,40(sp)
    80003b7c:	7c02                	ld	s8,32(sp)
    80003b7e:	6ce2                	ld	s9,24(sp)
    80003b80:	6d42                	ld	s10,16(sp)
    80003b82:	6da2                	ld	s11,8(sp)
    80003b84:	6165                	addi	sp,sp,112
    80003b86:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b88:	89d6                	mv	s3,s5
    80003b8a:	bff1                	j	80003b66 <readi+0xce>
    return 0;
    80003b8c:	4501                	li	a0,0
}
    80003b8e:	8082                	ret

0000000080003b90 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b90:	457c                	lw	a5,76(a0)
    80003b92:	10d7e863          	bltu	a5,a3,80003ca2 <writei+0x112>
{
    80003b96:	7159                	addi	sp,sp,-112
    80003b98:	f486                	sd	ra,104(sp)
    80003b9a:	f0a2                	sd	s0,96(sp)
    80003b9c:	eca6                	sd	s1,88(sp)
    80003b9e:	e8ca                	sd	s2,80(sp)
    80003ba0:	e4ce                	sd	s3,72(sp)
    80003ba2:	e0d2                	sd	s4,64(sp)
    80003ba4:	fc56                	sd	s5,56(sp)
    80003ba6:	f85a                	sd	s6,48(sp)
    80003ba8:	f45e                	sd	s7,40(sp)
    80003baa:	f062                	sd	s8,32(sp)
    80003bac:	ec66                	sd	s9,24(sp)
    80003bae:	e86a                	sd	s10,16(sp)
    80003bb0:	e46e                	sd	s11,8(sp)
    80003bb2:	1880                	addi	s0,sp,112
    80003bb4:	8aaa                	mv	s5,a0
    80003bb6:	8bae                	mv	s7,a1
    80003bb8:	8a32                	mv	s4,a2
    80003bba:	8936                	mv	s2,a3
    80003bbc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bbe:	00e687bb          	addw	a5,a3,a4
    80003bc2:	0ed7e263          	bltu	a5,a3,80003ca6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003bc6:	00043737          	lui	a4,0x43
    80003bca:	0ef76063          	bltu	a4,a5,80003caa <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bce:	0c0b0863          	beqz	s6,80003c9e <writei+0x10e>
    80003bd2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bd4:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bd8:	5c7d                	li	s8,-1
    80003bda:	a091                	j	80003c1e <writei+0x8e>
    80003bdc:	020d1d93          	slli	s11,s10,0x20
    80003be0:	020ddd93          	srli	s11,s11,0x20
    80003be4:	05848513          	addi	a0,s1,88
    80003be8:	86ee                	mv	a3,s11
    80003bea:	8652                	mv	a2,s4
    80003bec:	85de                	mv	a1,s7
    80003bee:	953a                	add	a0,a0,a4
    80003bf0:	fffff097          	auipc	ra,0xfffff
    80003bf4:	9ec080e7          	jalr	-1556(ra) # 800025dc <either_copyin>
    80003bf8:	07850263          	beq	a0,s8,80003c5c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bfc:	8526                	mv	a0,s1
    80003bfe:	00000097          	auipc	ra,0x0
    80003c02:	780080e7          	jalr	1920(ra) # 8000437e <log_write>
    brelse(bp);
    80003c06:	8526                	mv	a0,s1
    80003c08:	fffff097          	auipc	ra,0xfffff
    80003c0c:	4f2080e7          	jalr	1266(ra) # 800030fa <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c10:	013d09bb          	addw	s3,s10,s3
    80003c14:	012d093b          	addw	s2,s10,s2
    80003c18:	9a6e                	add	s4,s4,s11
    80003c1a:	0569f663          	bgeu	s3,s6,80003c66 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003c1e:	00a9559b          	srliw	a1,s2,0xa
    80003c22:	8556                	mv	a0,s5
    80003c24:	fffff097          	auipc	ra,0xfffff
    80003c28:	7a0080e7          	jalr	1952(ra) # 800033c4 <bmap>
    80003c2c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c30:	c99d                	beqz	a1,80003c66 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003c32:	000aa503          	lw	a0,0(s5)
    80003c36:	fffff097          	auipc	ra,0xfffff
    80003c3a:	394080e7          	jalr	916(ra) # 80002fca <bread>
    80003c3e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c40:	3ff97713          	andi	a4,s2,1023
    80003c44:	40ec87bb          	subw	a5,s9,a4
    80003c48:	413b06bb          	subw	a3,s6,s3
    80003c4c:	8d3e                	mv	s10,a5
    80003c4e:	2781                	sext.w	a5,a5
    80003c50:	0006861b          	sext.w	a2,a3
    80003c54:	f8f674e3          	bgeu	a2,a5,80003bdc <writei+0x4c>
    80003c58:	8d36                	mv	s10,a3
    80003c5a:	b749                	j	80003bdc <writei+0x4c>
      brelse(bp);
    80003c5c:	8526                	mv	a0,s1
    80003c5e:	fffff097          	auipc	ra,0xfffff
    80003c62:	49c080e7          	jalr	1180(ra) # 800030fa <brelse>
  }

  if(off > ip->size)
    80003c66:	04caa783          	lw	a5,76(s5)
    80003c6a:	0127f463          	bgeu	a5,s2,80003c72 <writei+0xe2>
    ip->size = off;
    80003c6e:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c72:	8556                	mv	a0,s5
    80003c74:	00000097          	auipc	ra,0x0
    80003c78:	aa6080e7          	jalr	-1370(ra) # 8000371a <iupdate>

  return tot;
    80003c7c:	0009851b          	sext.w	a0,s3
}
    80003c80:	70a6                	ld	ra,104(sp)
    80003c82:	7406                	ld	s0,96(sp)
    80003c84:	64e6                	ld	s1,88(sp)
    80003c86:	6946                	ld	s2,80(sp)
    80003c88:	69a6                	ld	s3,72(sp)
    80003c8a:	6a06                	ld	s4,64(sp)
    80003c8c:	7ae2                	ld	s5,56(sp)
    80003c8e:	7b42                	ld	s6,48(sp)
    80003c90:	7ba2                	ld	s7,40(sp)
    80003c92:	7c02                	ld	s8,32(sp)
    80003c94:	6ce2                	ld	s9,24(sp)
    80003c96:	6d42                	ld	s10,16(sp)
    80003c98:	6da2                	ld	s11,8(sp)
    80003c9a:	6165                	addi	sp,sp,112
    80003c9c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c9e:	89da                	mv	s3,s6
    80003ca0:	bfc9                	j	80003c72 <writei+0xe2>
    return -1;
    80003ca2:	557d                	li	a0,-1
}
    80003ca4:	8082                	ret
    return -1;
    80003ca6:	557d                	li	a0,-1
    80003ca8:	bfe1                	j	80003c80 <writei+0xf0>
    return -1;
    80003caa:	557d                	li	a0,-1
    80003cac:	bfd1                	j	80003c80 <writei+0xf0>

0000000080003cae <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003cae:	1141                	addi	sp,sp,-16
    80003cb0:	e406                	sd	ra,8(sp)
    80003cb2:	e022                	sd	s0,0(sp)
    80003cb4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003cb6:	4639                	li	a2,14
    80003cb8:	ffffd097          	auipc	ra,0xffffd
    80003cbc:	106080e7          	jalr	262(ra) # 80000dbe <strncmp>
}
    80003cc0:	60a2                	ld	ra,8(sp)
    80003cc2:	6402                	ld	s0,0(sp)
    80003cc4:	0141                	addi	sp,sp,16
    80003cc6:	8082                	ret

0000000080003cc8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003cc8:	7139                	addi	sp,sp,-64
    80003cca:	fc06                	sd	ra,56(sp)
    80003ccc:	f822                	sd	s0,48(sp)
    80003cce:	f426                	sd	s1,40(sp)
    80003cd0:	f04a                	sd	s2,32(sp)
    80003cd2:	ec4e                	sd	s3,24(sp)
    80003cd4:	e852                	sd	s4,16(sp)
    80003cd6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cd8:	04451703          	lh	a4,68(a0)
    80003cdc:	4785                	li	a5,1
    80003cde:	00f71a63          	bne	a4,a5,80003cf2 <dirlookup+0x2a>
    80003ce2:	892a                	mv	s2,a0
    80003ce4:	89ae                	mv	s3,a1
    80003ce6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ce8:	457c                	lw	a5,76(a0)
    80003cea:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cec:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cee:	e79d                	bnez	a5,80003d1c <dirlookup+0x54>
    80003cf0:	a8a5                	j	80003d68 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cf2:	00005517          	auipc	a0,0x5
    80003cf6:	8b650513          	addi	a0,a0,-1866 # 800085a8 <syscalls+0x1a0>
    80003cfa:	ffffd097          	auipc	ra,0xffffd
    80003cfe:	84a080e7          	jalr	-1974(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003d02:	00005517          	auipc	a0,0x5
    80003d06:	8be50513          	addi	a0,a0,-1858 # 800085c0 <syscalls+0x1b8>
    80003d0a:	ffffd097          	auipc	ra,0xffffd
    80003d0e:	83a080e7          	jalr	-1990(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d12:	24c1                	addiw	s1,s1,16
    80003d14:	04c92783          	lw	a5,76(s2)
    80003d18:	04f4f763          	bgeu	s1,a5,80003d66 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d1c:	4741                	li	a4,16
    80003d1e:	86a6                	mv	a3,s1
    80003d20:	fc040613          	addi	a2,s0,-64
    80003d24:	4581                	li	a1,0
    80003d26:	854a                	mv	a0,s2
    80003d28:	00000097          	auipc	ra,0x0
    80003d2c:	d70080e7          	jalr	-656(ra) # 80003a98 <readi>
    80003d30:	47c1                	li	a5,16
    80003d32:	fcf518e3          	bne	a0,a5,80003d02 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d36:	fc045783          	lhu	a5,-64(s0)
    80003d3a:	dfe1                	beqz	a5,80003d12 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d3c:	fc240593          	addi	a1,s0,-62
    80003d40:	854e                	mv	a0,s3
    80003d42:	00000097          	auipc	ra,0x0
    80003d46:	f6c080e7          	jalr	-148(ra) # 80003cae <namecmp>
    80003d4a:	f561                	bnez	a0,80003d12 <dirlookup+0x4a>
      if(poff)
    80003d4c:	000a0463          	beqz	s4,80003d54 <dirlookup+0x8c>
        *poff = off;
    80003d50:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d54:	fc045583          	lhu	a1,-64(s0)
    80003d58:	00092503          	lw	a0,0(s2)
    80003d5c:	fffff097          	auipc	ra,0xfffff
    80003d60:	750080e7          	jalr	1872(ra) # 800034ac <iget>
    80003d64:	a011                	j	80003d68 <dirlookup+0xa0>
  return 0;
    80003d66:	4501                	li	a0,0
}
    80003d68:	70e2                	ld	ra,56(sp)
    80003d6a:	7442                	ld	s0,48(sp)
    80003d6c:	74a2                	ld	s1,40(sp)
    80003d6e:	7902                	ld	s2,32(sp)
    80003d70:	69e2                	ld	s3,24(sp)
    80003d72:	6a42                	ld	s4,16(sp)
    80003d74:	6121                	addi	sp,sp,64
    80003d76:	8082                	ret

0000000080003d78 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d78:	711d                	addi	sp,sp,-96
    80003d7a:	ec86                	sd	ra,88(sp)
    80003d7c:	e8a2                	sd	s0,80(sp)
    80003d7e:	e4a6                	sd	s1,72(sp)
    80003d80:	e0ca                	sd	s2,64(sp)
    80003d82:	fc4e                	sd	s3,56(sp)
    80003d84:	f852                	sd	s4,48(sp)
    80003d86:	f456                	sd	s5,40(sp)
    80003d88:	f05a                	sd	s6,32(sp)
    80003d8a:	ec5e                	sd	s7,24(sp)
    80003d8c:	e862                	sd	s8,16(sp)
    80003d8e:	e466                	sd	s9,8(sp)
    80003d90:	1080                	addi	s0,sp,96
    80003d92:	84aa                	mv	s1,a0
    80003d94:	8b2e                	mv	s6,a1
    80003d96:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d98:	00054703          	lbu	a4,0(a0)
    80003d9c:	02f00793          	li	a5,47
    80003da0:	02f70363          	beq	a4,a5,80003dc6 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003da4:	ffffe097          	auipc	ra,0xffffe
    80003da8:	d36080e7          	jalr	-714(ra) # 80001ada <myproc>
    80003dac:	15053503          	ld	a0,336(a0)
    80003db0:	00000097          	auipc	ra,0x0
    80003db4:	9f6080e7          	jalr	-1546(ra) # 800037a6 <idup>
    80003db8:	89aa                	mv	s3,a0
  while(*path == '/')
    80003dba:	02f00913          	li	s2,47
  len = path - s;
    80003dbe:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003dc0:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003dc2:	4c05                	li	s8,1
    80003dc4:	a865                	j	80003e7c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003dc6:	4585                	li	a1,1
    80003dc8:	4505                	li	a0,1
    80003dca:	fffff097          	auipc	ra,0xfffff
    80003dce:	6e2080e7          	jalr	1762(ra) # 800034ac <iget>
    80003dd2:	89aa                	mv	s3,a0
    80003dd4:	b7dd                	j	80003dba <namex+0x42>
      iunlockput(ip);
    80003dd6:	854e                	mv	a0,s3
    80003dd8:	00000097          	auipc	ra,0x0
    80003ddc:	c6e080e7          	jalr	-914(ra) # 80003a46 <iunlockput>
      return 0;
    80003de0:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003de2:	854e                	mv	a0,s3
    80003de4:	60e6                	ld	ra,88(sp)
    80003de6:	6446                	ld	s0,80(sp)
    80003de8:	64a6                	ld	s1,72(sp)
    80003dea:	6906                	ld	s2,64(sp)
    80003dec:	79e2                	ld	s3,56(sp)
    80003dee:	7a42                	ld	s4,48(sp)
    80003df0:	7aa2                	ld	s5,40(sp)
    80003df2:	7b02                	ld	s6,32(sp)
    80003df4:	6be2                	ld	s7,24(sp)
    80003df6:	6c42                	ld	s8,16(sp)
    80003df8:	6ca2                	ld	s9,8(sp)
    80003dfa:	6125                	addi	sp,sp,96
    80003dfc:	8082                	ret
      iunlock(ip);
    80003dfe:	854e                	mv	a0,s3
    80003e00:	00000097          	auipc	ra,0x0
    80003e04:	aa6080e7          	jalr	-1370(ra) # 800038a6 <iunlock>
      return ip;
    80003e08:	bfe9                	j	80003de2 <namex+0x6a>
      iunlockput(ip);
    80003e0a:	854e                	mv	a0,s3
    80003e0c:	00000097          	auipc	ra,0x0
    80003e10:	c3a080e7          	jalr	-966(ra) # 80003a46 <iunlockput>
      return 0;
    80003e14:	89d2                	mv	s3,s4
    80003e16:	b7f1                	j	80003de2 <namex+0x6a>
  len = path - s;
    80003e18:	40b48633          	sub	a2,s1,a1
    80003e1c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e20:	094cd463          	bge	s9,s4,80003ea8 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e24:	4639                	li	a2,14
    80003e26:	8556                	mv	a0,s5
    80003e28:	ffffd097          	auipc	ra,0xffffd
    80003e2c:	f1e080e7          	jalr	-226(ra) # 80000d46 <memmove>
  while(*path == '/')
    80003e30:	0004c783          	lbu	a5,0(s1)
    80003e34:	01279763          	bne	a5,s2,80003e42 <namex+0xca>
    path++;
    80003e38:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e3a:	0004c783          	lbu	a5,0(s1)
    80003e3e:	ff278de3          	beq	a5,s2,80003e38 <namex+0xc0>
    ilock(ip);
    80003e42:	854e                	mv	a0,s3
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	9a0080e7          	jalr	-1632(ra) # 800037e4 <ilock>
    if(ip->type != T_DIR){
    80003e4c:	04499783          	lh	a5,68(s3)
    80003e50:	f98793e3          	bne	a5,s8,80003dd6 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e54:	000b0563          	beqz	s6,80003e5e <namex+0xe6>
    80003e58:	0004c783          	lbu	a5,0(s1)
    80003e5c:	d3cd                	beqz	a5,80003dfe <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e5e:	865e                	mv	a2,s7
    80003e60:	85d6                	mv	a1,s5
    80003e62:	854e                	mv	a0,s3
    80003e64:	00000097          	auipc	ra,0x0
    80003e68:	e64080e7          	jalr	-412(ra) # 80003cc8 <dirlookup>
    80003e6c:	8a2a                	mv	s4,a0
    80003e6e:	dd51                	beqz	a0,80003e0a <namex+0x92>
    iunlockput(ip);
    80003e70:	854e                	mv	a0,s3
    80003e72:	00000097          	auipc	ra,0x0
    80003e76:	bd4080e7          	jalr	-1068(ra) # 80003a46 <iunlockput>
    ip = next;
    80003e7a:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e7c:	0004c783          	lbu	a5,0(s1)
    80003e80:	05279763          	bne	a5,s2,80003ece <namex+0x156>
    path++;
    80003e84:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e86:	0004c783          	lbu	a5,0(s1)
    80003e8a:	ff278de3          	beq	a5,s2,80003e84 <namex+0x10c>
  if(*path == 0)
    80003e8e:	c79d                	beqz	a5,80003ebc <namex+0x144>
    path++;
    80003e90:	85a6                	mv	a1,s1
  len = path - s;
    80003e92:	8a5e                	mv	s4,s7
    80003e94:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e96:	01278963          	beq	a5,s2,80003ea8 <namex+0x130>
    80003e9a:	dfbd                	beqz	a5,80003e18 <namex+0xa0>
    path++;
    80003e9c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e9e:	0004c783          	lbu	a5,0(s1)
    80003ea2:	ff279ce3          	bne	a5,s2,80003e9a <namex+0x122>
    80003ea6:	bf8d                	j	80003e18 <namex+0xa0>
    memmove(name, s, len);
    80003ea8:	2601                	sext.w	a2,a2
    80003eaa:	8556                	mv	a0,s5
    80003eac:	ffffd097          	auipc	ra,0xffffd
    80003eb0:	e9a080e7          	jalr	-358(ra) # 80000d46 <memmove>
    name[len] = 0;
    80003eb4:	9a56                	add	s4,s4,s5
    80003eb6:	000a0023          	sb	zero,0(s4)
    80003eba:	bf9d                	j	80003e30 <namex+0xb8>
  if(nameiparent){
    80003ebc:	f20b03e3          	beqz	s6,80003de2 <namex+0x6a>
    iput(ip);
    80003ec0:	854e                	mv	a0,s3
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	adc080e7          	jalr	-1316(ra) # 8000399e <iput>
    return 0;
    80003eca:	4981                	li	s3,0
    80003ecc:	bf19                	j	80003de2 <namex+0x6a>
  if(*path == 0)
    80003ece:	d7fd                	beqz	a5,80003ebc <namex+0x144>
  while(*path != '/' && *path != 0)
    80003ed0:	0004c783          	lbu	a5,0(s1)
    80003ed4:	85a6                	mv	a1,s1
    80003ed6:	b7d1                	j	80003e9a <namex+0x122>

0000000080003ed8 <dirlink>:
{
    80003ed8:	7139                	addi	sp,sp,-64
    80003eda:	fc06                	sd	ra,56(sp)
    80003edc:	f822                	sd	s0,48(sp)
    80003ede:	f426                	sd	s1,40(sp)
    80003ee0:	f04a                	sd	s2,32(sp)
    80003ee2:	ec4e                	sd	s3,24(sp)
    80003ee4:	e852                	sd	s4,16(sp)
    80003ee6:	0080                	addi	s0,sp,64
    80003ee8:	892a                	mv	s2,a0
    80003eea:	8a2e                	mv	s4,a1
    80003eec:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003eee:	4601                	li	a2,0
    80003ef0:	00000097          	auipc	ra,0x0
    80003ef4:	dd8080e7          	jalr	-552(ra) # 80003cc8 <dirlookup>
    80003ef8:	e93d                	bnez	a0,80003f6e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003efa:	04c92483          	lw	s1,76(s2)
    80003efe:	c49d                	beqz	s1,80003f2c <dirlink+0x54>
    80003f00:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f02:	4741                	li	a4,16
    80003f04:	86a6                	mv	a3,s1
    80003f06:	fc040613          	addi	a2,s0,-64
    80003f0a:	4581                	li	a1,0
    80003f0c:	854a                	mv	a0,s2
    80003f0e:	00000097          	auipc	ra,0x0
    80003f12:	b8a080e7          	jalr	-1142(ra) # 80003a98 <readi>
    80003f16:	47c1                	li	a5,16
    80003f18:	06f51163          	bne	a0,a5,80003f7a <dirlink+0xa2>
    if(de.inum == 0)
    80003f1c:	fc045783          	lhu	a5,-64(s0)
    80003f20:	c791                	beqz	a5,80003f2c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f22:	24c1                	addiw	s1,s1,16
    80003f24:	04c92783          	lw	a5,76(s2)
    80003f28:	fcf4ede3          	bltu	s1,a5,80003f02 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f2c:	4639                	li	a2,14
    80003f2e:	85d2                	mv	a1,s4
    80003f30:	fc240513          	addi	a0,s0,-62
    80003f34:	ffffd097          	auipc	ra,0xffffd
    80003f38:	ec6080e7          	jalr	-314(ra) # 80000dfa <strncpy>
  de.inum = inum;
    80003f3c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f40:	4741                	li	a4,16
    80003f42:	86a6                	mv	a3,s1
    80003f44:	fc040613          	addi	a2,s0,-64
    80003f48:	4581                	li	a1,0
    80003f4a:	854a                	mv	a0,s2
    80003f4c:	00000097          	auipc	ra,0x0
    80003f50:	c44080e7          	jalr	-956(ra) # 80003b90 <writei>
    80003f54:	1541                	addi	a0,a0,-16
    80003f56:	00a03533          	snez	a0,a0
    80003f5a:	40a00533          	neg	a0,a0
}
    80003f5e:	70e2                	ld	ra,56(sp)
    80003f60:	7442                	ld	s0,48(sp)
    80003f62:	74a2                	ld	s1,40(sp)
    80003f64:	7902                	ld	s2,32(sp)
    80003f66:	69e2                	ld	s3,24(sp)
    80003f68:	6a42                	ld	s4,16(sp)
    80003f6a:	6121                	addi	sp,sp,64
    80003f6c:	8082                	ret
    iput(ip);
    80003f6e:	00000097          	auipc	ra,0x0
    80003f72:	a30080e7          	jalr	-1488(ra) # 8000399e <iput>
    return -1;
    80003f76:	557d                	li	a0,-1
    80003f78:	b7dd                	j	80003f5e <dirlink+0x86>
      panic("dirlink read");
    80003f7a:	00004517          	auipc	a0,0x4
    80003f7e:	65650513          	addi	a0,a0,1622 # 800085d0 <syscalls+0x1c8>
    80003f82:	ffffc097          	auipc	ra,0xffffc
    80003f86:	5c2080e7          	jalr	1474(ra) # 80000544 <panic>

0000000080003f8a <namei>:

struct inode*
namei(char *path)
{
    80003f8a:	1101                	addi	sp,sp,-32
    80003f8c:	ec06                	sd	ra,24(sp)
    80003f8e:	e822                	sd	s0,16(sp)
    80003f90:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f92:	fe040613          	addi	a2,s0,-32
    80003f96:	4581                	li	a1,0
    80003f98:	00000097          	auipc	ra,0x0
    80003f9c:	de0080e7          	jalr	-544(ra) # 80003d78 <namex>
}
    80003fa0:	60e2                	ld	ra,24(sp)
    80003fa2:	6442                	ld	s0,16(sp)
    80003fa4:	6105                	addi	sp,sp,32
    80003fa6:	8082                	ret

0000000080003fa8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003fa8:	1141                	addi	sp,sp,-16
    80003faa:	e406                	sd	ra,8(sp)
    80003fac:	e022                	sd	s0,0(sp)
    80003fae:	0800                	addi	s0,sp,16
    80003fb0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003fb2:	4585                	li	a1,1
    80003fb4:	00000097          	auipc	ra,0x0
    80003fb8:	dc4080e7          	jalr	-572(ra) # 80003d78 <namex>
}
    80003fbc:	60a2                	ld	ra,8(sp)
    80003fbe:	6402                	ld	s0,0(sp)
    80003fc0:	0141                	addi	sp,sp,16
    80003fc2:	8082                	ret

0000000080003fc4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fc4:	1101                	addi	sp,sp,-32
    80003fc6:	ec06                	sd	ra,24(sp)
    80003fc8:	e822                	sd	s0,16(sp)
    80003fca:	e426                	sd	s1,8(sp)
    80003fcc:	e04a                	sd	s2,0(sp)
    80003fce:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fd0:	0001d917          	auipc	s2,0x1d
    80003fd4:	af090913          	addi	s2,s2,-1296 # 80020ac0 <log>
    80003fd8:	01892583          	lw	a1,24(s2)
    80003fdc:	02892503          	lw	a0,40(s2)
    80003fe0:	fffff097          	auipc	ra,0xfffff
    80003fe4:	fea080e7          	jalr	-22(ra) # 80002fca <bread>
    80003fe8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fea:	02c92683          	lw	a3,44(s2)
    80003fee:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003ff0:	02d05763          	blez	a3,8000401e <write_head+0x5a>
    80003ff4:	0001d797          	auipc	a5,0x1d
    80003ff8:	afc78793          	addi	a5,a5,-1284 # 80020af0 <log+0x30>
    80003ffc:	05c50713          	addi	a4,a0,92
    80004000:	36fd                	addiw	a3,a3,-1
    80004002:	1682                	slli	a3,a3,0x20
    80004004:	9281                	srli	a3,a3,0x20
    80004006:	068a                	slli	a3,a3,0x2
    80004008:	0001d617          	auipc	a2,0x1d
    8000400c:	aec60613          	addi	a2,a2,-1300 # 80020af4 <log+0x34>
    80004010:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004012:	4390                	lw	a2,0(a5)
    80004014:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004016:	0791                	addi	a5,a5,4
    80004018:	0711                	addi	a4,a4,4
    8000401a:	fed79ce3          	bne	a5,a3,80004012 <write_head+0x4e>
  }
  bwrite(buf);
    8000401e:	8526                	mv	a0,s1
    80004020:	fffff097          	auipc	ra,0xfffff
    80004024:	09c080e7          	jalr	156(ra) # 800030bc <bwrite>
  brelse(buf);
    80004028:	8526                	mv	a0,s1
    8000402a:	fffff097          	auipc	ra,0xfffff
    8000402e:	0d0080e7          	jalr	208(ra) # 800030fa <brelse>
}
    80004032:	60e2                	ld	ra,24(sp)
    80004034:	6442                	ld	s0,16(sp)
    80004036:	64a2                	ld	s1,8(sp)
    80004038:	6902                	ld	s2,0(sp)
    8000403a:	6105                	addi	sp,sp,32
    8000403c:	8082                	ret

000000008000403e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000403e:	0001d797          	auipc	a5,0x1d
    80004042:	aae7a783          	lw	a5,-1362(a5) # 80020aec <log+0x2c>
    80004046:	0af05d63          	blez	a5,80004100 <install_trans+0xc2>
{
    8000404a:	7139                	addi	sp,sp,-64
    8000404c:	fc06                	sd	ra,56(sp)
    8000404e:	f822                	sd	s0,48(sp)
    80004050:	f426                	sd	s1,40(sp)
    80004052:	f04a                	sd	s2,32(sp)
    80004054:	ec4e                	sd	s3,24(sp)
    80004056:	e852                	sd	s4,16(sp)
    80004058:	e456                	sd	s5,8(sp)
    8000405a:	e05a                	sd	s6,0(sp)
    8000405c:	0080                	addi	s0,sp,64
    8000405e:	8b2a                	mv	s6,a0
    80004060:	0001da97          	auipc	s5,0x1d
    80004064:	a90a8a93          	addi	s5,s5,-1392 # 80020af0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004068:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000406a:	0001d997          	auipc	s3,0x1d
    8000406e:	a5698993          	addi	s3,s3,-1450 # 80020ac0 <log>
    80004072:	a035                	j	8000409e <install_trans+0x60>
      bunpin(dbuf);
    80004074:	8526                	mv	a0,s1
    80004076:	fffff097          	auipc	ra,0xfffff
    8000407a:	15e080e7          	jalr	350(ra) # 800031d4 <bunpin>
    brelse(lbuf);
    8000407e:	854a                	mv	a0,s2
    80004080:	fffff097          	auipc	ra,0xfffff
    80004084:	07a080e7          	jalr	122(ra) # 800030fa <brelse>
    brelse(dbuf);
    80004088:	8526                	mv	a0,s1
    8000408a:	fffff097          	auipc	ra,0xfffff
    8000408e:	070080e7          	jalr	112(ra) # 800030fa <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004092:	2a05                	addiw	s4,s4,1
    80004094:	0a91                	addi	s5,s5,4
    80004096:	02c9a783          	lw	a5,44(s3)
    8000409a:	04fa5963          	bge	s4,a5,800040ec <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000409e:	0189a583          	lw	a1,24(s3)
    800040a2:	014585bb          	addw	a1,a1,s4
    800040a6:	2585                	addiw	a1,a1,1
    800040a8:	0289a503          	lw	a0,40(s3)
    800040ac:	fffff097          	auipc	ra,0xfffff
    800040b0:	f1e080e7          	jalr	-226(ra) # 80002fca <bread>
    800040b4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040b6:	000aa583          	lw	a1,0(s5)
    800040ba:	0289a503          	lw	a0,40(s3)
    800040be:	fffff097          	auipc	ra,0xfffff
    800040c2:	f0c080e7          	jalr	-244(ra) # 80002fca <bread>
    800040c6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040c8:	40000613          	li	a2,1024
    800040cc:	05890593          	addi	a1,s2,88
    800040d0:	05850513          	addi	a0,a0,88
    800040d4:	ffffd097          	auipc	ra,0xffffd
    800040d8:	c72080e7          	jalr	-910(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    800040dc:	8526                	mv	a0,s1
    800040de:	fffff097          	auipc	ra,0xfffff
    800040e2:	fde080e7          	jalr	-34(ra) # 800030bc <bwrite>
    if(recovering == 0)
    800040e6:	f80b1ce3          	bnez	s6,8000407e <install_trans+0x40>
    800040ea:	b769                	j	80004074 <install_trans+0x36>
}
    800040ec:	70e2                	ld	ra,56(sp)
    800040ee:	7442                	ld	s0,48(sp)
    800040f0:	74a2                	ld	s1,40(sp)
    800040f2:	7902                	ld	s2,32(sp)
    800040f4:	69e2                	ld	s3,24(sp)
    800040f6:	6a42                	ld	s4,16(sp)
    800040f8:	6aa2                	ld	s5,8(sp)
    800040fa:	6b02                	ld	s6,0(sp)
    800040fc:	6121                	addi	sp,sp,64
    800040fe:	8082                	ret
    80004100:	8082                	ret

0000000080004102 <initlog>:
{
    80004102:	7179                	addi	sp,sp,-48
    80004104:	f406                	sd	ra,40(sp)
    80004106:	f022                	sd	s0,32(sp)
    80004108:	ec26                	sd	s1,24(sp)
    8000410a:	e84a                	sd	s2,16(sp)
    8000410c:	e44e                	sd	s3,8(sp)
    8000410e:	1800                	addi	s0,sp,48
    80004110:	892a                	mv	s2,a0
    80004112:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004114:	0001d497          	auipc	s1,0x1d
    80004118:	9ac48493          	addi	s1,s1,-1620 # 80020ac0 <log>
    8000411c:	00004597          	auipc	a1,0x4
    80004120:	4c458593          	addi	a1,a1,1220 # 800085e0 <syscalls+0x1d8>
    80004124:	8526                	mv	a0,s1
    80004126:	ffffd097          	auipc	ra,0xffffd
    8000412a:	a34080e7          	jalr	-1484(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    8000412e:	0149a583          	lw	a1,20(s3)
    80004132:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004134:	0109a783          	lw	a5,16(s3)
    80004138:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000413a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000413e:	854a                	mv	a0,s2
    80004140:	fffff097          	auipc	ra,0xfffff
    80004144:	e8a080e7          	jalr	-374(ra) # 80002fca <bread>
  log.lh.n = lh->n;
    80004148:	4d3c                	lw	a5,88(a0)
    8000414a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000414c:	02f05563          	blez	a5,80004176 <initlog+0x74>
    80004150:	05c50713          	addi	a4,a0,92
    80004154:	0001d697          	auipc	a3,0x1d
    80004158:	99c68693          	addi	a3,a3,-1636 # 80020af0 <log+0x30>
    8000415c:	37fd                	addiw	a5,a5,-1
    8000415e:	1782                	slli	a5,a5,0x20
    80004160:	9381                	srli	a5,a5,0x20
    80004162:	078a                	slli	a5,a5,0x2
    80004164:	06050613          	addi	a2,a0,96
    80004168:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000416a:	4310                	lw	a2,0(a4)
    8000416c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000416e:	0711                	addi	a4,a4,4
    80004170:	0691                	addi	a3,a3,4
    80004172:	fef71ce3          	bne	a4,a5,8000416a <initlog+0x68>
  brelse(buf);
    80004176:	fffff097          	auipc	ra,0xfffff
    8000417a:	f84080e7          	jalr	-124(ra) # 800030fa <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000417e:	4505                	li	a0,1
    80004180:	00000097          	auipc	ra,0x0
    80004184:	ebe080e7          	jalr	-322(ra) # 8000403e <install_trans>
  log.lh.n = 0;
    80004188:	0001d797          	auipc	a5,0x1d
    8000418c:	9607a223          	sw	zero,-1692(a5) # 80020aec <log+0x2c>
  write_head(); // clear the log
    80004190:	00000097          	auipc	ra,0x0
    80004194:	e34080e7          	jalr	-460(ra) # 80003fc4 <write_head>
}
    80004198:	70a2                	ld	ra,40(sp)
    8000419a:	7402                	ld	s0,32(sp)
    8000419c:	64e2                	ld	s1,24(sp)
    8000419e:	6942                	ld	s2,16(sp)
    800041a0:	69a2                	ld	s3,8(sp)
    800041a2:	6145                	addi	sp,sp,48
    800041a4:	8082                	ret

00000000800041a6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041a6:	1101                	addi	sp,sp,-32
    800041a8:	ec06                	sd	ra,24(sp)
    800041aa:	e822                	sd	s0,16(sp)
    800041ac:	e426                	sd	s1,8(sp)
    800041ae:	e04a                	sd	s2,0(sp)
    800041b0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041b2:	0001d517          	auipc	a0,0x1d
    800041b6:	90e50513          	addi	a0,a0,-1778 # 80020ac0 <log>
    800041ba:	ffffd097          	auipc	ra,0xffffd
    800041be:	a30080e7          	jalr	-1488(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    800041c2:	0001d497          	auipc	s1,0x1d
    800041c6:	8fe48493          	addi	s1,s1,-1794 # 80020ac0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041ca:	4979                	li	s2,30
    800041cc:	a039                	j	800041da <begin_op+0x34>
      sleep(&log, &log.lock);
    800041ce:	85a6                	mv	a1,s1
    800041d0:	8526                	mv	a0,s1
    800041d2:	ffffe097          	auipc	ra,0xffffe
    800041d6:	fac080e7          	jalr	-84(ra) # 8000217e <sleep>
    if(log.committing){
    800041da:	50dc                	lw	a5,36(s1)
    800041dc:	fbed                	bnez	a5,800041ce <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041de:	509c                	lw	a5,32(s1)
    800041e0:	0017871b          	addiw	a4,a5,1
    800041e4:	0007069b          	sext.w	a3,a4
    800041e8:	0027179b          	slliw	a5,a4,0x2
    800041ec:	9fb9                	addw	a5,a5,a4
    800041ee:	0017979b          	slliw	a5,a5,0x1
    800041f2:	54d8                	lw	a4,44(s1)
    800041f4:	9fb9                	addw	a5,a5,a4
    800041f6:	00f95963          	bge	s2,a5,80004208 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041fa:	85a6                	mv	a1,s1
    800041fc:	8526                	mv	a0,s1
    800041fe:	ffffe097          	auipc	ra,0xffffe
    80004202:	f80080e7          	jalr	-128(ra) # 8000217e <sleep>
    80004206:	bfd1                	j	800041da <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004208:	0001d517          	auipc	a0,0x1d
    8000420c:	8b850513          	addi	a0,a0,-1864 # 80020ac0 <log>
    80004210:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004212:	ffffd097          	auipc	ra,0xffffd
    80004216:	a8c080e7          	jalr	-1396(ra) # 80000c9e <release>
      break;
    }
  }
}
    8000421a:	60e2                	ld	ra,24(sp)
    8000421c:	6442                	ld	s0,16(sp)
    8000421e:	64a2                	ld	s1,8(sp)
    80004220:	6902                	ld	s2,0(sp)
    80004222:	6105                	addi	sp,sp,32
    80004224:	8082                	ret

0000000080004226 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004226:	7139                	addi	sp,sp,-64
    80004228:	fc06                	sd	ra,56(sp)
    8000422a:	f822                	sd	s0,48(sp)
    8000422c:	f426                	sd	s1,40(sp)
    8000422e:	f04a                	sd	s2,32(sp)
    80004230:	ec4e                	sd	s3,24(sp)
    80004232:	e852                	sd	s4,16(sp)
    80004234:	e456                	sd	s5,8(sp)
    80004236:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004238:	0001d497          	auipc	s1,0x1d
    8000423c:	88848493          	addi	s1,s1,-1912 # 80020ac0 <log>
    80004240:	8526                	mv	a0,s1
    80004242:	ffffd097          	auipc	ra,0xffffd
    80004246:	9a8080e7          	jalr	-1624(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    8000424a:	509c                	lw	a5,32(s1)
    8000424c:	37fd                	addiw	a5,a5,-1
    8000424e:	0007891b          	sext.w	s2,a5
    80004252:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004254:	50dc                	lw	a5,36(s1)
    80004256:	efb9                	bnez	a5,800042b4 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004258:	06091663          	bnez	s2,800042c4 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000425c:	0001d497          	auipc	s1,0x1d
    80004260:	86448493          	addi	s1,s1,-1948 # 80020ac0 <log>
    80004264:	4785                	li	a5,1
    80004266:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004268:	8526                	mv	a0,s1
    8000426a:	ffffd097          	auipc	ra,0xffffd
    8000426e:	a34080e7          	jalr	-1484(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004272:	54dc                	lw	a5,44(s1)
    80004274:	06f04763          	bgtz	a5,800042e2 <end_op+0xbc>
    acquire(&log.lock);
    80004278:	0001d497          	auipc	s1,0x1d
    8000427c:	84848493          	addi	s1,s1,-1976 # 80020ac0 <log>
    80004280:	8526                	mv	a0,s1
    80004282:	ffffd097          	auipc	ra,0xffffd
    80004286:	968080e7          	jalr	-1688(ra) # 80000bea <acquire>
    log.committing = 0;
    8000428a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000428e:	8526                	mv	a0,s1
    80004290:	ffffe097          	auipc	ra,0xffffe
    80004294:	f52080e7          	jalr	-174(ra) # 800021e2 <wakeup>
    release(&log.lock);
    80004298:	8526                	mv	a0,s1
    8000429a:	ffffd097          	auipc	ra,0xffffd
    8000429e:	a04080e7          	jalr	-1532(ra) # 80000c9e <release>
}
    800042a2:	70e2                	ld	ra,56(sp)
    800042a4:	7442                	ld	s0,48(sp)
    800042a6:	74a2                	ld	s1,40(sp)
    800042a8:	7902                	ld	s2,32(sp)
    800042aa:	69e2                	ld	s3,24(sp)
    800042ac:	6a42                	ld	s4,16(sp)
    800042ae:	6aa2                	ld	s5,8(sp)
    800042b0:	6121                	addi	sp,sp,64
    800042b2:	8082                	ret
    panic("log.committing");
    800042b4:	00004517          	auipc	a0,0x4
    800042b8:	33450513          	addi	a0,a0,820 # 800085e8 <syscalls+0x1e0>
    800042bc:	ffffc097          	auipc	ra,0xffffc
    800042c0:	288080e7          	jalr	648(ra) # 80000544 <panic>
    wakeup(&log);
    800042c4:	0001c497          	auipc	s1,0x1c
    800042c8:	7fc48493          	addi	s1,s1,2044 # 80020ac0 <log>
    800042cc:	8526                	mv	a0,s1
    800042ce:	ffffe097          	auipc	ra,0xffffe
    800042d2:	f14080e7          	jalr	-236(ra) # 800021e2 <wakeup>
  release(&log.lock);
    800042d6:	8526                	mv	a0,s1
    800042d8:	ffffd097          	auipc	ra,0xffffd
    800042dc:	9c6080e7          	jalr	-1594(ra) # 80000c9e <release>
  if(do_commit){
    800042e0:	b7c9                	j	800042a2 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042e2:	0001da97          	auipc	s5,0x1d
    800042e6:	80ea8a93          	addi	s5,s5,-2034 # 80020af0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042ea:	0001ca17          	auipc	s4,0x1c
    800042ee:	7d6a0a13          	addi	s4,s4,2006 # 80020ac0 <log>
    800042f2:	018a2583          	lw	a1,24(s4)
    800042f6:	012585bb          	addw	a1,a1,s2
    800042fa:	2585                	addiw	a1,a1,1
    800042fc:	028a2503          	lw	a0,40(s4)
    80004300:	fffff097          	auipc	ra,0xfffff
    80004304:	cca080e7          	jalr	-822(ra) # 80002fca <bread>
    80004308:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000430a:	000aa583          	lw	a1,0(s5)
    8000430e:	028a2503          	lw	a0,40(s4)
    80004312:	fffff097          	auipc	ra,0xfffff
    80004316:	cb8080e7          	jalr	-840(ra) # 80002fca <bread>
    8000431a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000431c:	40000613          	li	a2,1024
    80004320:	05850593          	addi	a1,a0,88
    80004324:	05848513          	addi	a0,s1,88
    80004328:	ffffd097          	auipc	ra,0xffffd
    8000432c:	a1e080e7          	jalr	-1506(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004330:	8526                	mv	a0,s1
    80004332:	fffff097          	auipc	ra,0xfffff
    80004336:	d8a080e7          	jalr	-630(ra) # 800030bc <bwrite>
    brelse(from);
    8000433a:	854e                	mv	a0,s3
    8000433c:	fffff097          	auipc	ra,0xfffff
    80004340:	dbe080e7          	jalr	-578(ra) # 800030fa <brelse>
    brelse(to);
    80004344:	8526                	mv	a0,s1
    80004346:	fffff097          	auipc	ra,0xfffff
    8000434a:	db4080e7          	jalr	-588(ra) # 800030fa <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000434e:	2905                	addiw	s2,s2,1
    80004350:	0a91                	addi	s5,s5,4
    80004352:	02ca2783          	lw	a5,44(s4)
    80004356:	f8f94ee3          	blt	s2,a5,800042f2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000435a:	00000097          	auipc	ra,0x0
    8000435e:	c6a080e7          	jalr	-918(ra) # 80003fc4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004362:	4501                	li	a0,0
    80004364:	00000097          	auipc	ra,0x0
    80004368:	cda080e7          	jalr	-806(ra) # 8000403e <install_trans>
    log.lh.n = 0;
    8000436c:	0001c797          	auipc	a5,0x1c
    80004370:	7807a023          	sw	zero,1920(a5) # 80020aec <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004374:	00000097          	auipc	ra,0x0
    80004378:	c50080e7          	jalr	-944(ra) # 80003fc4 <write_head>
    8000437c:	bdf5                	j	80004278 <end_op+0x52>

000000008000437e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000437e:	1101                	addi	sp,sp,-32
    80004380:	ec06                	sd	ra,24(sp)
    80004382:	e822                	sd	s0,16(sp)
    80004384:	e426                	sd	s1,8(sp)
    80004386:	e04a                	sd	s2,0(sp)
    80004388:	1000                	addi	s0,sp,32
    8000438a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000438c:	0001c917          	auipc	s2,0x1c
    80004390:	73490913          	addi	s2,s2,1844 # 80020ac0 <log>
    80004394:	854a                	mv	a0,s2
    80004396:	ffffd097          	auipc	ra,0xffffd
    8000439a:	854080e7          	jalr	-1964(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000439e:	02c92603          	lw	a2,44(s2)
    800043a2:	47f5                	li	a5,29
    800043a4:	06c7c563          	blt	a5,a2,8000440e <log_write+0x90>
    800043a8:	0001c797          	auipc	a5,0x1c
    800043ac:	7347a783          	lw	a5,1844(a5) # 80020adc <log+0x1c>
    800043b0:	37fd                	addiw	a5,a5,-1
    800043b2:	04f65e63          	bge	a2,a5,8000440e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043b6:	0001c797          	auipc	a5,0x1c
    800043ba:	72a7a783          	lw	a5,1834(a5) # 80020ae0 <log+0x20>
    800043be:	06f05063          	blez	a5,8000441e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800043c2:	4781                	li	a5,0
    800043c4:	06c05563          	blez	a2,8000442e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043c8:	44cc                	lw	a1,12(s1)
    800043ca:	0001c717          	auipc	a4,0x1c
    800043ce:	72670713          	addi	a4,a4,1830 # 80020af0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043d2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043d4:	4314                	lw	a3,0(a4)
    800043d6:	04b68c63          	beq	a3,a1,8000442e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043da:	2785                	addiw	a5,a5,1
    800043dc:	0711                	addi	a4,a4,4
    800043de:	fef61be3          	bne	a2,a5,800043d4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043e2:	0621                	addi	a2,a2,8
    800043e4:	060a                	slli	a2,a2,0x2
    800043e6:	0001c797          	auipc	a5,0x1c
    800043ea:	6da78793          	addi	a5,a5,1754 # 80020ac0 <log>
    800043ee:	963e                	add	a2,a2,a5
    800043f0:	44dc                	lw	a5,12(s1)
    800043f2:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043f4:	8526                	mv	a0,s1
    800043f6:	fffff097          	auipc	ra,0xfffff
    800043fa:	da2080e7          	jalr	-606(ra) # 80003198 <bpin>
    log.lh.n++;
    800043fe:	0001c717          	auipc	a4,0x1c
    80004402:	6c270713          	addi	a4,a4,1730 # 80020ac0 <log>
    80004406:	575c                	lw	a5,44(a4)
    80004408:	2785                	addiw	a5,a5,1
    8000440a:	d75c                	sw	a5,44(a4)
    8000440c:	a835                	j	80004448 <log_write+0xca>
    panic("too big a transaction");
    8000440e:	00004517          	auipc	a0,0x4
    80004412:	1ea50513          	addi	a0,a0,490 # 800085f8 <syscalls+0x1f0>
    80004416:	ffffc097          	auipc	ra,0xffffc
    8000441a:	12e080e7          	jalr	302(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    8000441e:	00004517          	auipc	a0,0x4
    80004422:	1f250513          	addi	a0,a0,498 # 80008610 <syscalls+0x208>
    80004426:	ffffc097          	auipc	ra,0xffffc
    8000442a:	11e080e7          	jalr	286(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    8000442e:	00878713          	addi	a4,a5,8
    80004432:	00271693          	slli	a3,a4,0x2
    80004436:	0001c717          	auipc	a4,0x1c
    8000443a:	68a70713          	addi	a4,a4,1674 # 80020ac0 <log>
    8000443e:	9736                	add	a4,a4,a3
    80004440:	44d4                	lw	a3,12(s1)
    80004442:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004444:	faf608e3          	beq	a2,a5,800043f4 <log_write+0x76>
  }
  release(&log.lock);
    80004448:	0001c517          	auipc	a0,0x1c
    8000444c:	67850513          	addi	a0,a0,1656 # 80020ac0 <log>
    80004450:	ffffd097          	auipc	ra,0xffffd
    80004454:	84e080e7          	jalr	-1970(ra) # 80000c9e <release>
}
    80004458:	60e2                	ld	ra,24(sp)
    8000445a:	6442                	ld	s0,16(sp)
    8000445c:	64a2                	ld	s1,8(sp)
    8000445e:	6902                	ld	s2,0(sp)
    80004460:	6105                	addi	sp,sp,32
    80004462:	8082                	ret

0000000080004464 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004464:	1101                	addi	sp,sp,-32
    80004466:	ec06                	sd	ra,24(sp)
    80004468:	e822                	sd	s0,16(sp)
    8000446a:	e426                	sd	s1,8(sp)
    8000446c:	e04a                	sd	s2,0(sp)
    8000446e:	1000                	addi	s0,sp,32
    80004470:	84aa                	mv	s1,a0
    80004472:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004474:	00004597          	auipc	a1,0x4
    80004478:	1bc58593          	addi	a1,a1,444 # 80008630 <syscalls+0x228>
    8000447c:	0521                	addi	a0,a0,8
    8000447e:	ffffc097          	auipc	ra,0xffffc
    80004482:	6dc080e7          	jalr	1756(ra) # 80000b5a <initlock>
  lk->name = name;
    80004486:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000448a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000448e:	0204a423          	sw	zero,40(s1)
}
    80004492:	60e2                	ld	ra,24(sp)
    80004494:	6442                	ld	s0,16(sp)
    80004496:	64a2                	ld	s1,8(sp)
    80004498:	6902                	ld	s2,0(sp)
    8000449a:	6105                	addi	sp,sp,32
    8000449c:	8082                	ret

000000008000449e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000449e:	1101                	addi	sp,sp,-32
    800044a0:	ec06                	sd	ra,24(sp)
    800044a2:	e822                	sd	s0,16(sp)
    800044a4:	e426                	sd	s1,8(sp)
    800044a6:	e04a                	sd	s2,0(sp)
    800044a8:	1000                	addi	s0,sp,32
    800044aa:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044ac:	00850913          	addi	s2,a0,8
    800044b0:	854a                	mv	a0,s2
    800044b2:	ffffc097          	auipc	ra,0xffffc
    800044b6:	738080e7          	jalr	1848(ra) # 80000bea <acquire>
  while (lk->locked) {
    800044ba:	409c                	lw	a5,0(s1)
    800044bc:	cb89                	beqz	a5,800044ce <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044be:	85ca                	mv	a1,s2
    800044c0:	8526                	mv	a0,s1
    800044c2:	ffffe097          	auipc	ra,0xffffe
    800044c6:	cbc080e7          	jalr	-836(ra) # 8000217e <sleep>
  while (lk->locked) {
    800044ca:	409c                	lw	a5,0(s1)
    800044cc:	fbed                	bnez	a5,800044be <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044ce:	4785                	li	a5,1
    800044d0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044d2:	ffffd097          	auipc	ra,0xffffd
    800044d6:	608080e7          	jalr	1544(ra) # 80001ada <myproc>
    800044da:	591c                	lw	a5,48(a0)
    800044dc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044de:	854a                	mv	a0,s2
    800044e0:	ffffc097          	auipc	ra,0xffffc
    800044e4:	7be080e7          	jalr	1982(ra) # 80000c9e <release>
}
    800044e8:	60e2                	ld	ra,24(sp)
    800044ea:	6442                	ld	s0,16(sp)
    800044ec:	64a2                	ld	s1,8(sp)
    800044ee:	6902                	ld	s2,0(sp)
    800044f0:	6105                	addi	sp,sp,32
    800044f2:	8082                	ret

00000000800044f4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044f4:	1101                	addi	sp,sp,-32
    800044f6:	ec06                	sd	ra,24(sp)
    800044f8:	e822                	sd	s0,16(sp)
    800044fa:	e426                	sd	s1,8(sp)
    800044fc:	e04a                	sd	s2,0(sp)
    800044fe:	1000                	addi	s0,sp,32
    80004500:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004502:	00850913          	addi	s2,a0,8
    80004506:	854a                	mv	a0,s2
    80004508:	ffffc097          	auipc	ra,0xffffc
    8000450c:	6e2080e7          	jalr	1762(ra) # 80000bea <acquire>
  lk->locked = 0;
    80004510:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004514:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004518:	8526                	mv	a0,s1
    8000451a:	ffffe097          	auipc	ra,0xffffe
    8000451e:	cc8080e7          	jalr	-824(ra) # 800021e2 <wakeup>
  release(&lk->lk);
    80004522:	854a                	mv	a0,s2
    80004524:	ffffc097          	auipc	ra,0xffffc
    80004528:	77a080e7          	jalr	1914(ra) # 80000c9e <release>
}
    8000452c:	60e2                	ld	ra,24(sp)
    8000452e:	6442                	ld	s0,16(sp)
    80004530:	64a2                	ld	s1,8(sp)
    80004532:	6902                	ld	s2,0(sp)
    80004534:	6105                	addi	sp,sp,32
    80004536:	8082                	ret

0000000080004538 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004538:	7179                	addi	sp,sp,-48
    8000453a:	f406                	sd	ra,40(sp)
    8000453c:	f022                	sd	s0,32(sp)
    8000453e:	ec26                	sd	s1,24(sp)
    80004540:	e84a                	sd	s2,16(sp)
    80004542:	e44e                	sd	s3,8(sp)
    80004544:	1800                	addi	s0,sp,48
    80004546:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004548:	00850913          	addi	s2,a0,8
    8000454c:	854a                	mv	a0,s2
    8000454e:	ffffc097          	auipc	ra,0xffffc
    80004552:	69c080e7          	jalr	1692(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004556:	409c                	lw	a5,0(s1)
    80004558:	ef99                	bnez	a5,80004576 <holdingsleep+0x3e>
    8000455a:	4481                	li	s1,0
  release(&lk->lk);
    8000455c:	854a                	mv	a0,s2
    8000455e:	ffffc097          	auipc	ra,0xffffc
    80004562:	740080e7          	jalr	1856(ra) # 80000c9e <release>
  return r;
}
    80004566:	8526                	mv	a0,s1
    80004568:	70a2                	ld	ra,40(sp)
    8000456a:	7402                	ld	s0,32(sp)
    8000456c:	64e2                	ld	s1,24(sp)
    8000456e:	6942                	ld	s2,16(sp)
    80004570:	69a2                	ld	s3,8(sp)
    80004572:	6145                	addi	sp,sp,48
    80004574:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004576:	0284a983          	lw	s3,40(s1)
    8000457a:	ffffd097          	auipc	ra,0xffffd
    8000457e:	560080e7          	jalr	1376(ra) # 80001ada <myproc>
    80004582:	5904                	lw	s1,48(a0)
    80004584:	413484b3          	sub	s1,s1,s3
    80004588:	0014b493          	seqz	s1,s1
    8000458c:	bfc1                	j	8000455c <holdingsleep+0x24>

000000008000458e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000458e:	1141                	addi	sp,sp,-16
    80004590:	e406                	sd	ra,8(sp)
    80004592:	e022                	sd	s0,0(sp)
    80004594:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004596:	00004597          	auipc	a1,0x4
    8000459a:	0aa58593          	addi	a1,a1,170 # 80008640 <syscalls+0x238>
    8000459e:	0001c517          	auipc	a0,0x1c
    800045a2:	66a50513          	addi	a0,a0,1642 # 80020c08 <ftable>
    800045a6:	ffffc097          	auipc	ra,0xffffc
    800045aa:	5b4080e7          	jalr	1460(ra) # 80000b5a <initlock>
}
    800045ae:	60a2                	ld	ra,8(sp)
    800045b0:	6402                	ld	s0,0(sp)
    800045b2:	0141                	addi	sp,sp,16
    800045b4:	8082                	ret

00000000800045b6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045b6:	1101                	addi	sp,sp,-32
    800045b8:	ec06                	sd	ra,24(sp)
    800045ba:	e822                	sd	s0,16(sp)
    800045bc:	e426                	sd	s1,8(sp)
    800045be:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045c0:	0001c517          	auipc	a0,0x1c
    800045c4:	64850513          	addi	a0,a0,1608 # 80020c08 <ftable>
    800045c8:	ffffc097          	auipc	ra,0xffffc
    800045cc:	622080e7          	jalr	1570(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045d0:	0001c497          	auipc	s1,0x1c
    800045d4:	65048493          	addi	s1,s1,1616 # 80020c20 <ftable+0x18>
    800045d8:	0001d717          	auipc	a4,0x1d
    800045dc:	5e870713          	addi	a4,a4,1512 # 80021bc0 <disk>
    if(f->ref == 0){
    800045e0:	40dc                	lw	a5,4(s1)
    800045e2:	cf99                	beqz	a5,80004600 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045e4:	02848493          	addi	s1,s1,40
    800045e8:	fee49ce3          	bne	s1,a4,800045e0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045ec:	0001c517          	auipc	a0,0x1c
    800045f0:	61c50513          	addi	a0,a0,1564 # 80020c08 <ftable>
    800045f4:	ffffc097          	auipc	ra,0xffffc
    800045f8:	6aa080e7          	jalr	1706(ra) # 80000c9e <release>
  return 0;
    800045fc:	4481                	li	s1,0
    800045fe:	a819                	j	80004614 <filealloc+0x5e>
      f->ref = 1;
    80004600:	4785                	li	a5,1
    80004602:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004604:	0001c517          	auipc	a0,0x1c
    80004608:	60450513          	addi	a0,a0,1540 # 80020c08 <ftable>
    8000460c:	ffffc097          	auipc	ra,0xffffc
    80004610:	692080e7          	jalr	1682(ra) # 80000c9e <release>
}
    80004614:	8526                	mv	a0,s1
    80004616:	60e2                	ld	ra,24(sp)
    80004618:	6442                	ld	s0,16(sp)
    8000461a:	64a2                	ld	s1,8(sp)
    8000461c:	6105                	addi	sp,sp,32
    8000461e:	8082                	ret

0000000080004620 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004620:	1101                	addi	sp,sp,-32
    80004622:	ec06                	sd	ra,24(sp)
    80004624:	e822                	sd	s0,16(sp)
    80004626:	e426                	sd	s1,8(sp)
    80004628:	1000                	addi	s0,sp,32
    8000462a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000462c:	0001c517          	auipc	a0,0x1c
    80004630:	5dc50513          	addi	a0,a0,1500 # 80020c08 <ftable>
    80004634:	ffffc097          	auipc	ra,0xffffc
    80004638:	5b6080e7          	jalr	1462(ra) # 80000bea <acquire>
  if(f->ref < 1)
    8000463c:	40dc                	lw	a5,4(s1)
    8000463e:	02f05263          	blez	a5,80004662 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004642:	2785                	addiw	a5,a5,1
    80004644:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004646:	0001c517          	auipc	a0,0x1c
    8000464a:	5c250513          	addi	a0,a0,1474 # 80020c08 <ftable>
    8000464e:	ffffc097          	auipc	ra,0xffffc
    80004652:	650080e7          	jalr	1616(ra) # 80000c9e <release>
  return f;
}
    80004656:	8526                	mv	a0,s1
    80004658:	60e2                	ld	ra,24(sp)
    8000465a:	6442                	ld	s0,16(sp)
    8000465c:	64a2                	ld	s1,8(sp)
    8000465e:	6105                	addi	sp,sp,32
    80004660:	8082                	ret
    panic("filedup");
    80004662:	00004517          	auipc	a0,0x4
    80004666:	fe650513          	addi	a0,a0,-26 # 80008648 <syscalls+0x240>
    8000466a:	ffffc097          	auipc	ra,0xffffc
    8000466e:	eda080e7          	jalr	-294(ra) # 80000544 <panic>

0000000080004672 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004672:	7139                	addi	sp,sp,-64
    80004674:	fc06                	sd	ra,56(sp)
    80004676:	f822                	sd	s0,48(sp)
    80004678:	f426                	sd	s1,40(sp)
    8000467a:	f04a                	sd	s2,32(sp)
    8000467c:	ec4e                	sd	s3,24(sp)
    8000467e:	e852                	sd	s4,16(sp)
    80004680:	e456                	sd	s5,8(sp)
    80004682:	0080                	addi	s0,sp,64
    80004684:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004686:	0001c517          	auipc	a0,0x1c
    8000468a:	58250513          	addi	a0,a0,1410 # 80020c08 <ftable>
    8000468e:	ffffc097          	auipc	ra,0xffffc
    80004692:	55c080e7          	jalr	1372(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004696:	40dc                	lw	a5,4(s1)
    80004698:	06f05163          	blez	a5,800046fa <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000469c:	37fd                	addiw	a5,a5,-1
    8000469e:	0007871b          	sext.w	a4,a5
    800046a2:	c0dc                	sw	a5,4(s1)
    800046a4:	06e04363          	bgtz	a4,8000470a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046a8:	0004a903          	lw	s2,0(s1)
    800046ac:	0094ca83          	lbu	s5,9(s1)
    800046b0:	0104ba03          	ld	s4,16(s1)
    800046b4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046b8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046bc:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046c0:	0001c517          	auipc	a0,0x1c
    800046c4:	54850513          	addi	a0,a0,1352 # 80020c08 <ftable>
    800046c8:	ffffc097          	auipc	ra,0xffffc
    800046cc:	5d6080e7          	jalr	1494(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    800046d0:	4785                	li	a5,1
    800046d2:	04f90d63          	beq	s2,a5,8000472c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046d6:	3979                	addiw	s2,s2,-2
    800046d8:	4785                	li	a5,1
    800046da:	0527e063          	bltu	a5,s2,8000471a <fileclose+0xa8>
    begin_op();
    800046de:	00000097          	auipc	ra,0x0
    800046e2:	ac8080e7          	jalr	-1336(ra) # 800041a6 <begin_op>
    iput(ff.ip);
    800046e6:	854e                	mv	a0,s3
    800046e8:	fffff097          	auipc	ra,0xfffff
    800046ec:	2b6080e7          	jalr	694(ra) # 8000399e <iput>
    end_op();
    800046f0:	00000097          	auipc	ra,0x0
    800046f4:	b36080e7          	jalr	-1226(ra) # 80004226 <end_op>
    800046f8:	a00d                	j	8000471a <fileclose+0xa8>
    panic("fileclose");
    800046fa:	00004517          	auipc	a0,0x4
    800046fe:	f5650513          	addi	a0,a0,-170 # 80008650 <syscalls+0x248>
    80004702:	ffffc097          	auipc	ra,0xffffc
    80004706:	e42080e7          	jalr	-446(ra) # 80000544 <panic>
    release(&ftable.lock);
    8000470a:	0001c517          	auipc	a0,0x1c
    8000470e:	4fe50513          	addi	a0,a0,1278 # 80020c08 <ftable>
    80004712:	ffffc097          	auipc	ra,0xffffc
    80004716:	58c080e7          	jalr	1420(ra) # 80000c9e <release>
  }
}
    8000471a:	70e2                	ld	ra,56(sp)
    8000471c:	7442                	ld	s0,48(sp)
    8000471e:	74a2                	ld	s1,40(sp)
    80004720:	7902                	ld	s2,32(sp)
    80004722:	69e2                	ld	s3,24(sp)
    80004724:	6a42                	ld	s4,16(sp)
    80004726:	6aa2                	ld	s5,8(sp)
    80004728:	6121                	addi	sp,sp,64
    8000472a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000472c:	85d6                	mv	a1,s5
    8000472e:	8552                	mv	a0,s4
    80004730:	00000097          	auipc	ra,0x0
    80004734:	34c080e7          	jalr	844(ra) # 80004a7c <pipeclose>
    80004738:	b7cd                	j	8000471a <fileclose+0xa8>

000000008000473a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000473a:	715d                	addi	sp,sp,-80
    8000473c:	e486                	sd	ra,72(sp)
    8000473e:	e0a2                	sd	s0,64(sp)
    80004740:	fc26                	sd	s1,56(sp)
    80004742:	f84a                	sd	s2,48(sp)
    80004744:	f44e                	sd	s3,40(sp)
    80004746:	0880                	addi	s0,sp,80
    80004748:	84aa                	mv	s1,a0
    8000474a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000474c:	ffffd097          	auipc	ra,0xffffd
    80004750:	38e080e7          	jalr	910(ra) # 80001ada <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004754:	409c                	lw	a5,0(s1)
    80004756:	37f9                	addiw	a5,a5,-2
    80004758:	4705                	li	a4,1
    8000475a:	04f76763          	bltu	a4,a5,800047a8 <filestat+0x6e>
    8000475e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004760:	6c88                	ld	a0,24(s1)
    80004762:	fffff097          	auipc	ra,0xfffff
    80004766:	082080e7          	jalr	130(ra) # 800037e4 <ilock>
    stati(f->ip, &st);
    8000476a:	fb840593          	addi	a1,s0,-72
    8000476e:	6c88                	ld	a0,24(s1)
    80004770:	fffff097          	auipc	ra,0xfffff
    80004774:	2fe080e7          	jalr	766(ra) # 80003a6e <stati>
    iunlock(f->ip);
    80004778:	6c88                	ld	a0,24(s1)
    8000477a:	fffff097          	auipc	ra,0xfffff
    8000477e:	12c080e7          	jalr	300(ra) # 800038a6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004782:	46e1                	li	a3,24
    80004784:	fb840613          	addi	a2,s0,-72
    80004788:	85ce                	mv	a1,s3
    8000478a:	05093503          	ld	a0,80(s2)
    8000478e:	ffffd097          	auipc	ra,0xffffd
    80004792:	f1e080e7          	jalr	-226(ra) # 800016ac <copyout>
    80004796:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000479a:	60a6                	ld	ra,72(sp)
    8000479c:	6406                	ld	s0,64(sp)
    8000479e:	74e2                	ld	s1,56(sp)
    800047a0:	7942                	ld	s2,48(sp)
    800047a2:	79a2                	ld	s3,40(sp)
    800047a4:	6161                	addi	sp,sp,80
    800047a6:	8082                	ret
  return -1;
    800047a8:	557d                	li	a0,-1
    800047aa:	bfc5                	j	8000479a <filestat+0x60>

00000000800047ac <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047ac:	7179                	addi	sp,sp,-48
    800047ae:	f406                	sd	ra,40(sp)
    800047b0:	f022                	sd	s0,32(sp)
    800047b2:	ec26                	sd	s1,24(sp)
    800047b4:	e84a                	sd	s2,16(sp)
    800047b6:	e44e                	sd	s3,8(sp)
    800047b8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047ba:	00854783          	lbu	a5,8(a0)
    800047be:	c3d5                	beqz	a5,80004862 <fileread+0xb6>
    800047c0:	84aa                	mv	s1,a0
    800047c2:	89ae                	mv	s3,a1
    800047c4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047c6:	411c                	lw	a5,0(a0)
    800047c8:	4705                	li	a4,1
    800047ca:	04e78963          	beq	a5,a4,8000481c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047ce:	470d                	li	a4,3
    800047d0:	04e78d63          	beq	a5,a4,8000482a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047d4:	4709                	li	a4,2
    800047d6:	06e79e63          	bne	a5,a4,80004852 <fileread+0xa6>
    ilock(f->ip);
    800047da:	6d08                	ld	a0,24(a0)
    800047dc:	fffff097          	auipc	ra,0xfffff
    800047e0:	008080e7          	jalr	8(ra) # 800037e4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047e4:	874a                	mv	a4,s2
    800047e6:	5094                	lw	a3,32(s1)
    800047e8:	864e                	mv	a2,s3
    800047ea:	4585                	li	a1,1
    800047ec:	6c88                	ld	a0,24(s1)
    800047ee:	fffff097          	auipc	ra,0xfffff
    800047f2:	2aa080e7          	jalr	682(ra) # 80003a98 <readi>
    800047f6:	892a                	mv	s2,a0
    800047f8:	00a05563          	blez	a0,80004802 <fileread+0x56>
      f->off += r;
    800047fc:	509c                	lw	a5,32(s1)
    800047fe:	9fa9                	addw	a5,a5,a0
    80004800:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004802:	6c88                	ld	a0,24(s1)
    80004804:	fffff097          	auipc	ra,0xfffff
    80004808:	0a2080e7          	jalr	162(ra) # 800038a6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000480c:	854a                	mv	a0,s2
    8000480e:	70a2                	ld	ra,40(sp)
    80004810:	7402                	ld	s0,32(sp)
    80004812:	64e2                	ld	s1,24(sp)
    80004814:	6942                	ld	s2,16(sp)
    80004816:	69a2                	ld	s3,8(sp)
    80004818:	6145                	addi	sp,sp,48
    8000481a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000481c:	6908                	ld	a0,16(a0)
    8000481e:	00000097          	auipc	ra,0x0
    80004822:	3ce080e7          	jalr	974(ra) # 80004bec <piperead>
    80004826:	892a                	mv	s2,a0
    80004828:	b7d5                	j	8000480c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000482a:	02451783          	lh	a5,36(a0)
    8000482e:	03079693          	slli	a3,a5,0x30
    80004832:	92c1                	srli	a3,a3,0x30
    80004834:	4725                	li	a4,9
    80004836:	02d76863          	bltu	a4,a3,80004866 <fileread+0xba>
    8000483a:	0792                	slli	a5,a5,0x4
    8000483c:	0001c717          	auipc	a4,0x1c
    80004840:	32c70713          	addi	a4,a4,812 # 80020b68 <devsw>
    80004844:	97ba                	add	a5,a5,a4
    80004846:	639c                	ld	a5,0(a5)
    80004848:	c38d                	beqz	a5,8000486a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000484a:	4505                	li	a0,1
    8000484c:	9782                	jalr	a5
    8000484e:	892a                	mv	s2,a0
    80004850:	bf75                	j	8000480c <fileread+0x60>
    panic("fileread");
    80004852:	00004517          	auipc	a0,0x4
    80004856:	e0e50513          	addi	a0,a0,-498 # 80008660 <syscalls+0x258>
    8000485a:	ffffc097          	auipc	ra,0xffffc
    8000485e:	cea080e7          	jalr	-790(ra) # 80000544 <panic>
    return -1;
    80004862:	597d                	li	s2,-1
    80004864:	b765                	j	8000480c <fileread+0x60>
      return -1;
    80004866:	597d                	li	s2,-1
    80004868:	b755                	j	8000480c <fileread+0x60>
    8000486a:	597d                	li	s2,-1
    8000486c:	b745                	j	8000480c <fileread+0x60>

000000008000486e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000486e:	715d                	addi	sp,sp,-80
    80004870:	e486                	sd	ra,72(sp)
    80004872:	e0a2                	sd	s0,64(sp)
    80004874:	fc26                	sd	s1,56(sp)
    80004876:	f84a                	sd	s2,48(sp)
    80004878:	f44e                	sd	s3,40(sp)
    8000487a:	f052                	sd	s4,32(sp)
    8000487c:	ec56                	sd	s5,24(sp)
    8000487e:	e85a                	sd	s6,16(sp)
    80004880:	e45e                	sd	s7,8(sp)
    80004882:	e062                	sd	s8,0(sp)
    80004884:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004886:	00954783          	lbu	a5,9(a0)
    8000488a:	10078663          	beqz	a5,80004996 <filewrite+0x128>
    8000488e:	892a                	mv	s2,a0
    80004890:	8aae                	mv	s5,a1
    80004892:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004894:	411c                	lw	a5,0(a0)
    80004896:	4705                	li	a4,1
    80004898:	02e78263          	beq	a5,a4,800048bc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000489c:	470d                	li	a4,3
    8000489e:	02e78663          	beq	a5,a4,800048ca <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048a2:	4709                	li	a4,2
    800048a4:	0ee79163          	bne	a5,a4,80004986 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048a8:	0ac05d63          	blez	a2,80004962 <filewrite+0xf4>
    int i = 0;
    800048ac:	4981                	li	s3,0
    800048ae:	6b05                	lui	s6,0x1
    800048b0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800048b4:	6b85                	lui	s7,0x1
    800048b6:	c00b8b9b          	addiw	s7,s7,-1024
    800048ba:	a861                	j	80004952 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800048bc:	6908                	ld	a0,16(a0)
    800048be:	00000097          	auipc	ra,0x0
    800048c2:	22e080e7          	jalr	558(ra) # 80004aec <pipewrite>
    800048c6:	8a2a                	mv	s4,a0
    800048c8:	a045                	j	80004968 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048ca:	02451783          	lh	a5,36(a0)
    800048ce:	03079693          	slli	a3,a5,0x30
    800048d2:	92c1                	srli	a3,a3,0x30
    800048d4:	4725                	li	a4,9
    800048d6:	0cd76263          	bltu	a4,a3,8000499a <filewrite+0x12c>
    800048da:	0792                	slli	a5,a5,0x4
    800048dc:	0001c717          	auipc	a4,0x1c
    800048e0:	28c70713          	addi	a4,a4,652 # 80020b68 <devsw>
    800048e4:	97ba                	add	a5,a5,a4
    800048e6:	679c                	ld	a5,8(a5)
    800048e8:	cbdd                	beqz	a5,8000499e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048ea:	4505                	li	a0,1
    800048ec:	9782                	jalr	a5
    800048ee:	8a2a                	mv	s4,a0
    800048f0:	a8a5                	j	80004968 <filewrite+0xfa>
    800048f2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048f6:	00000097          	auipc	ra,0x0
    800048fa:	8b0080e7          	jalr	-1872(ra) # 800041a6 <begin_op>
      ilock(f->ip);
    800048fe:	01893503          	ld	a0,24(s2)
    80004902:	fffff097          	auipc	ra,0xfffff
    80004906:	ee2080e7          	jalr	-286(ra) # 800037e4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000490a:	8762                	mv	a4,s8
    8000490c:	02092683          	lw	a3,32(s2)
    80004910:	01598633          	add	a2,s3,s5
    80004914:	4585                	li	a1,1
    80004916:	01893503          	ld	a0,24(s2)
    8000491a:	fffff097          	auipc	ra,0xfffff
    8000491e:	276080e7          	jalr	630(ra) # 80003b90 <writei>
    80004922:	84aa                	mv	s1,a0
    80004924:	00a05763          	blez	a0,80004932 <filewrite+0xc4>
        f->off += r;
    80004928:	02092783          	lw	a5,32(s2)
    8000492c:	9fa9                	addw	a5,a5,a0
    8000492e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004932:	01893503          	ld	a0,24(s2)
    80004936:	fffff097          	auipc	ra,0xfffff
    8000493a:	f70080e7          	jalr	-144(ra) # 800038a6 <iunlock>
      end_op();
    8000493e:	00000097          	auipc	ra,0x0
    80004942:	8e8080e7          	jalr	-1816(ra) # 80004226 <end_op>

      if(r != n1){
    80004946:	009c1f63          	bne	s8,s1,80004964 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000494a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000494e:	0149db63          	bge	s3,s4,80004964 <filewrite+0xf6>
      int n1 = n - i;
    80004952:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004956:	84be                	mv	s1,a5
    80004958:	2781                	sext.w	a5,a5
    8000495a:	f8fb5ce3          	bge	s6,a5,800048f2 <filewrite+0x84>
    8000495e:	84de                	mv	s1,s7
    80004960:	bf49                	j	800048f2 <filewrite+0x84>
    int i = 0;
    80004962:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004964:	013a1f63          	bne	s4,s3,80004982 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004968:	8552                	mv	a0,s4
    8000496a:	60a6                	ld	ra,72(sp)
    8000496c:	6406                	ld	s0,64(sp)
    8000496e:	74e2                	ld	s1,56(sp)
    80004970:	7942                	ld	s2,48(sp)
    80004972:	79a2                	ld	s3,40(sp)
    80004974:	7a02                	ld	s4,32(sp)
    80004976:	6ae2                	ld	s5,24(sp)
    80004978:	6b42                	ld	s6,16(sp)
    8000497a:	6ba2                	ld	s7,8(sp)
    8000497c:	6c02                	ld	s8,0(sp)
    8000497e:	6161                	addi	sp,sp,80
    80004980:	8082                	ret
    ret = (i == n ? n : -1);
    80004982:	5a7d                	li	s4,-1
    80004984:	b7d5                	j	80004968 <filewrite+0xfa>
    panic("filewrite");
    80004986:	00004517          	auipc	a0,0x4
    8000498a:	cea50513          	addi	a0,a0,-790 # 80008670 <syscalls+0x268>
    8000498e:	ffffc097          	auipc	ra,0xffffc
    80004992:	bb6080e7          	jalr	-1098(ra) # 80000544 <panic>
    return -1;
    80004996:	5a7d                	li	s4,-1
    80004998:	bfc1                	j	80004968 <filewrite+0xfa>
      return -1;
    8000499a:	5a7d                	li	s4,-1
    8000499c:	b7f1                	j	80004968 <filewrite+0xfa>
    8000499e:	5a7d                	li	s4,-1
    800049a0:	b7e1                	j	80004968 <filewrite+0xfa>

00000000800049a2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049a2:	7179                	addi	sp,sp,-48
    800049a4:	f406                	sd	ra,40(sp)
    800049a6:	f022                	sd	s0,32(sp)
    800049a8:	ec26                	sd	s1,24(sp)
    800049aa:	e84a                	sd	s2,16(sp)
    800049ac:	e44e                	sd	s3,8(sp)
    800049ae:	e052                	sd	s4,0(sp)
    800049b0:	1800                	addi	s0,sp,48
    800049b2:	84aa                	mv	s1,a0
    800049b4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049b6:	0005b023          	sd	zero,0(a1)
    800049ba:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049be:	00000097          	auipc	ra,0x0
    800049c2:	bf8080e7          	jalr	-1032(ra) # 800045b6 <filealloc>
    800049c6:	e088                	sd	a0,0(s1)
    800049c8:	c551                	beqz	a0,80004a54 <pipealloc+0xb2>
    800049ca:	00000097          	auipc	ra,0x0
    800049ce:	bec080e7          	jalr	-1044(ra) # 800045b6 <filealloc>
    800049d2:	00aa3023          	sd	a0,0(s4)
    800049d6:	c92d                	beqz	a0,80004a48 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049d8:	ffffc097          	auipc	ra,0xffffc
    800049dc:	122080e7          	jalr	290(ra) # 80000afa <kalloc>
    800049e0:	892a                	mv	s2,a0
    800049e2:	c125                	beqz	a0,80004a42 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049e4:	4985                	li	s3,1
    800049e6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049ea:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049ee:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049f2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049f6:	00004597          	auipc	a1,0x4
    800049fa:	c8a58593          	addi	a1,a1,-886 # 80008680 <syscalls+0x278>
    800049fe:	ffffc097          	auipc	ra,0xffffc
    80004a02:	15c080e7          	jalr	348(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    80004a06:	609c                	ld	a5,0(s1)
    80004a08:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a0c:	609c                	ld	a5,0(s1)
    80004a0e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a12:	609c                	ld	a5,0(s1)
    80004a14:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a18:	609c                	ld	a5,0(s1)
    80004a1a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a1e:	000a3783          	ld	a5,0(s4)
    80004a22:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a26:	000a3783          	ld	a5,0(s4)
    80004a2a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a2e:	000a3783          	ld	a5,0(s4)
    80004a32:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a36:	000a3783          	ld	a5,0(s4)
    80004a3a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a3e:	4501                	li	a0,0
    80004a40:	a025                	j	80004a68 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a42:	6088                	ld	a0,0(s1)
    80004a44:	e501                	bnez	a0,80004a4c <pipealloc+0xaa>
    80004a46:	a039                	j	80004a54 <pipealloc+0xb2>
    80004a48:	6088                	ld	a0,0(s1)
    80004a4a:	c51d                	beqz	a0,80004a78 <pipealloc+0xd6>
    fileclose(*f0);
    80004a4c:	00000097          	auipc	ra,0x0
    80004a50:	c26080e7          	jalr	-986(ra) # 80004672 <fileclose>
  if(*f1)
    80004a54:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a58:	557d                	li	a0,-1
  if(*f1)
    80004a5a:	c799                	beqz	a5,80004a68 <pipealloc+0xc6>
    fileclose(*f1);
    80004a5c:	853e                	mv	a0,a5
    80004a5e:	00000097          	auipc	ra,0x0
    80004a62:	c14080e7          	jalr	-1004(ra) # 80004672 <fileclose>
  return -1;
    80004a66:	557d                	li	a0,-1
}
    80004a68:	70a2                	ld	ra,40(sp)
    80004a6a:	7402                	ld	s0,32(sp)
    80004a6c:	64e2                	ld	s1,24(sp)
    80004a6e:	6942                	ld	s2,16(sp)
    80004a70:	69a2                	ld	s3,8(sp)
    80004a72:	6a02                	ld	s4,0(sp)
    80004a74:	6145                	addi	sp,sp,48
    80004a76:	8082                	ret
  return -1;
    80004a78:	557d                	li	a0,-1
    80004a7a:	b7fd                	j	80004a68 <pipealloc+0xc6>

0000000080004a7c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a7c:	1101                	addi	sp,sp,-32
    80004a7e:	ec06                	sd	ra,24(sp)
    80004a80:	e822                	sd	s0,16(sp)
    80004a82:	e426                	sd	s1,8(sp)
    80004a84:	e04a                	sd	s2,0(sp)
    80004a86:	1000                	addi	s0,sp,32
    80004a88:	84aa                	mv	s1,a0
    80004a8a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a8c:	ffffc097          	auipc	ra,0xffffc
    80004a90:	15e080e7          	jalr	350(ra) # 80000bea <acquire>
  if(writable){
    80004a94:	02090d63          	beqz	s2,80004ace <pipeclose+0x52>
    pi->writeopen = 0;
    80004a98:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a9c:	21848513          	addi	a0,s1,536
    80004aa0:	ffffd097          	auipc	ra,0xffffd
    80004aa4:	742080e7          	jalr	1858(ra) # 800021e2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004aa8:	2204b783          	ld	a5,544(s1)
    80004aac:	eb95                	bnez	a5,80004ae0 <pipeclose+0x64>
    release(&pi->lock);
    80004aae:	8526                	mv	a0,s1
    80004ab0:	ffffc097          	auipc	ra,0xffffc
    80004ab4:	1ee080e7          	jalr	494(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004ab8:	8526                	mv	a0,s1
    80004aba:	ffffc097          	auipc	ra,0xffffc
    80004abe:	f44080e7          	jalr	-188(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004ac2:	60e2                	ld	ra,24(sp)
    80004ac4:	6442                	ld	s0,16(sp)
    80004ac6:	64a2                	ld	s1,8(sp)
    80004ac8:	6902                	ld	s2,0(sp)
    80004aca:	6105                	addi	sp,sp,32
    80004acc:	8082                	ret
    pi->readopen = 0;
    80004ace:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ad2:	21c48513          	addi	a0,s1,540
    80004ad6:	ffffd097          	auipc	ra,0xffffd
    80004ada:	70c080e7          	jalr	1804(ra) # 800021e2 <wakeup>
    80004ade:	b7e9                	j	80004aa8 <pipeclose+0x2c>
    release(&pi->lock);
    80004ae0:	8526                	mv	a0,s1
    80004ae2:	ffffc097          	auipc	ra,0xffffc
    80004ae6:	1bc080e7          	jalr	444(ra) # 80000c9e <release>
}
    80004aea:	bfe1                	j	80004ac2 <pipeclose+0x46>

0000000080004aec <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004aec:	7159                	addi	sp,sp,-112
    80004aee:	f486                	sd	ra,104(sp)
    80004af0:	f0a2                	sd	s0,96(sp)
    80004af2:	eca6                	sd	s1,88(sp)
    80004af4:	e8ca                	sd	s2,80(sp)
    80004af6:	e4ce                	sd	s3,72(sp)
    80004af8:	e0d2                	sd	s4,64(sp)
    80004afa:	fc56                	sd	s5,56(sp)
    80004afc:	f85a                	sd	s6,48(sp)
    80004afe:	f45e                	sd	s7,40(sp)
    80004b00:	f062                	sd	s8,32(sp)
    80004b02:	ec66                	sd	s9,24(sp)
    80004b04:	1880                	addi	s0,sp,112
    80004b06:	84aa                	mv	s1,a0
    80004b08:	8aae                	mv	s5,a1
    80004b0a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b0c:	ffffd097          	auipc	ra,0xffffd
    80004b10:	fce080e7          	jalr	-50(ra) # 80001ada <myproc>
    80004b14:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b16:	8526                	mv	a0,s1
    80004b18:	ffffc097          	auipc	ra,0xffffc
    80004b1c:	0d2080e7          	jalr	210(ra) # 80000bea <acquire>
  while(i < n){
    80004b20:	0d405463          	blez	s4,80004be8 <pipewrite+0xfc>
    80004b24:	8ba6                	mv	s7,s1
  int i = 0;
    80004b26:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b28:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b2a:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b2e:	21c48c13          	addi	s8,s1,540
    80004b32:	a08d                	j	80004b94 <pipewrite+0xa8>
      release(&pi->lock);
    80004b34:	8526                	mv	a0,s1
    80004b36:	ffffc097          	auipc	ra,0xffffc
    80004b3a:	168080e7          	jalr	360(ra) # 80000c9e <release>
      return -1;
    80004b3e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b40:	854a                	mv	a0,s2
    80004b42:	70a6                	ld	ra,104(sp)
    80004b44:	7406                	ld	s0,96(sp)
    80004b46:	64e6                	ld	s1,88(sp)
    80004b48:	6946                	ld	s2,80(sp)
    80004b4a:	69a6                	ld	s3,72(sp)
    80004b4c:	6a06                	ld	s4,64(sp)
    80004b4e:	7ae2                	ld	s5,56(sp)
    80004b50:	7b42                	ld	s6,48(sp)
    80004b52:	7ba2                	ld	s7,40(sp)
    80004b54:	7c02                	ld	s8,32(sp)
    80004b56:	6ce2                	ld	s9,24(sp)
    80004b58:	6165                	addi	sp,sp,112
    80004b5a:	8082                	ret
      wakeup(&pi->nread);
    80004b5c:	8566                	mv	a0,s9
    80004b5e:	ffffd097          	auipc	ra,0xffffd
    80004b62:	684080e7          	jalr	1668(ra) # 800021e2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b66:	85de                	mv	a1,s7
    80004b68:	8562                	mv	a0,s8
    80004b6a:	ffffd097          	auipc	ra,0xffffd
    80004b6e:	614080e7          	jalr	1556(ra) # 8000217e <sleep>
    80004b72:	a839                	j	80004b90 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b74:	21c4a783          	lw	a5,540(s1)
    80004b78:	0017871b          	addiw	a4,a5,1
    80004b7c:	20e4ae23          	sw	a4,540(s1)
    80004b80:	1ff7f793          	andi	a5,a5,511
    80004b84:	97a6                	add	a5,a5,s1
    80004b86:	f9f44703          	lbu	a4,-97(s0)
    80004b8a:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b8e:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b90:	05495063          	bge	s2,s4,80004bd0 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004b94:	2204a783          	lw	a5,544(s1)
    80004b98:	dfd1                	beqz	a5,80004b34 <pipewrite+0x48>
    80004b9a:	854e                	mv	a0,s3
    80004b9c:	ffffe097          	auipc	ra,0xffffe
    80004ba0:	88a080e7          	jalr	-1910(ra) # 80002426 <killed>
    80004ba4:	f941                	bnez	a0,80004b34 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ba6:	2184a783          	lw	a5,536(s1)
    80004baa:	21c4a703          	lw	a4,540(s1)
    80004bae:	2007879b          	addiw	a5,a5,512
    80004bb2:	faf705e3          	beq	a4,a5,80004b5c <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bb6:	4685                	li	a3,1
    80004bb8:	01590633          	add	a2,s2,s5
    80004bbc:	f9f40593          	addi	a1,s0,-97
    80004bc0:	0509b503          	ld	a0,80(s3)
    80004bc4:	ffffd097          	auipc	ra,0xffffd
    80004bc8:	b74080e7          	jalr	-1164(ra) # 80001738 <copyin>
    80004bcc:	fb6514e3          	bne	a0,s6,80004b74 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004bd0:	21848513          	addi	a0,s1,536
    80004bd4:	ffffd097          	auipc	ra,0xffffd
    80004bd8:	60e080e7          	jalr	1550(ra) # 800021e2 <wakeup>
  release(&pi->lock);
    80004bdc:	8526                	mv	a0,s1
    80004bde:	ffffc097          	auipc	ra,0xffffc
    80004be2:	0c0080e7          	jalr	192(ra) # 80000c9e <release>
  return i;
    80004be6:	bfa9                	j	80004b40 <pipewrite+0x54>
  int i = 0;
    80004be8:	4901                	li	s2,0
    80004bea:	b7dd                	j	80004bd0 <pipewrite+0xe4>

0000000080004bec <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bec:	715d                	addi	sp,sp,-80
    80004bee:	e486                	sd	ra,72(sp)
    80004bf0:	e0a2                	sd	s0,64(sp)
    80004bf2:	fc26                	sd	s1,56(sp)
    80004bf4:	f84a                	sd	s2,48(sp)
    80004bf6:	f44e                	sd	s3,40(sp)
    80004bf8:	f052                	sd	s4,32(sp)
    80004bfa:	ec56                	sd	s5,24(sp)
    80004bfc:	e85a                	sd	s6,16(sp)
    80004bfe:	0880                	addi	s0,sp,80
    80004c00:	84aa                	mv	s1,a0
    80004c02:	892e                	mv	s2,a1
    80004c04:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c06:	ffffd097          	auipc	ra,0xffffd
    80004c0a:	ed4080e7          	jalr	-300(ra) # 80001ada <myproc>
    80004c0e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c10:	8b26                	mv	s6,s1
    80004c12:	8526                	mv	a0,s1
    80004c14:	ffffc097          	auipc	ra,0xffffc
    80004c18:	fd6080e7          	jalr	-42(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c1c:	2184a703          	lw	a4,536(s1)
    80004c20:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c24:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c28:	02f71763          	bne	a4,a5,80004c56 <piperead+0x6a>
    80004c2c:	2244a783          	lw	a5,548(s1)
    80004c30:	c39d                	beqz	a5,80004c56 <piperead+0x6a>
    if(killed(pr)){
    80004c32:	8552                	mv	a0,s4
    80004c34:	ffffd097          	auipc	ra,0xffffd
    80004c38:	7f2080e7          	jalr	2034(ra) # 80002426 <killed>
    80004c3c:	e941                	bnez	a0,80004ccc <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c3e:	85da                	mv	a1,s6
    80004c40:	854e                	mv	a0,s3
    80004c42:	ffffd097          	auipc	ra,0xffffd
    80004c46:	53c080e7          	jalr	1340(ra) # 8000217e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c4a:	2184a703          	lw	a4,536(s1)
    80004c4e:	21c4a783          	lw	a5,540(s1)
    80004c52:	fcf70de3          	beq	a4,a5,80004c2c <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c56:	09505263          	blez	s5,80004cda <piperead+0xee>
    80004c5a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c5c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c5e:	2184a783          	lw	a5,536(s1)
    80004c62:	21c4a703          	lw	a4,540(s1)
    80004c66:	02f70d63          	beq	a4,a5,80004ca0 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c6a:	0017871b          	addiw	a4,a5,1
    80004c6e:	20e4ac23          	sw	a4,536(s1)
    80004c72:	1ff7f793          	andi	a5,a5,511
    80004c76:	97a6                	add	a5,a5,s1
    80004c78:	0187c783          	lbu	a5,24(a5)
    80004c7c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c80:	4685                	li	a3,1
    80004c82:	fbf40613          	addi	a2,s0,-65
    80004c86:	85ca                	mv	a1,s2
    80004c88:	050a3503          	ld	a0,80(s4)
    80004c8c:	ffffd097          	auipc	ra,0xffffd
    80004c90:	a20080e7          	jalr	-1504(ra) # 800016ac <copyout>
    80004c94:	01650663          	beq	a0,s6,80004ca0 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c98:	2985                	addiw	s3,s3,1
    80004c9a:	0905                	addi	s2,s2,1
    80004c9c:	fd3a91e3          	bne	s5,s3,80004c5e <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ca0:	21c48513          	addi	a0,s1,540
    80004ca4:	ffffd097          	auipc	ra,0xffffd
    80004ca8:	53e080e7          	jalr	1342(ra) # 800021e2 <wakeup>
  release(&pi->lock);
    80004cac:	8526                	mv	a0,s1
    80004cae:	ffffc097          	auipc	ra,0xffffc
    80004cb2:	ff0080e7          	jalr	-16(ra) # 80000c9e <release>
  return i;
}
    80004cb6:	854e                	mv	a0,s3
    80004cb8:	60a6                	ld	ra,72(sp)
    80004cba:	6406                	ld	s0,64(sp)
    80004cbc:	74e2                	ld	s1,56(sp)
    80004cbe:	7942                	ld	s2,48(sp)
    80004cc0:	79a2                	ld	s3,40(sp)
    80004cc2:	7a02                	ld	s4,32(sp)
    80004cc4:	6ae2                	ld	s5,24(sp)
    80004cc6:	6b42                	ld	s6,16(sp)
    80004cc8:	6161                	addi	sp,sp,80
    80004cca:	8082                	ret
      release(&pi->lock);
    80004ccc:	8526                	mv	a0,s1
    80004cce:	ffffc097          	auipc	ra,0xffffc
    80004cd2:	fd0080e7          	jalr	-48(ra) # 80000c9e <release>
      return -1;
    80004cd6:	59fd                	li	s3,-1
    80004cd8:	bff9                	j	80004cb6 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cda:	4981                	li	s3,0
    80004cdc:	b7d1                	j	80004ca0 <piperead+0xb4>

0000000080004cde <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004cde:	1141                	addi	sp,sp,-16
    80004ce0:	e422                	sd	s0,8(sp)
    80004ce2:	0800                	addi	s0,sp,16
    80004ce4:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004ce6:	8905                	andi	a0,a0,1
    80004ce8:	c111                	beqz	a0,80004cec <flags2perm+0xe>
      perm = PTE_X;
    80004cea:	4521                	li	a0,8
    if(flags & 0x2)
    80004cec:	8b89                	andi	a5,a5,2
    80004cee:	c399                	beqz	a5,80004cf4 <flags2perm+0x16>
      perm |= PTE_W;
    80004cf0:	00456513          	ori	a0,a0,4
    return perm;
}
    80004cf4:	6422                	ld	s0,8(sp)
    80004cf6:	0141                	addi	sp,sp,16
    80004cf8:	8082                	ret

0000000080004cfa <exec>:

int
exec(char *path, char **argv)
{
    80004cfa:	df010113          	addi	sp,sp,-528
    80004cfe:	20113423          	sd	ra,520(sp)
    80004d02:	20813023          	sd	s0,512(sp)
    80004d06:	ffa6                	sd	s1,504(sp)
    80004d08:	fbca                	sd	s2,496(sp)
    80004d0a:	f7ce                	sd	s3,488(sp)
    80004d0c:	f3d2                	sd	s4,480(sp)
    80004d0e:	efd6                	sd	s5,472(sp)
    80004d10:	ebda                	sd	s6,464(sp)
    80004d12:	e7de                	sd	s7,456(sp)
    80004d14:	e3e2                	sd	s8,448(sp)
    80004d16:	ff66                	sd	s9,440(sp)
    80004d18:	fb6a                	sd	s10,432(sp)
    80004d1a:	f76e                	sd	s11,424(sp)
    80004d1c:	0c00                	addi	s0,sp,528
    80004d1e:	84aa                	mv	s1,a0
    80004d20:	dea43c23          	sd	a0,-520(s0)
    80004d24:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d28:	ffffd097          	auipc	ra,0xffffd
    80004d2c:	db2080e7          	jalr	-590(ra) # 80001ada <myproc>
    80004d30:	892a                	mv	s2,a0

  begin_op();
    80004d32:	fffff097          	auipc	ra,0xfffff
    80004d36:	474080e7          	jalr	1140(ra) # 800041a6 <begin_op>

  if((ip = namei(path)) == 0){
    80004d3a:	8526                	mv	a0,s1
    80004d3c:	fffff097          	auipc	ra,0xfffff
    80004d40:	24e080e7          	jalr	590(ra) # 80003f8a <namei>
    80004d44:	c92d                	beqz	a0,80004db6 <exec+0xbc>
    80004d46:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d48:	fffff097          	auipc	ra,0xfffff
    80004d4c:	a9c080e7          	jalr	-1380(ra) # 800037e4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d50:	04000713          	li	a4,64
    80004d54:	4681                	li	a3,0
    80004d56:	e5040613          	addi	a2,s0,-432
    80004d5a:	4581                	li	a1,0
    80004d5c:	8526                	mv	a0,s1
    80004d5e:	fffff097          	auipc	ra,0xfffff
    80004d62:	d3a080e7          	jalr	-710(ra) # 80003a98 <readi>
    80004d66:	04000793          	li	a5,64
    80004d6a:	00f51a63          	bne	a0,a5,80004d7e <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d6e:	e5042703          	lw	a4,-432(s0)
    80004d72:	464c47b7          	lui	a5,0x464c4
    80004d76:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d7a:	04f70463          	beq	a4,a5,80004dc2 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d7e:	8526                	mv	a0,s1
    80004d80:	fffff097          	auipc	ra,0xfffff
    80004d84:	cc6080e7          	jalr	-826(ra) # 80003a46 <iunlockput>
    end_op();
    80004d88:	fffff097          	auipc	ra,0xfffff
    80004d8c:	49e080e7          	jalr	1182(ra) # 80004226 <end_op>
  }
  return -1;
    80004d90:	557d                	li	a0,-1
}
    80004d92:	20813083          	ld	ra,520(sp)
    80004d96:	20013403          	ld	s0,512(sp)
    80004d9a:	74fe                	ld	s1,504(sp)
    80004d9c:	795e                	ld	s2,496(sp)
    80004d9e:	79be                	ld	s3,488(sp)
    80004da0:	7a1e                	ld	s4,480(sp)
    80004da2:	6afe                	ld	s5,472(sp)
    80004da4:	6b5e                	ld	s6,464(sp)
    80004da6:	6bbe                	ld	s7,456(sp)
    80004da8:	6c1e                	ld	s8,448(sp)
    80004daa:	7cfa                	ld	s9,440(sp)
    80004dac:	7d5a                	ld	s10,432(sp)
    80004dae:	7dba                	ld	s11,424(sp)
    80004db0:	21010113          	addi	sp,sp,528
    80004db4:	8082                	ret
    end_op();
    80004db6:	fffff097          	auipc	ra,0xfffff
    80004dba:	470080e7          	jalr	1136(ra) # 80004226 <end_op>
    return -1;
    80004dbe:	557d                	li	a0,-1
    80004dc0:	bfc9                	j	80004d92 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004dc2:	854a                	mv	a0,s2
    80004dc4:	ffffd097          	auipc	ra,0xffffd
    80004dc8:	dda080e7          	jalr	-550(ra) # 80001b9e <proc_pagetable>
    80004dcc:	8baa                	mv	s7,a0
    80004dce:	d945                	beqz	a0,80004d7e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dd0:	e7042983          	lw	s3,-400(s0)
    80004dd4:	e8845783          	lhu	a5,-376(s0)
    80004dd8:	c7ad                	beqz	a5,80004e42 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dda:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ddc:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004dde:	6c85                	lui	s9,0x1
    80004de0:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004de4:	def43823          	sd	a5,-528(s0)
    80004de8:	ac3d                	j	80005026 <exec+0x32c>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004dea:	00004517          	auipc	a0,0x4
    80004dee:	89e50513          	addi	a0,a0,-1890 # 80008688 <syscalls+0x280>
    80004df2:	ffffb097          	auipc	ra,0xffffb
    80004df6:	752080e7          	jalr	1874(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dfa:	8756                	mv	a4,s5
    80004dfc:	012d86bb          	addw	a3,s11,s2
    80004e00:	4581                	li	a1,0
    80004e02:	8526                	mv	a0,s1
    80004e04:	fffff097          	auipc	ra,0xfffff
    80004e08:	c94080e7          	jalr	-876(ra) # 80003a98 <readi>
    80004e0c:	2501                	sext.w	a0,a0
    80004e0e:	1caa9063          	bne	s5,a0,80004fce <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004e12:	6785                	lui	a5,0x1
    80004e14:	0127893b          	addw	s2,a5,s2
    80004e18:	77fd                	lui	a5,0xfffff
    80004e1a:	01478a3b          	addw	s4,a5,s4
    80004e1e:	1f897b63          	bgeu	s2,s8,80005014 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004e22:	02091593          	slli	a1,s2,0x20
    80004e26:	9181                	srli	a1,a1,0x20
    80004e28:	95ea                	add	a1,a1,s10
    80004e2a:	855e                	mv	a0,s7
    80004e2c:	ffffc097          	auipc	ra,0xffffc
    80004e30:	2e0080e7          	jalr	736(ra) # 8000110c <walkaddr>
    80004e34:	862a                	mv	a2,a0
    if(pa == 0)
    80004e36:	d955                	beqz	a0,80004dea <exec+0xf0>
      n = PGSIZE;
    80004e38:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e3a:	fd9a70e3          	bgeu	s4,s9,80004dfa <exec+0x100>
      n = sz - i;
    80004e3e:	8ad2                	mv	s5,s4
    80004e40:	bf6d                	j	80004dfa <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e42:	4a01                	li	s4,0
  iunlockput(ip);
    80004e44:	8526                	mv	a0,s1
    80004e46:	fffff097          	auipc	ra,0xfffff
    80004e4a:	c00080e7          	jalr	-1024(ra) # 80003a46 <iunlockput>
  end_op();
    80004e4e:	fffff097          	auipc	ra,0xfffff
    80004e52:	3d8080e7          	jalr	984(ra) # 80004226 <end_op>
  p = myproc();
    80004e56:	ffffd097          	auipc	ra,0xffffd
    80004e5a:	c84080e7          	jalr	-892(ra) # 80001ada <myproc>
    80004e5e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e60:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e64:	6785                	lui	a5,0x1
    80004e66:	17fd                	addi	a5,a5,-1
    80004e68:	9a3e                	add	s4,s4,a5
    80004e6a:	757d                	lui	a0,0xfffff
    80004e6c:	00aa77b3          	and	a5,s4,a0
    80004e70:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e74:	4691                	li	a3,4
    80004e76:	6609                	lui	a2,0x2
    80004e78:	963e                	add	a2,a2,a5
    80004e7a:	85be                	mv	a1,a5
    80004e7c:	855e                	mv	a0,s7
    80004e7e:	ffffc097          	auipc	ra,0xffffc
    80004e82:	5f2080e7          	jalr	1522(ra) # 80001470 <uvmalloc>
    80004e86:	8b2a                	mv	s6,a0
  ip = 0;
    80004e88:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e8a:	14050263          	beqz	a0,80004fce <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e8e:	75f9                	lui	a1,0xffffe
    80004e90:	95aa                	add	a1,a1,a0
    80004e92:	855e                	mv	a0,s7
    80004e94:	ffffc097          	auipc	ra,0xffffc
    80004e98:	7e6080e7          	jalr	2022(ra) # 8000167a <uvmclear>
  stackbase = sp - PGSIZE;
    80004e9c:	7c7d                	lui	s8,0xfffff
    80004e9e:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ea0:	e0043783          	ld	a5,-512(s0)
    80004ea4:	6388                	ld	a0,0(a5)
    80004ea6:	c535                	beqz	a0,80004f12 <exec+0x218>
    80004ea8:	e9040993          	addi	s3,s0,-368
    80004eac:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004eb0:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004eb2:	ffffc097          	auipc	ra,0xffffc
    80004eb6:	fb8080e7          	jalr	-72(ra) # 80000e6a <strlen>
    80004eba:	2505                	addiw	a0,a0,1
    80004ebc:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ec0:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004ec4:	13896c63          	bltu	s2,s8,80004ffc <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ec8:	e0043d83          	ld	s11,-512(s0)
    80004ecc:	000dba03          	ld	s4,0(s11)
    80004ed0:	8552                	mv	a0,s4
    80004ed2:	ffffc097          	auipc	ra,0xffffc
    80004ed6:	f98080e7          	jalr	-104(ra) # 80000e6a <strlen>
    80004eda:	0015069b          	addiw	a3,a0,1
    80004ede:	8652                	mv	a2,s4
    80004ee0:	85ca                	mv	a1,s2
    80004ee2:	855e                	mv	a0,s7
    80004ee4:	ffffc097          	auipc	ra,0xffffc
    80004ee8:	7c8080e7          	jalr	1992(ra) # 800016ac <copyout>
    80004eec:	10054c63          	bltz	a0,80005004 <exec+0x30a>
    ustack[argc] = sp;
    80004ef0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ef4:	0485                	addi	s1,s1,1
    80004ef6:	008d8793          	addi	a5,s11,8
    80004efa:	e0f43023          	sd	a5,-512(s0)
    80004efe:	008db503          	ld	a0,8(s11)
    80004f02:	c911                	beqz	a0,80004f16 <exec+0x21c>
    if(argc >= MAXARG)
    80004f04:	09a1                	addi	s3,s3,8
    80004f06:	fb3c96e3          	bne	s9,s3,80004eb2 <exec+0x1b8>
  sz = sz1;
    80004f0a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f0e:	4481                	li	s1,0
    80004f10:	a87d                	j	80004fce <exec+0x2d4>
  sp = sz;
    80004f12:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f14:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f16:	00349793          	slli	a5,s1,0x3
    80004f1a:	f9040713          	addi	a4,s0,-112
    80004f1e:	97ba                	add	a5,a5,a4
    80004f20:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004f24:	00148693          	addi	a3,s1,1
    80004f28:	068e                	slli	a3,a3,0x3
    80004f2a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f2e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f32:	01897663          	bgeu	s2,s8,80004f3e <exec+0x244>
  sz = sz1;
    80004f36:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f3a:	4481                	li	s1,0
    80004f3c:	a849                	j	80004fce <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f3e:	e9040613          	addi	a2,s0,-368
    80004f42:	85ca                	mv	a1,s2
    80004f44:	855e                	mv	a0,s7
    80004f46:	ffffc097          	auipc	ra,0xffffc
    80004f4a:	766080e7          	jalr	1894(ra) # 800016ac <copyout>
    80004f4e:	0a054f63          	bltz	a0,8000500c <exec+0x312>
  p->trapframe->a1 = sp;
    80004f52:	058ab783          	ld	a5,88(s5)
    80004f56:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f5a:	df843783          	ld	a5,-520(s0)
    80004f5e:	0007c703          	lbu	a4,0(a5)
    80004f62:	cf11                	beqz	a4,80004f7e <exec+0x284>
    80004f64:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f66:	02f00693          	li	a3,47
    80004f6a:	a039                	j	80004f78 <exec+0x27e>
      last = s+1;
    80004f6c:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f70:	0785                	addi	a5,a5,1
    80004f72:	fff7c703          	lbu	a4,-1(a5)
    80004f76:	c701                	beqz	a4,80004f7e <exec+0x284>
    if(*s == '/')
    80004f78:	fed71ce3          	bne	a4,a3,80004f70 <exec+0x276>
    80004f7c:	bfc5                	j	80004f6c <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f7e:	4641                	li	a2,16
    80004f80:	df843583          	ld	a1,-520(s0)
    80004f84:	158a8513          	addi	a0,s5,344
    80004f88:	ffffc097          	auipc	ra,0xffffc
    80004f8c:	eb0080e7          	jalr	-336(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f90:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f94:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f98:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f9c:	058ab783          	ld	a5,88(s5)
    80004fa0:	e6843703          	ld	a4,-408(s0)
    80004fa4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004fa6:	058ab783          	ld	a5,88(s5)
    80004faa:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004fae:	85ea                	mv	a1,s10
    80004fb0:	ffffd097          	auipc	ra,0xffffd
    80004fb4:	c8a080e7          	jalr	-886(ra) # 80001c3a <proc_freepagetable>
  vmprint(p->pagetable);
    80004fb8:	050ab503          	ld	a0,80(s5)
    80004fbc:	ffffd097          	auipc	ra,0xffffd
    80004fc0:	974080e7          	jalr	-1676(ra) # 80001930 <vmprint>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fc4:	0004851b          	sext.w	a0,s1
    80004fc8:	b3e9                	j	80004d92 <exec+0x98>
    80004fca:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004fce:	e0843583          	ld	a1,-504(s0)
    80004fd2:	855e                	mv	a0,s7
    80004fd4:	ffffd097          	auipc	ra,0xffffd
    80004fd8:	c66080e7          	jalr	-922(ra) # 80001c3a <proc_freepagetable>
  if(ip){
    80004fdc:	da0491e3          	bnez	s1,80004d7e <exec+0x84>
  return -1;
    80004fe0:	557d                	li	a0,-1
    80004fe2:	bb45                	j	80004d92 <exec+0x98>
    80004fe4:	e1443423          	sd	s4,-504(s0)
    80004fe8:	b7dd                	j	80004fce <exec+0x2d4>
    80004fea:	e1443423          	sd	s4,-504(s0)
    80004fee:	b7c5                	j	80004fce <exec+0x2d4>
    80004ff0:	e1443423          	sd	s4,-504(s0)
    80004ff4:	bfe9                	j	80004fce <exec+0x2d4>
    80004ff6:	e1443423          	sd	s4,-504(s0)
    80004ffa:	bfd1                	j	80004fce <exec+0x2d4>
  sz = sz1;
    80004ffc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005000:	4481                	li	s1,0
    80005002:	b7f1                	j	80004fce <exec+0x2d4>
  sz = sz1;
    80005004:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005008:	4481                	li	s1,0
    8000500a:	b7d1                	j	80004fce <exec+0x2d4>
  sz = sz1;
    8000500c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005010:	4481                	li	s1,0
    80005012:	bf75                	j	80004fce <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005014:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005018:	2b05                	addiw	s6,s6,1
    8000501a:	0389899b          	addiw	s3,s3,56
    8000501e:	e8845783          	lhu	a5,-376(s0)
    80005022:	e2fb51e3          	bge	s6,a5,80004e44 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005026:	2981                	sext.w	s3,s3
    80005028:	03800713          	li	a4,56
    8000502c:	86ce                	mv	a3,s3
    8000502e:	e1840613          	addi	a2,s0,-488
    80005032:	4581                	li	a1,0
    80005034:	8526                	mv	a0,s1
    80005036:	fffff097          	auipc	ra,0xfffff
    8000503a:	a62080e7          	jalr	-1438(ra) # 80003a98 <readi>
    8000503e:	03800793          	li	a5,56
    80005042:	f8f514e3          	bne	a0,a5,80004fca <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005046:	e1842783          	lw	a5,-488(s0)
    8000504a:	4705                	li	a4,1
    8000504c:	fce796e3          	bne	a5,a4,80005018 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005050:	e4043903          	ld	s2,-448(s0)
    80005054:	e3843783          	ld	a5,-456(s0)
    80005058:	f8f966e3          	bltu	s2,a5,80004fe4 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000505c:	e2843783          	ld	a5,-472(s0)
    80005060:	993e                	add	s2,s2,a5
    80005062:	f8f964e3          	bltu	s2,a5,80004fea <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005066:	df043703          	ld	a4,-528(s0)
    8000506a:	8ff9                	and	a5,a5,a4
    8000506c:	f3d1                	bnez	a5,80004ff0 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000506e:	e1c42503          	lw	a0,-484(s0)
    80005072:	00000097          	auipc	ra,0x0
    80005076:	c6c080e7          	jalr	-916(ra) # 80004cde <flags2perm>
    8000507a:	86aa                	mv	a3,a0
    8000507c:	864a                	mv	a2,s2
    8000507e:	85d2                	mv	a1,s4
    80005080:	855e                	mv	a0,s7
    80005082:	ffffc097          	auipc	ra,0xffffc
    80005086:	3ee080e7          	jalr	1006(ra) # 80001470 <uvmalloc>
    8000508a:	e0a43423          	sd	a0,-504(s0)
    8000508e:	d525                	beqz	a0,80004ff6 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005090:	e2843d03          	ld	s10,-472(s0)
    80005094:	e2042d83          	lw	s11,-480(s0)
    80005098:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000509c:	f60c0ce3          	beqz	s8,80005014 <exec+0x31a>
    800050a0:	8a62                	mv	s4,s8
    800050a2:	4901                	li	s2,0
    800050a4:	bbbd                	j	80004e22 <exec+0x128>

00000000800050a6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050a6:	7179                	addi	sp,sp,-48
    800050a8:	f406                	sd	ra,40(sp)
    800050aa:	f022                	sd	s0,32(sp)
    800050ac:	ec26                	sd	s1,24(sp)
    800050ae:	e84a                	sd	s2,16(sp)
    800050b0:	1800                	addi	s0,sp,48
    800050b2:	892e                	mv	s2,a1
    800050b4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800050b6:	fdc40593          	addi	a1,s0,-36
    800050ba:	ffffe097          	auipc	ra,0xffffe
    800050be:	ba8080e7          	jalr	-1112(ra) # 80002c62 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050c2:	fdc42703          	lw	a4,-36(s0)
    800050c6:	47bd                	li	a5,15
    800050c8:	02e7eb63          	bltu	a5,a4,800050fe <argfd+0x58>
    800050cc:	ffffd097          	auipc	ra,0xffffd
    800050d0:	a0e080e7          	jalr	-1522(ra) # 80001ada <myproc>
    800050d4:	fdc42703          	lw	a4,-36(s0)
    800050d8:	01a70793          	addi	a5,a4,26
    800050dc:	078e                	slli	a5,a5,0x3
    800050de:	953e                	add	a0,a0,a5
    800050e0:	611c                	ld	a5,0(a0)
    800050e2:	c385                	beqz	a5,80005102 <argfd+0x5c>
    return -1;
  if(pfd)
    800050e4:	00090463          	beqz	s2,800050ec <argfd+0x46>
    *pfd = fd;
    800050e8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050ec:	4501                	li	a0,0
  if(pf)
    800050ee:	c091                	beqz	s1,800050f2 <argfd+0x4c>
    *pf = f;
    800050f0:	e09c                	sd	a5,0(s1)
}
    800050f2:	70a2                	ld	ra,40(sp)
    800050f4:	7402                	ld	s0,32(sp)
    800050f6:	64e2                	ld	s1,24(sp)
    800050f8:	6942                	ld	s2,16(sp)
    800050fa:	6145                	addi	sp,sp,48
    800050fc:	8082                	ret
    return -1;
    800050fe:	557d                	li	a0,-1
    80005100:	bfcd                	j	800050f2 <argfd+0x4c>
    80005102:	557d                	li	a0,-1
    80005104:	b7fd                	j	800050f2 <argfd+0x4c>

0000000080005106 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005106:	1101                	addi	sp,sp,-32
    80005108:	ec06                	sd	ra,24(sp)
    8000510a:	e822                	sd	s0,16(sp)
    8000510c:	e426                	sd	s1,8(sp)
    8000510e:	1000                	addi	s0,sp,32
    80005110:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005112:	ffffd097          	auipc	ra,0xffffd
    80005116:	9c8080e7          	jalr	-1592(ra) # 80001ada <myproc>
    8000511a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000511c:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffdd3d0>
    80005120:	4501                	li	a0,0
    80005122:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005124:	6398                	ld	a4,0(a5)
    80005126:	cb19                	beqz	a4,8000513c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005128:	2505                	addiw	a0,a0,1
    8000512a:	07a1                	addi	a5,a5,8
    8000512c:	fed51ce3          	bne	a0,a3,80005124 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005130:	557d                	li	a0,-1
}
    80005132:	60e2                	ld	ra,24(sp)
    80005134:	6442                	ld	s0,16(sp)
    80005136:	64a2                	ld	s1,8(sp)
    80005138:	6105                	addi	sp,sp,32
    8000513a:	8082                	ret
      p->ofile[fd] = f;
    8000513c:	01a50793          	addi	a5,a0,26
    80005140:	078e                	slli	a5,a5,0x3
    80005142:	963e                	add	a2,a2,a5
    80005144:	e204                	sd	s1,0(a2)
      return fd;
    80005146:	b7f5                	j	80005132 <fdalloc+0x2c>

0000000080005148 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005148:	715d                	addi	sp,sp,-80
    8000514a:	e486                	sd	ra,72(sp)
    8000514c:	e0a2                	sd	s0,64(sp)
    8000514e:	fc26                	sd	s1,56(sp)
    80005150:	f84a                	sd	s2,48(sp)
    80005152:	f44e                	sd	s3,40(sp)
    80005154:	f052                	sd	s4,32(sp)
    80005156:	ec56                	sd	s5,24(sp)
    80005158:	e85a                	sd	s6,16(sp)
    8000515a:	0880                	addi	s0,sp,80
    8000515c:	8b2e                	mv	s6,a1
    8000515e:	89b2                	mv	s3,a2
    80005160:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005162:	fb040593          	addi	a1,s0,-80
    80005166:	fffff097          	auipc	ra,0xfffff
    8000516a:	e42080e7          	jalr	-446(ra) # 80003fa8 <nameiparent>
    8000516e:	84aa                	mv	s1,a0
    80005170:	16050063          	beqz	a0,800052d0 <create+0x188>
    return 0;

  ilock(dp);
    80005174:	ffffe097          	auipc	ra,0xffffe
    80005178:	670080e7          	jalr	1648(ra) # 800037e4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000517c:	4601                	li	a2,0
    8000517e:	fb040593          	addi	a1,s0,-80
    80005182:	8526                	mv	a0,s1
    80005184:	fffff097          	auipc	ra,0xfffff
    80005188:	b44080e7          	jalr	-1212(ra) # 80003cc8 <dirlookup>
    8000518c:	8aaa                	mv	s5,a0
    8000518e:	c931                	beqz	a0,800051e2 <create+0x9a>
    iunlockput(dp);
    80005190:	8526                	mv	a0,s1
    80005192:	fffff097          	auipc	ra,0xfffff
    80005196:	8b4080e7          	jalr	-1868(ra) # 80003a46 <iunlockput>
    ilock(ip);
    8000519a:	8556                	mv	a0,s5
    8000519c:	ffffe097          	auipc	ra,0xffffe
    800051a0:	648080e7          	jalr	1608(ra) # 800037e4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051a4:	000b059b          	sext.w	a1,s6
    800051a8:	4789                	li	a5,2
    800051aa:	02f59563          	bne	a1,a5,800051d4 <create+0x8c>
    800051ae:	044ad783          	lhu	a5,68(s5)
    800051b2:	37f9                	addiw	a5,a5,-2
    800051b4:	17c2                	slli	a5,a5,0x30
    800051b6:	93c1                	srli	a5,a5,0x30
    800051b8:	4705                	li	a4,1
    800051ba:	00f76d63          	bltu	a4,a5,800051d4 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800051be:	8556                	mv	a0,s5
    800051c0:	60a6                	ld	ra,72(sp)
    800051c2:	6406                	ld	s0,64(sp)
    800051c4:	74e2                	ld	s1,56(sp)
    800051c6:	7942                	ld	s2,48(sp)
    800051c8:	79a2                	ld	s3,40(sp)
    800051ca:	7a02                	ld	s4,32(sp)
    800051cc:	6ae2                	ld	s5,24(sp)
    800051ce:	6b42                	ld	s6,16(sp)
    800051d0:	6161                	addi	sp,sp,80
    800051d2:	8082                	ret
    iunlockput(ip);
    800051d4:	8556                	mv	a0,s5
    800051d6:	fffff097          	auipc	ra,0xfffff
    800051da:	870080e7          	jalr	-1936(ra) # 80003a46 <iunlockput>
    return 0;
    800051de:	4a81                	li	s5,0
    800051e0:	bff9                	j	800051be <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800051e2:	85da                	mv	a1,s6
    800051e4:	4088                	lw	a0,0(s1)
    800051e6:	ffffe097          	auipc	ra,0xffffe
    800051ea:	462080e7          	jalr	1122(ra) # 80003648 <ialloc>
    800051ee:	8a2a                	mv	s4,a0
    800051f0:	c921                	beqz	a0,80005240 <create+0xf8>
  ilock(ip);
    800051f2:	ffffe097          	auipc	ra,0xffffe
    800051f6:	5f2080e7          	jalr	1522(ra) # 800037e4 <ilock>
  ip->major = major;
    800051fa:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800051fe:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005202:	4785                	li	a5,1
    80005204:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    80005208:	8552                	mv	a0,s4
    8000520a:	ffffe097          	auipc	ra,0xffffe
    8000520e:	510080e7          	jalr	1296(ra) # 8000371a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005212:	000b059b          	sext.w	a1,s6
    80005216:	4785                	li	a5,1
    80005218:	02f58b63          	beq	a1,a5,8000524e <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    8000521c:	004a2603          	lw	a2,4(s4)
    80005220:	fb040593          	addi	a1,s0,-80
    80005224:	8526                	mv	a0,s1
    80005226:	fffff097          	auipc	ra,0xfffff
    8000522a:	cb2080e7          	jalr	-846(ra) # 80003ed8 <dirlink>
    8000522e:	06054f63          	bltz	a0,800052ac <create+0x164>
  iunlockput(dp);
    80005232:	8526                	mv	a0,s1
    80005234:	fffff097          	auipc	ra,0xfffff
    80005238:	812080e7          	jalr	-2030(ra) # 80003a46 <iunlockput>
  return ip;
    8000523c:	8ad2                	mv	s5,s4
    8000523e:	b741                	j	800051be <create+0x76>
    iunlockput(dp);
    80005240:	8526                	mv	a0,s1
    80005242:	fffff097          	auipc	ra,0xfffff
    80005246:	804080e7          	jalr	-2044(ra) # 80003a46 <iunlockput>
    return 0;
    8000524a:	8ad2                	mv	s5,s4
    8000524c:	bf8d                	j	800051be <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000524e:	004a2603          	lw	a2,4(s4)
    80005252:	00003597          	auipc	a1,0x3
    80005256:	45658593          	addi	a1,a1,1110 # 800086a8 <syscalls+0x2a0>
    8000525a:	8552                	mv	a0,s4
    8000525c:	fffff097          	auipc	ra,0xfffff
    80005260:	c7c080e7          	jalr	-900(ra) # 80003ed8 <dirlink>
    80005264:	04054463          	bltz	a0,800052ac <create+0x164>
    80005268:	40d0                	lw	a2,4(s1)
    8000526a:	00003597          	auipc	a1,0x3
    8000526e:	44658593          	addi	a1,a1,1094 # 800086b0 <syscalls+0x2a8>
    80005272:	8552                	mv	a0,s4
    80005274:	fffff097          	auipc	ra,0xfffff
    80005278:	c64080e7          	jalr	-924(ra) # 80003ed8 <dirlink>
    8000527c:	02054863          	bltz	a0,800052ac <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    80005280:	004a2603          	lw	a2,4(s4)
    80005284:	fb040593          	addi	a1,s0,-80
    80005288:	8526                	mv	a0,s1
    8000528a:	fffff097          	auipc	ra,0xfffff
    8000528e:	c4e080e7          	jalr	-946(ra) # 80003ed8 <dirlink>
    80005292:	00054d63          	bltz	a0,800052ac <create+0x164>
    dp->nlink++;  // for ".."
    80005296:	04a4d783          	lhu	a5,74(s1)
    8000529a:	2785                	addiw	a5,a5,1
    8000529c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800052a0:	8526                	mv	a0,s1
    800052a2:	ffffe097          	auipc	ra,0xffffe
    800052a6:	478080e7          	jalr	1144(ra) # 8000371a <iupdate>
    800052aa:	b761                	j	80005232 <create+0xea>
  ip->nlink = 0;
    800052ac:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800052b0:	8552                	mv	a0,s4
    800052b2:	ffffe097          	auipc	ra,0xffffe
    800052b6:	468080e7          	jalr	1128(ra) # 8000371a <iupdate>
  iunlockput(ip);
    800052ba:	8552                	mv	a0,s4
    800052bc:	ffffe097          	auipc	ra,0xffffe
    800052c0:	78a080e7          	jalr	1930(ra) # 80003a46 <iunlockput>
  iunlockput(dp);
    800052c4:	8526                	mv	a0,s1
    800052c6:	ffffe097          	auipc	ra,0xffffe
    800052ca:	780080e7          	jalr	1920(ra) # 80003a46 <iunlockput>
  return 0;
    800052ce:	bdc5                	j	800051be <create+0x76>
    return 0;
    800052d0:	8aaa                	mv	s5,a0
    800052d2:	b5f5                	j	800051be <create+0x76>

00000000800052d4 <sys_dup>:
{
    800052d4:	7179                	addi	sp,sp,-48
    800052d6:	f406                	sd	ra,40(sp)
    800052d8:	f022                	sd	s0,32(sp)
    800052da:	ec26                	sd	s1,24(sp)
    800052dc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052de:	fd840613          	addi	a2,s0,-40
    800052e2:	4581                	li	a1,0
    800052e4:	4501                	li	a0,0
    800052e6:	00000097          	auipc	ra,0x0
    800052ea:	dc0080e7          	jalr	-576(ra) # 800050a6 <argfd>
    return -1;
    800052ee:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052f0:	02054363          	bltz	a0,80005316 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052f4:	fd843503          	ld	a0,-40(s0)
    800052f8:	00000097          	auipc	ra,0x0
    800052fc:	e0e080e7          	jalr	-498(ra) # 80005106 <fdalloc>
    80005300:	84aa                	mv	s1,a0
    return -1;
    80005302:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005304:	00054963          	bltz	a0,80005316 <sys_dup+0x42>
  filedup(f);
    80005308:	fd843503          	ld	a0,-40(s0)
    8000530c:	fffff097          	auipc	ra,0xfffff
    80005310:	314080e7          	jalr	788(ra) # 80004620 <filedup>
  return fd;
    80005314:	87a6                	mv	a5,s1
}
    80005316:	853e                	mv	a0,a5
    80005318:	70a2                	ld	ra,40(sp)
    8000531a:	7402                	ld	s0,32(sp)
    8000531c:	64e2                	ld	s1,24(sp)
    8000531e:	6145                	addi	sp,sp,48
    80005320:	8082                	ret

0000000080005322 <sys_read>:
{
    80005322:	7179                	addi	sp,sp,-48
    80005324:	f406                	sd	ra,40(sp)
    80005326:	f022                	sd	s0,32(sp)
    80005328:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000532a:	fd840593          	addi	a1,s0,-40
    8000532e:	4505                	li	a0,1
    80005330:	ffffe097          	auipc	ra,0xffffe
    80005334:	952080e7          	jalr	-1710(ra) # 80002c82 <argaddr>
  argint(2, &n);
    80005338:	fe440593          	addi	a1,s0,-28
    8000533c:	4509                	li	a0,2
    8000533e:	ffffe097          	auipc	ra,0xffffe
    80005342:	924080e7          	jalr	-1756(ra) # 80002c62 <argint>
  if(argfd(0, 0, &f) < 0)
    80005346:	fe840613          	addi	a2,s0,-24
    8000534a:	4581                	li	a1,0
    8000534c:	4501                	li	a0,0
    8000534e:	00000097          	auipc	ra,0x0
    80005352:	d58080e7          	jalr	-680(ra) # 800050a6 <argfd>
    80005356:	87aa                	mv	a5,a0
    return -1;
    80005358:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000535a:	0007cc63          	bltz	a5,80005372 <sys_read+0x50>
  return fileread(f, p, n);
    8000535e:	fe442603          	lw	a2,-28(s0)
    80005362:	fd843583          	ld	a1,-40(s0)
    80005366:	fe843503          	ld	a0,-24(s0)
    8000536a:	fffff097          	auipc	ra,0xfffff
    8000536e:	442080e7          	jalr	1090(ra) # 800047ac <fileread>
}
    80005372:	70a2                	ld	ra,40(sp)
    80005374:	7402                	ld	s0,32(sp)
    80005376:	6145                	addi	sp,sp,48
    80005378:	8082                	ret

000000008000537a <sys_write>:
{
    8000537a:	7179                	addi	sp,sp,-48
    8000537c:	f406                	sd	ra,40(sp)
    8000537e:	f022                	sd	s0,32(sp)
    80005380:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005382:	fd840593          	addi	a1,s0,-40
    80005386:	4505                	li	a0,1
    80005388:	ffffe097          	auipc	ra,0xffffe
    8000538c:	8fa080e7          	jalr	-1798(ra) # 80002c82 <argaddr>
  argint(2, &n);
    80005390:	fe440593          	addi	a1,s0,-28
    80005394:	4509                	li	a0,2
    80005396:	ffffe097          	auipc	ra,0xffffe
    8000539a:	8cc080e7          	jalr	-1844(ra) # 80002c62 <argint>
  if(argfd(0, 0, &f) < 0)
    8000539e:	fe840613          	addi	a2,s0,-24
    800053a2:	4581                	li	a1,0
    800053a4:	4501                	li	a0,0
    800053a6:	00000097          	auipc	ra,0x0
    800053aa:	d00080e7          	jalr	-768(ra) # 800050a6 <argfd>
    800053ae:	87aa                	mv	a5,a0
    return -1;
    800053b0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053b2:	0007cc63          	bltz	a5,800053ca <sys_write+0x50>
  return filewrite(f, p, n);
    800053b6:	fe442603          	lw	a2,-28(s0)
    800053ba:	fd843583          	ld	a1,-40(s0)
    800053be:	fe843503          	ld	a0,-24(s0)
    800053c2:	fffff097          	auipc	ra,0xfffff
    800053c6:	4ac080e7          	jalr	1196(ra) # 8000486e <filewrite>
}
    800053ca:	70a2                	ld	ra,40(sp)
    800053cc:	7402                	ld	s0,32(sp)
    800053ce:	6145                	addi	sp,sp,48
    800053d0:	8082                	ret

00000000800053d2 <sys_close>:
{
    800053d2:	1101                	addi	sp,sp,-32
    800053d4:	ec06                	sd	ra,24(sp)
    800053d6:	e822                	sd	s0,16(sp)
    800053d8:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053da:	fe040613          	addi	a2,s0,-32
    800053de:	fec40593          	addi	a1,s0,-20
    800053e2:	4501                	li	a0,0
    800053e4:	00000097          	auipc	ra,0x0
    800053e8:	cc2080e7          	jalr	-830(ra) # 800050a6 <argfd>
    return -1;
    800053ec:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053ee:	02054463          	bltz	a0,80005416 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053f2:	ffffc097          	auipc	ra,0xffffc
    800053f6:	6e8080e7          	jalr	1768(ra) # 80001ada <myproc>
    800053fa:	fec42783          	lw	a5,-20(s0)
    800053fe:	07e9                	addi	a5,a5,26
    80005400:	078e                	slli	a5,a5,0x3
    80005402:	97aa                	add	a5,a5,a0
    80005404:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005408:	fe043503          	ld	a0,-32(s0)
    8000540c:	fffff097          	auipc	ra,0xfffff
    80005410:	266080e7          	jalr	614(ra) # 80004672 <fileclose>
  return 0;
    80005414:	4781                	li	a5,0
}
    80005416:	853e                	mv	a0,a5
    80005418:	60e2                	ld	ra,24(sp)
    8000541a:	6442                	ld	s0,16(sp)
    8000541c:	6105                	addi	sp,sp,32
    8000541e:	8082                	ret

0000000080005420 <sys_fstat>:
{
    80005420:	1101                	addi	sp,sp,-32
    80005422:	ec06                	sd	ra,24(sp)
    80005424:	e822                	sd	s0,16(sp)
    80005426:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005428:	fe040593          	addi	a1,s0,-32
    8000542c:	4505                	li	a0,1
    8000542e:	ffffe097          	auipc	ra,0xffffe
    80005432:	854080e7          	jalr	-1964(ra) # 80002c82 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005436:	fe840613          	addi	a2,s0,-24
    8000543a:	4581                	li	a1,0
    8000543c:	4501                	li	a0,0
    8000543e:	00000097          	auipc	ra,0x0
    80005442:	c68080e7          	jalr	-920(ra) # 800050a6 <argfd>
    80005446:	87aa                	mv	a5,a0
    return -1;
    80005448:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000544a:	0007ca63          	bltz	a5,8000545e <sys_fstat+0x3e>
  return filestat(f, st);
    8000544e:	fe043583          	ld	a1,-32(s0)
    80005452:	fe843503          	ld	a0,-24(s0)
    80005456:	fffff097          	auipc	ra,0xfffff
    8000545a:	2e4080e7          	jalr	740(ra) # 8000473a <filestat>
}
    8000545e:	60e2                	ld	ra,24(sp)
    80005460:	6442                	ld	s0,16(sp)
    80005462:	6105                	addi	sp,sp,32
    80005464:	8082                	ret

0000000080005466 <sys_link>:
{
    80005466:	7169                	addi	sp,sp,-304
    80005468:	f606                	sd	ra,296(sp)
    8000546a:	f222                	sd	s0,288(sp)
    8000546c:	ee26                	sd	s1,280(sp)
    8000546e:	ea4a                	sd	s2,272(sp)
    80005470:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005472:	08000613          	li	a2,128
    80005476:	ed040593          	addi	a1,s0,-304
    8000547a:	4501                	li	a0,0
    8000547c:	ffffe097          	auipc	ra,0xffffe
    80005480:	826080e7          	jalr	-2010(ra) # 80002ca2 <argstr>
    return -1;
    80005484:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005486:	10054e63          	bltz	a0,800055a2 <sys_link+0x13c>
    8000548a:	08000613          	li	a2,128
    8000548e:	f5040593          	addi	a1,s0,-176
    80005492:	4505                	li	a0,1
    80005494:	ffffe097          	auipc	ra,0xffffe
    80005498:	80e080e7          	jalr	-2034(ra) # 80002ca2 <argstr>
    return -1;
    8000549c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000549e:	10054263          	bltz	a0,800055a2 <sys_link+0x13c>
  begin_op();
    800054a2:	fffff097          	auipc	ra,0xfffff
    800054a6:	d04080e7          	jalr	-764(ra) # 800041a6 <begin_op>
  if((ip = namei(old)) == 0){
    800054aa:	ed040513          	addi	a0,s0,-304
    800054ae:	fffff097          	auipc	ra,0xfffff
    800054b2:	adc080e7          	jalr	-1316(ra) # 80003f8a <namei>
    800054b6:	84aa                	mv	s1,a0
    800054b8:	c551                	beqz	a0,80005544 <sys_link+0xde>
  ilock(ip);
    800054ba:	ffffe097          	auipc	ra,0xffffe
    800054be:	32a080e7          	jalr	810(ra) # 800037e4 <ilock>
  if(ip->type == T_DIR){
    800054c2:	04449703          	lh	a4,68(s1)
    800054c6:	4785                	li	a5,1
    800054c8:	08f70463          	beq	a4,a5,80005550 <sys_link+0xea>
  ip->nlink++;
    800054cc:	04a4d783          	lhu	a5,74(s1)
    800054d0:	2785                	addiw	a5,a5,1
    800054d2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054d6:	8526                	mv	a0,s1
    800054d8:	ffffe097          	auipc	ra,0xffffe
    800054dc:	242080e7          	jalr	578(ra) # 8000371a <iupdate>
  iunlock(ip);
    800054e0:	8526                	mv	a0,s1
    800054e2:	ffffe097          	auipc	ra,0xffffe
    800054e6:	3c4080e7          	jalr	964(ra) # 800038a6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054ea:	fd040593          	addi	a1,s0,-48
    800054ee:	f5040513          	addi	a0,s0,-176
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	ab6080e7          	jalr	-1354(ra) # 80003fa8 <nameiparent>
    800054fa:	892a                	mv	s2,a0
    800054fc:	c935                	beqz	a0,80005570 <sys_link+0x10a>
  ilock(dp);
    800054fe:	ffffe097          	auipc	ra,0xffffe
    80005502:	2e6080e7          	jalr	742(ra) # 800037e4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005506:	00092703          	lw	a4,0(s2)
    8000550a:	409c                	lw	a5,0(s1)
    8000550c:	04f71d63          	bne	a4,a5,80005566 <sys_link+0x100>
    80005510:	40d0                	lw	a2,4(s1)
    80005512:	fd040593          	addi	a1,s0,-48
    80005516:	854a                	mv	a0,s2
    80005518:	fffff097          	auipc	ra,0xfffff
    8000551c:	9c0080e7          	jalr	-1600(ra) # 80003ed8 <dirlink>
    80005520:	04054363          	bltz	a0,80005566 <sys_link+0x100>
  iunlockput(dp);
    80005524:	854a                	mv	a0,s2
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	520080e7          	jalr	1312(ra) # 80003a46 <iunlockput>
  iput(ip);
    8000552e:	8526                	mv	a0,s1
    80005530:	ffffe097          	auipc	ra,0xffffe
    80005534:	46e080e7          	jalr	1134(ra) # 8000399e <iput>
  end_op();
    80005538:	fffff097          	auipc	ra,0xfffff
    8000553c:	cee080e7          	jalr	-786(ra) # 80004226 <end_op>
  return 0;
    80005540:	4781                	li	a5,0
    80005542:	a085                	j	800055a2 <sys_link+0x13c>
    end_op();
    80005544:	fffff097          	auipc	ra,0xfffff
    80005548:	ce2080e7          	jalr	-798(ra) # 80004226 <end_op>
    return -1;
    8000554c:	57fd                	li	a5,-1
    8000554e:	a891                	j	800055a2 <sys_link+0x13c>
    iunlockput(ip);
    80005550:	8526                	mv	a0,s1
    80005552:	ffffe097          	auipc	ra,0xffffe
    80005556:	4f4080e7          	jalr	1268(ra) # 80003a46 <iunlockput>
    end_op();
    8000555a:	fffff097          	auipc	ra,0xfffff
    8000555e:	ccc080e7          	jalr	-820(ra) # 80004226 <end_op>
    return -1;
    80005562:	57fd                	li	a5,-1
    80005564:	a83d                	j	800055a2 <sys_link+0x13c>
    iunlockput(dp);
    80005566:	854a                	mv	a0,s2
    80005568:	ffffe097          	auipc	ra,0xffffe
    8000556c:	4de080e7          	jalr	1246(ra) # 80003a46 <iunlockput>
  ilock(ip);
    80005570:	8526                	mv	a0,s1
    80005572:	ffffe097          	auipc	ra,0xffffe
    80005576:	272080e7          	jalr	626(ra) # 800037e4 <ilock>
  ip->nlink--;
    8000557a:	04a4d783          	lhu	a5,74(s1)
    8000557e:	37fd                	addiw	a5,a5,-1
    80005580:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005584:	8526                	mv	a0,s1
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	194080e7          	jalr	404(ra) # 8000371a <iupdate>
  iunlockput(ip);
    8000558e:	8526                	mv	a0,s1
    80005590:	ffffe097          	auipc	ra,0xffffe
    80005594:	4b6080e7          	jalr	1206(ra) # 80003a46 <iunlockput>
  end_op();
    80005598:	fffff097          	auipc	ra,0xfffff
    8000559c:	c8e080e7          	jalr	-882(ra) # 80004226 <end_op>
  return -1;
    800055a0:	57fd                	li	a5,-1
}
    800055a2:	853e                	mv	a0,a5
    800055a4:	70b2                	ld	ra,296(sp)
    800055a6:	7412                	ld	s0,288(sp)
    800055a8:	64f2                	ld	s1,280(sp)
    800055aa:	6952                	ld	s2,272(sp)
    800055ac:	6155                	addi	sp,sp,304
    800055ae:	8082                	ret

00000000800055b0 <sys_unlink>:
{
    800055b0:	7151                	addi	sp,sp,-240
    800055b2:	f586                	sd	ra,232(sp)
    800055b4:	f1a2                	sd	s0,224(sp)
    800055b6:	eda6                	sd	s1,216(sp)
    800055b8:	e9ca                	sd	s2,208(sp)
    800055ba:	e5ce                	sd	s3,200(sp)
    800055bc:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055be:	08000613          	li	a2,128
    800055c2:	f3040593          	addi	a1,s0,-208
    800055c6:	4501                	li	a0,0
    800055c8:	ffffd097          	auipc	ra,0xffffd
    800055cc:	6da080e7          	jalr	1754(ra) # 80002ca2 <argstr>
    800055d0:	18054163          	bltz	a0,80005752 <sys_unlink+0x1a2>
  begin_op();
    800055d4:	fffff097          	auipc	ra,0xfffff
    800055d8:	bd2080e7          	jalr	-1070(ra) # 800041a6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055dc:	fb040593          	addi	a1,s0,-80
    800055e0:	f3040513          	addi	a0,s0,-208
    800055e4:	fffff097          	auipc	ra,0xfffff
    800055e8:	9c4080e7          	jalr	-1596(ra) # 80003fa8 <nameiparent>
    800055ec:	84aa                	mv	s1,a0
    800055ee:	c979                	beqz	a0,800056c4 <sys_unlink+0x114>
  ilock(dp);
    800055f0:	ffffe097          	auipc	ra,0xffffe
    800055f4:	1f4080e7          	jalr	500(ra) # 800037e4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055f8:	00003597          	auipc	a1,0x3
    800055fc:	0b058593          	addi	a1,a1,176 # 800086a8 <syscalls+0x2a0>
    80005600:	fb040513          	addi	a0,s0,-80
    80005604:	ffffe097          	auipc	ra,0xffffe
    80005608:	6aa080e7          	jalr	1706(ra) # 80003cae <namecmp>
    8000560c:	14050a63          	beqz	a0,80005760 <sys_unlink+0x1b0>
    80005610:	00003597          	auipc	a1,0x3
    80005614:	0a058593          	addi	a1,a1,160 # 800086b0 <syscalls+0x2a8>
    80005618:	fb040513          	addi	a0,s0,-80
    8000561c:	ffffe097          	auipc	ra,0xffffe
    80005620:	692080e7          	jalr	1682(ra) # 80003cae <namecmp>
    80005624:	12050e63          	beqz	a0,80005760 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005628:	f2c40613          	addi	a2,s0,-212
    8000562c:	fb040593          	addi	a1,s0,-80
    80005630:	8526                	mv	a0,s1
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	696080e7          	jalr	1686(ra) # 80003cc8 <dirlookup>
    8000563a:	892a                	mv	s2,a0
    8000563c:	12050263          	beqz	a0,80005760 <sys_unlink+0x1b0>
  ilock(ip);
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	1a4080e7          	jalr	420(ra) # 800037e4 <ilock>
  if(ip->nlink < 1)
    80005648:	04a91783          	lh	a5,74(s2)
    8000564c:	08f05263          	blez	a5,800056d0 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005650:	04491703          	lh	a4,68(s2)
    80005654:	4785                	li	a5,1
    80005656:	08f70563          	beq	a4,a5,800056e0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000565a:	4641                	li	a2,16
    8000565c:	4581                	li	a1,0
    8000565e:	fc040513          	addi	a0,s0,-64
    80005662:	ffffb097          	auipc	ra,0xffffb
    80005666:	684080e7          	jalr	1668(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000566a:	4741                	li	a4,16
    8000566c:	f2c42683          	lw	a3,-212(s0)
    80005670:	fc040613          	addi	a2,s0,-64
    80005674:	4581                	li	a1,0
    80005676:	8526                	mv	a0,s1
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	518080e7          	jalr	1304(ra) # 80003b90 <writei>
    80005680:	47c1                	li	a5,16
    80005682:	0af51563          	bne	a0,a5,8000572c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005686:	04491703          	lh	a4,68(s2)
    8000568a:	4785                	li	a5,1
    8000568c:	0af70863          	beq	a4,a5,8000573c <sys_unlink+0x18c>
  iunlockput(dp);
    80005690:	8526                	mv	a0,s1
    80005692:	ffffe097          	auipc	ra,0xffffe
    80005696:	3b4080e7          	jalr	948(ra) # 80003a46 <iunlockput>
  ip->nlink--;
    8000569a:	04a95783          	lhu	a5,74(s2)
    8000569e:	37fd                	addiw	a5,a5,-1
    800056a0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056a4:	854a                	mv	a0,s2
    800056a6:	ffffe097          	auipc	ra,0xffffe
    800056aa:	074080e7          	jalr	116(ra) # 8000371a <iupdate>
  iunlockput(ip);
    800056ae:	854a                	mv	a0,s2
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	396080e7          	jalr	918(ra) # 80003a46 <iunlockput>
  end_op();
    800056b8:	fffff097          	auipc	ra,0xfffff
    800056bc:	b6e080e7          	jalr	-1170(ra) # 80004226 <end_op>
  return 0;
    800056c0:	4501                	li	a0,0
    800056c2:	a84d                	j	80005774 <sys_unlink+0x1c4>
    end_op();
    800056c4:	fffff097          	auipc	ra,0xfffff
    800056c8:	b62080e7          	jalr	-1182(ra) # 80004226 <end_op>
    return -1;
    800056cc:	557d                	li	a0,-1
    800056ce:	a05d                	j	80005774 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056d0:	00003517          	auipc	a0,0x3
    800056d4:	fe850513          	addi	a0,a0,-24 # 800086b8 <syscalls+0x2b0>
    800056d8:	ffffb097          	auipc	ra,0xffffb
    800056dc:	e6c080e7          	jalr	-404(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056e0:	04c92703          	lw	a4,76(s2)
    800056e4:	02000793          	li	a5,32
    800056e8:	f6e7f9e3          	bgeu	a5,a4,8000565a <sys_unlink+0xaa>
    800056ec:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056f0:	4741                	li	a4,16
    800056f2:	86ce                	mv	a3,s3
    800056f4:	f1840613          	addi	a2,s0,-232
    800056f8:	4581                	li	a1,0
    800056fa:	854a                	mv	a0,s2
    800056fc:	ffffe097          	auipc	ra,0xffffe
    80005700:	39c080e7          	jalr	924(ra) # 80003a98 <readi>
    80005704:	47c1                	li	a5,16
    80005706:	00f51b63          	bne	a0,a5,8000571c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000570a:	f1845783          	lhu	a5,-232(s0)
    8000570e:	e7a1                	bnez	a5,80005756 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005710:	29c1                	addiw	s3,s3,16
    80005712:	04c92783          	lw	a5,76(s2)
    80005716:	fcf9ede3          	bltu	s3,a5,800056f0 <sys_unlink+0x140>
    8000571a:	b781                	j	8000565a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000571c:	00003517          	auipc	a0,0x3
    80005720:	fb450513          	addi	a0,a0,-76 # 800086d0 <syscalls+0x2c8>
    80005724:	ffffb097          	auipc	ra,0xffffb
    80005728:	e20080e7          	jalr	-480(ra) # 80000544 <panic>
    panic("unlink: writei");
    8000572c:	00003517          	auipc	a0,0x3
    80005730:	fbc50513          	addi	a0,a0,-68 # 800086e8 <syscalls+0x2e0>
    80005734:	ffffb097          	auipc	ra,0xffffb
    80005738:	e10080e7          	jalr	-496(ra) # 80000544 <panic>
    dp->nlink--;
    8000573c:	04a4d783          	lhu	a5,74(s1)
    80005740:	37fd                	addiw	a5,a5,-1
    80005742:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005746:	8526                	mv	a0,s1
    80005748:	ffffe097          	auipc	ra,0xffffe
    8000574c:	fd2080e7          	jalr	-46(ra) # 8000371a <iupdate>
    80005750:	b781                	j	80005690 <sys_unlink+0xe0>
    return -1;
    80005752:	557d                	li	a0,-1
    80005754:	a005                	j	80005774 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005756:	854a                	mv	a0,s2
    80005758:	ffffe097          	auipc	ra,0xffffe
    8000575c:	2ee080e7          	jalr	750(ra) # 80003a46 <iunlockput>
  iunlockput(dp);
    80005760:	8526                	mv	a0,s1
    80005762:	ffffe097          	auipc	ra,0xffffe
    80005766:	2e4080e7          	jalr	740(ra) # 80003a46 <iunlockput>
  end_op();
    8000576a:	fffff097          	auipc	ra,0xfffff
    8000576e:	abc080e7          	jalr	-1348(ra) # 80004226 <end_op>
  return -1;
    80005772:	557d                	li	a0,-1
}
    80005774:	70ae                	ld	ra,232(sp)
    80005776:	740e                	ld	s0,224(sp)
    80005778:	64ee                	ld	s1,216(sp)
    8000577a:	694e                	ld	s2,208(sp)
    8000577c:	69ae                	ld	s3,200(sp)
    8000577e:	616d                	addi	sp,sp,240
    80005780:	8082                	ret

0000000080005782 <sys_open>:

uint64
sys_open(void)
{
    80005782:	7131                	addi	sp,sp,-192
    80005784:	fd06                	sd	ra,184(sp)
    80005786:	f922                	sd	s0,176(sp)
    80005788:	f526                	sd	s1,168(sp)
    8000578a:	f14a                	sd	s2,160(sp)
    8000578c:	ed4e                	sd	s3,152(sp)
    8000578e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005790:	f4c40593          	addi	a1,s0,-180
    80005794:	4505                	li	a0,1
    80005796:	ffffd097          	auipc	ra,0xffffd
    8000579a:	4cc080e7          	jalr	1228(ra) # 80002c62 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000579e:	08000613          	li	a2,128
    800057a2:	f5040593          	addi	a1,s0,-176
    800057a6:	4501                	li	a0,0
    800057a8:	ffffd097          	auipc	ra,0xffffd
    800057ac:	4fa080e7          	jalr	1274(ra) # 80002ca2 <argstr>
    800057b0:	87aa                	mv	a5,a0
    return -1;
    800057b2:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800057b4:	0a07c963          	bltz	a5,80005866 <sys_open+0xe4>

  begin_op();
    800057b8:	fffff097          	auipc	ra,0xfffff
    800057bc:	9ee080e7          	jalr	-1554(ra) # 800041a6 <begin_op>

  if(omode & O_CREATE){
    800057c0:	f4c42783          	lw	a5,-180(s0)
    800057c4:	2007f793          	andi	a5,a5,512
    800057c8:	cfc5                	beqz	a5,80005880 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057ca:	4681                	li	a3,0
    800057cc:	4601                	li	a2,0
    800057ce:	4589                	li	a1,2
    800057d0:	f5040513          	addi	a0,s0,-176
    800057d4:	00000097          	auipc	ra,0x0
    800057d8:	974080e7          	jalr	-1676(ra) # 80005148 <create>
    800057dc:	84aa                	mv	s1,a0
    if(ip == 0){
    800057de:	c959                	beqz	a0,80005874 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057e0:	04449703          	lh	a4,68(s1)
    800057e4:	478d                	li	a5,3
    800057e6:	00f71763          	bne	a4,a5,800057f4 <sys_open+0x72>
    800057ea:	0464d703          	lhu	a4,70(s1)
    800057ee:	47a5                	li	a5,9
    800057f0:	0ce7ed63          	bltu	a5,a4,800058ca <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057f4:	fffff097          	auipc	ra,0xfffff
    800057f8:	dc2080e7          	jalr	-574(ra) # 800045b6 <filealloc>
    800057fc:	89aa                	mv	s3,a0
    800057fe:	10050363          	beqz	a0,80005904 <sys_open+0x182>
    80005802:	00000097          	auipc	ra,0x0
    80005806:	904080e7          	jalr	-1788(ra) # 80005106 <fdalloc>
    8000580a:	892a                	mv	s2,a0
    8000580c:	0e054763          	bltz	a0,800058fa <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005810:	04449703          	lh	a4,68(s1)
    80005814:	478d                	li	a5,3
    80005816:	0cf70563          	beq	a4,a5,800058e0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000581a:	4789                	li	a5,2
    8000581c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005820:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005824:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005828:	f4c42783          	lw	a5,-180(s0)
    8000582c:	0017c713          	xori	a4,a5,1
    80005830:	8b05                	andi	a4,a4,1
    80005832:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005836:	0037f713          	andi	a4,a5,3
    8000583a:	00e03733          	snez	a4,a4
    8000583e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005842:	4007f793          	andi	a5,a5,1024
    80005846:	c791                	beqz	a5,80005852 <sys_open+0xd0>
    80005848:	04449703          	lh	a4,68(s1)
    8000584c:	4789                	li	a5,2
    8000584e:	0af70063          	beq	a4,a5,800058ee <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005852:	8526                	mv	a0,s1
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	052080e7          	jalr	82(ra) # 800038a6 <iunlock>
  end_op();
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	9ca080e7          	jalr	-1590(ra) # 80004226 <end_op>

  return fd;
    80005864:	854a                	mv	a0,s2
}
    80005866:	70ea                	ld	ra,184(sp)
    80005868:	744a                	ld	s0,176(sp)
    8000586a:	74aa                	ld	s1,168(sp)
    8000586c:	790a                	ld	s2,160(sp)
    8000586e:	69ea                	ld	s3,152(sp)
    80005870:	6129                	addi	sp,sp,192
    80005872:	8082                	ret
      end_op();
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	9b2080e7          	jalr	-1614(ra) # 80004226 <end_op>
      return -1;
    8000587c:	557d                	li	a0,-1
    8000587e:	b7e5                	j	80005866 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005880:	f5040513          	addi	a0,s0,-176
    80005884:	ffffe097          	auipc	ra,0xffffe
    80005888:	706080e7          	jalr	1798(ra) # 80003f8a <namei>
    8000588c:	84aa                	mv	s1,a0
    8000588e:	c905                	beqz	a0,800058be <sys_open+0x13c>
    ilock(ip);
    80005890:	ffffe097          	auipc	ra,0xffffe
    80005894:	f54080e7          	jalr	-172(ra) # 800037e4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005898:	04449703          	lh	a4,68(s1)
    8000589c:	4785                	li	a5,1
    8000589e:	f4f711e3          	bne	a4,a5,800057e0 <sys_open+0x5e>
    800058a2:	f4c42783          	lw	a5,-180(s0)
    800058a6:	d7b9                	beqz	a5,800057f4 <sys_open+0x72>
      iunlockput(ip);
    800058a8:	8526                	mv	a0,s1
    800058aa:	ffffe097          	auipc	ra,0xffffe
    800058ae:	19c080e7          	jalr	412(ra) # 80003a46 <iunlockput>
      end_op();
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	974080e7          	jalr	-1676(ra) # 80004226 <end_op>
      return -1;
    800058ba:	557d                	li	a0,-1
    800058bc:	b76d                	j	80005866 <sys_open+0xe4>
      end_op();
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	968080e7          	jalr	-1688(ra) # 80004226 <end_op>
      return -1;
    800058c6:	557d                	li	a0,-1
    800058c8:	bf79                	j	80005866 <sys_open+0xe4>
    iunlockput(ip);
    800058ca:	8526                	mv	a0,s1
    800058cc:	ffffe097          	auipc	ra,0xffffe
    800058d0:	17a080e7          	jalr	378(ra) # 80003a46 <iunlockput>
    end_op();
    800058d4:	fffff097          	auipc	ra,0xfffff
    800058d8:	952080e7          	jalr	-1710(ra) # 80004226 <end_op>
    return -1;
    800058dc:	557d                	li	a0,-1
    800058de:	b761                	j	80005866 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058e0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058e4:	04649783          	lh	a5,70(s1)
    800058e8:	02f99223          	sh	a5,36(s3)
    800058ec:	bf25                	j	80005824 <sys_open+0xa2>
    itrunc(ip);
    800058ee:	8526                	mv	a0,s1
    800058f0:	ffffe097          	auipc	ra,0xffffe
    800058f4:	002080e7          	jalr	2(ra) # 800038f2 <itrunc>
    800058f8:	bfa9                	j	80005852 <sys_open+0xd0>
      fileclose(f);
    800058fa:	854e                	mv	a0,s3
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	d76080e7          	jalr	-650(ra) # 80004672 <fileclose>
    iunlockput(ip);
    80005904:	8526                	mv	a0,s1
    80005906:	ffffe097          	auipc	ra,0xffffe
    8000590a:	140080e7          	jalr	320(ra) # 80003a46 <iunlockput>
    end_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	918080e7          	jalr	-1768(ra) # 80004226 <end_op>
    return -1;
    80005916:	557d                	li	a0,-1
    80005918:	b7b9                	j	80005866 <sys_open+0xe4>

000000008000591a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000591a:	7175                	addi	sp,sp,-144
    8000591c:	e506                	sd	ra,136(sp)
    8000591e:	e122                	sd	s0,128(sp)
    80005920:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	884080e7          	jalr	-1916(ra) # 800041a6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000592a:	08000613          	li	a2,128
    8000592e:	f7040593          	addi	a1,s0,-144
    80005932:	4501                	li	a0,0
    80005934:	ffffd097          	auipc	ra,0xffffd
    80005938:	36e080e7          	jalr	878(ra) # 80002ca2 <argstr>
    8000593c:	02054963          	bltz	a0,8000596e <sys_mkdir+0x54>
    80005940:	4681                	li	a3,0
    80005942:	4601                	li	a2,0
    80005944:	4585                	li	a1,1
    80005946:	f7040513          	addi	a0,s0,-144
    8000594a:	fffff097          	auipc	ra,0xfffff
    8000594e:	7fe080e7          	jalr	2046(ra) # 80005148 <create>
    80005952:	cd11                	beqz	a0,8000596e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	0f2080e7          	jalr	242(ra) # 80003a46 <iunlockput>
  end_op();
    8000595c:	fffff097          	auipc	ra,0xfffff
    80005960:	8ca080e7          	jalr	-1846(ra) # 80004226 <end_op>
  return 0;
    80005964:	4501                	li	a0,0
}
    80005966:	60aa                	ld	ra,136(sp)
    80005968:	640a                	ld	s0,128(sp)
    8000596a:	6149                	addi	sp,sp,144
    8000596c:	8082                	ret
    end_op();
    8000596e:	fffff097          	auipc	ra,0xfffff
    80005972:	8b8080e7          	jalr	-1864(ra) # 80004226 <end_op>
    return -1;
    80005976:	557d                	li	a0,-1
    80005978:	b7fd                	j	80005966 <sys_mkdir+0x4c>

000000008000597a <sys_mknod>:

uint64
sys_mknod(void)
{
    8000597a:	7135                	addi	sp,sp,-160
    8000597c:	ed06                	sd	ra,152(sp)
    8000597e:	e922                	sd	s0,144(sp)
    80005980:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005982:	fffff097          	auipc	ra,0xfffff
    80005986:	824080e7          	jalr	-2012(ra) # 800041a6 <begin_op>
  argint(1, &major);
    8000598a:	f6c40593          	addi	a1,s0,-148
    8000598e:	4505                	li	a0,1
    80005990:	ffffd097          	auipc	ra,0xffffd
    80005994:	2d2080e7          	jalr	722(ra) # 80002c62 <argint>
  argint(2, &minor);
    80005998:	f6840593          	addi	a1,s0,-152
    8000599c:	4509                	li	a0,2
    8000599e:	ffffd097          	auipc	ra,0xffffd
    800059a2:	2c4080e7          	jalr	708(ra) # 80002c62 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059a6:	08000613          	li	a2,128
    800059aa:	f7040593          	addi	a1,s0,-144
    800059ae:	4501                	li	a0,0
    800059b0:	ffffd097          	auipc	ra,0xffffd
    800059b4:	2f2080e7          	jalr	754(ra) # 80002ca2 <argstr>
    800059b8:	02054b63          	bltz	a0,800059ee <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059bc:	f6841683          	lh	a3,-152(s0)
    800059c0:	f6c41603          	lh	a2,-148(s0)
    800059c4:	458d                	li	a1,3
    800059c6:	f7040513          	addi	a0,s0,-144
    800059ca:	fffff097          	auipc	ra,0xfffff
    800059ce:	77e080e7          	jalr	1918(ra) # 80005148 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059d2:	cd11                	beqz	a0,800059ee <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059d4:	ffffe097          	auipc	ra,0xffffe
    800059d8:	072080e7          	jalr	114(ra) # 80003a46 <iunlockput>
  end_op();
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	84a080e7          	jalr	-1974(ra) # 80004226 <end_op>
  return 0;
    800059e4:	4501                	li	a0,0
}
    800059e6:	60ea                	ld	ra,152(sp)
    800059e8:	644a                	ld	s0,144(sp)
    800059ea:	610d                	addi	sp,sp,160
    800059ec:	8082                	ret
    end_op();
    800059ee:	fffff097          	auipc	ra,0xfffff
    800059f2:	838080e7          	jalr	-1992(ra) # 80004226 <end_op>
    return -1;
    800059f6:	557d                	li	a0,-1
    800059f8:	b7fd                	j	800059e6 <sys_mknod+0x6c>

00000000800059fa <sys_chdir>:

uint64
sys_chdir(void)
{
    800059fa:	7135                	addi	sp,sp,-160
    800059fc:	ed06                	sd	ra,152(sp)
    800059fe:	e922                	sd	s0,144(sp)
    80005a00:	e526                	sd	s1,136(sp)
    80005a02:	e14a                	sd	s2,128(sp)
    80005a04:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a06:	ffffc097          	auipc	ra,0xffffc
    80005a0a:	0d4080e7          	jalr	212(ra) # 80001ada <myproc>
    80005a0e:	892a                	mv	s2,a0
  
  begin_op();
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	796080e7          	jalr	1942(ra) # 800041a6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a18:	08000613          	li	a2,128
    80005a1c:	f6040593          	addi	a1,s0,-160
    80005a20:	4501                	li	a0,0
    80005a22:	ffffd097          	auipc	ra,0xffffd
    80005a26:	280080e7          	jalr	640(ra) # 80002ca2 <argstr>
    80005a2a:	04054b63          	bltz	a0,80005a80 <sys_chdir+0x86>
    80005a2e:	f6040513          	addi	a0,s0,-160
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	558080e7          	jalr	1368(ra) # 80003f8a <namei>
    80005a3a:	84aa                	mv	s1,a0
    80005a3c:	c131                	beqz	a0,80005a80 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	da6080e7          	jalr	-602(ra) # 800037e4 <ilock>
  if(ip->type != T_DIR){
    80005a46:	04449703          	lh	a4,68(s1)
    80005a4a:	4785                	li	a5,1
    80005a4c:	04f71063          	bne	a4,a5,80005a8c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a50:	8526                	mv	a0,s1
    80005a52:	ffffe097          	auipc	ra,0xffffe
    80005a56:	e54080e7          	jalr	-428(ra) # 800038a6 <iunlock>
  iput(p->cwd);
    80005a5a:	15093503          	ld	a0,336(s2)
    80005a5e:	ffffe097          	auipc	ra,0xffffe
    80005a62:	f40080e7          	jalr	-192(ra) # 8000399e <iput>
  end_op();
    80005a66:	ffffe097          	auipc	ra,0xffffe
    80005a6a:	7c0080e7          	jalr	1984(ra) # 80004226 <end_op>
  p->cwd = ip;
    80005a6e:	14993823          	sd	s1,336(s2)
  return 0;
    80005a72:	4501                	li	a0,0
}
    80005a74:	60ea                	ld	ra,152(sp)
    80005a76:	644a                	ld	s0,144(sp)
    80005a78:	64aa                	ld	s1,136(sp)
    80005a7a:	690a                	ld	s2,128(sp)
    80005a7c:	610d                	addi	sp,sp,160
    80005a7e:	8082                	ret
    end_op();
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	7a6080e7          	jalr	1958(ra) # 80004226 <end_op>
    return -1;
    80005a88:	557d                	li	a0,-1
    80005a8a:	b7ed                	j	80005a74 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a8c:	8526                	mv	a0,s1
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	fb8080e7          	jalr	-72(ra) # 80003a46 <iunlockput>
    end_op();
    80005a96:	ffffe097          	auipc	ra,0xffffe
    80005a9a:	790080e7          	jalr	1936(ra) # 80004226 <end_op>
    return -1;
    80005a9e:	557d                	li	a0,-1
    80005aa0:	bfd1                	j	80005a74 <sys_chdir+0x7a>

0000000080005aa2 <sys_exec>:

uint64
sys_exec(void)
{
    80005aa2:	7145                	addi	sp,sp,-464
    80005aa4:	e786                	sd	ra,456(sp)
    80005aa6:	e3a2                	sd	s0,448(sp)
    80005aa8:	ff26                	sd	s1,440(sp)
    80005aaa:	fb4a                	sd	s2,432(sp)
    80005aac:	f74e                	sd	s3,424(sp)
    80005aae:	f352                	sd	s4,416(sp)
    80005ab0:	ef56                	sd	s5,408(sp)
    80005ab2:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005ab4:	e3840593          	addi	a1,s0,-456
    80005ab8:	4505                	li	a0,1
    80005aba:	ffffd097          	auipc	ra,0xffffd
    80005abe:	1c8080e7          	jalr	456(ra) # 80002c82 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005ac2:	08000613          	li	a2,128
    80005ac6:	f4040593          	addi	a1,s0,-192
    80005aca:	4501                	li	a0,0
    80005acc:	ffffd097          	auipc	ra,0xffffd
    80005ad0:	1d6080e7          	jalr	470(ra) # 80002ca2 <argstr>
    80005ad4:	87aa                	mv	a5,a0
    return -1;
    80005ad6:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005ad8:	0c07c263          	bltz	a5,80005b9c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005adc:	10000613          	li	a2,256
    80005ae0:	4581                	li	a1,0
    80005ae2:	e4040513          	addi	a0,s0,-448
    80005ae6:	ffffb097          	auipc	ra,0xffffb
    80005aea:	200080e7          	jalr	512(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005aee:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005af2:	89a6                	mv	s3,s1
    80005af4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005af6:	02000a13          	li	s4,32
    80005afa:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005afe:	00391513          	slli	a0,s2,0x3
    80005b02:	e3040593          	addi	a1,s0,-464
    80005b06:	e3843783          	ld	a5,-456(s0)
    80005b0a:	953e                	add	a0,a0,a5
    80005b0c:	ffffd097          	auipc	ra,0xffffd
    80005b10:	0b8080e7          	jalr	184(ra) # 80002bc4 <fetchaddr>
    80005b14:	02054a63          	bltz	a0,80005b48 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005b18:	e3043783          	ld	a5,-464(s0)
    80005b1c:	c3b9                	beqz	a5,80005b62 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b1e:	ffffb097          	auipc	ra,0xffffb
    80005b22:	fdc080e7          	jalr	-36(ra) # 80000afa <kalloc>
    80005b26:	85aa                	mv	a1,a0
    80005b28:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b2c:	cd11                	beqz	a0,80005b48 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b2e:	6605                	lui	a2,0x1
    80005b30:	e3043503          	ld	a0,-464(s0)
    80005b34:	ffffd097          	auipc	ra,0xffffd
    80005b38:	0e2080e7          	jalr	226(ra) # 80002c16 <fetchstr>
    80005b3c:	00054663          	bltz	a0,80005b48 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005b40:	0905                	addi	s2,s2,1
    80005b42:	09a1                	addi	s3,s3,8
    80005b44:	fb491be3          	bne	s2,s4,80005afa <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b48:	10048913          	addi	s2,s1,256
    80005b4c:	6088                	ld	a0,0(s1)
    80005b4e:	c531                	beqz	a0,80005b9a <sys_exec+0xf8>
    kfree(argv[i]);
    80005b50:	ffffb097          	auipc	ra,0xffffb
    80005b54:	eae080e7          	jalr	-338(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b58:	04a1                	addi	s1,s1,8
    80005b5a:	ff2499e3          	bne	s1,s2,80005b4c <sys_exec+0xaa>
  return -1;
    80005b5e:	557d                	li	a0,-1
    80005b60:	a835                	j	80005b9c <sys_exec+0xfa>
      argv[i] = 0;
    80005b62:	0a8e                	slli	s5,s5,0x3
    80005b64:	fc040793          	addi	a5,s0,-64
    80005b68:	9abe                	add	s5,s5,a5
    80005b6a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b6e:	e4040593          	addi	a1,s0,-448
    80005b72:	f4040513          	addi	a0,s0,-192
    80005b76:	fffff097          	auipc	ra,0xfffff
    80005b7a:	184080e7          	jalr	388(ra) # 80004cfa <exec>
    80005b7e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b80:	10048993          	addi	s3,s1,256
    80005b84:	6088                	ld	a0,0(s1)
    80005b86:	c901                	beqz	a0,80005b96 <sys_exec+0xf4>
    kfree(argv[i]);
    80005b88:	ffffb097          	auipc	ra,0xffffb
    80005b8c:	e76080e7          	jalr	-394(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b90:	04a1                	addi	s1,s1,8
    80005b92:	ff3499e3          	bne	s1,s3,80005b84 <sys_exec+0xe2>
  return ret;
    80005b96:	854a                	mv	a0,s2
    80005b98:	a011                	j	80005b9c <sys_exec+0xfa>
  return -1;
    80005b9a:	557d                	li	a0,-1
}
    80005b9c:	60be                	ld	ra,456(sp)
    80005b9e:	641e                	ld	s0,448(sp)
    80005ba0:	74fa                	ld	s1,440(sp)
    80005ba2:	795a                	ld	s2,432(sp)
    80005ba4:	79ba                	ld	s3,424(sp)
    80005ba6:	7a1a                	ld	s4,416(sp)
    80005ba8:	6afa                	ld	s5,408(sp)
    80005baa:	6179                	addi	sp,sp,464
    80005bac:	8082                	ret

0000000080005bae <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bae:	7139                	addi	sp,sp,-64
    80005bb0:	fc06                	sd	ra,56(sp)
    80005bb2:	f822                	sd	s0,48(sp)
    80005bb4:	f426                	sd	s1,40(sp)
    80005bb6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bb8:	ffffc097          	auipc	ra,0xffffc
    80005bbc:	f22080e7          	jalr	-222(ra) # 80001ada <myproc>
    80005bc0:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005bc2:	fd840593          	addi	a1,s0,-40
    80005bc6:	4501                	li	a0,0
    80005bc8:	ffffd097          	auipc	ra,0xffffd
    80005bcc:	0ba080e7          	jalr	186(ra) # 80002c82 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005bd0:	fc840593          	addi	a1,s0,-56
    80005bd4:	fd040513          	addi	a0,s0,-48
    80005bd8:	fffff097          	auipc	ra,0xfffff
    80005bdc:	dca080e7          	jalr	-566(ra) # 800049a2 <pipealloc>
    return -1;
    80005be0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005be2:	0c054463          	bltz	a0,80005caa <sys_pipe+0xfc>
  fd0 = -1;
    80005be6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bea:	fd043503          	ld	a0,-48(s0)
    80005bee:	fffff097          	auipc	ra,0xfffff
    80005bf2:	518080e7          	jalr	1304(ra) # 80005106 <fdalloc>
    80005bf6:	fca42223          	sw	a0,-60(s0)
    80005bfa:	08054b63          	bltz	a0,80005c90 <sys_pipe+0xe2>
    80005bfe:	fc843503          	ld	a0,-56(s0)
    80005c02:	fffff097          	auipc	ra,0xfffff
    80005c06:	504080e7          	jalr	1284(ra) # 80005106 <fdalloc>
    80005c0a:	fca42023          	sw	a0,-64(s0)
    80005c0e:	06054863          	bltz	a0,80005c7e <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c12:	4691                	li	a3,4
    80005c14:	fc440613          	addi	a2,s0,-60
    80005c18:	fd843583          	ld	a1,-40(s0)
    80005c1c:	68a8                	ld	a0,80(s1)
    80005c1e:	ffffc097          	auipc	ra,0xffffc
    80005c22:	a8e080e7          	jalr	-1394(ra) # 800016ac <copyout>
    80005c26:	02054063          	bltz	a0,80005c46 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c2a:	4691                	li	a3,4
    80005c2c:	fc040613          	addi	a2,s0,-64
    80005c30:	fd843583          	ld	a1,-40(s0)
    80005c34:	0591                	addi	a1,a1,4
    80005c36:	68a8                	ld	a0,80(s1)
    80005c38:	ffffc097          	auipc	ra,0xffffc
    80005c3c:	a74080e7          	jalr	-1420(ra) # 800016ac <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c40:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c42:	06055463          	bgez	a0,80005caa <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c46:	fc442783          	lw	a5,-60(s0)
    80005c4a:	07e9                	addi	a5,a5,26
    80005c4c:	078e                	slli	a5,a5,0x3
    80005c4e:	97a6                	add	a5,a5,s1
    80005c50:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c54:	fc042503          	lw	a0,-64(s0)
    80005c58:	0569                	addi	a0,a0,26
    80005c5a:	050e                	slli	a0,a0,0x3
    80005c5c:	94aa                	add	s1,s1,a0
    80005c5e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c62:	fd043503          	ld	a0,-48(s0)
    80005c66:	fffff097          	auipc	ra,0xfffff
    80005c6a:	a0c080e7          	jalr	-1524(ra) # 80004672 <fileclose>
    fileclose(wf);
    80005c6e:	fc843503          	ld	a0,-56(s0)
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	a00080e7          	jalr	-1536(ra) # 80004672 <fileclose>
    return -1;
    80005c7a:	57fd                	li	a5,-1
    80005c7c:	a03d                	j	80005caa <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c7e:	fc442783          	lw	a5,-60(s0)
    80005c82:	0007c763          	bltz	a5,80005c90 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c86:	07e9                	addi	a5,a5,26
    80005c88:	078e                	slli	a5,a5,0x3
    80005c8a:	94be                	add	s1,s1,a5
    80005c8c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c90:	fd043503          	ld	a0,-48(s0)
    80005c94:	fffff097          	auipc	ra,0xfffff
    80005c98:	9de080e7          	jalr	-1570(ra) # 80004672 <fileclose>
    fileclose(wf);
    80005c9c:	fc843503          	ld	a0,-56(s0)
    80005ca0:	fffff097          	auipc	ra,0xfffff
    80005ca4:	9d2080e7          	jalr	-1582(ra) # 80004672 <fileclose>
    return -1;
    80005ca8:	57fd                	li	a5,-1
}
    80005caa:	853e                	mv	a0,a5
    80005cac:	70e2                	ld	ra,56(sp)
    80005cae:	7442                	ld	s0,48(sp)
    80005cb0:	74a2                	ld	s1,40(sp)
    80005cb2:	6121                	addi	sp,sp,64
    80005cb4:	8082                	ret
	...

0000000080005cc0 <kernelvec>:
    80005cc0:	7111                	addi	sp,sp,-256
    80005cc2:	e006                	sd	ra,0(sp)
    80005cc4:	e40a                	sd	sp,8(sp)
    80005cc6:	e80e                	sd	gp,16(sp)
    80005cc8:	ec12                	sd	tp,24(sp)
    80005cca:	f016                	sd	t0,32(sp)
    80005ccc:	f41a                	sd	t1,40(sp)
    80005cce:	f81e                	sd	t2,48(sp)
    80005cd0:	fc22                	sd	s0,56(sp)
    80005cd2:	e0a6                	sd	s1,64(sp)
    80005cd4:	e4aa                	sd	a0,72(sp)
    80005cd6:	e8ae                	sd	a1,80(sp)
    80005cd8:	ecb2                	sd	a2,88(sp)
    80005cda:	f0b6                	sd	a3,96(sp)
    80005cdc:	f4ba                	sd	a4,104(sp)
    80005cde:	f8be                	sd	a5,112(sp)
    80005ce0:	fcc2                	sd	a6,120(sp)
    80005ce2:	e146                	sd	a7,128(sp)
    80005ce4:	e54a                	sd	s2,136(sp)
    80005ce6:	e94e                	sd	s3,144(sp)
    80005ce8:	ed52                	sd	s4,152(sp)
    80005cea:	f156                	sd	s5,160(sp)
    80005cec:	f55a                	sd	s6,168(sp)
    80005cee:	f95e                	sd	s7,176(sp)
    80005cf0:	fd62                	sd	s8,184(sp)
    80005cf2:	e1e6                	sd	s9,192(sp)
    80005cf4:	e5ea                	sd	s10,200(sp)
    80005cf6:	e9ee                	sd	s11,208(sp)
    80005cf8:	edf2                	sd	t3,216(sp)
    80005cfa:	f1f6                	sd	t4,224(sp)
    80005cfc:	f5fa                	sd	t5,232(sp)
    80005cfe:	f9fe                	sd	t6,240(sp)
    80005d00:	d91fc0ef          	jal	ra,80002a90 <kerneltrap>
    80005d04:	6082                	ld	ra,0(sp)
    80005d06:	6122                	ld	sp,8(sp)
    80005d08:	61c2                	ld	gp,16(sp)
    80005d0a:	7282                	ld	t0,32(sp)
    80005d0c:	7322                	ld	t1,40(sp)
    80005d0e:	73c2                	ld	t2,48(sp)
    80005d10:	7462                	ld	s0,56(sp)
    80005d12:	6486                	ld	s1,64(sp)
    80005d14:	6526                	ld	a0,72(sp)
    80005d16:	65c6                	ld	a1,80(sp)
    80005d18:	6666                	ld	a2,88(sp)
    80005d1a:	7686                	ld	a3,96(sp)
    80005d1c:	7726                	ld	a4,104(sp)
    80005d1e:	77c6                	ld	a5,112(sp)
    80005d20:	7866                	ld	a6,120(sp)
    80005d22:	688a                	ld	a7,128(sp)
    80005d24:	692a                	ld	s2,136(sp)
    80005d26:	69ca                	ld	s3,144(sp)
    80005d28:	6a6a                	ld	s4,152(sp)
    80005d2a:	7a8a                	ld	s5,160(sp)
    80005d2c:	7b2a                	ld	s6,168(sp)
    80005d2e:	7bca                	ld	s7,176(sp)
    80005d30:	7c6a                	ld	s8,184(sp)
    80005d32:	6c8e                	ld	s9,192(sp)
    80005d34:	6d2e                	ld	s10,200(sp)
    80005d36:	6dce                	ld	s11,208(sp)
    80005d38:	6e6e                	ld	t3,216(sp)
    80005d3a:	7e8e                	ld	t4,224(sp)
    80005d3c:	7f2e                	ld	t5,232(sp)
    80005d3e:	7fce                	ld	t6,240(sp)
    80005d40:	6111                	addi	sp,sp,256
    80005d42:	10200073          	sret
    80005d46:	00000013          	nop
    80005d4a:	00000013          	nop
    80005d4e:	0001                	nop

0000000080005d50 <timervec>:
    80005d50:	34051573          	csrrw	a0,mscratch,a0
    80005d54:	e10c                	sd	a1,0(a0)
    80005d56:	e510                	sd	a2,8(a0)
    80005d58:	e914                	sd	a3,16(a0)
    80005d5a:	6d0c                	ld	a1,24(a0)
    80005d5c:	7110                	ld	a2,32(a0)
    80005d5e:	6194                	ld	a3,0(a1)
    80005d60:	96b2                	add	a3,a3,a2
    80005d62:	e194                	sd	a3,0(a1)
    80005d64:	4589                	li	a1,2
    80005d66:	14459073          	csrw	sip,a1
    80005d6a:	6914                	ld	a3,16(a0)
    80005d6c:	6510                	ld	a2,8(a0)
    80005d6e:	610c                	ld	a1,0(a0)
    80005d70:	34051573          	csrrw	a0,mscratch,a0
    80005d74:	30200073          	mret
	...

0000000080005d7a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d7a:	1141                	addi	sp,sp,-16
    80005d7c:	e422                	sd	s0,8(sp)
    80005d7e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d80:	0c0007b7          	lui	a5,0xc000
    80005d84:	4705                	li	a4,1
    80005d86:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d88:	c3d8                	sw	a4,4(a5)
}
    80005d8a:	6422                	ld	s0,8(sp)
    80005d8c:	0141                	addi	sp,sp,16
    80005d8e:	8082                	ret

0000000080005d90 <plicinithart>:

void
plicinithart(void)
{
    80005d90:	1141                	addi	sp,sp,-16
    80005d92:	e406                	sd	ra,8(sp)
    80005d94:	e022                	sd	s0,0(sp)
    80005d96:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d98:	ffffc097          	auipc	ra,0xffffc
    80005d9c:	d16080e7          	jalr	-746(ra) # 80001aae <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005da0:	0085171b          	slliw	a4,a0,0x8
    80005da4:	0c0027b7          	lui	a5,0xc002
    80005da8:	97ba                	add	a5,a5,a4
    80005daa:	40200713          	li	a4,1026
    80005dae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005db2:	00d5151b          	slliw	a0,a0,0xd
    80005db6:	0c2017b7          	lui	a5,0xc201
    80005dba:	953e                	add	a0,a0,a5
    80005dbc:	00052023          	sw	zero,0(a0)
}
    80005dc0:	60a2                	ld	ra,8(sp)
    80005dc2:	6402                	ld	s0,0(sp)
    80005dc4:	0141                	addi	sp,sp,16
    80005dc6:	8082                	ret

0000000080005dc8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005dc8:	1141                	addi	sp,sp,-16
    80005dca:	e406                	sd	ra,8(sp)
    80005dcc:	e022                	sd	s0,0(sp)
    80005dce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005dd0:	ffffc097          	auipc	ra,0xffffc
    80005dd4:	cde080e7          	jalr	-802(ra) # 80001aae <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005dd8:	00d5179b          	slliw	a5,a0,0xd
    80005ddc:	0c201537          	lui	a0,0xc201
    80005de0:	953e                	add	a0,a0,a5
  return irq;
}
    80005de2:	4148                	lw	a0,4(a0)
    80005de4:	60a2                	ld	ra,8(sp)
    80005de6:	6402                	ld	s0,0(sp)
    80005de8:	0141                	addi	sp,sp,16
    80005dea:	8082                	ret

0000000080005dec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dec:	1101                	addi	sp,sp,-32
    80005dee:	ec06                	sd	ra,24(sp)
    80005df0:	e822                	sd	s0,16(sp)
    80005df2:	e426                	sd	s1,8(sp)
    80005df4:	1000                	addi	s0,sp,32
    80005df6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005df8:	ffffc097          	auipc	ra,0xffffc
    80005dfc:	cb6080e7          	jalr	-842(ra) # 80001aae <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e00:	00d5151b          	slliw	a0,a0,0xd
    80005e04:	0c2017b7          	lui	a5,0xc201
    80005e08:	97aa                	add	a5,a5,a0
    80005e0a:	c3c4                	sw	s1,4(a5)
}
    80005e0c:	60e2                	ld	ra,24(sp)
    80005e0e:	6442                	ld	s0,16(sp)
    80005e10:	64a2                	ld	s1,8(sp)
    80005e12:	6105                	addi	sp,sp,32
    80005e14:	8082                	ret

0000000080005e16 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e16:	1141                	addi	sp,sp,-16
    80005e18:	e406                	sd	ra,8(sp)
    80005e1a:	e022                	sd	s0,0(sp)
    80005e1c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e1e:	479d                	li	a5,7
    80005e20:	04a7cc63          	blt	a5,a0,80005e78 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005e24:	0001c797          	auipc	a5,0x1c
    80005e28:	d9c78793          	addi	a5,a5,-612 # 80021bc0 <disk>
    80005e2c:	97aa                	add	a5,a5,a0
    80005e2e:	0187c783          	lbu	a5,24(a5)
    80005e32:	ebb9                	bnez	a5,80005e88 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e34:	00451613          	slli	a2,a0,0x4
    80005e38:	0001c797          	auipc	a5,0x1c
    80005e3c:	d8878793          	addi	a5,a5,-632 # 80021bc0 <disk>
    80005e40:	6394                	ld	a3,0(a5)
    80005e42:	96b2                	add	a3,a3,a2
    80005e44:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e48:	6398                	ld	a4,0(a5)
    80005e4a:	9732                	add	a4,a4,a2
    80005e4c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005e50:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005e54:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005e58:	953e                	add	a0,a0,a5
    80005e5a:	4785                	li	a5,1
    80005e5c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005e60:	0001c517          	auipc	a0,0x1c
    80005e64:	d7850513          	addi	a0,a0,-648 # 80021bd8 <disk+0x18>
    80005e68:	ffffc097          	auipc	ra,0xffffc
    80005e6c:	37a080e7          	jalr	890(ra) # 800021e2 <wakeup>
}
    80005e70:	60a2                	ld	ra,8(sp)
    80005e72:	6402                	ld	s0,0(sp)
    80005e74:	0141                	addi	sp,sp,16
    80005e76:	8082                	ret
    panic("free_desc 1");
    80005e78:	00003517          	auipc	a0,0x3
    80005e7c:	88050513          	addi	a0,a0,-1920 # 800086f8 <syscalls+0x2f0>
    80005e80:	ffffa097          	auipc	ra,0xffffa
    80005e84:	6c4080e7          	jalr	1732(ra) # 80000544 <panic>
    panic("free_desc 2");
    80005e88:	00003517          	auipc	a0,0x3
    80005e8c:	88050513          	addi	a0,a0,-1920 # 80008708 <syscalls+0x300>
    80005e90:	ffffa097          	auipc	ra,0xffffa
    80005e94:	6b4080e7          	jalr	1716(ra) # 80000544 <panic>

0000000080005e98 <virtio_disk_init>:
{
    80005e98:	1101                	addi	sp,sp,-32
    80005e9a:	ec06                	sd	ra,24(sp)
    80005e9c:	e822                	sd	s0,16(sp)
    80005e9e:	e426                	sd	s1,8(sp)
    80005ea0:	e04a                	sd	s2,0(sp)
    80005ea2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ea4:	00003597          	auipc	a1,0x3
    80005ea8:	87458593          	addi	a1,a1,-1932 # 80008718 <syscalls+0x310>
    80005eac:	0001c517          	auipc	a0,0x1c
    80005eb0:	e3c50513          	addi	a0,a0,-452 # 80021ce8 <disk+0x128>
    80005eb4:	ffffb097          	auipc	ra,0xffffb
    80005eb8:	ca6080e7          	jalr	-858(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ebc:	100017b7          	lui	a5,0x10001
    80005ec0:	4398                	lw	a4,0(a5)
    80005ec2:	2701                	sext.w	a4,a4
    80005ec4:	747277b7          	lui	a5,0x74727
    80005ec8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005ecc:	14f71e63          	bne	a4,a5,80006028 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005ed0:	100017b7          	lui	a5,0x10001
    80005ed4:	43dc                	lw	a5,4(a5)
    80005ed6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ed8:	4709                	li	a4,2
    80005eda:	14e79763          	bne	a5,a4,80006028 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ede:	100017b7          	lui	a5,0x10001
    80005ee2:	479c                	lw	a5,8(a5)
    80005ee4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005ee6:	14e79163          	bne	a5,a4,80006028 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eea:	100017b7          	lui	a5,0x10001
    80005eee:	47d8                	lw	a4,12(a5)
    80005ef0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ef2:	554d47b7          	lui	a5,0x554d4
    80005ef6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005efa:	12f71763          	bne	a4,a5,80006028 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005efe:	100017b7          	lui	a5,0x10001
    80005f02:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f06:	4705                	li	a4,1
    80005f08:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f0a:	470d                	li	a4,3
    80005f0c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f0e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f10:	c7ffe737          	lui	a4,0xc7ffe
    80005f14:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdca5f>
    80005f18:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f1a:	2701                	sext.w	a4,a4
    80005f1c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f1e:	472d                	li	a4,11
    80005f20:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005f22:	0707a903          	lw	s2,112(a5)
    80005f26:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005f28:	00897793          	andi	a5,s2,8
    80005f2c:	10078663          	beqz	a5,80006038 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f30:	100017b7          	lui	a5,0x10001
    80005f34:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005f38:	43fc                	lw	a5,68(a5)
    80005f3a:	2781                	sext.w	a5,a5
    80005f3c:	10079663          	bnez	a5,80006048 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f40:	100017b7          	lui	a5,0x10001
    80005f44:	5bdc                	lw	a5,52(a5)
    80005f46:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f48:	10078863          	beqz	a5,80006058 <virtio_disk_init+0x1c0>
  if(max < NUM)
    80005f4c:	471d                	li	a4,7
    80005f4e:	10f77d63          	bgeu	a4,a5,80006068 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80005f52:	ffffb097          	auipc	ra,0xffffb
    80005f56:	ba8080e7          	jalr	-1112(ra) # 80000afa <kalloc>
    80005f5a:	0001c497          	auipc	s1,0x1c
    80005f5e:	c6648493          	addi	s1,s1,-922 # 80021bc0 <disk>
    80005f62:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005f64:	ffffb097          	auipc	ra,0xffffb
    80005f68:	b96080e7          	jalr	-1130(ra) # 80000afa <kalloc>
    80005f6c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005f6e:	ffffb097          	auipc	ra,0xffffb
    80005f72:	b8c080e7          	jalr	-1140(ra) # 80000afa <kalloc>
    80005f76:	87aa                	mv	a5,a0
    80005f78:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005f7a:	6088                	ld	a0,0(s1)
    80005f7c:	cd75                	beqz	a0,80006078 <virtio_disk_init+0x1e0>
    80005f7e:	0001c717          	auipc	a4,0x1c
    80005f82:	c4a73703          	ld	a4,-950(a4) # 80021bc8 <disk+0x8>
    80005f86:	cb6d                	beqz	a4,80006078 <virtio_disk_init+0x1e0>
    80005f88:	cbe5                	beqz	a5,80006078 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    80005f8a:	6605                	lui	a2,0x1
    80005f8c:	4581                	li	a1,0
    80005f8e:	ffffb097          	auipc	ra,0xffffb
    80005f92:	d58080e7          	jalr	-680(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f96:	0001c497          	auipc	s1,0x1c
    80005f9a:	c2a48493          	addi	s1,s1,-982 # 80021bc0 <disk>
    80005f9e:	6605                	lui	a2,0x1
    80005fa0:	4581                	li	a1,0
    80005fa2:	6488                	ld	a0,8(s1)
    80005fa4:	ffffb097          	auipc	ra,0xffffb
    80005fa8:	d42080e7          	jalr	-702(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    80005fac:	6605                	lui	a2,0x1
    80005fae:	4581                	li	a1,0
    80005fb0:	6888                	ld	a0,16(s1)
    80005fb2:	ffffb097          	auipc	ra,0xffffb
    80005fb6:	d34080e7          	jalr	-716(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005fba:	100017b7          	lui	a5,0x10001
    80005fbe:	4721                	li	a4,8
    80005fc0:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005fc2:	4098                	lw	a4,0(s1)
    80005fc4:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005fc8:	40d8                	lw	a4,4(s1)
    80005fca:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005fce:	6498                	ld	a4,8(s1)
    80005fd0:	0007069b          	sext.w	a3,a4
    80005fd4:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005fd8:	9701                	srai	a4,a4,0x20
    80005fda:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005fde:	6898                	ld	a4,16(s1)
    80005fe0:	0007069b          	sext.w	a3,a4
    80005fe4:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005fe8:	9701                	srai	a4,a4,0x20
    80005fea:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005fee:	4685                	li	a3,1
    80005ff0:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80005ff2:	4705                	li	a4,1
    80005ff4:	00d48c23          	sb	a3,24(s1)
    80005ff8:	00e48ca3          	sb	a4,25(s1)
    80005ffc:	00e48d23          	sb	a4,26(s1)
    80006000:	00e48da3          	sb	a4,27(s1)
    80006004:	00e48e23          	sb	a4,28(s1)
    80006008:	00e48ea3          	sb	a4,29(s1)
    8000600c:	00e48f23          	sb	a4,30(s1)
    80006010:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006014:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006018:	0727a823          	sw	s2,112(a5)
}
    8000601c:	60e2                	ld	ra,24(sp)
    8000601e:	6442                	ld	s0,16(sp)
    80006020:	64a2                	ld	s1,8(sp)
    80006022:	6902                	ld	s2,0(sp)
    80006024:	6105                	addi	sp,sp,32
    80006026:	8082                	ret
    panic("could not find virtio disk");
    80006028:	00002517          	auipc	a0,0x2
    8000602c:	70050513          	addi	a0,a0,1792 # 80008728 <syscalls+0x320>
    80006030:	ffffa097          	auipc	ra,0xffffa
    80006034:	514080e7          	jalr	1300(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006038:	00002517          	auipc	a0,0x2
    8000603c:	71050513          	addi	a0,a0,1808 # 80008748 <syscalls+0x340>
    80006040:	ffffa097          	auipc	ra,0xffffa
    80006044:	504080e7          	jalr	1284(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006048:	00002517          	auipc	a0,0x2
    8000604c:	72050513          	addi	a0,a0,1824 # 80008768 <syscalls+0x360>
    80006050:	ffffa097          	auipc	ra,0xffffa
    80006054:	4f4080e7          	jalr	1268(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006058:	00002517          	auipc	a0,0x2
    8000605c:	73050513          	addi	a0,a0,1840 # 80008788 <syscalls+0x380>
    80006060:	ffffa097          	auipc	ra,0xffffa
    80006064:	4e4080e7          	jalr	1252(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006068:	00002517          	auipc	a0,0x2
    8000606c:	74050513          	addi	a0,a0,1856 # 800087a8 <syscalls+0x3a0>
    80006070:	ffffa097          	auipc	ra,0xffffa
    80006074:	4d4080e7          	jalr	1236(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006078:	00002517          	auipc	a0,0x2
    8000607c:	75050513          	addi	a0,a0,1872 # 800087c8 <syscalls+0x3c0>
    80006080:	ffffa097          	auipc	ra,0xffffa
    80006084:	4c4080e7          	jalr	1220(ra) # 80000544 <panic>

0000000080006088 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006088:	7159                	addi	sp,sp,-112
    8000608a:	f486                	sd	ra,104(sp)
    8000608c:	f0a2                	sd	s0,96(sp)
    8000608e:	eca6                	sd	s1,88(sp)
    80006090:	e8ca                	sd	s2,80(sp)
    80006092:	e4ce                	sd	s3,72(sp)
    80006094:	e0d2                	sd	s4,64(sp)
    80006096:	fc56                	sd	s5,56(sp)
    80006098:	f85a                	sd	s6,48(sp)
    8000609a:	f45e                	sd	s7,40(sp)
    8000609c:	f062                	sd	s8,32(sp)
    8000609e:	ec66                	sd	s9,24(sp)
    800060a0:	e86a                	sd	s10,16(sp)
    800060a2:	1880                	addi	s0,sp,112
    800060a4:	892a                	mv	s2,a0
    800060a6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060a8:	00c52c83          	lw	s9,12(a0)
    800060ac:	001c9c9b          	slliw	s9,s9,0x1
    800060b0:	1c82                	slli	s9,s9,0x20
    800060b2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060b6:	0001c517          	auipc	a0,0x1c
    800060ba:	c3250513          	addi	a0,a0,-974 # 80021ce8 <disk+0x128>
    800060be:	ffffb097          	auipc	ra,0xffffb
    800060c2:	b2c080e7          	jalr	-1236(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    800060c6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060c8:	4ba1                	li	s7,8
      disk.free[i] = 0;
    800060ca:	0001cb17          	auipc	s6,0x1c
    800060ce:	af6b0b13          	addi	s6,s6,-1290 # 80021bc0 <disk>
  for(int i = 0; i < 3; i++){
    800060d2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800060d4:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060d6:	0001cc17          	auipc	s8,0x1c
    800060da:	c12c0c13          	addi	s8,s8,-1006 # 80021ce8 <disk+0x128>
    800060de:	a8b5                	j	8000615a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    800060e0:	00fb06b3          	add	a3,s6,a5
    800060e4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800060e8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800060ea:	0207c563          	bltz	a5,80006114 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800060ee:	2485                	addiw	s1,s1,1
    800060f0:	0711                	addi	a4,a4,4
    800060f2:	1f548a63          	beq	s1,s5,800062e6 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    800060f6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800060f8:	0001c697          	auipc	a3,0x1c
    800060fc:	ac868693          	addi	a3,a3,-1336 # 80021bc0 <disk>
    80006100:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006102:	0186c583          	lbu	a1,24(a3)
    80006106:	fde9                	bnez	a1,800060e0 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006108:	2785                	addiw	a5,a5,1
    8000610a:	0685                	addi	a3,a3,1
    8000610c:	ff779be3          	bne	a5,s7,80006102 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006110:	57fd                	li	a5,-1
    80006112:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006114:	02905a63          	blez	s1,80006148 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006118:	f9042503          	lw	a0,-112(s0)
    8000611c:	00000097          	auipc	ra,0x0
    80006120:	cfa080e7          	jalr	-774(ra) # 80005e16 <free_desc>
      for(int j = 0; j < i; j++)
    80006124:	4785                	li	a5,1
    80006126:	0297d163          	bge	a5,s1,80006148 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000612a:	f9442503          	lw	a0,-108(s0)
    8000612e:	00000097          	auipc	ra,0x0
    80006132:	ce8080e7          	jalr	-792(ra) # 80005e16 <free_desc>
      for(int j = 0; j < i; j++)
    80006136:	4789                	li	a5,2
    80006138:	0097d863          	bge	a5,s1,80006148 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000613c:	f9842503          	lw	a0,-104(s0)
    80006140:	00000097          	auipc	ra,0x0
    80006144:	cd6080e7          	jalr	-810(ra) # 80005e16 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006148:	85e2                	mv	a1,s8
    8000614a:	0001c517          	auipc	a0,0x1c
    8000614e:	a8e50513          	addi	a0,a0,-1394 # 80021bd8 <disk+0x18>
    80006152:	ffffc097          	auipc	ra,0xffffc
    80006156:	02c080e7          	jalr	44(ra) # 8000217e <sleep>
  for(int i = 0; i < 3; i++){
    8000615a:	f9040713          	addi	a4,s0,-112
    8000615e:	84ce                	mv	s1,s3
    80006160:	bf59                	j	800060f6 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006162:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006166:	00479693          	slli	a3,a5,0x4
    8000616a:	0001c797          	auipc	a5,0x1c
    8000616e:	a5678793          	addi	a5,a5,-1450 # 80021bc0 <disk>
    80006172:	97b6                	add	a5,a5,a3
    80006174:	4685                	li	a3,1
    80006176:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006178:	0001c597          	auipc	a1,0x1c
    8000617c:	a4858593          	addi	a1,a1,-1464 # 80021bc0 <disk>
    80006180:	00a60793          	addi	a5,a2,10
    80006184:	0792                	slli	a5,a5,0x4
    80006186:	97ae                	add	a5,a5,a1
    80006188:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    8000618c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006190:	f6070693          	addi	a3,a4,-160
    80006194:	619c                	ld	a5,0(a1)
    80006196:	97b6                	add	a5,a5,a3
    80006198:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000619a:	6188                	ld	a0,0(a1)
    8000619c:	96aa                	add	a3,a3,a0
    8000619e:	47c1                	li	a5,16
    800061a0:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061a2:	4785                	li	a5,1
    800061a4:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800061a8:	f9442783          	lw	a5,-108(s0)
    800061ac:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800061b0:	0792                	slli	a5,a5,0x4
    800061b2:	953e                	add	a0,a0,a5
    800061b4:	05890693          	addi	a3,s2,88
    800061b8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800061ba:	6188                	ld	a0,0(a1)
    800061bc:	97aa                	add	a5,a5,a0
    800061be:	40000693          	li	a3,1024
    800061c2:	c794                	sw	a3,8(a5)
  if(write)
    800061c4:	100d0d63          	beqz	s10,800062de <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061c8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061cc:	00c7d683          	lhu	a3,12(a5)
    800061d0:	0016e693          	ori	a3,a3,1
    800061d4:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    800061d8:	f9842583          	lw	a1,-104(s0)
    800061dc:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061e0:	0001c697          	auipc	a3,0x1c
    800061e4:	9e068693          	addi	a3,a3,-1568 # 80021bc0 <disk>
    800061e8:	00260793          	addi	a5,a2,2
    800061ec:	0792                	slli	a5,a5,0x4
    800061ee:	97b6                	add	a5,a5,a3
    800061f0:	587d                	li	a6,-1
    800061f2:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061f6:	0592                	slli	a1,a1,0x4
    800061f8:	952e                	add	a0,a0,a1
    800061fa:	f9070713          	addi	a4,a4,-112
    800061fe:	9736                	add	a4,a4,a3
    80006200:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006202:	6298                	ld	a4,0(a3)
    80006204:	972e                	add	a4,a4,a1
    80006206:	4585                	li	a1,1
    80006208:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000620a:	4509                	li	a0,2
    8000620c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006210:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006214:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006218:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000621c:	6698                	ld	a4,8(a3)
    8000621e:	00275783          	lhu	a5,2(a4)
    80006222:	8b9d                	andi	a5,a5,7
    80006224:	0786                	slli	a5,a5,0x1
    80006226:	97ba                	add	a5,a5,a4
    80006228:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000622c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006230:	6698                	ld	a4,8(a3)
    80006232:	00275783          	lhu	a5,2(a4)
    80006236:	2785                	addiw	a5,a5,1
    80006238:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000623c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006240:	100017b7          	lui	a5,0x10001
    80006244:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006248:	00492703          	lw	a4,4(s2)
    8000624c:	4785                	li	a5,1
    8000624e:	02f71163          	bne	a4,a5,80006270 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006252:	0001c997          	auipc	s3,0x1c
    80006256:	a9698993          	addi	s3,s3,-1386 # 80021ce8 <disk+0x128>
  while(b->disk == 1) {
    8000625a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000625c:	85ce                	mv	a1,s3
    8000625e:	854a                	mv	a0,s2
    80006260:	ffffc097          	auipc	ra,0xffffc
    80006264:	f1e080e7          	jalr	-226(ra) # 8000217e <sleep>
  while(b->disk == 1) {
    80006268:	00492783          	lw	a5,4(s2)
    8000626c:	fe9788e3          	beq	a5,s1,8000625c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006270:	f9042903          	lw	s2,-112(s0)
    80006274:	00290793          	addi	a5,s2,2
    80006278:	00479713          	slli	a4,a5,0x4
    8000627c:	0001c797          	auipc	a5,0x1c
    80006280:	94478793          	addi	a5,a5,-1724 # 80021bc0 <disk>
    80006284:	97ba                	add	a5,a5,a4
    80006286:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000628a:	0001c997          	auipc	s3,0x1c
    8000628e:	93698993          	addi	s3,s3,-1738 # 80021bc0 <disk>
    80006292:	00491713          	slli	a4,s2,0x4
    80006296:	0009b783          	ld	a5,0(s3)
    8000629a:	97ba                	add	a5,a5,a4
    8000629c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800062a0:	854a                	mv	a0,s2
    800062a2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800062a6:	00000097          	auipc	ra,0x0
    800062aa:	b70080e7          	jalr	-1168(ra) # 80005e16 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800062ae:	8885                	andi	s1,s1,1
    800062b0:	f0ed                	bnez	s1,80006292 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062b2:	0001c517          	auipc	a0,0x1c
    800062b6:	a3650513          	addi	a0,a0,-1482 # 80021ce8 <disk+0x128>
    800062ba:	ffffb097          	auipc	ra,0xffffb
    800062be:	9e4080e7          	jalr	-1564(ra) # 80000c9e <release>
}
    800062c2:	70a6                	ld	ra,104(sp)
    800062c4:	7406                	ld	s0,96(sp)
    800062c6:	64e6                	ld	s1,88(sp)
    800062c8:	6946                	ld	s2,80(sp)
    800062ca:	69a6                	ld	s3,72(sp)
    800062cc:	6a06                	ld	s4,64(sp)
    800062ce:	7ae2                	ld	s5,56(sp)
    800062d0:	7b42                	ld	s6,48(sp)
    800062d2:	7ba2                	ld	s7,40(sp)
    800062d4:	7c02                	ld	s8,32(sp)
    800062d6:	6ce2                	ld	s9,24(sp)
    800062d8:	6d42                	ld	s10,16(sp)
    800062da:	6165                	addi	sp,sp,112
    800062dc:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062de:	4689                	li	a3,2
    800062e0:	00d79623          	sh	a3,12(a5)
    800062e4:	b5e5                	j	800061cc <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062e6:	f9042603          	lw	a2,-112(s0)
    800062ea:	00a60713          	addi	a4,a2,10
    800062ee:	0712                	slli	a4,a4,0x4
    800062f0:	0001c517          	auipc	a0,0x1c
    800062f4:	8d850513          	addi	a0,a0,-1832 # 80021bc8 <disk+0x8>
    800062f8:	953a                	add	a0,a0,a4
  if(write)
    800062fa:	e60d14e3          	bnez	s10,80006162 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800062fe:	00a60793          	addi	a5,a2,10
    80006302:	00479693          	slli	a3,a5,0x4
    80006306:	0001c797          	auipc	a5,0x1c
    8000630a:	8ba78793          	addi	a5,a5,-1862 # 80021bc0 <disk>
    8000630e:	97b6                	add	a5,a5,a3
    80006310:	0007a423          	sw	zero,8(a5)
    80006314:	b595                	j	80006178 <virtio_disk_rw+0xf0>

0000000080006316 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006316:	1101                	addi	sp,sp,-32
    80006318:	ec06                	sd	ra,24(sp)
    8000631a:	e822                	sd	s0,16(sp)
    8000631c:	e426                	sd	s1,8(sp)
    8000631e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006320:	0001c497          	auipc	s1,0x1c
    80006324:	8a048493          	addi	s1,s1,-1888 # 80021bc0 <disk>
    80006328:	0001c517          	auipc	a0,0x1c
    8000632c:	9c050513          	addi	a0,a0,-1600 # 80021ce8 <disk+0x128>
    80006330:	ffffb097          	auipc	ra,0xffffb
    80006334:	8ba080e7          	jalr	-1862(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006338:	10001737          	lui	a4,0x10001
    8000633c:	533c                	lw	a5,96(a4)
    8000633e:	8b8d                	andi	a5,a5,3
    80006340:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006342:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006346:	689c                	ld	a5,16(s1)
    80006348:	0204d703          	lhu	a4,32(s1)
    8000634c:	0027d783          	lhu	a5,2(a5)
    80006350:	04f70863          	beq	a4,a5,800063a0 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006354:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006358:	6898                	ld	a4,16(s1)
    8000635a:	0204d783          	lhu	a5,32(s1)
    8000635e:	8b9d                	andi	a5,a5,7
    80006360:	078e                	slli	a5,a5,0x3
    80006362:	97ba                	add	a5,a5,a4
    80006364:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006366:	00278713          	addi	a4,a5,2
    8000636a:	0712                	slli	a4,a4,0x4
    8000636c:	9726                	add	a4,a4,s1
    8000636e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006372:	e721                	bnez	a4,800063ba <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006374:	0789                	addi	a5,a5,2
    80006376:	0792                	slli	a5,a5,0x4
    80006378:	97a6                	add	a5,a5,s1
    8000637a:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000637c:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006380:	ffffc097          	auipc	ra,0xffffc
    80006384:	e62080e7          	jalr	-414(ra) # 800021e2 <wakeup>

    disk.used_idx += 1;
    80006388:	0204d783          	lhu	a5,32(s1)
    8000638c:	2785                	addiw	a5,a5,1
    8000638e:	17c2                	slli	a5,a5,0x30
    80006390:	93c1                	srli	a5,a5,0x30
    80006392:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006396:	6898                	ld	a4,16(s1)
    80006398:	00275703          	lhu	a4,2(a4)
    8000639c:	faf71ce3          	bne	a4,a5,80006354 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800063a0:	0001c517          	auipc	a0,0x1c
    800063a4:	94850513          	addi	a0,a0,-1720 # 80021ce8 <disk+0x128>
    800063a8:	ffffb097          	auipc	ra,0xffffb
    800063ac:	8f6080e7          	jalr	-1802(ra) # 80000c9e <release>
}
    800063b0:	60e2                	ld	ra,24(sp)
    800063b2:	6442                	ld	s0,16(sp)
    800063b4:	64a2                	ld	s1,8(sp)
    800063b6:	6105                	addi	sp,sp,32
    800063b8:	8082                	ret
      panic("virtio_disk_intr status");
    800063ba:	00002517          	auipc	a0,0x2
    800063be:	42650513          	addi	a0,a0,1062 # 800087e0 <syscalls+0x3d8>
    800063c2:	ffffa097          	auipc	ra,0xffffa
    800063c6:	182080e7          	jalr	386(ra) # 80000544 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
