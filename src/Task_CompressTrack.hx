package;
import djNode.app.AppSpawner;
import djNode.app.EcmTools;
import djNode.app.FFmpegAudio;
import djNode.task.Task;
import djNode.tools.CDInfo.CueTrack;
import djNode.tools.LOG;
import js.node.Fs;
import js.node.Path;

/**
 * Compress a single Cue Track
 * Compatible extensions:
 * 		PCM  => ogg or flac
 * 		BIN  => ecm
 */
class Task_CompressTrack extends Task
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
		name = 'Compressing track ${tr.trackNo}';
		super();
		progress_type = "percent";
		track = tr;
		// REMEMBER: shared var is only occupied on run();
	}//---------------------------------------------------;
	
	
	override public function run() 
	{
		super.run();
		
		trackFullPath = Path.join(shared.tempDir, track.getFilenameRaw());

		if (!track.isData)
		{
			// Compress Audio
			var ffmpeg = new FFmpegAudio();
			addListeners(ffmpeg);
			ffmpeg.compressPCM(trackFullPath, CDC.batch_quality);

		}else
		{	
			// ECM the BIN file
			var ecm = new EcmTools();
			addListeners(ecm);
			ecm.ecm(trackFullPath);
		}
	}//---------------------------------------------------;

	// --
	function postCompress()
	{
		// -- 1. Delete the old file
		if (flag_delete_old)
		try {
			LOG.log('Deleting $trackFullPath');
			Fs.unlinkSync(trackFullPath);
		}catch (e:Dynamic) {
			LOG.log('Unable to delete.', 2);
		}
		
		// -- 2. I need to update the track's filename to point to the new file
		track.filename = track.getTrackName();
	
		if (track.isData) 
		{
			track.filename += ".bin.ecm";
		}else
		{
			if (CDC.batch_quality < 4) 
				track.filename += ".ogg";
			else
				track.filename += ".flac";
		}
			
		LOG.log('Set new track filename to ${track.filename}');
		
		complete();
	}//---------------------------------------------------;
	
	//--
	// Helper function to add event listeners to ECM and FFMPEG
	// It's the same for both, reduce redudnancy
	function addListeners(proc:AppSpawner)
	{
		proc.events.once("close", function(st:Bool) {
			if (st) {
				postCompress();
			}else {
				fail('Can\'t compress "$trackFullPath", Check write access or free space!', 'IO');
			}
		});
		
		proc.events.on("progress", function(p:Int) {
			progress_percent = p;
			onStatus("progress", this);
		});
	}//---------------------------------------------------;
	
}// --