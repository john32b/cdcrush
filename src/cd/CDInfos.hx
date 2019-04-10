/**
 * = CDInfos
 * = Provide CD information and functions, works with `CDCRUSH`
 * 
 * + Describe/Store and Restore a CD cuesheet file
 * + Read a .cue file
 * + Store the read information to a .json file
 * + Read a .json file
 * + Create a .cue file 
 *
 * 
 * + Using haxe.sys, so should be compatible with all haxe targets
 * 
 * HELP :
 *  - http://wiki.hydrogenaud.io/index.php?title=Cue_sheet
 * 
 * NOTES :
 *  ! The last track on single file bin will get a sector size from the start
 *    of the track to the end of the file, ( instead of trimming the extra data )
 * 
 * 
 * FOR C# :
 * + try catch (haxe.lang.HaxeException) on functions and access ().message
 * 
 */

package cd;

import haxe.Json;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import cd.CDTrack.CueTime;

@:keep
@:public // For when exporing to C#
@:nativeGen // don't generate reflection,
class CDInfos 
{
	// CDInfos Ver.
	static var VERSION:Int = 4;

	// Custom LOG function, set externally
	public static var LOG:String->Void = function(s){};
	public static var NEWLINE:String = "\n";	// Can be externally set

	// These are supported when parsing CUE files
	static var SUPPORTED_TRACK_FILES:Array<String> = ["BINARY", "WAVE"];
	
	// --
	public static function getSectorsByDataType(type:String):Int {
		switch(type) {
			case "AUDIO": 		return 2352;	// PCM Audio
			case "CDG" : 		return 2352;	// Karaoke cd+g
			case "MODE1/2048":	return 2048;	// CDROM Mode1 Data (cooked)
			case "MODE1/2352":	return 2352;	// CDROM Mode1 Data (raw)
			case "MODE2/2336":	return 2336;	// CDROM XA Mode2 Data
			case "MODE2/2352":	return 2352;	// CDROM XA Mode2 Data
			case "CDI/2336":	return 2336;	// CDI Mode2 Data
			case "CDI/2352":	return 2352;	// CDI Mode2 Data
			default: throw "Unsuported type " + type;
		}
	}//------------------------------------
	
	// -- These are saved to the JSON
	// --	
	public var CD_TITLE:String;				// The CD TITLE as it is read/written on the CUE
	public var CD_TYPE:String;				// TYPE, (e.g. MODE1/2352 )
	public var CD_AUDIO_QUALITY:String;		// Describe the audio quality in a string. SET EXTERNALLY.
	public var CD_TOTAL_SIZE:Int;			// Size of all tracks of the CD in bytes
	public var SECTOR_SIZE:Int;				// The byte length of a single sector
	public var MULTIFILE:Bool;				// The CD was read from a CUE with multiple files, (every track own file)
	public var tracks:Array<CDTrack>;		// Hold all the CD tracks here

	// -- Helpers used by parser
	var openTrack:CDTrack;	// current track
	var openFile:String;	// current track filename
	
	// == Functions :: ------------------------------------:
	
	public function new() 
	{
		// Init All instance vars
		CD_TITLE = "untitled"; 	CD_TYPE = null;
		CD_AUDIO_QUALITY = null; CD_TOTAL_SIZE = 0;
		SECTOR_SIZE = 0; MULTIFILE = false;
		tracks = [];
		openTrack = null; openFile = null;
	}//---------------------------------------------------;

