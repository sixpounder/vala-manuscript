namespace Manuscript {
  public class EditorWindow : Gtk.ApplicationWindow {
    protected uint configure_id = 0;
    protected AppSettings settings;
    protected Gtk.Box layout;
    protected WelcomeView welcome_view;
    protected Header header;
    protected StatusBar status_bar;
    protected SearchBar search_bar;
    protected Gtk.ScrolledWindow scroll_container;
    protected Document document;
    protected ulong document_load_signal_id;
    protected ulong document_error_signal_id;

    public string initial_document_path { get; construct; }

    public Editor current_editor = null;

    public EditorWindow.with_document (Gtk.Application app, string? document_path = null) {
      Object (
        application: app,
        initial_document_path: document_path
      );
    }

    construct {
      settings = AppSettings.get_instance ();

      // Load some styles
      var css_provider = new Gtk.CssProvider ();
      css_provider.load_from_resource ("/com/github/sixpounder/manuscript/main.css");
      Gtk.StyleContext.add_provider_for_screen (screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

      // Position and resize window according to last settings
      int x = settings.window_x;
      int y = settings.window_y;
      if (settings.window_width != -1 || settings.window_height != -1) {
        var rect = Gtk.Allocation ();
        rect.height = settings.window_height;
        rect.width = settings.window_width;
        resize (rect.width, rect.height);
      }

      if (x != -1 && y != -1) {
        move (x, y);
      }

      // Main layout container
      layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

      // Setup header
      header = new Header (this);
      set_titlebar (header);

      // Setup welcome view
      welcome_view = new WelcomeView ();

      current_editor = new Editor ();
      configure_searchbar ();

      // Scrolled window element
      scroll_container = new Gtk.ScrolledWindow (null, null);
      layout.pack_start (scroll_container, true, true, 0);

      // Status bar (bottom)
      layout.pack_end (status_bar = new StatusBar (), false, true, 0);

      add (layout);

      connect_events ();
      configure_key_events ();

      // Lift off
      if (initial_document_path != null && initial_document_path != "") {
        open_file_at_path (initial_document_path);
      } else {
        set_layout_body (welcome_view);
      }
    }

    public void connect_events () {
      delete_event.connect (on_destroy);

      header.open_file.connect (() => {
        if (this.document != null && document.has_changes) {
          if (quit_dialog ()) {
            open_file_dialog ();
          }
        } else {
          open_file_dialog ();
        }
      });

      header.save_file.connect ((choose_path) => {
        if (choose_path) {
          var dialog = new FileSaveDialog (this, document);
          int res = dialog.run ();
          if (res == Gtk.ResponseType.ACCEPT) {
            document.save (dialog.get_filename ());
            settings.last_opened_document = this.document.file_path;
          }
          dialog.destroy ();
        } else {
          document.save ();
        }
      });

      welcome_view.should_open_file.connect (open_file_dialog);
      welcome_view.should_create_new_file.connect (open_with_temp_file);
    }

    public void configure_searchbar () {
      search_bar = new SearchBar (this, current_editor);
      layout.pack_start (search_bar, false, false, 0);
      settings.change.connect ((k) => {
        if (k == "searchbar") {
          show_searchbar ();
        }
      });
    }

    public bool configure_key_events () {
      key_press_event.connect ((e) => {
        uint keycode = e.hardware_keycode;

        if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
          if (Manuscript.Utils.Keys.match_keycode (Gdk.Key.f, keycode)) {
            if (settings.searchbar == false) {
              debug ("Searchbar on");
              settings.searchbar = true;
            } else {
              debug ("Searchbar off");
              settings.searchbar = false;
            }
          } else if (Manuscript.Utils.Keys.match_keycode (Gdk.Key.s, keycode)) {
            if (document.temporary) {
              // Ask where to save this
              var dialog = new FileSaveDialog (this, document);
              int res = dialog.run ();
              if (res == Gtk.ResponseType.ACCEPT) {
                document.save (dialog.get_filename ());
              }
              dialog.destroy ();
            } else {
              document.save ();
            }
          }
        }

        return false;
      });

      return false;
    }

    public override bool configure_event (Gdk.EventConfigure event) {
      if (configure_id != 0) {
          GLib.Source.remove (configure_id);
      }

      // Avoid trashing the disc
      configure_id = Timeout.add (100, () => {
        configure_id = 0;

        int height, width;
        this.get_size (out width, out height);
        settings.window_width = width;
        settings.window_height = height;

        int root_x, root_y;
        this.get_position (out root_x, out root_y);
        settings.window_x = root_x;
        settings.window_y = root_y;

        return false;
      });

      return base.configure_event (event);
    }

    public void show_searchbar () {
      debug ("Showing searchbar");
      search_bar.reveal_child = settings.searchbar;
      if (settings.searchbar == true) {
        search_bar.search_entry.grab_focus_without_selecting ();
      }
    }

    /**
     * Shows the open document dialog
     */
    public void open_file_dialog () {
      Gtk.FileChooserDialog dialog = new Gtk.FileChooserDialog (
        _("Open document"),
        (Gtk.Window) get_toplevel (),
        Gtk.FileChooserAction.OPEN,
        _("Cancel"),
        Gtk.ResponseType.CANCEL,
        _("Open"),
        Gtk.ResponseType.ACCEPT
      );

      Gtk.FileFilter text_file_filter = new Gtk.FileFilter ();
      text_file_filter.add_mime_type ("text/plain");
      text_file_filter.add_mime_type ("text/markdown");
      text_file_filter.add_pattern ("*.txt");
      text_file_filter.add_pattern ("*.md");

      dialog.add_filter (text_file_filter);

      dialog.response.connect ((res) => {
        dialog.hide ();
        if (res == Gtk.ResponseType.ACCEPT) {
          open_file_at_path (dialog.get_filename ());
        }
      });

      dialog.run ();
    }

    // Like open_file_at_path, but with a temporary file
    public void open_with_temp_file () {
      try {
        File tmp_file = FileUtils.new_temp_file ();
        open_file_at_path (tmp_file.get_path (), true);
      } catch (GLib.Error err) {
        message (_("Unable to create temporary document"));
        error (err.message);
      }
    }

    // Opens file at path and sets up the editor
    public void open_file_at_path (string path, bool temporary = false) {
      try {
        if (document != null) {
          document.disconnect (document_load_signal_id);
          document.disconnect (document_error_signal_id);
        }
        debug ("Opening " + path);
        document = Document.from_file (path, temporary);
        if (document == null) {
          warning ("File not found");
          show_not_found_alert ();
        } else {
          document_error_signal_id = document.read_error.connect (show_not_found_alert);
          document_load_signal_id = document.load.connect (() => {
            debug ("Document loaded, initializing view");

            header.document = document;
            status_bar.document = document;

            current_editor.document = document;

            set_layout_body (current_editor);
            debug ("Layout done");

            settings.last_opened_document = this.document.file_path;
          });
        }

      } catch (GLib.Error error) {
        warning (error.message);
        this.message (_("Unable to open document at " + path));
      }
    }

    protected void set_layout_body (Gtk.Widget widget) {
      if (scroll_container.get_child () != null) {
        scroll_container.remove (scroll_container.get_child ());
      }
      scroll_container.add (widget);
      widget.show_all ();
      widget.focus (Gtk.DirectionType.UP);
    }

    protected bool on_destroy () {
      if (this.current_editor != null && this.document.has_changes) {
        return !this.quit_dialog ();
      } else {
        return false;
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

    protected bool quit_dialog () {
      QuitDialog confirm_dialog = new QuitDialog (this);

      int outcome = confirm_dialog.run ();
      confirm_dialog.destroy ();

      return outcome == 1;
    }

    protected void show_not_found_alert () {
      FileNotFound fnf = new FileNotFound (document.file_path);
      fnf.show_all ();
      set_layout_body (fnf);
    }
  }
}

