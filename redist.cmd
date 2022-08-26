@echo off

echo.
echo Building redist...
haxelib run redistHelper js.hxml -o redist data index.html -ignore style.css,*.scss,*.map
ren redist\js scrambler

echo.
echo Updating GitHub site...
rmdir /Q/S htdocs
xcopy redist\scrambler htdocs\ /S /Y /Q