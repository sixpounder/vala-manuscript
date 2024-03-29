/*
 * Copyright 2022 Andrea Coronese <sixpounder@protonmail.com>
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

namespace Manuscript {
    namespace Constants {
        public const string APP_ID = "com.github.sixpounder.manuscript";
        public const string APP_NAME = "Manuscript";
        public const string MAIN_CSS_URI = "/com/github/sixpounder/manuscript/main.css";
        public const string DEFAULT_FILE_EXT = ".mscript";

        public const string DEFAULT_FONT_FAMILY = "iA Writer Duospace";
        public const int64 DEFAULT_FONT_SIZE = 14;
        public const double DEFAULT_LINE_SPACING = 5;
        public const double DEFAULT_PARAGRAPH_SPACING = 35;
        public const double DEFAULT_PARAGRAPH_INITIAL_PADDING = 0;

        public const double MIN_FONT_SCALE = 0.1;
        public const double MAX_FONT_SCALE = 5;

        public const uint QUICK_SEARCH_DEBOUNCE_TIME = 100;
        public const uint AUTOSAVE_DEBOUNCE_TIME = 5000;
        public const int FILE_MONITOR_RATE_LIMIT = 500;

        public const uint A4_WIDHT_IN_POINTS = 595;
        public const uint A4_HEIGHT_IN_POINTS = 842;

        public const string RANDOM_IMAGE_SOURCE_URI = "https://source.unsplash.com/random";
    }
}
