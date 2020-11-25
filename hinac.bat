@echo off
call config.bat
%LUA_CMD% src/hinac.lua %1 %2 %3