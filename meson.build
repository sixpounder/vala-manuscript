project('com.github.sixpounder.manuscript', ['vala', 'c'],        version: '0.1.0',
  meson_version: '>= 0.40.0',
)

i18n = import('i18n')
gnome = import('gnome')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

subdir('src')

subdir('data')

subdir('po')

message ('Post install')
meson.add_install_script('meson/post_install.py')

