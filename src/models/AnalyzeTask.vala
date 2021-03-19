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

namespace Manuscript.Models {
    public class AnalyzeResult : Object {
        public uint words_count { get; construct; }
        public double estimate_reading_time { get; construct; }

        public AnalyzeResult (uint words_count, double estimate_reading_time) {
            Object (
                words_count: words_count,
                estimate_reading_time: estimate_reading_time
            );
        }
    }
    public class AnalyzeTask : Object, Manuscript.Services.ThreadWorker<AnalyzeResult> {
        public string buffer { get; construct; }

        public AnalyzeTask (string buffer) {
            Object (
                buffer: buffer
            );
        }

        public AnalyzeResult worker_run () {
            uint words_count = Utils.Strings.count_words (buffer);
            double estimate_reading_time = Utils.Strings.estimate_reading_time (words_count); 
            return new AnalyzeResult (words_count, estimate_reading_time);
        }

        public string get_group () {
            return "text_analyzers";
        }
    }
}
