package test;

import app.Arc;
import cd.CDInfos;
import djNode.BaseApp;
import djNode.task.CJob;
import djNode.task.CTestTask;
import djNode.tools.FileTool;
import djNode.tools.LOG;
import djNode.utils.CJobReport;
import js.Error;
import js.Node;
import js.node.Fs;
import js.node.Path;

/**
 * Small Unit Tests
 * ...
 */
class TestMain extends BaseApp 
{

	// Test Folder, Writable folder for some tests
	var FLD_01:String = "a:\\";
	
	var quickExit:Void->Void = null;
	
	// --
	override function init() 
	{
		LOG.setLogFile("a:\\LOG.txt", true);
		//--
		PROGRAM_INFO.name = "TESTS FOR " + CDCRUSH.PROGRAM_NAME;
		PROGRAM_INFO.version = CDCRUSH.PROGRAM_VERSION;
		PROGRAM_INFO.desc = CDCRUSH.PROGRAM_SHORT_DESC;
		PROGRAM_INFO.executable = "cdcrush";
		PROGRAM_INFO.author = CDCRUSH.AUTHORNAME;
		PROGRAM_INFO.contact = CDCRUSH.LINK_SOURCE;
		
		// <Actions>
		ARGS.requireAction = true;
		ARGS.Actions.push(['t1', 'Test cdcrush', 'Some CDCRUSH engine tests']);
		ARGS.Actions.push(['arc', 'Test ARC', 'Compresses all input files to output file (must be arc)']);
		super.init();
		
	}//---------------------------------------------------;
	
	override function onStart() 
	{
		super.onStart();

		CDInfos.LOG = function(s){ LOG.log(s);};
		
		switch(argsAction)
		{
			case "t1": testCDCRUSH();
			case "arc" : testArc();	// This is a one time test to test a big on the Arc.hx
			default:
		}
	
		//var p = new CDCRUSH.CrushParams();
		//p.inputFile = argsInput[0];
		//p.audio = {id:'flac', quality:0};
		//p.compressionLevel = 3;
		//var j = getJobCrush(p);
		//
		//var report = new CJobReport(j, false, true);
		//
		//activeJob = j;
		//j.start();
	}//---------------------------------------------------;
	
