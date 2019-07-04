public class Write : Gtk.Application {
    public Write () {
        Object (
            application_id: "com.github.sixpounder.write",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        var main_window = new MainWindow (this);
        main_window.default_height = 300;
        main_window.default_width = 600;
        main_window.title = "Write";
        main_window.show_all ();
    }

    public static int main (string[] args) {
        var app = new Write ();
        return app.run (args);
    }
}