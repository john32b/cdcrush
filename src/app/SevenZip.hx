/****
 * 7ZIP 
 * Interface for the CLI app
 * -------
 * johndimi, johndimi@outlook.com
 * -------
 * @requires: [7za.exe]
 * @supports: nodeJS
 * @platform: windows
 * 
 * @DEVNOTES
 * 	- 7za.exe is the standalone version of 7zip
 *  - Guide: https://sevenzip.osdn.jp/chm/cmdline/index.htm
 * 
 * @NOTES
 * 	- SOLID : (-ms=on),  (-ms=off)
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
import js.node.Fs;
import js.node.Path;

class SevenZip extends Archiver
{
	
	static var S01 = ">update";	// Inner Helper special string ID to use on update/compress
	
	static var WIN32_EXE:String = "7za.exe";
	
	//---------------------------------------------------;
	
	public function new(exePath:String = "")
	{
		super(Path.join(exePath, WIN32_EXE));
		
		app.LOG_STDOUT = true;
		app.LOG_STDERR = true;
		
		app.onClose = (s)->{
			
			if (!s) // ERROR
			{
				ERROR = app.ERROR;
				HTool.sCall(onFail, ERROR);
				return;
			}
			
			if (operation == "compress")
			{
				// Since stdout gives me the compressed size,
				// capture in case I need it later
				// - STDOUT Example :
				// - .......Files read from disk: 1\nArchive size: 544561 bytes (532 KiB)\nEverything is Ok
				var r = ~/Archive size: (\d+)/;
				if (r.match(app.stdOutLog))
				{
					COMPRESSED_SIZE = Std.parseFloat(r.matched(1));
					LOG.log('$ARCHIVE_PATH Compressed size = $COMPRESSED_SIZE');
				}
			}
			HTool.sCall(onComplete);
		};
		
		// - Progress capture is the same on all operations ::
		// - STDOUT :
		// - 24% 13 + Devil Dice (USA).cue
		var expr = ~/(\d+)%/;		
		app.onStdOut = (data)->{
			if (expr.match(data)) {
				progress = Std.parseInt(expr.matched(1)); // Triggers setter and sends to user
			}	
		};
		
	}//---------------------------------------------------;
	
	
	/**
	   Compress a bunch of files into an archive
	   
	   # DEVNOTES
			- WARNING: If archive exists, it will APPEND files.
			- If a file in files[] does not exist, it will NOT ERROR
			- The files are going to be put in the ROOT of the archive.
			  even if input files are from multiple directories
			  
	   @param	files Files to add
	   @param	archive Final archive filename
	   @param	cs (Compression String) a Valid Compression String for FreeArc. | e.g. "-m4x"
	**/
	override public function compress(files:Array<String>, archive:String, cs:String = null):Bool
	{
		ARCHIVE_PATH = archive;
		operation = "compress";
		progress = 0;
		LOG.log('Compressing "$files" to "$archive" ... Compression:$cs' );
		
		// 7Zip does not have a command to replace the archive
		// so I delete it manually if it exists
		if (cs == S01)
		{
			cs = null;
			operation = "update";
		}else
		{
			if (Fs.existsSync(archive)) {
				Fs.unlinkSync(archive);
			}
		}
		
		var p:Array<String> = [
			'a', 						// Add
			'-bsp1', 					// Redirect PROGRESS outout to STDOUT (important)
			'-mmt' 						// Multithreaded
		];
		if (cs != null) p = p.concat(cs.split(' '));
		p.push(archive);
		p = p.concat(files);
		app.start(p);
		return true;
	}//---------------------------------------------------;
	
	
	/**
	   Extract file(s) from an archive. Overwrites output
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
			'e',			// Extract
			archive,
			'-bsp1',		// Progress in stdout
			'-mmt',			// Multithread
			'-aoa',			// Overwrite
			'-o$output'		// Target folder. DEV: Does not need "" works with spaces just fine
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
	   - Best use this on NON-SOLID archives (default solid = off in this class)
	   @param	archive
	   @param	files
	   @return
	**/
	override public function append(archive:String, files:Array<String>):Bool 
	{
		compress(files, archive, S01);
		return true;
	}//---------------------------------------------------;
	
	
	
	/**
	   Get a generic compression string
		- Not recommended. Read the 7ZIP docs and produce custom compression 
	     strings for use in encode();
	   @param	level 1 is the lowest, 9 is the highest
	**/
	public static function getCompressionString(l:Int = 4)
	{
		HTool.inRange(l, 1, 9);
		return '-mx${l}';
	}//---------------------------------------------------;
	
}// --