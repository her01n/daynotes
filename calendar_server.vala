
public struct Event {
    public string uid;
    public string summary;
    public string description;
    public bool all_day;
    public int64 start;
    public int64 end;
    public HashTable<string, Variant> extras;
}

[DBus (name = "org.gnome.Shell.CalendarServer.Error")]
public errordomain CalendarError {
    FAILED
}

[DBus (name = "org.gnome.Shell.CalendarServer")]
public class CalendarServer : Object {

    public Event[] get_events(int64 int_since, int64 int_until, bool force_reload) 
            throws CalendarError, FileError {
        since = int_since;
        until = int_until;
        DateTime i = new DateTime.from_unix_utc(int_since);
        DateTime dt_until = new DateTime.from_unix_utc(int_until);
        int u_year = dt_until.get_year();
        int u_month = dt_until.get_month();
        int u_day = dt_until.get_day_of_month();
        Event[] events = {};
        while (true) {
            int year = i.get_year();
            int month = i.get_month();
            int day = i.get_day_of_month();
            if (year > u_year) {
                break;
            } else if (year == u_year) {
                if (month > u_month) {
                    break;
                } else if (month == u_month) {
                    if (day > u_day) {
                        break;
                    }
                }
            }
            string note = read_note(day, month, year);
            if (note != "") {
                var e = Event() {
                    uid = "%d-%d-%d".printf(day, month, year),
                    summary = note.split("\n", 2)[0],
                    description = note,
                    all_day = true,
                    start = new DateTime.local(year, month, day, 9, 0, 0).to_unix(),
                    end = new DateTime.local(year, month, day, 17, 0, 0).to_unix(),
                    extras = new HashTable<string, Variant>(null, null)
                };
                events += e;
            }
            i = i.add_days(1);
        }
        return events;
    }

    public bool has_calendars { get; set; default = true; }
    public int64 since { get; set; default = 0; }
    public int64 until { get; set; default = 0; } 

    public signal void changed();

    public CalendarServer() {
        try {
            int stdout = 0;
            bool success = Process.spawn_async_with_pipes(null, 
                { "inotifywait", "-m", "-r", notes_dir(), "-e", "moved_to",
                  "-e", "moved_from", "-e", "modify", "-e", "delete" }, null, 
                SpawnFlags.SEARCH_PATH, null, null, null, out stdout);
            if (!success) {
                stderr.printf("failed to watch notes\n");
                return;
            }
            IOChannel watch = new IOChannel.unix_new(stdout);
            var r = watch.add_watch(IOCondition.IN, (source, condition) => {
                try {
                    if (condition == IOCondition.HUP) {
                        return false;
                    } else {
                        string line;
                        size_t i2, i3;
                        source.read_line(out line, out i2, out i3);
                        changed();
                        return true;
                    }
                } catch (Error e) {
                    stderr.printf("error reading subprocess: %s\n", e.message);
                    return true;
                }
            });
            if (r == 0) {
                stderr.printf("failed to add watch\n");
            }
        } catch (Error e) {
            stderr.printf("watch notes error: %s\n", e.message);
        }
    }

}

void on_bus_aquire(DBusConnection conn) {
    try {
        conn.register_object("/org/gnome/Shell/CalendarServer", new CalendarServer());
    } catch (IOError e) {
        stderr.printf("register object failed: " + e.message);
    }
}

void main() {
    Bus.own_name(BusType.SESSION, "org.gnome.Shell.CalendarServer", BusNameOwnerFlags.NONE,
        on_bus_aquire,
        () => {},
        () => stderr.printf("Could not aquire name\n"));
    new MainLoop().run();
}

