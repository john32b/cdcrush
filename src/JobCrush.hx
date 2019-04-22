package;

import app.Archiver;
import app.FreeArc;
import cd.CDInfos;
import djNode.task.CJob;
import djNode.task.CTask;
import djNode.tools.FileTool;
import djNode.tools.LOG;
import js.node.Fs;
import js.node.Path;
import CDCRUSH.CrushParams;


@:allow(TaskEncodeTrack,TaskCutTrackFiles)
class JobCrush extends CJob 
{
	// Temp dir for the current batch, Is a subfolder of the master TEMP folder.
	var tempDir:String;
	// Keep the CD infos of the CD, it is going to be read later
	var cd:CDInfos;

	// If true, then all the track files are stored in temp folder and safe to delete
	var flag_tracksOnTempFolder:Bool;
	
	// The running parameters
	var p:CrushParams;
	var AC:CodecMaster.SettingsTuple;
	var DC:CodecMaster.SettingsTuple;
	
	// In <CONVERT> operation, Holds path of new <.cue> file
	public var convertedCuePath:String;
	// Hold size of Archive created
	public var final_size:Float = 0;
	// Final destination ARCHIVE file, Name is autogenerated from CD TITLE
	public var final_arc:String;
	
	// DEV: If set, will autowrite at the final step of the job
	var nfoFile:String;
	var nfoFileData:String; // Data to write below the standard cd infos
	
	// --
	public function new(P:CrushParams)
	{
		super();
		p = P;
		if (p.flag_convert_only == null) p.flag_convert_only = false;
		if (p.flag_convert_only) name = "convert"; else name = "crush";
	}//---------------------------------------------------;
	
	// -- Errors thrown here will be caught
	// --
	override public function init() 
	{
		// - Any parse errors in ac/dc settings should be checked on MAIN and error to user from there
		// - ac/dc strings should be normalized before here
		if (p.ac == null) p.ac = CodecMaster.DEFAULT_AUDIO_PARAM;
		if (p.dc == null) p.dc = CodecMaster.DEFAULT_ARCHIVER_PARAM;
		AC = CodecMaster.getSettingsTuple(p.ac);
		DC = CodecMaster.getSettingsTuple(p.dc);
		
		tempDir = CDCRUSH.getSubTempDir();
		
		//-- Input check
		CDCRUSH.checkFileQuick(p.inputFile, [CDCRUSH.CUE_EXTENSION]);
		
		//-- Output folder check
		if (p.outputDir == null || p.outputDir.length == 0) {
			p.outputDir = Path.dirname(p.inputFile);
		}
		
		if (p.flag_convert_only)
		{
			// Create a subfolder in output dir, because it will create a bunch of files
			p.outputDir = CDCRUSH.checkCreateUniqueOutput(
				p.outputDir, Path.parse(p.inputFile).name + CDCRUSH.RESTORED_FOLDER_SUFFIX);
		}else
		{
			FileTool.createRecursiveDir(p.outputDir);
		}
		
		FileTool.createRecursiveDir(tempDir);
		
		LOG.log('== Creating a CRUSH Job with these parameters :');
		LOG.log(' - Input : ' + p.inputFile);
		LOG.log(' - Output Dir : ' + p.outputDir);
		LOG.log(' - Audio Compression : ' + p.ac);
		LOG.log(' - Archive Compression : ' + p.dc);
		LOG.log(' - Convert Only : ' + p.flag_convert_only);
		
		// --- START ADDING JOBS : ----


		addQ("-Reading CUE Data & Preparing", (t)-> 
		{
			cd = new CDInfos();
			cd.cueLoad(p.inputFile);
			
			if (p.flag_convert_only && cd.tracks.length == 1 && cd.tracks[0].isData)
			{
				fail("No point in converting. No audio tracks on the cd."); return;
			}
			
			// Human Readable Audio Quality String
			cd.CD_AUDIO_QUALITY = CodecMaster.getAudioQualityInfo(AC);
			t.complete();
		});
		
		// - Cut tracks
		// ---------------------------
		add(new TaskCutTrackFiles());
		
		// - Encode tracks
		// ---------------------
		addQ("-Preparing to Compress",(t)->
		{
			for (tr in cd.tracks)
			{
				if (p.flag_convert_only && tr.isData) continue;	// Do not Compress Data to ECM
				addNextAsync(new TaskEncodeTrack(tr));
			}
			
			t.complete();
		});
		
		
		if (p.flag_convert_only)
		{
			_addTasksConvert();
		}else
		{
			_addTasksCrush();
		}
		
		// - Final
		addQ((t)->
		{
			LOG.log( "== Detailed CD INFOS:\n" +  cd.getDetailedInfo() );
			
			if (nfoFile != null) {
				var data = cd.getDetailedInfo();
					data += '\n${nfoFileData}\n- CDCRUSH (nodejs) version : ' + CDCRUSH.PROGRAM_VERSION;
				Fs.writeFileSync(nfoFile, data);
			}
			t.complete();
		});

		
	}//---------------------------------------------------;
		
	
	
