namespace Manuscript.Widgets {
    public class SourceListChunkItem : Granite.Widgets.SourceList.Item {
        protected Models.DocumentChunk _chunk;

        public SourceListChunkItem.with_chunk (Models.DocumentChunk chunk) {
            Object (
                chunk: chunk,
                editable: true
            );
        }

        construct {
            edited.connect (on_edited);
        }

        ~ SourceListChunkItem () {
            edited.disconnect (on_edited);
        }

        public Models.DocumentChunk chunk {
            get {
                return _chunk;
            }
            set {
                _chunk = value;
                name = chunk.title;
            }
        }

        private void on_edited (string new_name) {
            chunk.title = new_name;
        }
    }
}
