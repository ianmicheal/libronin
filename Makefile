NETSERIAL = 0
NETCD = 0
CCC = sh-elf-c++ -fno-rtti -fconserve-space
CC = sh-elf-gcc -Wall
LD = sh-elf-ld -EL
AS = sh-elf-as -little
AR = sh-elf-ar


#Must be O4 to handle long jumps correctly.
OPTIMISE=-O4 -ffreestanding -ffast-math -fschedule-insns2 -fomit-frame-pointer -fno-inline-functions -fno-defer-pop -fforce-addr -fstrict-aliasing -funroll-loops -fdelete-null-pointer-checks -fno-exceptions
CPUFLAGS = -ml  -m4-single-only
INCLUDES = -I. -Izlib -Ilwip/include -Ilwip/include/ipv4 -Ilwip/arch/dc/include

# TYPE can be elf, srec or bin
TYPE = elf
EXTRALIBS += -lm
CRT0=crt0.o
ifeq "$(TYPE)" "bin"
LINK=$(CPUFLAGS) -nostartfiles -nostdlib $(INCLUDES) -o $@ -Lzlib -lz -L. -lronin-noserial -lgcc -lc
else
LINK=$(CPUFLAGS) -nostartfiles -nostdlib $(INCLUDES) -o $@ -Lzlib -lz -L. -lronin -lgcc -lc
endif

EXAMPLEFLAGS = -DVMUCOMPRESS
CCFLAGS = $(OPTIMISE) $(CPUFLAGS) $(EXAMPLEFLAGS) -I. -DDC -DDREAMCAST 

CFLAGS = $(CCFLAGS)


# begin lwIP

LWCOREOBJS=lwip/core/mem.o lwip/core/memp.o lwip/core/netif.o \
	lwip/core/pbuf.o lwip/core/stats.o lwip/core/sys.o \
        lwip/core/tcp.o lwip/core/tcp_input.o \
        lwip/core/tcp_output.o lwip/core/udp.o 
LWCORE4OBJS=lwip/core/ipv4/icmp.o lwip/core/ipv4/ip.o \
	lwip/core/inet.o lwip/core/ipv4/ip_addr.o

LWAPIOBJS=lwip/api/api_lib.o lwip/api/api_msg.o lwip/api/tcpip.o \
	lwip/api/err.o lwip/api/sockets.o 

LWNETIFOBJS=lwip/netif/loopif.o \
	lwip/netif/tcpdump.o lwip/netif/arp.o

LWARCHOBJS=lwip/arch/dc/sys_arch.o lwip/arch/dc/thread_switch.o \
	lwip/arch/dc/netif/bbaif.o lwip/arch/dc/netif/rtk.o \
	lwip/arch/dc/netif/gapspci.o

LWIPOBJS=$(LWCOREOBJS) $(LWCORE4OBJS) $(LWAPIOBJS) $(LWNETIFOBJS) \
	$(LWARCHOBJS) lwip_util.o

# end lwIP

OBJECTS  = report.o ta.o maple.o video.o c_video.o vmsfs.o time.o display.o sound.o gddrive.o gtext.o translate.o misc.o gfxhelper.o malloc.o matrix.o

ifeq "$(NETSERIAL)" "1"
OBJECTS += netserial.o
else
OBJECTS += serial.o
endif
ifeq "$(NETCD)" "1"
OBJECTS += netcd.o
else
OBJECTS += cdfs.o
endif

OBJECTS += $(LWIPOBJS)

OBJECTS += notlibc.o 
EXAMPLES = examples/ex_serial.$(TYPE) \
	   examples/ex_video.$(TYPE) \
	   examples/ex_vmsfscheck.$(TYPE) \
	   examples/ex_gtext.$(TYPE) \
	   examples/ex_showpvr.$(TYPE) \
	   examples/ex_malloc.$(TYPE) \
	   examples/ex_purupuru.$(TYPE) \
	   examples/ex_compress.$(TYPE) \
	   examples/ex_videomodes.$(TYPE) \

ARMFLAGS=-mcpu=arm7 -ffreestanding  -O5 -funroll-loops

most: crt0.o libronin.a libz.a

all: crt0.o libronin.a libronin-noserial.a cleanish libz.a

