
CDCRUSH.nodejs CHANGELOG:
-------------------------

V 1.3 (April 2018)

	- Compatible with the **.net** version of cdcrush
	- Job system can now run Tasks in parallel
	- Added Lib Vorbis and MP3 encoding support.
	
V 1.1.2

	- BUGFIX, Supports filenames with a single bracket in the cue files
	- EXPERIMENTAL : Flag "-s", can restore multitrack games into a single CUE/BIN file
		
V 1.1.1

	- BUGFIX, Can now restore .arc files made with any version of CDCRUSH,
			  The issue was on the djNode CDInfo class

V 1.1 

	- BUGFIX, You can now use spaces and symbols at the pathnames. e.g "C:/@ @ #$%^ games/isos @#/"
	- NEW, Run with "-f" to restore ARC files to separate folders.
	- NEW, Run with "-w" to overwrite any files during the convertion.
	- Supports Cue Sheets with multiple track files. Some cuesheets have the tracks 
	  already cut into multiple files and no splitting is required.
	  ```
	  		  e.g. CueSheets that look like this are now supported:
				  
				FILE "WipEout 3 (USA) (Track 01).bin" BINARY
					TRACK 01 MODE2/2352
					INDEX 01 00:00:00
				FILE "WipEout 3 (USA) (Track 02).bin" BINARY
					TRACK 02 AUDIO
					INDEX 00 00:00:00
					INDEX 01 00:02:00
				FILE "WipEout 3 (USA) (Track 03).bin" BINARY
					..
					..
	```
	
V 1.0
	- Mostly re-written. Compiled using the _hxnodejs_ library.
	- Added checks to see if temp and output directories are writable
	- Added a pre-run check to see if FFMPEG is installed

V 0.9.10
	- Fixed CCD imput file bug. Will now process it correctly. ( Keep in mind cdcrush does not support subchannel data )

V 0.9.9
	- Fixed bug where output could not be defined with -o    

V 0.9.8
	- Added support for basic * wildcards.
		e.g.  
		`cdcrush c:\iso\*.arc`  

V 0.9.7 
	- Initial release.