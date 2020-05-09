namespace Manuscript.Models.Conversion {
    public GLib.List<G> to_list<G> (Gee.ArrayList<G> gee_list) {
        var r = new GLib.List<G> ();
        var it = gee_list.iterator ();
        while (it.has_next ()) {
            it.next ();
            r.append (it.@get ());
        }

        return r;
    }

    public G[] list_to_array<G> (List<G> list) {
        var r = new G[list.length ()];
        for (uint i = 0; i < list.length (); i++) {
            r[i] = list.nth_data (i);
        }

        return r;
    }

    public Gee.ArrayList<G> to_array_list<G> (GLib.List<G> list) {
        var r = new Gee.ArrayList<G> ();
        for (uint i = 0; i < list.length (); i++) {
            r.add (list.nth_data (i));
        }

        return r;
    }
}

