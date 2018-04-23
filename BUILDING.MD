
# Building cdcrush nodeJS


### Requirements

- HAXE 3.4.7\
https://haxe.org/download/

- hxnodejs 4.0.9 (*library*)\
https://github.com/HaxeFoundation/hxnodejs
`haxelib install hxnodejs`

- djNode 0.2 (*library*)\
https://github.com/johndimi/djNode
`haxelib git djNode https://github.com/johndimi/djNode.git`

- HaxeDevelop\
https://haxedevelop.org/



### Building `release`

- Create a subfolder named `tools` and copy all the external executables there `[Arc.exe , ecm.exe , unecm.exe ]`
- Type `haxe build.hxml`, this will build the binary in **/bin**


### Building `debug`

- The tool executables are fetched from the root repo folder `/tools/`, so you don't need to copy them anywhere.
- Open the **project file** `cdcrush.hxproj` with **HaxeDevelop**. Select **DEBUG** from the menu bar and press `F8`. This will build into the **/bin** folder

### Running 

>**YOU NEED TO GET FFMPEG AND SET IT UP ON YOUR PATH**
>The easiest way to do it is to copy `ffmpeg.exe` into your `c:\windows` folder

To run the produced `.js` file. Just type `nodejs cdcrush.js`

### External tools used :

- **FreeArc**, an open source archiver. **Included** in the project files.\
Project Site : https://sourceforge.net/projects/freearc

- **Ecmtools**, open source CD tools. **Included** in the project files. \
Project Site :  https://github.com/kidoz/ecm

- **FFmpeg**, open source video/audio codecs. **NOT INCLUDED** \
Project Site : https://www.ffmpeg.org\