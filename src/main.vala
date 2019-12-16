namespace Manuscript {
  public class Application : Gtk.Application {
    public Application () {
      Object (
        application_id: Constants.APP_ID,
        flags: ApplicationFlags.FLAGS_NONE
      );
    }

    construct {
      Granite.Services.Paths.initialize(Constants.APP_ID, Constants.APP_ID);
      Granite.Services.Paths.ensure_directory_exists(Granite.Services.Paths.user_cache_folder);
    }

    protected override void activate () {
      AppSettings settings = AppSettings.get_instance ();
      EditorWindow main_window;
      debug (settings.last_opened_document);
      if (settings.last_opened_document != "") {
        debug ("Opening with document - " + settings.last_opened_document);
        main_window = new EditorWindow.with_document (this, settings.last_opened_document);
      } else {
        debug ("Opening with welcome view");
        main_window = new EditorWindow.with_document (this);
      }
      main_window.title = Constants.APP_NAME;
      main_window.show_all ();
    }

    public static int main (string[] args) {
      var app = new Application ();
      return app.run (args);
    }
  }
}

