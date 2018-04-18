package;

import cd.CDInfos;
import djNode.BaseApp;
import djNode.tools.LOG;

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

	override function init() 
	{
		#if debug
		LOG.setLogFile("a:\\LOG.txt", true);
		#end
		
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
		//ARGS.requireAction = true;
		ARGS.helpInput = "Action is determined by input file extension.\nSupports multiple inputs and wildcards (*.cue)";
		ARGS.helpOutput = "Specify output directory";

		#if debug // -- Tests --
		ARGS.Options.push(['-t1', '','load a cue','yes']);
		ARGS.Options.push(['-t2', '','load json','yes']);
		#end
		
		super.init();
	}//---------------------------------------------------;
	
	override function onStart() 
	{
		printBanner();
		
		CDCRUSH.init();
		
		LOG.log("ACTION = " + argsAction);
	
		if (argsAction == "c")
		{
			LOG.log("Starting a CRUSH JOB");
			
			// test
			var p = new CDCRUSH.CrushParams();
				p.inputFile = argsInput[0];
				p.audio = {id:'flac', quality:0};
				p.compressionLevel = 4;
				
			var j = new JobCrush(p);
				j.start();
				
				
			return;
		}
		
		if (argsAction == "r")
		{
			// test
			var p = new CDCRUSH.RestoreParams();
				p.inputFile = argsInput[0];
				p.flag_subfolder = true;
				//p.flag_encCue = true;
				p.flag_forceSingle = true;
				
			var j = new JobRestore(p);
				j.start();
			return;
		}
		
		
		if (argsOptions.t1 != null)
		{
			var a = new CDInfos();
			CDInfos.LOG = function(a){trace(a); };
			a.cueLoad(argsOptions.t1);
			
			for (tr in a.tracks)
			{
				trace("BEFORE ----- ");
				trace(tr);
				tr.setNewTimesReset();
				//tr.setNewTimesBasedOnSector(); // to singlefile
				trace("AFTER setNewTimesReset() ----- ");
				trace(tr);
			}
			
			return;
		}
		
		if (argsOptions.t2 != null)
		{
			var a = new CDInfos();
			CDInfos.LOG = function(a){trace(a); };
			a.jsonLoad(argsOptions.t2);
		}
		
		LOG.log("OK");
		
	}//---------------------------------------------------;
	
	// --
	static function main()  {
		new Main();
	}//---------------------------------------------------;
	
}// --