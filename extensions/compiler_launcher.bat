
:: This script is used to launch the compiler. It is called by cmake and
:: the compiler path is passed as an argument. The script will then
:: launch the compiler with the correct arguments.

@echo off

:: set the environment variables
SET CCACHE_DIR=".ccache"
SET SCCACHE_DIR=".sccache"

SET CCACHE_SLOPPINESS="locale,time_macros,include_file_ctime,include_file_mtime"

%*

