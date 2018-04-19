package;

import cd.CDTrack;
import djNode.file.FileCopyPart;
import djNode.task.CTask;
import djNode.tools.ArrayExecSync;
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
		super(null, "Cut", "Cutting tracks into separate files");
	}
	
	// Note, gets called regardless of number of tracks
	override public function start() 
	{
		super.start();
		
		var p:CDCRUSH.CrushParams = cast jobData;
		var cd:cd.CDInfos = p.cd;
		
		var input:String = cd.tracks[0].workingFile;
		
		// No need to cut an already cut CD
		// Multifiles `workingfile` is already set to proper	
		if (cd.MULTIFILE)
		{
			LOG.log("- No need to cut a multifile cd. Returning");
			complete();
			return;
		}
		
		// No need to copy the bytes to the temp folder, just work from the source
		if (cd.tracks.length == 1)
		{
			LOG.log("- No need to cut a CD with only 1 track. Returning");
			complete();
			return;
		}
		
		var progressStep:Int = Math.round(100 / cd.tracks.length);

		// -
		var ax = new ArrayExecSync(cd.tracks);
		
		// This file cutter is ASYNC
		// So I need a way to manage calls with an array exec sync
		var fc = new FileCopyPart();
		
		fc.events.on("complete", function(err:String){
			
			PROGRESS += progressStep;
			
			if (err == null){
				ax.next();
			}else{
				fail(err);
			}
			
		});
			
		LOG.log(' - Cutting tracks from `$input` to `${p.tempDir}`');
		ax.queue_action = function(tr:CDTrack)
		{
			// Set the new working file for the tracks
			tr.workingFile = Path.join(p.tempDir, tr.getFilenameRaw());
			var byteStart:Int = tr.sectorStart * cd.SECTOR_SIZE;
			LOG.log(' - Cutting Track ${tr.trackNo}');
			fc.start(input, tr.workingFile, byteStart, tr.byteSize, true);
		};
			
		ax.queue_complete = function()
		{
			complete();
		};
		
		ax.start();
	}//---------------------------------------------------;
	
}