namespace Manuscript.Widgets {
    public class SearchPanel : Gtk.Revealer {
        public weak Services.AppSettings settings { get; set; }
        public weak Manuscript.Window parent_window { get; construct; }
        public SearchResultsOverlay results_panel { get; private set; }

        public Gtk.Grid grid;
        public Gtk.SearchEntry search_entry;
        public Gtk.SearchEntry replace_entry;
        public Gtk.Button replace_tool_button;
        public Gtk.Button replace_all_tool_button;
        //  public Gtk.TextBuffer? text_buffer = null;
        public Gtk.SourceSearchContext search_context = null;

        public SearchPanel (Manuscript.Window parent_window) {
            Object (
                parent_window: parent_window
            );
        }

        construct {
            valign = Gtk.Align.START;
            vexpand = false;
            hexpand = true;
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;

            settings = Services.AppSettings.get_default ();

            replace_entry = new Gtk.SearchEntry ();
            replace_entry.hexpand = true;
            replace_entry.placeholder_text = _("Replace with…");
            replace_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.PRIMARY, "edit-symbolic");
            //  replace_entry.activate.connect (on_replace_entry_activate);

            replace_tool_button = new Gtk.Button.with_label (_("Replace"));
            //  replace_tool_button.clicked.connect (on_replace_entry_activate);

            replace_all_tool_button = new Gtk.Button.with_label (_("Replace all"));
            //  replace_all_tool_button.clicked.connect (on_replace_all_entry_activate);

            grid = new Gtk.Grid ();
            grid.row_spacing = 6;
            grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);

            //  search_entry_item ();
            search_entry = new Gtk.SearchEntry ();
            search_entry.hexpand = true;
            search_entry.placeholder_text = _("Find…");
            search_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.PRIMARY, "edit-find-symbolic");
            grid.add (search_entry);

            var entry_path = new Gtk.WidgetPath ();
            entry_path.append_type (typeof (Gtk.Widget));

            var entry_context = new Gtk.StyleContext ();
            entry_context.set_path (entry_path);
            entry_context.add_class ("entry");

            search_entry.search_changed.connect (() => {
                //  search ();
            });

            search_entry.key_press_event.connect (on_search_entry_key_press);

            //  search_previous_item ();
            var tool_arrow_up = new Gtk.Button.from_icon_name ("go-up-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            //  tool_arrow_up.clicked.connect (search_previous);
            tool_arrow_up.tooltip_text = _("Search previous");
            
            //  search_next_item ();
            var tool_arrow_down = new Gtk.Button.from_icon_name ("go-down-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            //  tool_arrow_down.clicked.connect (search_next);
            tool_arrow_down.tooltip_text = _("Search next");

            var style_context = grid.get_style_context ();
            style_context.add_class ("searchbar");
            
            grid.add (tool_arrow_up);
            grid.add (tool_arrow_down);
            grid.add (replace_entry);
            grid.add (replace_tool_button);
            grid.add (replace_all_tool_button);

            add (grid);

            //  results_panel = new SearchResultsOverlay ();
            //  child = results_panel;
        }

        private bool on_search_entry_key_press (Gdk.EventKey event) {
            string key = Gdk.keyval_name (event.keyval);
            if (Gdk.ModifierType.SHIFT_MASK in event.state) {
                key = "<Shift>" + key;
            }

            switch (key) {
                case "<Shift>Return":
                case "Up":
                    if (search_entry.text == "") {
                        return false;
                    } else {
                        //  search_previous ();
                        return true;
                    }
                case "Return":
                case "Down":
                    if (search_entry.text == "") {
                        return false;
                    } else {
                        //  search_next ();
                        return true;
                    }
                case "Escape":
                    settings.searchbar = false;
                    return true;
                case "Tab":
                    if (search_entry.is_focus) {
                        replace_entry.grab_focus ();
                    }

                    return true;
            }

            return false;
        }
    }

    public class SearchResultsOverlay : Gtk.Overlay {
        construct {
            Gtk.Grid layout = new Gtk.Grid ();
            layout.halign = Gtk.Align.CENTER;
            layout.valign = Gtk.Align.CENTER;
            layout.expand = true;
        }
    }
}
