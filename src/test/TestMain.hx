package test;

import app.EcmTools;
import app.FFmpeg;
import app.FreeArc;
import app.SevenZip;
import app.Tak;
import cd.CDInfos;
import djNode.BaseApp;
import djNode.task.CJob;
import djNode.task.CTask;
import djNode.tools.FileTool;
import djNode.tools.HTool;
import djNode.tools.LOG;
import djNode.utils.CLIApp;
import haxe.macro.Expr;
import js.node.Crypto;
import js.node.Fs;
import js.node.Path;

/**
 * Tests for CDCRUSH Engine & Components
 * 
 * HOW TO RUN
 * ----------
 *  - set `PATH_TESTS` to a writable folder
 */
class TestMain extends BaseApp 
{
	// -
	static function main() new test.TestMain();
	
	// You can check this file for more info on the tests
	var LOG_FILE 	= "a:\\cdcrush_dev_log.txt";
	var PATH_TESTS 	= "a:\\cdcrush_tests"; 		// (folder will be created)
	// --
	// Leave these alone:
	var SOUND_WAV 	= "..\\tests\\sound.wav";	// Master sound to test codecs with
	var PATH_CUE	= "..\\tests\\cd_test.cue";
	var PATH_TOOLS 	= "..\\tools";
	
	// Some generated files that I need to keep track of
	// Filepaths are generated from within Jobs
	var gen = {
		pcm:"",
		flac:"",
		flactopcm:"",
		tak:"",
		taktopcm:"",
		a_7z:"",
		a_zip:"",
		a_arc:"",
		fileR:"",
		fileR_md5:"",
	};
	
	// Since no operations are going to run simultaneously. I can reuse these objects
	var Ff:FFmpeg;
	var Tk:Tak;
	//---------------------------------------------------;
	
	override function init() 
	{
		LOG.setLogFile(LOG_FILE);
		super.init();
	}//---------------------------------------------------;
	
	override function onStart() 
	{
		T.H2("CDCRUSH Component Tests :");
		
		Ff = new FFmpeg(); //<- You need ffmpeg on path
		Tk = new Tak(PATH_TOOLS);
		
		// --
		try{
			FileTool.deleteRecursiveDir(PATH_TESTS);
			FileTool.createRecursiveDir(PATH_TESTS);
		}catch (e:Dynamic) {
			exitError('Can`t create or access $PATH_TESTS');
		}
		
		
		// Task/Job Reports
		// TODO: Better reports
		CJob.global_job_status = (s, j)->{
			if (s == CJobStatus.start) {
				T.printf('--> STARTING TESTS : ~yellow~${j.name}~!~\n');
			}else
			if (s == CJobStatus.allcomplete) {
				T.printf('--> All tests completed successfully ~green~[OK]~!~\n');
				post();
			}else
			if (s == CJobStatus.fail) {
				T.printf('~red~## A TEST HAS FAILED ##~!~\n');
				T.printf('  > Task : ${j.TASK_LAST} | ERROR : ${j.ERROR}\n');
				post();
			}else
			if (s == CJobStatus.taskStart) {
				if (j.TASK_LAST.info != null) T.printf(' >> ${j.TASK_LAST.info}\n');
			}
			return null;
		};

		// Run Tests:
		test_FFMPEG()
			.start()
			.then(test_TAK())
			.then(test_Lossless_Integrity())
			.then(test_Archivers())
			.then(test_Split_Join())
			.then(test_ECM())
			.then(test_CDParser())
			.then(test_CodecMaster());
	}//---------------------------------------------------;


	
	function post()
	{
		T.fg("yellow");
		T.print('Please manually delete the test folder\n');
		T.printf('  > $PATH_TESTS ~!~\n');
	}//---------------------------------------------------;
	
