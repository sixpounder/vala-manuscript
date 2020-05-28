namespace Manuscript.Widgets{
    /**
     * Groups all the items relative to a single editor view
     */
    public class EditorView: Granite.Widgets.Tab, Protocols.EditorController {
        public weak Manuscript.Window parent_window { get; construct; }
        public Widgets.StatusBar status_bar { get; set; }
        public Editor editor { get; private set; }
        public Models.DocumentChunk chunk { get; construct; }

        public EditorView (Manuscript.Window parent_window, Models.DocumentChunk chunk) {
            Object (
                parent_window: parent_window,
                chunk: chunk,
                label: chunk.title
            );
        }

        construct {
            assert (chunk != null);
            get_style_context ().add_class ("editor-view");
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            box.expand = true;
            box.homogeneous = false;
            box.halign = Gtk.Align.FILL;
            var scrolled_container = new Gtk.ScrolledWindow (null, null);
            scrolled_container.kinetic_scrolling = true;
            scrolled_container.overlay_scrolling = true;
            scrolled_container.hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
            scrolled_container.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
            scrolled_container.vadjustment.value_changed.connect (() => {
                Gtk.Allocation allocation;
                editor.get_allocation (out allocation);
                status_bar.update_scroll_progress (
                    scrolled_container.vadjustment.value,
                    scrolled_container.vadjustment.lower,
                    scrolled_container.vadjustment.upper - allocation.height
                );
            });
            editor = new Editor (chunk);
            reflect_document_settings ();
            status_bar = new Widgets.StatusBar (parent_window, chunk);
            status_bar.height_request = 50;
            scrolled_container.add (editor);
            box.pack_start (scrolled_container);
            box.pack_start (status_bar, false, true, 0);
            page = box;

            chunk.notify["title"].connect (() => {
                label = chunk.title;
            });

            parent_window.document_manager.document.settings.notify.connect (reflect_document_settings);
        }

        protected void reflect_document_settings () {
            set_font (
                Pango.FontDescription.from_string (
                    parent_window.document_manager.document.settings.font != null
                        ? parent_window.document_manager.document.settings.font
                        : Constants.DEFAULT_FONT
                )
            );
            editor.indent = (int) parent_window.document_manager.document.settings.paragraph_start_padding;
            editor.pixels_below_lines = (int) parent_window.document_manager.document.settings.paragraph_spacing;

        }

        public void set_font (Pango.FontDescription font) {
            editor.override_font (font);
        }
        
        // Editor controller protocol
        public void focus_editor () {
            editor.focus (Gtk.DirectionType.DOWN);
        }

        public bool has_changes () {
            // TODO: return an actually meaningful value
            return false;
        }

        public Protocols.SearchResult[] search (string word) {
            return {};
        }

        public void content_event (Protocols.ContentEvent event) {}

        public Gtk.TextBuffer get_buffer () {
            return chunk.buffer;
        }

        public bool scroll_to_iter (Gtk.TextIter iter, double within_margin, bool use_align, double xalign, double yalign) {
            return editor.scroll_to_iter (iter, within_margin, use_align, xalign, yalign);
        }

        public bool search_for_iter (Gtk.TextIter ? start_iter, out Gtk.TextIter ? end_iter) {
            return editor.search_for_iter (start_iter, out end_iter);
        }

        public bool search_for_iter_backward (Gtk.TextIter ? start_iter, out Gtk.TextIter ? end_iter) {
            return editor.search_for_iter_backward (start_iter, out end_iter);
        }
    }
}