	function _addTasksConvert()
	{
		addQ('-Create new CUE File' , (t)->		
		{
			var stepProgress:Int = Math.ceil(100.0 / cd.tracks.length);
			
			for (tr in cd.tracks)
			{
				if (!cd.MULTIFILE)
				{
					// Fix the index times to start with 00:00:00
					tr.rewriteIndexes_forMultiFile();
				}
				
				var ext = Path.extname(tr.workingFile);
				tr.trackFile = '${cd.CD_TITLE} (track ${tr.trackNo})$ext';
				
				// Data track was not cut or encoded.
				// It's in the input folder, don't move it
				if(tr.isData && cd.MULTIFILE)
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
			convertedCuePath = Path.join(p.outputDir, cd.CD_TITLE + CDCRUSH.CUE_EXTENSION);
			cd.cueSave(convertedCuePath, [
				'CDCRUSH (nodejs) version : ' + CDCRUSH.PROGRAM_VERSION,
				CDCRUSH.LINK_SOURCE
			]);
			
			if (CDCRUSH.FLAG_NFO)
			{
				nfoFile = FileTool.getPathNoExt(convertedCuePath) + CDCRUSH.INFO_SUFFIX + '.txt';
				nfoFileData = 'Converted to CUE/Encoded Audio Tracks';
			}
			
			t.complete();
		});
	}//---------------------------------------------------;
	
	
	
	function _addTasksCrush()
	{
		// I need this to be on this scope
		var A:Archiver;
		
		// Create Archive
		// Add all tracks to the final archive
		// ---------------------
		addQ("Creating Archive",(t)->
		{
			// Generate the final arc name now that I have the CD TITLE
			final_arc = Path.join(p.outputDir, cd.CD_TITLE + CodecMaster.getArcExt(DC.id));
			
			// Do not overwrite archive if exists, rather rename the new file until unique
			// This is rare, but worth checking
			while (FileTool.pathExists(final_arc))
			{
				LOG.log(final_arc + " already exists, adding (_) until unique", 2);
				final_arc = FileTool.getPathNoExt(final_arc) + "_" + CodecMaster.getArcExt(DC.id);
			}
			
			LOG.log("- Destination Archive :" + final_arc );
			
			// Dev note: working file was set earlier in TaskEncodeTrack();
			var files:Array<String> = [ for (tr in cd.tracks) tr.workingFile ];
			// -
			var path_settings = Path.join(tempDir, CDCRUSH.CDCRUSH_SETTINGS);
			cd.jsonSave(path_settings);
			files.push(path_settings);
			
			// TODO -> Proper Archiver
			A = CodecMaster.getArchiver(DC.id);
				t.syncWith(A);
				t.killExtra = A.kill;
				A.compress(files, final_arc, CodecMaster.getArchiverStr(DC));
		});
		
		// - Get post data
		addQ((t)->
		{
			final_size = A.COMPRESSED_SIZE;
			
			if (CDCRUSH.FLAG_NFO)
			{
				nfoFile = FileTool.getPathNoExt(final_arc) + CDCRUSH.INFO_SUFFIX + '.txt';
				nfoFileData = 
					'Crushed File : ' + Path.basename(final_arc) + '\n' +
					'Archive Size : $final_size';
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
			LOG.log("Deleting tempdir : " + tempDir);
			FileTool.deleteRecursiveDir(tempDir);
		}
	}//---------------------------------------------------;
	
}// --




