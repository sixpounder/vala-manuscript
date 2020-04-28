namespace Manuscript.Mathz {
    public int max (int val1, ...) {
        int max = val1;
        var list = va_list ();
        for (int? v = list.arg<int?> (); v != null ; v = list.arg<int?> ()) {
            max = max > v ? max :v;
        }

        return max;
    }

    public double fmax (double val1, ...) {
        var l = va_list ();
        double max = val1;
        while (true) {
            double? v = l.arg ();
            if (v == null) {
                break;
            }
            if (v > max) {
                max = v;
            }
        }

        return max;
    }
}
