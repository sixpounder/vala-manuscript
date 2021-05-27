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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Manuscript.Dialogs {
    public class ExportDialog : Gtk.Dialog {
        public const int ICON_SIZE = 64;
        public weak Manuscript.Window parent_window { get; construct; }
        public weak Manuscript.Models.Document document { get; construct; }

        private Manuscript.Models.ExportFormat _export_format;
        public Manuscript.Models.ExportFormat export_format {
            get {
                return _export_format;
            }
            private set {
                _export_format = value;
                adapt_filename_to_format (_export_format);
            }
        }

        protected Gtk.Button export_button;
        protected Gtk.Button close_button;
        protected Gtk.Box format_selection_grid;
        protected Gtk.Spinner progress_indicator;
        protected Gtk.Widget export_button_label;

        protected Gtk.Entry file_name_entry;
        protected Gtk.FileChooserButton folder_chooser_button;

        public ExportDialog (Manuscript.Window parent_window, Manuscript.Models.Document document) {
            Object (
                parent_window: parent_window,
                transient_for: parent_window,
                document: document,
                modal: true,
                width_request: 500,
                height_request: 500
            );
        }

        construct {
            export_button = new Gtk.Button.with_label (_("Export"));
            export_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            export_button_label = export_button.get_child ();

            close_button = new Gtk.Button.with_label (_("Cancel"));

            progress_indicator = new Gtk.Spinner ();
            progress_indicator.no_show_all = true;

            add_action_widget (close_button, Gtk.ResponseType.CLOSE);
            add_action_widget (export_button, Gtk.ResponseType.NONE);

            var layout = new Gtk.Grid ();
            layout.margin_start = layout.margin_end = 30;
            layout.row_spacing = 15;
            layout.row_homogeneous = false;
            layout.expand = true;
            layout.halign = Gtk.Align.CENTER;
            layout.valign = Gtk.Align.CENTER;
            layout.width_request = 500;
            layout.height_request = 500;

            format_selection_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
            format_selection_grid.halign = Gtk.Align.CENTER;
            format_selection_grid.valign = Gtk.Align.CENTER;
            format_selection_grid.homogeneous = true;
            format_selection_grid.hexpand = true;

            var pdf_radio = new Gtk.RadioButton (null);
            var pdf_icon = new Gtk.Image ();
            pdf_icon.gicon = new ThemedIcon ("application-pdf");
            pdf_icon.pixel_size = ICON_SIZE;
            pdf_radio.image = pdf_icon;
            pdf_radio.toggled.connect (() => {
                export_format = Manuscript.Models.ExportFormat.PDF;
            });
            format_selection_grid.pack_start (pdf_radio);

#if EXPORT_COMPILER_HTML
            var html_radio = new Gtk.RadioButton.from_widget (pdf_radio);
            var html_icon = new Gtk.Image ();
            html_icon.gicon = new ThemedIcon ("text-html");
            html_icon.pixel_size = ICON_SIZE;
            html_radio.image = html_icon;
            html_radio.toggled.connect (() => {
                export_format = Manuscript.Models.ExportFormat.HTML;
            });
            format_selection_grid.pack_start (html_radio);
#endif

#if EXPORT_COMPILER_MARKDOWN
            var markdown_radio = new Gtk.RadioButton.from_widget (pdf_radio);
            var markdown_icon = new Gtk.Image ();
            markdown_icon.gicon = new ThemedIcon ("text-markdown");
            markdown_icon.pixel_size = ICON_SIZE;
            markdown_radio.image = markdown_icon;
            markdown_radio.toggled.connect (() => {
                export_format = Manuscript.Models.ExportFormat.MARKDOWN;
            });
            format_selection_grid.pack_start (markdown_radio);
#endif

#if EXPORT_COMPILER_PLAIN
            var plain_radio = new Gtk.RadioButton.from_widget (pdf_radio);
            var plain_icon = new Gtk.Image ();
            plain_icon.gicon = new ThemedIcon ("text-x-generic");
            plain_icon.pixel_size = ICON_SIZE;
            plain_radio.image = plain_icon;
            plain_radio.toggled.connect (() => {
                export_format = Manuscript.Models.ExportFormat.PLAIN;
            });
            format_selection_grid.pack_start (plain_radio);
#endif

#if EXPORT_COMPILER_ARCHIVE
            var archive_radio = new Gtk.RadioButton.from_widget (pdf_radio);
            var archive_icon = new Gtk.Image ();
            archive_icon.gicon = new ThemedIcon ("package-x-generic");
            archive_icon.pixel_size = 64;
            archive_radio.image = archive_icon;
            archive_radio.toggled.connect (() => {
                export_format = Manuscript.Models.ExportFormat.ARCHIVE;
            });
            format_selection_grid.pack_start (archive_radio);
#endif

            layout.attach_next_to (format_selection_grid, null, Gtk.PositionType.LEFT);

            file_name_entry = new Gtk.Entry ();
            file_name_entry.valign = Gtk.Align.START;
            adapt_filename_to_format (export_format);
            layout.attach_next_to (file_name_entry, format_selection_grid, Gtk.PositionType.BOTTOM);

            folder_chooser_button = new Gtk.FileChooserButton (_("Output folder"), Gtk.FileChooserAction.SELECT_FOLDER);
            folder_chooser_button.valign = Gtk.Align.START;
            folder_chooser_button.set_current_folder (Environment.get_user_special_dir (UserDirectory.DOCUMENTS));
            layout.attach_next_to (folder_chooser_button, file_name_entry, Gtk.PositionType.BOTTOM);

            get_content_area ().add (layout);

            show_all ();
        }

        protected void disable_ui () {
            format_selection_grid.sensitive = false;
            export_button.sensitive = false;
            close_button.sensitive = false;
            export_button.remove (export_button.get_child ());
            export_button.child = progress_indicator;
            progress_indicator.show ();
            progress_indicator.start ();
        }

        protected void enable_ui () {
            format_selection_grid.sensitive = true;
            export_button.sensitive = true;
            close_button.sensitive = true;
            export_button.remove (export_button.get_child ());
            export_button.child = export_button_label;
            progress_indicator.hide ();
            progress_indicator.stop ();
        }

        private void adapt_filename_to_format (Models.ExportFormat format) {
            var current_name = file_name_entry.text == ""
                ? document.title.strip() == ""
                    ? _("Untitled")
                    : document.title.strip()
                : file_name_entry.text;
            switch (format) {
                case Models.ExportFormat.PDF:
                    file_name_entry.text = @"$(FileUtils.get_extensionless (current_name)).pdf";
                    break;
                case Models.ExportFormat.MARKDOWN:
                    file_name_entry.text = @"$(FileUtils.get_extensionless (current_name)).md";
                    break;
                case Models.ExportFormat.HTML:
                    file_name_entry.text = @"$(FileUtils.get_extensionless (current_name)).html";
                    break;
                case Models.ExportFormat.PLAIN:
                    file_name_entry.text = @"$(FileUtils.get_extensionless (current_name)).txt";
                    break;
                default:
                    break;
            }
        }

        protected async void compile (Manuscript.Models.ExportFormat output_format) throws Compilers.CompilerError {
            if (file_name_entry.text.strip() == "") {
                throw new Compilers.CompilerError.FORMAL ("Missing filename");
            }

            Manuscript.Compilers.ManuscriptCompiler compiler
                = Manuscript.Compilers.ManuscriptCompiler.for_format (output_format);

            compiler.filename = Path.build_filename (
                folder_chooser_button.get_current_folder (),
                file_name_entry.text
            );

            yield compiler.compile (document);
        }

        public async void start_export () throws Compilers.CompilerError {
            disable_ui ();
            SourceFunc callback = start_export.callback;
            if (Thread.supported ()) {
                new Thread<void> ("compile-thread", () => {
                    compile.begin (export_format, (obj, res) => {
                        try {
                            compile.end (res);
                        } catch (Compilers.CompilerError e) {
                            critical (e.message);
                        }
                        enable_ui ();
                        Idle.add ((owned) callback);
                    });
                });
                yield;
            } else {
                try {
                    yield compile (export_format);
                } catch (Compilers.CompilerError e) {
                    throw e;
                }
            }
        }
    }
}
