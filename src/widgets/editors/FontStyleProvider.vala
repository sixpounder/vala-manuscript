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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Manuscript.Widgets {
    public class FontStyleProvider : Gtk.CssProvider {
        private static FontStyleProvider? _instance = null;
        public weak Manuscript.Services.AppSettings settings { get; construct; }

        internal FontStyleProvider (Manuscript.Services.AppSettings settings) {
            Object (
                settings: settings
            );
        }

        construct {
            var use_font = Constants.DEFAULT_FONT_FAMILY;
            var use_size = Constants.DEFAULT_FONT_SIZE;
            var scale_factor = settings == null ? 1 : settings.text_scale_factor;

            try {
                load_from_data (@"
                    .manuscript-text-editor {
                        font-family: $(use_font);
                        font-size: $(use_size * scale_factor)pt;
                    }
                ");
            } catch (Error e) {
                warning (e.message);
            }
        }


        public new static FontStyleProvider get_default (Manuscript.Services.AppSettings? settings = null) {
            if (_instance == null) {
                _instance = new FontStyleProvider (settings);
            }
            return _instance;
        }
    }
}
