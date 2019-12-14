/*-
 * Copyright (c) 2019 Andrea Coronese
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Andrea Coronese <sixpounder@protonmail.com>
 */

public class EditorWindow : Gtk.ApplicationWindow {
  protected uint configure_id = 0;
  protected AppSettings settings;
  protected Gtk.Box layout;
  protected WelcomeView welcome_view;
  protected Header header;
  protected StatusBar status_bar;
  protected Gtk.ScrolledWindow scroll_container;
  protected Document document;
  protected ulong document_load_signal_id;

  public string initial_document_path { get; construct; }

  public Editor current_editor = null;

  public EditorWindow.with_document (Gtk.Application app, string? document_path = null) {
    Object(
      application: app,
      initial_document_path: document_path
    );
  }

  construct {
    settings = AppSettings.get_instance();

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

    layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

    // HEADER
    header = new Header (this);
    header.open_file.connect(() => {
      open_file_dialog ();
    });

    header.save_file.connect(() => {
      document.save ();
    });
    set_titlebar (header);

    // WELCOME VIEW
    welcome_view = new WelcomeView();
    welcome_view.should_open_file.connect (open_file_dialog);
    welcome_view.should_create_new_file.connect (open_with_temp_file);

    scroll_container = new Gtk.ScrolledWindow(null, null);

    layout.pack_start (scroll_container, true, true, 0);

    layout.pack_end (status_bar = new StatusBar (), false, true, 0);

    add (layout);

    key_press_event.connect (on_key_press);
    delete_event.connect (on_destroy);

    if (initial_document_path != null && initial_document_path != "") {
      open_file_at_path (initial_document_path);
    } else {
      set_layout_body (welcome_view);
    }
  }

  public override bool configure_event (Gdk.EventConfigure event) {
    if (configure_id != 0) {
        GLib.Source.remove (configure_id);
    }

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

  /**
   * Shows the open document dialog
   */
  public void open_file_dialog () {
    Gtk.FileChooserDialog dialog = new Gtk.FileChooserDialog(
      _("Open document"),
      (Gtk.Window) get_toplevel(),
      Gtk.FileChooserAction.OPEN,
      _("Cancel"),
      Gtk.ResponseType.CANCEL,
      _("Open"),
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
        open_file_at_path(dialog.get_filename());
      }
    });

    dialog.run();
  }

  public void open_with_temp_file () {
    try {
      File tmp_file = FileUtils.new_temp_file();
      open_file_at_path (tmp_file.get_path(), true);
    } catch (GLib.Error err) {
      message (_("Unable to create temporary document"));
      error (err.message);
    }
  }

  public void open_file_at_path (string path, bool temporary = false) {
    try {
      if (document != null) {
        document.disconnect (document_load_signal_id);
      }
      debug ("Opening " + path);
      document = Document.from_file (path, temporary);
      document_load_signal_id = document.load.connect(() => {
        debug ("Document loaded, initializing view");

        header.document = document;
        status_bar.document = document;

        current_editor = new Editor ();
        current_editor.document = document;

        set_layout_body (current_editor);
        debug ("Layout done");

        settings.last_opened_document = this.document.file_path;
      });

    } catch (GLib.Error error) {
      warning (error.message);
      this.message(_("Unable to open document at " + path));
    }
  }

  protected void cleanup_layout () {
    GLib.List<weak Gtk.Widget> children = this.layout.get_children();
    foreach (Gtk.Widget element in children) {
      if (element is WelcomeView) {
        debug ("Removing welcome view");
        this.layout.remove(element);
      }
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

  protected bool on_key_press (Gdk.EventKey event) {
    if (event.state == Gdk.ModifierType.CONTROL_MASK && event.keyval == 115) {
      if (document.temporary) {
        // Ask where to save this
        FileSaveDialog dialog = new FileSaveDialog (this, document);
        int res = dialog.run ();
        if (res == Gtk.ResponseType.ACCEPT) {
          document.save(dialog.get_filename ());
        }
        dialog.destroy ();
      } else {
        document.save();
      }
    }

    return false;
  }

  protected bool on_destroy () {
    if (this.current_editor != null && this.document.has_changes) {
      return !this.quit_dialog();
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
	  var confirm_dialog = new QuitDialog (this);

    int outcome = confirm_dialog.run ();
    confirm_dialog.destroy ();

    return outcome == 1;
	}
}
