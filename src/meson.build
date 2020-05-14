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
	'WelcomeView.vala',
	'FileUtils.vala',
	'Palettes.vala',
	'DocumentTagTable.vala',

	'services/AppSettings.vala',
	'services/DocumentManager.vala',
	'services/ActionManager.vala',

	'widgets/Header.vala',
	'widgets/Editor.vala',
	'widgets/StatusBar.vala',
	'widgets/MenuButton.vala',
	'widgets/Sidebar.vala',
	'widgets/SettingsPopover.vala',
	'widgets/ExportPopover.vala',
	'widgets/SidebarRow.vala',
	'widgets/ThemeButton.vala',
	'widgets/FileNotFound.vala',
	'widgets/SearchBar.vala',
	'widgets/EditorsController.vala',
	'widgets/EditorView.vala',
	'widgets/ChunkPreview.vala',
    'widgets/SourceListChunkItem.vala',
    'widgets/DocumentSettings.vala',

    'widgets/settings/Metrics.vala',
    'widgets/settings/General.vala',

	'models/ChunkType.vala',
	'models/DocumentChunk.vala',
	'models/Chapter.vala',
	'models/Document.vala',
	'models/LoadState.vala',
    'models/DocumentSettings.vala',
    'models/Utils.vala',

    'protocols/Editor.vala',

	'utils/StringUtils.vala',
	'utils/StyleProvider.vala',
	'utils/Easing.vala',
	'utils/Keys.vala',
	'utils/Math.vala',

    'dialogs/GenericDialog.vala',
	'dialogs/QuitDialog.vala',
	'dialogs/FileSaveDialog.vala',
	'dialogs/InvalidFileDialog.vala',
	'dialogs/InfoBar.vala',
	asresources,
	dependencies: [
		dependency('gtk+-3.0'),
		dependency('gio-2.0', version: '>= 2.56.0'),
		dependency('gee-0.8', version : '>= 0.8'),
		dependency('cairo', version : '>= 1.15'),
		dependency('pangocairo', version : '>= 1.40'),
		dependency('json-glib-1.0'),
		dependency('gtksourceview-3.0'),
		dependency('granite', version : '>= 5.3.0')
	],
	install: true
)
