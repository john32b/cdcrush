package;

import djNode.file.FileJoiner;
import djNode.task.Task;
import djNode.tools.CDInfo.CueTrack;
import djNode.tools.FileTool;
import djNode.tools.LOG;
import js.node.Path;

/**
 * Binary join files into a new file 
 * TODO: Generalize this task?
 */
class Task_JoinTracks extends Task
{
	// If I ever want to keep the old files?
	var flag_delete_old:Bool = true;
	// Pointer to global parameters
	var par:CDC.CDCRunParameters;
	// Joiner object
	var joiner:FileJoiner;
	//---------------------------------------------------;
	
	// --
	override public function run() 
	{
		name = 'Joining Tracks';
		par = cast shared;
		progress_type = "steps";
		progress_steps_total = par.cd.tracks_total;
		super.run();
		LOG.log('Joining tracks to an image. Total tracks ${par.cd.tracks_total}');
				
		/*
		 * Perhaps I want to force-join
		 * 
			if (par.cd.isMultiImage) {
				LOG.log("- NO need to JOIN, Track is multitrack");
				complete();
				return;
			}
		*/

		
		// No need to join, just move the file
		if (par.cd.tracks_total == 1)
		{
			FileTool.moveFile( Path.join(par.tempDir, par.cd.tracks[0].filename) ,
								par.imagePath, function() {
									complete();
								});
			return;
		}
		
		
		joiner = new FileJoiner();
		
		joiner.events.once("close", function(st:Bool) {
			if (st) {
				LOG.log("Join Complete");
				// Should I check for filesize??
				complete();
			}else {
				LOG.log("Join ERROR - " + joiner.error_log);
				fail(joiner.error_log);
			}
		});
		
		joiner.events.on("progress", function(a:Int, ?b:Int) {
			progress_steps_current = a;
			onStatus("progress", this);
		});

		// ORDERING IS SUPER IMPORTANT!
		var filesToJoin:Array<String> = [];
		for (i in par.cd.tracks) {
			filesToJoin.push(Path.join(par.tempDir, i.filename));
		}
		
		joiner.join(par.imagePath, filesToJoin);
	}//---------------------------------------------------;
	
}// --