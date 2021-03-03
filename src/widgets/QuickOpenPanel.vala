namespace Manuscript.Widgets {
    public class QuickOpenPanel: Gtk.Box {
        protected Gtk.Entry query_input;
        construct {
            orientation = Gtk.Orientation.VERTICAL;
            homogeneous = false;
            valign = Gtk.Align.FILL;
            halign = Gtk.Align.CENTER;
            expand = true;
            width_request = 500;

            get_style_context ().add_class ("quick-open-panel");

            query_input = new Gtk.Entry ();
            query_input.valign = Gtk.Align.START;
            query_input.placeholder_text = _("Type to quick open");

            pack_start (query_input);

            show.connect (on_show);

            show_all ();
        }

        protected void on_show () {
            query_input.grab_focus ();
        }
    }
}
