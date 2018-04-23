package;
import app.Arc;
import djNode.task.CJob;
import djNode.task.CTask;
import djNode.tools.FileTool;
import djNode.tools.LOG;
import js.node.Path;

import CDCRUSH.RestoreParams;

/**
 * A collection of tasks, that will Restore a cd
 * ...
 */
class JobRestore extends CJob
{
	// Push out information about the job at this callback
	// public var pushInfos:RestoreParams->Void;
	
	public function new(p:RestoreParams)
	{
		super("restore");
		jobData = p;
	}//---------------------------------------------------;
	
	// -- Errors thrown here will be caught
	// --
	override public function init() 
	{
		var p:RestoreParams = jobData;

		p.tempDir = CDCRUSH.getSubTempDir();
		
		//-- Input check
		CDCRUSH.checkFileQuick(p.inputFile, CDCRUSH.CDCRUSH_EXTENSION);
		
		//-- Output folder check
		if (p.outputDir == null || p.outputDir.length == 0){
			p.outputDir = Path.dirname(p.inputFile);
		}
		
		if (p.flag_subfolder) 
		{
			p.outputDir = CDCRUSH.checkCreateUniqueOutput(
				p.outputDir, Path.parse(p.inputFile).name + CDCRUSH.RESTORED_FOLDER_SUFFIX);
		}else
		{
			FileTool.createRecursiveDir(p.outputDir);
		}
		
		FileTool.createRecursiveDir(p.tempDir);

		// Safeguard, even if the GUI doesn't allow it
		if(p.flag_encCue)
		{
			p.flag_forceSingle = false;
		}
		
		// - Extract the Archive
		// -----------------------
		add(new CTask(function(t)
		{
			var arc = new Arc(CDCRUSH.TOOLS_PATH);
				t.handleCliReport(arc);
				arc.extractAll(p.inputFile, p.tempDir);
				t.killExtra = function(){ arc.kill(); }

		}, "Extracting", "Extracting archive to temp folder"));
		
		
		//  - Read JSON data
		//  - Restore tracks
		//  - JOIN if it has to
		// -----------------------
		add(new CTask(function(t)
		{
			var cd = new cd.CDInfos(); jobData.cd = cd;
			
			cd.jsonLoad(Path.join(p.tempDir, CDCRUSH.CDCRUSH_SETTINGS));
			
			for (track in cd.tracks){
				addNextAsync(new TaskRestoreTrack(track));
			}
			t.complete();

		}, "-Preparing to Restore", "Reading stored CD and preparing"));


		// - Join Tracks, but only when not creating .Cue/Enc Audio
		// -----------------------
		if(!p.flag_encCue) 
		add(new CTask(function(t)
		{
			// -- Join tracks
			if(p.flag_forceSingle || !p.cd.MULTIFILE) {
				// The task will read data from the shared job data var
				// Will join all tracks in place into track01.bin
				// Note: Sets track.workingFile to null to moved track
				addNext(new TaskJoinTrackFiles());
			}//--

			t.complete();

		}, "-Preparing to Join"));
		
		
		// == Calculating track data and creating .CUE
		// 
		// - Prepare tracks `trackfile` which is the track written to the CUE
		// - Convert tracks
		// - Move files to final destination
		// - Create CUE files
		// - Delete Temp Files
		// -----------------------
		add(new CTask(function(t)
		{
			var progressStep:Int = Math.round(100 / p.cd.tracks.length);

			for (tr in p.cd.tracks)
			{
				// Restoring to encoded audio files / CUE
				if (p.flag_encCue) 
				{
					var ext:String = Path.extname(tr.workingFile);
					if (p.cd.tracks.length == 1)
					{
						tr.trackFile = p.cd.CD_TITLE + ext;
					}else{
						tr.trackFile = '${p.cd.CD_TITLE} (track ${tr.trackNo})$ext';
					}
					
					if (!p.cd.MULTIFILE) tr.rewriteIndexes_forMultiFile();
					
				} else 
				// Restoring to a normal CD with BIN/CUE
				{
					
					if (p.flag_forceSingle && p.cd.MULTIFILE)
					{
						tr.rewriteIndexes_forSingleFile();
					}
					
					if (p.cd.MULTIFILE && !p.flag_forceSingle)
					{
						tr.trackFile = p.cd.CD_TITLE + " " + tr.getFilenameRaw();
					}
					
					// Single bin output :
					if (!p.cd.MULTIFILE || p.flag_forceSingle)
					{
						if (tr.trackNo == 1)
							tr.trackFile = p.cd.CD_TITLE + ".bin";
						else
							tr.trackFile = null;
					}
					
				}// --
			
			// --
			// Move ALL files to final output folder
			// NULL workingFile means that is has been deleted

			if (tr.workingFile != null)
			{
				FileTool.moveFile(tr.workingFile, Path.join(p.outputDir, tr.trackFile));
				t.PROGRESS += progressStep;
			}
		
			}// -- end for.
			
			// --
			//-- Create the new CUE file
			p.createdCueFile = Path.join(p.outputDir, p.cd.CD_TITLE + ".cue");
			p.cd.cueSave(p.createdCueFile, [
				'CDCRUSH (nodejs) version : ' + CDCRUSH.PROGRAM_VERSION,
				CDCRUSH.LINK_SOURCE
			]);

			LOG.log( "== Detailed CD INFOS:\n" +  p.cd.getDetailedInfo() );
			
			t.complete();
		
		}, "Moving, Finalizing"));
		
		
		// --
		LOG.log('=== RESTORING A CD with the following parameters :');
		LOG.log('- Input : ' + p.inputFile);
		LOG.log('- Output Dir : ' + p.outputDir);
		LOG.log('- Temp Dir : ' + p.tempDir);
		LOG.log('- Force Single bin : ' + p.flag_forceSingle);
		LOG.log('- Create subfolder : ' + p.flag_subfolder);
		LOG.log('- Restore to encoded audio/.cue : ' + p.flag_encCue);
	}//---------------------------------------------------;
	
	
	// --
	override function kill() 
	{
		super.kill();
		
		var p:RestoreParams = jobData;
		
		if (CDCRUSH.FLAG_KEEP_TEMP) return;
		
		if (p.tempDir != p.outputDir)
		{
			LOG.log("Deleting tempdir " + p.tempDir);
			FileTool.deleteRecursiveDir(p.tempDir);
		}
	}//---------------------------------------------------;
	
}// --


