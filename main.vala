using Gtk;

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

public class App : Window {

    private DateTime current;
    private HeaderBar header = new HeaderBar();

    private void set_date(DateTime set) {
        current = set;
        header.title = set.format("%x");
        var now = new DateTime.now_local();
        string rel;
        int d = year_diff(set, now);
        if (d < 0) {
            rel = "%d years ago".printf(-d);
        } else if (d > 0) {
            rel = "in %d years".printf(d);
        } else {
            d = month_diff(set, now);
            if (d < -1) {
                rel = "%d months ago".printf(-d);
            } else if (d > 1) {
                rel = "in %d months".printf(d);
            } else {
                d = day_diff(set, now);
                if (d < -13) {
                    rel = "%d weeks ago".printf(-d/7);
                } else if (d < -1) {
                    rel = "%d days ago".printf(-d);
                } else if (d == -1) {
                    rel = "yesterday";
                } else if (d == 0) {
                    rel = "today";
                } else if (d == 1) {
                    rel = "tommorow";
                } else if (d < 14) {
                    rel = "in %d days".printf(d);
                } else {
                    rel = "in %d weeks".printf(d/7);
                }
            }
        }
        header.subtitle = rel;
    }

    public App() {
        var notes = new TextView();
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
        add(notes);
        destroy.connect(Gtk.main_quit);
        set_date(new DateTime.now_local());
    }

}

int main(string[] args) {
    Gtk.init(ref args);
    new App().show_all();
    Gtk.main();
    return 0;
}

