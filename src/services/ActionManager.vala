namespace Manuscript.Services {

    public class ActionManager : Object {
        public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

        public const string ACTION_PREFIX = "win.";
        public const string ACTION_NEW_WINDOW = "action_new_window";
        public const string ACTION_OPEN = "action_open";
        public const string ACTION_SAVE = "action_save";
        public const string ACTION_SAVE_AS = "action_save_as";
        public const string ACTION_QUIT = "action_quit";

        public const string ACTION_ADD_CHAPTER = "action_add_chapter";
        public const string ACTION_ADD_CHARACTER_SHEET = "action_add_character_sheet";
        public const string ACTION_ADD_NOTE = "action_add_note";
        public const string ACTION_IMPORT = "action_import";

        private const ActionEntry[] ACTION_ENTRIES = {
            { ACTION_NEW_WINDOW, action_new_window },
            { ACTION_OPEN, action_open },
            { ACTION_SAVE, action_save },
            { ACTION_SAVE_AS, action_save_as },
            { ACTION_QUIT, action_quit },

            { ACTION_ADD_CHAPTER, action_add_chapter },
            { ACTION_ADD_CHARACTER_SHEET, action_add_character_sheet },
            { ACTION_ADD_NOTE, action_add_note },
            { ACTION_IMPORT, action_import }
        };

        public weak Manuscript.Application application { get; construct; }
        public weak Manuscript.Window window { get; construct; }

        public SimpleActionGroup actions { get; construct; }

        static construct {
            action_accelerators.set (ACTION_OPEN, "<Control>o");
            action_accelerators.set (ACTION_SAVE, "<Control>s");
            action_accelerators.set (ACTION_SAVE_AS, "<Control><Shift>s");
            action_accelerators.set (ACTION_QUIT, "<Control>q");
            action_accelerators.set (ACTION_ADD_CHAPTER, "<Alt>1");
            action_accelerators.set (ACTION_ADD_CHARACTER_SHEET, "<Alt>2");
            action_accelerators.set (ACTION_ADD_NOTE, "<Alt>3");
        }

        public ActionManager (Manuscript.Application app, Manuscript.Window window) {
            Object (
                application: app,
                window: window
            );
        }


        construct {
            actions = new SimpleActionGroup ();
            actions.add_action_entries (ACTION_ENTRIES, this);
            window.insert_action_group ("win", actions);

            foreach (var action in action_accelerators.get_keys ()) {
                application.set_accels_for_action (ACTION_PREFIX + action, action_accelerators[action].to_array ());
            }
        }

        protected void action_new_window () {}

        protected void action_open () {
            window.open_file_dialog ();
        }

        protected void action_save () {}

        protected void action_save_as () {}

        protected void action_quit () {
            if (window != null) {
                window.close ();
            }
        }

        protected void action_add_chapter () {}
        protected void action_add_character_sheet () {}
        protected void action_add_note () {}
        protected void action_import () {}
    }
}
