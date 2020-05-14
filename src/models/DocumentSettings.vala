namespace Manuscript.Models {
    public class DocumentSettings : Object, Json.Serializable {
        public string font_family { get; set; }
        public int64 font_size { get; set; }
        public double paragraph_spacing { get; set; }

        public DocumentSettings () {
            set_defaults ();
        }

        public DocumentSettings.from_json_object (Json.Object? obj) {
            if (obj != null) {
                font_family = obj.get_string_member ("font_family");
                font_size = obj.get_int_member ("font_size");
                paragraph_spacing = obj.get_double_member ("paragraph_spacing");
            } else {
                set_defaults ();
            }
        }

        public void set_defaults () {
            font_size = 10;
            paragraph_spacing = 20;
            font_family = "iA Writer Duospace";
        }

        public Json.Object to_json_object () {
            var root = new Json.Object ();
            root.set_string_member ("font_family", font_family);
            root.set_int_member ("font_size", font_size);
            root.set_double_member ("paragraph_spacing", paragraph_spacing);

            return root;
        }
    }
}