	//====================================================;
	// TESTS 
	//====================================================;
	
	
	function testArc()
	{
		trace("Compressing", argsInput);
		trace("Into", argsOutput);
		var arc = new Arc("../tools/");
			arc.events.on("progress", function(t){
				trace("ARC PROGRESS GOT " , t);
			});
			arc.compress(argsInput, argsOutput, 5);
			quickExit  = function(){
				if (arc != null) {
					arc.kill();
				}
			}
	}//---------------------------------------------------;
	
	
	// @param tempFolder : A temporary folder for operations (ROOT) a subfolder will be created
	function testCDCRUSH()
	{
		trace('== CDRUSH UNIT TESTS ==');
		trace('-----------------------');
		
		// Some components tests,
		
		var testBins = "../../tests/";
		
		///** Old Version Load test:
			var cd = new cd.CDInfos();
			trace("Loading JSON Version 1 ---");
			cd.jsonLoad(Path.join(testBins, "V1.json"));
			trace("Loading JSON Version 2 ---");
			cd.jsonLoad(Path.join(testBins, "V2.json"));
			trace("Loading JSON Version 3 ---");
			cd.jsonLoad(Path.join(testBins, "V3.json"));
		
		// == CDCRUSH FUNCTIONS --
		// --------------------------
		
		
		var writableTemp = Path.join(FLD_01 , "//_cdcrush_tests");
		
		// Delete the folder
		if (FileTool.pathExists(writableTemp)) 
		{
			trace('- Test Unit Test Folder : "$writableTemp" exists. Deleting.....');
			FileTool.deleteRecursiveDir(writableTemp);
			trace(">> OK");
		}
		
		trace('- Creating Unit Test Folder : "$writableTemp"');
		Fs.mkdirSync(writableTemp);
		trace(">> OK");
		
		// --
		trace('- Setting Temp Folder to "$writableTemp"');
		CDCRUSH.setTempFolder(writableTemp);
		trace(">> OK");
		
		// --
		var tf2 = Path.join(writableTemp, "test");
		trace('- CheckCreateUniqueOutput($tf2);');
		CDCRUSH.checkCreateUniqueOutput(tf2);
		CDCRUSH.checkCreateUniqueOutput(writableTemp, 'test');
		if (!FileTool.pathExists(tf2)) throw "Error";
		if (!FileTool.pathExists(tf2 + "_")) throw "Error";
		trace(">> OK.");
		// --
		trace("- GetAudioQualityString() Some Formats ::");
		trace(CDCRUSH.getAudioQualityString({id:"flac",quality:0}));
		trace(CDCRUSH.getAudioQualityString({id:"vorbis", quality:3}));
		trace(CDCRUSH.getAudioQualityString({id:"opus", quality:3}));
		trace(CDCRUSH.getAudioQualityString({id:"mp3", quality:3}));
		
		try{
			trace(CDCRUSH.getAudioQualityString({id:"other", quality:3}));
		}catch (d:Dynamic){
			trace(" >> OK");
		}
		
		trace(">> OK");
		//--
		
	}//---------------------------------------------------;
	
	
	/**
	 * Simulate a real Crush Job
	 * For Testing out the UI
	 */
	function getJobCrush(p:CDCRUSH.CrushParams)
	{
		var j = new CJob("Compress CD");
		var TRACKS:Int = 3;
		p.tempDir = "\\TEMP_DIR_FAKE\\";
		// --
		j.add(new CTestTask(100, "-Reading", "Reading Cue Data and Preparing"));
		j.add(new CTestTask(500, "Cut", "Cutting tracks into separate files"));
	
		for (t in 0...TRACKS) 
		{
			j.addAsync(new CTestTask(500, "Encoding Track " + t));
		}
	
		j.add(new CTestTask(100, "-Preparing", "Preparing to compress tracks"));
		j.add(new CTestTask(700, "Compressing", "Compressing everything into an archive"));
		j.add(new CTestTask(200, "Finalizing", "Appending settings into the archive"));
		j.add(new CTestTask(100, "-Finalizing"));
		// --
		LOG.log('= COMPRESSING A CD with the following parameters :');
		LOG.log('- Input : ' + p.inputFile);
		LOG.log('- Output Dir : ' + p.outputDir);
		LOG.log('- Temp Dir : ' + p.tempDir);
		LOG.log('- Audio Quality : ' + CDCRUSH.getAudioQualityString(p.audio));
		LOG.log('- Compression Level : ' + p.compressionLevel);
	
		return j;
	}//---------------------------------------------------;
	
	
	
	/**
	 * Simulate a Restore Job
	 * For testing out the UI
	 */
	function getJobRestore(p:CDCRUSH.RestoreParams)
	{
		var j = new CJob("Restore CD");
		var TRACKS:Int = 5;
		p.tempDir = "\\TEMP_DIR_FAKE\\";
		// --
		j.add(new CTestTask(500, "Extracting", "Extracting the archive to temp folder"));
		j.add(new CTestTask(100, "-Preparing to Restore", "Reading stored CD and preparing"));
		for (t in 0...TRACKS) 
		{
			j.addAsync(new CTestTask(500, "Restoring Track " + t));
		}		
		j.add(new CTestTask(100, "-Preparing to Join"));
		j.add(new CTestTask(300, "Join", "Joining tracks into a single .bin"));
		j.add(new CTestTask(300, "Moving, Finalizing"));
		
		// --
		LOG.log('=== RESTORING A CD with the following parameters :');
		LOG.log('- Input : ' + p.inputFile);
		LOG.log('- Output Dir : ' + p.outputDir);
		LOG.log('- Temp Dir : ' + p.tempDir);
		LOG.log('- Force Single bin : ' + p.flag_forceSingle);
		LOG.log('- Create subfolder : ' + p.flag_subfolder);
		LOG.log('- Restore to encoded audio/.cue : ' + p.flag_encCue);
		return j;
	}//---------------------------------------------------;
		
	
	var activeJob:CJob;

	override function onExit() 
	{
		if (activeJob != null) activeJob.forceKill();
		if (quickExit != null) quickExit();
		super.onExit();
	}//---------------------------------------------------;
	
	// --
	static function main()  {
		new test.TestMain();
	}//---------------------------------------------------;
}// --