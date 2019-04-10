package;

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


/**
   CODEC MASTER
   ------------
   
	- Responsible for creating audio/archive encoding strings from user settings
	- Every Audio/Archive codec supports (3) arbitrary quality settings
	
**/

class CodecMaster 
{
	
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
				name:"MP3", ext:".mp3",
				qReal:['9', '6', '1'],
				qName:['65' , '115', '225'], p:'k Vbr',
				encstr:'-c:a libmp3lame -q:a '
				},
				
		"VORBIS" => {
				name:"Vorbis", ext:".ogg",
				qReal:['0', '3', '9'],
				qName:['64', '112', '320'], p:'k Vbr',
				encstr:'-c:a libvorbis -q '
				},
		
		"OPUS" => {
				name:"Opus", ext:".ogg",
				qReal:['48k', '96k', '320k'],
				qName:['48', '96', '320'], p:'k Vbr',
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
	
	
	
	public static function getAudioStr(codecID:String, q:Int):String
	{
		var c = audio.get(codecID);
		if (c.qReal == null) 
			return c.encstr;
		else
			return c.encstr + c.qReal[q];
	}//---------------------------------------------------;
	
	
	public static function getAvailableAudioCodecsID():Array<String>
	{
		var a:Array<String> = [];
		for (k in audio.keys()) a.push(k);
		return a;
	}//---------------------------------------------------;
	
	/**
	   
	   @param	codecID
	   @param	quality 0,1,2 (LOW,MED,HIGH)
	**/
	public static function getAudioQualityInfo(codecID:String, quality:Int):String
	{
		var c = audio.get(codecID);
		
		if (c.qReal.length == 0) // LOSSLESS
		{
			return c.name;
		}
		
		// e.g. "Opus 96k Vbr";
		return c.name + ' ' + c.qName[quality] + c.p;
	}//---------------------------------------------------;
	
}// --