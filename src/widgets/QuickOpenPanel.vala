namespace Manuscript.Widgets {
    public class QuickOpenPanel: Gtk.Frame {
        public virtual signal void action (Manuscript.Models.DocumentChunk? chunk) {
            hide ();
        }

        public Manuscript.Services.DocumentManager document_manager { get; construct; }
        protected uint search_timer_id = 0;
        protected Gtk.Entry query_input;
        protected Gtk.ListBox results_grid;

        public QuickOpenPanel (Manuscript.Services.DocumentManager document_manager) {
            Object (
                document_manager: document_manager,
                label: _("Quick open"),
                width_request: 500,
                expand: false,
                halign: Gtk.Align.CENTER,
                valign: Gtk.Align.START,
                shadow_type: Gtk.ShadowType.ETCHED_OUT
            );
        }

        construct {
            var style_context = get_style_context ();
            style_context.add_class ("quick-open-panel");

            var box = new Gtk.Box (Gtk.Align.VERTICAL, 0);
            box.orientation = Gtk.Orientation.VERTICAL;
            box.homogeneous = true;
            box.halign = Gtk.Align.FILL;
            box.valign = Gtk.Align.START;
            box.expand = true;


            query_input = new Gtk.Entry ();
            query_input.valign = Gtk.Align.START;
            query_input.placeholder_text = _("Type to search");

            box.pack_start (query_input);

            results_grid = new Gtk.ListBox ();
            results_grid.no_show_all = true;
            results_grid.selection_mode = Gtk.SelectionMode.SINGLE;

            box.pack_start (results_grid);

            connect_events ();
            
            add (box);
            show_all ();
        }
        
        protected void connect_events () {
            show.connect (on_show);
            key_press_event.connect (on_key_pressed);
            query_input.key_press_event.connect (on_key_pressed);
            query_input.changed.connect (on_query_change);
        }

        protected bool on_key_pressed (Gdk.EventKey event) {
            if (event.keyval == Gdk.Key.Escape) {
                action (null);
                return true;
            } else if (event.keyval == Gdk.Key.Return) {
                debug ("Return");
                action (null);
                return true;
            } else if (event.keyval == Gdk.Key.downarrow) {
                debug ("Next result");
                action (null);
                return true;
            } else if (event.keyval == Gdk.Key.uparrow) {
                debug ("Previous result");
                action (null);
                return true;
            } else {
                return false;
            }
        }

        protected void on_query_change () {
            if (search_timer_id != 0) {
                GLib.Source.remove (search_timer_id);
            }
            search_timer_id = Timeout.add (Manuscript.Constants.QUICK_SEARCH_DEBOUNCE_TIME, () => {
                search_timer_id = 0;
                search ();
                return false;
            });
        }

        protected void on_show () {
            query_input.grab_focus ();
        }

        protected void search () {
            string word = query_input.text;
            if (word.length != 0) {
                word = word.down();
                var chunks = document_manager.document.chunks;
                if (chunks != null) {
                    debug (@"Searching for $(word)");
                    var results_buffer = chunks.filter ((item) => {
                        return item.title.down().contains (word);
                    });
                    build_results_interface_from_iterator (results_buffer);
                }
            } else {
                reset_results_interface ();
            }
        }

        protected void reset_results_interface () {
            results_grid.@foreach ((child) => {
                results_grid.remove (child);
            });
        }

        protected void build_results_interface_from_iterator (owned Gee.Iterator<Manuscript.Models.DocumentChunk> iter) {
            reset_results_interface ();
            uint i = 0;
            while (iter.has_next ()) {
                iter.next();
                var item = iter.@get ();
                var widget = new Manuscript.Widgets.QuickOpenEntry (item);
                i++;
            }

            if (i > 0) {
                results_grid.show ();
            } else {
                results_grid.hide ();
            }

            debug(@"$(i) results shown");
        }
    }
}