	/**
	 * Small tests
	 */
	function test_CodecMaster()
	{
		return new CJob("Codec Master.").addQ((t)->{
			trace("Archivers" 	, CodecMaster.getAvailableArchivers());
			trace("Audio Codecs" , CodecMaster.getAvailableAudioCodecs());
			trace("Normalized Codec Strings");
			// Test User Params
			var cc = ['OPUS:1', 'OPUS', 'MP3::', 'MP3:4', 'tak', 'tak:f', 'null:null', 'ne:2:three', 'VORBIS:4'];
			for (c in cc){
				var nfo = "";
				var res = CodecMaster.normalizeAudioSettings(c);
				if (res == null) res = "ERROR"; 
				else nfo = CodecMaster.getAudioQualityInfo(CodecMaster.getSettingsTuple(res));
				trace('$c  ->  $res  :  $nfo');
			}
			t.complete();
		});
	}//---------------------------------------------------;
	
	
	/**
	   Test CDInfos class
	   - Reading/Writing CUE
	   - Reading/Writing JSON
	**/
	function test_CDParser()
	{
		var j = new CJob("CD Parser");
		var cd:CDInfos;
		
		j.addQ((t)->{
			CDInfos.LOG = (s)->LOG.log(s);
			cd = new CDInfos();
			// Should load and not throw errors
			trace("Reading CUE file");
			cd.cueLoad(PATH_CUE);
			// Should save and not throw errors
			trace("Saving CUE file");
			cd.cueSave(Path.join(PATH_TESTS, "cuesave.cue"), ["Saved from CDCRUSH TestSuite"]);
			// -
			trace("Saving JSON CD Info file");
			cd.tracks[0].storedFileName = "track01.bin";
			cd.tracks[1].storedFileName = "track02.bin";
			cd.tracks[2].storedFileName = "track03.bin";
			cd.jsonSave(Path.join(PATH_TESTS, "cdsave.json"));
			t.complete();
		});
		
		return j;
	}//---------------------------------------------------;
	
	
	/**
	   - Splitting A file to multiple parts
	   - Joining that file back to a single file
	   - Comparing Hashes
	**/
	function test_Split_Join()
	{
		var j = new CJob("File Split/Join");
		
		var BYTELEN = 65536 * 2;
		var p1len = Math.floor(BYTELEN / 2) - 1024; // Not exactly half
		var md5 = "";
		var p1,p2,joined:String;
		
		j.addQ((t)->{
			gen.fileR = Path.join(PATH_TESTS, 'fileRandom.rnd');
			// Create random file;
			var fs = Fs.createWriteStream(gen.fileR);
				fs.write(Crypto.randomBytes(BYTELEN), t.complete);
		});
		j.addQ((t)->{
			trace('Generated File with Random Data ($BYTELEN) bytes');
			p1 = gen.fileR + '.part1';
			trace("Cutting File to part 1 with size " + p1len);
			FileTool.copyFilePart(gen.fileR, p1, 0, p1len, (s)->{
				if (s == null) t.complete(); else t.fail(s);
			});
		});
		j.addQ((t)->{
			p2 = gen.fileR + '.part2';
			trace("Cutting File to part 2 with remaining size");
			FileTool.copyFilePart(gen.fileR, p2, p1len, 0, (s)->{
				if (s == null) t.complete(); else t.fail(s);
			});
		});
		j.addQ((t)->{
			trace('Joining Part1 + Part2 Together again');
			joined = gen.fileR + '.joined';
			FileTool.copyFilePart(p1, joined, 0, 0, (s)->{
				if (s == null) t.complete(); else t.fail(s);
			});
		});
		j.addQ((t)->{
			FileTool.copyFilePart(p2, joined, 0, 0, (s)->{
				if (s == null) t.complete(); else t.fail(s);
			});
		});
		j.addQ((t)->{
			gen.fileR_md5 = FileTool.getFileMD5(gen.fileR);
			var md5_j = FileTool.getFileMD5(joined);
			trace('Original File MD5: ${gen.fileR_md5}');
			trace('Joined   File MD5: $md5_j');
			if (gen.fileR_md5 != md5_j){
				throw " Joined file different MD5 hash";
			}else{
				t.complete();
			}
		});
		return j;
	}//---------------------------------------------------;
		
	
	/**
		- Creating 7zip and zip archives
		- Restoring 7zip and zip archives
		- Comparing filesize of original and restored
	**/
	function test_Archivers():CJob
	{
		var j = new CJob("7Zip Archiver");
		var Z = new SevenZip(PATH_TOOLS);
		var A = new FreeArc(PATH_TOOLS);
		
		var fold:Array<String> = []; // Extracted archives folders [7z,zip,arc];
		
		var flist:Array<String>;	// Files to compress
		var fsize:Float;
	
		j.addQ("Initializing Archiver test files", (t)->{
			gen.a_7z  = Path.join(PATH_TESTS, 'archive.7z');
			gen.a_zip = Path.join(PATH_TESTS, 'archive.zip');
			gen.a_arc = Path.join(PATH_TESTS, 'archive.arc');
			flist = [gen.flac, gen.tak, gen.pcm];
			fsize = 0.0; // Force Float Type
			for (i in flist) fsize += Fs.statSync(i).size;
			t.complete();
		});
				
		// Compress files with default compression
		j.addQ("Creating (.7z) Archive", (t)->{
			t.syncWith(Z);
			Z.compress(flist, gen.a_7z);
		});
		j.addQ("Creating (.zip) Archive",(t)->{
			t.syncWith(Z);
			Z.compress(flist, gen.a_zip);
		});
		j.addQ("Creating (.arc) Archive",(t)->{
			t.syncWith(A);
			A.compress(flist, gen.a_arc);
		});
	
		// Restore archives each to separate folder
		j.addQ("Restoring Archive (.7z)",(t)->{
			t.syncWith(Z);
			fold[0] = Path.join(PATH_TESTS, "_7z");
			Z.extract(gen.a_7z, fold[0]);
		});
		j.addQ("Restoring Archive (.zip)",(t)->{
			t.syncWith(Z);
			fold[1] = Path.join(PATH_TESTS, "_zip");
			Z.extract(gen.a_zip, fold[1]);
		});
		j.addQ("Restoring Archive (.arc)",(t)->{
			t.syncWith(A);
			fold[2] = Path.join(PATH_TESTS, "_arc");
			A.extract(gen.a_arc, fold[2]);
		});
		
		// Check file sizes 
		j.addQ("Checking Archives", (t)->{
			trace("Original files Size: " + fsize);
			
			// - Get the restored files size
			var fl:Array<Array<String>> = [];
			var sizes:Array<Float> = [];
			for (i in fold) fl.push(FileTool.getFileListFromDir(i, true));
			for (c in 0...fl.length) {
				sizes[c] = 0;
				for (f in fl[c]) sizes[c] += Fs.statSync(f).size;
			}
			
			trace("Extracted files from (.7z) Size   : " + sizes[0]);
			trace("Extracted files from (.zip) Size  : " + sizes[1]);
			trace("Extracted files from (.arc) Size  : " + sizes[2]);
			if (sizes[0] != fsize) throw "7zip restored files, different size";
			if (sizes[1] != fsize) throw "Zip restored files, different size";
			if (sizes[2] != fsize) throw "FreeArc restored files, different size";
			t.complete();
		});
		
		return j;
	}//---------------------------------------------------;
	
	
	/**
	   - Calculates MD5 of lossless tracks restored back to PCM
	   - FLAC,TAK -against-> original PCM
	   - Hash must be the same
	**/
	function test_Lossless_Integrity():CJob
	{
		var j = new CJob("Test Recovered Audio Hash");
		return j.addQ("Checking Audio Integrity", (t)->{
			var m1 = FileTool.getFileMD5(gen.pcm);
			var m2 = FileTool.getFileMD5(gen.flactopcm);
			var m3 = FileTool.getFileMD5(gen.taktopcm);
			trace("Audio MD5 (PCM)       : " + m1);
			trace("Audio MD5 (FLAC->PCM) : " + m2);
			trace("Audio MD5 (TAK->PCM)  : " + m3);
			if (m1 != m2) throw "Flac Restore Error";
			if (m1 != m3) throw "TAK Restore Error";
			t.complete();
		});
	}//---------------------------------------------------;
	
	
	/**
	  - Checks TAK functions 
	**/
	function test_TAK():CJob
	{
		gen.tak = gen.pcm + '_.tak';
		gen.taktopcm = gen.pcm + '_(r)_tak_.pcm';
		
		var j = new CJob("TAK Test");

		j.addQ((t)->{
			trace("TAK.streamEncode() , FFmpeg.stream_PCMtoWAVStream()");
			trace("PCM (STREAM) -> FFMPEG -> WAV (STREAM) -> TAK -> File Output");
			t.syncWith(Tk);	// <- next task when Tak process Closes
			// NOTE: I can do pipes like this, no callbacks when ready, since they are buffered to RAM
			var inWavstream = Tk.streamEncode(gen.tak);
			var pcmtowav = Ff.stream_PCMtoWAVStream(); // Dual Converter
				pcmtowav._out.pipe(inWavstream);
			var fstream = Fs.createReadStream(gen.pcm);
				fstream.pipe(pcmtowav._in);
		});		
		
		j.addQ((t)->{
			trace("TAK.streamDecode()");
			trace("TAK File -> WAV (STREAM) -> FFMPEG -> PCM File");
			t.syncWith(Ff);
			var inwav  = Ff.stream_WAVtoPCMFile(gen.taktopcm);
			var takstr = Tk.streamDecode(gen.tak);
			takstr.pipe(inwav);
			
		});
		
		return j;
	}//---------------------------------------------------;


