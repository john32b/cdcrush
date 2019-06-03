
# Building cdcrush nodeJS


### Requirements

- HAXE 4  
https://haxe.org/download/

- hxnodejs 6.9.1 (*library*)  
https://github.com/HaxeFoundation/hxnodejs
`haxelib install hxnodejs`

- djNode 0.4.0 (*library*)  
https://github.com/johndimi/djNode/releases/tag/v0.4  
Download the source zip and then
`haxelib install djNode-0.4.zip`


- HaxeDevelop  *(optional)*
https://haxedevelop.org/

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