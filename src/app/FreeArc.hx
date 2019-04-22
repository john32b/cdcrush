/****
 * FreeArc
 * Interface for the CLI app
 * -------
 * johndimi, johndimi@outlook.com
 * -------
 * @requires: [Arc.exe]
 * @supports: nodeJS
 * @platform: windows
 * 
 * FreeArc is a modern general-purpose archiver. 
 *  Main advantage of FreeArc is fast but efficient
 *  compression and rich set of features.
 *  http://freearc.org/
 * 
 * 
 * @NOTES
 * - SOLID : (-s) ON , (-s-) OFF
 * 
 * @callbacks
 * 
 * 	- onProgress (progress (0-100))
 *  - onComplete (success) ; Read ERROR if error
 * 
 * ---------------------------------------*/

package app;

import djNode.tools.HTool;
import djNode.tools.LOG;
import djNode.utils.CLIApp;
import js.Node;
import js.node.Fs;
import js.node.Path;

class FreeArc extends Archiver
{
	// Require 'Arc.exe' on executable path
	static var WIN32_EXE:String = "Arc.exe";
	
	//---------------------------------------------------;
	public function new(exePath:String = "")
	{
		super(Path.join(exePath, WIN32_EXE));
		
		app.onClose = (s) -> {
			
			if (!s) // ERROR
			{
				ERROR = app.ERROR;
				return onComplete(false);
			}
			
			if (operation == "compress")
			{
				// Since stdout gives me the compressed size,
				// capture in case I need it later
				// - Stdout line:
				// - Compressed 2 files, 127,707 => 120,363 bytes. Ratio 94.2%
				var r = ~/=> (.*) bytes/;
				if (r.match(app.stdOutLog))
				{
					var m = r.matched(1).split(',').join(''); // get rid of the ','
					COMPRESSED_SIZE = Std.parseFloat(m);
					LOG.log('$ARCHIVE_PATH Compressed size = $COMPRESSED_SIZE');
				}
			}
			onComplete(true);
		};
		
		// - Progress capture is the same on all operations ::
		// - STDOUT
		// - Compressing Track222.bin  39%  
		var expr = ~/(\d{1,3})%\s*$/; 
		app.onStdOut = (data)->{
			if (expr.match(data)) {
				progress = Std.parseInt(expr.matched(1)); // Triggers setter and sends to user
			}	
		};
	}//---------------------------------------------------;
	
	/**
	   Compress a bunch of files into an archive
	   
	   # DEVNOTES
			- If a file in files[] does not exist, it will not ERROR
			- The files are going to be put in the ROOT of the archive.
			  even if input files are from multiple directories
			  
	   @param	files Files to add
	   @param	archive Final archive filename
	   @param	cs (Compression String) a Valid Compression String for FreeArc. | e.g. "-m4x -md32m"
	**/
	override public function compress(files:Array<String>, archive:String, cs:String = null):Bool
	{
		ARCHIVE_PATH = archive;
		LOG.log('Compressing "$files" to "$archive" ... Compression:$cs' );
		operation = "compress";
		progress = 0;
		var p:Array<String> = [
			'create', 			// Create new, delete if already exists
			//SOLID?'-s':'-s-',	// Solid, Not Solid :: REMOVED: Manually set in compression string
			'-mt0', 			// Automatic use of threads
			'-i1', 				// Display progress info only
			'-ep'				// Don't store paths in files ( PUT EVERYTHING at the ROOT of the archive )
		];
		if (cs != null) p = p.concat(cs.split(' '));
		p.push(archive);
		p = p.concat(files);
		app.start(p);
		return true;
	}//---------------------------------------------------;
	
	/**
	   Extract file(s) from an archive
	   @param	archive To Extract
	   @param	output Path (will be created)
	   @param	files Optional, if set will extract those files only
	**/
	override public function extract(archive:String, output:String, files:Array<String> = null):Bool 
	{
		ARCHIVE_PATH = archive;
		operation = "extract";
		progress = 0;
		var p:Array<String> = [
			'e',			// extract
			'-o+',			// overwrite
			'-i1',			// Display progress info only
			'-mt0',			// Automatic use of threads
			'-dp$output',   // Target path
			archive
		];
		var _inf = "";
		if (files == null) {
			_inf = 'all files';
		}else {
			_inf = files.join(',');
			p = p.concat(files);
		}
		LOG.log('Extracting [$_inf] from "$archive" to "$output"' );
		app.start(p);
		return true;
	}//---------------------------------------------------;
	
	/**
	   Append files in an archive
	   - It uses the SAME compression as the archive
	   - Best use this on NON-SOLID archives
	   @param	archive
	   @param	files
	   @return
	**/
	override public function append(archive:String, files:Array<String>):Bool 
	{
		ARCHIVE_PATH = archive;
		if (!Fs.existsSync(archive)) {
			ERROR = "Archive does not exist " + archive;
			return false;
		}
		operation = "append";
		progress = 0;
		
		LOG.log('Appending [ ' + files.join(',') + '] into "$archive"');
		
		var p:Array<String> = [
			'a', 			// Create new, delete if already exists
			'--append',		// Add new files to the end of archive
			'-mt0', 		// Automatic use of threads
			'-i1', 			// Display progress info only
			'-ep',			// Don't store paths in files ( PUT EVERYTHING at the ROOT of the archive )
			archive
		].concat(files);
		
		app.start(p);
		return true;
	}//---------------------------------------------------;
	
	/**
	   Get a generic compression string
		- Not recommended. Read the FREEARC docs and produce custom compression 
	     strings for use in encode();
		- Very high 7,8,9 is NOT recommended either.
	   @param	level 1 is the lowest, 9 is the highest
	**/
	public static function getCompressionString(l:Int = 4)
	{
		HTool.inRange(l, 1, 9);
		return '-m${l}';
	}//---------------------------------------------------;
	
}//--end class--
