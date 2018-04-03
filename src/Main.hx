package;

import djNode.BaseApp;
import djNode.Terminal;
import djNode.task.Job;
import djNode.task.Task;
import djNode.term.info.ActionInfo;
import djNode.tools.LOG;
import djNode.tools.StrTool;


// The main class is separated from the Core CDCRUSH functionality
// This is responsible for setting the running parameters and displaying
// info on the terminal.
// --
class Main extends BaseApp
{	
	// Terminal indo writer object
	var info:ActionInfo;
	
	// Procedure to apply
	var action:String;
	//---------------------------------------------------;
	
	// --
	override function init():Void 
	{
		// djNode App Initialize :
		info_program_name = CDC.PROGRAM_NAME;
		info_program_version = CDC.PROGRAM_VERSION;
		info_program_desc = CDC.PROGRAM_SHORT_DESC;
		info_author = CDC.AUTHORNAME;
		require_input_rule = "yes";
		require_output_rule = "opt";
		support_multiple_inputs = true;
		addParam("c", "Crush", "Crush a cd image file (.cue .ccd files)");
		addParam("r", "Restore", "Restore a crushed image (.arc files)");
		addParam("-t", "Temp Directory", "Set a custom working directory", true);
		addParam("-w", "Force Overwrite", "Overwrite any files", false, false, true );
		addParam("-s", "Single File Restore", "Force restore to a single bin/cue", false, false, true );
		addParam("-f", "Restore to Folders", "Restore ARC files to separate folders", false, false);
		addParam("-q", "Audio compression quality",
						'1 - ${CDC.audioQualityInfo[0]}#nl' +
						'2 - ${CDC.audioQualityInfo[1]}#nl' +
						'3 - ${CDC.audioQualityInfo[2]}#nl' +
						'4 - ${CDC.audioQualityInfo[3]}', true);
						
		#if debug addParam("-sim", "Simulate run", "Debugging purposes"); #end
		
		// Auto crush cue and ccd files
		setActionByFileExt("c", ["cue", "ccd"]);
		
		// Auto restore arc files
		setActionByFileExt("r", [CDC.CDCRUSH_EXTENSION]);
		
		help_text_input = "~darkgray~Action is determined by input file extension.\nSupports multiple inputs and wildcards (*.cue)";
		help_text_output = "~darkgray~Specify output directory.";
		
		// Must set parameters before calling super.init();
		super.init();	
	}//---------------------------------------------------;
	
	// This is autocalled after the init() is done.
	// --
	override function create():Void 
	{ 
		// Clear the screen and start from the top of the console?
		// t.pageDown();
		info = new ActionInfo();
		printBanner();
		
		
		// DEV NOTE: Getting the action from the file only works for the first file only!
		//			 I have got to re-check later for each file extension
		switch(params_Action) {
			case "c": action = "crush"; 
			case "r": action = "restore";
			default: criticalError('Invalid input', true); return;
		}
		
		// -- Display some info if multiple files
		if (params_Input.length > 1) {
			info.printPair("Number of input files", params_Input.length);
			t.printf(" ~darkgray~~line~");
		}
		
		// -- Engine
		CDC.onJobStatus = processJobStatus;
		CDC.onTaskStatus = processTaskStatus;
		CDC.init(params_Input, { 
			mode : action,
			temp : getOptionParameter('-t'),
			sim  : params_Options.exists('-sim'),
			quality: getOptionParameter('-q'),
			output : params_Output,
			flag_overwrite : params_Options.exists('-w'),
			flag_res_to_folders : params_Options.exists('-f'),
			flag_single_restore: params_Options.exists('-s')
		} );
		
		// This will triger the first file of the list
		// all the files will be auto-processed. 
		// Will report progress by checking for status updates callbacks for job and tasks
		CDC.processNextFile(); 
	}//---------------------------------------------------;
	
	// --
	// Can fire [ start, complete, fail ]
	function processJobStatus(status:String, job:Job)
	{		
		var inf:CDC.CDCRunParameters = cast job.sharedData;
		switch(status) {
			
		case "start":
			//t.endl();
			var remain:String = "";
			if (inf.queueTotal > 1) {
				remain = '~darkgray~[${inf.queueCurrent} of ${inf.queueTotal}]';
				// t.printf(remain).endl();
			}
			
			if (CDC.batch_mode == "restore") 
			{
				t.printf(' + ~cyan~Restoring~white~ : ${inf.input} $remain \n~!~');
				info.printPair("Destination", CDC.outputDir_Info);
			}
			else // crash
			{
				t.printf(' + ~cyan~Crushing~white~  : ${inf.input} $remain \n~!~');
				info.printPair("Audio Quality", CDC.audioQualityInfo[CDC.batch_quality - 1]);
				info.printPair("Destination", CDC.outputDir_Info);
			}
						
			t.endl();// this line is going to be deleted by the task info
			
			
			
		case "complete":
			
			// delete the last line, because
			info.deletePrevLine();
			var s0 = StrTool.bytesToMBStr(inf.sizeBefore) + "MB";
			var s1 = StrTool.bytesToMBStr(inf.sizeAfter) + "MB";
			
			if (CDC.batch_mode == "restore")
			{
				info.deletePrevLine();
				info.printPair("Created", inf.cuePath + " + .bins");
				info.printPair("Crushed size", s0);
				info.printPair("Restored Image size", s1);
			}
			else // crush
			{
				info.deletePrevLine();
				info.printPair("Created", inf.crushedArc);
				info.printPair("Number of tracks", inf.cd.tracks_total);
				info.printPair("Raw size", s0);
				info.printPair("Crushed size", s1);
			}
			
			t.printf("~green~ Complete!\n~darkgray~ ~line2~~!~");
			// Cdcrush will autoprocess the next file
			
		case "fail":
			info.reset();
			t.printf(" ~red~ERROR : " + job.fail_log + "~!~\n");
			t.printLine();
			CDC.processNextFile(); // CDC will not manually advance next file, do it manually
			return;
		}
	}//---------------------------------------------------;
	
	// Can fire [ start, complete, progress, fail ]
	function processTaskStatus(status:String, task:Task)
	{	
		// Skip reporting progress for task names starting with '-'
		if (task.name.substr(0, 1) == "-") return;
		
		info.genericProgress(status, task, true);
	}//---------------------------------------------------;
	
	// --
	static function main()  {
		LOG.flag_socket_log = false;
		LOG.logFile = "_log.txt";
		new Main();
	}//---------------------------------------------------;
	
}// --