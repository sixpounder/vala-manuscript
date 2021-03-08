namespace Manuscript.Compilers {
    public abstract class Compiler : Object {
        public string filename { get; construct; }

        public static Compiler for_format (Manuscript.Models.ExportFormat format) {
            switch (format) {
                case Manuscript.Models.ExportFormat.PDF:
                    return new PDFCompiler ();
                case Manuscript.Models.ExportFormat.MARKDOWN:
                    return new MarkdownCompiler ();
                default:
                    assert_not_reached ();
            }
        }

        public abstract void compile (Manuscript.Models.Document document);
    }
}
