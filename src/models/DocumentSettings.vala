namespace Manuscript.Models {
    public class DocumentSettings : Object, Json.Serializable {
        public string font { get; set; }
        public double paragraph_spacing { get; set; }
        public double paragraph_start_padding { get; set; }

        public DocumentSettings () {
            set_defaults ();
        }

        public DocumentSettings.from_json_object (Json.Object? obj) {
            if (obj != null) {
                font = obj.get_string_member ("font");
                paragraph_spacing = obj.get_double_member ("paragraph_spacing");
                paragraph_start_padding = obj.get_double_member ("paragraph_start_padding");
            } else {
                set_defaults ();
            }
        }

        public void set_defaults () {
            paragraph_spacing = 20;
            paragraph_start_padding = 10;
            font = Constants.DEFAULT_FONT;
        }

        public Json.Object to_json_object () {
            var root = new Json.Object ();
            root.set_string_member ("font", font);
            root.set_double_member ("paragraph_spacing", paragraph_spacing);
            root.set_double_member ("paragraph_start_padding", paragraph_start_padding);

            return root;
        }
    }
}
