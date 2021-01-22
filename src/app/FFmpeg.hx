/****
 * FFmpegAudio Interface
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
 * @DEVNOTES:
 * 	- ffmpeg.exe will return error code (1) if run with no arguments
 *  - DO NOT use "" to files when passing to the CLI runner
 * 
 * 
 * @notes :
 * 
 * 	! ALL operations Overwrite generated files
 *  ! ALL operations Input files are not checked
 *  ! To check if ffmpeg.exe exists use `ffmpeg -L`
 *  ! Progress sending not available in stream functions
 * 
 * @events: 
 * 			`close` 	: ExitOK:<Bool>, ErrorMessage:<String>
 * 			`progress` 	: Percent<Int>
 * 
 * Useful Links:
 * 
 * https://trac.ffmpeg.org/wiki/Encode/HighQualityAudio
 * http://ffmpeg.org/ffmpeg-codecs.html#libopus
 * http://ffmpeg.org/ffmpeg-codecs.html#libvorbis
 * ---------------------------------------*/

package app;

import djNode.tools.FileTool;
import djNode.tools.HTool;
import djNode.tools.LOG;
import djNode.utils.CLIApp;
import djNode.utils.ISendingProgress;
import js.node.Fs;
import js.node.Path;
import js.node.stream.Readable;
import js.node.stream.Writable;
import js.node.stream.Writable.IWritable;


class FFmpeg implements ISendingProgress
{
	// --
	static var WIN32_EXE:String = "ffmpeg.exe";
	
	// The CLI object
	var app:CLIApp;
	
	// -- Helpers
	var secondsConverted:Int;
	var targetSeconds:Int;
	var progress:Int;
	
	// --
  	public var onComplete:Void->Void;
	public var onFail:String->Void;
	public var onProgress:Int->Void;
	public var ERROR(default, null):String;
	
	public function new(exePath:String = "") 
	{
		app = new CLIApp(WIN32_EXE, exePath);
		app.FLAG_ERRORS_ON_STDERR = true;
		app.LOG_STDOUT = false;	// <- For the streams to work, also ffmpeg outputs to user in stderr
		
		targetSeconds = progress = secondsConverted = 0;
		
		// - Listen to Progress
		app.onStdErr = (s) -> {
			if (targetSeconds == 0) return;
			secondsConverted = parseSecondsFromData(s, "time=(\\d{2}):(\\d{2}):(\\d{2})");
			if (secondsConverted ==-1) return;
			progress = Math.ceil((secondsConverted / targetSeconds) * 100);
			if (progress > 100) progress = 100;
			HTool.sCall(onProgress, progress);
		};
		
		// Regardless of success, copy over the error (if any) and pass over success from the app
		app.onClose = (s)->{
			if(s){
				HTool.sCall(onComplete);
			}else{
				ERROR = app.ERROR;	
				HTool.sCall(onFail, ERROR);
			}
		};
	}//---------------------------------------------------;
	
	public function exists():Bool
	{
		return app.exists('-version');
		// NOTE: if ffmpeg runs with no parameters it will error exit
	}//---------------------------------------------------;
	
