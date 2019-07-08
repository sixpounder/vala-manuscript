public class MainWindow : Gtk.ApplicationWindow {
  protected uint configure_id = 0;
  protected AppSettings settings;
  protected Gtk.Box layout;
  protected WelcomeView welcome_view;
  protected Header header;
  public Editor current_editor;

  public MainWindow (Gtk.Application app) {
    Object(
      application: app,
      default_height: settings.window_height,
      default_width: settings.window_width
    );

    this.layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
    this.settings = AppSettings.get_instance();

    this.header = new Header(this);
    this.header.open_file.connect(() => {
      this.open_file_dialog();
    });
    this.set_titlebar(header);


    this.welcome_view = new WelcomeView();
    this.welcome_view.should_open_file.connect(this.open_file_dialog);

    this.add(this.layout);

    if (settings.last_opened_document != "") {
      this.open_file_at_path(settings.last_opened_document);
    } else {
      this.layout.pack_start(this.welcome_view);
    }

    this.layout.pack_end(new StatusBar(), false, true, 0);
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
    if (this.current_editor != null) {
      this.cleanup_layout();
    }
    this.current_editor = new Editor(path);
    this.layout.pack_start(this.current_editor);
  }

  protected void cleanup_layout () {
    GLib.List<weak Gtk.Widget> children = this.layout.get_children();
    foreach (Gtk.Widget element in children) {
      if (element is Editor || element is WelcomeView) {
        this.layout.remove(element);
      }
    }
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