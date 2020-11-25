@echo off
call "%~dp0config.bat"
%LUA_CMD% "%~dp0src/hinac.lua" %1 %2 %3 %4 %5 %6 %7