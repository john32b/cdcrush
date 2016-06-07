package;

import djNode.app.AppSpawner;
import djNode.app.EcmTools;
import djNode.app.FFmpegAudio;
import djNode.app.IArchiver;
import djNode.task.Task;
import djNode.tools.CDInfo.CueTrack;
import djNode.tools.LOG;
import djNode.tools.StrTool;
import js.Error;
import js.node.Fs;
import js.node.Path;

/**
 * Restore a single cue track to uncompressed TRACK DATA
 * Compatible extensions:
 * 
 * 		flac => PCM
 * 		ogg  => PCM
 * 		ecm  => BIN
 */
class Task_RestoreTrack extends Task
{
	// The current track being processed
	var track:CueTrack;
	// The full path of the trackFile being processed
	var trackFullPath:String;
	// If I ever want to keep the old files?
	var flag_delete_old:Bool = true;

	//---------------------------------------------------;
	public function new(tr:CueTrack)
	{
		name = 'Restoring track ${tr.trackNo}';
		super();
		progress_type = "percent";
		track = tr;
		// REMEMBER: shared var is only occupied on run();
	}//---------------------------------------------------;
	
	// --
	override public function run() 
	{
		super.run();
		
		trackFullPath = Path.join(shared.tempDir, track.filename);
		LOG.log('Restore Track $trackFullPath');
		
		if (!track.isData) 
		{
			// AUDIO 
			var ffmpeg = new FFmpegAudio();
			addListeners(ffmpeg);
			ffmpeg.convertToPCM(trackFullPath);	// no output param will extract to same dir as input file
		}else 
		{
			// ECM DATA
			var ecm = new EcmTools();
			addListeners(ecm);
			ecm.unecm(trackFullPath);
		}
	}//---------------------------------------------------;
	
	// --
	// Auto called after a restoration is done.
	// Audio files need to be fixed into a correct size
	function postRestore()
	{
		// -- 1. Delete the old file
		if (flag_delete_old)
		try {
			LOG.log('Deleting $trackFullPath');
			Fs.unlinkSync(trackFullPath);
		}catch (e:Dynamic) {
			LOG.log('Unable to delete.', 2);
		}
			
		// -- 2. Fix the track.filename to point to the new restoredfile
		track.filename = track.getFilenameRaw();
		LOG.log('Altering new track filename to "${track.filename}"');
		trackFullPath = Path.join(shared.tempDir, track.filename); // also fic this

			
		//  -- 3. ONLY WHEN RESTORING PCM FILES --
		//  Truncate the file to the correct sector size.
		//  This is because when converting a file back to PCM it is 
		//  usually padded with extra space, as ffmpeg conversion 
		//  can't be precise to the millisecond.
		// ---------------------------------------------
		if (!track.isData)
		{
			var targetSize:Int = Std.int(track.sectorSize * shared.cd.SECTORSIZE);
			var trackSize:Int;
			LOG.log("Fixing size :: ");
			trackSize = Std.int(Fs.statSync(trackFullPath).size);
			LOG.log('  pre size = $trackSize');
			Fs.truncateSync(trackFullPath, targetSize);
			trackSize = Std.int(Fs.statSync(trackFullPath).size);
			LOG.log('  post size = $trackSize');
			if (trackSize != targetSize) {
				fail('Size mismatch! Size is not what is should be', 'IO');
				return;
			}
		}
		
		complete();
		
	}//---------------------------------------------------;

	//--
	// Helper function to add event listeners to ECM and FFMPEG
	// It's the same for both, reduce redudnancy
	function addListeners(proc:AppSpawner)
	{
		proc.events.once("close", function(st:Bool) {
			if (st) {
				postRestore();
			}else {
				fail('Can\'t restore "$trackFullPath", Check write access or free space!', 'IO');
			}
		});
		
		proc.events.on("progress", function(p:Int) {
			progress_percent = p;
			onStatus("progress", this);
		});
	}//---------------------------------------------------;
	
	
	
}// --