package;

import cd.CDInfos;
import cd.CDTrack;
import djNode.task.CTask;
import djNode.tools.ArrayExecSync;
import djNode.tools.FileTool;
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
	var j:JobRestore;
	
	public function new(delete_old:Bool = true) 
	{
		super("Joining tracks into a single .bin");
		flag_delete_processed = delete_old;
	}//---------------------------------------------------;
	
	override public function start() 
	{
		super.start();
		j = cast parent;
		
		// --
		if (j.cd.tracks.length == 1)
		{
			LOG.log("> No need to Join, already 1 track on the CD");
			return complete();
		}
		
		var output = j.cd.tracks[0].workingFile;
		var progressStep:Int = Math.round(100 / j.cd.tracks.length);
		
		// --
		var ax = new ArrayExecSync(j.cd.tracks);
		killExtra = ax.kill;
		ax.queue_complete = complete;
		
		// Current track being processed
		var last:CDTrack;

		ax.queue_action = function(tr:CDTrack)
		{			
			last = tr;
			// Skip the First Track.
			if (tr.trackNo == 1) return ax.next(); 
			FileTool.copyFilePart(tr.workingFile, output, 0, 0, (s)->{
				if (s != null){
					fail(s);
				}else{
					// Track Copied OK :
					if (last.trackNo > 1) {
						LOG.log("Joined `Track " + last.trackNo + "` -> into -> `Track 1`");
						if (flag_delete_processed && !CDCRUSH.FLAG_KEEP_TEMP) {
							Fs.unlinkSync(last.workingFile);
						}
						last.workingFile = null;
					}
					PROGRESS += progressStep;
					ax.next();
				}
			});
		};
		
		ax.start();
	}//---------------------------------------------------;
	
}// --