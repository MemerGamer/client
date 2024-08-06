#!/bin/bash

# This script is used to launch the compiler. It is called by cmake and
# the compiler path is passed as an argument. The script will then
# launch the compiler with the correct arguments.

# set all the environment variables
export CCACHE_DIR=".ccache"
export SCCACHE_DIR=".sccache"

export CCACHE_SLOPPINESS="locale,time_macros,include_file_ctime,include_file_mtime"

# check if ccache is installed
if [ -x "$(command -v ccache)" ]; then
    ccache "$@"
elif [ -x "$(command -v sccache)" ]; then
    sccache "$@"
else
    "$@"
fi
