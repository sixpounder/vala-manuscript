namespace Manuscript.Services {
    
    public class ActionManager : Object {
        private static ActionManager instance;
        
        public static ActionManager get_default () {
            if (instance == null) {
                instance = new ActionManager ();
            }

            return instance;
        }

        public static Gee.MultiMap<string, string> action_accels = new Gee.HashMultiMap<string, string> ();

        public const string ACTION_PREFIX = "win.";

        static construct {
            action_accels.set ("action_open", "<Control>o");
            action_accels.set ("action_save", "<Control>s");
        }
    }
    
}
