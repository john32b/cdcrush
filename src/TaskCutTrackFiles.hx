package;

import cd.CDTrack;
import djNode.task.CTask;
import djNode.tools.ArrayExecSync;
import djNode.tools.FileTool;
import djNode.tools.LOG;
import js.node.Path;

/**
 * Cut the a single CD BIN to multiple trackfiles
 *
 * - If single track or multitrack, will skip
 * - track.workingFile : is set to the new cut track full path
 * 
 */
class TaskCutTrackFiles extends CTask 
{
	public function new() 
	{
		super("Cutting BIN into Track Files");
	}//---------------------------------------------------;
	
	// Note, gets called regardless of number of tracks
	override public function start() 
	{
		super.start();
		
		var j:JobCrush = cast parent;
		var input = j.cd.tracks[0].workingFile;
		
		// No need to cut an already cut CD
		// Multifiles `workingfile` is already set to proper	
		if (j.cd.MULTIFILE)
		{
			LOG.log("- No need to cut a multifile cd. Returning");
			return complete();
		}
		
		// No need to copy the bytes to the temp folder, just work from the source
		if (j.cd.tracks.length == 1)
		{
			LOG.log("- No need to cut a CD with only 1 track. Returning");
			return complete();
		}
		
		j.flag_tracksOnTempFolder = true;
		
		var progressStep = Math.round(100 / j.cd.tracks.length);
		
		// -
		LOG.log(' - Cutting tracks from `$input` to `${j.tempDir}`');
		
		var ax = new ArrayExecSync(j.cd.tracks);
		ax.queue_complete = complete;
		ax.queue_action = function(tr:CDTrack) 
		{
			LOG.log(' - Cutting Track ${tr.trackNo}');
			// Set the new working file for the tracks
			tr.workingFile = Path.join(j.tempDir, tr.getFilenameRaw());
			var byteStart:Int = tr.sectorStart * j.cd.SECTOR_SIZE;
			FileTool.copyFilePart(input, tr.workingFile, byteStart, tr.byteSize, (s)->{
				PROGRESS += progressStep;
				if (s == null) ax.next(); else fail(s);
			});
		};
			
		ax.start();
		
		killExtra = ax.kill;
	}//---------------------------------------------------;
	
}// --