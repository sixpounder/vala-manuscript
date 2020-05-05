namespace Manuscript.Models {
    public struct ChunkTypeIconInfo {
        public string? name;
    }

    public enum ChunkType {
        COVER,
        CHAPTER,
        CHARACTER_SHEET,
        NOTE;

        public string to_string () {
            switch (this) {
                case COVER:
                    return "Cover";
                case CHAPTER:
                    return "Chapter";
                case CHARACTER_SHEET:
                    return "Character Sheet";
                case NOTE:
                    return "Note";
                default:
                    assert_not_reached ();
            }
        }

        public ChunkTypeIconInfo to_icon_info (bool symbolic = true) {
            ChunkTypeIconInfo icon_info = ChunkTypeIconInfo () {
                name = ""
            };

            switch (this) {
                case COVER:
                    icon_info.name = "image-x-generic";
                    break;
                case CHAPTER:
                    icon_info.name = "insert-text";
                    break;
                case CHARACTER_SHEET:
                    icon_info.name = "avatar-default";
                    break;
                case NOTE:
                    icon_info.name = "note";
                    break;
                default:
                    assert_not_reached ();
            }

            if (symbolic) {
                icon_info.name = @"$(icon_info.name)-symbolic";
            }

            return icon_info;
        }

        public string to_icon_name (bool symbolic = true) {
            return this.to_icon_info (symbolic).name;
        }

        public Gtk.Image to_icon (int size = 24, bool symbolic = true) {
            string icon_name = this.to_icon_name ();
            var icon = new Gtk.Image ();
            icon.gicon = new ThemedIcon (icon_name);
            icon.pixel_size = size;

            return icon;
        }

        public static ChunkType[] all () {
            return { CHAPTER, CHARACTER_SHEET, NOTE };
        }
    }
}
