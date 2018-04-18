/**----------------------------------------------
 * == CDCRUSH.hx
 *  - @Author: johndimi, <johndimi@outlook.com>
 * ----------------------------------------------
 *  CDCRUSH main engine class, 
 *  responsible for all operations
 * ----------------------------------------------
 * 
 * Notes:
 * 
 * 	-
 * 
 ========================================================*/
 
package;
import app.FFmpegAudio;
import cd.CDInfos;
import djNode.task.CJob;
import djNode.task.CJob.CJobStatus;
import djNode.tools.FileTool;
import djNode.tools.LOG;
import djNode.tools.StrTool;
import js.Error;
import js.Node;
import js.node.Fs;
import js.node.Os;
import js.node.Path;



//   ___ ___     ___ ___ _   _ ___ _  _ 
//  / __|   \   / __| _ \ | | / __| || |
// | (__| |) | | (__|   / |_| \__ \ __ |
//  \___|___/   \___|_|_\\___/|___/_||_|
//

class CDCRUSH
{
	//====================================================;
	// SOME STATIC VARIABLES ABOUT THE CDCRUSH ENGINE
	//====================================================;
	
	// -- Program Infos
	public static inline var AUTHORNAME = "John Dimi";
	public static inline var PROGRAM_NAME = "cdcrush";
	public static inline var PROGRAM_VERSION = "1.3";
	public static inline var PROGRAM_SHORT_DESC = "Highy compress cd-image games";
	public static inline var LINK_DONATE = "https://www.paypal.me/johndimi";
	public static inline var LINK_SOURCE = "https://github.com/johndimi/cdcrush";
	public static inline var CDCRUSH_SETTINGS = "crushdata.json";
	public static inline var CDCRUSH_COVER = "cover.jpg";	// Unused in CLI modes
	public static inline var CDCRUSH_EXTENSION = ".arc";	
	
	// When restoring a cd to a folder, put this at the end of the folder's name
	public static inline var RESTORED_FOLDER_SUFFIX = " (r)";	
	
	// The temp folder name to create under `TEMP_FOLDER`
	// No other program in the world should have this unique name, right?
	// ~~ Shares name with the C# BUILD
	public static inline var TEMP_FOLDER_NAME = "CDCRUSH_361C4202-25A3-4F09-A690";
	
	// Keep temporary files, don't delete them
	// Currently for debug builds only
	public static var FLAG_KEEP_TEMP:Bool = false;
	
	// Maximum concurrent tasks in CJobs
	public static var MAX_TASKS:Int = 2;
	
	// Is FFMPEG ready to go?
	public static var FFMPEG_OK(default, null):Bool;
	
	// FFMPEG path
	public static var FFMPEG_PATH(default, null):String;

	// Relative directory for the external tools (Arc, EcmTools)
	public static var TOOLS_PATH(default, null):String;

	// This is the GLOBAL Temp Folder used for ALL operations
	public static var TEMP_FOLDER(default, null):String;
		
	// General use Error Message, read this to get latest errors from functions
	//public static var ERROR(default, null):String;
	
	// Available Audio Codecs
	public static var AUDIO_CODECS(default, null):Map<String,String> = [
		"flac" => "FLAC",
		"vorbis" => "Ogg Vorbis",
		"opus" => "Ogg Opus",
		"mp3" => "MP3"
	];
	
	// #Externally Set, all Jobs will push progress there
	public static var JOB_STATUS_HANDLER:CJobStatus->CJob->Void = null;
	
	
	// -----
	
