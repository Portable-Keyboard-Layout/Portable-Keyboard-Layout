@echo off
rem usage: GenerateImages layout

del out\*.ini
del out\*.html
del out\*.png

copy ..\layouts\%1\layout.ini out\layout.ini
perl ini2html.pl

del *.png
"C:\Program Files\Mozilla Firefox\firefox.exe" -p screengrab -no-remote -savepng out/layout.html

perl split_png.pl
del *.png

del ..\layouts\%1\layout.html
del ..\layouts\%1\*.png
move out\*.png ..\layouts\%1\
move out\layout.html ..\layouts\%1\