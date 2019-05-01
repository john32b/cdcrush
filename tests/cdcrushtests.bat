@echo off 
REM Runs a bunch of CDCRUSH operations
REM This is not fully automated, and you need to check the 
REM output files manually for anything out of place.
REM - The MD5 of Lossless tracks when restored are calculated from within the program
set exe="..\bin\app.js"
set cue1="Sample - Multitrack"
set cue2="Sample - Singletrack"
set output=a:\cdcrush_test_cd

echo Running Tests
mkdir %output%

node %exe% %cue1%.cue -o %output% -ac MP3 -dc ZIP -nfo
node %exe% %cue2%.cue -o %output% -ac TAK -dc ARC -nfo
node %exe% %cue2%.cue -o %output% -ac FLAC -dc 7Z -nfo
node %exe% NONEXISTENT.cue -o %output% -ac FLAC -dc 7Z -nfo

node %exe% %cue1%.cue -o %output% -ac MP3 -dc ZIP -enc -nfo
node %exe% %cue2%.cue -o %output% -ac OPUS -dc ZIP -enc -nfo

node %exe% %output%\\%cue1%.zip -merge -nfo
node %exe% %output%\\%cue2%.arc -enc -nfo
node %exe% %output%\\%cue2%.7z -o %output%\nosub -nosub -merge -nfo