libronin.a: $(OBJECTS) arm_sound_code.h Makefile
	rm -f $@ && $(AR) rs $@ $(OBJECTS)

noserial-dummy: $(OBJECTS) arm_sound_code.h Makefile
	@echo Dummy done.

libronin-noserial.a: libronin.a
	$(MAKE) cleanish
	rm -f libronin-serial.a
	$(MAKE) CCFLAGS="$(CCFLAGS) -DNOSERIAL" CFLAGS="$(CCFLAGS) -DNOSERIAL" noserial-dummy
	rm -f $@ && $(AR) rs $@ $(OBJECTS)

libz.a:
	cd zlib; $(MAKE) libz.a
	@echo Making convenience links.
	-ln -s zlib/libz.a .
	-ln -s zlib/zlib.h .
	-ln -s zlib/zconf.h .

cleanish:
	rm -f $(OBJECTS) $(EXAMPLES) \
	      arm_sound_code.h arm_sound_code.bin arm_sound_code.elf \
	      arm_sound_code.o arm_startup.o

clean: cleanish
	rm -f crt0.o
	rm -f libronin.a 
	rm -f libronin-noserial.a 
	cd zlib && $(MAKE) clean

examples: libronin.a $(EXAMPLES)

ifeq "$(NETSERIAL)$(NETCD)" "00"
DISTHEADERS=cdfs.h common.h dc_time.h gddrive.h gfxhelper.h gtext.h maple.h misc.h notlibc.h report.h ronin.h serial.h sincos_rroot.h soundcommon.h sound.h ta.h translate.h video.h vmsfs.h
dist: $(DISTHEADERS) 
	@$(MAKE) clean && \
	$(MAKE) all && \
	if [ `ar -t libronin-noserial.a|egrep 'net(cd|serial)'|wc -l` = 0 -a \
	     `ar -t libronin.a | egrep 'net(cd|serial)' | wc -l` = 0 ]; then \
		mkdir disttmp && mkdir disttmp/ronin && \
		mkdir disttmp/ronin/include && mkdir disttmp/ronin/include/ronin && \
		cp libronin.a disttmp/ronin && \
		cp libronin-noserial.a disttmp/ronin && \
		cp crt0.o disttmp/ronin && \
		cp $(DISTHEADERS) disttmp/ronin/include/ronin && \
		cp README disttmp/ronin && \
		cp COPYING disttmp/ronin && \
		cp zlib/README disttmp/ronin/ZLIB_README && \
		cp zlib/libz.a disttmp/ronin && \
		cp zlib/zlib.h disttmp/ronin/include && \
		cp zlib/zconf.h disttmp/ronin/include && \
		cp lwip/COPYING disttmp/ronin/LWIP_COPYING && \
		cp lwipopts.h disttmp/ronin/include && \
		cp -R lwip/include/lwip disttmp/ronin/include/ && \
		cp -R lwip/include/netif disttmp/ronin/include/ && \
		cp -R lwip/include/ipv4/lwip disttmp/ronin/include/ && \
		cp -R lwip/arch/dc/include/arch disttmp/ronin/include/ && \
		cp -R lwip/arch/dc/include/netif disttmp/ronin/include/ && \
		find disttmp -type d -a -name CVS -exec rm -rf {} \; && \
		(cd disttmp && tar cvf - ronin) | gzip -c > ronin-dist.tar.gz && \
		echo "remember to tag and bump version if you didn't already." && \
		rm -rf disttmp; \
	else \
		echo "Parts of NETCD/NETSERIAL found in libs!"; \
	fi;

else
dist:
	@echo "You must disable NETCD/NETSERIAL!"
endif

#RIS specific upload targets
test-vmufs: examples/ex_vmsfscheck.$(TYPE)
	/home/peter/hack/dreamsnes/dc/ipupload.pike < examples/ex_vmsfscheck.$(TYPE)

test-gtext: examples/ex_gtext.$(TYPE) 
	/home/peter/hack/dreamsnes/dc/ipupload.pike < examples/ex_gtext.$(TYPE)

test-showpvr: examples/ex_showpvr.$(TYPE) 
	/home/peter/hack/dreamsnes/dc/ipupload.pike < examples/ex_showpvr.$(TYPE)

