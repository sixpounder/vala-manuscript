project(
  'com.github.sixpounder.manuscript',
  ['vala', 'c'],
  version: '1.0.0',
  meson_version: '>= 0.46.0',
)

i18n = import('i18n')
gnome = import('gnome')

manuscript_prefix = get_option('prefix')
manuscript_datadir = join_paths(manuscript_prefix, get_option('datadir'))
manuscript_pkgdatadir = join_paths(manuscript_datadir, meson.project_name())
application_id = meson.project_name()

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

# Uncomment to enable import entry in the insert menu
add_project_arguments('-D', 'IMPORT_ENABLED', language: 'vala')

# Uncomment each line to support the corresponding chunk
add_project_arguments('-D', 'CHUNK_CHAPTER', language: 'vala')
add_project_arguments('-D', 'CHUNK_CHARACTER_SHEET', language: 'vala')
add_project_arguments('-D', 'CHUNK_NOTE', language: 'vala')
# add_project_arguments('-D', 'CHUNK_COVER', language: 'vala')

# Uncomment each export compiler the application should support
# add_project_arguments('-D', 'EXPORT_COMPILER_ARCHIVE', language: 'vala')
add_project_arguments('-D', 'EXPORT_COMPILER_MARKDOWN', language: 'vala')
add_project_arguments('-D', 'EXPORT_COMPILER_PLAIN', language: 'vala')
add_project_arguments('-D', 'EXPORT_COMPILER_HTML', language: 'vala')

# Comment this line to disable notification support
add_project_arguments('-D', 'NOTIFICATIONS', language: 'vala')

vala_lint = find_program('io.elementary.vala-lint', required : false)
if vala_lint.found()
    test (
        'Vala lint',
        vala_lint,
        args: ['-d', join_paths(meson.source_root(), 'src')]
    )
endif

subdir('src')

subdir('data')

subdir('po')

message ('Post install')
meson.add_install_script('meson/post_install.py')
