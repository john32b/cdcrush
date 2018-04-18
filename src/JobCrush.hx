package;

import app.Arc;
import cd.CDInfos;
import djNode.task.CJob;
import djNode.task.CTask;
import djNode.tools.FileTool;
import djNode.tools.LOG;
import js.node.Fs;
import js.node.Path;
import CDCRUSH.CrushParams;




/**
 * A collection of tasks, that will CRUSH a cd,
 * Tasks will run in order, and some will run in parallel
 * ...
 * 
 */
class JobCrush extends CJob 
{

	// --
	public function new(p:CrushParams) 
	{
		super("Compress CD");
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
		
		FileTool.createRecursiveDir(p.outputDir);
		FileTool.createRecursiveDir(p.tempDir);
		
		// --
		p.flag_convert_only = false;
		
		// --- START ADDING JOBS : ----
		
		add(new CTask(function(t)
		{
			var cd = new CDInfos();
			p.cd = cd;
			
			cd.cueLoad(p.inputFile);
			
			// Meaning the tracks are going to be extracted in the temp folder
			p.flag_sourceTracksOnTemp = (!cd.MULTIFILE && cd.tracks.length > 1);

			// Real quality to string name
			cd.CD_AUDIO_QUALITY = CDCRUSH.getAudioQualityString(p.audio);

			// Generate the final arc name now that I have the CD TITLE
			p.finalArcPath= Path.join(p.outputDir, cd.CD_TITLE + ".arc");
			LOG.log("- Destination Archive :" + p.finalArcPath );

			t.complete();		
					
		}, "-Reading", "Reading Cue Data and Preparing"));
		
		
		// - Cut tracks
		// ---------------------------
		add(new TaskCutTrackFiles());
		
		
		// - Encode tracks
		// ---------------------
		add(new CTask(function(t)
		{
			for (t in p.cd.tracks) {
				addNextAsync(new TaskEncodeTrack(t));
			}
			t.complete();
		}, "-Preparing", "Preparing to compress tracks"));
		

		// Create Archive
		// Add all tracks to the final archive
		// ---------------------
		add(new CTask(function(t) 
		{
		
			var files:Array<String> = [];
			for (tr in p.cd.tracks) {
				// Dev note: working file was set earlier on TaskEncodeTrack();
				files.push(tr.workingFile);
			}
			
			var arc = new Arc(CDCRUSH.TOOLS_PATH);
				t.handleCliReport(arc);
				arc.compress(files, p.finalArcPath, p.compressionLevel);

		}, "Compressing", "Compressing everything into an archive"));

		
		// - Create CD SETTINGS and push it to the final archive
		// ( I am appending these files so that they can be quickly loaded later )
		// --------------------
		add(new CTask(function(t)
		{
			LOG.log( "== Detailed CD INFOS:\n" +  p.cd.getDetailedInfo() );
			
			var path_settings = Path.join(p.tempDir, CDCRUSH.CDCRUSH_SETTINGS);

			p.cd.jsonSave(path_settings);
			
			var arc = new Arc(CDCRUSH.TOOLS_PATH);
			t.handleCliReport(arc);
			arc.appendFiles([path_settings], p.finalArcPath);

		}, "Finalizing", "Appending settings into the archive"));
		
		
		// - Get post data
		add(new CTask(function(t)
		{
			p.crushedSize = Std.int(Fs.statSync(p.finalArcPath).size);
			t.complete();

		}, "-Finalizing"));
		
		// --
		
		LOG.log('= COMPRESSING A CD with the following parameters :');
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