test-clouds: examples/ex_clouds.elf
	/home/peter/hack/dreamsnes/dc/ipupload.pike < examples/ex_clouds.$(TYPE)

test-control: examples/ex_control.elf
	/home/peter/hack/dreamsnes/dc/ipupload.pike < examples/ex_control.$(TYPE)

test-malloc: examples/ex_malloc.elf
	/home/peter/hack/dreamsnes/dc/ipupload.pike < examples/ex_malloc.$(TYPE)

test-purupuru: examples/ex_purupuru.elf
	/home/peter/hack/dreamsnes/dc/ipupload.pike < examples/ex_purupuru.$(TYPE)

test-compress: examples/ex_compress.elf
	/home/peter/hack/dreamsnes/dc/ipupload.pike < examples/ex_compress.$(TYPE)

test-videomodes: examples/ex_videomodes.elf
	/home/peter/hack/dreamsnes/dc/ipupload.pike < examples/ex_videomodes.$(TYPE)

#ARM sound code
arm_sound_code.h: arm_sound_code.bin
	./encode_armcode.pike < $< > $@

arm_sound_code.bin: arm_sound_code.elf
	arm-elf-objcopy -O binary $< $@

arm_sound_code.elf: arm_startup.o arm_sound_code.o
	arm-elf-gcc $(ARMFLAGS) -Wl,-Ttext,0 -nostdlib -nostartfiles -o $@ $^ -lgcc -lgcc

arm_sound_code.o: arm_sound_code.c soundcommon.h
	arm-elf-gcc -c -I libmad -Wall $(ARMFLAGS) -Wundefined   -o $@ $<

# -DMPEG_AUDIO

arm_startup.o: arm_startup.s
	arm-elf-as -marm7 -o $@ $<

#Serial code that hangs
stella.elf: examples/ex_serial.c examples/ex_serial.o libronin.a serial.h Makefile
	$(CCC) -Wl,-Ttext=0x8c020000 $(CRT0) examples/ex_serial.o $(LINK)


#Automatic extension conversion.
.SUFFIXES: .o .cpp .c .cc .h .m .i .S .asm .elf .srec .bin

.c.elf: libronin.a crt0.o Makefile
	$(CC) -Wl,-Ttext=0x8c020000 $(CCFLAGS) $(CRT0) $*.c $(LINK) -lm

.c.bin: libronin-noserial.a crt0.o Makefile
	$(CC) -Wl,-Ttext=0x8c010000,--oformat,binary -DNOSERIAL $(CCFLAGS) $(CRT0) $*.c $(LINK)

.c.srec: libronin.a crt0.o Makefile
	$(CC) -Wl,-Ttext=0x8c020000,--oformat,srec $(CCFLAGS) $(CRT0) $*.c $(LINK)

.cpp.o:
#	@echo Compiling $*.cpp
	$(CCC) $(INCLUDES) -c $(CCFLAGS) $*.cpp -o $@

.c.o: Makefile
#	@echo Compiling $*.c
	$(CC)  $(INCLUDES) -c $(CCFLAGS) $*.c -o $@

.cpp.S:
	$(CCC) $(INCLUDES) -S $(CCFLAGS) $*.cpp -o $@

.cpp.i:
	$(CCC) $(INCLUDES) -E $(CCFLAGS) $*.cpp -o $@

.S.o:
#	@echo Compiling $*.s
#	$(CCC) $(INCLUDES) -S $(CCFLAGS) $*.S -o $@
	$(AS) $*.S -o $@

.S.i:
	$(CCC) $(INCLUDES) -c -E $(CCFLAGS) $*.S -o $@

.s.o:
#	@echo Compiling $*.s
	$(AS) $*.s -o $@


#Extra dependencies.
sound.o: arm_sound_code.h

#Nice to have for special (libronin) development purposes.
cdfs.o: gddrive.h
malloc.o: Makefile
notlibc.o: Makefile
examples/ex_gtext.$(TYPE): libronin.a
examples/ex_showpvr.$(TYPE): libronin.a
examples/ex_cloud.$(TYPE): libronin.a
examples/ex_malloc.elf: libronin.a
