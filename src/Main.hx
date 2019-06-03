package;

import djNode.BaseApp;
import djNode.task.CJob;
import djNode.tools.LOG;
import djNode.tools.StrTool;
import djNode.utils.CJobReport;
import djNode.utils.Print2;

/**
 * == CDCRUSH Main Entry
 */
class Main extends BaseApp 
{
	static function main() new Main();
	// Current active job
	var job:CJob;
	var AC:String;
	var DC:String;
	// Advanced Prints
	var P2:Print2;
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
			['r', 'restore', 'Restore a compressed CD.', "arc,7z,zip"],
			#if EXTRA_TESTS
			// Check `test\Tests.hx`
			['test', 'Components Test', 'Run some basic tests for various components, Arguments :\n1:Component Test\n2:Gui Test']
			#end
		];
		ARGS.requireAction = true;
		ARGS.inputRule 	= "multi";
		ARGS.helpInput  = "Action is determined by input file extension.\nSupports multiple inputs and wildcards (*.cue)";
		ARGS.helpOutput = "Specify an output directory (optional)";
		// --
		ARGS.Options = [
			['nosub', 'No SubFolder', 'On <Restore>, do not create a subfolder in <output> for the new files'],
			['enc', 'Encoded Audio/Cue', '<Restore> / <Crush> to encoded audio files/.cue\n' +
					'If you specify an archiver with (-dc) files will be put inside an archive.'],
			['merge', 'Force Single Bin', '<Restore> tracks into a single .bin/.cue '],
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
		
		#if debug
			LOG.setLogFile("a:\\CDCRUSH_LOG.txt");
		#end
		
		P2 = new Print2(T);
		P2.style(0, "yellow");
		P2.style(1, "cyan");
		super.init();
	}//---------------------------------------------------;
	
	override function onExit(c:Int) 
	{
		super.onExit(c);
		if (c == 1223){ // CTRL + C
			if (job != null) job.kill();
			T.printf("\n~bg_yellow~~black~ - Aborted - ~!~\n");
		}
	}//---------------------------------------------------;
	
	// --
	override function onStart() 
	{
		printBanner();
	
		#if debug
			T.printf("~red~ - DEBUG BUILD - ~!~\n");
			// CDCRUSH.FLAG_KEEP_TEMP = true;
		#end
		
		#if EXTRA_TESTS
			if (argsAction == 'test') 
			{
				var test = new test.Tests();
				var t = Std.parseInt(argsInput[0]);
				if (t == 1) test.TEST_Components(); else
				if (t == 2) test.TEST_Gui();
				return;
			}
		#end
		
		// -- Initialize and Process Input Parameters
		try{
			CDCRUSH.init(argsOptions.tmp); // Note: If null, it defaults to
		}catch (e:Dynamic){
			exitError(e);
		}
		
		if (argsOptions.th != null) {
			CDCRUSH.setThreads(Std.parseInt(argsOptions.th));
		}
		
		CDCRUSH.FLAG_NFO = argsOptions.nfo;
		
		AC = DC = null;
		if (argsOptions.ac != null)
		{
			AC = CodecMaster.normalizeAudioSettings(argsOptions.ac);
			if (AC == null) exitError("Invalid Audio Codec String.",true);
		}else{
			AC = CodecMaster.DEFAULT_AUDIO_PARAM;
		}
		
		if (argsOptions.dc != null)
		{
			DC = CodecMaster.normalizeArchiverSettings(argsOptions.dc);
			if (DC == null) exitError("Invalid Archiver String", true);
		}else{
			DC = CodecMaster.DEFAULT_ARCHIVER_PARAM;
		}
		
		
		// -- Print the running arguments
		// --
		if (argsAction == "r") {
			P2.print1('Action : {0}', ['Restore']);
			var flags:String = 	((argsOptions.merge)?"(Merge) ":"") +
								((argsOptions.nosub)?"(No Subfolder) ":"") +
								((argsOptions.enc)?"(Encoded Audio) ":"");
			if (flags.length > 0)
				P2.print1('Flags  : {0}', [flags]);
		}else
		if (argsAction == "c")
		{
			if (argsOptions.enc){
				P2.print1('Action  : {0}', ['Convert']);
			}
			else{
				P2.print1('Action  : {0}', ['Crush']);
				P2.print1('Archive : {0}', [CodecMaster.getArchiverInfo(CodecMaster.getSettingsTuple(DC))]);
			}
			
			P2.print1('Audio   : {0}', [CodecMaster.getAudioQualityInfo(CodecMaster.getSettingsTuple(AC))]);
		}
		
		if(argsOptions.nfo){
			P2.print1('Output  : {0}', [((argsOutput == null)?'.(same as source)':argsOutput)]);
		}
		
		T.drawLine();
		
		// -- Start Processing
		do_nextFile();
	}//---------------------------------------------------;
	
	
	/**
	   Process the next input file
	   - Present running parameters info:
	   - 
	**/
	function do_nextFile()
	{
		var f = argsInput.shift();
		
		if (f == null) {
			LOG.log("[END] - All input files processed");
			Sys.exit(0);
		}
		
		//
		var postInfos:CJob->Void = null;
		
		if (argsAction == "r") {
			job = new JobRestore({
				inputFile:f,
				outputDir:argsOutput,
				flag_forceSingle:argsOptions.merge,
				flag_nosub:argsOptions.nosub,
				flag_encCue:argsOptions.enc
			});
			postInfos = (_)->{
				var j:JobRestore = cast job;
				P2.print1('  Created : {0}', [j.createdCueFile + ' + bins']);
				P2.print1('  Size : {1} -> {0}', [StrTool.bytesToMBStr(j.original_size)+'MB', StrTool.bytesToMBStr(j.final_size)+'MB']);
			};
			
		}else if (argsAction == "c") {
			job = new JobCrush({
				inputFile:f,
				outputDir:argsOutput,
				ac:AC, dc:DC,
				flag_convert_only:argsOptions.enc
			});
			
			if(argsOptions.enc)
				postInfos = (_)->{ // CONVERT
					var j:JobCrush = cast job;
					P2.print1('  Created : {0}', [j.convertedCuePath + ' + bins']);
					P2.print1('  Size : {1} -> {0}', [StrTool.bytesToMBStr(j.original_size)+'MB', StrTool.bytesToMBStr(j.final_size)+'MB']);
				};
			else
				postInfos = (_)->{ // CRUSH
					var j:JobCrush = cast job;
					P2.print1('  Created : {0}', [j.final_arc]);
					P2.print1('  Size : {1} -> {0}', [StrTool.bytesToMBStr(j.original_size)+'MB', StrTool.bytesToMBStr(j.final_size)+'MB']);					
				};
		}
		// This will autoprint JOB progress
		var rep = new CJobReport(job, false, true);
			rep.onComplete = postInfos;
		
		job.MAX_CONCURRENT = CDCRUSH.MAX_TASKS;
		job.onComplete = do_nextFile;
		job.start();
	}//---------------------------------------------------;
	
}// --