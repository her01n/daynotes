
default: all

all: 
	perl make.pl

clean:
	rm -rf bin

.PHONY: all clean default
