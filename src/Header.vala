public class Header : Gtk.HeaderBar {
  public weak Gtk.Window parent_window { get; construct; }

  public signal void open_file ();
  public signal void save_file ();

  protected Gtk.Switch zen_switch;

  protected Gtk.Button save_file_button;

  public weak Document document {
    get {
      return this._document;
    }

    set {
      this._document = value;
      if (this._document != null) {
        debug (this._document.file_path);
        this._document.change.connect (this.on_document_change);
        this._document.saved.connect (this.on_document_saved);
        this._document.undo.connect (this.on_document_change);
        this._document.redo.connect (this.on_document_change);
      }
      this.update_subtitle();
      this.update_icons();
    }
  }

  protected bool has_changes {
    get {
      return this.document.has_changes;
    }
  }

  protected Document _document = null;
  protected bool _has_changes = false;

  public Header (Gtk.Window parent) {
    Object(
      title: Constants.APP_NAME,
      parent_window: parent,
      has_subtitle: true,
      show_close_button: true
    );

  }

  construct {
    AppSettings settings = AppSettings.get_instance();

    Gtk.Button open_file_button = new Gtk.Button.from_icon_name("document-open");
    open_file_button.tooltip_text = _("Open file");
    open_file_button.clicked.connect(() => {
      open_file ();
    });
    this.pack_start (open_file_button);

    save_file_button = new Gtk.Button.from_icon_name ("document-save");
    save_file_button.tooltip_text = _("Save file");
    save_file_button.clicked.connect(() => {
      save_file ();
    });
    save_file_button.sensitive = this.document != null ? this.has_changes : false;
    this.pack_start (save_file_button);
    update_icons ();

    zen_switch = new Gtk.Switch();
    zen_switch.set_vexpand(false);
    zen_switch.set_hexpand(false);
    zen_switch.halign = Gtk.Align.CENTER;
    zen_switch.valign = Gtk.Align.CENTER;
    zen_switch.active = settings.zen;
    zen_switch.activate.connect(this.update_settings);
    this.pack_end(zen_switch);
  }

  protected void update_subtitle () {
    this.subtitle = this.document.file_path + (this.has_changes ? " (" + _("modified") + ")" : "");
  }

  protected void update_icons () {
    this.save_file_button.sensitive = this.has_changes;
  }

  protected void on_document_change () {
    this.update_subtitle();
    this.update_icons();
  }

  protected void on_document_saved (string to_path) {
    this.update_subtitle();
    this.update_icons();
  }

  protected void update_settings () {
    AppSettings settings = AppSettings.get_instance();
    settings.zen = this.zen_switch.active;
  }
}

