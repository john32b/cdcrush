/****
 * FreeArc interface
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
 * @events: 
 * 			`close`		;	ExitOK:<Bool>, ErrorMessage:<String>, 
 * 			`progress`	;	Progress:<Int>
 * ---------------------------------------*/
 
package app;

import djNode.tools.LOG;
import djNode.utils.CLIApp;
import js.Node;
import js.node.Path;


class Arc extends CLIApp
{
	// Require 'Arc.exe' on executable path
	static var WIN32_EXE:String = "Arc.exe";
	
	//---------------------------------------------------;
	public function new(exePath:String = "")
	{
		super(Path.join(exePath, WIN32_EXE));
	}//---------------------------------------------------;
	
	// - Compress a list of files
	// - If multiple files, destination will be the name of the first file
	public function compress(files:Array<String>, archive:String, compressionLevel:Int = 4):Void
	{
		LOG.log('Compressing "$files" to "$archive" ... Compression:$compressionLevel' );
		
		// NOTE: Possible problem if input files at different directories!
		var sourceFolder = Path.dirname(files[0]);
		
		var args:Array<String> = [	
			"a",
			'-m${compressionLevel}',	// m4 is the default compression
			'-s',	// Solid Compression, To merge all files in one solid block
			'-i1', 	// Display progress info only
					// -md32m is dictionary size -- removed since 1.2.3
			'-o+',	// Overwrite
			'--diskpath=$sourceFolder',
			archive
		];
		
		// Now push all the input files
		for (i in files) args.push(Path.basename(i));
		
		listen_progress();
		
		start(args);
		
	}//---------------------------------------------------;
		
	// - Append a bunch of files in an archive
	// ! ALL files must be in the same DIR
	public function appendFiles(files:Array<String>, archive:String)
	{
		LOG.log('Appending "$files" to "$archive" ');
		
		var sourceFolder = Path.dirname(files[0]);
		
		var args:Array<String> = [	
			"a",
			'--diskpath=$sourceFolder',
			archive
		];
		
		// Now push all the input files
		for (i in files) args.push(Path.basename(i));
		
		args.push('--append');
		
		listen_progress();
		
		start(args);
	}//---------------------------------------------------;
	
	// - Extracts all files,ingores pathnames
	// -
	public function extractAll(inputFile:String, destinationFolder:String = null)
	{
		if (destinationFolder == null)
		{
			destinationFolder = Path.dirname(inputFile);
		}
		
		LOG.log('Extracting `$inputFile` into `$destinationFolder`');
		
		var args:Array<String> = [
			'e',
			'-o+',
			'-i1',
			inputFile,
			'-dp$destinationFolder'
		];

		listen_progress();
		
		start(args);

	}//---------------------------------------------------;
	
	// - Extract selected files from an archive
	// -
	public function extractFiles(inputFile:String, listOfFiles:Array<String>, destinationFolder:String = null)
	{
		if (destinationFolder == null)
		{
			destinationFolder = Path.dirname(inputFile);
		}
		
		LOG.log('Extracting `$listOfFiles` into `$destinationFolder`');
		
		var args:Array<String> = [
			'e',
			'-o+',
			'-i1',
			inputFile
		];
		
		for (i in listOfFiles) args.push(i);
		
		args.push('-dp$destinationFolder');

		listen_progress();
		
		start(args);
		
	}//---------------------------------------------------;


	/**
	 * Call this BEFORE the process has been created.
	 */
	private function listen_progress():Void
	{	
		var expr = ~/(\d{1,3})%\s*$/; // Compressing Track222.bin  39%  
		
		events.emit("progress", 0);
		
		onStdOut = function(data:String){
			if (expr.match(data)) {
				// Sends the percent completed
				events.emit("progress", Std.parseInt(expr.matched(1)));
			}	
		};
	}//---------------------------------------------------;
	
}//--end class--




/* [A0001] STD OUT Example: 
 * FreeArc 0.67 (March 15 2014) listing archive: c:\temp\doom.arc
	Date/time                  Size Filename
	----------------------------------------
	2015-12-13 15:18:44       4,480 crushdata.json
	2015-12-13 15:17:43   2,639,529 Track02.ogg
	2015-12-13 15:17:51   1,601,991 Track03.ogg
	2015-12-13 15:18:05   3,640,301 Track04.ogg
	2015-12-13 15:18:18   2,889,499 Track05.ogg
	2015-12-13 15:18:27   1,807,526 Track06.ogg
	2015-12-13 15:18:30     743,577 Track07.ogg
	2015-12-13 15:18:44   3,126,641 Track08.ogg
	----------------------------------------
	8 files, 16,453,544 bytes, 14,843,058 compressed
	All OK
-----------------------------------*/
	



/* Getting File List Old Code

	AppSpawner.quickExec(compiledPathExe + ' l $filename', 
		function(s:Bool, out:String, err:String) {
		 -- Break the output into lines
		  - Trim the first and last lines that do not display files
		  - Get the last characters of each line ( the filename ) in
			into an aray and return that.
		var reg:EReg = ~/(\S*)$/;
		var lines:Array<String> = [];
		
		lines = out.split("\r");
		lines = lines.splice(3, lines.length - 8);
		lines = lines.map(function(s) {
			if (reg.match(s)) {
				return reg.matched(0);
			} return null;
		});
		callback(lines);		
	});

-----------------------------------*/
	