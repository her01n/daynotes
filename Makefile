
default: all

all: 
	mkdir -p bin
	valac --pkg gtk+-3.0 main.vala daynotes.vala -o bin/daynotes 2>&1 | perl valac_remove_columns.pl
	valac --pkg gtk+-3.0 calendar_server.vala daynotes.vala -o bin/calendar_server 2>&1 | perl valac_remove_columns.pl

clean:
	rm -rf bin

.PHONY: all clean default

