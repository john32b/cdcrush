package;

import app.EcmTools;
import app.FFmpegAudio;
import cd.CDTrack;
import djNode.task.CTask;
import djNode.tools.FileTool;
import djNode.tools.LOG;
import js.node.Fs;
import js.node.Path;

/**
 *  Restores an encoded track to PCM/BIN
 * 
 *  - Track is on the Temp Folder
 *  - Track.storedFileName is set (e.g. track03.ogg)
 *  - Going to be restored on the Temp Folder
 * ----->
 *  - Sets track.workingFile to new file path
 *  - Deletes old file
 */
class TaskRestoreTrack extends CTask 
{
	
	// Pointer to Job's restore parameters
	var p:CDCRUSH.RestoreParams;
	
	// Pointer to working track
	var track:CDTrack;
	
	// Where is the track originally,( e.g. temp/track04.ogg )
	// Autoset by this class
	var crushedTrackPath:String;
	
	// Helper
	var isFlac:Bool;
	
	public function new(tr:CDTrack) 
	{
		super(null, "Restoring Track " + tr.trackNo);
		track = tr;
	}
	
	override public function start() 
	{
		super.start();
	
		p = cast jobData;
		
		crushedTrackPath = Path.join(p.tempDir, track.storedFileName);
		// Set the final track pathname now, I need this for later.
		track.workingFile = Path.join(p.tempDir, track.getFilenameRaw());
		
		if (track.isData)
		{
			isFlac = false;
			
			var ecm = new EcmTools(CDCRUSH.TOOLS_PATH);
				ecm.events.on("progress", onProgress);
				ecm.events.once("close", onClose);
				ecm.unecm(crushedTrackPath, track.workingFile);
			
		}else{
			// No need to convert back
			if (p.flag_encCue)
			{
				track.workingFile = crushedTrackPath;
				complete();
				return;
			}
			
			isFlac = Path.extname(track.storedFileName) == ".flac";
			
			var ffmp = new FFmpegAudio(CDCRUSH.FFMPEG_PATH);
				ffmp.events.on("progress", onProgress);
				ffmp.events.once("close", onClose);
				ffmp.audioToPCM(crushedTrackPath, track.workingFile);
		}
		
	}//---------------------------------------------------;
	
	
	
	// Fix the filesize of the restored track
	// This is only when restoring from .OGG files, .FLAC seems to be fine by default.
	function correctPCMSize()
	{
		LOG.log('+ Correcting PCM Size -- for track ${track.trackNo}');
		var targetSize = track.byteSize;
		Fs.truncateSync(track.workingFile, targetSize);
		#if TEST_EVERYTHING
			if (targetSize != Fs.statSync(track.workingFile).size)
				throw "Size mismatch on restoring track to original size for file " + track.workingFile;
		#end
	}//---------------------------------------------------;
	
	
	// Check for MD5, auto fail on error
	function checkRestoredMD5()
	{
		#if TEST_EVERYTHING
		
		if (isFlac || track.isData)
		if (track.md5 != null && track.md5.length > 2) {
			if (FileTool.getFileMD5(track.workingFile) != track.md5) {
				throw "Restored Track WRONG MD5 for track " + track.workingFile;
			}
		}
		
		#end
	}//---------------------------------------------------;
	
	
	// CLI App progress event
	function onProgress(p:Int)
	{
		PROGRESS = p;// uses setter
	}//---------------------------------------------------;
	
	// CLI App close event
	function onClose(s:Bool, m:String)
	{	
		if (s){
			
			deleteOldFile();
			
			try{
				if (!track.isData && !isFlac) correctPCMSize();
				checkRestoredMD5();
			}catch (e:String){
				fail(e);
				return;
			}
			
			complete();
			
		}else{
			fail(m);
		}
	}//---------------------------------------------------;
	
	// Delete old files ONLY IF they reside in the TEMP folder!
	function deleteOldFile()
	{
		if (CDCRUSH.FLAG_KEEP_TEMP) return;
		Fs.unlinkSync(crushedTrackPath);
	}//---------------------------------------------------;
	
}// --