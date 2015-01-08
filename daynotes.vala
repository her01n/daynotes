
public string notes_dir() {
    var dir = "%s/.local/share/daynotes".printf(Environment.get_home_dir());
    DirUtils.create_with_parents(dir, 0755);
    return dir;
}

private string note_path(int day, int month, int year) {
    return "%s/%d/%d-%d".printf(notes_dir(), year, day, month);
}

public string read_note(int day, int month, int year) throws FileError {
    var path = note_path(day, month, year);
    if (FileUtils.test(path, FileTest.EXISTS)) {
        string text;
        FileUtils.get_contents(path, out text);
        return text;
    } else {
        return "";
    }
}

public void save_note(int day, int month, int year, string note) throws Error {
    var path = note_path(day, month, year);
    if (note != "") {
        var dir = Path.get_dirname(path);
        DirUtils.create_with_parents(dir, 0755);
        FileUtils.set_contents(path, note);
    } else {
        FileUtils.unlink(path);
    }
}

