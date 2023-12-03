CROSS_COMPILE =
CC = $(CROSS_COMPILE)-gcc
RM = rm -f
default: all

all: writer

writer: writer.c
	$(CC) -o writer writer.c

clean:
	$(RM) writer
