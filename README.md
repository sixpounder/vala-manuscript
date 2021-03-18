# Manuscript
Manuscript is a free, open source environment for writers

# Build

You will need these dependencies installed

```bash
glib-2.0
gtk+-3.0
gio-2.0
granite, version : '>= 5.3.0'
gee-0.8, version : '>= 0.8'
cairo, version : '>= 1.15'
pangocairo, version : '>= 1.40'
json-glib-1.0, version : '>= 1.4.2'
gtksourceview-3.0

# Optional
m
```

Building
```bash
meson build --prefix=/usr
cd build
ninja
sudo ninja install # Install system wide
```