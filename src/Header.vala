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
      _document = value;
      if (_document != null) {
        if (_document.load_state == DocumentLoadState.LOADED) {
          load_document ();
        } else {
          _document.load.connect (load_document);
        }
      }
    }
  }

  protected bool has_changes {
    get {
      return document.has_changes;
    }
  }

  protected Document _document = null;

  public Header (Gtk.Window parent) {
    Object(
      title: Constants.APP_NAME,
      parent_window: parent,
      has_subtitle: true,
      show_close_button: true
    );
  }

  construct {
    AppSettings settings = AppSettings.get_instance ();

    Gtk.Button open_file_button = new Gtk.Button.from_icon_name ("document-open");
    open_file_button.tooltip_text = _("Open file");
    open_file_button.clicked.connect(() => {
      open_file ();
    });
    pack_start (open_file_button);

    save_file_button = new Gtk.Button.from_icon_name ("document-save");
    save_file_button.tooltip_text = _("Save file");
    save_file_button.clicked.connect(() => {
      save_file ();
    });
    save_file_button.sensitive = document != null ? has_changes : false;
    pack_start (save_file_button);
    update_icons ();

    zen_switch = new Gtk.Switch();
    zen_switch.set_vexpand (false);
    zen_switch.set_hexpand (false);
    zen_switch.halign = Gtk.Align.CENTER;
    zen_switch.valign = Gtk.Align.CENTER;
    zen_switch.active = settings.zen;
    zen_switch.activate.connect (update_settings);
    pack_end (zen_switch);
  }

  protected void update_subtitle () {
    subtitle = document.file_path + (has_changes ? " (" + _("modified") + ")" : "");
  }

  protected void update_icons () {
    save_file_button.sensitive = has_changes;
  }

  protected void on_document_change () {
    update_subtitle ();
    update_icons ();
  }

  protected void on_document_saved (string to_path) {
    update_subtitle();
    update_icons();
  }

  protected void update_settings () {
    AppSettings settings = AppSettings.get_instance();
    settings.zen = zen_switch.active;
  }

  protected void load_document () {
    document.change.connect (on_document_change);
    document.saved.connect (on_document_saved);
    document.undo.connect (on_document_change);
    document.redo.connect (on_document_change);
    update_subtitle();
    update_icons();
  }
}

