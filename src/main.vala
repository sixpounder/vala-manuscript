namespace Manuscript {
    public class Application : Gtk.Application {

        public static bool ensure_directory_exists (File dir) {

            if (!dir.query_exists ())
                try {
                    dir.make_directory_with_parents ();
                    return true;
                } catch {
                    error ("Could not access or create the directory '%s'.", dir.get_path ());
                }

            return false;
        }

        public Application () {
            Object (
                application_id: Constants.APP_ID,
                flags: ApplicationFlags.HANDLES_OPEN
            );
        }

        construct {
            debug (@"Cache folder: $(Path.build_path(Path.DIR_SEPARATOR_S, Environment.get_user_cache_dir (), Constants.APP_ID))");
            Environment.set_application_name ("Manuscript");
            Application.ensure_directory_exists (
                File.new_for_path(
                    Path.build_path(Path.DIR_SEPARATOR_S, Environment.get_user_cache_dir (), Constants.APP_ID)
                )
            );
        }

        protected override void activate () {
            Services.AppSettings settings = Services.AppSettings.get_default ();

            weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
            default_theme.add_resource_path ("/com/github/sixpounder/manuscript/icons");

            Manuscript.Window main_window;

            if (settings.last_opened_document != "") {
                main_window = this.new_window (settings.last_opened_document);
            } else {
                main_window = this.new_window ();
            }

            Globals.application = this;
            Globals.window = main_window;
        }

        protected override void open (File[] files, string hint) {
            Services.AppSettings settings = Services.AppSettings.get_default ();

            weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
            default_theme.add_resource_path ("/com/github/sixpounder/manuscript/icons");

            Manuscript.Window main_window;

            if (files.length != 0) {
                main_window = this.new_window (files[0].get_path ());
            } else {
                if (settings.last_opened_document != "") {
                    main_window = this.new_window (settings.last_opened_document);
                } else {
                    main_window = this.new_window ();
                }
            }

            Globals.application = this;
            Globals.window = main_window;
        }

        public Manuscript.Window new_window (string ? document_path = null) {
            Manuscript.Window window;

            if (document_path != null && document_path != "") {
                debug ("Opening with document - " + document_path);
                window = new Manuscript.Window.with_document (this, document_path);
            } else {
                debug ("Opening with welcome view");
                window = new Manuscript.Window.with_document (this);
            }

            window.title = Constants.APP_NAME;

            window.show_all ();

            return window;
        }

        public static int main (string[] args) {
            var app = new Manuscript.Application ();
            return app.run (args);
        }
    }
}
