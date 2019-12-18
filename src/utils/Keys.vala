namespace Manuscript.Utils.Keys {
  #if VALA_0_42
  public bool match_keycode (uint keyval, uint code) {
  #else
  public bool match_keycode (int keyval, uint code) {
  #endif
    Gdk.KeymapKey [] keys;
    Gdk.Keymap keymap = Gdk.Keymap.get_for_display (Gdk.Display.get_default ());
    if (keymap.get_entries_for_keyval (keyval, out keys)) {
      foreach (var key in keys) {
        if (code == key.keycode) {
          return true;
        }
      }
    }
    return false;
  }
}

