package;

import app.EcmTools;
import app.FFmpeg;
import app.Tak;
import cd.CDTrack;
import djNode.task.CTask;
import djNode.tools.FileTool;
import djNode.utils.CLIApp;
import djNode.utils.ISendingProgress;
import js.Node;
import js.node.Fs;
import js.node.Path;


/**
 * - Compresses a Track (data or audio)
 * 
 * CHANGES:
 *  - track.workingFile -> points to the new encoded file path
 *  - track.storedFileName -> is set to just a filename. e.g (track02.ogg) How it's saved in the archive?
 *  - old file `track.workingFile` is deleted
 * ...
 */

class TaskEncodeTrack extends CTask 
{
	// Pointer to working track
	var track:CDTrack;
	// Temp Name, Autogenerated
	var sourceTrackFile:String;
	var j:JobCrush;
	
	// --
	public function new(tr:CDTrack) 
	{
		super("Encoding Track " + tr.trackNo);
		track = tr;
	}//---------------------------------------------------;
	
	/**
	   Prepare the working file to be of that extension
	   - Sets `workingFile` as the file to be created
	   @param	ext With an '.'
	**/
	function setupTrackFiles(ext:String)
	{
		track.storedFileName = track.getTrackName() + ext;

		if (j.p.flag_convert_only) {
			// Convert files to output folder directly
			track.workingFile = Path.join(j.p.outputDir, track.storedFileName);
		}else{
			// Convert files to temp folder, since they are going to be archived later
			track.workingFile = Path.join(j.tempDir, track.storedFileName);
		}
	}// -----------------------------------------
	
	override public function syncWith(p:ISendingProgress) 
	{
		p.onComplete = ()->{
			p.onComplete = null; // Safekeep
			if (!CDCRUSH.FLAG_KEEP_TEMP && j.flag_tracksOnTempFolder) {
				// Delete Old File
				Fs.unlinkSync(sourceTrackFile);
			}
			complete();
		};
		p.onFail = (f)->fail(f, null);
		p.onProgress = (p)-> PROGRESS = p;
	}//---------------------------------------------------;
	
	// --
	override public function start() 
	{
		super.start();
		j = cast parent;
		sourceTrackFile = track.workingFile;
		// Get track MD5
		track.md5 = FileTool.getFileMD5(sourceTrackFile);
		if (track.md5 == null) {
			fail("Could not calculate MD5 of " + sourceTrackFile);
		}
		// --
		if (track.isData)
		{
			setupTrackFiles(".bin.ecm");
			var ecm = new EcmTools(CDCRUSH.TOOLS_PATH);
			killExtra = ecm.kill;
			syncWith(ecm);
			ecm.ecm(sourceTrackFile, track.workingFile);
			return;
		}
		
		var F = new FFmpeg(CDCRUSH.FFMPEG_PATH);
		setupTrackFiles(CodecMaster.getAudioExt(j.AC.id));
		
		if (j.AC.id == "TAK")
		{
			var T = new Tak(CDCRUSH.TOOLS_PATH);
			syncWith(T);
			killExtra = ()->{
				T.kill();
				F.kill();
			}
			// WAV->TAK File
			var inWavstream = T.streamEncode(track.workingFile);
			var PcmToWav = F.stream_PCMtoWAVStream(); // Dual Converter
				PcmToWav._out.pipe(inWavstream);
			var fileStr = Fs.createReadStream(sourceTrackFile);
				fileStr.pipe(PcmToWav._in);
		}else
		{
			syncWith(F);
			killExtra = F.kill;
			F.encodeFromPCM(sourceTrackFile, CodecMaster.getAudioStr(j.AC), track.workingFile);
		}

	}//---------------------------------------------------;
	
}// --