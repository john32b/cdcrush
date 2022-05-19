package;

import app.Archiver;
import cd.CDInfos;
import djNode.task.CJob;
import djNode.tools.FileTool;
import djNode.tools.LOG;
import djNode.tools.StrTool;
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
	// -
	var AC:CodecMaster.SettingsTuple;
	var DC:CodecMaster.SettingsTuple;
	
	var nfoFile:String;		// DEV: If set, will autowrite at the final step of the job
	var nfoFileData:String; // Data to write below the standard cd infos
	
	
	// These vars will be read from the UI to display some info after completion ::
	// 
	// In <CONVERT> operation, Holds path of new <.cue> file
	public var convertedCuePath:String;
	// Hold size of Archive created
	public var final_size:Float = 0;	// Crushed Size
	public var original_size:Float = 0;	// Bin Size
	// Final destination ARCHIVE file, Name is autogenerated from CD TITLE
	public var final_arc:String;
	
	// --
	public function new(P:CrushParams)
	{
		super();
		p = P;
		var _f = Path.basename(P.inputFile);
		if (p.flag_convert_only == null){
			p.flag_convert_only = false;
		}
		if (p.flag_convert_only) {
			sid = "convert";
			info = 'Converting : [${_f}]';	// [ ] will be replaced with color codes in cJobReport
		}else{
			sid = "crush";
			info = 'Crushing : [${_f}]';	// ^ same
		}
	}//---------------------------------------------------;
	
	// -- Errors thrown here will be caught
	// --
	override public function init() 
	{
		// NOTE: ac/dc MUST be checked beforehand
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
		
		// --- START ADDING TASKS : ----

		addQ("-Reading CUE Data & Preparing", (t)-> 
		{
			cd = new CDInfos();
			cd.cueLoad(p.inputFile);
			
			if (p.flag_convert_only && cd.tracks.length == 1 && cd.tracks[0].isData)
			{
				return t.fail("No point in converting. No audio tracks on the cd.");
			}
			
			original_size = cd.CD_TOTAL_SIZE;
			
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
				if (p.flag_convert_only && tr.isData) 
				{
					// Do not Compress Data to ECM, leave it as is
					// Calculate MD5 here, since this is normally done in TaskEncodeTrack()
					tr.md5 = FileTool.getFileMD5(tr.workingFile);
					continue;
				}
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
					data += '\n${nfoFileData}\n\n; CDCRUSH (nodejs) version : ' + CDCRUSH.PROGRAM_VERSION;
				Fs.writeFileSync(nfoFile, data);
			}
			t.complete();
		});

		
	}//---------------------------------------------------;
		
	
	
	function _addTasksConvert()
	{
		addQ('Finalizing' , (t)->
		{
			var stepProgress:Int = Math.ceil(100.0 / cd.tracks.length);
			
			for (tr in cd.tracks)
			{
				if (!cd.MULTIFILE)
				{
					// I want to force multifile mode on the cd
					// Fix the index times to start with 00:00:00
					tr.rewriteIndexes_forMultiFile();
				}
				
				var ext = Path.extname(tr.workingFile);
				final_size += Fs.statSync(tr.workingFile).size;

				tr.trackFile = '${cd.CD_TITLE} (track ${tr.trackNo})$ext';

				if (tr.isData && !flag_tracksOnTempFolder)
				{
					// Copy only data tracks that are still on <input>
					FileTool.copyFileSync(tr.workingFile, Path.join(p.outputDir, tr.trackFile));
				}
				else
				{
					// NOTE: - <TaskCompress> already put the audio files on the output folder
					// 		   This just renames the files to proper filename
					// 		 - All data tracks that were cut are on temp folder
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
					'Archive Size : ' + StrTool.bytesToMBStr(final_size) + 'MB\n' +
					'Archive Compression : ' + CodecMaster.getArchiverInfo(DC);
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




