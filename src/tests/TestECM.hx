package tests;

import app.FFmpegAudio;
import djNode.BaseApp;
import djNode.tools.LOG;
import app.EcmTools;
import js.node.Fs;
import js.node.Path;
import js.node.crypto.ECDH;

/**
 * Quick ECM user tests
 * not a unit test
 * ...
 * LOG : Works ok
 */
class TestECM extends BaseApp 
{
	override function init() 
	{
		PROGRAM_INFO.name = "ECM Test";
		ARGS.requireAction = true;
		ARGS.inputRule = "yes";
		ARGS.Actions.push(['ecm', "ECM" , "Encode a cd track"]);
		ARGS.Actions.push(['unecm', "UN-ECM", "Decode a cd track"]);
		super.init();
	}
	
	override function onStart() 
	{
		printBanner();
		
		var ecm = new EcmTools("../tools/");

		ecm.events.once("close", function(s, a){
			if (s){
				LOG.log("Complete");
			}else{
				LOG.log("Error, " + a, 3);
			}
		});
		
		ecm.events.on("progress", function(p){
			LOG.log('Process = $p');
		});
		

		switch(argsAction)
		{
			case "ecm":
			T.H2("Track to ECM");
			ecm.ecm(argsInput[0]);
			case "unecm":
			T.H2("Track UN-ECM");
			ecm.unecm(argsInput[0]);
			default:
		}
		
	}// -
	
	// --
	static function main()  {
		LOG.init("testECM.log.txt");
		new TestECM();
	}//-----------------------------------------------;
	
}//---------------------------------------------------;