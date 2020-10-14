
# Building cdcrush nodeJS


### Requirements

- HAXE 4.1.3
https://haxe.org/download/

- hxnodejs 12.1.0 (*library*)  
https://github.com/HaxeFoundation/hxnodejs
`haxelib install hxnodejs 12.1.0`

- djNode 0.5.0 (*library*)  
https://github.com/johndimi/djNode/releases/tag/v0.5  
Download the source zip and then
`haxelib install djNode-0.5.zip`

- HaxeDevelop *(optional)*
https://haxedevelop.org/

	
### Build

	- Execute  `npm run build`  to build the `.js` file in the bin folder

> **! NOTE !**
> The build might produce some warnings about some things being deprecated, this is ok.



### Running 

>**YOU NEED TO GET FFMPEG AND SET IT UP ON YOUR PATH**
>The easiest way to do it is to copy `ffmpeg.exe` into your `c:\windows` folder  
To run the produced `.js` file. Just type `nodejs cdcrush.js`

### External tools used :

- **FreeArc**, an open source archiver. **Included** in the project files. 
Project Site : https://sourceforge.net/projects/freearc
- **Ecmtools**, open source CD tools. **Included** in the project files.  
Project Site :  https://github.com/kidoz/ecm
- **FFmpeg**, open source video/audio codecs. **NOT INCLUDED**  
Project Site : https://www.ffmpeg.org
- **7-Zip**, open source archiver. **Included** in the project files.  
Project Site : https://www.7-zip.org/