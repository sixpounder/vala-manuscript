public class MainWindow : Gtk.ApplicationWindow {
  protected uint configure_id = 0;
  protected AppSettings settings;
  protected Gtk.Box layout;
  protected WelcomeView welcome_view;
  public Editor current_editor;

  public MainWindow (Gtk.Application app) {
    Object(
      application: app
    );

    this.set_titlebar(new Header(this));

    this.settings = AppSettings.get_instance();

    this.default_width = settings.window_width;
    this.default_height = settings.window_height;

    this.layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
    this.layout.add.connect(widget => {
      if (widget is WelcomeView) {
        this.layout.remove(this.welcome_view);
      }
    });

    this.welcome_view = new WelcomeView();
    this.welcome_view.should_open_file.connect(this.open_file_dialog);

    this.add(this.layout);


    if (settings.last_opened_document != "") {
      this.open_file_at_path(settings.last_opened_document);
    } else {
      this.layout.pack_start(this.welcome_view);
    }
  }

  public override bool configure_event (Gdk.EventConfigure event) {
    if (configure_id != 0) {
        GLib.Source.remove (configure_id);
    }

    configure_id = Timeout.add (100, () => {
      configure_id = 0;

      Gtk.Allocation rect;
      get_allocation(out rect);
      settings.window_width = rect.width;
      settings.window_height = rect.height;

      int root_x, root_y;
      get_position(out root_x, out root_y);
      settings.window_x = root_x;
      settings.window_y = root_y;

      return false;
    });

    return base.configure_event (event);
  }

  /**
   * Shows the open document dialog
   */
  public void open_file_dialog () {
    Gtk.FileChooserDialog dialog = new Gtk.FileChooserDialog(
      "Open document",
      (Gtk.Window) this.get_toplevel(),
      Gtk.FileChooserAction.OPEN,
      "Cancel",
      Gtk.ResponseType.CANCEL,
      "Open",
      Gtk.ResponseType.ACCEPT
    );

    Gtk.FileFilter text_file_filter = new Gtk.FileFilter();
    text_file_filter.add_mime_type("text/plain");
    text_file_filter.add_mime_type("text/markdown");
    text_file_filter.add_pattern("*.txt");
    text_file_filter.add_pattern("*.md");

    dialog.add_filter(text_file_filter);

    dialog.response.connect((res) => {
      dialog.hide();
      if (res == Gtk.ResponseType.ACCEPT) {
        this.open_file_at_path(dialog.get_filename());
      }
    });

    dialog.run();
  }

  public void open_file_at_path (string path) {
    this.layout.pack_start(this.current_editor = new Editor(path));
  }

  protected void message (string message, Gtk.MessageType level = Gtk.MessageType.ERROR) {
		var messagedialog = new Gtk.MessageDialog (this,
                            Gtk.DialogFlags.MODAL,
                            Gtk.MessageType.ERROR,
                            Gtk.ButtonsType.OK,
                            message);
		messagedialog.show ();
	}
}