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

namespace Manuscript.Utils.Strings {

    /**
     * Returns the string with its first letter capitalized
     */
    public string ucfirst (string in_string = "") {
        if (in_string.length > 0) {
            return @"$(head (in_string).up ())$(tail (in_string))";
        } else {
            return "";
        }
    }

    public string head (string in_string = "") {
        if (in_string.length > 0) {
            return in_string.substring (0, 1);
        } else {
            return "";
        }
    }

    public string tail (string in_string = "") {
        if (in_string.length > 0) {
            return in_string.substring (1, in_string.length - 1);
        } else {
            return "";
        }
    }

    /**
     * Estimates the reading time of a certain amount of words
     * @return {double[]} Two numbers, representing minutes and seconds
     */
    public static double estimate_reading_time (uint words_count) {
        double[] minsecs = { 0, 0 };
        double tmp;
        minsecs[0] = (uint)Math.floor (words_count / 200);
        minsecs[1] = (uint)(Math.modf (words_count / 200, out tmp)) * 0.60;
        return minsecs[0];
    }

    /**
     * Counts words into a string
     */
    public static uint count_words (string buffer = "") {
        uint state = 0;
        uint wc = 0;

        for (var i = 0; i < buffer.length; i++) {
            char c = buffer[i];
            if (c == ' ' || c == '\n' || c == '\t' || c == '\v' || c == '\f' || c == '\r') {
                state = 0;
            } else if (state == 0) {
                state = 1;
                ++wc;
            }
        }

        return wc;
    }

    public static string join (string[] a, string separator = ", ") {
      string o = "";

      for (int i = 0; i < a.length; i++) {
        string s = a[i];
        o += s;
        if (i < a.length - 1) {
          o += separator;
        }
      }

      return o;
    }
}
