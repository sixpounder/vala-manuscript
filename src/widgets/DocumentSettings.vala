namespace Manuscript.Widgets {
    public class DocumentSettings : Gtk.Box {

        //  public Manuscript.Window parent_window { get; set; }
        public Gtk.Stack settings_views { get; private set; }

        public DocumentSettings () {
            Object (
                orientation: Gtk.Orientation.VERTICAL
            );
        }

        construct {
            settings_views = new Gtk.Stack ();
            settings_views.get_style_context ().add_class ("horizontal linked stack-switcher");
            settings_views.add_titled (new Gtk.Grid (), "general", _("General"));
            settings_views.add_titled (new Gtk.Grid (), "metrics", _("Fonts & Metrics"));

            Gtk.StackSwitcher view_switchers = new Gtk.StackSwitcher ();
            view_switchers.orientation = Gtk.Orientation.HORIZONTAL;
            view_switchers.margin_start = 50;
            view_switchers.margin_end = 50;
            view_switchers.expand = false;
            view_switchers.halign = Gtk.Align.CENTER;
            view_switchers.valign = Gtk.Align.START;
            view_switchers.stack = settings_views;

            pack_start (view_switchers);
            pack_start (settings_views);
            show_all ();
        }
    }
}
