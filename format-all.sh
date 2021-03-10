#!/usr/bin/env bash
for f in ./**/*.vala; do
    uncrustify -c uncrustify.cfg --no-backup $f
done

