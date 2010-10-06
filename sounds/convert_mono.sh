#!/bin/sh
find . -iname "*.wav" | xargs --replace=file ffmpeg -y -i file -ac 1 file
