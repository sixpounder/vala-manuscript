namespace Manuscript.Services {

    /**
     * A service to use as an application-wide thread pool
     */
    public class ThreadPool : Object {
        private static Services.ThreadPool instance { get; set; }
        private GLib.ThreadPool<ThreadWorker> pool;

        public bool supported {
            get {
                return GLib.Thread.supported ();
            }
        }

        public static Services.ThreadPool get_default () {
            return instance;
        }

        static construct {
            Services.ThreadPool.instance = new Services.ThreadPool ();
        }

        construct {
            if (GLib.Thread.supported ()) {
                try {
                    pool = new GLib.ThreadPool<ThreadWorker>.with_owned_data (
                        (worker) => {
                            on_worker_added (worker);
                        },
                        (int) Manuscript.Utils.Threads.get_thread_number (),
                        false
                    );
                    info ("Thread pool ready");
                } catch (ThreadError e) {
                    pool = null;
                    warning (@"Could not create thread pool: $(e.message)");
                }
            } else {
                pool = null;
                warning ("Threads are not available on this system");
            }
        }

        protected void on_worker_added (ThreadWorker<void*> worker) {
            debug ("Added thread worker");
            var result = worker.worker_run ();
            worker.worker_done (result);
        }
 
        public void add (owned ThreadWorker worker) {
            assert (worker != null);
            if (worker != null) {
                try {
                    pool.add (worker);
                } catch (ThreadError e) {
                    warning (@"Could not add worker to pool: $(e.message)");
                }
            }
        }
    }

    public delegate void ThreadWorkerDoneFn<T> (T returned_data);

    public interface ThreadWorker<T> : Object {
        public abstract T worker_run ();
        public abstract void worker_done (T? result = null);
    }
}
