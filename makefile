TARGET = example.exe
TESTBUILD = example
LEX = flex
LFLAGS = -Cf
YACC = bison
YFLAGS = -d
CC = i586-mingw32msvc-gcc
CFLAGS = -O -Wall 
INSTALLDIR = ~/bin

.PHONY: default all clean install uninstall cleanall

default: $(TARGET)

all: default install

FLEXFILES = $(wildcard *.l)
BISONFILES = $(wildcard *.y)
CFLEX = $(patsubst %.l, %.c, $(FLEXFILES)) 
CBISON = $(patsubst %.y, %.c, $(BISONFILES))
OBJECTS = $(CFLEX) $(CBISON)

%.c: %.l
	$(LEX) $(LFLAGS) -o $@ $<

%.c: %.y
	$(YACC) $(YFLAGS) -o $@ $<

%.h: %.c
	@touch $@

$(CFLEX): $(CBISON)

.PRECIOUS: $(TARGET) $(OBJECTS)

$(TARGET): $(OBJECTS)
	$(CC) -g $(OBJECTS) $(CFLAGS) -o $@

linux: $(OBJECTS)
	gcc -g $(OBJECTS) $(CFLAGS) -o $(TESTBUILD)

cleanall: clean uninstall

clean:
	-rm -f *.c
	-rm -f $(TARGET)
	-rm -f $(TESTBUILD)

uninstall:
	-rm -f $(INSTALLDIR)/$(TARGET)

install:
	cp -f $(TARGET) $(INSTALLDIR)

build:
	bison -d -o parser.c parser.y
	flex -Cf -o scanner.c scanner.l
	$(CC) -g $(OBJECTS) $(CFLAGS) -o $(TARGET)

test:
	bison -d -o parser.c parser.y
	flex -Cf -o scanner.c scanner.l
	gcc -g $(OBJECTS) $(CFLAGS) -o rvtest
