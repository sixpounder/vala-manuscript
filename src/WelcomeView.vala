namespace Manuscript {
    public class WelcomeView : Gtk.Grid {
        public signal void should_open_file ();
        public signal void should_create_new_file ();

        construct {
            var welcome =
                new Granite.Widgets.Welcome (
                    _("Welcome to " + Constants.APP_NAME), _("Distraction free writing environment")
                );
            welcome.append ("document-new", _("New manuscript"), _("Create a new empty manuscript"));
            welcome.append ("document-open", _("Open"), _("Open an existing manuscript"));

            add (welcome);

            welcome.activated.connect ((index) => {
                switch (index) {
                    case 0:
                        this.should_create_new_file ();
                        break;
                    case 1:
                        this.should_open_file ();
                        break;
                }
            });
        }
    }
}
