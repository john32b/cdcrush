CDCRUSH
========

**Version:** 1.1
**Author:** John Dimi, <johndimi@outlook.com>, twitter:[@jondmt](https://twitter.com/jondmt)  
**Language:** Haxe 3.2 **Compiles to:** nodeJS (windows)

------

**CDCRUSH** is a nodeJS CLI tool to compress and restore CD-image based games. It encodes the data and audio tracks with modern codecs resulting in a very small filesize. Then the compressed files can be restored back to a fully usable CD Image.

This is the source code repository. 
[Check out the **NPM** page of the project here](https://www.npmjs.com/package/cdcrush)

### CHANGELOG

**Version 1.1** : 	
- BUGFIX, You can now use spaces and symbols in the pathnames. e.g.
  `cdcrush "C:/@ @ #$%^ games/isos @#/game.arc"`
- NEW, run with "-f" to restore ARC files to separate folders.
- NEW, run with "-w" to overwrite any files during the convertion.
- Supports Cue Sheets with multiple track files.

### How to build

You will need:
- **HAXE** 3.2
- **hxnodejs** *(nodeJS externs for Haxe)*
 ```haxelib install hxnodejs```
- *[djNode](https://github.com/johndimi/djNode)* library (Personal CLI helper library)
  ```haxelib git djNode https://github.com/johndimi/djNode.git```  

### To run

- **FFMPEG** installed and set on %PATH% 
- **FreeArc** is already included in the bin folder
- **ECM tools** are already included in the bin folder
- Windows


Don't hesitate to contact me by email or twitter. Cheers.

