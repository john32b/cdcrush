package;

import cd.CDInfos;
import djNode.BaseApp;
import djNode.task.CJob;
import djNode.task.CTask;
import djNode.tools.LOG;
import djNode.tools.StrTool;
import djNode.utils.CJobReport;
import js.Node;
import js.node.Path;

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
	// Hold all the files to be processed
	var filesQueue:Array<String>;
	var fileIndex:Int;
	
	// Current active job
	var job:CJob;
	
	// Deco line used as separator in between job infos
	static inline var LINE_WIDTH:Int = 30;
	
	// --
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
		
		
		#if debug
			LOG.pipeTrace();
			LOG.setLogFile("a:\\LOG.txt", true);
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
		
		filesQueue = argsInput.copy();
		fileIndex = 0;
		
		queueStart();
	}//---------------------------------------------------;
	
	
	// --
	function queueStart()
	{
		if (filesQueue.length > 1)
		{
			T.println('Number of input files : ${filesQueue.length}');
			T.drawLine("-", LINE_WIDTH);
		}
			
		queueProcessNext();
	}//---------------------------------------------------;
	
	// --
	function queueComplete()
	{
		if (filesQueue.length > 1)
		{
			T.println("All Done");
		}
		
		Sys.exit(0);
	}//---------------------------------------------------;
	
	// --
	function queueJobComplete(success:Bool)
	{
		// -- Print Post
		if (success)
		{
			// Extra info
			if (job.name == "crush")
			{
				var p:CDCRUSH.CrushParams = job.jobData;
				H2('Created', p.finalArcPath);
				H2('Original size', StrTool.bytesToMBStr(p.cd.CD_TOTAL_SIZE) + "Mb");
				H2('Crushed size', StrTool.bytesToMBStr(p.crushedSize) + "Mb");
				T.printf('~green~- Compressed OK~!~\n');
			}else
			if (job.name == "convert")
			{
				var p:CDCRUSH.CrushParams = job.jobData;
				H2('Created',p.convertedCuePath + " + tracks");
				T.printf('~green~- Converted OK~!~\n');
			}else
			if (job.name == "restore")
			{
				var p:CDCRUSH.RestoreParams = job.jobData;
				H2('Created', p.createdCueFile + " + .bins");
				T.printf('~green~- Restored OK~!~\n');
			}
			
		}else
		{
			T.printf('~red~- Failed : ~yellow~' + job.ERROR.message).endl().reset();
		}
		
		T.drawLine("-", LINE_WIDTH);
		job = null;
		queueProcessNext();		
	}//---------------------------------------------------;	
	
	// --
	function queueProcessNext()
	{
		fileIndex++;
		
		var file = filesQueue[fileIndex-1];
		
		if (file == null)
		{
			queueComplete(); return;
		}
		
		// - CRUSH
		if (argsAction == "c")
		{
			var p = CDCRUSH.getCrushParams(
					file, argsOutput, argsOptions.ac, argsOptions.aq, argsOptions.cl);
					
			if (argsOptions.enc)
			{
				job = new JobConvert(p);
				H1("Converting", file);
			}else
			{
				job = new JobCrush(p);
				H1("Compressing", file);
			}
			
			// wait for new information retrieved at the first task
			job.events.on("taskStatus", _taskStatus_captureInit);
		}
		
		// - RESTORE
		if (argsAction == "r")
		{
			var p = CDCRUSH.getRestoreParams(
					file, argsOutput, argsOptions.single, argsOptions.folder, argsOptions.enc);
			job = new JobRestore(p);
			H1("Restoring", file);
			var rep = new CJobReport(job, true, false);
		}
		
		// --
		var dd:String = (argsOutput == null?". (same as input file)":argsOutput);
		H2('Output Folder :', dd);
		
		job.MAX_CONCURRENT = CDCRUSH.MAX_TASKS;
		job.onComplete = queueJobComplete;
		job.start();
	}//---------------------------------------------------;
	
	// -- Format Text
	function H1(t1:String, f:String)
	{
		var queStr:String = null;
		if (filesQueue.length > 1) {
			queStr = '[$fileIndex / ${filesQueue.length}]';
		}
		
		f = Path.basename(f);
		
		T.printf('+ ~magenta~$t1~white~ : $f ');
		if (queStr != null){
			T.printf('~darkgray~$queStr');
		}
		T.reset().endl();
	}//---------------------------------------------------;
	
	// -- Format Text
	function H2(t1:String, t2:String)
	{
		T.printf('  $t1 : ~yellow~$t2~!~\n');
	}//---------------------------------------------------;
	
	
	// :: capture when the first task has been completed for 
	// ~ "Crush" and "Convert" operations ONLY
	function _taskStatus_captureInit(s:CTaskStatus, t:CTask)
	{
		if (s == CTaskStatus.complete && t.name == "init")
		{
			var p:CDCRUSH.CrushParams = t.jobData;
			H2("Audio", CDCRUSH.getAudioQualityString(p.audio));
			H2("Number of Tracks", Std.string(p.cd.tracks.length));
			job.events.removeListener("taskStatus", _taskStatus_captureInit);
			var rep = new CJobReport(job, true, false);
		}
	}//---------------------------------------------------;
	
	// --
	override function onExit() 
	{
		// A job is working, kill it, so it deletes any temp file created
		if (job != null)
		{
			job.forceKill();
		}
		super.onExit();
	}//---------------------------------------------------;
	
	// --
	static function main()  {
		new Main();
	}//---------------------------------------------------;
	
}// --