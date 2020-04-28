namespace Manuscript.Models {
    public enum ChunkType {
        CHAPTER,
        CHARACTER_SHEET;

        public string to_string () {
            switch (this) {
                case CHAPTER:
                    return "Chapter";
                case CHARACTER_SHEET:
                    return "Character Sheet";
                default:
                    assert_not_reached ();
            }
        }

        public Gtk.Image to_icon (int size = 24, bool symbolic = true) {
            string icon_name;
            switch (this) {
                case CHAPTER:
                    icon_name = "insert-text";
                    break;
                case CHARACTER_SHEET:
                    icon_name = "avatar-default";
                    break;
                default:
                    assert_not_reached ();
            }

            if (symbolic) {
                icon_name = @"$icon_name-symbolic";
            }

            var icon = new Gtk.Image ();
            icon.gicon = new ThemedIcon (icon_name);
            icon.pixel_size = size;

            return icon;
        }

        public static ChunkType[] all () {
            return { CHAPTER, CHARACTER_SHEET };
        }
    }
}
