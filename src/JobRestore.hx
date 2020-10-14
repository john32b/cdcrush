package;
import app.Archiver;
import djNode.task.CJob;
import djNode.task.CTask;
import djNode.tools.FileTool;
import djNode.tools.LOG;
import js.node.Fs;
import js.node.Path;

import CDCRUSH.RestoreParams;
import cd.CDInfos;


@:allow(TaskRestoreTrack,TaskJoinTrackFiles)
class JobRestore extends CJob
{
	// Temp dir for the current batch, it's autoset by Jobs
	// is a subfolder of the master TEMP folder
	var tempDir:String;
	// Keeps the current job CDINfo object
	var cd:CDInfos;
	// The running parameters
	var p:RestoreParams;
	
	// Read by the UI:
	//
	// What file was created (full path)
	public var createdCueFile:String;
	
	public var final_size:Float = 0;	// Restored Size
	public var original_size:Float = 0;	// Archive Size
	
	// --
	public function new(P:RestoreParams)
	{
		super("restore");
		info = 'Restoring : [' + Path.basename(P.inputFile) + ']';	// [ ] will be replaced with color codes on the terminal
		p = P;
	}//---------------------------------------------------;
	
	// -- Errors thrown here will be caught
	// --
	override public function init() 
	{
		tempDir = CDCRUSH.getSubTempDir();
		
		//-- Input check
		CDCRUSH.checkFileQuick(p.inputFile, [".zip", ".7z", ".arc"]);
		
		//-- Output folder check
		if (p.outputDir == null || p.outputDir.length == 0){
			p.outputDir = Path.dirname(p.inputFile);
		}
		
		if (!p.flag_nosub) 
		{
			// Create a subfolder in output dir, because it will create a bunch of files
			p.outputDir = CDCRUSH.checkCreateUniqueOutput(
				p.outputDir, Path.parse(p.inputFile).name + CDCRUSH.RESTORED_FOLDER_SUFFIX);
		}else
		{
			FileTool.createRecursiveDir(p.outputDir);
		}
		
		FileTool.createRecursiveDir(tempDir);
		
		// --
		LOG.log('=== Creating RESTORE job with the following parameters :');
		LOG.log('- Input : ' + p.inputFile);
		LOG.log('- Output Dir : ' + p.outputDir);
		LOG.log('- Force Single bin : ' + p.flag_forceSingle);
		LOG.log('- Create subfolder : ' + p.flag_nosub);
		LOG.log('- Restore to encoded audio/.cue : ' + p.flag_encCue);
		
		// - Extract the Archive
		// -----------------------
		addQ("Extracting", (t)->{
			var arc:Archiver = CodecMaster.getArchiverByExt(Path.extname(p.inputFile));
			t.syncWith(arc);
			t.killExtra = arc.kill;
			original_size = Fs.statSync(p.inputFile).size;
			arc.extract(p.inputFile, tempDir);
		});
		
		//  - Read JSON data
		//  - Restore tracks
		// -----------------------
		addQ('-Preparing', (t)->{
			cd = new CDInfos();
			cd.jsonLoad(Path.join(tempDir, CDCRUSH.CDCRUSH_SETTINGS));
			final_size = cd.CD_TOTAL_SIZE;
			// -- Restore
			for (track in cd.tracks) {
				// Note: <flag_encCue> will be handled from inside the task
				addNextAsync(new TaskRestoreTrack(track));
			}
			t.complete();
		});
		
		//-- JOIN
		if(!p.flag_encCue)
		addQ('-Join Prepare', (t)->{
			if (p.flag_forceSingle || !cd.MULTIFILE) {
				// Will join all tracks in place into track01.bin
				// Note: Sets track.workingFile to null of moved tracks
				addNext(new TaskJoinTrackFiles());
			}
			t.complete();
		});
		
		
		// == Calculating track data and creating .CUE
		// 
		// - Prepare tracks `trackfile` which is the track written to the CUE
		// - Move files to final destination
		// - Create CUE files
		// - Delete Temp Files
		// -----------------------
		addQ("Moving", (t)->{
			
			var progressStep:Int = Math.round(100 / cd.tracks.length);
			
			for (tr in cd.tracks)
			{
				// Restoring to encoded audio files / CUE
				if (p.flag_encCue) 
				{
					var ext = Path.extname(tr.workingFile);
					if (cd.tracks.length == 1){
						tr.trackFile = cd.CD_TITLE + ext;
					}else{
						tr.trackFile = '${cd.CD_TITLE} (track ${tr.trackNo})$ext';
					}
					if (!cd.MULTIFILE) tr.rewriteIndexes_forMultiFile();
				} else 
				// Restoring to a normal CD with BIN/CUE
				{
					if (cd.MULTIFILE && p.flag_forceSingle) {
						tr.rewriteIndexes_forSingleFile();
					}
					if (cd.MULTIFILE && !p.flag_forceSingle) {
						tr.trackFile = cd.CD_TITLE + " " + tr.getFilenameRaw();
					}
					// Single bin output :
					if (!cd.MULTIFILE || p.flag_forceSingle) {
						if (tr.trackNo == 1)
							tr.trackFile = cd.CD_TITLE + ".bin";
						else
							tr.trackFile = null;
					}
				}
				
				// Move ALL files to final output folder
				// NULL workingFile means that is has been deleted
				if (tr.workingFile != null) {
					FileTool.moveFile(tr.workingFile, Path.join(p.outputDir, tr.trackFile));
					t.PROGRESS += progressStep;
				}
			}// -- end for.
			
			//--
			//-- Create the new CUE file
			createdCueFile = Path.join(p.outputDir, cd.CD_TITLE + CDCRUSH.CUE_EXTENSION);
			cd.cueSave(createdCueFile, [
				'CDCRUSH (nodejs) version : ' + CDCRUSH.PROGRAM_VERSION,
				CDCRUSH.LINK_SOURCE
			]);
			
			LOG.log( "== Detailed CD INFOS:\n" +  cd.getDetailedInfo() );
			
			// -- 
			// Write NFO
			if (CDCRUSH.FLAG_NFO)
			{
				var nfoFile = FileTool.getPathNoExt(createdCueFile) + CDCRUSH.INFO_SUFFIX + '.txt';
				var data = cd.getDetailedInfo();
					data += '\n; CDCRUSH (nodejs) version : ' + CDCRUSH.PROGRAM_VERSION;
				Fs.writeFileSync(nfoFile, data);					
			}
			t.complete();
		});
		
	}//---------------------------------------------------;
	
	
	// --
	override function kill() 
	{
		super.kill();
		if (CDCRUSH.FLAG_KEEP_TEMP) return;
		if (tempDir != p.outputDir) {
			LOG.log("Deleting tempdir " + tempDir);
			FileTool.deleteRecursiveDir(tempDir);
		}
	}//---------------------------------------------------;
	
}// --


