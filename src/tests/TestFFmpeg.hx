package tests;

import app.FFmpegAudio;
import djNode.BaseApp;
import djNode.tools.LOG;
import js.node.Fs;
import js.node.Path;

/**
 * Quick FFMPEG user tests
 * not a unit test
 * ...
 * LOG : Works ok
 */
class TestFFmpeg extends BaseApp 
{

	override function init() 
	{
		PROGRAM_INFO.name = "FFMPEG Test";
		ARGS.requireAction = true;
		ARGS.inputRule = "yes";
		ARGS.Actions.push(['pcm', "ToPCM"]);
		ARGS.Actions.push(['vorb', "ToVorbis"]);
		ARGS.Actions.push(['opus', "ToOpus"]);
		ARGS.Actions.push(['mp3', "ToMp3"]);
		super.init();
	}
	
	override function onStart() 
	{
		printBanner();
		
		var dest = Path.join(Path.dirname(argsInput[0]), "FFmpegTestGenerated");
		
		var f = new FFmpegAudio();

		f.events.once("close", function(s,a){
			if (s){
				LOG.log("Complete");
			}else{
				LOG.log("Error, " + a, 3);
			}
		});

		
		var q:Int = 2;
		if (argsInput[1] != null)
		{
			q = Std.parseInt(argsInput[1]);
		}
		
		
		switch(argsAction)
		{
			case "pcm":
			T.H2("Converting to PCM");
			f.audioToPCM(argsInput[0], dest + '.pcm');
			case "vorb":
			T.H2("Converting PCM to LIB VORBIS");
			f.audioPCMToOggVorbis(argsInput[0], q, dest + '.ogg');
			case "flac":
			T.H2("Converting PCM to FLAC");
			f.audioPCMToFlac(argsInput[0], dest + '.flac');
			case "opus":
			T.H2("Converting PCM to OPUS");
			f.audioPCMToOggOpus(argsInput[0],q, dest + '.ogg');
			case "mp3":
			T.H2("Converting PCM to MP3");
			f.audioPCMToMP3(argsInput[0], q, dest + '.mp3');
			default:
		}
		
	}// -
	
	// --
	static function main()  {
		LOG.init("testffmpeg.log.txt");
		new TestFFmpeg();
	}//-----------------------------------------------;
	
}//---------------------------------------------------;