	/**
	   - Checks FFmpeg and functions
	**/
	function test_FFMPEG():CJob
	{		
		var j = new CJob("FFmpeg Test");
	
		// - Prepare the filenames to be created (some of them)
		gen.pcm  = Path.join(PATH_TESTS, 'audio_.pcm');

		// -- 
		j.addQ("FFmpeg check", (t)->{
			// Check for FFMPEG
			if (!Ff.exists()) throw "ffmpeg.exe not found";
			trace('FFMPEG.FileDuration()');
			Ff.getSecondsFromFile(SOUND_WAV, (s)->{
				trace('Seconds Got : $s');
				if (s ==-1) {
					t.fail("Error reading file info.");
				}else{
					t.complete();
				}
			});
		});
		
		j.addQ( (t)->{
			// And in the same task do:
			trace('FFMPEG.encodeToPCM()');
			t.syncWith(Ff);
			Ff.encodeToPCM(SOUND_WAV, gen.pcm);
			// I need to wait for that ^ to finish, so new task
		});
		
		// - Test FFMPEG codecs
		var codecs = CodecMaster.getAvailableAudioCodecs();
		for (i in codecs)
		{
			// Special, TAK encoding not with FFMPEG
			if (i == "TAK") continue;
			
			j.addQ( (t)->{
				var ac = CodecMaster.audio.get(i);
				var encstr = CodecMaster.getAudioStr({id:i, q:1});
				trace('FFMPEG.encodeFromPCM($encstr)');
				t.syncWith(Ff);
				var f = '${gen.pcm}_${i}_${ac.ext}';
				if (i == "FLAC") gen.flac = f;
				Ff.encodeFromPCM(gen.pcm, encstr, f);
			});
		}
		
		j.addQ( (t) ->{
			trace("Restoring FLAC back to PCM");
			t.syncWith(Ff);
			gen.flactopcm = gen.pcm + '_(r)_flac_.pcm';
			Ff.encodeToPCM(gen.flac, gen.flactopcm);
		});
		
		
		j.addQ( (t) ->{
			trace("FFMPEG.stream_PCMtoEncFile()");
			var fstream  = Fs.createReadStream(gen.pcm);
			// Puting a random encoder, encoders already tested
			var instream = Ff.stream_PCMtoEncFile(CodecMaster.getAudioStr({id:'VORBIS', q:0}), Path.join(PATH_TESTS, "frompcmstream.ogg"));
			t.syncWith(Ff);
			fstream.pipe(instream);
			fstream.once("close", ()-> trace('File Stream for "${gen.pcm}" [CLOSE]'));
		});
		
		return j;
	}//---------------------------------------------------;
	
	
	function test_ECM()
	{
		var j = new CJob("ECM-UNECM Test");
		var E = new EcmTools(PATH_TOOLS);
		
		var ecmp = "";
		var unecmp = "";
		
		j.addQ('-> ECM ..', (t)->{
			ecmp = gen.fileR + ".ecm";
			t.syncWith(E);
			E.ecm(gen.fileR, ecmp);
		});
		
		j.addQ('-> UNECM ..', (t)->{
			t.syncWith(E);
			unecmp = gen.fileR + ".unecm";
			E.unecm(ecmp, unecmp);
		});
		
		j.addQ('Check ..', (t)->{
			// NOTE: In order to check MD5 I need to test with a real BIN track, else MD5 are not the same
			t.complete();
		});
		
		return j;
	}//---------------------------------------------------;
	
}// 