	/**
	   Load and parse a .CUE FILE
	   @Throws String Errors
	   @param	input
	**/
	public function cueLoad(input:String):Void
	{
		LOG('cueLoad(): Loading `$input`');
		
		if (!FileSystem.exists(input))
		{
			throw 'File $input does not exist.';
		}
		
		var input_dir = Path.directory(input);
		var input_ext = Path.extension(input).toLowerCase();
		
		if (input_ext != "cue")
		{
			throw 'File $input must be a `.CUE` file.';
		}
		
		var fileContent = File.getContent(input);	// Don't need it anymore
		var fileData:Array<String> = fileContent.split("\n");
		
		// -- Auto Guess CD TITLE based on input filename
			// Basically captures the last portion of a path without the extension
			// Like .getFilename(x);
			var rtitle:EReg = ~/([^\/\\]*)\.cue$/i;
			if (rtitle.match(input)) CD_TITLE = rtitle.matched(1);
			LOG('Guessed cd title = $CD_TITLE');
		
		// -- Start Parsing the loaded CUE file
		for (l in 0...fileData.length)
		{
			var line:String = fileData[l];
			if (line.length == 0) continue;
			line = StringTools.trim(line);
			try{
				cue_parser(line);
			}catch (e:String){
				throw 'Cue Parse Error ( Line $l ) : $e';
			}
			
		}// --
		
		// Finished parsing, don't need this anymore:
		openTrack = null;
		
		// -- Post Parse Checks and Inits
		
		if (tracks.length == 0) {
			throw "No tracks in the .Cue file";
		}
		
		// -- Get CD Type and SECTORS
				
		for (t in tracks) if (t.isData) { CD_TYPE = t.trackType; break; }
		if (CD_TYPE == null) CD_TYPE = "AUDIO";
		
		SECTOR_SIZE = getSectorsByDataType(CD_TYPE);
					
		// -- Go through each and every track,
		//	Check TrackFiles and Initialize some Track variables
		//	Also count the number of file images to figure out `multifilecd`

		var cc:Int = 0; // Number of tracks with diskfiles found
		for (t in tracks)
		{
			if (t.indexes.length == 0) {
				throw 'Track ${t.trackNo} has no indexes defined';
			}
			
			if (t.trackFile == null) continue;
			cc++;
			
			// Important for the CDCRUSH operations:
			t.workingFile = Path.join([input_dir, t.trackFile]);
			
			// Check the diskFiles
			if (!FileSystem.exists(t.workingFile)) {
				throw 'TrackFile ${t.trackFile} is defined but does not exist';
			}
		
			// Get sizes
			var finfo = FileSystem.stat(t.workingFile);
			t.byteSize = finfo.size;
			t.sectorSize = Math.ceil(t.byteSize / SECTOR_SIZE);
			
			// Rare but worth checking
			if (t.sectorSize <= 0){
				throw 'TrackFile ${t.trackFile} is corrupted.';
			}
			
			CD_TOTAL_SIZE += t.byteSize;
			
		}// --
			
		// -- Continue Post Parse Checks
		//  - Calculate Tracks sectorSize and sectorStart if missing
		
		if (cc == tracks.length && cc > 1)
		{
			//	Every Track is associated with a file
			LOG("Multi-File CD Image");
			MULTIFILE = true;
			// Note: Track sectorStart is 0 and I need to define it
			initTracks_SectorStart();	// sectorSize IS defined OK
		}
		else if (cc == 1)
		{
			LOG("Single-File CD image");
			MULTIFILE = false;
			// Note: Track sectorSize is 0 and I need to define it
			var imSectorSize = tracks[0].sectorSize;
			var c = tracks.length - 1;
			// Going from the last to the first, calculate starts
			tracks[c].initSectorStartFromIndex();
			tracks[c].sectorSize = imSectorSize - tracks[c].sectorStart;
			while (--c >= 0) {
				tracks[c].initSectorStartFromIndex();
				tracks[c].sectorSize = tracks[c + 1].sectorStart - tracks[c].sectorStart;
			}
			
			initTracks_byteSize();
			
		}
		else if (cc == 0) {
			throw "There are no image files defined in the cuesheet";
		}else {
			throw "Not Supported. Either one track file or all track files";
		}

		LOGINFOS();
		
	}//---------------------------------------------------;
		
	
	// -- Save current CD infos to a CUE file
	//
	public function cueSave(output:String, extraLines:Array<String> = null):Void
	{
		LOG('Saving .cue, $output');
		
		var GAP = "  ";
		
		if (tracks.length == 0) {
			throw "There is no data to save";
		}
		
		var data:String = ""; // Data to be written
		var tr:CDTrack; // Temp
		var i:Int = 0;	// Counter
		
		do
		{
			tr = tracks[i];
			
			// FILE
			if (tr.trackFile != null)
			{
				var fileType:String = switch(Path.extension(tr.trackFile).toLowerCase()){
					case "ogg"  : "OGG";
					case "flac" : "FLAC";
					case "mp3"  : "MP3";
					default : "BINARY";
				}
				
				data += 'FILE "${tr.trackFile}" $fileType\n';
			}
			
			// TRACK
			var _st = StringTools.lpad('${tr.trackNo}', "0", 2);
				data += '${GAP}TRACK $_st ${tr.trackType}\n'; 
		
			// PREGAP
			if (tr.pregap != null) {
				var _sp = tr.pregap.toString();
				data += '${GAP}${GAP}PREGAP $_sp\n';
			}
			
			// INDEX
			for (i in 0...tr.indexes.length){
				var _s0 = StringTools.lpad('${tr.indexes[i].no}', "0", 2);
				var _s1 = tr.indexes[i].toString();
				data += '${GAP}${GAP}INDEX $_s0 $_s1\n';
			}
		
		}while (++i < tracks.length);
		
		
		data += 'REM ------------------------------\n';
		if (CD_AUDIO_QUALITY != null){
			data += 'REM Audio Quality : $CD_AUDIO_QUALITY\n';
		}
		
		if (extraLines != null)
		{
			for (l in extraLines){
				data += 'REM ' + l + '\n';
			}
		}

		File.saveContent(output, data);
	
	}//---------------------------------------------------;
	
