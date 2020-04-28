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

        public static ChunkType[] all () {
            return { CHAPTER, CHARACTER_SHEET };
        }
    }
}
