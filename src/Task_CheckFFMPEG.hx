package;
import djNode.task.Task;
import djNode.app.FFmpegAudio;

/**
 * Check if FFMPEG is available
 * ...
 */
class Task_CheckFFMPEG extends Task
{
	public function new() 
	{
		name = "-checkffmpeg";
		super();
	}//---------------------------------------------------;
	override public function run() 
	{
		super.run();
		var ffmpeg = new FFmpegAudio();
			ffmpeg.events.once("check", function(st:Bool) {
				if (st)
					complete();
				else
					fail("You need FFMPEG installed and set on the path to use CDCrush.", "user");
			});
		ffmpeg.checkApp();
	}//---------------------------------------------------;
}// --