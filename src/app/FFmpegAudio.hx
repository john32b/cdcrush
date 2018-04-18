/****
 * FFmpegAudio Interface
 * -------
 * johndimi, johndimi@outlook.com
 * -------
 * @requires: [FFmpeg.exe]
 * @supports: nodeJS
 * @platform: windows
 * 
 *  - Reports progress with events
 * 	- Encode to PCM
 *  - Encode to MP3
 *  - Encode to LibVorbis
 *  - Encode to LibOpus
 *
 * 
 * @notes :
 * 
 * 	! ALL operations Overwrite generated files
 *  ! ALL operations Input files are not checked
 * 
 * @events: 
 * 			`close` 	: ExitOK:<Bool>, ErrorMessage:<String>
 * 			`progress` 	: Percent<Int>
 * 			
 * 
 * Useful Links:
 * 
 * https://trac.ffmpeg.org/wiki/Encode/HighQualityAudio
 * http://ffmpeg.org/ffmpeg-codecs.html#libopus
 * http://ffmpeg.org/ffmpeg-codecs.html#libvorbis
 * ---------------------------------------*/

package app;

import djNode.utils.CLIApp;
import djNode.tools.FileTool;
import djNode.tools.LOG;
import js.Node;
import js.node.Fs;
import js.node.Path;


class FFmpegAudio extends CLIApp
{
	// --
	static var WIN32_EXE:String = "ffmpeg.exe";
	
	// Ogg vorbis Quality (index), VBR kbps
	public static var VORBIS_QUALITY:Array<Int> = [ 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 500 ];

	// MP3 quality (index), VBR kbps
	public static var MP3_QUALITY:Array<Int> = [65, 85, 100, 115, 130, 165, 175, 190, 225, 245];
	
	// OPUS quality (index), VBR kbps
	public static var OPUS_QUALITY:Array<Int> = [ 32, 48, 64, 80, 96, 112, 128, 160, 320];
	
	// -- Helpers
	var secondsConverted:Int;
	var targetSeconds:Int;
	var progress:Int;
	
	public function new(exePath:String = "") 
	{
		super(Path.join(exePath, WIN32_EXE));
		
		// - Listen to Progress
		onStdErr = function(s){
			if (targetSeconds == 0) return;
			secondsConverted = readSecondsFromOutput(s, "time=(\\d{2}):(\\d{2}):(\\d{2})");
			if (secondsConverted ==-1) return;
			progress = Math.ceil((secondsConverted / targetSeconds) * 100);
			if (progress > 100) progress = 100;
			events.emit("progress", progress);
		};
	
	}//---------------------------------------------------;
	
	/**
	   Returns FFMPEG time to seconds. HELPER FUNCTION
	**/
	function readSecondsFromOutput(input:String, expression:String)
	{
		var e = new EReg(expression,"");
		var seconds = -1;
		if (e.match(input))
		{
			var hh:Int = Std.parseInt(e.matched(1));
			var mm:Int = Std.parseInt(e.matched(2));
			var ss:Int = Std.parseInt(e.matched(3));
			seconds = (ss + (mm * 60) + (hh * 360));
		}
		return seconds;
	}//---------------------------------------------------;

	/**
	   Read a file's duration, used for when converting to PCM
	   @param	input 
	   @param	callback <0 for error. >0 for seconds read
	**/
	function getSecondsFromFile(input:String,callback:Int->Void)
	{
		var i = -1;
		CLIApp.quickExec(exePath + ' -i "$input" -f null -', function(success, stdout, stderr){
			if (success){
				i = readSecondsFromOutput(stderr, "\\s*Duration:\\s*(\\d{2}):(\\d{2}):(\\d{2})");
			}
			callback(i);
		});
	}//---------------------------------------------------;
	
