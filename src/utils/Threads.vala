namespace Manuscript.Utils.Threads {

    /**
     * Gets the ideal max number of threads that can be run on the
     * current system
     */
    public uint get_thread_number () {
        uint concurrency = get_num_processors () - 1;
        if (concurrency <= 0) {
            // Single CPU env? In 2021?
            concurrency = 1;
        }

        return concurrency;
    }
}
