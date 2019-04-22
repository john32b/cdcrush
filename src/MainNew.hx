package;

import djNode.BaseApp;
import djNode.task.CJob;
import djNode.tools.LOG;

/**
 * == CDCRUSH Main Entry
 */
class MainNew extends BaseApp 
{
	static function main() new MainNew();
	
	// Deco line used as separator in between job infos
	static inline var LINE_WIDTH:Int = 30;
	
	// Current active job
	var job:CJob;
	
	override function init() 
	{		
		// --
		PROGRAM_INFO.name = CDCRUSH.PROGRAM_NAME;
		PROGRAM_INFO.version = CDCRUSH.PROGRAM_VERSION;
		PROGRAM_INFO.desc = CDCRUSH.PROGRAM_SHORT_DESC;
		PROGRAM_INFO.executable = "cdcrush";
		PROGRAM_INFO.author = CDCRUSH.AUTHORNAME;
		PROGRAM_INFO.info = CDCRUSH.LINK_SOURCE;
		
		// --
		ARGS.Actions = [
			['c', 'crush', 'Compress a CD image file.', "cue"],
			['r', 'restore', 'Restore a compressed CD.', "arc,7z,zip"]
		];
		
		ARGS.requireAction = true;
		ARGS.inputRule 	= "multi";
		ARGS.helpInput  = "Action is determined by input file extension.\nSupports multiple inputs and wildcards (*.cue)";
		ARGS.helpOutput = "Specify an output directory (optional)";
		
		// --
		ARGS.Options = [
			['nosub', 'No SubFolder', 'On <Restore>, do not create a subfolder in <output> for the new files'],
			['enc', 'Encoded Audio/Cue', '<Restore> <Crush> to encoded audio files/.cue'],
			['sb', 'Force Single Bin', '<Restore> to a single .bin/.cue '],
			
			['ac', 'CODEC:QUALITY , Audio compression for audio tracks', 
					"Codecs : flac , opus , vorbis , mp3 , tak : (Defaults to flac)\n" +
					"Quality : 0 low, 1 normal, 2 high : (Defaults to 1)\n" +
					"e.g. -ac flac , -ac opus:0, -ac mp3:2", 'yes'],
			['dc', 'ARCHIVER:Compression , Data compression for final archive',
					"Archivers : 7z , zip , arc : (Defaults to arc)\n" +
					"Compression : 0 low, 1 normal, 2 high : (Defaults to 1)\n" +
					"e.g. -dc zip , -dc arc:2", 'yes'],
					
			['th',   'Threads', 'Number of maximum threads allowed for operations (1-8) (Default = ${CDCRUSH.MAX_TASKS})', 'yes'],
			['tmp', 'Temp Folder', 'Set a custom temp folder for operations', 'yes'],
			['nfo', 'Save Info', 'Produce an info .txt file next to the produced files\ncontaining general infos, like track MD5 and sizes']
		];
		
		// LOG.pipeTrace();
		
		#if debug
			LOG.setLogFile("a:\\CDCRUSH_LOG.txt", true);
		#end
		
		super.init();
	}//---------------------------------------------------;
	
	// --
	override function onStart() 
	{
		printBanner();
		
		#if debug
			T.printf("~red~DEBUG BUILD~!~\n");
			//CDCRUSH.FLAG_KEEP_TEMP = true;
		#end
				
		// If null, it defaults
		CDCRUSH.init(argsOptions.tmp);
		
		if (argsOptions.th != null)
		{
			CDCRUSH.setThreads(Std.parseInt(argsOptions.th));
		}
		
		CDCRUSH.FLAG_NFO = argsOptions.nfo;
		
		var AC, DC:String; AC = DC = null;
		
		if (argsOptions.ac != null)
		{
			AC = CodecMaster.normalizeAudioSettings(argsOptions.ac);
			if (AC == null) exitError("Invalid Audio Codec String.",true);
		}		
		
		if (argsOptions.dc != null)
		{
			DC = CodecMaster.normalizeArchiverSettings(argsOptions.dc);
			if (DC == null) exitError("Invalid Archiver String", true);
		}
		
		if (argsAction == "c")
		{
			trace("CRUSHING A CD");
			var j = new JobCrush({
				inputFile:argsInput[0],
				outputDir:argsOutput,
				ac:AC,
				dc:DC,
				flag_convert_only:argsOptions.enc
			});
			j.MAX_CONCURRENT = CDCRUSH.MAX_TASKS;
			j.start();
		}else
		
		if (argsAction == "r")
		{
			trace("RESTORING A CD");
			var j = new JobRestore({
				inputFile:argsInput[0],
				outputDir:argsOutput,
				flag_forceSingle:argsOptions.sb,
				flag_nosub:argsOptions.nosub,
				flag_encCue:argsOptions.enc
			});
			j.MAX_CONCURRENT = CDCRUSH.MAX_TASKS;
			j.start();
		}
	}//---------------------------------------------------;

}// --