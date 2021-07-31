add_project_arguments('-D', 'GTKSOURCEVIEW3', language: 'vala')

# Uncomment this when switching to gtksourceview4
# add_project_arguments('-D', 'GTKSOURCEVIEW4', language: 'vala')

asresources = gnome.compile_resources(
	'as-resources', '../data/' + meson.project_name() + '.gresource.xml',
	source_dir: '../data',
	c_name: 'as'
)

gtk = dependency('gtk+-3.0')
if meson.get_compiler('c').find_library('gtk4', required: false).found()
	# GTK4 can be used
	gtk = dependency('gtk4')
	add_project_arguments('-D', 'GTK_4', language: 'vala')
endif

executable(
	meson.project_name(),
	'main.vala',
	'Globals.vala',
	'Constants.vala',
	'Window.vala',

	'services/AppSettings.vala',
	'services/DocumentManager.vala',
	'services/ActionManager.vala',
	'services/Notification.vala',
	'services/ThreadPool.vala',

	'widgets/WelcomeView.vala',
	'widgets/Header.vala',
	'widgets/StatusBar.vala',
	'widgets/MenuButton.vala',
	'widgets/Sidebar.vala',
	'widgets/SettingsPopover.vala',
	'widgets/ExportPopover.vala',
	'widgets/FileNotFound.vala',
    'widgets/ScrollProgress.vala',
	'widgets/DocumentSourceList.vala',
	'widgets/SourceListCategoryItem.vala',
    'widgets/SourceListChunkItem.vala',
    'widgets/DocumentSettings.vala',
    'widgets/SearchPanel.vala',
	'widgets/QuickOpenPanel.vala',
	'widgets/QuickOpenEntry.vala',
	'widgets/EditorCourtesyView.vala',

	'widgets/editors/EditorsController.vala',
	'widgets/editors/TextEditorView.vala',
	'widgets/editors/TextEditor.vala',
	'widgets/editors/CoverEditor.vala',
	'widgets/editors/CharacterSheetEditor.vala',
	'widgets/editors/FormatToolbar.vala',
	'widgets/editors/artifacts/FootNoteIndicator.vala',
	'widgets/editors/artifacts/TextHighlightIndicator.vala',

	'widgets/settings/Metrics.vala',
    'widgets/settings/Typography.vala',
    'widgets/settings/General.vala',
	# 'widgets/settings/Covers.vala',

	'models/TextBuffer.vala',
	'models/DocumentTagTable.vala',
	'models/Document.vala',
	'models/DocumentChunk.vala',
	'models/ChunkType.vala',
	'models/ChapterChunk.vala',
	'models/CharacterSheetChunk.vala',
	'models/CoverChunk.vala',
	'models/NoteChunk.vala',
	'models/FootNote.vala',
	'models/LoadState.vala',
    'models/DocumentSettings.vala',
	'models/ExportFormat.vala',
    'models/Utils.vala',
	'models/AnalyzeTask.vala',

	# 'models/lib/MarkupParser.vala',

	'compilers/Base.vala',
	'compilers/Html.vala',
	'compilers/Pdf.vala',
	'compilers/Plain.vala',
	'compilers/Markdown.vala',
	'compilers/Utils.vala',

    'protocols/Editor.vala',

	'utils/StringUtils.vala',
	'utils/Easing.vala',
	'utils/Keys.vala',
	'utils/Math.vala',
	'utils/FileUtils.vala',
	'utils/Threads.vala',

    'dialogs/GenericDialog.vala',
	'dialogs/ExportDialog.vala',
	'dialogs/ExportMetrics.vala',
	'dialogs/QuitDialog.vala',
	'dialogs/FileSaveDialog.vala',
	'dialogs/InfoBar.vala',
	asresources,
	dependencies: [
        dependency('glib-2.0'),
		gtk,
        meson.get_compiler('c').find_library('m', required: false),
		dependency('gio-2.0', version: '>= 2.56.0'),
		dependency('granite', version : '>= 5.3.0'),
		dependency('gee-0.8', version : '>= 0.8'),
		dependency('cairo', version : '>= 1.15'),
		dependency('pangocairo', version : '>= 1.40'),
		dependency('json-glib-1.0', version : '>= 1.4.2'),
		dependency('gtksourceview-3.0'),
		dependency('libarchive')
	],
	install: true
)
