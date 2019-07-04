project('com.github.sixpounder.write', ['vala', 'c'],        version: '0.1.0',
  meson_version: '>= 0.40.0',
)

subdir('src')

subdir('data')

message ('Post install')
meson.add_install_script('meson/post_install.py')
