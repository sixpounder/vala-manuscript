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
        public int64 paragraph_spacing { get; set; }

        public DocumentSettings.from_json_object (Json.Object? obj) {
            if (obj != null) {
                font_family = obj.get_string_member ("font_family");
                font_size = (Manuscript.Models.FontSize) obj.get_int_member ("font_size");
                paragraph_spacing = obj.get_int_member ("paragraph_spacing");
            } else {
                font_size = FontSize.MEDIUM;
                paragraph_spacing = 20;
                font_family = "iA Writer Duospace";
            }
        }
    }
}
