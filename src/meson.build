asresources = gnome.compile_resources(
	'as-resources', '../data/' + meson.project_name() + '.gresource.xml',
	source_dir: '../data',
	c_name: 'as'
)
executable(
	meson.project_name(),
	'Constants.vala',
	'main.vala',
	'AppSettings.vala',
	'EditorWindow.vala',
	'WelcomeView.vala',
	'Editor.vala',
	'Header.vala',
	'StatusBar.vala',
	'FileUtils.vala',
	'Palettes.vala',
	'DocumentTagTable.vala',
	'SettingsPopover.vala',
	'widgets/ThemeButton.vala',
	'widgets/FileNotFound.vala',
	'models/Document.vala',
	'models/LoadState.vala',
	'utils/StringUtils.vala',
	'utils/StyleProvider.vala',
	'utils/Easing.vala',
	'dialogs/QuitDialog.vala',
	'dialogs/FileSaveDialog.vala',
	'dialogs/InfoBar.vala',
	asresources,
	dependencies: [
		dependency('gtk+-3.0'),
		dependency('gtksourceview-3.0'),
		dependency('granite')
	],
	install: true
)