	// Load a previously saved CD infos .json
	// --
	public function jsonLoad(input:String):Void
	{
		LOG('jsonLoad(): Loading `$input`');
		
		if (!FileSystem.exists(input))
		{
			throw 'File $input does not exist.';
		}
		
		var obj:Dynamic = Json.parse( File.getContent(input) );
		if (obj == null) throw 'Can\'t parse parameters file';
		
		// --
		// V1,V2 Are old nodeJS versions
		// V3+ is DotNet CdCrush
		var versionLoaded:Int = 1;
		if (Reflect.hasField(obj, "version")) {
			versionLoaded = obj.version;
		}
		
		// Copy
		var TR:Array<Dynamic> = obj.tracks;

		if (versionLoaded == 1) // Convert V1 to V2
		{
			var cdSecSize:Int = obj.sectorSize;
			
			if (TR.length == 1) {
				TR[0].sectorSize = Math.ceil(obj.imageSize / cdSecSize);
			}
			
			for (i in TR){
				i.diskFileSize = i.sectorSize * cdSecSize;
			}
			
			versionLoaded++;
		}
		
		if (versionLoaded == 2) // Convert V2 to V3
		{
			var diskFiles:Int = 0;				// Count tracks with diskfiles set
			var capturedAudio:String = "";		// Is there any audio track? Used to fill the CD_QUALITY
			var dt:String = null;
			for (i in TR){
				i.trackType = i.type;
				i.indexes = i.indexAr;
				i.storedFileName = i.filename;
				i.byteSize = i.diskFileSize;
				i.md5 = "-";
				if (dt == null && i.trackType != "AUDIO") dt = i.trackType; // If any track is data, then this is the CD TYPE
				if (i.diskFile != null) diskFiles++;
				if (capturedAudio == null && i.trackType == "AUDIO") {
					capturedAudio = Path.extension(i.filename); // "ogg","flac"
				}
			}//- for tracks
			
			if (capturedAudio != null)
			{
				if (capturedAudio == "ogg") obj.audio = "Ogg Vorbis ??? k Vbr";
				if (capturedAudio == "flac") obj.audio = "FLAC Lossless";
				
			}else
			{
				obj.audio = null;
			}
			
			obj.totalSize = obj.imageSize;
			obj.multiFile = (diskFiles > 1) && (diskFiles == TR.length);
			obj.cdType = (dt == null) ? "AUDIO" : dt;
			versionLoaded++;
		}
		
		if (versionLoaded == 3) // Convert V3 to V4
		{
			for (i in TR)
			{
				if (i.pregapMinutes > 0 || i.pregapSeconds > 0 || i.pregapMillisecs > 0){
					i.pregap = new CueTime(0, i.pregapMinutes, i.pregapSeconds, i.pregapMillisecs);
				}
				
				// index.millisecs -> index.frames
				var indexes:Array<Dynamic> = i.indexes;
				for (ii in indexes){
					ii.frames = ii.millisecs;
					Reflect.deleteField(ii, "millisecs");
				}
			}
		}
		
		// -- Create Tracks ::
		tracks = [];
		for (i in TR) 
		{
			var t = new CDTrack();
				t.fromJSON(i);
			tracks.push(t);
		}
		
		// -- CD INFOS ::
		CD_TITLE = obj.cdTitle;
		CD_TYPE = obj.cdType;
		CD_TOTAL_SIZE = obj.totalSize;
		CD_AUDIO_QUALITY = obj.audio;
		MULTIFILE = obj.multiFile;
		SECTOR_SIZE = obj.sectorSize;
		
		// -- Some Checks ::
		
		// Old Version ( single file multi track ) that didn't calculate bytesize
		if (tracks[0].byteSize == 0) {
			initTracks_byteSize();
		}
		
		// Old Version that didn't calculate sector start on cueLoad
		if (tracks.length > 1 && tracks[1].sectorStart == 0){
			initTracks_SectorStart();
		}
		
		LOGINFOS();
	}//---------------------------------------------------;
	
