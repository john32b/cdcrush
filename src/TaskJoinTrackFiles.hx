package;

import cd.CDTrack;
import djNode.file.FileCopyPart;
import djNode.task.CTask;
import djNode.tools.ArrayExecSync;
import djNode.tools.LOG;
import js.node.Fs;

/**
 * 
 * - Joins all the trackfiles together
 * - Merges all tracks from 2 and up into track 1 data
 * - Changes track.workingFile from second's track up to null
 * - Can delete old files
 * 
 */
class TaskJoinTrackFiles extends CTask 
{

	var flag_delete_processed:Bool;
		
	public function new(delete_old:Bool = true) 
	{
		super(null, "Join", "Joining tracks into a single .bin");
		flag_delete_processed = delete_old;
	}//---------------------------------------------------;
	
	override public function start() 
	{
		super.start();
		
		var cd:cd.CDInfos = jobData.cd;
		
		// --
		if (cd.tracks.length == 1)
		{
			complete();
			return;
		}
		
		var inputs = [];
		var output = cd.tracks[0].workingFile;
		var progressStep:Int = Math.round(100 / cd.tracks.length);
		// --
		var ax = new ArrayExecSync(cd.tracks);
		
		// This file cutter is ASYNC
		// So I need a way to manage calls with an array exec sync
		var fc = new FileCopyPart();
		
		// Current track being processed
		var last:CDTrack;
		
		fc.events.on("complete", function(err:String)
		{
			if (last.trackNo > 1)
			{
				LOG.log("Joined `Track " + last.trackNo + "` -> into -> `Track 1`");
				
				if (flag_delete_processed && !CDCRUSH.FLAG_KEEP_TEMP)
				{
					LOG.log("Deleting " + last.workingFile);
					Fs.unlinkSync(last.workingFile);
				}
				
				last.workingFile = null;
			}
			
			PROGRESS += progressStep;
			
			if (err == null){
				ax.next();
			}else{
				fail(err);
			}
			
		});		
	
		ax.queue_action = function(tr:CDTrack)
		{
			last = tr;
			if (tr.trackNo == 1) {
				ax.next(); 
				return;
			}
			// Skip the first one
			fc.start(tr.workingFile, output, 0, 0, false);	// False = append data
		};
			
		ax.queue_complete = function()
		{
			complete();
		};
		
		ax.start();
	}//---------------------------------------------------;
	
}// --