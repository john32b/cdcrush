package;

import djNode.task.Task;
import djNode.tools.ArrayExecSync;
import djNode.tools.CDInfo.CueTrack;
import djNode.tools.FileTool;
import djNode.tools.LOG;
import js.node.Path;

/**
 * CDCRUSH specific,
 * The source cd is already multitracked, and it doesn't have to be joined
 * This MOVES the files from the TEMPDIR to the OUTPUTDIR
 * ...
 */
class Task_MoveFiles extends Task
{
	// Pointer to global parameters
	var par:CDC.CDCRunParameters;
	// --
	var arexec:ArrayExecSync<CueTrack>;
	//---------------------------------------------------;
	// --
	override public function run() 
	{
		name = 'Moving';
		par = cast shared;
		progress_type = "steps";
		progress_steps_total = par.cd.tracks_total;
		super.run();
		
		// I need to move tempDir/track01.02.03.04.... to outputDir/game01,game02,game03
		// converted back to their original names!!
		
		arexec = new ArrayExecSync(par.cd.tracks);
	
		arexec.queue_action = function(tr:CueTrack) 
		{
			var sourcePath:String = Path.join(par.tempDir, tr.filename);
			var destPath:String = Path.join(par.outputDir, tr.diskFile);
			
			FileTool.moveFile(sourcePath, destPath, function() {
				LOG.log(' Moved file $sourcePath to $destPath');
				arexec.next();
			});
			
			progress_steps_current = tr.trackNo;
			onStatus("progress", this);
		}
		// --
		arexec.queue_complete = function() {
			LOG.log("Move Complete");
			complete();
		}

		// --
		// - Start cutting
		arexec.start();
	}//---------------------------------------------------;
	
}