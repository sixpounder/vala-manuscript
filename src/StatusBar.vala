/*-
 * Copyright (c) 2018 Andrea Coronese
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Andrea Coronese <sixpounder@protonmail.com>
 */


public class StatusBar : Gtk.ActionBar {
  private uint _words_count = 0;
  private double _reading_time = 0;
  protected Gtk.Label words_label;
  protected Gtk.Label reading_time_label;
  protected Gtk.Image reading_time_icon;
  protected Document document = Store.get_instance().current_document;

  construct {
    this.words_label = new Gtk.Label ("0 " + _("words"));
    this.pack_start (words_label);

    this.reading_time_label = new Gtk.Label ("");
    this.reading_time_label.tooltip_text = _("Estimated reading time");
    this.pack_end (reading_time_label);

    this.reading_time_icon = new Gtk.Image ();
    this.reading_time_icon.gicon = new ThemedIcon ("preferences-system-time");
    this.reading_time_icon.pixel_size = 16;
    this.pack_end (reading_time_icon);

    this.words = this.document.words_count;

    this.document.analyze.connect(() => {
      this.words = this.document.words_count;
    });
  }

  public uint words {
    get {
      return _words_count;
    }
    set {
      _words_count = value;
      this.words_label.label = "" + _words_count.to_string () + " " + _("words");
      this.reading_time = this.document.estimate_reading_time;
    }
  }

  public double reading_time {
    get {
      return _reading_time;
    }

    set {
      _reading_time = value;
      reading_time_label.label = format_reading_time(_reading_time);
    }
  }

  private string format_reading_time (double minutes) {
    return minutes == 0
      ?
      "< 1 " + _("minute")
      :
      minutes.to_string () + " " + _("minutes");
  }
}
