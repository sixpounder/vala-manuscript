namespace Manuscript.Services {

    public class ActionManager : Object {
        public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

        public const string ACTION_PREFIX = "win.";
        public const string ACTION_NEW_WINDOW = "action_new_window";
        public const string ACTION_OPEN = "action_open";
        public const string ACTION_SAVE = "action_save";
        public const string ACTION_SAVE_AS = "action_save_as";
        public const string ACTION_DOCUMENT_SETTINGS = "action_document_settings";
        public const string ACTION_CLOSE_DOCUMENT = "action_close_document";
        public const string ACTION_QUIT = "action_quit";

        public const string ACTION_FIND = "action_find";

        public const string ACTION_ADD_CHAPTER = "action_add_chapter";
        public const string ACTION_ADD_CHARACTER_SHEET = "action_add_character_sheet";
        public const string ACTION_ADD_COVER = "action_add_cover";
        public const string ACTION_ADD_NOTE = "action_add_note";
        public const string ACTION_IMPORT = "action_import";

        private const ActionEntry[] ACTION_ENTRIES = {
            { ACTION_NEW_WINDOW, action_new_window },
            { ACTION_OPEN, action_open },
            { ACTION_SAVE, action_save },
            { ACTION_SAVE_AS, action_save_as },
            { ACTION_DOCUMENT_SETTINGS, action_document_settings },
            { ACTION_CLOSE_DOCUMENT, action_close_document },
            { ACTION_QUIT, action_quit },

            { ACTION_FIND, action_find },

            { ACTION_ADD_CHAPTER, action_add_chapter },
            { ACTION_ADD_CHARACTER_SHEET, action_add_character_sheet },
            { ACTION_ADD_COVER, action_add_cover },
            { ACTION_ADD_NOTE, action_add_note },
            { ACTION_IMPORT, action_import }
        };

        public weak Manuscript.Application application { get; construct; }
        public weak Manuscript.Window window { get; construct; }
        public weak Manuscript.Services.AppSettings settings { get; private set; }
        public SimpleActionGroup actions { get; construct; }

        public ActionManager (Manuscript.Application app, Manuscript.Window window) {
            Object (
                application: app,
                window: window
            );
        }

        static construct {
            action_accelerators.set (ACTION_NEW_WINDOW, "<Control>n");
            action_accelerators.set (ACTION_OPEN, "<Control>o");
            action_accelerators.set (ACTION_SAVE, "<Control>s");
            action_accelerators.set (ACTION_SAVE_AS, "<Control><Shift>s");
            action_accelerators.set (ACTION_DOCUMENT_SETTINGS, "<Control>comma");
            action_accelerators.set (ACTION_CLOSE_DOCUMENT, "<Control><alt>c");
            action_accelerators.set (ACTION_FIND, "<Control>f");
            action_accelerators.set (ACTION_QUIT, "<Control>q");
            action_accelerators.set (ACTION_ADD_CHAPTER, "<Alt>1");
            action_accelerators.set (ACTION_ADD_CHARACTER_SHEET, "<Alt>2");
            action_accelerators.set (ACTION_ADD_COVER, "<Alt>3");
            action_accelerators.set (ACTION_ADD_NOTE, "<Alt>4");
        }

        construct {
            settings = Services.AppSettings.get_default ();
            actions = new SimpleActionGroup ();
            actions.add_action_entries (ACTION_ENTRIES, this);
            window.insert_action_group ("win", actions);

            foreach (var action in action_accelerators.get_keys ()) {
                application.set_accels_for_action (ACTION_PREFIX + action, action_accelerators[action].to_array ());
            }
        }

        protected void action_new_window () {
            application.new_window ();
        }

        protected void action_open () {
            window.open_file_dialog ();
        }

        protected void action_save () {
            window.document_manager.save ();
        }

        protected void action_save_as () {
            window.document_manager.save_as ();
        }

        protected void action_quit () {
            if (window != null) {
                window.close ();
            }
        }

        protected void action_find () {
            if (settings.searchbar == false) {
                debug ("Searchbar on");
                settings.searchbar = true;
            } else {
                debug ("Searchbar off");
                settings.searchbar = false;
            }
        }

        protected void action_add_chapter () {
            window.document_manager.document.add_chunk (
                new Models.DocumentChunk.empty (Models.ChunkType.CHAPTER)
            );
        }

        protected void action_add_character_sheet () {
            window.document_manager.document.add_chunk (
                new Models.DocumentChunk.empty (Models.ChunkType.CHARACTER_SHEET)
            );
        }

        protected void action_add_cover () {
        }

        protected void action_add_note () {
            window.document_manager.document.add_chunk (
                new Models.DocumentChunk.empty (Models.ChunkType.NOTE)
            );
        }

        protected void action_document_settings () {
            window.show_document_settings ();
        }

        protected void action_close_document () {
            window.document_manager.set_current_document (null);
        }

        protected void action_import () {}
    }
}
