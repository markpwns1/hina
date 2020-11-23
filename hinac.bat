@echo off
call config.bat
%LUA_EXE% src/hinac.lua %1 %2 %3