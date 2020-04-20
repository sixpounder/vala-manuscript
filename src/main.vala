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
      AppSettings settings = AppSettings.get_instance ();
      Window main_window;

      if (settings.last_opened_document != "") {
        debug ("Opening with document - " + settings.last_opened_document);
        main_window = new Window.with_document (this, settings.last_opened_document);
      } else {
        debug ("Opening with welcome view");
        main_window = new Window.with_document (this);
      }
      main_window.title = Constants.APP_NAME;

      // Current window close accelerator
      var quit_action = new SimpleAction ("quit", null);
      add_action (quit_action);
      quit_action.activate.connect (() => {
        if (main_window != null) {
          main_window.close ();
        }
      });
      set_accels_for_action ("app.quit", {"<Ctrl>Q"});

      // Zen mode accelerator
      var zen_action = new SimpleAction ("zen", null);
      add_action (zen_action);
      zen_action.activate.connect (() => {
        settings.zen = !settings.zen;
      });
      set_accels_for_action ("app.zen", {"<Alt>M"});

      main_window.show_all ();

      Globals.application = this;
      Globals.window = main_window;
    }

    public static int main (string[] args) {
      var app = new Application ();
      return app.run (args);
    }
  }
}

