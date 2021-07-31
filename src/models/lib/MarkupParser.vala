//  /*
//   * Copyright 2021 Andrea Coronese <sixpounder@protonmail.com>
//   *
//   * This program is free software: you can redistribute it and/or modify
//   * it under the terms of the GNU General Public License as published by
//   * the Free Software Foundation, either version 3 of the License, or
//   * (at your option) any later version.
//   *
//   * This program is distributed in the hope that it will be useful,
//   * but WITHOUT ANY WARRANTY; without even the implied warranty of
//   * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//   * GNU General Public License for more details.
//   *
//   * You should have received a copy of the GNU General Public License
//   * along with this program.  If not, see <http://www.gnu.org/licenses/>.
//   *
//   * SPDX-License-Identifier: GPL-3.0-or-later
//   */

//  namespace Manuscript.Models.Lib {
//      public class MarkupParser {
//          private const GLib.MarkupParser parser = {
//              visit_start,
//              visit_end,
//              visit_text,
//              visit_passthrough,
//              error
//          };

//          private unowned TextBuffer buffer;
//          private Gtk.TextIter cursor;
//          private MarkupParseContext context;
//          private int depth;

//          public MarkupParser (TextBuffer buffer) {
//              this.context = new MarkupParseContext (parser, 0, this, null);
//              this.buffer = buffer;
//          }

//          private void visit_start (
//              MarkupParseContext context,
//              string name,
//              string[] attr_names,
//              string[] attr_values
//          ) throws MarkupError {
//              if (name == "Tag") {
//                  unowned string tag_name = null;

//                  for (int i = 0; i < attr_names.length; i++) {
//                      if (attr_names[i] == "name") {
//                          tag_name = attr_values[i];
//                          var tag = buffer.tag_table.lookup (tag_name);
//                          if (tag != null) {
                            
//                          }
//                      }
//                  }
//              }        
//          }

//          private void visit_end (MarkupParseContext context, string name) throws MarkupError {
            
//          }

//          private void visit_text (MarkupParseContext context, string text, size_t text_len) throws MarkupError {
//              buffer.insert_text (ref cursor, text, (int) text_len);
//          }

//          private void visit_passthrough (MarkupParseContext context, string text, size_t text_len) throws MarkupError {
//              buffer.insert_text (ref cursor, text, (int) text_len);
//          }

//          public bool parse (string markup) throws MarkupError {
//              depth = 0;
//              return context.parse (markup, -1);
//          }

//          private void error (MarkupParseContext context, Error error) {
//          }
//      }
//  }
