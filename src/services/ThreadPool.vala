/*
 * Copyright 2021 Andrea Coronese <sixpounder@protonmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Manuscript.Services {

    /**
     * A service to use as an application-wide thread pool
     */
    public class ThreadPool : Object {
        private static Services.ThreadPool instance { get; set; }
        private GLib.ThreadPool<ThreadWorker> pool;

        public static bool supported {
            get {
                return GLib.Thread.supported ();
            }
        }

        public static Services.ThreadPool get_default () {
            if (Services.ThreadPool.instance == null) {
                Services.ThreadPool.instance = new Services.ThreadPool ();
            }

            return instance;
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
            debug (@"Added thread worker to _$(worker.get_group ())_ group");
            var result = worker.worker_run ();
            GLib.MainContext.get_thread_default ().invoke (() => {
                worker.done (result);
                return GLib.Source.REMOVE;
            });
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

    public delegate void ThreadWorkerFn<T> (T returned_data);

    public interface ThreadWorker<T> : Object {
        public virtual string get_name () {
            return "worker";
        }

        public virtual string get_group () {
            return "default";
        }

        public abstract T worker_run ();
        public virtual signal void done (T? result = null) {}
    }
}
