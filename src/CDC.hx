/**--------------------------------------------------------
 * CDCRUSH
 * @author: johndimi, <johndimi@outlook.com> , @jondmt
 * --------------------------------------------------------
 * @Description
 * -------
 * CDcrush main engine static class
 * 
 * @Notes
 * ------
 * 
 ========================================================*/
package;

import djNode.task.FakeTask;
import djNode.task.Job;
import djNode.task.Task;
import djNode.tools.CDInfo;
import djNode.tools.FileTool;
import djNode.tools.LOG;
import js.Node;
import js.node.Fs;
import js.node.Path;


// Put job parameters into an object
// for easy access from tasks
class CDCRunParameters
{
	// Parsed CUE info, useful to share between tasks
	public var cd:CDInfo; 
	
	// File being processed, can be short or full path
	public var input:String;
	// Used in crush, FULL Path of generated ARC
	public var crushedArc:String;
	
	public var imagePath:String; // When Restoring Single Tracks
	public var cuePath:String;   // Whem Restoring Single tracks
	
	// Path that the input file is on.
	// e.g. (If input file is "c:\iso\game.arc" then inputDir == "c:\iso\")
	public var inputDir:String;
	// Path that the files are going to be extracted and worked on
	public var tempDir:String;
	// MUST BE SET. Every job can have it's own output dir.
	public var outputDir:String;
	// Size in bytes, useful for reporting
	public var sizeBefore:Int;
	// Size in bytes, useful for reporting
	public var sizeAfter:Int; 
	//-- Job que counter--
	public var queueCurrent:Int; // Current order in the queue
	public var queueTotal:Int;
	public function new() { }
}//--

/**
 * Main CDCRUSH engine
 */
class CDC
{
	//====================================================;
	// SOME STATIC VARIABLES ABOUT THE CDCRUSH ENGINE
	//====================================================;
	
	//--- CDCrush parameters
	public static inline var AUTHORNAME 		= "JohnDimi, twitter@jondmt";
	public static inline var PROGRAM_NAME 		= "CD Crush";
	public static inline var PROGRAM_VERSION 	= "1.1.2";
	public static inline var PROGRAM_SHORT_DESC	= "Dramatically reduce the filesize of CD image games";
	public static inline var CDCRUSH_SETTINGS   = "crushdata.json";
	public static inline var CDCRUSH_EXTENSION  = "arc";
	public static inline var QUALITY_DEFAULT	= 2;
	
	//====================================================;
	// Batch parameters , applies to all files in queue
	//====================================================;
	// Operation mode, one of : [ crush, restore ]
	public static var batch_mode(default,null):String;
	// Global Quality to compress the audio tracks
	// 	1:lowest
	// 	2:normal (default)
	// 	3:high
	//	 4:lossless
	public static var batch_quality(default, null):Int;
	// Hold the text of the audio infos
	public static var audioQualityInfo(default, null):Array<String> = [ 
		'Ogg Vorbis, 96kbps VBR', 
		'Ogg Vorbis, 128kbps VBR',
		'Ogg Vorbis, 196kbps VBR',
		'FLAC, Lossless'
	];
	// Temp dir for file operations
	public static var batch_tempdir(default, null):String;
	// Output directory for the files. If null it's the same as each file's input dir
	public static var batch_outputDir(default, null):String;
	// This will be displayed to the user as the output dir.
	public static var outputDir_Info(default, null):String;
	// If true, then no real file will be processed, and the outputs will be simulated
	public static var simulatedRun:Bool = false;
	
	// FLAG - w - Overwrite files
	public static var flag_overwrite:Bool = false;
	
	// FLAG - f - Restore to folder
	public static var flag_res_to_folders:Bool = false;
	
	// EXPERIMENTAL - s - Restore to a single bin/cue regardless of origin
	public static var flag_single_restore:Bool = false;
	
	//---------------------------------------------------;
	// List of files to process
	static var fileList:Array<String>;
	// Original queue length when the engine was inited
	static var queueTotal:Int;
	// Queue counter
	static var queueCurrent:Int;
	//====================================================;
	
	// User set, push job updates there
	// passthrough , check Job.hx
	public static var onJobStatus:String->Job->Void; // ! MUST BE SET
	// User set, push task updates
	// passthrough, check Task.hx
	public static var onTaskStatus:String->Task->Void;
	// All operations complete
	public static var onComplete:Void->Void;
	
	
	//====================================================;
	// Functions 
	//====================================================;
	
