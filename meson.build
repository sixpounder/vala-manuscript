project('com.github.sixpounder.manuscript', ['vala', 'c'],        version: '1.0.0',
  meson_version: '>= 0.40.0',
)

i18n = import('i18n')
gnome = import('gnome')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

# Uncomment each export compiler the application should support
add_project_arguments('-D', 'EXPORT_COMPILER_PDF', language: 'vala')
add_project_arguments('-D', 'EXPORT_COMPILER_MARKDOWN', language: 'vala')
add_project_arguments('-D', 'EXPORT_COMPILER_PLAIN', language: 'vala')

# Uncomment this to "fake" exports and return after five seconds
# add_project_arguments('-D', 'EXPORT_DEMO_MODE', language: 'vala')

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
