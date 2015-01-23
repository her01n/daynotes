
default: all

all: 
	mkdir -p bin
	valac --pkg gtk+-3.0 main.vala daynotes.vala -o bin/daynotes 2>&1 | perl valac_remove_columns.pl
	valac --pkg gtk+-3.0 calendar_server.vala daynotes.vala -o bin/daynotes-calendar-server 2>&1 | perl valac_remove_columns.pl

clean:
	rm -rf bin

install:
	mkdir -p /usr/local/bin
	install bin/daynotes /usr/local/bin/daynotes
	mkdir -p /usr/local/libexec
	install bin/daynotes-calendar-server /usr/local/libexec/daynotes-calendar-server
	mkdir -p /usr/local/share/applications
	install daynotes.desktop /usr/local/share/applications/daynotes.desktop
	# XXX ugly hack
	mv /usr/share/dbus-1/services/org.gnome.Shell.CalendarServer.service /usr/share/dbus-1/services/org.gnome.Shell.CalendarServer.service.backup || true
	install fake.CalendarServer.service /usr/share/dbus-1/services/org.gnome.Shell.CalendarServer.service

uninstall:
	rm -rf /usr/local/bin/daynotes
	rm -rf /usr/local/libexec/daynotes-calendar-server
	mv /usr/share/dbus-1/services/org.gnome.Shell.CalendarServer.service.backup /usr/share/dbus-1/services/org.gnome.Shell.CalendarServer.service || true

.PHONY: all clean default

