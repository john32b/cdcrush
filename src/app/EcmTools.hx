/****
 * ECM Tools interface
 * -------
 * johndimi, johndimi@outlook.com
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


import djNode.utils.CLIApp;
import djNode.tools.LOG;
import js.Node;
import js.node.Path;

	
class EcmTools extends CLIApp
{
	#if windows
		private static inline var win32_ecm:String   = "ecm.exe";
		private static inline var win32_unecm:String = "unecm.exe";
	#end

	#if linux
		private static inline var linux_ecm:String   = "ecm-compress";
		private static inline var linux_unecm:String = "ecm-uncompress";
	#end

	// Final Paths
	var exe_ecm:String;
	var exe_unecm:String;
	
	var expr_dec = ~/\s*Decoding \((\d{1,3})%/;
	var expr_enc = ~/\s*Encoding \((\d{1,3})%/;
	
	// --
	public function new(ExeFolder:String = null) 
	{
		super();
		
		#if windows
			exe_ecm = Path.join(ExeFolder, win32_ecm);
			exe_unecm = Path.join(ExeFolder, win32_unecm);
		#elseif linux
			exe_ecm = Path.join(ExeFolder, linux_ecm);
			exe_unecm = Path.join(ExeFolder, linux_unecm);
		#end
		
	}//---------------------------------------------------;
	//
	// Will produce to same directory as the input file
	public function ecm(input:String, ?output:String ):Void 
	{
		exePath = exe_ecm;
		listen_progress("encode");
		if(output==null)
			start([input]);
		else
			start([input, output]);
	}//---------------------------------------------------;
	
	// Will ALWAYS un-ECM at the same dir as the file..
	public function unecm(input:String, ?output:String):Void 
	{
		exePath = exe_unecm;
		listen_progress("decode");
		if(output==null)
			start([input]);
		else
			start([input, output]);
	}//---------------------------------------------------;
	
	/**
	 * Call this after the process has been created.
	 */
	private function listen_progress(oper:String):Void
	{	
		var expr_per:EReg;
		if (oper == "encode") expr_per = expr_enc; else expr_per = expr_dec;
		onStdErr = function(data){
			if (expr_per.match(data)) {
				events.emit("progress", Std.parseInt(expr_per.matched(1)));
			}	
		};	
	}//---------------------------------------------------;
	
		
}//--end class--