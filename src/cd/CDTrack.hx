package cd;

//
// Describe a Track of a CD
// Basic INFOS + Extra Metadata
// --
@:keep
@:publicFields
@:public // For when exporing to C#
class CDTrack 
{
	var trackNo:Int;					// The Number of the track as it is on the CD
	var trackType(default, set):String;	// Predefined ID of the type (e.g. "mode2/2352")
	var indexes:Array<CueTime>;			// Hold all the indexes described in the Cue file
										// . The array index is the Index No
	var sectorStart:Int;				// At which byte of the CD this track starts
	var sectorSize:Int;					// How many CD sectors this track occupies
	var byteSize:Int;					// Size of the track in bytes
	var pregap:CueTime;					// There can only be ONE pregap per Track. (00:00:00)
	var md5:String;						// The MD5 of the source Binary	
	var storedFileName:String;			// Keep the crushed track filename. (e.g. `Track02.ogg`)

	// JSON_IGNORE vars:
	
	var trackFile:String;				// The FILENAME(nopath) this track is associated with
										// . What is read/written to the .CUE
									
	var isData:Bool;					// Quick lookup for data or not 
	
	var workingFile:String;				// A temporary path, used when this track is being processed
	
	
	// FUNCTIONS :: 
	
	public function new()
	{
		indexes = [];
		pregap = null; // Null for NO pregap
		trackNo = 0;
		trackType = null;
		sectorStart = 0;
		sectorSize = 0;
		byteSize = 0;
		md5 = "";
		storedFileName = null;
		// --
		isData = false;
		workingFile = null;
		trackFile = null;
	}//---------------------------------------------------;
	
	public function set(no:Int, type:String)
	{
		trackNo = no;
		trackType = type;
		CDInfos.getSectorsByDataType(trackType); // Throws error if invalid
	}//---------------------------------------------------;
	
	// --
	function set_trackType(value) {
		trackType = value;
		if (trackType != null){
			isData = (trackType != "AUDIO");
		}
		return trackType;
	}//---------------------------------------------------;
	
	// --
	// Fill the sectorStart var based on the existing index time
	// Used in 
	public function initSectorStartFromIndex()
	{
		sectorStart = indexes[0].toSectors();
	}//---------------------------------------------------;
	// --
	public function addIndex(no:Int, min:Int, sec:Int, ms:Int)
	{
		indexes.push(new CueTime(no, min, sec, ms));
	}//---------------------------------------------------;
	// --
	public function indexExists(indexNo:Int)
	{
		for(i in indexes) if(i.no == indexNo) return true; return false;
	}//---------------------------------------------------;
	//--
	public function setPregap(min:Int, sec:Int, ms:Int)
	{
		pregap = new CueTime(0, min, sec, ms); 
	}//---------------------------------------------------;
	// --
	public function toString()
	{
		return 	' - Track #:$trackNo, type:$trackType, size:$byteSize, CueFile:$trackFile, indexes:${indexes.length}, ' +
				'sectorStart:$sectorStart, sectorSize:$sectorSize, storedFile:$storedFileName, md5:$md5';
	}//---------------------------------------------------;
	
	// --
	// Hacky way to exlcude fields, is to create a new object
	// I could use an external lib for this, but why including a bunch of code
	public function toJSON():Dynamic
	{
		return {
			trackNo:trackNo,
			trackType:trackType,
			sectorStart:sectorStart,
			sectorSize:sectorSize,
			byteSize:byteSize,
			storedFileName:storedFileName,
			md5:md5,
			pregap:pregap,
			indexes:indexes
		};
	}//---------------------------------------------------;
	
	public function fromJSON(o:Dynamic)
	{
		for (f in Reflect.fields(o)) {
			if (Reflect.hasField(this, f)){
				Reflect.setField(this, f, Reflect.field(o, f));
			}
		}
		
		if (o.pregap != null) 
		{
			pregap = new CueTime();
			pregap.fromJSON(o.pregap);
		}
		
		indexes = [];
		var oInd:Array<Dynamic> = o.indexes;
		for (i in oInd)
		{
			var ind = new CueTime();
				ind.fromJSON(i);
				indexes.push(ind);
		}
		
	}//---------------------------------------------------;
	
}// --





// Describe a TIME string read from a .CUE
// Also provides some functionality
// --
@:keep
@:publicFields
@:public // For when exporing to C#
class CueTime
{
	var no:Int;
	var minutes:Int;
	var seconds:Int;
	var millisecs:Int;
	
	// --
	public function new(n:Int = 0, m:Int = 0, s:Int = 0, ms:Int = 0)
	{
		no = n;			// Used in storing Indexes
		minutes = m;
		seconds = s;
		millisecs = ms;
	}//---------------------------------------------------;
	
	// From Sector Length to Time
	// --
	public function fromSectors(secLen:Int):Void
	{
		minutes = Math.floor(secLen / 4500);
		seconds = Math.floor((secLen % 4500) / 75);
		millisecs = (secLen % 4500) % 75;
	}//---------------------------------------------------;
	
	// Convert current index time to sector time
	// --
	public function toSectors():Int
	{
		var sector:Int = minutes * 4500;
			sector += seconds * 75;
			sector += millisecs;
		return sector;
	}//---------------------------------------------------;	
	
	public function toString():String
	{
		return 	StringTools.lpad('$minutes','0',2) + ":" + 
				StringTools.lpad('$seconds','0',2) + ":" +
				StringTools.lpad('$millisecs', '0', 2);
	}//---------------------------------------------------;
	
	public function fromJSON(o:Dynamic)
	{
		for (f in Reflect.fields(o)) {
			Reflect.setField(this, f, Reflect.field(o, f));
		}
	}//---------------------------------------------------;
}//--