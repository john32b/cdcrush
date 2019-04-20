package;

import djNode.BaseApp;
import djNode.task.CJob;
import djNode.tools.LOG;

/**
 * == CDCRUSH Main Entry
 */
class MainNew extends BaseApp 
{
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
			['e', 'Encoded Audio/Cue', '<Restore> <Crush> to encoded audio files/.cue'],
			['b', 'SubFolder', '<Restore> to a subfolder in output path (autonamed to CD title)'],
			['s', 'Force Single Bin', '<Restore> to a single .bin/.cue '],
			
			['ac', 'CODEC:QUALITY , Audio compression for audio tracks', 
					"Codecs : flac , opus , vorbis , mp3 , tak : (Defaults to flac)\n" +
					"Quality : 0 low, 1 normal, 2 high : (Defaults to 1)\n" +
					"e.g. -ac flac , -ac opus:0, -ac mp3:2", 'yes'],
			['dc', 'ARCHIVER:Compression , Data compression for final archive',
					"Archivers : 7z , zip , arc : (Defaults to arc)\n" +
					"Compression : 0 low, 1 normal, 2 high : (Defaults to 1)\n" +
					"e.g. -dc zip , -dc arc:2", 'yes'],
					
			['t',  'Threads', 'Number of maximum threads allowed for operations (1-8)', 'yes'],
			['tmp', 'Temp Folder', 'Set a custom temp folder for operations', 'yes'],
			['log', 'Set Log File', 'Produce a log file to a path.(e.g. -log c:\\log.txt)', 'yes']
		];
		
		// LOG.pipeTrace();
		
		#if debug
			LOG.setLogFile("a:\\CDCRUSH_LOG.txt", true);
		#end
		
		FLAG_USE_SLASH_FOR_OPTION = true;
		super.init();
	}//---------------------------------------------------;
	
	// --
	override function onStart() 
	{
		printBanner();
		
		#if debug
		T.printf("~red~DEBUG BUILD~!~\n");
		#end
		
		if (argsOptions.log != null)
		{
			LOG.setLogFile(argsOptions.log);
		}
		
		// If null, it defaults
		CDCRUSH.init(argsOptions.temp);
		
		if (argsOptions.threads != null)
		{
			CDCRUSH.setThreads(Std.parseInt(argsOptions.threads));
		}
		
		
	}//---------------------------------------------------;
	// --
	static function main() new MainNew();
	
}// --