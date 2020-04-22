namespace Manuscript.Widgets {
    public class ExportPopover : Gtk.Popover {
        public ExportPopover (Gtk.Widget relative_to) {
            Object (
                relative_to: relative_to
            );
            set_size_request (256, -1);
        }
    }
}
