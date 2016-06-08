package;

import djNode.app.Arc;
import djNode.task.FakeTask;
import djNode.task.Job;
import CDC;
import djNode.task.Task;
import djNode.task.Task.Qtask;
import djNode.term.UserAsk;
import djNode.tools.CDInfo;
import djNode.tools.FileTool;
import djNode.tools.LOG;
import js.node.Fs;
import js.node.Path;

/**
 * Create a job that will Crush a file.
 * ---------------------------------------------
 * This job gets running parameters from the 
 * taskData object which is set in the CDC class
 * Also might use some CDC static vars.
 * ---------------------------------------------
 */
class Job_Crush extends Job
{
	// Pointer to sharedData, I am doing this to get intellisense 
	var par:CDCRunParameters;
	
	//====================================================;
	override public function start():Void 
	{
		// Easy access, intellisense
		par = cast sharedData;
		
		#if debug 
		if (CDC.simulatedRun) {
			addQueue_simulate(); super.start(); return;
		}
		#end
		
		// -- Tasks are going to be executed sequentially.
		
		// --
		add(new Task_CheckFFMPEG());
		
		// --
		add(new Qtask("-loadingImageInfo", function(t:Qtask) {

			// -- Check to see if the output dir is writable
			// -- Generate output Folder
			if (par.outputDir == null) {
				par.outputDir = par.inputDir;
			}
			CDC.isWritable(par.outputDir);
			
			// Try to load the file
			// IF the file is not supported or it does not exist, CDINFO will throw error
			try{
				par.cd = new CDInfo(par.input);
			}catch (e:String) {
				t._fail(e); return;
			}
			
			par.sizeBefore = par.cd.total_size;
			
			LOG.log('Loaded ${par.input}');
			LOG.log('Image TITLE = ${par.cd.TITLE}');

			var arcFile = par.cd.TITLE + "." + CDC.CDCRUSH_EXTENSION;
			
			par.crushedArc = Path.join(par.outputDir, arcFile);
			LOG.log('Setting output file to ${par.crushedArc}');
			
			// Try to see if the output file already exists
			if (FileTool.pathExists(par.crushedArc) && !CDC.flag_overwrite) {
				throw '"$arcFile" already exists. \n Run with -w to overwrite files';
			}
			
			// Try to create the temp dir, which is input filename specific
			if (!CDC.createTempDir(par)) {
				t._fail('Could not create tempdir at "${par.tempDir}"' , "IO"); 
				return;
			}
			
			if (par.cd.isMultiImage == false)
			{
				addNext(new Task_CutTracks());
			}
			
			t._complete();
			
		}));
		
		
		// -- Compress the tracks
		add(new Qtask("-postCut", function(t:Qtask) {
			// Add as many tasks as there are tracks.
			var c = par.cd.tracks_total;
			while (--c >= 0) {
				this.addNext(new Task_CompressTrack(par.cd.tracks[c]));
			}
			t._complete();
		}));
		
		// -- Create and Save the CDCRUSH SETTINGS file
		add(new Qtask('-saveSettings', function(t:Qtask) {
			par.cd.self_save(Path.join(par.tempDir, CDC.CDCRUSH_SETTINGS));
			t._complete();
		}));
	
		
		// This is going to be accessed from the 2 tasks below
		var listOfFilesToCompress:Array<String>;
		
		// -- Compress files to ARC
		add(new Qtask('Compressing', function(t:Qtask) {
			t.progress_type = "percent";
			var arc = new Arc();
			arc.events.once("close", function(st:Bool) {
				if (st) 
					t._complete(); 
				else 
					t._fail(arc.error_log, arc.error_code);
			});
			arc.events.on("progress", function(p:Int) {
				t.progress_percent = p;
				t.onStatus("progress", t);
			});
			
			listOfFilesToCompress = [];
			listOfFilesToCompress = [Path.join(par.tempDir, CDC.CDCRUSH_SETTINGS)];
			for (i in par.cd.tracks) {
				listOfFilesToCompress.push(Path.join(par.tempDir, i.filename));
			}
			arc.compress(listOfFilesToCompress, par.crushedArc);
			
		}));
		
		// -- ARC is done, delete files
		add(new Qtask("-cleaning", function(t:Qtask) {
			for (i in listOfFilesToCompress) {
				LOG.log('Deleting "$i"');
				Fs.unlinkSync(i);
			}
			LOG.log('Deleting "${par.tempDir}"');
			Fs.rmdirSync(par.tempDir);

			par.sizeAfter = Std.int(Fs.statSync(par.crushedArc).size);
			t._complete();
		}));
		
		// -- Rnu the job.
		super.start();
		
	}//---------------------------------------------------;
	
	//====================================================;
	// SIMULATE A RUN TO CHECK THE PROGRESS INDICATORS
	//====================================================;
	#if debug function addQueue_simulate()
	{
		// Report some bogus values
		var gamename = Path.parse(Path.basename(par.input)).name;
		var gamedir = Path.dirname(par.input);
		par.sizeBefore = 512000000;
		par.sizeAfter = 32000134;
		par.imagePath = gamedir + gamename + ".bin";
		par.cuePath = gamedir + gamename + ".cue";
		par.crushedArc = gamedir + gamename + ".arc";
		
		par.cd = new CDInfo();
		par.cd.tracks_total = 7;
		
		add(new FakeTask("Spliting", "steps", 0.2));
		add(new FakeTask("Compressing track 1", "progress", 0.3));
		add(new FakeTask("Compressing track 2", "progress", 0.3));
		add(new FakeTask("Compressing track 3", "progress", 0.3));
		add(new FakeTask("Compressing", "progress", 1));
	}//---------------------------------------------------;
	#end
	
}// --