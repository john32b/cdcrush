package;

import cd.CDInfos;
import djNode.BaseApp;
import djNode.task.CJob;
import djNode.tools.LOG;
import djNode.utils.CJobReport;

/**
 * == CDCRUSH Main Entry for CLI
 *    Responsible for :
 * 
 * - Reading Input Parameters
 * - Interacting with the CDCRUSH engine
 * - Reading CDCRUSH Jobs and outputing status infos
 * 
 */
class Main extends BaseApp 
{

	// --
	var filesQueue:Array<String>;

	
	override function init() 
	{		
		//--
		PROGRAM_INFO.name = CDCRUSH.PROGRAM_NAME;
		PROGRAM_INFO.version = CDCRUSH.PROGRAM_VERSION;
		PROGRAM_INFO.desc = CDCRUSH.PROGRAM_SHORT_DESC;
		PROGRAM_INFO.executable = "cdcrush";
		PROGRAM_INFO.author = CDCRUSH.AUTHORNAME;
		PROGRAM_INFO.contact = CDCRUSH.LINK_SOURCE;
		
		//
		ARGS.Actions.push(['c', 'crush', 'Crush a CD image file', "cue"]);
		ARGS.Actions.push(['r', 'restore', 'Restore a crushed image', "arc"]);

		ARGS.requireAction = true;
		
		ARGS.helpInput = "Action is determined by input file extension.\nSupports multiple inputs and wildcards (*.cue)";
		ARGS.helpOutput = "Specify output directory";

		// flags ::
		ARGS.Options.push(['-folder',  'Folder','Restore to a subfolder named after the CD title']);
		ARGS.Options.push(['-enc', 'Encoded Audio/Cue','Restore/Convert to encoded audio files/.cue\nCan be used by crush and restore operations.']);
		ARGS.Options.push(['-single',  'Force Single Bin','Restore to a single .bin/.cue ']);
		
		// other ::
		ARGS.Options.push(['-temp', 'Temp Folder', 'Set a custom temp folder for operations', 'yes']);
		ARGS.Options.push(['-log', 'Log File', 'Produce a log file to a path.(e.g. -log c:\\log.txt)', 'yes']);
		
		// codecs ::
		ARGS.Options.push(['-ac', 'Audio Codec', 'Select an audio codec for encoding audio tracks\n' +
				"'flac','opus','vorbis','mp3'", 'yes']);
		ARGS.Options.push(['-aq', 'Audio Quality', 'Select an audio quality for the audio codec\n' +
				"0:lowest, 10:highest (Ignored in FLAC)", 'yes']);
				
		ARGS.Options.push(['-cl', 'Compression Level', 'FreeArc compression Level,\n0:Fastest, 4:Default, 9:Highest(not recommended)', 'yes']);
		
		ARGS.Options.push(['-threads', 'Threads', 'Number of maximum threads allowed for operations (1-8)', 'yes']);
		
		
		#if debug
		LOG.setLogFile("a:\\LOG.txt", true);
		#end
		
		super.init();
	}//---------------------------------------------------;
	
	override function onStart() 
	{
		printBanner();
		
		if (argsOptions.log != null){
			LOG.setLogFile(argsOptions.log);
		}
		
		// If temp is set it will set it, if null it will set a default temp folder
		CDCRUSH.init(argsOptions.temp);
		
		if (argsOptions.threads != null){
			CDCRUSH.setThreads(Std.parseInt(argsOptions.threads));
		}
		
		filesQueue = argsInput.copy();
		
		processNextFile();
		
	}//---------------------------------------------------;
	
	
	// --
	function processNextFile()
	{
		var file = filesQueue.shift();
		
		trace("Processing " + file);
		
		var job:CJob;
		
		// - CRUSH
		if (argsAction == "c")
		{
			var p = CDCRUSH.getCrushParams(
					file, argsOutput, argsOptions.ac, argsOptions.aq, argsOptions.cl);
			job = new JobCrush(p);
			var rep = new CJobReport(job, true, true);
			job.start();			
		}
		
		// - RESTORE
		if (argsAction == "r")
		{
			var p = CDCRUSH.getRestoreParams(
					file, argsOutput, argsOptions.single, argsOptions.folder, argsOptions.enc);
			job = new JobRestore(p);
			var rep = new CJobReport(job);
			job.start();			
		}		
		
	}//---------------------------------------------------;
	
	
	// --
	static function main()  {
		new Main();
	}//---------------------------------------------------;
	
}// --