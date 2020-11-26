@echo off
call "%~dp0config.bat"
%LUA_CMD% "%~dp0src/hinarepl.lua" %1 %2 %3 %4 %5 %6 %7