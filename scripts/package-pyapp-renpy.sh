#!/bin/bash -e

# Packages Ren'Py files (for use in Emscripten MEMFS)

# Copyright (C) 2019  Sylvain Beucler

# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


FILE_PACKAGER="python $(dirname $(which emcc))/tools/file_packager.py"
PACKAGEDIR=build/package-pyapp-renpy
OUTDIR=build/t


rm -rf $PACKAGEDIR/
mkdir -p $PACKAGEDIR

# # Compile Ren'Py Python scripts
# for i in $(cd renpy/renpy/ && find . -name "*.py"); do
#     if [ renpy/renpy/$i -nt renpy/renpy/${i%.py}.pyo ]; then
# 	python -OO -m py_compile renpy/renpy/$i
#     fi
# done

if [ ! -e renpy/lib ];  then
    echo renpy/lib does not exist. Please symlink or copy it in.
    exit 1
fi

# This compiles the .pyo files and any .rpyc files that need it.
renpy/renpy.sh renpy/the_question quit


# Copy Ren'Py data and remove source files
cp -a renpy/renpy $PACKAGEDIR/
# pygame_sdl2-static
mkdir -p $PACKAGEDIR/lib/python2.7/site-packages/pygame_sdl2/threads
for i in $(cd install && find lib/python2.7/site-packages/pygame_sdl2/ -name "*.pyo"); do
   cp -a install/$i $PACKAGEDIR/$i
done
find $PACKAGEDIR/renpy/ \( -name "*.py" -o -name "*.pyc" \
    -o -name "*.pyx" -o -name "*.pxd" \
    -o -name "*.rpy" -o -name "*.rpym" \) -print0 \
  | xargs -r0 rm

# Stub out these two libs.
mkdir -p $PACKAGEDIR/lib/python2.7
cp pystub/*.py  $PACKAGEDIR/lib/python2.7

# Compile manually added Python scripts
find $PACKAGEDIR/ -name "*.py" -print0 | xargs -r0 python -OO -m py_compile
find $PACKAGEDIR/ -name "*.py" -print0 | xargs -r0 rm

# Entry point
# TODO: Python doesn't like .pyo entry points?
cp -a renpy/renpy.py $PACKAGEDIR/main.py

# RenPyWeb-specific files
cp -a presplash.png $PACKAGEDIR/

$FILE_PACKAGER \
    $OUTDIR/pyapp.data --js-output=$OUTDIR/pyapp-data.js \
    --preload $PACKAGEDIR@/ \
    --use-preload-cache --no-heap-copy
