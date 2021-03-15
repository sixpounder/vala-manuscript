namespace Manuscript.Widgets {
    public class CoverCanvas : Gtk.AspectFrame {
        protected const float RATIO =
            Manuscript.Constants.A4_WIDHT_IN_POINTS / Manuscript.Constants.A4_HEIGHT_IN_POINTS;

        public CoverCanvas (string? label) {
            Object (
                label,
                .5f,
                .5f,
                RATIO,
                false
            );
        }
    }
}