	/**
	 * Init the engine, and set the running parameters
	 * ..
	 * @param	fileList_ File list to process
	 * @param	params Object:
	 * 			{ 
	 * 				quality:int, 1-4, audio quality when crushing 
	 * 				temp:String, temporary dir for operations 
	 * 				mode:String, 'crush' or 'restore'
	 * 				output:String, output dir for the new files
	 * 				sim:Bool, #DEBUG ONLY#, simulation mode
	 * 			}
	 */
	public static function init(fileList_:Array<String>, params:Dynamic)
	{
		// Set the global running parameters
		fileList = fileList_;
		batch_mode = params.mode;
		batch_tempdir = params.temp;
		batch_quality = params.quality;
		batch_outputDir = params.output;
		simulatedRun = params.sim;
		flag_overwrite = params.flag_overwrite;
		flag_res_to_folders = params.flag_res_to_folders;
		flag_single_restore = params.flag_single_restore;
		
		
		queueCurrent = 0;
		queueTotal = fileList.length;
		
		#if debug
		// -- SIMULATED RUN --
		// -  Fake run parameters
		if (simulatedRun) { 
		switch(batch_mode) {
			case "crush":
				fileList = ["c:\\Sonic CD [J].cue"];
				batch_tempdir = "g:\\temp";
				batch_outputDir = "c:\\";
				outputDir_Info = ". (Same as source)";
				batch_quality = 3;
				queueTotal = 1;
				return;
			case "restore":
				fileList = ["c:\\Wipeout [JUE].arc"];
				batch_tempdir = "g:\\temp";
				batch_outputDir = "c:\\";
				outputDir_Info = ". (Same as source)";
				queueTotal = 1;
				return;
		} }
		#end
		
		
		// -------------------------
		// -- Normal run
		// - Assert input parameters 
		
		if (queueTotal == 0) {
			throw 'No files to process';
		}
		
		// It should be checked before, but check again
		if (['crush', 'restore'].indexOf(batch_mode) < 0) {
			throw 'Invalid operation mode ($batch_mode)';
		}
		
		if (batch_quality == null) batch_quality = QUALITY_DEFAULT; else
		if (batch_quality < 1) batch_quality = 1; else
		if (batch_quality > 4) batch_quality = 4;
		
		// -- Check if tempdir is there ( GOING TO BE RECHECKED LATER AT A TASK IF NULL )
		if (batch_tempdir != null)
		{
			// I am not checking for write access here
			// First task is to write there, so if no write access should throw error there.
			batch_tempdir = Path.normalize(batch_tempdir);
			if (!FileTool.pathExists(batch_tempdir)) {
				throw 'Temp dir "$batch_tempdir" does not exist.';
			}
		}
		
		// -- Check output dir
		if (batch_outputDir == null) {
			outputDir_Info = ". (Same as source)";
		}else {
			batch_outputDir = Path.normalize(batch_outputDir);
			outputDir_Info = batch_outputDir + "\\";
		}

		
		// -- Some parameters are sanitized.
		LOG.log('-- CDC RUN PARAMETERS --');
		LOG.log(' mode      = $batch_mode');
		LOG.log(' quality   = $batch_quality');
		LOG.log(' outputDir = $batch_outputDir');
		LOG.log(' tempdir   = $batch_tempdir');
		LOG.log(' files     = $fileList');
		LOG.log('-------------------------');
	}//---------------------------------------------------;

	
	// --
	// Start a new processing job from the next file in queue
	public static function processNextFile()
	{
		var fileToProcess = fileList.shift();
		
		if (fileToProcess == null){
			if (onComplete != null) onComplete();
			return;
		}
		
		// Set the job infos
		var inf:CDCRunParameters = new CDCRunParameters();
		inf.input = Path.normalize(fileToProcess);
		inf.inputDir = Path.dirname(fileToProcess);
		inf.outputDir = batch_outputDir;
		inf.tempDir = batch_tempdir;	   // Pass the root of the tempdir, going to be processed first thing
		
		inf.queueTotal = queueTotal;	   // Just for infos
		inf.queueCurrent = ++queueCurrent; // Just for infos
		
		var job:Job = switch(batch_mode) {
			case "crush": new Job_Crush('crush');
			case "restore": new Job_Restore('restore');
			case _: throw "Critical";
		}
		
		job.sharedData = inf;
		job.onJobStatus = onJobStatus;	// send to user
		job.onTaskStatus = onTaskStatus; // send to user
		job.onComplete = processNextFile;
		
		job.start();
		
	}//---------------------------------------------------;
	
	
	//====================================================;
	// HELPERS
	//====================================================;
	
	// Return a unique string in the form of : "_temp_game_24255362"
	// It's time based so it's unique
	// -- Filename should only be the filename without the ext
	static function generateTempFolderName(filename:String):String
	{
		filename = ~/\s/gi.replace(filename, "");
		return '_temp_${filename}_' + Std.string(Date.now().getTime());
	}//---------------------------------------------------;
	
	// -- Create the temp dir at the proper path
	// returns true if OK, false of something wrong
	public static function createTempDir(par:CDCRunParameters)
	{
		// -- Temp Dir check
		if (par.tempDir == null) {
			par.tempDir = par.outputDir;
		}
		par.tempDir = Path.join(par.tempDir, generateTempFolderName(Path.parse(par.input).name));
	
		// Try to create the temp dir
		try {
			LOG.log('Creating temp directory "${par.tempDir}"');
			FileTool.createRecursiveDir(par.tempDir);
		}catch (e:String) {
			return false;
		}
		return true;
	}//---------------------------------------------------;
	
	
	
	
	
	// --
	public static function isWritable(dir:String)
	{
		// -- Check to see if output dir is writable
		//    I am checking this early because I don't want to have a job
		//    fail halfway because it can't write to some directory. Check it now.
		
		try {
			var testFile = "_cdcrush_test_file_temp";
			// Avoid a bug, where this file exists from a previous failed CDCRUSH process?
			if (FileTool.pathExists(Path.join(dir, testFile)) == false) {
				Fs.writeFileSync(Path.join(dir, testFile), "ok");
			}
			Fs.unlinkSync(Path.join(dir, testFile));
		}catch (e:Dynamic)
		{
			if (!FileTool.pathExists(dir)) {
				throw 'Folder "$dir" does not exist, or can\'t create';
			}else {
				throw 'Can\'t write to output dir "$dir" do you have write access?';
			}
		}
	}//---------------------------------------------------;
	
}//--//