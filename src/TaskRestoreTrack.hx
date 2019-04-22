package;

import app.EcmTools;
import app.FFmpeg;
import app.Tak;
import cd.CDTrack;
import djNode.task.CTask;
import djNode.tools.FileTool;
import djNode.tools.LOG;
import js.node.Fs;
import js.node.Path;

/**
 *  Restores an encoded track to PCM/BIN
 *  PRE::
 *  - Track is on the Temp Folder
 *  - Track.storedFileName is set (e.g. track03.ogg)
 *  - Going to be restored on the Temp Folder
 *  POST::
 *  - Sets track.workingFile to new file path
 *  - Deletes old file
 */
class TaskRestoreTrack extends CTask 
{
	
	// Pointer to working track
	var track:CDTrack;
	
	// Where is the track originally,( e.g. temp/track04.ogg )
	// Autoset by this class
	var crushedTrackPath:String;
	
	// Helper
	var isLosslessAudio:Bool;
	
	var j:JobRestore;
	
	public function new(tr:CDTrack) 
	{
		track = tr;
		super("Restoring Track " + tr.trackNo);
	}//---------------------------------------------------;
	
	override public function start() 
	{
		super.start();
		j = cast parent;
		// -
		crushedTrackPath = Path.join(j.tempDir, track.storedFileName);
		// Set the final track pathname now, I need this for later.
		track.workingFile = Path.join(j.tempDir, track.getFilenameRaw());
		
		var trext = Path.extname(track.storedFileName).toLowerCase();
		isLosslessAudio = ['.flac', '.tak'].indexOf(trext) >= 0;
		
		if (track.isData)
		{
			var ecm = new EcmTools(CDCRUSH.TOOLS_PATH);
				syncWith(ecm);
				killExtra = ecm.kill;
				ecm.unecm(crushedTrackPath, track.workingFile);
			return;
		}

		// No need to convert back, leave as is
		// NOTE: It will be moved to output folder later
		if (j.p.flag_encCue)
		{
			track.workingFile = crushedTrackPath;
			return complete();
		}

		var F = new FFmpeg(CDCRUSH.FFMPEG_PATH);
		killExtra = F.kill;
		syncWith(F);
		
		if (trext == ".tak")
		{
			var T = new Tak(CDCRUSH.TOOLS_PATH);
			var inwav = F.stream_WAVtoPCMFile(track.workingFile);
			var takstr = T.streamDecode(crushedTrackPath);
			takstr.pipe(inwav);
			return;
		}
		
		// All other audio extensions use FFMPEG:
		F.encodeToPCM(crushedTrackPath, track.workingFile);
		
	}//---------------------------------------------------;
	
	/**
	   HiJack Complete() to check some things
	**/
	override public function complete() 
	{
		// Delete Old File
		if (!CDCRUSH.FLAG_KEEP_TEMP) Fs.unlinkSync(crushedTrackPath);
	
		try{
			if (!track.isData && !isLosslessAudio) correctPCMSize();
			checkRestoredMD5();
		}catch (e:String){
			return fail(e);
		}
		
		super.complete();
	}//---------------------------------------------------;
	
	
	// Fix the filesize of the restored track
	// This is only when restoring from .OGG files, .FLAC seems to be fine by default.
	function correctPCMSize()
	{
		LOG.log('+ Correcting PCM Size -- for track ${track.trackNo}');
		var targetSize = track.byteSize;
		Fs.truncateSync(track.workingFile, targetSize);
		#if EXTRA_TESTS
			if (targetSize != Fs.statSync(track.workingFile).size)
				throw "Size mismatch on restoring track to original size for file " + track.workingFile;
		#end
	}//---------------------------------------------------;
	
	// Check for MD5, auto fail on error
	function checkRestoredMD5()
	{
		#if EXTRA_TESTS
		if (isLosslessAudio || track.isData)
		if (track.md5 != null && track.md5.length > 2) { // >2 because default MD5 string is "-"
			if (FileTool.getFileMD5(track.workingFile) != track.md5) {
				throw "Restored Track WRONG MD5 for track " + track.workingFile;
			}
		}
		#end
	}//---------------------------------------------------;
	
}// --