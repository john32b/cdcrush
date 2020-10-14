/*----------------------------------------------
 *   ___ ___     ___ ___ _   _ ___ _  _ 
 *  / __|   \   / __| _ \ | | / __| || |
 * | (__| |) | | (__|   / |_| \__ \ __ |
 *  \___|___/   \___|_|_\\___/|___/_||_|
 * 
 * == CDCRUSH.hx
 * @author: JohnDimi, <johndimi@outlook.com>
 * ----------------------------------------------
 * - CDCRUSH main engine class
 * ----------------------------------------------
 * 
 * ---------------------------------------------- */

package;
import app.FFmpeg;
import cd.CDInfos;
import djNode.tools.FileTool;
import djNode.tools.HTool;
import djNode.tools.LOG;
import djNode.tools.StrTool;
import js.lib.Error;
import js.Node;
import js.node.Fs;
import js.node.Os;
import js.node.Path;


class CDCRUSH
{
	//====================================================;
	// SOME STATIC VARIABLES 
	//====================================================;
	
	// -- Program Infos
	public static inline var AUTHORNAME = "John Dimi";
	public static inline var PROGRAM_NAME = "cdcrush";
	public static inline var PROGRAM_VERSION = "1.5.1";
	public static inline var PROGRAM_SHORT_DESC = "Highly compress cd-image games";
	public static inline var LINK_DONATE = "https://www.paypal.me/johndimi";
	public static inline var LINK_SOURCE = "https://github.com/johndimi/cdcrush";
	public static inline var CDCRUSH_SETTINGS = "crushdata.json";
	public static inline var CDCRUSH_COVER = "cover.jpg";	// Unused in CLI modes
	public static inline var CUE_EXTENSION = ".cue";
	
	public static inline var INFO_SUFFIX = " (cdcrush)";
	
	// When restoring a cd to a folder, put this at the end of the folder's name
	public static inline var RESTORED_FOLDER_SUFFIX = " (r)";	
	
	// The temp folder name to create under `TEMP_FOLDER`
	// No other program in the world should have this unique name, right?
	// ~~ Shares name with the C# BUILD
	public static inline var TEMP_FOLDER_NAME = "CDCRUSH_361C4202-25A3-4F09-A690";
	
	// Keep temporary files, don't delete them
	// Useful for debugging
	public static var FLAG_KEEP_TEMP:Bool = false;
	
	// Maximum concurrent tasks in CJobs
	public static var MAX_TASKS(default, null):Int = 2;
	
	// Is FFMPEG ready to go?
	public static var FFMPEG_OK(default, null):Bool;
	
	// FFMPEG path
	public static var FFMPEG_PATH(default, null):String;

	// Relative directory for the external tools (Arc, EcmTools)
	public static var TOOLS_PATH(default, null):String;

	// This is the GLOBAL Temp Folder used for ALL operations
	public static var TEMP_FOLDER(default, null):String;
	
	// GLOBAL
	// If true, all operations will produce an info .txt file
	public static var FLAG_NFO:Bool = false;
	
	/**
	   Initialize CDCRUSH 
	   @param	tempFolder
	**/
	public static function init(?tempFolder:String)
	{
		LOG.log('== ' + PROGRAM_NAME + ' - v ' + PROGRAM_VERSION);
		LOG.log('== ' + PROGRAM_SHORT_DESC);
		#if EXTRA_TESTS
		LOG.log('== DEFINED : EXTRA_TESTS');
		LOG.log('== > Test Suite accessible.');
		LOG.log('== > Will do extra checksum checks on all operations.');
		#end
		LOG.log('== ------------------------------------------------- \n');
		
		// Works for NPM and DEBUG builds
		TOOLS_PATH = Path.join( Path.dirname(Node.process.argv[1]), "../tools/");
		FFMPEG_PATH = "";
		
		#if STANDALONE
			// Everying is included in there
			TOOLS_PATH = "tools/";
			FFMPEG_PATH = "tools/";
		#end
		
		CDInfos.LOG = (l)->LOG.log(l);
		
		setTempFolder(tempFolder);
		
		var f = new FFmpeg(FFMPEG_PATH);
		if (!f.exists()) {
			throw "Could not find ffmpeg.exe. Make sure it is set on system/user path";
		}
	}//---------------------------------------------------;
	
