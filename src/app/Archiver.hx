package app;
import djNode.utils.CLIApp;
import djNode.utils.ISendingProgress;

/**
 * Generic Archiver,
 * Needs to be extended
 * ...
 */
class Archiver implements ISendingProgress
{
	// This will be auto-set whenever compress() is complete and returns TRUE
	// This value will be read to whatever the archiver reports to the stdout
	public var COMPRESSED_SIZE(default, null):Float = 0;
	
	// Holds the archive path that was worked on
	// Useful to have
	public var ARCHIVE_PATH	(default, null):String;
	
	// Hold the current operation ID ("compress","restore")
	var operation:String;
	
	var app:CLIApp;
	
	// Progress (-1) when the process is not started yet
	public var progress(default, set):Int = -1;
	function set_progress(val){
		if (val == progress) return val;
		progress = val;
		onProgress(val);
		return val;
	}
		
 	public var onComplete:Void->Void;
	public var onFail:String->Void;
	public var onProgress:Int->Void = (p)->{};
	public var ERROR(default, null):String;
	
	public function new(exePath:String)
	{
		app = new CLIApp(exePath);
	}//---------------------------------------------------;

	/**
	   @param	files Files to add
	   @param	archive Final archive filename
	   @param	cs (Compression String)
	**/
	public function compress(files:Array<String>, archive:String, cs:String = null):Bool return false;
	
	public function extract(archive:String, output:String, files:Array<String> = null):Bool return false;
	
	public function append(archive:String, files:Array<String>):Bool return false;
	
	public function kill()
	{
		if (app != null) app.kill();
	}//---------------------------------------------------;
	
}// -