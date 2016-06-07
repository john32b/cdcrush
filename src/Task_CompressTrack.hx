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
	var trackRawPath:String;
	// The full path of the new generated track
	var trackGenPath:String;
	
	// If I ever want to keep the old files?
	var flag_delete_old:Bool = true;
	
	var multiTrack:Bool = false;
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
	
		multiTrack = shared.cd.isMultiImage;
		
		// Update the final trackName, i need it for later.
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
		
		if (multiTrack)
		{
			// Multitrack sheets are already cut and have the files already there on the input folder
			trackRawPath = Path.join(shared.inputDir, track.diskFile);
		}else
		{
			// Single image tracks are cut and are on the temp dir
			trackRawPath = Path.join(shared.tempDir, track.getFilenameRaw());
		}

		LOG.log('Compressing track ${trackRawPath} to ${track.filename}');

		// Store the full path of the final track
		trackGenPath = Path.join(shared.tempDir, track.filename);
					
		if (!track.isData)
		{
			// Compress Audio
			var ffmpeg = new FFmpegAudio();
			addListeners(ffmpeg);
			ffmpeg.compressPCM(trackRawPath, CDC.batch_quality, trackGenPath);

		}else
		{	
			// ECM the BIN file
			var ecm = new EcmTools();
			addListeners(ecm);
			ecm.ecm(trackRawPath, trackGenPath);
		}
	}//---------------------------------------------------;

	// --
	function postCompress()
	{
		if (flag_delete_old && !multiTrack)
		try {
			LOG.log('Deleting $trackRawPath');
			Fs.unlinkSync(trackRawPath);
		}catch (e:Dynamic) {
			LOG.log('Unable to delete.', 2);
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
				postCompress();
			}else {
				fail('Can\'t compress "$trackRawPath", Check write access or free space!', 'IO');
			}
		});
		
		proc.events.on("progress", function(p:Int) {
			progress_percent = p;
			onStatus("progress", this);
		});
	}//---------------------------------------------------;
	
}// --