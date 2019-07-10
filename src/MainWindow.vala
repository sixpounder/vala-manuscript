public class MainWindow : Gtk.ApplicationWindow {
  protected uint configure_id = 0;
  protected AppSettings settings;
  protected Gtk.Box layout;
  protected WelcomeView welcome_view;
  protected Header header;
  protected Document document;
  public Editor current_editor;

  public MainWindow (Gtk.Application app) {
    Object(
      application: app
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

    this.key_press_event.connect(this.on_key_press);
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
    try {
      this.document = Store.get_instance().load_document(path);
      if (this.current_editor == null) {
        this.current_editor = new Editor(this.document);
        this.layout.pack_start(this.current_editor, true, true, 0);
      } else {
        this.current_editor.document = this.document;
      }
    } catch (GLib.Error error) {
      this.message(_("Unable to open document at " + path));
    }
  }

  protected void cleanup_layout () {
    GLib.List<weak Gtk.Widget> children = this.layout.get_children();
    foreach (Gtk.Widget element in children) {
      if (element is Editor || element is WelcomeView) {
        this.layout.remove(element);
      }
    }
  }

  protected bool on_key_press (Gdk.EventKey event) {
    if (event.state == Gdk.ModifierType.CONTROL_MASK && event.keyval == 115) {
      debug("Saving");
    }

    return false;
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