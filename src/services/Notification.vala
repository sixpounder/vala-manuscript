namespace Manuscript.Services {
    public class Notification : Object {
        protected static Application application { get; set; }
        
        public static void init (Application app) {
            application = app;
        }

        public static void show (string title, string? body) {
#if NOTIFICATIONS
            var notification = new GLib.Notification (title);
            if (body != null) {
                notification.set_body (body);
            }
            application.send_notification (Manuscript.Constants.APP_ID, notification);
#endif
        }
    }
}
