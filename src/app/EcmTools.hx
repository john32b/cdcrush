/****
 * ECM Tools interface
 * -------
 * johndimi, johndimi@outlook.com
 * -------
 * @requires: [ecm.exe, unecm.exe]
 * @supportedplatforms: nodeJS
 * 
 * 
 * Provides an interface for the ecm tools
 * ECM tools must be in the executable file's folder
 * 
 * @events: 
 * 			progress(int), Percentage
 *
 * ---------------------------------------*/


package djNode.app;


import djNode.tools.FileTool;
import djNode.tools.LOG;
import js.Node;
import djNode.app.AppSpawner;
import js.node.Path;


/*

Version 0.9
	Added output
	
Version 0.8
	First
	
*/
	
class EcmTools extends AppSpawner
{
	private static inline var win32_ecm:String   = "ecm.exe";
	private static inline var win32_unecm:String = "unecm.exe";

	private static inline var linux_ecm:String   = "ecm-compress";
	private static inline var linux_unecm:String = "ecm-uncompress";

	private var exe_ecm:String;
	private var exe_unecm:String;
	
	private var expr_dec = ~/\s*Decoding \((\d{1,3})%/;
	private var expr_enc = ~/\s*Encoding \((\d{1,3})%/;
		
	//---------------------------------------------------;
	
	public function new() 
	{
		super();
		
		audit.linux = { check:true, type:"package",  param:"ecm"};
		audit.win32 = { check:true, type:"folder",   param:win32_ecm };

		if(platform == "linux") {
			exe_ecm   = linux_ecm;
			exe_unecm = linux_unecm;
		}else 
		if(platform == "win32") {
			exe_ecm   = win32_ecm;
			exe_unecm = win32_unecm;
		}
	}//---------------------------------------------------;
	//
	// Will produce to same directory as the input file
	public function ecm(input:String, ?output:String ):Void 
	{		
		if (output != null)
			spawnProc(Path.join(dir_exe, exe_ecm) , [input, output]);
		else
			spawnProc(Path.join(dir_exe, exe_ecm) , [input]);
		
		listen_progress("encode");		
	}//---------------------------------------------------;
	
	// Will ALWAYS un-ECM at the same dir as the file..
	public function unecm(input:String, ?output:String):Void 
	{
		// It will just enecm at same dir for now.
		if (output != null)
			spawnProc(Path.join(dir_exe, exe_unecm) , [input, output]);
		else
			spawnProc(Path.join(dir_exe, exe_unecm) , [input]);
			
		listen_progress("decode");
	}//---------------------------------------------------;
	
	/**
	 * Call this after the process has been created.
	 */
	private function listen_progress(oper:String):Void
	{	
		var expr_per:EReg;
		if (oper == "encode") expr_per = expr_enc; else expr_per = expr_dec;
		proc.stderr.setEncoding("utf8");
		proc.stderr.on("data", function(data:String) {
			if (expr_per.match(data)) {
				events.emit("progress", Std.parseInt(expr_per.matched(1)));
			}	
		});				
	}//---------------------------------------------------;
	
		
}//--end class--