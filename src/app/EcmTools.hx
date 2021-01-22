/****
 * ECM Tools interface
 * -------
 * @requires: 	[ecm.exe, unecm.exe] Windows
 * 				[ecm-compress,ecm-uncompress] Linux
 * 
 * @supports: nodeJS
 * @platform: windows, Linux
 * 
 * 	Provides an interface for the ecm tools
 * 
 * 
 * @events: 
 * 			`close` 	: ExitOK:<Bool>, ErrorMessage:<String>
 * 			`progress` 	: Percent<Int>
 *
 * ---------------------------------------*/


package app;


import djNode.tools.HTool;
import djNode.utils.CLIApp;
import djNode.tools.LOG;
import djNode.utils.ISendingProgress;
import js.Node;
import js.node.Path;

	
class EcmTools implements ISendingProgress
{
	#if windows
		private static inline var bin_ecm:String   = "ecm.exe";
		private static inline var bin_unecm:String = "unecm.exe";
	#end

	#if linux
		private static inline var bin_ecm:String   = "ecm-compress";
		private static inline var bin_unecm:String = "ecm-uncompress";
	#end

	// Final Paths
	var exe_ecm:String;
	var exe_unecm:String;
	
	var expr_dec = ~/\s*Decoding \((\d{1,3})%/;
	var expr_enc = ~/\s*Encoding \((\d{1,3})%/;
	
	var app:CLIApp;
	
  	public var onComplete:Void->Void;
	public var onFail:String->Void;
	public var onProgress:Int->Void;
	public var ERROR(default, null):String;

	// --
	public function new(ExeFolder:String = null) 
	{
		exe_ecm = Path.join(ExeFolder, bin_ecm);
		exe_unecm = Path.join(ExeFolder, bin_unecm);
	}//---------------------------------------------------;
	//
	// Will produce to same directory as the input file
	public function ecm(input:String, ?output:String ):Void 
	{
		app = new CLIApp(exe_ecm);
		setup("encode");
		if(output==null)
			app.start([input]);
		else
			app.start([input, output]);
	}//---------------------------------------------------;
	
	// Will ALWAYS un-ECM at the same dir as the file..
	public function unecm(input:String, ?output:String):Void 
	{
		app = new CLIApp(exe_unecm);
		setup("decode");
		if(output==null)
			app.start([input]);
		else
			app.start([input, output]);
	}//---------------------------------------------------;
	
	/**
	 * Call this after the process has been created.
	 */
	private function setup(oper:String):Void
	{
		app.onClose = (s)->{
			if (s){
				HTool.sCall(onComplete);
			}else{
				ERROR = app.ERROR;
				HTool.sCall(onFail,ERROR);
			}
		};
		var expr_per:EReg;
		if (oper == "encode") expr_per = expr_enc; else expr_per = expr_dec;
		app.onStdErr = function(data){
			if (expr_per.match(data)) {
				HTool.sCall(onProgress, Std.parseInt(expr_per.matched(1)));
			}	
		};	
	}//---------------------------------------------------;
	
	public function kill()
	{
		if (app != null) app.kill();
	}//---------------------------------------------------;
	
}//--end class--