	// Save current settings to a .json file
	// Stores everything (cue data + metadata)
	// --
	public function jsonSave(output:String):Void
	{
		if (tracks.length == 0) throw "Warning , No tracks to save";
		
		// Safeguard
		for (i in tracks) {
			if (i.storedFileName == null) throw 'Track ${i.trackNo} should have a filename set.';
		}

		// What will be written on the file
		// --
		var o:Dynamic = {
			version 	: VERSION,
			cdTitle 	: CD_TITLE,
			cdType		: CD_TYPE,
			audio		: CD_AUDIO_QUALITY,
			sectorSize	: SECTOR_SIZE,
			totalSize	: CD_TOTAL_SIZE,
			multiFile	: MULTIFILE,
			tracks		: [for (t in tracks) t.toJSON()]
		};
		
		File.saveContent(output, Json.stringify(o, null, "\t"));
	}//---------------------------------------------------;
	
	//====================================================;
	
	// -- Fills `SectorStart` for all tracks
	// == Used when:
	// - Loading old version JSON
	// - Reading a multi file .CUE
	// PRE: Tracks SectorSize is Set
	function initTracks_SectorStart()
	{
		if (tracks.length == 0) return;
		var last:Int = 0;
		for (i in 0...tracks.length) {
			tracks[i].sectorStart = last;
			last +=  tracks[i].sectorSize;
		}
	}//---------------------------------------------------;
	
