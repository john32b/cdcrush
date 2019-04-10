/**
   TAK - Lossless Audio Encoder/Decoder 
   Interface for the CLI app
   ----
   
	HELP:
	- https://wiki.hydrogenaud.io/index.php?title=TAK
	
	NOTES:
	
	- Just Streaming from STDIN/STDOUT functions
	
**/

package app;

import djNode.tools.HTool;
import djNode.tools.LOG;
import djNode.utils.CLIApp;
import djNode.utils.ISendingProgress;
import js.node.stream.Readable.IReadable;
import js.node.stream.Writable;

class Tak implements ISendingProgress
{
	// --
	static var WIN32_EXE:String = "Takc.exe";
	// The CLI object
	var app:CLIApp;
	// --
	public var onComplete:Bool->Void;
	public var onProgress:Int->Void;
	public var ERROR(default, null):String;
	
	public function new(exePath:String) 
	{
		app = new CLIApp(WIN32_EXE, exePath);
		app.LOG_STDOUT = false;
		
		app.onClose = (s)->{
			ERROR = app.ERROR;
			HTool.sCall(onComplete, s);
		};
	}//---------------------------------------------------;
	
	/**
	   WAV Stream to TAK File
	   @param	output 
	   @return   Stream, Push data to it
	**/
	public function streamEncode(output:String):IWritable
	{
		LOG.log('Encoding WAV Stream to TAK "$output"');
		app.start(['-e', '-ihs', '-', output]);
		// -e 		encode
		// -ihs		ignore (wave) header size entry (pipe encoding only)
		// -		read from stdin	
		return app.proc.stdin;
	}//---------------------------------------------------;
	
	/**
	   TAK file to WAV Stream
	   @param	input TAK file
	   @param	onReady
	**/
	public function streamDecode(input:String):IReadable
	{
		LOG.log('Converting TAK File to WAV Stream');
		app.start(['-d', input, '-']);
		return app.proc.stdout;
	}//---------------------------------------------------;
	
}// --