	// -- Helper
	// -- Set the progress vars for a PCM file
	function _initProgressVars(input:String)
	{
		var fsize:Int = Std.int(Fs.statSync(input).size);
		secondsConverted = progress = 0;
		targetSeconds = Math.floor(fsize / 176400);
		events.emit("progress", 0);
	}//---------------------------------------------------;

	
	/**
	   Convert an audio file to a PCM file (CDDA)
	   @param	input Full path of file to be converted to PCM
	   @param	output If ommited will be autonamed
	**/
	public function audioToPCM(input:String, ?output:String)
	{		
		if (output == null) output = FileTool.getPathNoExt(input) + ".pcm";
		
		//LOG.log('Converting `$input` to PCM `$output`');
		LOG.log('Converting "' + Path.basename(input) + '" to PCM');
		
		secondsConverted = progress = 0;
		events.emit("progress", progress); // Zero out progress
		getSecondsFromFile(input, function(sec)
		{
			if (sec < 0){
				events.emit("close", false, 'Could not read $input');
				return;
			}
			targetSeconds = sec;
			start([
				'-i', input,
				'-y', '-f', 's16le', '-acodec', 'pcm_s16le', output
			]);
		});
	}//---------------------------------------------------;
		
		
	/**
	   Convert a PCM audio file to OGG OPUS
	   @param	input
	   @param	quality In KBPS from 32 to 500
	   @param	output If ommited, will be automatically set
	**/
	public function audioPCMToOggOpus(input:String, quality:Int, ?output:String)
	{
		if (quality < 32) quality = 32;
		else if (quality > 500) quality = 500;
		if (output == null) output = FileTool.getPathNoExt(input) + ".ogg";
		
		LOG.log('Converting "' + Path.basename(input) + '" to OPUS OGG, Quality $quality`');
		//LOG.log('Converting `$input` to OPUS OGG `$output`, Quality `$quality`');
		
		_initProgressVars(input);
		start([
			'-y', '-f', 's16le', '-ar', '44.1k', '-ac', '2', '-i', input,
			'-c:a', 'libopus', '-b:a', '${quality}k', '-vbr', 'on', '-compression_level', '10', output
		]);
	}//---------------------------------------------------;
	
	/**
	   Convert a PCM audio file to OGG VORBIS
	   @param	input
	   @param	quality Quality from 0(lowest) to 10(highest)
	   @param	output
	**/
	public function audioPCMToOggVorbis(input:String, quality:Int, ?output:String)
	{
		if (quality < 0) quality = 0; else if (quality > 10) quality = 10;
		if (output == null) output = FileTool.getPathNoExt(input) + ".ogg";
		
		LOG.log('Converting "' + Path.basename(input) + '" to VORBIS OGG, Quality ' + VORBIS_QUALITY[quality]);
		
		_initProgressVars(input);
		start([
			'-y', '-f', 's16le', '-ar', '44.1k', '-ac', '2', '-i', input,
			'-c:a', 'libvorbis', '-q', '$quality', output
		]);
	}//---------------------------------------------------;
	
	/**
	   Convert a PCM audio file to FLAC
	   @param	input
	   @param	quality
	   @param	output
	**/
	public function audioPCMToFlac(input:String, ?output:String)
	{
		if (output == null) output = FileTool.getPathNoExt(input) + ".flac";
		
		LOG.log('Converting "' + Path.basename(input) + '" to FLAC');
		
		_initProgressVars(input);
		
		start([
			'-y', '-f', 's16le', '-ar', '44.1k', '-ac', '2', '-i', input,
			'-c:a', 'flac', output
		]);
	}//---------------------------------------------------;

	/**
	   Convert a PCM audio file to MP3 Variable Bitrate
	   @param	input
	   @param	quality 0 to 9 (lowest -> highest)
	   @param	output
	**/
	public function audioPCMToMP3(input:String, quality:Int, ?output:String)
	{
		if (quality < 0) quality = 0; else if (quality > 9) quality = 9;
		if (output == null) output = FileTool.getPathNoExt(input) + ".mp3";
		
		// For this MP3 codec, 0s is the highest, and 9 the lowest quality
		// I am inverting these to comply with all the codecs (0 lowest quality)
		quality = 9 - quality;
		
		LOG.log('Converting "' + Path.basename(input) + '" to MP3, Quality' + MP3_QUALITY[quality]);
		
		_initProgressVars(input);
		start([
			'-y', '-f', 's16le', '-ar', '44.1k', '-ac', '2', '-i', input,
			'-c:a', 'libmp3lame', '-q:a', '$quality', output
		]);
	}//---------------------------------------------------;
	
}//--end class--