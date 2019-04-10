package;

import djNode.task.CJob;
import cd.CDInfos;
import djNode.task.CJob;
import djNode.task.CTask;
import djNode.tools.FileTool;
import djNode.tools.LOG;
import js.node.Fs;
import js.node.Path;
import CDCRUSH.CrushParams;

/**
 * A collection of tasks, that will Convert a cd from cue/bin to encoded audio/cue
 * ...
 */
class JobConvert extends CJob 
{

	// --
	public function new(p:CrushParams)
	{
		super("convert");
		jobData = p;
	}//---------------------------------------------------;
	
	
	// -- Errors thrown here will be caught
	// --
	override public function init() 
	{
		var p:CrushParams = jobData;
		
		p.tempDir = CDCRUSH.getSubTempDir();
		
		//-- Input check
		CDCRUSH.checkFileQuick(p.inputFile, ".cue");
		
		//-- Output folder check
		if (p.outputDir == null || p.outputDir.length == 0){
			p.outputDir = Path.dirname(p.inputFile);
		}
		
		p.outputDir = CDCRUSH.checkCreateUniqueOutput(
				p.outputDir, Path.parse(p.inputFile).name + CDCRUSH.RESTORED_FOLDER_SUFFIX);
				
		FileTool.createRecursiveDir(p.tempDir);
		
		// --
		p.flag_convert_only = true;
		
		
		// --- START ADDING JOBS : ----
		
		add(new CTask(function(t)
		{
			var cd = new CDInfos();
			p.cd = cd;
			
			cd.cueLoad(p.inputFile);
			
			if (cd.tracks.length == 1 && cd.tracks[0].isData)
			{
				fail("No point in converting. No audio tracks on the cd."); return;
			}
			
			// Meaning the tracks are going to be extracted in the temp folder
			p.flag_sourceTracksOnTemp = (!cd.MULTIFILE && cd.tracks.length > 1);

			// Real quality to string name
			cd.CD_AUDIO_QUALITY = CDCRUSH.getAudioQualityString(p.audio);
			
			t.complete();		
					
		}, "-init", "Reading Cue Data and Preparing"));
		
		
		// - Cut tracks
		// ---------------------------
		add(new TaskCutTrackFiles());
		
		
		// - Encode AUDIO tracks only
		// ---------------------
		add(new CTask(function(t)
		{
			for (t in p.cd.tracks) {
				if (!t.isData) addNextAsync(new TaskEncodeTrack(t));
			}
			t.complete();
		}, "-Preparing", "Preparing to compress tracks"));
		
	
		// - Create new CUE file
		// --------------------
		add(new CTask(function(t)
		{
			
			var stepProgress:Int = Math.ceil(100.0 / p.cd.tracks.length);
			
			for (tr in p.cd.tracks)
			{
				if (!p.cd.MULTIFILE)
				{
					// Fix the index times to start with 00:00:00
					tr.rewriteIndexes_forMultiFile();
				}
				
				var ext = Path.extname(tr.workingFile);
				tr.trackFile = '${p.cd.CD_TITLE} (track ${tr.trackNo})$ext';
				
				// Data track was not cut or encoded.
				// It's in the input folder, don't move it
				if(tr.isData && p.cd.MULTIFILE)
				{
					FileTool.copyFile(tr.workingFile, Path.join(p.outputDir, tr.trackFile));
				}else{
					// Note: TaskCompress already put the audio files on the output folder
					// Renames files to proper filename : 
					// Either on same folder or on temp folder
					FileTool.moveFile(tr.workingFile, Path.join(p.outputDir, tr.trackFile));
				}
				
				t.PROGRESS += stepProgress;
				
			}//- end for
			
			
			//-- Create the new CUE file
			p.convertedCuePath = Path.join(p.outputDir, p.cd.CD_TITLE + ".cue");
			p.cd.cueSave(p.convertedCuePath, [
				'CDCRUSH (nodejs) version : ' + CDCRUSH.PROGRAM_VERSION,
				CDCRUSH.LINK_SOURCE
			]);
			
			
			LOG.log( "== Detailed CD INFOS:\n" +  p.cd.getDetailedInfo() );
			
			t.complete();
			
		}, "Finalizing"));
		
		// --
		
		LOG.log('= CONVERTING A CD with the following parameters :');
		LOG.log('- Input : ' + p.inputFile);
		LOG.log('- Output Dir : ' + p.outputDir);
		LOG.log('- Temp Dir : ' + p.tempDir);
		LOG.log('- Audio Quality : ' + CDCRUSH.getAudioQualityString(p.audio));
		LOG.log('- Compression Level : ' + p.compressionLevel);
	}//---------------------------------------------------;
		
	
	// --
	override function kill() 
	{
		super.kill();
		
		var p:CrushParams = jobData;
		
		if (CDCRUSH.FLAG_KEEP_TEMP) return;
		
		if (p.tempDir != p.outputDir)
		{
			LOG.log("Deleting tempdir " + p.tempDir);
			FileTool.deleteRecursiveDir(p.tempDir);
		}
	}//---------------------------------------------------;
	
}// --




