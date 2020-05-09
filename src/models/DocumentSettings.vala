namespace Manuscript.Models {
    public enum FontSize {
        SMALL,
        MEDIUM,
        LARGE,
        XLARGE
    }

    public class DocumentSettings : Object, Json.Serializable {
        public string font_family { get; set; }
        public FontSize font_size { get; set; }
        public int paragraph_spacing { get; set; }

        construct {
            // Give em some defaults
            font_size = FontSize.MEDIUM;
            paragraph_spacing = 20;
            font_family = "iA Writer Duospace";
        }
    }
}
