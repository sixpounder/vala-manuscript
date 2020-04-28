namespace Manuscript {
    public class Menus : Object {
        private static Menus instance;

        public static Menus get_default () {
            if (Menus.instance == null) {
                Menus.instance = new Menus ();
            }

            return Menus.instance;
        }

        public GLib.Menu main_menu { get; private set; }
        public GLib.Menu create_menu { get; private set; }

        construct {
            main_menu = new GLib.Menu ();
            main_menu.append ("Open", null);

            create_menu = new GLib.Menu ();
            foreach (Models.ChunkType c in Models.ChunkType.all ()) {
                create_menu.append (c.to_string (), null);
            }
        }
    }
}
