namespace Manuscript.Compilers {
    public class PDFCompiler : Compiler {
        protected Cairo.PdfSurface surface;

        internal PDFCompiler () {}

        construct {
            surface = new Cairo.PdfSurface (
                filename,
                Manuscript.Constants.A4_WIDHT_IN_POINTS,
                Manuscript.Constants.A4_HEIGHT_IN_POINTS
            );
        }

        public override void compile (Manuscript.Models.Document document) {}
    }
}
