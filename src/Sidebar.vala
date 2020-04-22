namespace Manuscript {
    public class Sidebar : Gtk.StackSidebar {
        protected Document _document;

        public Sidebar () {
        }

        public Document document {
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
