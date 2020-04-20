namespace Manuscript {
  public class Header : Gtk.HeaderBar {
    public weak Gtk.Window parent_window { get; construct; }

    public signal void new_file ();
    public signal void open_file ();
    public signal void save_file (bool choose_path);

    protected Gtk.Switch zen_switch;
    protected Gtk.Button settings_button;
    protected Gtk.Button save_file_button;
    protected Gtk.Button save_file_as_button;
    protected SettingsPopover settings_popover;

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
        return document != null && document.has_changes;
      }
    }

    protected Document _document = null;

    public Header (Gtk.Window parent) {
      Object (
        title: Constants.APP_NAME,
        parent_window: parent,
        has_subtitle: true,
        show_close_button: true
      );
    }

    construct {
      AppSettings settings = AppSettings.get_instance ();

      Gtk.Button new_file_button = new Gtk.Button.from_icon_name ("document-new", Gtk.IconSize.LARGE_TOOLBAR);
      new_file_button.tooltip_text = _("New file");
      new_file_button.clicked.connect (() => {
        new_file ();
      });
      pack_start (new_file_button);

      Gtk.Button open_file_button = new Gtk.Button.from_icon_name ("document-open", Gtk.IconSize.LARGE_TOOLBAR);
      open_file_button.tooltip_text = _("Open file");
      open_file_button.clicked.connect (() => {
        open_file ();
      });
      pack_start (open_file_button);

      save_file_button = new Gtk.Button.from_icon_name ("document-save", Gtk.IconSize.LARGE_TOOLBAR);
      save_file_button.tooltip_text = _("Save file");
      save_file_button.clicked.connect (() => {
        save_file (false);
      });
      save_file_button.sensitive = document != null ? has_changes : false;
      pack_start (save_file_button);

      save_file_as_button = new Gtk.Button.from_icon_name ("document-save-as", Gtk.IconSize.LARGE_TOOLBAR);
      save_file_as_button.tooltip_text = _("Save file as");
      save_file_as_button.clicked.connect (() => {
        save_file (true);
      });
      save_file_button.sensitive = document != null ? has_changes : false;
      pack_start (save_file_as_button);

      update_icons ();

      settings_button = new Gtk.Button.from_icon_name ("preferences-system-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
      settings_button.tooltip_text = _("Settings");
      settings_button.clicked.connect (() => {
        if (settings_popover.visible) {
          settings_popover.popdown ();
        } else {
          settings_popover.popup ();
          settings_popover.show_all ();
        }
      });
      pack_end (settings_button);

      zen_switch = new Gtk.Switch ();
      zen_switch.set_vexpand (false);
      zen_switch.set_hexpand (false);
      zen_switch.halign = Gtk.Align.CENTER;
      zen_switch.valign = Gtk.Align.CENTER;
      zen_switch.active = settings.zen;
      zen_switch.state_set.connect (() => {
        update_settings ();
        return false;
      });
      pack_end (zen_switch);

      settings.change.connect ((prop) => {
        update_ui ();
      });

      settings_popover = new SettingsPopover (settings_button);
    }

    protected void update_subtitle () {
      subtitle = document.filename + (has_changes ? " (" + _("modified") + ")" : "");
    }

    protected void update_icons () {
      save_file_button.sensitive = has_changes;
      save_file_as_button.sensitive = has_changes;
    }

    protected void update_ui () {
      AppSettings settings = AppSettings.get_instance ();
      zen_switch.active = settings.zen;
    }

    protected void on_document_change () {
      update_subtitle ();
      update_icons ();
    }

    protected void on_document_saved (string to_path) {
      update_subtitle ();
      update_icons ();
    }

    protected void update_settings () {
      AppSettings settings = AppSettings.get_instance ();
      settings.zen = zen_switch.active;
    }

    protected void load_document () {
      document.change.connect (on_document_change);
      document.saved.connect (on_document_saved);
      document.undo.connect (on_document_change);
      document.redo.connect (on_document_change);
      update_subtitle ();
      update_icons ();
    }
  }
}

