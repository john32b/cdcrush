package;
import app.Archiver;
import app.FreeArc;
import app.SevenZip;

typedef AudioInfo = {
	name:String,
	qReal:Array<String>, // Real quality passed to encoder
	qName:Array<String>, // Name of quality
	encstr:String,		 // Encoding String + qReal = Final Encoding String
	ext:String,
	p:String			// Postfix after quality name
};


typedef ArcInfo = {
	name:String,
	cStr:Array<String>,	// Compression strings Quality low->high
	ext:String
};


// Store either Audio or Archiver Settings
typedef SettingsTuple = {
	id:String,
	q:Int
};


/**
   CODEC MASTER
   ------------
   
	- Responsible for creating audio/archive encoding strings from user settings
	
**/

class CodecMaster 
{
	
	public static var DEFAULT_AUDIO_PARAM = "FLAC";
	public static var DEFAULT_ARCHIVER_PARAM = "ARC:1";
	
	
	// ARCHIVERS
	public static var arc:Map<String,ArcInfo> = [
		"ARC" => {
			name:"FreeArc", ext:".arc",
			cStr:[
				'-s- -m3', 
				'-s- -m4', 
				'-s- -m5x']
		},
		
		"7Z" => {
			name:"7-Zip", ext:".7z",
			cStr:[
				'-t7z -ms=off -mx4',
				'-t7z -ms=off -mx6',
				'-t7z -ms=off -mx7' ]
		},
		
		"ZIP" => {
			name:"Zip", ext:".zip",
			cStr:[
				'-tzip -mx1',
				'-tzip -mx6',
				'-tzip -mx8',
			]
		}
	];
	
	
	// AUDIO CODECS
	public static var audio:Map<String,AudioInfo> = [
	
		"MP3" => {
				// https://trac.ffmpeg.org/wiki/Encode/MP3
				// NO 320CBR because according to the ffmpeg wiki it is wasteful
				// If you need higher quality, consider OPUS320 or FLAC
				name:"MP3", ext:".mp3",
				qReal:['9', '7', '5', '1'],
				qName:['65', '100', '130', '225'], p:'k Vbr',
				encstr:'-c:a libmp3lame -q:a '
				},
				
		"VORBIS" => {
				name:"Vorbis", ext:".ogg",
				qReal:['0', '1.5', '3', '9'],
				qName:['64', '88', '112', '320'], p:'k Vbr',
				encstr:'-c:a libvorbis -q '
				},
		
		"OPUS" => {
				name:"Opus", ext:".ogg",
				qReal:['48k', '64k', '96k', '320k'],
				qName:['48', '64', '96', '320'], p:'k Vbr',
				encstr:'-c:a libopus -vbr on -compression_level 10 -b:a '
			},
			
		"FLAC" => {
				name:"Flac Lossless", ext:".flac",
				qReal:null,
				qName:null, p:'',
				encstr:'-c:a flac'
			},
		
		"TAK" => {
				name:"Tak Lossless", ext:".tak",
				qReal:null,
				qName:null, p:'',
				encstr:''
			},
	];
	
	//---------------------------------------------------;
	
	
	public static function getArchiver(id:String):Archiver
	{
		if (id == "ARC") 
		return new FreeArc(CDCRUSH.TOOLS_PATH) ;
		return new SevenZip(CDCRUSH.TOOLS_PATH);
	}//---------------------------------------------------;
	
	public static function getArchiverByExt(ext:String):Archiver
	{
		for (k => v in arc)
		{
			if (v.ext == ext.toLowerCase())
			{
				return getArchiver(k);
			}
		}
		
		return null;
	}//---------------------------------------------------;
	
	public static function getArcExt(id:String)
	{
		return arc.get(id).ext;
	}//---------------------------------------------------;
	
	public static function getArchiverStr(a:SettingsTuple):String
	{
		return arc.get(a.id).cStr[a.q];
	}//---------------------------------------------------;
	
	public static function getArchiverInfo(a:SettingsTuple):String
	{
		return arc.get(a.id).name + ' ' + ['low', 'medium', 'high'][a.q];
	}//---------------------------------------------------;
	
	/**
	   Return User Readable string from CodecID/Quality Combo
	   @param	codecID
	   @param	quality 0,1,2 (LOW,MED,HIGH)
	**/
	public static function getAudioQualityInfo(a:SettingsTuple):String
	{
		var c = audio.get(a.id);
		if (c.qReal == null) // LOSSLESS
		{
			return c.name;
		}
		// e.g. "Opus 96k Vbr";
		return c.name + ' ' + c.qName[a.q] + c.p;
	}//---------------------------------------------------;
	
	public static function getAudioStr(a:SettingsTuple):String
	{
		var c = audio.get(a.id);
		if (c.qReal == null) 
			return c.encstr;
		else
			return c.encstr + c.qReal[a.q];
	}//---------------------------------------------------;
	
	public static function getAudioExt(id:String):String
	{
		return audio.get(id).ext;
	}//---------------------------------------------------;
	
	public static function getAvailableArchivers():Array<String>
	{
		return [for (k in arc.keys()) k];
	}//---------------------------------------------------;
	
	public static function getAvailableAudioCodecs():Array<String>
	{
		return [for (k in audio.keys()) k];
	}//---------------------------------------------------;
	
	// Checks and Normalizes
	public static function normalizeAudioSettings(s:String):String
	{
		return parseCodecTuple(s, getAvailableAudioCodecs(), 3, 2);
	}//---------------------------------------------------;
	// Checks and Normalizes
	public static function normalizeArchiverSettings(s:String):String
	{
		return parseCodecTuple(s, getAvailableArchivers(), 2, 1);
	}//---------------------------------------------------;
	
	// PRE: Settings are VALID
	public static function getSettingsTuple(s:String):SettingsTuple
	{
		var a = s.split(':');
		return { id:a[0], q:Std.parseInt(a[1])};
	}//---------------------------------------------------;
	
	/**
	   Parses from ID:QUALITY to proper normalized string
	   - Capitalize ID
	   - Null if any Errors
	   - e.g. "mp3:" -> "MP3:2"
	   
	     @param	S	Input String. e.g. "mp3:0" "arc:2"
	     @param	M	ID names of Achiver/Codec ID ['MP3','VORBIS'.....]
	     @param	MAX Maximum number allowed in string
	     @param	DEF Default number to put in string, if ommited
	     @return Normalized/Fixed string 
	**/
	static function parseCodecTuple(S:String, M:Array<String>, MAX:Int, DEF:Int):String
	{
		var a = S.split(':');
		if (a.length > 0){
			var ret = "";
			var p1 = a[0].toUpperCase();
			if (M.indexOf(p1)>-1){
				ret = p1 + ':';
				if (a[1] != null) {
					var t = Std.parseInt(a[1]);
					if (t != null){
						if (t < 0) t = 0; else if (t>MAX) t=MAX;
						return ret + t;
					}
				}
				return ret + '$DEF';
			}
		}
		return null;
	}//---------------------------------------------------;
	
}// --