	// --Fills `byteSize` for all tracks
	// == Used when:
	// - Loading old version JSON
	// - Reading a single file .CUE
	// PRE: Tracks sectorSize is Set
	function initTracks_byteSize()
	{
		if (tracks.length == 0) return;
		for (t in tracks) {
			t.byteSize = t.sectorSize * SECTOR_SIZE;
		}
	}//---------------------------------------------------;
	
	
	function cue_parser(line:String)
	{
		
		// Get FILE image name
		if ( ~/^FILE/i.match(line) ) 
		{	
			openTrack = null;
			
			/** e.g.
			 * 
			 * NOTE: File brackets are always double brackets (")
			 * split everything to between ",
			 * [0] is "FILE "
			 * [last] is " BINARY"
			 * I want to keep the rest and join them. 
			 */
			var q = ~/"+/g.split(line);
			if (q.length < 3){
				throw "Could not read Track File";
			}
			var type = StringTools.trim(q.pop()).toUpperCase();
			if (SUPPORTED_TRACK_FILES.indexOf(type) < 0){
				throw "Unsupported Track File Type " + type;
			}
			q.shift();
			openFile = q.join("");
			return;
		}//--
		
		// Get Track NO and track TYPE
		// e.g. "TRACK 04 AUDIO"
		var regTrack:EReg = ~/^\s*TRACK\s+(\d+)\s+(\S+)/i;
		if (regTrack.match(line)) 
		{
			openTrack = null; // Close any open Track
			
			// [SAFEGUARD] Check to see if the trackNO is already defined in the tracks
			for (i in tracks) {
				if (i.trackNo == Std.parseInt(regTrack.matched(1))) {
					throw 'Track ${i.trackNo} is already defined';
				}
			}
			var tr = new CDTrack();
			tr.set(Std.parseInt(regTrack.matched(1)), regTrack.matched(2));
			tr.trackFile = openFile; openFile = null;
			openTrack = tr;
			tracks.push(tr);
			return;
		}//--
		
		
		// Get Index
		// e.g. "INDEX 00 11:06:33"
		var regIndex:EReg = ~/^\s*INDEX\s+(\d+)\s+(\d{1,2}):(\d{1,2}):(\d{1,2})/i;
		if (regIndex.match(line)) 
		{
			if (openTrack == null) throw "A Track is not defined yet";
			var indexno = Std.parseInt(regIndex.matched(1));
			if (openTrack.indexExists(indexno)) {
				throw 'Track {$openTrack.trackNo} ' + 
					  ', Duplicate Index entry. Index($indexno)';
			}
			
			openTrack.addIndex( indexno,
								Std.parseInt(regIndex.matched(2)), 
								Std.parseInt(regIndex.matched(3)), 
								Std.parseInt(regIndex.matched(4)) );
			return;
		}//--
		
		// Get PREGAP
		// e.g. "PREGAP 00:00:28"
		var regPregap:EReg = ~/^\s*PREGAP\s+(\d{1,2}):(\d{1,2}):(\d{1,2})/i;
		if (regPregap.match(line)) 
		{
			if (openTrack == null) throw "A Track is not defined yet";
			openTrack.setPregap(
				Std.parseInt(regPregap.matched(1)), 
				Std.parseInt(regPregap.matched(2)), 
				Std.parseInt(regPregap.matched(3))); 
			return;
		}
		
		// Get TITLE
		// Only applicable for CD TITLE, not inside tracks. *rarely used*
		if ( ~/^TITLE/i.match(line) ) 
		{
			if (openTrack != null) return;
			var r:EReg = ~/.+"(.+)"$/i;
			if (r.match(line)) {
				CD_TITLE = r.matched(1);
			}else{
				throw "TITLE error";
			}
		}
		
	}//---------------------------------------------------;

	
	// Return user Friendly CD REPORT
	// --
	public function getDetailedInfo():String
	{
		var d1:String = 
			'Title	:  ${CD_TITLE} $NEWLINE' + 
			'Type	:  ${CD_TYPE} $NEWLINE' + 
			'Audio	:  ${CD_AUDIO_QUALITY} $NEWLINE' + 
			'Tracks	:  ${tracks.length} $NEWLINE' + 
			'-------------------------------------------------- $NEWLINE' + 
			' #  Type       Pregap   Sectors  Size      MD5 $NEWLINE';
			
			var d2:String = "";
			var totalSectors:Int = 0;
			for (t in tracks) {
				totalSectors += t.sectorSize;
				var s = ' ' +
					StringTools.rpad('${t.trackNo}', ' ', 3) +
					StringTools.rpad(t.trackType, ' ', 11) +
					((t.pregap!=null) ?
						StringTools.rpad(t.pregap.toString(), ' ', 9) :
						'00:00:00 '
					) +
					StringTools.rpad('${t.sectorSize}', ' ', 9) +
					StringTools.rpad('${t.byteSize}', ' ', 10) +
					t.md5 + NEWLINE;
					d2 += s;
			}
			d2 += '-------------------------------------------------- $NEWLINE' +
				  'Total Sectors : ${totalSectors} $NEWLINE'+
				  'Total Size    : ${CD_TOTAL_SIZE} $NEWLINE';
				  
			return d1 + d2;
	
	}//---------------------------------------------------;
	
	// --
	// Quick INFO LOG
	#if debug
	function LOGINFOS()
	{
		LOG('cdTitle:$CD_TITLE, cdType:$CD_TYPE , totalSize:$CD_TOTAL_SIZE');
		LOG('multiFile:$MULTIFILE, audio:$CD_AUDIO_QUALITY, tracks:${tracks.length}');
		for (i in tracks) LOG(i.toString_());
		LOG(' ---');
	}//---------------------------------------------------;
	#else
	inline function LOGINFOS() {}
	#end

}//--