	/**
	   Returns FFMPEG time to seconds. HELPER FUNCTION
	   The input data is the STDERR FFMPEG produces.
	   @return -1 if could not parse anything
	**/
	function parseSecondsFromData(input:String, expression:String)
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
	public function getSecondsFromFile(input:String, callback:Int->Void)
	{
		var i = -1;
		// DEVNOTE: I can't get it to work in SYNC, because ffmpeg will error
		//			Don't bother fixing this.
		CLIApp.quickExec(app.exePath + ' -i "$input"', function(success, stdout, stderr) {
			// DEVNOTE: Do not check for success, since it will always FAIL even if it produces the output I want
			//			in case of no stderr, the parse function will return -1
			i = parseSecondsFromData(stderr, "\\s*Duration:\\s*(\\d{2}):(\\d{2}):(\\d{2})");
			callback(i);
		});
	}//---------------------------------------------------;
	
	
	/**
	   Encode a PCM file to Audio File
	   @param	input PCM file
	   @param	encodeStr Full Audio Encode String e.g. "-c:a libvorbis -q 64"
	   @param	output Full path with proper extension
	**/
	public function encodeFromPCM(input:String, encodeStr:String, output:String)
	{
		LOG.log('Encoding PCM "$input" to "$output"');
		
		// Init Progress Vars
		secondsConverted = progress = 0;
		targetSeconds = Math.floor(Std.int(Fs.statSync(input).size) / 176400);
		HTool.sCall(onProgress, 0);
		
		var params:Array<String> = [
			'-y', '-f', 's16le', '-ar', '44100', '-ac', '2', 
			'-i', input
		].concat(encodeStr.split(' '));
		params.push(output);
		app.start(params);
	}//---------------------------------------------------;
		
	
	/**
	   Convert an audio file to PCM
	   - Does not check if input exists
	   - Output will be autonamed if null
	   - Output will be overwritten
	   @return Success
	**/
	public function encodeToPCM(input:String, output:String = null)
	{
		if (output == null)
		{
			if (output == null) output = FileTool.getPathNoExt(input) + ".pcm";
		}
		
		secondsConverted = progress = 0;
		HTool.sCall(onProgress, 0);
		
		getSecondsFromFile(input, (s)->{
			if (s < 0) {
				ERROR = 'Could not read "$input"';
				HTool.sCall(onFail, ERROR);
				return;		
			}
			targetSeconds = s;
			
			LOG.log('Converting "$input" to PCM "$output"');
			
			app.start([
				'-i', input,
				'-y',
				'-f', 's16le', '-acodec', 'pcm_s16le', output
				]);
		});
	}//---------------------------------------------------;
	
	
	/**
	   Convert WAV Stream to PCM file
	   @param	output
	   @return  Stream, Push data to it
	**/
	public function stream_WAVtoPCMFile(output:String):IWritable
	{
		LOG.log('Converting WAV STREAM to PCM "$output"');
		targetSeconds = 0;
		app.start([
			'-f', 'wav',
			'-i', 'pipe:0',
			'-y',
			'-f', 's16le', '-acodec', 'pcm_s16le', output
		]);
		return app.proc.stdin;
	}//---------------------------------------------------;
	
	
	/**
	   Convert PCM Stream to Encoded Audio File
	   - You can listen to onComplete() just fine
	   @param	encodeStr Full Audio Encode String e.g. "-c:a libvorbis -q 64"
	   @param	output Full name of the output ( including extension )
	   @return  Stream, Push data to it
	**/
	public function stream_PCMtoEncFile(encodeStr:String, output:String):IWritable
	{
		LOG.log('Encoding Stream to --> "$output"');
		targetSeconds = 0;
		var params:Array<String> = [
			'-y' , '-f' , 's16le' , '-ar' , '44100' , '-ac' , '2',
			'-i' , 'pipe:0'
		].concat(encodeStr.split(' '));
		params.push(output);
		app.start(params);
		return app.proc.stdin;
	}//---------------------------------------------------;
	
	/**
	   Convert PCM Stream to WAV Stream
	   USAGE:
			var c = Ff.stream_PCMtoWAVStream();
			c._out.pipe( X.streamEncode("output.file") );
			Fs.createReadStream(InputFile).pipe(c._in);
	   @return  _in,_out
	**/
	public function stream_PCMtoWAVStream():{_in:IWritable, _out:IReadable}
	{
		LOG.log('Converting PCM Stream to WAV Stream');
		targetSeconds = 0;
		app.start([
			'-f', 's16le', '-ar' , '44100' , '-ac' , '2',
			'-i', 'pipe:0',
			'-f', 'wav', '-'	// '-' will push to stdout
		]);
		
		return {
			_in:app.proc.stdin, 
			_out:app.proc.stdout
		};
	}//---------------------------------------------------;
	
	public function kill()
	{
		if (app != null) app.kill();
	}//---------------------------------------------------;

}// --