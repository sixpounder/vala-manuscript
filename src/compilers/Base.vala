namespace Manuscript.Compilers {
    public class Compiler : Object {
        public string filename { get; construct; }

        public Compiler (string filename) {
            Object (
                filename: filename
            )
        }

        public abstract void compile (Manuscript.Models.Document document) {}
    }
}
