namespace Manuscript.Widgets {
    public class QuickOpenEntry: Gtk.ListBoxRow {
        public weak Manuscript.Models.DocumentChunk chunk { get; construct; }
        public bool highlighted { get; set; }
        public string query { get; construct; }

        public QuickOpenEntry (Manuscript.Models.DocumentChunk chunk, string query) {
            Object (
                chunk: chunk,
                query: query,
                highlighted: false,
                activatable: true
            );
        }

        construct {
            assert (chunk != null);

            var grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            grid.homogeneous = true;
            grid.get_style_context ().add_class ("quick-open-entry");

            string title = chunk.title;
            uint index_of_query_start = title.down ().index_of (query.down (), 0);
            uint index_of_query_end = index_of_query_start + query.length;

            string formatted_title = title;

            if (index_of_query_start != -1) {
                string label_start = title.substring (0, index_of_query_start);
                string label_strong = title.substring (index_of_query_start, index_of_query_end - index_of_query_start);
                string label_end = title.substring (index_of_query_end, title.length - index_of_query_end);
                StringBuilder builder = new StringBuilder ();
                builder.printf ("%s<b>%s</b>%s", label_start, label_strong, label_end);
                formatted_title = builder.str;
            }


            var title_label = new Gtk.Label (formatted_title);
            title_label.ellipsize = Pango.EllipsizeMode.END;
            title_label.use_markup = true;
            title_label.lines = 1;
            title_label.max_width_chars = 20;
            title_label.xalign = 0f;
            title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
            grid.pack_start (title_label);

            var kind_label = new Gtk.Label (chunk.kind.to_string ());
            kind_label.justify = Gtk.Justification.RIGHT;
            kind_label.xalign = 1f;
            kind_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
            kind_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
            grid.pack_end (kind_label);

            add (grid);
        }
    }
}
