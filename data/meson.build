# icon_sizes = ['16', '24', '32', '48', '64', '128']

icon_sizes = ['128']

foreach i : icon_sizes
    install_data(
        join_paths('icons', i, meson.project_name() + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
    )
endforeach

install_data(meson.project_name() + '.gschema.xml',
  install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

install_data(
    join_paths(meson.project_name() + '.desktop'),
    install_dir: join_paths(get_option('datadir'), 'applications')
)

install_data(
    join_paths(meson.project_name() + '.appdata.xml'),
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)

desktop_utils = find_program('desktop-file-validate', required: true)
if desktop_utils.found()
  test('Validate desktop file', desktop_utils,
    args: [meson.project_name() + '.desktop']
  )

  message('Desktop file OK')
endif

compile_schemas = find_program('glib-compile-schemas', required: true)
if compile_schemas.found()
  test('Validate schema file', compile_schemas,
    args: ['--strict', meson.current_source_dir()]
  )

  message('Schema OK')
endif