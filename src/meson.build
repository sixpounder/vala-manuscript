asresources = gnome.compile_resources(
	'as-resources', '../data/' + meson.project_name() + '.gresource.xml',
	source_dir: '../data',
	c_name: 'as'
)

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

	'widgets/WelcomeView.vala',
	'widgets/Header.vala',
	'widgets/StatusBar.vala',
	'widgets/MenuButton.vala',
	'widgets/Sidebar.vala',
	'widgets/SettingsPopover.vala',
	'widgets/ExportPopover.vala',
	# 'widgets/ThemeButton.vala',
	'widgets/FileNotFound.vala',
    'widgets/ScrollProgress.vala',
	# 'widgets/ChunkPreview.vala',
	'widgets/DocumentSourceList.vala',
	'widgets/SourceListCategoryItem.vala',
    'widgets/SourceListChunkItem.vala',
    'widgets/DocumentSettings.vala',
    # 'widgets/SearchPanel.vala',
	'widgets/QuickOpenPanel.vala',
	'widgets/QuickOpenEntry.vala',
	'widgets/EditorCourtesyView.vala',

	'widgets/editors/EditorsController.vala',
	'widgets/editors/EditorView.vala',
	'widgets/editors/TextEditor.vala',
	'widgets/editors/CoverEditor.vala',
	'widgets/editors/CharacterSheetEditor.vala',
	'widgets/editors/DocumentTagTable.vala',

    'widgets/settings/Metrics.vala',
    'widgets/settings/General.vala',
	'widgets/settings/Covers.vala',

	'models/Document.vala',
	'models/DocumentChunk.vala',
	'models/ChunkType.vala',
	'models/ChapterChunk.vala',
	'models/CharacterSheetChunk.vala',
	'models/CoverChunk.vala',
	'models/NoteChunk.vala',
	'models/LoadState.vala',
    'models/DocumentSettings.vala',
	'models/ExportFormat.vala',
    'models/Utils.vala',

	'compilers/Base.vala',
	'compilers/Pdf.vala',
	'compilers/Markdown.vala',

    'protocols/Editor.vala',

	'utils/StringUtils.vala',
	'utils/Easing.vala',
	'utils/Keys.vala',
	'utils/Math.vala',
	'utils/FileUtils.vala',

    'dialogs/GenericDialog.vala',
	'dialogs/ExportDialog.vala',
	'dialogs/QuitDialog.vala',
	'dialogs/FileSaveDialog.vala',
	'dialogs/InfoBar.vala',
	asresources,
	dependencies: [
        dependency('glib-2.0'),
		dependency('gtk+-3.0'),
        meson.get_compiler('c').find_library('m', required: false),
		dependency('gio-2.0', version: '>= 2.56.0'),
		dependency('granite', version : '>= 5.3.0'),
		dependency('gee-0.8', version : '>= 0.8'),
		dependency('cairo', version : '>= 1.15'),
		dependency('pangocairo', version : '>= 1.40'),
		dependency('json-glib-1.0', version : '>= 1.4.2'),
		dependency('gtksourceview-3.0')
	],
	install: true
)