	public static function init(?tempFolder:String)
	{
		LOG.log('== ' + PROGRAM_NAME + ' - v ' + PROGRAM_VERSION);
		LOG.log('== ' + PROGRAM_SHORT_DESC);
		LOG.log('== --------------------------');
		
		//
		#if debug
			TOOLS_PATH = "../tools/";
			FFMPEG_PATH = "";
		#else
			TOOLS_PATH = "tools";
			FFMPEG_PATH = "";
		#end
		
		CDInfos.LOG = function(l){ LOG.log(l); }	
		
		// ERROR = null;	// In case of eror/
		
		setTempFolder(tempFolder);
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
	   
	   @param	codecInfo { id, quality }
	   @return
	**/
	public static function getAudioQualityString(codecInfo:AudioCodecParams):String
	{
		var res:String = AUDIO_CODECS.get(codecInfo.id) + ' ';		
		switch(codecInfo.id) {
			case 'flac':
				res += "Lossless";
			case 'vorbis':
				res += FFmpegAudio.VORBIS_QUALITY[codecInfo.quality] + 'k Vbr';
			case 'opus' : 
				res += FFmpegAudio.OPUS_QUALITY[codecInfo.quality] + 'k Vbr';
			case 'mp3':
				res += FFmpegAudio.MP3_QUALITY[codecInfo.quality] + 'k Vbr';
		}
		return res;
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
			throw "Can't join paths (" + A + " + " + B + " ) ";
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
	   ~Throws Errors
	   @param ext Extension WITH "."
	**/
	public static function checkFileQuick(file:String, ext:String)
	{
		if (!FileTool.pathExists(file))
		{
			throw "File does not exist " + file;
		}
		
		if (Path.extname(file).toLowerCase() != ext)
		{
			throw "File, not valid extension " + file;
		}

	}//---------------------------------------------------;

	// --
	public static function getSubTempDir():String
	{
		return Path.join(TEMP_FOLDER , StrTool.getGUID().substr(0, 12));
	}//---------------------------------------------------;
	
	//====================================================;
	// JOBS
	//====================================================;
	
	public static function startJob_ConvertCue()
	{
		
	}
	
	public static function startJob_CrushCD()
	{
	}
	
	public static function startJob_RestoreCD()
	{
	}
	
	
	
	
	
	//====================================================;
	// TESTS 
	//====================================================;
	
	#if debug
	// Simple small unit tests
	// Tests some functions and objects
	// @param tempFolder : A temporary folder for operations (ROOT) a subfolder will be created
	public static function doTest(testFolder:String="")
	{
		trace('== CDRUSH UNIT TESTS ==');
		trace('-----------------------');
		
		var pcmFile = "C:/Mega/projects/cdcrush.nodejs/tests/audio.pcm";
		testFolder = Path.join(testFolder , "//_cdcrush_tests");
		
		// Delete the folder
		if (FileTool.pathExists(testFolder))
		{
			trace('- Test Unit Test Folder : "$testFolder" exists. Deleting.....');
			FileTool.deleteRecursiveDir(testFolder);
			trace(">> OK");
		}
		
		trace('- Creating Unit Test Folder : "$testFolder"');
		Fs.mkdirSync(testFolder);
		trace(">> OK");
		
		// --
		trace('- Setting Temp Folder to "$testFolder"');
		setTempFolder(testFolder);
		trace(">> OK");
		
		// --
		var tf2 = Path.join(testFolder, "test");
		trace('- CheckCreateUniqueOutput($tf2);');
		checkCreateUniqueOutput(tf2);
		checkCreateUniqueOutput(testFolder, 'test');
		if (!FileTool.pathExists(tf2)) throw "Error";
		if (!FileTool.pathExists(tf2 + "_")) throw "Error";
		trace(">> OK.");
		// --
		trace("- GetAudioQualityString() Some Formats ::");
		trace(getAudioQualityString({id:"flac",quality:0}));
		trace(getAudioQualityString({id:"vorbis", quality:3}));
		trace(getAudioQualityString({id:"opus", quality:3}));
		trace(getAudioQualityString({id:"mp3", quality:3}));
		trace(">> OK");
		//--
		
		trace("-- Testing MD5 Calculator");
		var	h = FileTool.getFileMD5(pcmFile);
		if (h == "0181f9b11744c19c9e3142b3a5124855") trace(">> OK same"); else trace(">> ERROR");
		
		//--
		
		var g = new TaskRestoreTrack(null);
		
		
	}//---------------------------------------------------;
	#end
	
}//-- end class








//====================================================;
// TYPES 
//====================================================;



// - Describe an encoding Audio Quality
typedef AudioCodecParams = {
	id:String,	// check CDCRUSH.AUDIO_CODECS
	quality:Int
}// --


/**
   Object storing all the parameters for :
   - CRUSH job
   - CONVERT job
**/
class CrushParams
{
	public function new(){}
	// -- Input Parameters -- //
	
	// The CUE file to compress
	public var inputFile:String;
	// Output Directory, The file will be autonamed
	// ~ Optional ~ Defaults to the directory of the `inputfile`
	public var outputDir:String;
	// Audio settings for encoding
	public var audio:CDCRUSH.AudioCodecParams;
	// ARC compression level, 0-9 (engine default to 4)
	public var compressionLevel:Int;

	// -- Internal Access -- //
	
	// Keep the CD infos of the CD, it is going to be read later
	public var cd:CDInfos;
	// Filesize of the final archive
	public var crushedSize:Int;
	// Temp dir for the current batch, it's autoset, is a subfolder of the master TEMP folder.
	public var tempDir:String;
	// Final destination ARC file, autogenerated from CD TITLE
	public var finalArcPath:String;
	// If true, then all the track files are stored in temp folder and safe to delete
	public var flag_sourceTracksOnTemp:Bool;
	// USED in `JobConvertCue`
	public var flag_convert_only:Bool;
	
}// --




/**
   Object storing all the parameters for 
   - RESTORE job
**/
class RestoreParams
{
	public function new(){}
	// -- Input Parameters -- //
	
	// The file to restore the CDIMAGE from
	public var inputFile:String;
	
	// Output Directory. Will change to subfolder if `flag_folder`
	// ~ Optional ~ Defaults to the directory of the `inputfile`
	public var outputDir:String;
	
	// TRUE: Create a single cue/bin file, even if the archive was MULTIFILE
	public var flag_forceSingle:Bool;
	
	// TRUE: Create a subfolder with the game name in OutputDir
	public var flag_subfolder:Bool;
	
	// TRUE: Will not restore audio tracks. Will create a cue with enc audio 
	public var flag_encCue:Bool;
	
	// : Internal Use :

	// Temp dir for the current batch, it's autoset by Jobs
	// is a subfolder of the master TEMP folder
	public var tempDir:String;
	// Keeps the current job CDINfo object
	public var cd:CDInfos;
	
}// --