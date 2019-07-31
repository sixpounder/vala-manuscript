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
  protected Gtk.ScrolledWindow scrollContainer;
  protected Document document;

  public Editor current_editor = null;

  public EditorWindow.with_document (Gtk.Application app, string document_path) {
    Object(
      application: app
    );

    if (document_path != null && document_path != "") {
      this.open_file_at_path (document_path);
    } else {
      this.layout.pack_start (this.welcome_view);
    }
  }

  public EditorWindow (Gtk.Application app) {
    Object(
      application: app
    );
  }

  construct {
    this.settings = AppSettings.get_instance();

    int x = settings.window_x;
    int y = settings.window_y;
    if (settings.window_width != -1 || settings.window_height != -1) {
      debug (@"Initializing with size $(settings.window_width)x$(settings.window_height)");
      var rect = Gtk.Allocation ();
      rect.height = settings.window_height;
      rect.width = settings.window_width;
      this.resize (rect.width, rect.height);
    }

    if (x != -1 && y != -1) {
      debug (@"Initializing at $(x) $(y)");
      this.move (x, y);
    }

    this.layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

    // HEADER
    this.header = new Header (this);
    this.header.open_file.connect(() => {
      this.open_file_dialog ();
    });
    this.set_titlebar (header);

    // WELCOME VIEW
    this.welcome_view = new WelcomeView();
    this.welcome_view.should_open_file.connect (this.open_file_dialog);

    this.add (this.layout);

    this.layout.pack_end (this.status_bar = new StatusBar (), false, true, 0);

    this.key_press_event.connect (this.on_key_press);
    this.delete_event.connect (this.on_destroy);
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
      document = Document.from_file (path);
      if (current_editor == null) {
        layout.remove (welcome_view);

        current_editor = new Editor ();
        current_editor.document = document;
        scrollContainer = new Gtk.ScrolledWindow(null, null);
        scrollContainer.add (current_editor);
        layout.pack_start (scrollContainer, true, true, 0);
      }
      current_editor.document = document;
      header.document = document;
      status_bar.document = document;
      settings.last_opened_document = this.document.file_path;

    } catch (GLib.Error error) {
      this.message(_("Unable to open document at " + path));
    }
  }

  protected void cleanup_layout () {
    GLib.List<weak Gtk.Widget> children = this.layout.get_children();
    foreach (Gtk.Widget element in children) {
      if (element is WelcomeView) {
        this.layout.remove(element);
      }
    }
  }

  protected bool on_key_press (Gdk.EventKey event) {
    if (event.state == Gdk.ModifierType.CONTROL_MASK && event.keyval == 115) {
      this.document.save();
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
