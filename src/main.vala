namespace Manuscript {
    public class Application : Gtk.Application {

        public Application () {
            Object (
                application_id: Constants.APP_ID,
                flags: ApplicationFlags.FLAGS_NONE
            );
        }

        construct {
            Granite.Services.Paths.initialize (Constants.APP_ID, Constants.APP_ID);
            Granite.Services.Paths.ensure_directory_exists (Granite.Services.Paths.user_cache_folder);
        }

        protected override void activate () {
            int monitor;
            Gdk.Rectangle monitor_geometry;
            Gdk.Screen.get_default ().get_monitor_geometry (0, out monitor_geometry);
            debug (@"$(monitor_geometry.x) $(monitor_geometry.y) $(monitor_geometry.width) $(monitor_geometry.height)");
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
