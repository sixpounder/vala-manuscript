namespace Manuscript {
    public class Sidebar : Gtk.StackSidebar {
        protected Models.Document _document;

        public Sidebar () {
        }

        public Models.Document document {
            get {
                return _document;
            }

            set {
                _document = document;
                update ();
            }
        }

        public void update () {}
    }
}
