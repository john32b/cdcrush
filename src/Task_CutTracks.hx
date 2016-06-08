package;

import djNode.file.FileCutter;
import djNode.task.Task;
import djNode.tools.ArrayExecSync;
import djNode.tools.CDInfo.CueTrack;
import djNode.tools.LOG;
import js.Node;
import js.node.Fs;
import js.node.Path;

/**
 * Split the image file into tracks
 * 
 */
class Task_CutTracks extends Task
{	
	// Pointer to global parameters
	var par:CDC.CDCRunParameters;
	
	// Counter for track cutter
	var tr_current:Int;
	var tr_total:Int;
	
	// --
	var arexec:ArrayExecSync<CueTrack>;
	
	// If I ever want to keep the old files?
	var flag_delete_source:Bool = false;
	
	//---------------------------------------------------;
	
	// --
	// The CDINFO object must be loaded
	override public function run() 
	{
		name = 'Spliting Tracks';
		par = cast shared;
		progress_type = "steps";
		progress_steps_total = par.cd.tracks_total;
		super.run();
		
		if (par.cd.isMultiImage) {
			LOG.log(" - Skipping CUT, as the image is already cut");
			complete();
			return;
		}
		
		var imageFile:String = Path.join(par.inputDir, par.cd.tracks[0].diskFile);
		LOG.log(' - Cutting file ${imageFile} ');

		arexec = new ArrayExecSync(par.cd.tracks);
		// --
		arexec.queue_action = function(tr:CueTrack) {
			var cutter = new FileCutter();
			cutter.events.once("close", function(b:Bool) {
				if (b) arexec.next(); else fail(cutter.error_log, cutter.error_code);
			});
			
			cutter.cut(	imageFile, 
						Path.join(par.tempDir, tr.getFilenameRaw()),
						tr.sectorStart * par.cd.SECTORSIZE,	// start byte
						tr.sectorSize * par.cd.SECTORSIZE); // bytes to get

			progress_steps_current = tr.trackNo;
			onStatus("progress", this);
		}
		// --
		arexec.queue_complete = function() {
			LOG.log("Cutting Complete");
			// Delete the image file??
			if (flag_delete_source) {
				LOG.log('Deleting image file "$imageFile"');
				Fs.unlinkSync(imageFile);
			}
			complete();
		}

		// --
		// - Start cutting
		arexec.start();
	}//---------------------------------------------------;
	
}// --