	// --
	public static function setThreads(t:Int)
	{
		HTool.inRange(t, 1, 8);
		MAX_TASKS = t;
		LOG.log("== MAX_TASKS = " + MAX_TASKS);
	}//---------------------------------------------------;
	
	/**
	   Try to set a temp folder, Returns success
	   @param	f The ROOT folder in which the temp folder will be created
	   @return  SUCCESS 
	**/
	public static function setTempFolder(?tmp:String)
	{
		var TEST_FOLDER:String;
		
		if (tmp == null) tmp = Os.tmpdir();
		
		TEST_FOLDER = Path.join(tmp, TEMP_FOLDER_NAME);
		
		try{
			FileTool.createRecursiveDir(TEST_FOLDER);
		}catch (e:String){
			LOG.log("Can't Create Temp Folder : " + TEST_FOLDER, 4);
			LOG.log(e, 4);
			throw "Can't Create Temp Folder : " + TEST_FOLDER;
		}
		
		// Write Access
		if (!FileTool.hasWriteAccess(TEST_FOLDER))
		{
			throw "Don't have write access to Temp Folder : " + TEST_FOLDER;
		}
		
		TEMP_FOLDER = TEST_FOLDER;
		LOG.log("+ TEMP FOLDER = " + TEMP_FOLDER);
	}//---------------------------------------------------;
	
	/**
	   Check if path exists and create it
	   If it exists, rename it to a new safe name, then return the new name
	**/
	public static function checkCreateUniqueOutput(A:String, B:String = ""):String
	{
		var path:String = "";
		
		try{
			path = Path.join(A, B);
		}catch (e:Error){
			throw 'Can`t join paths ($A + $B)';
		}
		
		while (FileTool.pathExists(path))
		{
			path = path + "_";
			LOG.log("! OutputFolder Exists, new name: " + path);
		}
	
		// Path now is unique
		try{
			FileTool.createRecursiveDir(path);
		}catch (e:String){
			throw "Can't create " + path;
		}
	
		// Path is created OK
		return path;
	}//---------------------------------------------------;
	
	/**
	   Check if file EXISTS and is of VALID EXTENSION
	   @Throws
	   @param ext Extension WITH "."
	**/
	public static function checkFileQuick(file:String, ext:Array<String>)
	{
		if (!FileTool.pathExists(file))
		{
			throw "File does not exist " + file;
		}
		
		if ( ext.indexOf(Path.extname(file).toLowerCase()) < 0)
		{
			throw "File, not valid extension " + file;
		}

	}//---------------------------------------------------;

	// --
	// Get a unique named temp folder ( inside the main temp folder )
	public static function getSubTempDir():String
	{
		return Path.join(TEMP_FOLDER , StrTool.getGUID().substr(0, 12));
	}//---------------------------------------------------;

}// -- end class


//====================================================;
// TYPES 
//====================================================;

/**
   Object storing all the parameters for :
   - CRUSH job
   - CONVERT job
**/
typedef CrushParams = {
	// The CUE file to compress
	inputFile:String,
	// Output Directory, The file will be autonamed
	// If null, will be set to the same dir as <inputfile>
	?outputDir:String,
	// Audio Settings String (e.g OPUS:1, MP3:1) Null for default ( defined in CodecMaster )
	?ac:String,
	// Data Compression String (e.g. 7Z:2, ARC ) Null for default ( defined in CodecMaster )
	?dc:String,
	// Do not Create Archive, Just Convert Audio Tracks (USED in `JobConvert`) Default to FALSE
	flag_convert_only:Bool
}// --

/**
   Object storing all the parameters for :
   - RESTORE job
**/
typedef RestoreParams = {
	// The file to restore the CDIMAGE from
	inputFile:String,
	// Output Directory. Will change to subfolder if `flag_folder`
	// Defaults to the directory of the `inputfile`
	?outputDir:String,
	// TRUE: Create a single cue/bin file, even if the archive was MULTIFILE
	flag_forceSingle:Bool,
	// TRUE: DO NOT Create a subfolder with the game name in OutputDir
	flag_nosub:Bool,
	// TRUE: Will not restore audio tracks to PCM. Will create CUE with Encoded Audio Files
	flag_encCue:Bool
};