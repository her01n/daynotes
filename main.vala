using GLib;
using Gtk;

// TODO check if the class GLib.Date can save us some of these methods
int days_of_year(int year) {
    if (year % 4 == 0) {
        if (year % 100 == 0) {
            if (year % 400 == 0) {
                return 366;
            } else {
                return 365;
            }
        } else {
            return 366;
        }
    } else {
        return 365;
    }
}

int day_diff(DateTime a, DateTime b) {
    int days = a.get_day_of_year() - b.get_day_of_year();
    int ay = a.get_year();
    int by = b.get_year();
    while (ay > by) {
        days += days_of_year(by);
        by--;
    }
    while (ay < by) {
        days -= days_of_year(ay);
        ay++;
    }
    return days;
}

int month_diff(DateTime a, DateTime b) {
    int diff = (a.get_month() + a.get_year()*12) 
        - (b.get_month() + b.get_year()*12);
    if (diff == 0) {
        return 0;
    } else if (diff < 0) {
        if (a.get_day_of_month() <= b.get_day_of_month()) {
            return diff;
        }
        return diff + 1;
    } else if (diff > 0) {
        if (a.get_day_of_month() >= b.get_day_of_month()) {
            return diff;
        }
        return diff - 1;
    }
    return 0;
}

int year_diff(DateTime a, DateTime b) {
    int diff = a.get_year() - b.get_year();
    if (diff == 0) {
        return 0;
    } else if (diff < 0) {
        if (a.get_month() < b.get_month()) {
            return diff;
        } else if (a.get_month() == b.get_month()) {
            if (a.get_day_of_month() <= b.get_day_of_month()) {
                return diff;
            }
        }
        return diff + 1;
    } else if (diff > 0) {
        if (a.get_month() > b.get_month()) {
            return diff;
        } else if (a.get_month() == b.get_month()) {
            if (a.get_day_of_month() >= b.get_day_of_month()) {
                return diff;
            }
        }
        return diff - 1;
    }
    return 0;
}


public class TimedTask {

    private bool running = true;
    private SourceFunc fun;

    public TimedTask(owned SourceFunc fun) {
        this.fun = (owned) fun;
        Timeout.add(200, forward);
    }

    public void cancel() {
        this.running = false;
    }

    private bool forward() {
        if (running) {
            fun();
        }
        return false;
    }

}

string relation(DateTime set, DateTime now) {
    int d = year_diff(set, now);
    if (d < 0) {
        return "%d years ago".printf(-d);
    } else if (d > 0) {
        return "in %d years".printf(d);
    } else {
        d = month_diff(set, now);
        if (d < -1) {
            return "%d months ago".printf(-d);
        } else if (d > 1) {
            return "in %d months".printf(d);
        } else {
            d = day_diff(set, now);
            if (d < -13) {
                return "%d weeks ago".printf(-d/7);
            } else if (d < -1) {
                return "%d days ago".printf(-d);
            } else if (d == -1) {
                return "yesterday";
            } else if (d == 0) {
                return "today";
            } else if (d == 1) {
                return "tommorow";
            } else if (d < 14) {
                return "in %d days".printf(d);
            } else {
                return "in %d weeks".printf(d/7);
            }
        }
    }
}

delegate void WorkerCallback(string text);

private class Worker {

    private WorkerCallback loaded;
    private WorkerCallback error;

    public Worker(owned WorkerCallback loaded, owned WorkerCallback error) throws ThreadError {
        this.loaded = (owned) loaded;
        this.error = (owned) error;
        // TODO funny i can't start a background thread properly
        Thread.create<string>(run, false);
    }

    private class Task {
        public DateTime? load = null;
        public string? save = null;
    }

    private AsyncQueue<Task> todo = new AsyncQueue<Task>();

    public void load(DateTime time) {
        Task task = new Task();
        task.load = time;
        todo.push(task);
    }

    public void save(string text) {
        Task task = new Task();
        task.save = text;
        todo.push(task);
    }

    private string run() {
        DateTime? load = null;
        while (true) {
            try {
                while (load == null) {
                    load = todo.pop().load;
                }
                int day = load.get_day_of_month();
                int month = load.get_month();
                int year = load.get_year();
                var text = read_note(day, month, year);
                Idle.add(() => {
                    loaded(text);
                    return false;
                });
                Task task;
                while ((task = todo.pop()).save != null) {
                    if (text != task.save) {
                        text = task.save;
                        save_note(day, month, year, task.save);
                    }
                }
                load = task.load;
            } catch (Error e) {
                var message = e.message;
                print(message);
                Idle.add(() => {
                    error(message);
                    return false;
                });
            }
        }
    }

}

public class App : Window {

    private DateTime current;
    private HeaderBar header = new HeaderBar();
    private TimedTask loading = null;
    private Overlay overlay = new Overlay();
    private TextView notes = new TextView();
    private Widget over = null;
    private Worker worker;

    private void set_date(DateTime set) {
        current = set;
        header.title = set.format("%x");
        header.subtitle = relation(set, new DateTime.now_local());
        notes.editable = false;
        if (loading != null) {
            loading.cancel();
        }
        loading = new TimedTask(show_loading);
        worker.load(current);
    }

    private void show_over(Widget? widget) {
        if (over != null) {
            over.destroy();
        }
        over = widget;
        if (widget != null) {
            overlay.add_overlay(widget);
        }
    }

    private bool show_loading() {
        var spinner = new Spinner();
        spinner.start();
        show_over(spinner);
        return true;
    }

    private void loaded(string text) {
        loading.cancel();
        show_over(null);
        notes.editable = true;
        notes.get_buffer().text = text;
    }

    private void error(string error) {
        var notice = new Label(error);
        show_over(notice);
    }

    public App() throws ThreadError {
        set_default_size(400, 300);
        var previous = new Button.from_icon_name("go-previous", IconSize.BUTTON);
        previous.relief = ReliefStyle.NONE;
        previous.clicked.connect(() => {
            set_date(current.add_days(-1));
        });
        var next = new Button.from_icon_name("go-next", IconSize.BUTTON);
        next.relief = ReliefStyle.NONE;
        next.clicked.connect(() => {
            set_date(current.add_days(1));
        });
        var navigation = new Box(Orientation.HORIZONTAL, 0);
        navigation.add(previous);
        navigation.add(next);
        header.show_close_button = true;
        header.pack_start(navigation);
        set_titlebar(header);
        ScrolledWindow scrolled = new ScrolledWindow(null, null);
        scrolled.add(notes);
        add(scrolled);
        destroy.connect(Gtk.main_quit);
        worker = new Worker(loaded, error);
        set_date(new DateTime.now_local());
        Timeout.add(200, () => {
            if (notes.editable) {
                worker.save(notes.get_buffer().text);
            }
            return true;
        });
    }

}

int main(string[] args) {
    try {
        Gtk.init(ref args);
        new App().show_all();
        Gtk.main();
        return 0;
    } catch (Error e) {
        stderr.printf("Error: %s\n", e.message);
        return -1;
    }
}

