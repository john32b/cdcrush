(function (console, $global) { "use strict";
var $estr = function() { return js_Boot.__string_rec(this,''); };
function $extend(from, fields) {
	function Inherit() {} Inherit.prototype = from; var proto = new Inherit();
	for (var name in fields) proto[name] = fields[name];
	if( fields.toString !== Object.prototype.toString ) proto.toString = fields.toString;
	return proto;
}
var CDCRunParameters = function() {
};
CDCRunParameters.__name__ = ["CDCRunParameters"];
CDCRunParameters.prototype = {
	__class__: CDCRunParameters
};
var CDC = function() { };
CDC.__name__ = ["CDC"];
CDC.init = function(fileList_,params) {
	CDC.fileList = fileList_;
	CDC.batch_mode = params.mode;
	CDC.batch_tempdir = params.temp;
	CDC.batch_quality = params.quality;
	CDC.batch_outputDir = params.output;
	CDC.simulatedRun = params.sim;
	CDC.queueCurrent = 0;
	CDC.queueTotal = CDC.fileList.length;
	if(CDC.simulatedRun) {
		var _g = CDC.batch_mode;
		switch(_g) {
		case "crush":
			CDC.fileList = ["c:\\Sonic CD [J].cue"];
			CDC.batch_tempdir = "g:\\temp";
			CDC.batch_outputDir = "c:\\";
			CDC.outputDir_Info = ". (Same as source)";
			CDC.batch_quality = 3;
			CDC.queueTotal = 1;
			return;
		case "restore":
			CDC.fileList = ["c:\\Wipeout [JUE].arc"];
			CDC.batch_tempdir = "g:\\temp";
			CDC.batch_outputDir = "c:\\";
			CDC.outputDir_Info = ". (Same as source)";
			CDC.queueTotal = 1;
			return;
		}
	}
	if(CDC.queueTotal == 0) throw new js__$Boot_HaxeError("No files to process");
	if(HxOverrides.indexOf(["crush","restore"],CDC.batch_mode,0) < 0) throw new js__$Boot_HaxeError("Invalid operation mode (" + CDC.batch_mode + ")");
	if(CDC.batch_quality == null) CDC.batch_quality = 2; else if(CDC.batch_quality < 1) CDC.batch_quality = 1; else if(CDC.batch_quality > 4) CDC.batch_quality = 4;
	if(CDC.batch_tempdir != null) {
		CDC.batch_tempdir = js_node_Path.normalize(CDC.batch_tempdir);
		if(!djNode_tools_FileTool.pathExists(CDC.batch_tempdir)) throw new js__$Boot_HaxeError("Temp dir \"" + CDC.batch_tempdir + "\" does not exist.");
	}
	if(CDC.batch_outputDir == null) {
		CDC.batch_outputDir = js_node_Path.dirname(CDC.fileList[0]);
		CDC.outputDir_Info = ". (Same as source)";
	} else {
		CDC.batch_outputDir = js_node_Path.normalize(CDC.batch_outputDir);
		CDC.outputDir_Info = CDC.batch_outputDir + "\\";
	}
	try {
		var testFile = "_cdcrush_test_file_temp";
		if(djNode_tools_FileTool.pathExists(js_node_Path.join(CDC.batch_outputDir,testFile)) == false) js_node_Fs.writeFileSync(js_node_Path.join(CDC.batch_outputDir,testFile),"ok");
		js_node_Fs.unlinkSync(js_node_Path.join(CDC.batch_outputDir,testFile));
	} catch( e ) {
		if (e instanceof js__$Boot_HaxeError) e = e.val;
		if(!djNode_tools_FileTool.pathExists(CDC.batch_outputDir)) throw new js__$Boot_HaxeError("Folder \"" + CDC.batch_outputDir + "\" does not exist."); else throw new js__$Boot_HaxeError("Can't write to output dir \"" + CDC.batch_outputDir + "\" do you have write access?");
	}
	djNode_tools_LOG.log("-- CDC RUN PARAMETERS --",null,{ fileName : "CDC.hx", lineNumber : 232, className : "CDC", methodName : "init"});
	djNode_tools_LOG.log(" mode      = " + CDC.batch_mode,null,{ fileName : "CDC.hx", lineNumber : 233, className : "CDC", methodName : "init"});
	djNode_tools_LOG.log(" quality   = " + CDC.batch_quality,null,{ fileName : "CDC.hx", lineNumber : 234, className : "CDC", methodName : "init"});
	djNode_tools_LOG.log(" outputDir = " + CDC.batch_outputDir,null,{ fileName : "CDC.hx", lineNumber : 235, className : "CDC", methodName : "init"});
	djNode_tools_LOG.log(" tempdir   = " + CDC.batch_tempdir,null,{ fileName : "CDC.hx", lineNumber : 236, className : "CDC", methodName : "init"});
	djNode_tools_LOG.log(" files     = " + Std.string(CDC.fileList),null,{ fileName : "CDC.hx", lineNumber : 237, className : "CDC", methodName : "init"});
	djNode_tools_LOG.log("-------------------------",null,{ fileName : "CDC.hx", lineNumber : 238, className : "CDC", methodName : "init"});
};
CDC.processNextFile = function() {
	var fileToProcess = CDC.fileList.shift();
	if(fileToProcess == null) {
		if(CDC.onComplete != null) CDC.onComplete();
		return;
	}
	var inf = new CDCRunParameters();
	inf.input = js_node_Path.normalize(fileToProcess);
	inf.inputDir = js_node_Path.dirname(fileToProcess);
	inf.tempDir = CDC.batch_tempdir;
	inf.queueTotal = CDC.queueTotal;
	inf.queueCurrent = ++CDC.queueCurrent;
	var job;
	var _g = CDC.batch_mode;
	switch(_g) {
	case "crush":
		job = new Job_$Crush("crush");
		break;
	case "restore":
		job = new Job_$Restore("restore");
		break;
	default:
		throw new js__$Boot_HaxeError("Critical");
	}
	job.sharedData = inf;
	job.onJobStatus = CDC.onJobStatus;
	job.onTaskStatus = CDC.onTaskStatus;
	job.onComplete = CDC.processNextFile;
	job.start();
};
CDC.generateTempFolderName = function(filename) {
	filename = new EReg("\\s","gi").replace(filename,"");
	return "_temp_" + filename + "_" + Std.string(new Date().getTime());
};
CDC.createTempDir = function(par) {
	if(par.tempDir == null) par.tempDir = CDC.batch_outputDir;
	par.tempDir = js_node_Path.join(par.tempDir,CDC.generateTempFolderName(js_node_Path.parse(par.input).name));
	try {
		djNode_tools_LOG.log("Creating temp directory \"" + par.tempDir + "\"",null,{ fileName : "CDC.hx", lineNumber : 303, className : "CDC", methodName : "createTempDir"});
		djNode_tools_FileTool.createRecursiveDir(par.tempDir);
	} catch( e ) {
		if (e instanceof js__$Boot_HaxeError) e = e.val;
		if( js_Boot.__instanceof(e,String) ) {
			return false;
		} else throw(e);
	}
	return true;
};
var EReg = function(r,opt) {
	opt = opt.split("u").join("");
	this.r = new RegExp(r,opt);
};
EReg.__name__ = ["EReg"];
EReg.prototype = {
	match: function(s) {
		if(this.r.global) this.r.lastIndex = 0;
		this.r.m = this.r.exec(s);
		this.r.s = s;
		return this.r.m != null;
	}
	,matched: function(n) {
		if(this.r.m != null && n >= 0 && n < this.r.m.length) return this.r.m[n]; else throw new js__$Boot_HaxeError("EReg::matched");
	}
	,matchedPos: function() {
		if(this.r.m == null) throw new js__$Boot_HaxeError("No string matched");
		return { pos : this.r.m.index, len : this.r.m[0].length};
	}
	,matchSub: function(s,pos,len) {
		if(len == null) len = -1;
		if(this.r.global) {
			this.r.lastIndex = pos;
			this.r.m = this.r.exec(len < 0?s:HxOverrides.substr(s,0,pos + len));
			var b = this.r.m != null;
			if(b) this.r.s = s;
			return b;
		} else {
			var b1 = this.match(len < 0?HxOverrides.substr(s,pos,null):HxOverrides.substr(s,pos,len));
			if(b1) {
				this.r.s = s;
				this.r.m.index += pos;
			}
			return b1;
		}
	}
	,split: function(s) {
		var d = "#__delim__#";
		return s.replace(this.r,d).split(d);
	}
	,replace: function(s,by) {
		return s.replace(this.r,by);
	}
	,map: function(s,f) {
		var offset = 0;
		var buf = new StringBuf();
		do {
			if(offset >= s.length) break; else if(!this.matchSub(s,offset)) {
				buf.add(HxOverrides.substr(s,offset,null));
				break;
			}
			var p = this.matchedPos();
			buf.add(HxOverrides.substr(s,offset,p.pos - offset));
			buf.add(f(this));
			if(p.len == 0) {
				buf.add(HxOverrides.substr(s,p.pos,1));
				offset = p.pos + 1;
			} else offset = p.pos + p.len;
		} while(this.r.global);
		if(!this.r.global && offset > 0 && offset < s.length) buf.add(HxOverrides.substr(s,offset,null));
		return buf.b;
	}
	,__class__: EReg
};
var HxOverrides = function() { };
HxOverrides.__name__ = ["HxOverrides"];
HxOverrides.dateStr = function(date) {
	var m = date.getMonth() + 1;
	var d = date.getDate();
	var h = date.getHours();
	var mi = date.getMinutes();
	var s = date.getSeconds();
	return date.getFullYear() + "-" + (m < 10?"0" + m:"" + m) + "-" + (d < 10?"0" + d:"" + d) + " " + (h < 10?"0" + h:"" + h) + ":" + (mi < 10?"0" + mi:"" + mi) + ":" + (s < 10?"0" + s:"" + s);
};
HxOverrides.cca = function(s,index) {
	var x = s.charCodeAt(index);
	if(x != x) return undefined;
	return x;
};
HxOverrides.substr = function(s,pos,len) {
	if(pos != null && pos != 0 && len != null && len < 0) return "";
	if(len == null) len = s.length;
	if(pos < 0) {
		pos = s.length + pos;
		if(pos < 0) pos = 0;
	} else if(len < 0) len = s.length + len - pos;
	return s.substr(pos,len);
};
HxOverrides.indexOf = function(a,obj,i) {
	var len = a.length;
	if(i < 0) {
		i += len;
		if(i < 0) i = 0;
	}
	while(i < len) {
		if(a[i] === obj) return i;
		i++;
	}
	return -1;
};
var djNode_task_Job = function(name,taskData) {
	this.onTaskStatus = null;
	this.onFail = null;
	this.onComplete = null;
	this.taskData = null;
	if(name == null) name = "GenericJob";
	this.taskData = taskData;
	this.name = name;
	this.currentTask = null;
	this.sharedData = { };
	this.taskQueue = [];
};
djNode_task_Job.__name__ = ["djNode","task","Job"];
djNode_task_Job.prototype = {
	add: function(t) {
		this.taskQueue.push(t);
		return this;
	}
	,addNext: function(t) {
		this.taskQueue.unshift(t);
		return this;
	}
	,start: function() {
		if(this.onJobStatus != null) this.onJobStatus("start",this);
		this.runNext();
	}
	,runNext: function() {
		if(this.taskQueue.length > 0) {
			this.currentTask = this.taskQueue.shift();
			this.currentTask.shared = this.sharedData;
			this.currentTask.dataGet = this.taskData;
			this.currentTask.onStatus = $bind(this,this._onTaskStatus);
			djNode_tools_LOG.log("Starting new Task [" + this.currentTask.name + "], remaining (" + this.taskQueue.length + ")",null,{ fileName : "Job.hx", lineNumber : 126, className : "djNode.task.Job", methodName : "runNext"});
			this.currentTask.run();
		} else {
			djNode_tools_LOG.log("Job [" + this.name + "] Complete",null,{ fileName : "Job.hx", lineNumber : 195, className : "djNode.task.Job", methodName : "_onJobComplete"});
			if(this.onJobStatus != null) this.onJobStatus("complete",this);
			if(this.onComplete != null) this.onComplete();
		}
		return this;
	}
	,kill: function() {
		if(this.currentTask != null) this.currentTask.kill();
		this.currentTask = null;
		this.taskQueue = null;
	}
	,_onTaskStatus: function(status,t) {
		if(this.onTaskStatus != null) this.onTaskStatus(status,t);
		switch(status) {
		case "complete":
			djNode_tools_LOG.log("Task complete [" + t.name + "]",null,{ fileName : "Job.hx", lineNumber : 165, className : "djNode.task.Job", methodName : "_onTaskStatus"});
			this.taskData = t.dataSend;
			t.kill();
			this.runNext();
			break;
		case "fail":
			if(t.important) {
				this.fail_log = t.fail_log;
				this.fail_code = t.fail_code;
				djNode_tools_LOG.log("Task [" + t.name + "] failed.",3,{ fileName : "Job.hx", lineNumber : 174, className : "djNode.task.Job", methodName : "_onTaskStatus"});
				djNode_tools_LOG.log("Reason : " + this.fail_log + " , [" + this.fail_code + "]",3,{ fileName : "Job.hx", lineNumber : 175, className : "djNode.task.Job", methodName : "_onTaskStatus"});
				if(this.onJobStatus != null) this.onJobStatus("fail",this);
				if(this.onFail != null) this.onFail();
				t.kill();
				t = null;
			} else {
				djNode_tools_LOG.log("Task Failed, but it was not important",2,{ fileName : "Job.hx", lineNumber : 181, className : "djNode.task.Job", methodName : "_onTaskStatus"});
				this.taskData = null;
				t.kill();
				t = null;
				this.runNext();
			}
			break;
		}
	}
	,_onJobComplete: function() {
		djNode_tools_LOG.log("Job [" + this.name + "] Complete",null,{ fileName : "Job.hx", lineNumber : 195, className : "djNode.task.Job", methodName : "_onJobComplete"});
		if(this.onJobStatus != null) this.onJobStatus("complete",this);
		if(this.onComplete != null) this.onComplete();
	}
	,__class__: djNode_task_Job
};
var Job_$Crush = function(name,taskData) {
	djNode_task_Job.call(this,name,taskData);
};
Job_$Crush.__name__ = ["Job_Crush"];
Job_$Crush.__super__ = djNode_task_Job;
Job_$Crush.prototype = $extend(djNode_task_Job.prototype,{
	start: function() {
		var _g = this;
		this.par = this.sharedData;
		if(CDC.simulatedRun) {
			this.addQueue_simulate();
			djNode_task_Job.prototype.start.call(this);
			return;
		}
		this.add(new Task_$CheckFFMPEG());
		this.add(new djNode_task_Qtask("-loadingImageInfo",function(t) {
			try {
				_g.par.cd = new djNode_tools_CDInfo(_g.par.input);
			} catch( e ) {
				if (e instanceof js__$Boot_HaxeError) e = e.val;
				if( js_Boot.__instanceof(e,String) ) {
					t._fail(e);
					return;
				} else throw(e);
			}
			if(!CDC.createTempDir(_g.par)) {
				t._fail("Could not create tempdir at \"" + _g.par.tempDir + "\"","IO");
				return;
			}
			_g.par.sizeBefore = _g.par.cd.total_size;
			djNode_tools_LOG.log("Loaded " + _g.par.input,null,{ fileName : "Job_Crush.hx", lineNumber : 64, className : "Job_Crush", methodName : "start"});
			djNode_tools_LOG.log("Image Path = " + _g.par.cd.image_path,null,{ fileName : "Job_Crush.hx", lineNumber : 65, className : "Job_Crush", methodName : "start"});
			djNode_tools_LOG.log("Image Size = " + _g.par.sizeBefore,null,{ fileName : "Job_Crush.hx", lineNumber : 66, className : "Job_Crush", methodName : "start"});
			_g.par.output = js_node_Path.join(CDC.batch_outputDir,_g.par.cd.TITLE + "." + "arc");
			djNode_tools_LOG.log("Setting output file to " + _g.par.output,null,{ fileName : "Job_Crush.hx", lineNumber : 69, className : "Job_Crush", methodName : "start"});
			if(djNode_tools_FileTool.pathExists(_g.par.output)) throw new js__$Boot_HaxeError("" + _g.par.output + " already exists. Delete this manually");
			t._complete();
		}));
		this.add(new Task_$CutTracks());
		this.add(new djNode_task_Qtask("-postCut",function(t1) {
			var c = _g.par.cd.tracks_total;
			while(--c >= 0) _g.addNext(new Task_$CompressTrack(_g.par.cd.tracks[c]));
			t1._complete();
		}));
		this.add(new djNode_task_Qtask("-saveSettings",function(t2) {
			_g.par.cd.self_save(js_node_Path.join(_g.par.tempDir,"crushdata.json"));
			_g.par.cd.self_save(js_node_Path.join(_g.par.inputDir,"crushdata.json"));
			t2._complete();
		}));
		var listOfFilesToCompress;
		this.add(new djNode_task_Qtask("Compressing",function(t3) {
			t3.progress_type = "percent";
			var arc = new djNode_app_Arc();
			arc.events.once("close",function(st) {
				if(st) t3._complete(); else t3._fail(arc.error_log,arc.error_code);
			});
			arc.events.on("progress",function(p) {
				t3.progress_percent = p;
				t3.onStatus("progress",t3);
			});
			listOfFilesToCompress = [];
			listOfFilesToCompress = [js_node_Path.join(_g.par.tempDir,"crushdata.json")];
			var _g1 = 0;
			var _g2 = _g.par.cd.tracks;
			while(_g1 < _g2.length) {
				var i = _g2[_g1];
				++_g1;
				listOfFilesToCompress.push(js_node_Path.join(_g.par.tempDir,i.filename));
			}
			arc.compress(listOfFilesToCompress,_g.par.output);
		}));
		this.add(new djNode_task_Qtask("-cleaning",function(t4) {
			var _g3 = 0;
			while(_g3 < listOfFilesToCompress.length) {
				var i1 = listOfFilesToCompress[_g3];
				++_g3;
				djNode_tools_LOG.log("Deleting \"" + i1 + "\"",null,{ fileName : "Job_Crush.hx", lineNumber : 130, className : "Job_Crush", methodName : "start"});
				js_node_Fs.unlinkSync(i1);
			}
			djNode_tools_LOG.log("Deleting \"" + _g.par.tempDir + "\"",null,{ fileName : "Job_Crush.hx", lineNumber : 133, className : "Job_Crush", methodName : "start"});
			js_node_Fs.rmdirSync(_g.par.tempDir);
			_g.par.sizeAfter = Std["int"](js_node_Fs.statSync(_g.par.output).size);
			t4._complete();
		}));
		djNode_task_Job.prototype.start.call(this);
	}
	,addQueue_simulate: function() {
		var gamename = js_node_Path.parse(js_node_Path.basename(this.par.input)).name;
		var gamedir = js_node_Path.dirname(this.par.input);
		this.par.sizeBefore = 512000000;
		this.par.sizeAfter = 32000134;
		this.par.imagePath = gamedir + gamename + ".bin";
		this.par.cuePath = gamedir + gamename + ".cue";
		this.par.output = gamedir + gamename + ".arc";
		this.par.cd = new djNode_tools_CDInfo();
		this.par.cd.tracks_total = 7;
		this.add(new djNode_task_FakeTask("Spliting","steps",0.2));
		this.add(new djNode_task_FakeTask("Compressing track 1","progress",0.3));
		this.add(new djNode_task_FakeTask("Compressing track 2","progress",0.3));
		this.add(new djNode_task_FakeTask("Compressing track 3","progress",0.3));
		this.add(new djNode_task_FakeTask("Compressing","progress",1));
	}
	,__class__: Job_$Crush
});
var Job_$Restore = function(name,taskData) {
	djNode_task_Job.call(this,name,taskData);
};
Job_$Restore.__name__ = ["Job_Restore"];
Job_$Restore.__super__ = djNode_task_Job;
Job_$Restore.prototype = $extend(djNode_task_Job.prototype,{
	start: function() {
		var _g = this;
		this.par = this.sharedData;
		if(CDC.simulatedRun) {
			this.addQueue_simulate();
			djNode_task_Job.prototype.start.call(this);
			return;
		}
		this.add(new Task_$CheckFFMPEG());
		this.add(new djNode_task_Qtask("-prerun",function(t) {
			if(!djNode_tools_FileTool.pathExists(_g.par.input)) {
				t._fail("File \"" + _g.par.input + "\" does not exist");
				return;
			}
			if(djNode_tools_FileTool.getFileExt(_g.par.input) != "arc") {
				t._fail("Input file is NOT a [." + "arc" + "] file","user");
				return;
			}
			if(!CDC.createTempDir(_g.par)) {
				t._fail("Could not create tempdir at \"" + _g.par.tempDir + "\"","IO");
				return;
			}
			_g.par.sizeBefore = Std["int"](js_node_Fs.statSync(_g.par.input).size);
			t._dataSend({ input : _g.par.input, output : _g.par.tempDir});
			t._complete();
		}));
		this.add(new djNode_task_Task_$ExtractFile());
		this.add(new djNode_task_Qtask("-loadcdinfo",function(t1) {
			_g.par.cd = new djNode_tools_CDInfo();
			try {
				_g.par.cd.loadSettingsFile(js_node_Path.join(_g.par.tempDir,"crushdata.json"));
			} catch( e ) {
				if (e instanceof js__$Boot_HaxeError) e = e.val;
				if( js_Boot.__instanceof(e,String) ) {
					t1._fail(e,"corrupt");
				} else throw(e);
			}
			_g.par.imagePath = js_node_Path.join(CDC.batch_outputDir,_g.par.cd.TITLE + ".bin");
			_g.par.cuePath = js_node_Path.join(CDC.batch_outputDir,_g.par.cd.TITLE + ".cue");
			var c = _g.par.cd.tracks_total;
			while(--c >= 0) _g.addNext(new Task_$RestoreTrack(_g.par.cd.tracks[c]));
			t1._complete();
		}));
		this.add(new djNode_task_Qtask("-loadcdinfo",function(t2) {
			if(_g.par.cd.isMultiImage) _g.addNext(new Task_$MoveFiles()); else _g.addNext(new Task_$JoinTracks());
			t2._complete();
		}));
		this.add(new djNode_task_Qtask("-finalize",function(t3) {
			_g.par.sizeAfter = _g.par.cd.total_size;
			djNode_tools_LOG.log("Creating CUE at " + _g.par.cuePath,null,{ fileName : "Job_Restore.hx", lineNumber : 131, className : "Job_Restore", methodName : "start"});
			_g.par.cd.saveAs_Cue(_g.par.cuePath,"GENERATED BY CDCRUSH " + "1.1");
			djNode_tools_LOG.log("Clearing temp dir",null,{ fileName : "Job_Restore.hx", lineNumber : 134, className : "Job_Restore", methodName : "start"});
			js_node_Fs.unlinkSync(js_node_Path.join(_g.par.tempDir,"crushdata.json"));
			var _g1 = 0;
			var _g2 = _g.par.cd.tracks;
			while(_g1 < _g2.length) {
				var i = _g2[_g1];
				++_g1;
				try {
					js_node_Fs.unlinkSync(js_node_Path.join(_g.par.tempDir,i.filename));
				} catch( e1 ) {
					if (e1 instanceof js__$Boot_HaxeError) e1 = e1.val;
				}
			}
			js_node_Fs.rmdirSync(_g.par.tempDir);
			t3._complete();
		}));
		djNode_task_Job.prototype.start.call(this);
	}
	,addQueue_simulate: function() {
		var gamename = js_node_Path.parse(js_node_Path.basename(this.par.input)).name;
		var gamedir = js_node_Path.dirname(this.par.input);
		this.par.sizeBefore = 32000134;
		this.par.sizeAfter = 512000000;
		this.par.imagePath = gamedir + gamename + ".bin";
		this.par.cuePath = gamedir + gamename + ".cue";
		this.add(new djNode_task_FakeTask("Extracting","progress",0.5));
		this.add(new djNode_task_FakeTask("Restoring track 1","progress",0.3));
		this.add(new djNode_task_FakeTask("Restoring track 2","progress",0.3));
		this.add(new djNode_task_FakeTask("Restoring track 3","progress",0.3));
		this.add(new djNode_task_FakeTask("Joining Tracks","steps",0.1));
	}
	,__class__: Job_$Restore
});
var djNode_BaseApp = function() {
	this.info_author = "";
	this.info_program_desc = "";
	this.info_program_version = "0.0";
	this.info_program_name = "UnnamedApp";
	this.help_text_output = null;
	this.help_text_input = null;
	this.support_multiple_inputs = false;
	this.require_input_rule = "no";
	this.require_output_rule = "no";
	this.flag_param_require_action = false;
	this._number_of_options = 0;
	this._number_of_actions = 0;
	this.params_Output = null;
	this.params_Action = null;
	this.flag_params_Input_discovered = false;
	var _g = this;
	djNode_tools_LOG.init();
	djNode_BaseApp.global_terminal = new djNode_Terminal();
	this.t = djNode_BaseApp.global_terminal;
	this.executable_name = js_node_Path.basename(process.argv[1]);
	this.params_Options = new haxe_ds_StringMap();
	this.params_Input = [];
	this.params_Accept = new haxe_ds_StringMap();
	this.params_autoActionExt = [];
	process.once("exit",$bind(this,this.onExit));
	process.once("SIGINT",function() {
		_g.flag_force_exit = true;
		process.exit(1);
	});
	process.once("uncaughtException",function(err) {
		djNode_tools_LOG.log("Critical Error",4,{ fileName : "BaseApp.hx", lineNumber : 151, className : "djNode.BaseApp", methodName : "new"});
		djNode_tools_LOG.logObj(err,4,{ fileName : "BaseApp.hx", lineNumber : 152, className : "djNode.BaseApp", methodName : "new"});
		_g.criticalError(err.message);
	});
	this.init();
	djNode_tools_LOG.log("Creating Application [ " + this.info_program_name + " ,v" + this.info_program_version + " ]",null,{ fileName : "BaseApp.hx", lineNumber : 158, className : "djNode.BaseApp", methodName : "new"});
	this.create();
};
djNode_BaseApp.__name__ = ["djNode","BaseApp"];
djNode_BaseApp.prototype = {
	create: function() {
	}
	,init: function() {
		djNode_tools_LOG.log("Initializing BaseApp",null,{ fileName : "BaseApp.hx", lineNumber : 180, className : "djNode.BaseApp", methodName : "init"});
		this.addParam("-help","Display Usage info","This screen",false,false);
		this.addParam("-o","output","Set the output for the app",true);
		if(this.help_text_input != null) this.help_text_input = "\t " + new EReg("(\n)","g").replace(this.help_text_input,"\n\t ");
		if(this.help_text_output != null) this.help_text_output = "\t " + new EReg("(\n)","g").replace(this.help_text_output,"\n\t ");
		try {
			this.getParameters();
		} catch( e ) {
			if (e instanceof js__$Boot_HaxeError) e = e.val;
			if( js_Boot.__instanceof(e,String) ) {
				if(e == "HELP") {
					this.showUsage();
					process.exit(1);
				}
				this.printBanner(true);
				this.criticalError(e,true);
			} else throw(e);
		}
	}
	,addParam: function(command,name,description,requireValue,isDefault) {
		var reg = new EReg("([\\s\r\n])","g");
		if(reg.match(command)) throw new js__$Boot_HaxeError("Command string must contain no whitespace or new line char");
		var p = new djNode_AcceptedArgument();
		if(HxOverrides.substr(command,0,1) == "-") {
			p.type = "option";
			this._number_of_options++;
			p.requireValue = requireValue == true;
		} else {
			p.type = "action";
			this._number_of_actions++;
			p.requireValue = false;
		}
		p.command = command;
		p.name = name;
		if(description != null) p.description = description; else p.description = "...";
		p.description = new EReg("#nl","g").replace(p.description,"\n\t");
		p.isdefault = isDefault == true;
		this.params_Accept.set(command,p);
	}
	,getOptionParameter: function(opt) {
		if(this.params_Options.exists(opt)) return this.params_Options.get(opt).parameter; else return null;
	}
	,setActionByFileExt: function(action,fileExtensions) {
		var str = action;
		var _g = 0;
		while(_g < fileExtensions.length) {
			var i = fileExtensions[_g];
			++_g;
			str += "," + i.toLowerCase();
		}
		this.params_autoActionExt.push(str);
	}
	,getParameters: function() {
		djNode_tools_LOG.log("Getting Parameters",1,{ fileName : "BaseApp.hx", lineNumber : 283, className : "djNode.BaseApp", methodName : "getParameters"});
		var cc = 2;
		var arg = process.argv[cc];
		while(arg != null) {
			if(this.params_Accept.exists(arg)) {
				if(arg == "-help") throw new js__$Boot_HaxeError("HELP");
				var par = this.params_Accept.get(arg);
				if(par.type == "action") this.params_Action = par.command; else {
					if(par.requireValue) {
						var nextArg = process.argv[++cc];
						if(nextArg == null || this.params_Accept.exists(nextArg)) throw new js__$Boot_HaxeError("Argument " + arg + " requires a parameter");
						par.parameter = nextArg;
					}
					if(this.params_Options.exists(arg)) this.params_Options.remove(arg);
					this.params_Options.set(par.command,par);
				}
			} else if(HxOverrides.substr(arg,0,1) == "-") {
				if(arg.toLowerCase().indexOf("-help") == 0) throw new js__$Boot_HaxeError("HELP");
				throw new js__$Boot_HaxeError("Illegal argument [" + arg + "]");
			} else this.params_Input.push(arg);
			arg = process.argv[++cc];
		}
		if(this.params_Options.exists("-o")) {
			this.params_Output = this.params_Options.get("-o").parameter;
			this.params_Options.remove("-o");
		}
		var $it0 = this.params_Accept.iterator();
		while( $it0.hasNext() ) {
			var i = $it0.next();
			if(i.isdefault == true) {
				if(i.type == "action") {
					if(this.params_Action == null) this.params_Action = i.command;
				}
				if(i.type == "option") {
					if(this.params_Options.exists(i.command) == false) this.params_Options.set(i.command,i);
				}
			}
		}
		if(this.params_Input.length > 0) {
			if(this.params_Input[0].indexOf("*") >= 0) {
				var temp = this.params_Input[0];
				this.params_Input = djNode_tools_FileTool.getFileListFromAsterisk(this.params_Input[0]);
				if(this.params_Input.length == 0) throw new js__$Boot_HaxeError("Input '" + temp + "' returned 0 files.");
				this.flag_params_Input_discovered = true;
			}
		}
		if(this.params_Action == null && this.params_Input[0] != null) {
			var _ext;
			var _this = js_node_Path.extname(this.params_Input[0].toLowerCase());
			_ext = HxOverrides.substr(_this,1,null);
			var _g = 0;
			var _g1 = this.params_autoActionExt;
			while(_g < _g1.length) {
				var i1 = _g1[_g];
				++_g;
				var str = i1.split(",");
				var _c = 0;
				while(++_c < str.length) if(str[_c] == _ext) this.params_Action = str[0];
			}
		}
		if(this.params_Action == null && this.flag_param_require_action == true) throw new js__$Boot_HaxeError("Setting an action is required");
		if(this.require_output_rule == "yes" && this.params_Output == null) throw new js__$Boot_HaxeError("Output is required");
		if(HxOverrides.indexOf(["yes","multi"],this.require_input_rule,0) >= 0 && this.params_Input.length == 0) throw new js__$Boot_HaxeError("Input is required");
	}
	,showUsage: function() {
		var _g = this;
		var __printUsageParameter = function(par) {
			if(par.command == "-o") return;
			_g.t.fg("white").print(" " + par.command + "\t");
			((function($this) {
				var $r;
				process.stdout.write(par.name);
				$r = _g.t;
				return $r;
			}(this))).reset();
			if(par.isdefault) _g.t.fg("yellow").print(" [default]");
			if(par.requireValue) _g.t.fg("gray").print(" [requires parameter] ");
			_g.t.fg("darkgray").print("\n\t" + par.description + "\n").reset();
		};
		var __getInfoTextFromRule = function(rule) {
			if(rule == "yes") return "is required.";
			return "is optional.";
		};
		if(this.params_Accept.exists("-o")) {
			this.params_Accept.remove("-o");
			this._number_of_options--;
		}
		var _r1 = null;
		var _r2 = null;
		this.printBanner(true);
		var s = "\t " + this.executable_name + " ";
		if(this._number_of_actions > 0) s += "<action> ";
		if(this._number_of_options > 1) s += "<opt> <opt.parameter> ... <opt N>\n\t\t";
		if(HxOverrides.indexOf(["yes","opt","multi"],this.require_input_rule,0) >= 0) {
			_r1 = true;
			if(this.support_multiple_inputs) s += "<input> .. <input N> "; else s += "<input> ";
		}
		if(HxOverrides.indexOf(["yes","opt"],this.require_output_rule,0) >= 0) {
			s += "-o <output> ";
			_r2 = true;
		}
		this.t.printf(" ~green~Program Usage:~!~\n");
		((function($this) {
			var $r;
			process.stdout.write(s);
			$r = $this.t;
			return $r;
		}(this))).endl().printf(" ~darkgray~~line2~");
		if(_r1) {
			this.t.printf("~yellow~ <input> ~!~");
			this.t.print(__getInfoTextFromRule(this.require_input_rule)).reset();
			if(this.help_text_input != null) ((function($this) {
				var $r;
				process.stdout.write("\n");
				$r = $this.t;
				return $r;
			}(this))).printf(this.help_text_input);
			process.stdout.write("\n");
			this.t;
		}
		if(_r2) {
			this.t.printf("~yellow~ <output> ~!~");
			this.t.print(__getInfoTextFromRule(this.require_output_rule)).reset();
			if(this.help_text_output != null) ((function($this) {
				var $r;
				process.stdout.write("\n");
				$r = $this.t;
				return $r;
			}(this))).printf(this.help_text_output);
			process.stdout.write("\n");
			this.t;
		}
		this.t.printf(" ~darkgray~~line2~");
		if(this._number_of_actions > 0) {
			this.t.printf(" ~magenta~<actions> ~!fg~");
			this.t.printf("~darkmagenta~you can set one action at a time ~!~\n");
			var $it0 = this.params_Accept.iterator();
			while( $it0.hasNext() ) {
				var i = $it0.next();
				if(i.type == "action") __printUsageParameter(i);
			}
		}
		if(this._number_of_options > 1) {
			this.t.printf(" ~cyan~<options> ~!fg~");
			this.t.printf("~darkcyan~you can set many options~!~\n");
			var $it1 = this.params_Accept.iterator();
			while( $it1.hasNext() ) {
				var i1 = $it1.next();
				if(i1.type == "option") __printUsageParameter(i1);
			}
		}
		this.useExample();
	}
	,useExample: function() {
	}
	,printBanner: function(longer) {
		if(longer == null) longer = false;
		var col = "white";
		var lineCol = "darkgray";
		var titletext = "" + this.info_program_name + " v" + this.info_program_version;
		process.stdout.write("\n");
		this.t;
		this.t.printf("== ~" + col + "~" + titletext + "~!~\n");
		if(longer && this.info_program_desc != "") this.t.printf(" - " + this.info_program_desc + "\n");
		if(longer && this.info_author != "") this.t.printf(" - " + this.info_author + "\n");
		this.t.printf(" ~" + lineCol + "~~line~~!~");
	}
	,_logProgress_start: function(str) {
		((function($this) {
			var $r;
			process.stdout.write("\x1B[0m");
			$r = $this.t;
			return $r;
		}(this))).fg("white").print(str).savePos();
		this.t.fg("yellow");
	}
	,_logProgress_update: function(str) {
		((function($this) {
			var $r;
			process.stdout.write("\x1B[u");
			$r = $this.t;
			return $r;
		}(this))).clearLine(0).print("" + Std.string(str));
	}
	,_logProgress_end: function(success,customMessage) {
		((function($this) {
			var $r;
			process.stdout.write("\x1B[u");
			$r = $this.t;
			return $r;
		}(this))).clearLine(0);
		if(success) {
			this.t.fg("green");
			if(customMessage == null) customMessage = "[complete]";
		} else {
			this.t.fg("red");
			if(customMessage == null) customMessage = "[fail]";
		}
		((function($this) {
			var $r;
			process.stdout.write(customMessage);
			$r = $this.t;
			return $r;
		}(this))).endl().reset();
	}
	,log: function(msg,pos) {
		djNode_tools_LOG.log(msg,1,pos);
		process.stdout.write(" - " + msg + "\n");
		this.t;
	}
	,criticalError: function(text,showHelp) {
		if(showHelp == null) showHelp = false;
		this.t.printf("~bg_darkred~~white~ ERROR ~!~ ~red~" + text + "\n");
		if(showHelp) this.t.printf("~darkgray~ ~line2~~yellow~ -help ~!~ for usage info\n");
		this.flag_critical_exit = true;
		process.exit(1);
	}
	,WaitKeyQuit: function() {
		var key;
		this.t.fg("darkgray").endl().println("Press any key to quit.");
		process.stdout.write("\x1B[0m");
		this.t;
		key = new djNode_Keyboard(function(e) {
			process.exit(0);
		});
		key.start();
	}
	,onExit: function() {
		if(this.flag_force_exit) djNode_tools_LOG.log("App Quit - User Quit",null,{ fileName : "BaseApp.hx", lineNumber : 593, className : "djNode.BaseApp", methodName : "onExit"}); else djNode_tools_LOG.log("App Quit -  Normally",null,{ fileName : "BaseApp.hx", lineNumber : 595, className : "djNode.BaseApp", methodName : "onExit"});
		djNode_tools_LOG.end();
		process.stdout.write("\x1B[0m");
		this.t;
	}
	,__class__: djNode_BaseApp
};
var Main = function() {
	djNode_BaseApp.call(this);
};
Main.__name__ = ["Main"];
Main.main = function() {
	djNode_tools_LOG.flag_socket_log = false;
	djNode_tools_LOG.logFile = "_log.txt";
	new Main();
};
Main.__super__ = djNode_BaseApp;
Main.prototype = $extend(djNode_BaseApp.prototype,{
	init: function() {
		this.info_program_name = "CD Crush";
		this.info_program_version = "1.1";
		this.info_program_desc = "Dramatically reduce the filesize of CD image games";
		this.info_author = "JohnDimi, twitter@jondmt";
		this.require_input_rule = "yes";
		this.require_output_rule = "opt";
		this.support_multiple_inputs = true;
		this.addParam("c","Crush","Crush a cd image file (.cue .ccd files)");
		this.addParam("r","Restore","Restore a crushed image (.arc files)");
		this.addParam("-t","Temp Directory","Set a custom working directory",true);
		this.addParam("-q","Audio compression quality","1 - " + CDC.audioQualityInfo[0] + "#nl" + ("2 - " + CDC.audioQualityInfo[1] + "#nl") + ("3 - " + CDC.audioQualityInfo[2] + "#nl") + ("4 - " + CDC.audioQualityInfo[3]),true);
		this.addParam("-sim","Simulate run","Debugging purposes");
		this.setActionByFileExt("c",["cue","ccd"]);
		this.setActionByFileExt("r",["arc"]);
		this.help_text_input = "~darkgray~Action is determined by input file extension.\nSupports multiple inputs and wildcards (*.cue)";
		this.help_text_output = "~darkgray~Specify output directory.";
		djNode_BaseApp.prototype.init.call(this);
	}
	,create: function() {
		this.info = new djNode_term_info_ActionInfo();
		this.printBanner();
		var _g = this.params_Action;
		switch(_g) {
		case "c":
			this.action = "crush";
			break;
		case "r":
			this.action = "restore";
			break;
		default:
			this.criticalError("Invalid input",true);
			return;
		}
		if(this.params_Input.length > 1) {
			this.info.printPair("Number of input files",this.params_Input.length);
			this.t.printf(" ~darkgray~~line~");
		}
		CDC.onJobStatus = $bind(this,this.processJobStatus);
		CDC.onTaskStatus = $bind(this,this.processTaskStatus);
		CDC.init(this.params_Input,{ mode : this.action, temp : this.getOptionParameter("-t"), sim : this.params_Options.exists("-sim"), quality : this.getOptionParameter("-q"), output : this.params_Output});
		CDC.processNextFile();
	}
	,processJobStatus: function(status,job) {
		var inf = job.sharedData;
		switch(status) {
		case "start":
			var remain = "";
			if(inf.queueTotal > 1) remain = "~darkgray~[" + inf.queueCurrent + " of " + inf.queueTotal + "]";
			if(CDC.batch_mode == "restore") {
				this.t.printf(" + ~cyan~Restoring~white~ : " + inf.input + " " + remain + " \n~!~");
				this.info.printPair("Destination",CDC.outputDir_Info);
			} else {
				this.t.printf(" + ~cyan~Crushing~white~  : " + inf.input + " " + remain + " \n~!~");
				this.info.printPair("Audio Quality",CDC.audioQualityInfo[CDC.batch_quality - 1]);
				this.info.printPair("Destination",CDC.outputDir_Info);
			}
			process.stdout.write("\n");
			this.t;
			break;
		case "complete":
			this.info.deletePrevLine();
			var s0 = djNode_tools_StrTool.bytesToMBStr(inf.sizeBefore) + "MB";
			var s1 = djNode_tools_StrTool.bytesToMBStr(inf.sizeAfter) + "MB";
			if(CDC.batch_mode == "restore") {
				this.info.deletePrevLine();
				this.info.printPair("Created",inf.cuePath + " + .bins");
				this.info.printPair("Crushed size",s0);
				this.info.printPair("Restored Image size",s1);
			} else {
				this.info.deletePrevLine();
				this.info.printPair("Created",inf.output);
				this.info.printPair("Number of tracks",inf.cd.tracks_total);
				this.info.printPair("Image size",s0);
				this.info.printPair("Crushed size",s1);
			}
			this.t.printf("~green~ Complete!\n~darkgray~ ~line2~~!~");
			break;
		case "fail":
			this.info.reset();
			this.t.printf(" ~red~ERROR : " + job.fail_log + "~!~\n");
			this.t.printLine();
			CDC.processNextFile();
			return;
		}
	}
	,processTaskStatus: function(status,task) {
		if(HxOverrides.substr(task.name,0,1) == "-") return;
		this.info.genericProgress(status,task,true);
	}
	,__class__: Main
});
Math.__name__ = ["Math"];
var Reflect = function() { };
Reflect.__name__ = ["Reflect"];
Reflect.setField = function(o,field,value) {
	o[field] = value;
};
Reflect.getProperty = function(o,field) {
	var tmp;
	if(o == null) return null; else if(o.__properties__ && (tmp = o.__properties__["get_" + field])) return o[tmp](); else return o[field];
};
Reflect.fields = function(o) {
	var a = [];
	if(o != null) {
		var hasOwnProperty = Object.prototype.hasOwnProperty;
		for( var f in o ) {
		if(f != "__id__" && f != "hx__closures__" && hasOwnProperty.call(o,f)) a.push(f);
		}
	}
	return a;
};
var Std = function() { };
Std.__name__ = ["Std"];
Std.string = function(s) {
	return js_Boot.__string_rec(s,"");
};
Std["int"] = function(x) {
	return x | 0;
};
Std.parseInt = function(x) {
	var v = parseInt(x,10);
	if(v == 0 && (HxOverrides.cca(x,1) == 120 || HxOverrides.cca(x,1) == 88)) v = parseInt(x);
	if(isNaN(v)) return null;
	return v;
};
var StringBuf = function() {
	this.b = "";
};
StringBuf.__name__ = ["StringBuf"];
StringBuf.prototype = {
	add: function(x) {
		this.b += Std.string(x);
	}
	,__class__: StringBuf
};
var StringTools = function() { };
StringTools.__name__ = ["StringTools"];
StringTools.lpad = function(s,c,l) {
	if(c.length <= 0) return s;
	while(s.length < l) s = c + s;
	return s;
};
StringTools.rpad = function(s,c,l) {
	if(c.length <= 0) return s;
	while(s.length < l) s = s + c;
	return s;
};
var djNode_task_Task = function() {
	this.onStatus = null;
	this.onComplete = null;
	this.dataGet = null;
	this.dataSend = null;
	this.custom = null;
	this.important = true;
	this.flag_reports_status = true;
	this.UID = ++djNode_task_Task.UID_;
	if(this.name == null) {
		var reg = new EReg("\\.*(\\w+)$","");
		if(reg.match(Type.getClassName(js_Boot.getClass(this)))) this.name = reg.matched(1); else this.name = "GenericTask";
	}
	djNode_tools_LOG.log("Task created, name = " + this.name + ", UID = " + this.UID,null,{ fileName : "Task.hx", lineNumber : 114, className : "djNode.task.Task", methodName : "new"});
	this.status = "waiting";
	this.progress_percent = 0;
	this.progress_steps_current = 0;
	this.progress_steps_total = 0;
	this.progress_type = "none";
};
djNode_task_Task.__name__ = ["djNode","task","Task"];
djNode_task_Task.prototype = {
	run: function() {
		this.status = "running";
		this.onStatus("start",this);
		this.onStatus("progress",this);
	}
	,fail: function(why,code) {
		this.status = "failed";
		this.fail_log = why;
		this.fail_code = code;
		this.onStatus("fail",this);
	}
	,complete: function() {
		this.progress_percent = 100;
		this.progress_steps_current = this.progress_steps_total;
		this.status = "complete";
		this.onStatus("progress",this);
		this.onStatus("complete",this);
		if(this.onComplete != null) this.onComplete();
	}
	,kill: function() {
	}
	,__class__: djNode_task_Task
};
var Task_$CheckFFMPEG = function() {
	this.name = "-checkffmpeg";
	djNode_task_Task.call(this);
};
Task_$CheckFFMPEG.__name__ = ["Task_CheckFFMPEG"];
Task_$CheckFFMPEG.__super__ = djNode_task_Task;
Task_$CheckFFMPEG.prototype = $extend(djNode_task_Task.prototype,{
	run: function() {
		var _g = this;
		djNode_task_Task.prototype.run.call(this);
		var ffmpeg = new djNode_app_FFmpegAudio();
		ffmpeg.events.once("check",function(st) {
			if(st) _g.complete(); else _g.fail("You need FFMPEG installed and set on the path to use CDCrush.","user");
		});
		ffmpeg.checkApp();
	}
	,__class__: Task_$CheckFFMPEG
});
var Task_$CompressTrack = function(tr) {
	this.multiTrack = false;
	this.flag_delete_old = true;
	this.name = "Compressing track " + tr.trackNo;
	djNode_task_Task.call(this);
	this.progress_type = "percent";
	this.track = tr;
};
Task_$CompressTrack.__name__ = ["Task_CompressTrack"];
Task_$CompressTrack.__super__ = djNode_task_Task;
Task_$CompressTrack.prototype = $extend(djNode_task_Task.prototype,{
	run: function() {
		djNode_task_Task.prototype.run.call(this);
		this.multiTrack = this.shared.cd.isMultiImage;
		this.track.filename = this.track.getTrackName();
		if(this.track.isData) this.track.filename += ".bin.ecm"; else if(CDC.batch_quality < 4) this.track.filename += ".ogg"; else this.track.filename += ".flac";
		if(this.multiTrack) this.trackRawPath = js_node_Path.join(this.shared.inputDir,this.track.diskFile); else this.trackRawPath = js_node_Path.join(this.shared.tempDir,this.track.getFilenameRaw());
		djNode_tools_LOG.log("Compressing track " + this.trackRawPath + " to " + this.track.filename,null,{ fileName : "Task_CompressTrack.hx", lineNumber : 72, className : "Task_CompressTrack", methodName : "run"});
		this.trackGenPath = js_node_Path.join(this.shared.tempDir,this.track.filename);
		if(!this.track.isData) {
			var ffmpeg = new djNode_app_FFmpegAudio();
			this.addListeners(ffmpeg);
			ffmpeg.compressPCM(this.trackRawPath,CDC.batch_quality,this.trackGenPath);
		} else {
			var ecm = new djNode_app_EcmTools();
			this.addListeners(ecm);
			ecm.ecm(this.trackRawPath,this.trackGenPath);
		}
	}
	,postCompress: function() {
		if(this.flag_delete_old && !this.multiTrack) try {
			djNode_tools_LOG.log("Deleting " + this.trackRawPath,null,{ fileName : "Task_CompressTrack.hx", lineNumber : 98, className : "Task_CompressTrack", methodName : "postCompress"});
			js_node_Fs.unlinkSync(this.trackRawPath);
		} catch( e ) {
			if (e instanceof js__$Boot_HaxeError) e = e.val;
			djNode_tools_LOG.log("Unable to delete.",2,{ fileName : "Task_CompressTrack.hx", lineNumber : 101, className : "Task_CompressTrack", methodName : "postCompress"});
		}
		this.complete();
	}
	,addListeners: function(proc) {
		var _g = this;
		proc.events.once("close",function(st) {
			if(st) _g.postCompress(); else _g.fail("Can't compress \"" + _g.trackRawPath + "\", Check write access or free space!","IO");
		});
		proc.events.on("progress",function(p) {
			_g.progress_percent = p;
			_g.onStatus("progress",_g);
		});
	}
	,__class__: Task_$CompressTrack
});
var Task_$CutTracks = function() {
	this.flag_delete_source = false;
	djNode_task_Task.call(this);
};
Task_$CutTracks.__name__ = ["Task_CutTracks"];
Task_$CutTracks.__super__ = djNode_task_Task;
Task_$CutTracks.prototype = $extend(djNode_task_Task.prototype,{
	run: function() {
		var _g = this;
		this.name = "Spliting Tracks";
		this.par = this.shared;
		this.progress_type = "steps";
		this.progress_steps_total = this.par.cd.tracks_total;
		djNode_task_Task.prototype.run.call(this);
		if(this.par.cd.isMultiImage) {
			djNode_tools_LOG.log("Skipping CUT, as the image is already cut",null,{ fileName : "Task_CutTracks.hx", lineNumber : 45, className : "Task_CutTracks", methodName : "run"});
			this.complete();
			return;
		}
		this.arexec = new djNode_tools_ArrayExecSync(this.par.cd.tracks);
		this.arexec.queue_action = function(tr) {
			var cutter = new djNode_file_FileCutter();
			cutter.events.once("close",function(b) {
				if(b) _g.arexec.next(); else _g.fail(cutter.error_log,cutter.error_code);
			});
			cutter.cut(_g.par.imagePath,js_node_Path.join(_g.par.tempDir,tr.getFilenameRaw()),tr.sectorStart * _g.par.cd.SECTORSIZE,tr.sectorSize * _g.par.cd.SECTORSIZE);
			_g.progress_steps_current = tr.trackNo;
			_g.onStatus("progress",_g);
		};
		this.arexec.queue_complete = function() {
			djNode_tools_LOG.log("Cutting Complete",null,{ fileName : "Task_CutTracks.hx", lineNumber : 68, className : "Task_CutTracks", methodName : "run"});
			if(_g.flag_delete_source) {
				djNode_tools_LOG.log("Deleting image file \"" + _g.par.imagePath + "\"",null,{ fileName : "Task_CutTracks.hx", lineNumber : 71, className : "Task_CutTracks", methodName : "run"});
				js_node_Fs.unlinkSync(_g.par.imagePath);
			}
			_g.complete();
		};
		this.arexec.start();
	}
	,__class__: Task_$CutTracks
});
var Task_$JoinTracks = function() {
	this.flag_delete_old = true;
	djNode_task_Task.call(this);
};
Task_$JoinTracks.__name__ = ["Task_JoinTracks"];
Task_$JoinTracks.__super__ = djNode_task_Task;
Task_$JoinTracks.prototype = $extend(djNode_task_Task.prototype,{
	run: function() {
		var _g = this;
		this.name = "Joining Tracks";
		this.par = this.shared;
		this.progress_type = "steps";
		this.progress_steps_total = this.par.cd.tracks_total;
		djNode_task_Task.prototype.run.call(this);
		djNode_tools_LOG.log("Joining tracks to an image. Total tracks " + this.par.cd.tracks_total,null,{ fileName : "Task_JoinTracks.hx", lineNumber : 31, className : "Task_JoinTracks", methodName : "run"});
		if(this.par.cd.isMultiImage) {
			djNode_tools_LOG.log("- NO need to JOIN, Track is multitrack",null,{ fileName : "Task_JoinTracks.hx", lineNumber : 34, className : "Task_JoinTracks", methodName : "run"});
			this.complete();
			return;
		}
		this.joiner = new djNode_file_FileJoiner();
		this.joiner.events.once("close",function(st) {
			if(st) {
				djNode_tools_LOG.log("Join Complete",null,{ fileName : "Task_JoinTracks.hx", lineNumber : 43, className : "Task_JoinTracks", methodName : "run"});
				_g.complete();
			} else {
				djNode_tools_LOG.log("Join ERROR - " + _g.joiner.error_log,null,{ fileName : "Task_JoinTracks.hx", lineNumber : 47, className : "Task_JoinTracks", methodName : "run"});
				_g.fail(_g.joiner.error_log);
			}
		});
		this.joiner.events.on("progress",function(a,b) {
			_g.progress_steps_current = a;
			_g.onStatus("progress",_g);
		});
		var filesToJoin = [];
		var _g1 = 0;
		var _g11 = this.par.cd.tracks;
		while(_g1 < _g11.length) {
			var i = _g11[_g1];
			++_g1;
			filesToJoin.push(js_node_Path.join(this.par.tempDir,i.filename));
		}
		this.joiner.join(this.par.imagePath,filesToJoin);
	}
	,__class__: Task_$JoinTracks
});
var Task_$MoveFiles = function() {
	djNode_task_Task.call(this);
};
Task_$MoveFiles.__name__ = ["Task_MoveFiles"];
Task_$MoveFiles.__super__ = djNode_task_Task;
Task_$MoveFiles.prototype = $extend(djNode_task_Task.prototype,{
	run: function() {
		var _g = this;
		this.name = "Moving";
		this.par = this.shared;
		this.progress_type = "steps";
		this.progress_steps_total = this.par.cd.tracks_total;
		djNode_task_Task.prototype.run.call(this);
		this.arexec = new djNode_tools_ArrayExecSync(this.par.cd.tracks);
		this.arexec.queue_action = function(tr) {
			var sourcePath = js_node_Path.join(_g.par.tempDir,tr.filename);
			var destPath = js_node_Path.join(CDC.batch_outputDir,tr.diskFile);
			djNode_tools_FileTool.moveFile(sourcePath,destPath,function() {
				djNode_tools_LOG.log(" Moved file " + sourcePath + " to " + destPath,null,{ fileName : "Task_MoveFiles.hx", lineNumber : 41, className : "Task_MoveFiles", methodName : "run"});
				_g.arexec.next();
			});
			_g.progress_steps_current = tr.trackNo;
			_g.onStatus("progress",_g);
		};
		this.arexec.queue_complete = function() {
			djNode_tools_LOG.log("Move Complete",null,{ fileName : "Task_MoveFiles.hx", lineNumber : 50, className : "Task_MoveFiles", methodName : "run"});
			_g.complete();
		};
		this.arexec.start();
	}
	,__class__: Task_$MoveFiles
});
var Task_$RestoreTrack = function(tr) {
	this.flag_delete_old = true;
	this.name = "Restoring track " + tr.trackNo;
	djNode_task_Task.call(this);
	this.progress_type = "percent";
	this.track = tr;
};
Task_$RestoreTrack.__name__ = ["Task_RestoreTrack"];
Task_$RestoreTrack.__super__ = djNode_task_Task;
Task_$RestoreTrack.prototype = $extend(djNode_task_Task.prototype,{
	run: function() {
		djNode_task_Task.prototype.run.call(this);
		this.trackFullPath = js_node_Path.join(this.shared.tempDir,this.track.filename);
		djNode_tools_LOG.log("Restore Track " + this.trackFullPath,null,{ fileName : "Task_RestoreTrack.hx", lineNumber : 48, className : "Task_RestoreTrack", methodName : "run"});
		if(!this.track.isData) {
			var ffmpeg = new djNode_app_FFmpegAudio();
			this.addListeners(ffmpeg);
			ffmpeg.convertToPCM(this.trackFullPath);
		} else {
			var ecm = new djNode_app_EcmTools();
			this.addListeners(ecm);
			ecm.unecm(this.trackFullPath);
		}
	}
	,postRestore: function() {
		if(this.flag_delete_old) try {
			djNode_tools_LOG.log("Deleting " + this.trackFullPath,null,{ fileName : "Task_RestoreTrack.hx", lineNumber : 73, className : "Task_RestoreTrack", methodName : "postRestore"});
			js_node_Fs.unlinkSync(this.trackFullPath);
		} catch( e ) {
			if (e instanceof js__$Boot_HaxeError) e = e.val;
			djNode_tools_LOG.log("Unable to delete.",2,{ fileName : "Task_RestoreTrack.hx", lineNumber : 76, className : "Task_RestoreTrack", methodName : "postRestore"});
		}
		this.track.filename = this.track.getFilenameRaw();
		djNode_tools_LOG.log("Altering new track filename to \"" + this.track.filename + "\"",null,{ fileName : "Task_RestoreTrack.hx", lineNumber : 81, className : "Task_RestoreTrack", methodName : "postRestore"});
		this.trackFullPath = js_node_Path.join(this.shared.tempDir,this.track.filename);
		if(!this.track.isData) {
			var targetSize = this.track.sectorSize * this.shared.cd.SECTORSIZE | 0;
			var trackSize;
			djNode_tools_LOG.log("Fixing size :: ",null,{ fileName : "Task_RestoreTrack.hx", lineNumber : 95, className : "Task_RestoreTrack", methodName : "postRestore"});
			trackSize = Std["int"](js_node_Fs.statSync(this.trackFullPath).size);
			djNode_tools_LOG.log("  pre size = " + trackSize,null,{ fileName : "Task_RestoreTrack.hx", lineNumber : 97, className : "Task_RestoreTrack", methodName : "postRestore"});
			js_node_Fs.truncateSync(this.trackFullPath,targetSize);
			trackSize = Std["int"](js_node_Fs.statSync(this.trackFullPath).size);
			djNode_tools_LOG.log("  post size = " + trackSize,null,{ fileName : "Task_RestoreTrack.hx", lineNumber : 100, className : "Task_RestoreTrack", methodName : "postRestore"});
			if(trackSize != targetSize) {
				this.fail("Size mismatch! Size is not what is should be","IO");
				return;
			}
		}
		this.complete();
	}
	,addListeners: function(proc) {
		var _g = this;
		proc.events.once("close",function(st) {
			if(st) _g.postRestore(); else _g.fail("Can't restore \"" + _g.trackFullPath + "\", Check write access or free space!","IO");
		});
		proc.events.on("progress",function(p) {
			_g.progress_percent = p;
			_g.onStatus("progress",_g);
		});
	}
	,__class__: Task_$RestoreTrack
});
var Type = function() { };
Type.__name__ = ["Type"];
Type.getClassName = function(c) {
	var a = c.__name__;
	if(a == null) return null;
	return a.join(".");
};
var djNode_AcceptedArgument = function() {
};
djNode_AcceptedArgument.__name__ = ["djNode","AcceptedArgument"];
djNode_AcceptedArgument.prototype = {
	__class__: djNode_AcceptedArgument
};
var djNode_Graphics = function() { };
djNode_Graphics.__name__ = ["djNode","Graphics"];
djNode_Graphics.init = function() {
	if(djNode_Graphics._isInited) return;
	djNode_Graphics.t = djNode_BaseApp.global_terminal;
	djNode_Graphics.borderStyles = [];
	djNode_Graphics.borderStyles[1] = { up : ["╔","═","╗"], down : ["╚","═","╝"], side : ["║","║"]};
	djNode_Graphics.borderStyles[2] = { up : ["┌","─","┐"], down : ["└","─","┘"], side : ["│","│"]};
	djNode_Graphics.MAX_WIDTH = djNode_Graphics.t.getWidth();
	djNode_Graphics.MAX_HEIGHT = djNode_Graphics.t.getHeight();
	djNode_Graphics._isInited = true;
};
djNode_Graphics.drawRect = function(x,y,width,height,color,fillString) {
	process.stdout.write("\x1B[0m");
	djNode_Graphics.t;
	if(fillString == null) fillString = " ";
	if(color == null) color = djNode_Graphics.colorBG;
	var s = StringTools.lpad("",fillString,width);
	djNode_Graphics.t.bg(color);
	var _g1 = y;
	var _g = y + height;
	while(_g1 < _g) {
		var ff = _g1++;
		process.stdout.write("\x1B[" + ff + ";" + x + "f");
		djNode_Graphics.t;
		process.stdout.write(s);
		djNode_Graphics.t;
	}
};
djNode_Graphics.rectsOverlap = function(ax,ay,aw,ah,bx,by,bw,bh) {
	if(ax + aw > bx) {
		if(ax < bx + bw) {
			if(ay + ah > by) {
				if(ay < by + bh) return true;
			}
		}
	}
	return false;
};
djNode_Graphics.drawBorder = function(x,y,width,height,style,fg,bg) {
	process.stdout.write("\x1B[0m");
	djNode_Graphics.t;
	if(bg == null) bg = djNode_Graphics.colorBG;
	if(fg == null) fg = djNode_Graphics.colorFG;
	if(style < 1) style = 1;
	djNode_Graphics.t.bg(bg).fg(fg);
	process.stdout.write("\x1B[" + y + ";" + x + "f");
	djNode_Graphics.t;
	djNode_Graphics.t.print(djNode_Graphics.borderStyles[style].up[0] + StringTools.lpad("",djNode_Graphics.borderStyles[style].up[1],width - 2) + djNode_Graphics.borderStyles[style].up[2]);
	var ff = 0;
	while(++ff < height) {
		process.stdout.write("\x1B[" + (y + ff) + ";" + x + "f");
		djNode_Graphics.t;
		process.stdout.write(djNode_Graphics.borderStyles[style].side[0]);
		djNode_Graphics.t;
		process.stdout.write("\x1B[" + (width - 2) + "C");
		djNode_Graphics.t;
		process.stdout.write(djNode_Graphics.borderStyles[style].side[1]);
		djNode_Graphics.t;
	}
	process.stdout.write("\x1B[" + (y + height - 1) + ";" + x + "f");
	djNode_Graphics.t;
	djNode_Graphics.t.print(djNode_Graphics.borderStyles[style].down[0] + StringTools.lpad("",djNode_Graphics.borderStyles[style].down[1],width - 2) + djNode_Graphics.borderStyles[style].down[2]);
};
djNode_Graphics.drawArray = function(ar,x,y) {
	var _g1 = 0;
	var _g = ar.length;
	while(_g1 < _g) {
		var i = _g1++;
		process.stdout.write("\x1B[" + (y + i) + ";" + x + "f");
		djNode_Graphics.t;
		process.stdout.write(ar[i]);
		djNode_Graphics.t;
	}
};
djNode_Graphics.drawProgressBar = function(x,y,width,percent) {
	djNode_Graphics._r1 = Math.ceil(width / 100 * percent);
	djNode_Graphics._s1 = StringTools.lpad(""," ",djNode_Graphics._r1);
	djNode_Graphics._s2 = StringTools.rpad("","-",width - djNode_Graphics._r1);
	if(djNode_Graphics._s3 == null) djNode_Graphics._s3 = djNode_Graphics.t.sprintf("~!~~darkgray~~bg_gray~");
	((function($this) {
		var $r;
		process.stdout.write("\x1B[" + y + ";" + x + "f");
		$r = djNode_Graphics.t;
		return $r;
	}(this))).print("" + djNode_Graphics._s3 + djNode_Graphics._s1).resetBg().print(djNode_Graphics._s2);
};
djNode_Graphics.hideCursor = function() {
	process.stdout.write("\x1B[" + 1 + ";" + 1 + "f");
	djNode_Graphics.t;
};
var djNode_Keycodes = { __ename__ : true, __constructs__ : ["up","down","left","right","home","insert","delete","end","pageup","pagedown","backsp","tab","enter","space","esc","ctrlC","acute","F1","F2","F3","F4","F5","other"] };
djNode_Keycodes.up = ["up",0];
djNode_Keycodes.up.toString = $estr;
djNode_Keycodes.up.__enum__ = djNode_Keycodes;
djNode_Keycodes.down = ["down",1];
djNode_Keycodes.down.toString = $estr;
djNode_Keycodes.down.__enum__ = djNode_Keycodes;
djNode_Keycodes.left = ["left",2];
djNode_Keycodes.left.toString = $estr;
djNode_Keycodes.left.__enum__ = djNode_Keycodes;
djNode_Keycodes.right = ["right",3];
djNode_Keycodes.right.toString = $estr;
djNode_Keycodes.right.__enum__ = djNode_Keycodes;
djNode_Keycodes.home = ["home",4];
djNode_Keycodes.home.toString = $estr;
djNode_Keycodes.home.__enum__ = djNode_Keycodes;
djNode_Keycodes.insert = ["insert",5];
djNode_Keycodes.insert.toString = $estr;
djNode_Keycodes.insert.__enum__ = djNode_Keycodes;
djNode_Keycodes["delete"] = ["delete",6];
djNode_Keycodes["delete"].toString = $estr;
djNode_Keycodes["delete"].__enum__ = djNode_Keycodes;
djNode_Keycodes.end = ["end",7];
djNode_Keycodes.end.toString = $estr;
djNode_Keycodes.end.__enum__ = djNode_Keycodes;
djNode_Keycodes.pageup = ["pageup",8];
djNode_Keycodes.pageup.toString = $estr;
djNode_Keycodes.pageup.__enum__ = djNode_Keycodes;
djNode_Keycodes.pagedown = ["pagedown",9];
djNode_Keycodes.pagedown.toString = $estr;
djNode_Keycodes.pagedown.__enum__ = djNode_Keycodes;
djNode_Keycodes.backsp = ["backsp",10];
djNode_Keycodes.backsp.toString = $estr;
djNode_Keycodes.backsp.__enum__ = djNode_Keycodes;
djNode_Keycodes.tab = ["tab",11];
djNode_Keycodes.tab.toString = $estr;
djNode_Keycodes.tab.__enum__ = djNode_Keycodes;
djNode_Keycodes.enter = ["enter",12];
djNode_Keycodes.enter.toString = $estr;
djNode_Keycodes.enter.__enum__ = djNode_Keycodes;
djNode_Keycodes.space = ["space",13];
djNode_Keycodes.space.toString = $estr;
djNode_Keycodes.space.__enum__ = djNode_Keycodes;
djNode_Keycodes.esc = ["esc",14];
djNode_Keycodes.esc.toString = $estr;
djNode_Keycodes.esc.__enum__ = djNode_Keycodes;
djNode_Keycodes.ctrlC = ["ctrlC",15];
djNode_Keycodes.ctrlC.toString = $estr;
djNode_Keycodes.ctrlC.__enum__ = djNode_Keycodes;
djNode_Keycodes.acute = ["acute",16];
djNode_Keycodes.acute.toString = $estr;
djNode_Keycodes.acute.__enum__ = djNode_Keycodes;
djNode_Keycodes.F1 = ["F1",17];
djNode_Keycodes.F1.toString = $estr;
djNode_Keycodes.F1.__enum__ = djNode_Keycodes;
djNode_Keycodes.F2 = ["F2",18];
djNode_Keycodes.F2.toString = $estr;
djNode_Keycodes.F2.__enum__ = djNode_Keycodes;
djNode_Keycodes.F3 = ["F3",19];
djNode_Keycodes.F3.toString = $estr;
djNode_Keycodes.F3.__enum__ = djNode_Keycodes;
djNode_Keycodes.F4 = ["F4",20];
djNode_Keycodes.F4.toString = $estr;
djNode_Keycodes.F4.__enum__ = djNode_Keycodes;
djNode_Keycodes.F5 = ["F5",21];
djNode_Keycodes.F5.toString = $estr;
djNode_Keycodes.F5.__enum__ = djNode_Keycodes;
djNode_Keycodes.other = ["other",22];
djNode_Keycodes.other.toString = $estr;
djNode_Keycodes.other.__enum__ = djNode_Keycodes;
var djNode_Keyboard = function(listener) {
	this._listener = listener;
	this.stdin = null;
};
djNode_Keyboard.__name__ = ["djNode","Keyboard"];
djNode_Keyboard.QUICKFIX = function(callback) {
	process.stdout.write("\x1B[s");
	djNode_BaseApp.global_terminal;
	djNode_BaseApp.global_terminal.printf("~line~ #~darkgray~ Quickfix for stdin problem..\n~!~ # Press ~yellow~[ENTER]~!~..\n");
	var kb = new djNode_Keyboard();
	kb._listener = function(s) {
		kb.stop();
		process.stdout.write("\x1B[u");
		djNode_BaseApp.global_terminal;
		djNode_BaseApp.global_terminal.clearScreen(0);
		callback();
	};
	kb.start();
};
djNode_Keyboard.prototype = {
	start: function(realtime) {
		if(realtime == null) realtime = true;
		this.stdin = process.stdin;
		this.stdin.setRawMode(realtime);
		this.stdin.setEncoding("utf8");
		this.stdin.on("data",this._listener);
		this.stdin.resume();
	}
	,stop: function() {
		if(this.stdin == null) return;
		this.stdin.pause();
		this.stdin.setRawMode(false);
		this.stdin.removeAllListeners("data");
	}
	,flush: function() {
		if(this.stdin == null) return;
		this.stdin.pause();
		this.stdin.resume();
	}
	,kill: function() {
		this.stop();
		this.stdin = null;
	}
	,getSpecialChar: function(c) {
		if(HxOverrides.cca(c,1) == null) {
			var _g = HxOverrides.cca(c,0);
			if(_g != null) switch(_g) {
			case 3:
				return djNode_Keycodes.ctrlC;
			case 8:
				return djNode_Keycodes.backsp;
			case 9:
				return djNode_Keycodes.tab;
			case 13:
				return djNode_Keycodes.enter;
			case 27:
				return djNode_Keycodes.esc;
			case 32:
				return djNode_Keycodes.space;
			case 96:
				return djNode_Keycodes.acute;
			case 127:
				return djNode_Keycodes.backsp;
			}
			return null;
		}
		if(HxOverrides.cca(c,0) == 27 && HxOverrides.cca(c,1) == 91) {
			var _g1 = HxOverrides.cca(c,2);
			if(_g1 != null) switch(_g1) {
			case 65:
				return djNode_Keycodes.up;
			case 66:
				return djNode_Keycodes.down;
			case 67:
				return djNode_Keycodes.right;
			case 68:
				return djNode_Keycodes.left;
			case 49:
				return djNode_Keycodes.home;
			case 51:
				return djNode_Keycodes["delete"];
			case 52:
				return djNode_Keycodes.end;
			case 53:
				return djNode_Keycodes.pageup;
			case 54:
				return djNode_Keycodes.pagedown;
			case 91:
				var _g11 = HxOverrides.cca(c,3);
				if(_g11 != null) switch(_g11) {
				case 65:
					return djNode_Keycodes.F1;
				case 66:
					return djNode_Keycodes.F2;
				case 67:
					return djNode_Keycodes.F3;
				case 68:
					return djNode_Keycodes.F4;
				case 69:
					return djNode_Keycodes.F5;
				}
				break;
			}
			return null;
		}
		return null;
	}
	,__class__: djNode_Keyboard
};
var djNode_Terminal = function() {
	this.colormap_fg = new haxe_ds_StringMap();
	this.colormap_fg.set("darkgray","\x1B[90m");
	this.colormap_fg.set("red","\x1B[91m");
	this.colormap_fg.set("green","\x1B[92m");
	this.colormap_fg.set("yellow","\x1B[93m");
	this.colormap_fg.set("blue","\x1B[94m");
	this.colormap_fg.set("magenta","\x1B[95m");
	this.colormap_fg.set("cyan","\x1B[96m");
	this.colormap_fg.set("white","\x1B[97m");
	this.colormap_fg.set("black","\x1B[30m");
	this.colormap_fg.set("darkred","\x1B[31m");
	this.colormap_fg.set("darkgreen","\x1B[32m");
	this.colormap_fg.set("darkyellow","\x1B[33m");
	this.colormap_fg.set("darkblue","\x1B[34m");
	this.colormap_fg.set("darkmagenta","\x1B[35m");
	this.colormap_fg.set("darkcyan","\x1B[36m");
	this.colormap_fg.set("gray","\x1B[37m");
	this.colormap_bg = new haxe_ds_StringMap();
	this.colormap_bg.set("darkgray","\x1B[100m");
	this.colormap_bg.set("red","\x1B[101m");
	this.colormap_bg.set("green","\x1B[102m");
	this.colormap_bg.set("yellow","\x1B[103m");
	this.colormap_bg.set("blue","\x1B[104m");
	this.colormap_bg.set("magenta","\x1B[105m");
	this.colormap_bg.set("cyan","\x1B[106m");
	this.colormap_bg.set("white","\x1B[107m");
	this.colormap_bg.set("black","\x1B[40m");
	this.colormap_bg.set("darkred","\x1B[41m");
	this.colormap_bg.set("darkgreen","\x1B[42m");
	this.colormap_bg.set("darkyellow","\x1B[43m");
	this.colormap_bg.set("darkblue","\x1B[44m");
	this.colormap_bg.set("darkmagenta","\x1B[45m");
	this.colormap_bg.set("darkcyan","\x1B[46m");
	this.colormap_bg.set("gray","\x1B[47m");
};
djNode_Terminal.__name__ = ["djNode","Terminal"];
djNode_Terminal.prototype = {
	demoPrintColors: function() {
		var startingY = 3;
		var startingX = 5;
		var distanceBetweenColumns = 15;
		var cc = startingY;
		this.clearScreen();
		process.stdout.write("\x1B[" + 1 + ";" + 1 + "f");
		this;
		this.printLine().println("Color Demonstration").printLine();
		var _g = 0;
		var _g1 = djNode_Terminal.AVAIL_COLORS;
		while(_g < _g1.length) {
			var i = _g1[_g];
			++_g;
			this.move(startingX,++cc);
			if(i == "black") this.bg("gray"); else this.bg("black");
			this.fg(i).print(i).endl().resetFg();
		}
		cc = startingY;
		process.stdout.write("\x1B[0m");
		this;
		var _g2 = 0;
		var _g11 = djNode_Terminal.AVAIL_COLORS;
		while(_g2 < _g11.length) {
			var i1 = _g11[_g2];
			++_g2;
			this.move(startingX + distanceBetweenColumns,++cc);
			if(i1 == "white" || i1 == "yellow") this.fg("darkgray"); else this.fg("white");
			this.bg(i1).print(i1).endl().resetBg();
		}
		this.printLine();
	}
	,getWidth: function() {
		return process.stdout.columns;
	}
	,getHeight: function() {
		return process.stdout.rows;
	}
	,print: function(str) {
		process.stdout.write(str);
		return this;
	}
	,println: function(str) {
		process.stdout.write(str + "\n");
		return this;
	}
	,fg: function(col) {
		if(col == null) {
			process.stdout.write("\x1B[39m");
			return this;
		}
		return this.print(this.colormap_fg.get(col));
	}
	,bg: function(col) {
		if(col == null) {
			process.stdout.write("\x1B[49m");
			return this;
		}
		return this.print(this.colormap_bg.get(col));
	}
	,bold: function() {
		process.stdout.write("\x1B[1m");
		return this;
	}
	,resetFg: function() {
		process.stdout.write("\x1B[39m");
		return this;
	}
	,resetBg: function() {
		process.stdout.write("\x1B[49m");
		return this;
	}
	,resetBold: function() {
		process.stdout.write("\x1B[21m");
		return this;
	}
	,reset: function() {
		process.stdout.write("\x1B[0m");
		return this;
	}
	,endl: function() {
		process.stdout.write("\n");
		return this;
	}
	,up: function(x) {
		if(x == null) x = 1;
		process.stdout.write("\x1B[" + x + "A");
		return this;
	}
	,down: function(x) {
		if(x == null) x = 1;
		process.stdout.write("\x1B[" + x + "B");
		return this;
	}
	,forward: function(x) {
		if(x == null) x = 1;
		process.stdout.write("\x1B[" + x + "C");
		return this;
	}
	,back: function(x) {
		if(x == null) x = 1;
		process.stdout.write("\x1B[" + x + "D");
		return this;
	}
	,move: function(x,y) {
		process.stdout.write("\x1B[" + y + ";" + x + "f");
		return this;
	}
	,savePos: function() {
		process.stdout.write("\x1B[s");
		return this;
	}
	,restorePos: function() {
		process.stdout.write("\x1B[u");
		return this;
	}
	,pageDown: function() {
		this.print(StringTools.lpad("","\n",this.getHeight() + 1));
		process.stdout.write("\x1B[" + 1 + ";" + 1 + "f");
		return this;
	}
	,clearFromHere: function(num) {
		((function($this) {
			var $r;
			process.stdout.write("\x1B[s");
			$r = $this;
			return $r;
		}(this))).print(StringTools.lpad(""," ",num));
		process.stdout.write("\x1B[u");
		return this;
	}
	,clearLine: function(type) {
		process.stdout.write("\x1B[" + Std.string(type != null?type:2) + "K");
		return this;
	}
	,printLine: function(symbol,length) {
		if(symbol == null) symbol = djNode_Terminal.DEFAULT_LINE_SYMBOL;
		if(length == null) length = djNode_Terminal.DEFAULT_LINE_WIDTH;
		return this.print(StringTools.lpad("",symbol,length)).endl();
	}
	,H1: function(text,color) {
		if(color == null) color = "darkgreen";
		this.print(this.sprintf("~" + color + "~ " + djNode_Terminal.H1_SYMBOL + "~!~ ~white~~bg_" + color + "~" + text + "~!~\n ~line~"));
	}
	,H2: function(text,color) {
		if(color == null) color = "cyan";
		this.print(this.sprintf(" ~bg_" + color + "~~black~" + djNode_Terminal.H2_SYMBOL + "~!~ ~" + color + "~" + text + "~!~\n ~line2~"));
	}
	,H3: function(text,color) {
		if(color == null) color = "blue";
		this.print(this.sprintf("~" + color + "~ " + djNode_Terminal.H3_SYMBOL + " ~!~" + text + "\n ~line2~"));
	}
	,list: function(text,color) {
		if(color == null) color = "green";
		this.print(this.sprintf("~" + color + "~  " + djNode_Terminal.LIST_SYMBOL + " ~!~" + text + "\n"));
	}
	,printf: function(str) {
		return this.print(this.sprintf(str));
	}
	,sprintf: function(str) {
		var _g = this;
		return new EReg("(~\\S[^~]*~)","g").map(str,function(reg) {
			var s;
			var _this = reg.matched(0).substring(1);
			s = HxOverrides.substr(_this,0,-1);
			switch(s) {
			case "!":
				return "\x1B[0m";
			case "!fg":
				return "\x1B[39m";
			case "!bg":
				return "\x1B[49m";
			case "line":
				return StringTools.lpad("",djNode_Terminal.DEFAULT_LINE_SYMBOL,djNode_Terminal.DEFAULT_LINE_WIDTH) + "\n";
			case "line2":
				return StringTools.lpad("",djNode_Terminal.DEFAULT_LINE_SYMBOL,Math.ceil(djNode_Terminal.DEFAULT_LINE_WIDTH / 2)) + "\n";
			case "!line":
				console.log("Error: Deprecated");
				return "--deprecated--";
			case "!line2":
				console.log("Error: Deprecated");
				return "--deprecated--";
			default:
				try {
					if(HxOverrides.substr(s,0,3) == "bg_") {
						var key = HxOverrides.substr(s,3,null);
						return _g.colormap_bg.get(key);
					} else return _g.colormap_fg.get(s);
				} catch( e ) {
					if (e instanceof js__$Boot_HaxeError) e = e.val;
					return "";
					djNode_tools_LOG.log("Parse error, check for typos, str=" + str,2,{ fileName : "Terminal.hx", lineNumber : 527, className : "djNode.Terminal", methodName : "sprintf"});
				}
			}
		});
	}
	,clearScreen: function(type) {
		process.stdout.write("\x1B[" + Std.string(type != null?type:2) + "J");
		return this;
		return this;
	}
	,__class__: djNode_Terminal
};
var djNode_app_AppSpawner = function() {
	this.audit = { linux : { check : false, type : "", param : ""}, win32 : { check : false, type : "", param : ""}};
	this.events = new js_node_events_EventEmitter();
	this.dir_exe = js_node_Path.dirname(process.argv[1]);
	this.platform = process.platform;
};
djNode_app_AppSpawner.__name__ = ["djNode","app","AppSpawner"];
djNode_app_AppSpawner.quickExec = function(path,callback) {
	var pr = js_node_ChildProcess.exec(path,function(error,stdout,stderr) {
		callback(error == null,stdout,stderr);
	});
};
djNode_app_AppSpawner.prototype = {
	spawnProc: function(path,params) {
		var _g = this;
		this.proc = js_node_ChildProcess.spawn(path,params);
		this.proc.once("error",function(a) {
			djNode_tools_LOG.log("Child Process - Error",3,{ fileName : "AppSpawner.hx", lineNumber : 110, className : "djNode.app.AppSpawner", methodName : "spawnProc"});
			_g.error_log = "" + Std.string(a);
			_g.error_code = "error";
			_g.events.emit("close",false);
			_g.kill();
		});
		this.listen_exit();
	}
	,listen_exit: function() {
		var _g = this;
		this.proc.once("close",function(exit,sig) {
			if(exit != 0 || sig != null) {
				_g.error_log = sig;
				_g.error_code = "error";
				djNode_tools_LOG.log("Child Process Close - [ ERROR ] - " + _g.error_log,3,{ fileName : "AppSpawner.hx", lineNumber : 127, className : "djNode.app.AppSpawner", methodName : "listen_exit"});
				_g.events.emit("close",false);
			} else {
				djNode_tools_LOG.log("Child Process Close - [ OK ]",null,{ fileName : "AppSpawner.hx", lineNumber : 131, className : "djNode.app.AppSpawner", methodName : "listen_exit"});
				_g.events.emit("close",true);
			}
			_g.kill();
		});
	}
	,kill: function() {
		if(this.proc != null) {
			this.proc.removeAllListeners("close");
			this.proc = null;
		}
	}
	,checkApp: function() {
		djNode_tools_LOG.log("Checking app..",null,{ fileName : "AppSpawner.hx", lineNumber : 158, className : "djNode.app.AppSpawner", methodName : "checkApp"});
		var _g = this.platform;
		switch(_g) {
		case "linux":
			if(this.audit.linux.check) {
				var _g1 = this.audit.linux.type;
				switch(_g1) {
				case "folder":
					this.check_allArch_infolder(this.audit.linux.param);
					break;
				case "onpath":
					this.check_allArch_onpath(this.audit.linux.param);
					break;
				case "package":
					this.check_linux_package(this.audit.linux.param);
					break;
				case "custom":
					this.check_linux_custom();
					break;
				default:
					this.onAppCheckResult(false,"Wrong audit type");
				}
			} else this.onAppCheckResult(true);
			break;
		case "win32":
			if(this.audit.win32.check) {
				var _g11 = this.audit.win32.type;
				switch(_g11) {
				case "onpath":
					this.check_allArch_onpath(this.audit.win32.param);
					break;
				case "folder":
					this.check_allArch_infolder(this.audit.win32.param);
					break;
				case "custom":
					this.check_win32_custom();
					break;
				default:
					this.onAppCheckResult(false,"Wrong audit type");
				}
			} else this.onAppCheckResult(true);
			break;
		default:
			this.onAppCheckResult(false,"Unsupported platform");
		}
	}
	,onAppCheckResult: function(status,msg) {
		if(status == null) status = true;
		if(status == true) {
			djNode_tools_LOG.log("AppCheck [OK]",null,{ fileName : "AppSpawner.hx", lineNumber : 195, className : "djNode.app.AppSpawner", methodName : "onAppCheckResult"});
			this.events.emit("check",true);
		} else {
			djNode_tools_LOG.log("AppCheck [ERROR]",null,{ fileName : "AppSpawner.hx", lineNumber : 198, className : "djNode.app.AppSpawner", methodName : "onAppCheckResult"});
			this.events.emit("check",false,msg);
		}
	}
	,check_allArch_onpath: function(exeToCheck) {
		var _g = this;
		djNode_tools_LOG.log("Checking on Path for " + exeToCheck,null,{ fileName : "AppSpawner.hx", lineNumber : 209, className : "djNode.app.AppSpawner", methodName : "check_allArch_onpath"});
		djNode_app_AppSpawner.quickExec(exeToCheck,function(status,so,se) {
			_g.onAppCheckResult(status,"Can't find [" + exeToCheck + "]");
		});
	}
	,check_linux_package: function(packageName) {
	}
	,check_allArch_infolder: function(path) {
		if(djNode_tools_FileTool.pathExists(js_node_Path.normalize(path))) this.onAppCheckResult(true); else this.onAppCheckResult(false,"Can't find [" + path + "]");
	}
	,check_win32_custom: function() {
		this.onAppCheckResult(false,"--");
	}
	,check_linux_custom: function() {
		this.onAppCheckResult(false,"--");
	}
	,__class__: djNode_app_AppSpawner
};
var djNode_app_IArchiver = function() { };
djNode_app_IArchiver.__name__ = ["djNode","app","IArchiver"];
djNode_app_IArchiver.prototype = {
	__class__: djNode_app_IArchiver
};
var djNode_app_Arc = function() {
	this.flag_quick_compress = false;
	this.win32_exe = "Arc.exe";
	djNode_app_AppSpawner.call(this);
	this.flag_quick_compress = true;
	this.compiledPathExe = js_node_Path.join(this.dir_exe,this.win32_exe);
	djNode_tools_LOG.log("ARC Compiled path exe = " + this.compiledPathExe + " ",null,{ fileName : "Arc.hx", lineNumber : 46, className : "djNode.app.Arc", methodName : "new"});
};
djNode_app_Arc.__name__ = ["djNode","app","Arc"];
djNode_app_Arc.__interfaces__ = [djNode_app_IArchiver];
djNode_app_Arc.__super__ = djNode_app_AppSpawner;
djNode_app_Arc.prototype = $extend(djNode_app_AppSpawner.prototype,{
	compress: function(ar,destinationFile) {
		if(destinationFile == null) destinationFile = ar[0] + ".arc";
		djNode_tools_LOG.log("Compressing " + Std.string(ar) + " to \"" + destinationFile + "\" ... ",null,{ fileName : "Arc.hx", lineNumber : 58, className : "djNode.app.Arc", methodName : "compress"});
		var sourceFolder = js_node_Path.dirname(ar[0]);
		var params;
		if(this.flag_quick_compress) params = ["a","-m1","-md8","-s","-o+",destinationFile,"-dp" + sourceFolder]; else params = ["a","-m4","-md32","-s","-o+",destinationFile,"-dp" + sourceFolder];
		var _g = 0;
		while(_g < ar.length) {
			var i = ar[_g];
			++_g;
			params.push(js_node_Path.basename(i));
		}
		this.spawnProc(this.compiledPathExe,params);
		this.listen_progress();
	}
	,uncompress: function(input,destinationFolder) {
		if(destinationFolder == null) destinationFolder = js_node_Path.dirname(input);
		this.spawnProc(this.compiledPathExe,["e","-o+",input,"-dp" + destinationFolder]);
		this.listen_progress();
	}
	,getFileList: function(filename,callback) {
		djNode_app_AppSpawner.quickExec(this.compiledPathExe + (" l " + filename),function(s,out,err) {
			var reg = new EReg("(\\S*)$","");
			var lines = [];
			lines = out.split("\r");
			lines = lines.splice(3,lines.length - 8);
			lines = lines.map(function(s1) {
				if(reg.match(s1)) return reg.matched(0);
				return null;
			});
			callback(lines);
		});
	}
	,listen_progress: function(oper) {
		var _g = this;
		var expr = new EReg("(\\d{1,3})%\\s*$","");
		this.proc.stdout.setEncoding("utf8");
		this.proc.stdout.on("data",function(data) {
			if(expr.match(data)) _g.events.emit("progress",Std.parseInt(expr.matched(1)));
		});
	}
	,__class__: djNode_app_Arc
});
var djNode_app_EcmTools = function() {
	this.expr_enc = new EReg("\\s*Encoding \\((\\d{1,3})%","");
	this.expr_dec = new EReg("\\s*Decoding \\((\\d{1,3})%","");
	djNode_app_AppSpawner.call(this);
	this.audit.linux = { check : true, type : "package", param : "ecm"};
	this.audit.win32 = { check : true, type : "folder", param : "ecm.exe"};
	if(this.platform == "linux") {
		this.exe_ecm = "ecm-compress";
		this.exe_unecm = "ecm-uncompress";
	} else if(this.platform == "win32") {
		this.exe_ecm = "ecm.exe";
		this.exe_unecm = "unecm.exe";
	}
};
djNode_app_EcmTools.__name__ = ["djNode","app","EcmTools"];
djNode_app_EcmTools.__super__ = djNode_app_AppSpawner;
djNode_app_EcmTools.prototype = $extend(djNode_app_AppSpawner.prototype,{
	ecm: function(input,output) {
		if(output != null) this.spawnProc(js_node_Path.join(this.dir_exe,this.exe_ecm),[input,output]); else this.spawnProc(js_node_Path.join(this.dir_exe,this.exe_ecm),[input]);
		this.listen_progress("encode");
	}
	,unecm: function(input,output) {
		if(output != null) this.spawnProc(js_node_Path.join(this.dir_exe,this.exe_unecm),[input,output]); else this.spawnProc(js_node_Path.join(this.dir_exe,this.exe_unecm),[input]);
		this.listen_progress("decode");
	}
	,listen_progress: function(oper) {
		var _g = this;
		var expr_per;
		if(oper == "encode") expr_per = this.expr_enc; else expr_per = this.expr_dec;
		this.proc.stderr.setEncoding("utf8");
		this.proc.stderr.on("data",function(data) {
			if(expr_per.match(data)) _g.events.emit("progress",Std.parseInt(expr_per.matched(1)));
		});
	}
	,__class__: djNode_app_EcmTools
});
var djNode_app_FFmpegAudio = function() {
	this.complete = false;
	djNode_app_AppSpawner.call(this);
	this.audit.linux = { check : true, type : "onpath", param : "ffmpeg -L"};
	this.audit.win32 = { check : true, type : "onpath", param : "ffmpeg -L"};
	this.qualityMap = [2,4,6];
};
djNode_app_FFmpegAudio.__name__ = ["djNode","app","FFmpegAudio"];
djNode_app_FFmpegAudio.__super__ = djNode_app_AppSpawner;
djNode_app_FFmpegAudio.prototype = $extend(djNode_app_AppSpawner.prototype,{
	compressPCM: function(input,quality,output) {
		if(quality == null) quality = 2;
		var outputParam = null;
		var outputExt = "";
		if(quality < 1) quality = 1; else if(quality > 4) quality = 4;
		if(quality <= 3) {
			outputExt = ".ogg";
			outputParam = ["-c:a","libvorbis"];
			outputParam.push("-q");
			outputParam.push(Std.string(this.qualityMap[quality - 1]));
		} else {
			outputExt = ".flac";
			outputParam = ["-c:a","flac"];
		}
		if(output == null) output = djNode_tools_FileTool.getPathNoExt(input) + outputExt;
		djNode_tools_LOG.log("Converting [" + input + "] to \"" + output + "\". QUALITY = " + quality,null,{ fileName : "FFmpegAudio.hx", lineNumber : 96, className : "djNode.app.FFmpegAudio", methodName : "compressPCM"});
		var st = js_node_Fs.statSync(input).size;
		this.targetSeconds = Math.floor(st / 176400);
		this.complete = false;
		var proc_params = ["-y","-f","s16le","-ar","44.1k","-ac","2","-i",input];
		var _g = 0;
		while(_g < outputParam.length) {
			var i = outputParam[_g];
			++_g;
			proc_params.push(i);
		}
		proc_params.push(output);
		djNode_tools_LOG.log("FFMPEG PARAMS:",null,{ fileName : "FFmpegAudio.hx", lineNumber : 117, className : "djNode.app.FFmpegAudio", methodName : "compressPCM"});
		djNode_tools_LOG.logObj(proc_params,null,{ fileName : "FFmpegAudio.hx", lineNumber : 118, className : "djNode.app.FFmpegAudio", methodName : "compressPCM"});
		this.spawnProc("ffmpeg",proc_params);
		this.listen_progress();
	}
	,listen_progress: function() {
		var _g = this;
		var expr_size = new EReg("size=\\s*(\\d*)kb","i");
		var expr_time = new EReg("time=(\\d{2}):(\\d{2}):(\\d{2})","i");
		this.proc.stderr.setEncoding("utf8");
		this.proc.stderr.on("data",function(data) {
			if(expr_time.match(data)) {
				_g.hh = Std.parseInt(expr_time.matched(1));
				_g.mm = Std.parseInt(expr_time.matched(2));
				_g.ss = Std.parseInt(expr_time.matched(3));
				_g.secondsConverted = _g.ss + _g.mm * 60 + _g.hh * 360;
				_g.percent = Math.ceil(_g.secondsConverted / _g.targetSeconds * 100);
				if(_g.percent > 100) _g.percent = 100;
				_g.events.emit("progress",_g.percent);
			}
		});
	}
	,getDuration: function(input) {
		var _g = this;
		this.secondsConverted = 0;
		this.targetSeconds = 0;
		djNode_app_AppSpawner.quickExec("ffmpeg -i " + input,function(s,o,e) {
			var expr_duration = new EReg("\\s*Duration:\\s*(\\d{2}):(\\d{2}):(\\d{2})","");
			if(expr_duration.match(e)) {
				_g.hh = Std.parseInt(expr_duration.matched(1));
				_g.mm = Std.parseInt(expr_duration.matched(2));
				_g.ss = Std.parseInt(expr_duration.matched(3));
				_g.targetSeconds = _g.ss + _g.mm * 60 + _g.hh * 360;
			} else if(djNode_tools_FileTool.pathExists(input)) _g.events.emit("close",false,"Could not get duration."); else _g.events.emit("close",false,"" + input + ", no such file.");
			djNode_tools_LOG.log("Duration got [" + _g.targetSeconds + "]",null,{ fileName : "FFmpegAudio.hx", lineNumber : 183, className : "djNode.app.FFmpegAudio", methodName : "getDuration"});
			_g.events.emit("durationGet");
		});
	}
	,convertToPCM: function(input,output) {
		var _g = this;
		djNode_tools_LOG.log("Converting [" + input + "] to PCM ..",null,{ fileName : "FFmpegAudio.hx", lineNumber : 194, className : "djNode.app.FFmpegAudio", methodName : "convertToPCM"});
		this.complete = false;
		if(output == null) output = djNode_tools_FileTool.getPathNoExt(input) + ".pcm";
		this.events.once("durationGet",function() {
			_g.spawnProc("ffmpeg",["-i",input,"-y","-f","s16le","-acodec","pcm_s16le",output]);
			_g.listen_progress();
		});
		this.getDuration(input);
	}
	,__class__: djNode_app_FFmpegAudio
});
var djNode_file_FileCutter = function() {
	this.file_startPos = 0;
	this.bytes_toRead = 0;
	this.events = new js_node_events_EventEmitter();
};
djNode_file_FileCutter.__name__ = ["djNode","file","FileCutter"];
djNode_file_FileCutter.prototype = {
	cut: function(source,destination,byteStart,bytes) {
		djNode_tools_LOG.log("Cutting " + source + " INTO " + destination + ", bytestart=" + byteStart + ", bytes=" + bytes,null,{ fileName : "FileCutter.hx", lineNumber : 64, className : "djNode.file.FileCutter", methodName : "cut"});
		this.inputFile = source;
		this.outputFile = destination;
		this.file_startPos = byteStart;
		this.bytes_toRead = bytes;
		js_node_Fs.writeFileSync(destination,"");
		this.dest_stream = js_node_Fs.createWriteStream(destination);
		js_node_Fs.open(this.inputFile,"r",$bind(this,this._readFunction));
	}
	,_readFunction: function(err,data) {
		var _g = this;
		if(err != null) {
			this.error_log = err.message;
			this.events.emit("close",false);
			return;
		}
		var buffer;
		var lastreadsize = this.bytes_toRead % 65536 | 0;
		var bytes_processed = 0;
		var __t = this.bytes_toRead - lastreadsize;
		while(bytes_processed < __t) {
			buffer = new js_node_buffer_Buffer(65536);
			bytes_processed += js_node_Fs.readSync(data,buffer,0,65536,this.file_startPos + bytes_processed);
			this.dest_stream.write(buffer);
		}
		if(lastreadsize > 0) {
			buffer = new js_node_buffer_Buffer(lastreadsize);
			bytes_processed += js_node_Fs.readSync(data,buffer,0,lastreadsize,this.file_startPos + bytes_processed);
			this.dest_stream.write(buffer);
		}
		js_node_Fs.closeSync(data);
		this.dest_stream.once("close",function() {
			_g.events.emit("close",true);
		});
		this.dest_stream.end();
	}
	,kill: function() {
		this.events.removeAllListeners("close");
		this.events = null;
		if(this.dest_stream != null) this.dest_stream.end();
	}
	,__class__: djNode_file_FileCutter
};
var djNode_file_FileJoiner = function() {
	this.flag_delete_processed = true;
	this.events = new js_node_events_EventEmitter();
};
djNode_file_FileJoiner.__name__ = ["djNode","file","FileJoiner"];
djNode_file_FileJoiner.prototype = {
	join: function(dest,files) {
		var _g = this;
		if(files.length == 0) return;
		this.dest_filename = dest;
		js_node_Fs.writeFileSync(this.dest_filename,"");
		this.dest_stream = js_node_Fs.createWriteStream(this.dest_filename);
		djNode_tools_LOG.log("Appending " + files.length + " files to \"" + this.dest_filename + "\"",null,{ fileName : "FileJoiner.hx", lineNumber : 89, className : "djNode.file.FileJoiner", methodName : "join"});
		this.arrayExec = new djNode_tools_ArrayExecSync(files);
		this.arrayExec.queue_action = function(f) {
			djNode_tools_LOG.log("Appending \"" + _g.fileBeingProcessed + "\"",null,{ fileName : "FileJoiner.hx", lineNumber : 95, className : "djNode.file.FileJoiner", methodName : "join"});
			_g.fileBeingProcessed = f;
			if(!djNode_tools_FileTool.pathExists(f)) {
				_g.error_log = "File \"" + f + "\" does not exist";
				_g.dest_stream.end();
				_g.events.emit("close",false);
				return;
			}
			js_node_Fs.open(f,"r",$bind(_g,_g._readFunction));
		};
		this.arrayExec.queue_complete = function() {
			_g.dest_stream.once("close",function() {
				_g.events.emit("close",true);
			});
			_g.dest_stream.end();
		};
		this.arrayExec.start();
	}
	,_readFunction: function(er,data) {
		if(er != null) {
			this.error_log = er.message;
			this.events.emit("close",false);
			return;
		}
		var stats = js_node_Fs.fstatSync(data);
		var buffer;
		var lastreadsize = stats.size % 65536 | 0;
		var bytes_processed = 0;
		var __t = stats.size - lastreadsize;
		while(bytes_processed < __t) {
			buffer = new js_node_buffer_Buffer(65536);
			bytes_processed += js_node_Fs.readSync(data,buffer,0,65536,bytes_processed);
			this.dest_stream.write(buffer);
		}
		if(lastreadsize > 0) {
			buffer = new js_node_buffer_Buffer(lastreadsize);
			bytes_processed += js_node_Fs.readSync(data,buffer,0,lastreadsize,bytes_processed);
			this.dest_stream.write(buffer);
		}
		this.events.emit("progress",this.arrayExec.counter);
		js_node_Fs.closeSync(data);
		if(this.flag_delete_processed) {
			djNode_tools_LOG.log("Deleting \"" + this.fileBeingProcessed + "\"..",null,{ fileName : "FileJoiner.hx", lineNumber : 154, className : "djNode.file.FileJoiner", methodName : "_readFunction"});
			js_node_Fs.unlinkSync(this.fileBeingProcessed);
		}
		this.arrayExec.next();
	}
	,kill: function() {
		this.events.removeAllListeners("progress");
		this.events.removeAllListeners("close");
		this.events = null;
		if(this.dest_stream != null) this.dest_stream.end();
	}
	,__class__: djNode_file_FileJoiner
};
var djNode_task_FakeTask = function(name,runType_,runTime_) {
	if(runTime_ == null) runTime_ = 2;
	if(runType_ == null) runType_ = "progress";
	this.progressMaxSteps = 10;
	this.progressPercentStep = 9;
	this.name = name;
	djNode_task_Task.call(this);
	this.runType = runType_;
	this.runTime = runTime_;
};
djNode_task_FakeTask.__name__ = ["djNode","task","FakeTask"];
djNode_task_FakeTask.__super__ = djNode_task_Task;
djNode_task_FakeTask.prototype = $extend(djNode_task_Task.prototype,{
	run: function() {
		var _g = this.runType;
		switch(_g) {
		case "progress":
			this.seq = new djNode_tools_Sequencer($bind(this,this.callback_progress));
			this.progress_type = "percent";
			this.r1 = this.runTime / this.progressPercentStep;
			this.seq.next(this.r1);
			break;
		case "fail":
			this.seq = new djNode_tools_Sequencer($bind(this,this.callback_fail));
			this.seq.next(this.runTime);
			break;
		case "steps":
			this.seq = new djNode_tools_Sequencer($bind(this,this.callback_steps));
			this.progress_type = "steps";
			this.r1 = 0;
			this.progress_steps_total = this.progressMaxSteps;
			this.seq.next(this.runTime);
			break;
		}
		djNode_task_Task.prototype.run.call(this);
	}
	,callback_progress: function(step) {
		this.progress_percent += this.progressPercentStep;
		if(this.progress_percent >= 100) {
			this.complete();
			return;
		}
		this.onStatus("progress",this);
		this.seq.next(this.r1);
	}
	,callback_fail: function(step) {
		this.fail("Dummy task has failed");
	}
	,callback_steps: function(step) {
		this.progress_steps_current++;
		if(this.progress_steps_current >= this.progress_steps_total) {
			this.complete();
			return;
		}
		this.onStatus("progress",this);
		this.seq.next(this.runTime);
	}
	,kill: function() {
		djNode_tools_LOG.log("killing dummy task...",null,{ fileName : "FakeTask.hx", lineNumber : 101, className : "djNode.task.FakeTask", methodName : "kill"});
		if(this.seq != null) {
			this.seq.stop();
			this.seq = null;
		}
	}
	,__class__: djNode_task_FakeTask
});
var djNode_task_Qtask = function(name,fn) {
	this._qrun = fn;
	if(name != null) this.name = name;
	djNode_task_Task.call(this);
};
djNode_task_Qtask.__name__ = ["djNode","task","Qtask"];
djNode_task_Qtask.__super__ = djNode_task_Task;
djNode_task_Qtask.prototype = $extend(djNode_task_Task.prototype,{
	run: function() {
		djNode_task_Task.prototype.run.call(this);
		if(this._qrun != null) this._qrun(this); else this._run();
	}
	,_complete: function() {
		this.complete();
	}
	,_fail: function(why,code) {
		this.fail(why,code);
	}
	,_dataSend: function(data) {
		this.dataSend = data;
	}
	,_dataGet: function() {
		return this.dataGet;
	}
	,__class__: djNode_task_Qtask
});
var djNode_task_Task_$ExtractFile = function(file,destinationFolder) {
	this.name = "Extracting";
	djNode_task_Task.call(this);
	this.progress_type = "percent";
	this.fileToExtract = file;
	this.destinationFolder = destinationFolder;
};
djNode_task_Task_$ExtractFile.__name__ = ["djNode","task","Task_ExtractFile"];
djNode_task_Task_$ExtractFile.__super__ = djNode_task_Task;
djNode_task_Task_$ExtractFile.prototype = $extend(djNode_task_Task.prototype,{
	run: function() {
		var _g = this;
		djNode_task_Task.prototype.run.call(this);
		if(this.fileToExtract == null) {
			this.fileToExtract = this.dataGet.input;
			this.destinationFolder = this.dataGet.output;
			djNode_tools_LOG.log("Extractor, got data from previous Task",null,{ fileName : "Task_ExtractFile.hx", lineNumber : 56, className : "djNode.task.Task_ExtractFile", methodName : "run"});
			djNode_tools_LOG.log("Input:" + this.fileToExtract + ", Output:" + this.destinationFolder,null,{ fileName : "Task_ExtractFile.hx", lineNumber : 57, className : "djNode.task.Task_ExtractFile", methodName : "run"});
		}
		this.fileExt = djNode_tools_FileTool.getFileExt(this.fileToExtract);
		if(!djNode_tools_FileTool.pathExists(this.fileToExtract)) {
			this.fail("File (" + this.fileToExtract + ") does not exist","user");
			return;
		}
		if(HxOverrides.indexOf(["7z","rar","arc"],this.fileExt,0) == -1) {
			this.fail("File extension [" + this.fileExt + "] is not supported by the extractor","user");
			return;
		}
		if(this.destinationFolder == null) this.destinationFolder = js_node_Path.dirname(this.fileToExtract);
		djNode_tools_LOG.log("Extracting file \"" + this.fileToExtract + "\" to folder \"" + this.destinationFolder + "\"",null,{ fileName : "Task_ExtractFile.hx", lineNumber : 82, className : "djNode.task.Task_ExtractFile", methodName : "run"});
		var arc = new djNode_app_Arc();
		arc.events.on("progress",function(e) {
			_g.progress_percent = e;
			_g.onStatus("progress",_g);
		});
		arc.events.once("close",function(d) {
			if(d == false) {
				_g.fail("Could not extract " + _g.fileToExtract);
				return;
			} else _g.complete();
		});
		arc.uncompress(this.fileToExtract,this.destinationFolder);
	}
	,__class__: djNode_task_Task_$ExtractFile
});
var djNode_term_UserAsk = function() { };
djNode_term_UserAsk.__name__ = ["djNode","term","UserAsk"];
djNode_term_UserAsk.init = function() {
	djNode_term_UserAsk.t = djNode_BaseApp.global_terminal;
	if(djNode_term_UserAsk.kb == null) djNode_term_UserAsk.kb = new djNode_Keyboard();
};
djNode_term_UserAsk.multipleChoice = function(choices,callback,additionalChars) {
	var maxoptions = 0;
	if(maxoptions > djNode_term_UserAsk.t.getHeight() - 2) djNode_tools_LOG.log("Warning, Screen will overflow ",2,{ fileName : "UserAsk.hx", lineNumber : 43, className : "djNode.term.UserAsk", methodName : "multipleChoice"});
	var _g = 0;
	while(_g < choices.length) {
		var i = choices[_g];
		++_g;
		maxoptions++;
		djNode_term_UserAsk.t.fg("yellow").print(" " + maxoptions + ". ");
		djNode_term_UserAsk.t.fg("white").print(i).endl().reset();
	}
	((function($this) {
		var $r;
		process.stdout.write("\x1B[0m");
		$r = djNode_term_UserAsk.t;
		return $r;
	}(this))).print(" Select one from [1-" + maxoptions + "] : ");
	process.stdout.write("\x1B[s");
	djNode_term_UserAsk.t;
	djNode_term_UserAsk.kb._listener = function(k) {
		djNode_term_UserAsk.checkEscapeKeys(k);
		var userSel = Std.parseInt(k);
		process.stdout.write("\x1B[u");
		djNode_term_UserAsk.t;
		djNode_term_UserAsk.t.clearLine(0);
		if(userSel > 0 && userSel <= maxoptions) {
			djNode_term_UserAsk.t.fg("green").print("" + userSel).reset().endl();
			djNode_term_UserAsk.kb.stop();
			callback(userSel - 1);
		}
	};
	djNode_term_UserAsk.kb.start(false);
};
djNode_term_UserAsk.yesNo = function(callback,question) {
	if(question != null) {
		djNode_term_UserAsk.t.fg("white");
		process.stdout.write(" " + question);
		djNode_term_UserAsk.t;
	}
	djNode_term_UserAsk.t.fg("yellow");
	process.stdout.write(" (Y/N) : ");
	djNode_term_UserAsk.t;
	djNode_term_UserAsk.kb._listener = function(k) {
		djNode_term_UserAsk.checkEscapeKeys(k);
		if(k.toLowerCase() == "y") {
			djNode_term_UserAsk.t.fg("green").print("Y").reset();
			djNode_term_UserAsk.kb.stop();
			callback(true);
		} else if(k.toLowerCase() == "n") {
			djNode_term_UserAsk.t.fg("red").print("N").reset();
			djNode_term_UserAsk.kb.stop();
			callback(false);
		}
	};
	djNode_term_UserAsk.kb.start();
};
djNode_term_UserAsk.checkEscapeKeys = function(k) {
	if(djNode_term_UserAsk.kb.getSpecialChar(k) == djNode_Keycodes.ctrlC) {
		if(djNode_term_UserAsk.callback_quit != null) djNode_term_UserAsk.callback_quit(); else {
			djNode_term_UserAsk.t.fg("red").print(" -- Process Exit -- \n").reset();
			process.exit(1);
		}
	}
};
var djNode_term_info_ActionInfo = function() {
	this.symbol_separator = ":";
	this.padding_string = " ";
	this.color_accent = "yellow";
	this.color_info = "gray";
	this.t = djNode_BaseApp.global_terminal;
	this._waitResult = false;
};
djNode_term_info_ActionInfo.__name__ = ["djNode","term","info","ActionInfo"];
djNode_term_info_ActionInfo.prototype = {
	printPair: function(action,info,pairColor) {
		if(info == null) info = "";
		this.__checkWaitStatus();
		this.t.printf("" + this.padding_string + action + " " + this.symbol_separator + " ");
		if(pairColor != null) this.t.printf("~" + pairColor + "~" + Std.string(info) + "\n~!~"); else this.t.printf("~" + this.color_accent + "~" + Std.string(info) + "\n~!~");
	}
	,deletePrevLine: function() {
		process.stdout.write("\x1B[" + 1 + "A");
		this.t;
		this.t.clearLine(2);
	}
	,quickAction: function(action,success,info) {
		this.__checkWaitStatus();
		this.t.printf("" + this.padding_string + action + " " + this.symbol_separator + " ");
		this.__printSuccess(success);
		if(info != null) this.t.printf("~" + this.color_info + "~ , " + info + "~!~\n");
	}
	,actionStart: function(action) {
		this.__checkWaitStatus();
		this.t.printf("" + this.padding_string + action + " " + this.symbol_separator + " ");
		process.stdout.write("\x1B[s");
		this.t;
		this._waitResult = true;
	}
	,actionEnd: function(success,info) {
		if(this._waitResult) {
			process.stdout.write("\x1B[u");
			this.t;
			this.t.clearLine(0);
		}
		this.__printSuccess(success);
		if(info != null) this.t.printf("~" + this.color_info + "~ , " + info + "~!~\n"); else {
			process.stdout.write("\n");
			this.t;
		}
		this._waitResult = false;
	}
	,actionProgress: function(progress,info) {
		process.stdout.write("\x1B[u");
		this.t;
		this.t.printf("~" + this.color_accent + "~[" + progress + "]~!~");
		if(info != null) this.t.printf("~" + this.color_info + "~ , " + info + "~!~\n");
	}
	,reset: function() {
		if(this._waitResult) {
			process.stdout.write("\x1B[u");
			this.t;
			this.t.clearLine(2);
			this.t.back(this.t.getWidth());
			this._waitResult = false;
		}
	}
	,genericProgress: function(status,task,useInline) {
		if(useInline == null) useInline = false;
		if(status == "fail") this.actionEnd(false); else if(status == "start") {
			if(useInline) this.deletePrevLine();
			this.actionStart(task.name);
		} else if(status == "complete") this.actionEnd(true); else if(status == "progress") {
			if(task.progress_type == "percent") this.actionProgress("% " + task.progress_percent); else if(task.progress_type == "steps") this.actionProgress("" + task.progress_steps_current + "/" + task.progress_steps_total);
		}
	}
	,__printSuccess: function(success) {
		if(success) this.t.printf("~green~[OK]~!~"); else this.t.printf("~red~[FAIL]~!~");
	}
	,__printStyled: function(str,bgColor) {
		this.t.printf("~bg_" + bgColor + "~~white~[" + str + "]~!~");
	}
	,__checkWaitStatus: function() {
		if(this._waitResult) {
			djNode_tools_LOG.log("Should not print a new line while waiting result",2,{ fileName : "ActionInfo.hx", lineNumber : 208, className : "djNode.term.info.ActionInfo", methodName : "__checkWaitStatus"});
			process.stdout.write("\x1B[u");
			this.t;
			this.__printStyled("aborted","darkred");
			process.stdout.write("\n");
			this.t;
			this._waitResult = false;
		}
	}
	,__class__: djNode_term_info_ActionInfo
};
var djNode_tools_ArrayExecSync = function(ar) {
	if(ar != null) this.queue = ar; else this.queue = [];
};
djNode_tools_ArrayExecSync.__name__ = ["djNode","tools","ArrayExecSync"];
djNode_tools_ArrayExecSync.prototype = {
	push: function(el) {
		this.queue.push(el);
	}
	,start: function(fn_action,fn_complete) {
		if(this.queue.length == 0) return;
		this.counter = -1;
		if(fn_action != null) this.queue_action = fn_action;
		if(fn_complete != null) this.queue_complete = fn_complete;
		this.next();
	}
	,next: function() {
		if(++this.counter < this.queue.length) this.queue_action(this.queue[this.counter]); else this.queue_complete();
	}
	,kill: function() {
		this.queue = null;
	}
	,__class__: djNode_tools_ArrayExecSync
};
var djNode_tools_CDInfo = function(descriptorFile) {
	if(descriptorFile != null) this.load(descriptorFile);
};
djNode_tools_CDInfo.__name__ = ["djNode","tools","CDInfo"];
djNode_tools_CDInfo.prototype = {
	getSupportedFormats: function() {
		return ["cue","cdd"];
	}
	,getSectorsByDataType: function(type) {
		switch(type) {
		case "AUDIO":
			return 2352;
		case "CDG":
			return 2352;
		case "MODE1/2048":
			return 2048;
		case "MODE1/2352":
			return 2352;
		case "MODE2/2336":
			return 2336;
		case "MODE2/2352":
			return 2352;
		case "CDI/2336":
			return 2336;
		case "CDI/2352":
			return 2352;
		default:
			throw new js__$Boot_HaxeError("Unsuported type " + type);
		}
	}
	,load: function(input) {
		djNode_tools_LOG.log("CDInfo, loading " + input,null,{ fileName : "CDInfo.hx", lineNumber : 119, className : "djNode.tools.CDInfo", methodName : "load"});
		if(djNode_tools_FileTool.pathExists(input) == false) throw new js__$Boot_HaxeError("Cue file \"" + input + "\" does not exist.");
		this.loadedFile = input;
		this.image_path = null;
		this.image_size = 0;
		this.total_size = 0;
		this.tracks = [];
		this.tracks_total = 0;
		this.TITLE = "untitled";
		this.SECTORSIZE = 0;
		this.TYPE = null;
		this.openTrack = null;
		this.openFile = null;
		this.loadedFile_dir = js_node_Path.dirname(this.loadedFile);
		var _this = js_node_Path.extname(input).toLowerCase();
		this.loadedFile_ext = HxOverrides.substr(_this,1,null);
		var rtitle = new EReg("([^/\\\\]*)\\.(?:ccd|cue)$","i");
		if(rtitle.match(input)) this.TITLE = rtitle.matched(1);
		djNode_tools_LOG.log("Guessed cd title = " + this.TITLE,null,{ fileName : "CDInfo.hx", lineNumber : 137, className : "djNode.tools.CDInfo", methodName : "load"});
		var parser = new djNode_tools_CDParser(input);
		parser.parseWith((function($this) {
			var $r;
			var _g = $this.loadedFile_ext;
			$r = (function($this) {
				var $r;
				switch(_g) {
				case "cue":
					$r = $bind($this,$this.parser_cue);
					break;
				case "ccd":
					$r = $bind($this,$this.parser_ccd);
					break;
				default:
					$r = (function($this) {
						var $r;
						throw new js__$Boot_HaxeError("Unsupported file type \"" + $this.loadedFile_ext + "\"");
						return $r;
					}($this));
				}
				return $r;
			}($this));
			return $r;
		}(this)));
		parser = null;
		this.postParse_check();
	}
	,postParse_check: function() {
		if(this.tracks_total == 0) throw new js__$Boot_HaxeError("No Tracks in the cue file");
		this._getCDTypeFromTracks();
		djNode_tools_LOG.log("CD Type = " + this.TYPE,null,{ fileName : "CDInfo.hx", lineNumber : 165, className : "djNode.tools.CDInfo", methodName : "postParse_check"});
		djNode_tools_LOG.log("Number of tracks = " + this.tracks.length,null,{ fileName : "CDInfo.hx", lineNumber : 166, className : "djNode.tools.CDInfo", methodName : "postParse_check"});
		if(this.loadedFile_ext == "ccd") {
			var tryToFind = [".bin",".img"];
			var _g = 0;
			while(_g < tryToFind.length) {
				var i = tryToFind[_g];
				++_g;
				if(djNode_tools_FileTool.pathExists(js_node_Path.join(this.loadedFile_dir,this.TITLE + i))) {
					this.tracks[0].diskFile = this.TITLE + i;
					break;
				}
			}
			if(this.tracks[0].diskFile == null) throw new js__$Boot_HaxeError("CloneCD sheet, Can't find image.");
		}
		var cc = 0;
		var _g1 = 0;
		var _g11 = this.tracks;
		while(_g1 < _g11.length) {
			var i1 = _g11[_g1];
			++_g1;
			if(i1.diskFile == null) continue;
			cc++;
			var check = js_node_Path.join(this.loadedFile_dir,i1.diskFile);
			if(djNode_tools_FileTool.pathExists(check) == false) throw new js__$Boot_HaxeError("Track image file does not exist - " + check);
			var imageStats = js_node_Fs.statSync(check);
			i1.sectorSize = Math.ceil(imageStats.size / this.SECTORSIZE);
			i1.diskFileSize = imageStats.size | 0;
			if(i1.sectorSize <= 0) throw new js__$Boot_HaxeError("File Error, invalid filesize , " + check);
			this.total_size += i1.diskFileSize;
		}
		if(cc == this.tracks.length) {
			this.isMultiImage = true;
			djNode_tools_LOG.log(" Cue Sheet is MULTI FILE ",null,{ fileName : "CDInfo.hx", lineNumber : 221, className : "djNode.tools.CDInfo", methodName : "postParse_check"});
			this.postParse_Multi();
		} else if(cc == 1) {
			this.isMultiImage = false;
			djNode_tools_LOG.log(" Cue Sheet is SINGLE FILE ",null,{ fileName : "CDInfo.hx", lineNumber : 226, className : "djNode.tools.CDInfo", methodName : "postParse_check"});
			this.postParse_Single();
		} else if(cc == 0) throw new js__$Boot_HaxeError("There are no FILES declared in the cuesheet."); else throw new js__$Boot_HaxeError("CDCRUSH doesn't support multi file cue sheets with multi tracks per file.");
		this.image_path = js_node_Path.join(this.loadedFile_dir,this.tracks[0].diskFile);
		var _g2 = 0;
		var _g12 = this.tracks;
		while(_g2 < _g12.length) {
			var i2 = _g12[_g2];
			++_g2;
			i2.debugInfo();
		}
	}
	,postParse_Multi: function() {
	}
	,postParse_Single: function() {
		if(this.tracks[0].diskFile == null) throw new js__$Boot_HaxeError("The first track doesn't have a file image");
		var imageSectorSize = this.tracks[0].sectorSize;
		var c = this.tracks_total - 1;
		this.tracks[c].calculateStart();
		this.tracks[c].sectorSize = imageSectorSize - this.tracks[c].sectorStart;
		while(--c >= 0) {
			this.tracks[c].calculateStart();
			this.tracks[c].sectorSize = this.tracks[c + 1].sectorStart - this.tracks[c].sectorStart;
		}
	}
	,parser_cue: function(line) {
		if(new EReg("^REM","i").match(line)) return;
		if(new EReg("^FILE","i").match(line)) {
			this.image_path = new EReg("[\"']+","g").split(line)[1];
			this.openFile = new EReg("[\"']+","g").split(line)[1];
			return;
		}
		var regTrack = new EReg("^\\s*TRACK\\s+(\\d+)\\s+(\\S+)","i");
		if(regTrack.match(line)) {
			var _g = 0;
			var _g1 = this.tracks;
			while(_g < _g1.length) {
				var i = _g1[_g];
				++_g;
				if(i.trackNo == Std.parseInt(regTrack.matched(1))) throw new js__$Boot_HaxeError("Parse Error, Track-" + i.trackNo + " is already defined");
			}
			var tr = new djNode_tools_CueTrack(regTrack.matched(1),regTrack.matched(2));
			tr.diskFile = this.openFile;
			this.openFile = null;
			this.tracks.push(tr);
			this.tracks_total++;
			this.openTrack = this.tracks[this.tracks_total - 1];
			return;
		}
		var regIndex = new EReg("^\\s*INDEX\\s+(\\d+)\\s+(\\d{1,2}):(\\d{1,2}):(\\d{1,2})","i");
		if(regIndex.match(line)) {
			if(this.openTrack == null) throw new js__$Boot_HaxeError("Parse error, Track is not yet defined");
			var indexno = Std.parseInt(regIndex.matched(1));
			if(this.openTrack.indexExists(indexno)) throw new js__$Boot_HaxeError("Parse Error, track-{" + Std.string(this.openTrack) + ".trackNo} " + (", Duplicate Index entry. Index[" + indexno + "]"));
			this.openTrack.addIndex(indexno,Std.parseInt(regIndex.matched(2)),Std.parseInt(regIndex.matched(3)),Std.parseInt(regIndex.matched(4)));
			return;
		}
		var regPregap = new EReg("^\\s*PREGAP\\s+(\\d{1,2}):(\\d{1,2}):(\\d{1,2})","i");
		if(regPregap.match(line)) {
			if(this.openTrack == null) throw new js__$Boot_HaxeError("Track is not yet defined");
			this.openTrack.setGap(regPregap.matched(1),regPregap.matched(2),regPregap.matched(3));
			return;
		}
	}
	,parser_ccd: function(line) {
		var regGetTrackNo = new EReg("\\[TRACK\\s*(\\d*)\\]","");
		if(regGetTrackNo.match(line)) {
			var tr = new djNode_tools_CueTrack(regGetTrackNo.matched(1));
			this.tracks.push(tr);
			this.openTrack = tr;
			djNode_tools_LOG.log("discovered Track - " + Std.string(tr),null,{ fileName : "CDInfo.hx", lineNumber : 356, className : "djNode.tools.CDInfo", methodName : "parser_ccd"});
			this.tracks_total++;
			return;
		}
		var regGetMode = new EReg("\n*\\s*MODE\\s*=\\s*(\\d)","");
		if(regGetMode.match(line)) {
			if(this.openTrack == null) throw new js__$Boot_HaxeError("Illegal MODE, No track is defined yet.");
			var _g = regGetMode.matched(1);
			switch(_g) {
			case "0":
				this.openTrack.type = "AUDIO";
				this.openTrack.isData = false;
				djNode_tools_LOG.log("AUDIO - ",null,{ fileName : "CDInfo.hx", lineNumber : 365, className : "djNode.tools.CDInfo", methodName : "parser_ccd"});
				break;
			case "2":
				this.openTrack.type = "MODE2/2352";
				djNode_tools_LOG.log("discovered Track - MODE2/2352",null,{ fileName : "CDInfo.hx", lineNumber : 366, className : "djNode.tools.CDInfo", methodName : "parser_ccd"});
				break;
			}
			return;
		}
		var regGetIndex = new EReg("\\s*INDEX\\s*(\\d)\\s*=\\s*(\\d*)","");
		if(regGetIndex.match(line)) {
			if(this.openTrack == null) throw new js__$Boot_HaxeError("Illegal INDEX, No track is defined yet.");
			var ino = Std.parseInt(regGetIndex.matched(1));
			var sst = Std.parseInt(regGetIndex.matched(2));
			this.openTrack.addIndexBySector(ino,sst);
			return;
		}
	}
	,saveAs_Cue: function(output,comment) {
		var data = "";
		var i = 0;
		var tr;
		if(this.tracks_total == 0) throw new js__$Boot_HaxeError("No Tracks to write");
		if(this.TITLE == null) {
			djNode_tools_LOG.log("Title is null, autoset to 'untitled'",2,{ fileName : "CDInfo.hx", lineNumber : 398, className : "djNode.tools.CDInfo", methodName : "saveAs_Cue"});
			this.TITLE = "untitled";
		}
		while(i < this.tracks_total) {
			tr = this.tracks[i];
			if(tr.diskFile != null) data += "FILE \"" + tr.diskFile + "\" BINARY\n";
			data += "\tTRACK " + tr.getTrackNoSTR() + (" " + tr.type + "\n");
			if(this.tracks[i].hasPregap()) data += "\t\tPREGAP " + this.tracks[i].getPregapString() + "\n";
			var t = 0;
			while(t < this.tracks[i].indexTotal) {
				var ind = this.tracks[i].indexAr[t];
				data += "\t\tINDEX ";
				if(ind.no < 10) data += "0";
				data += ind.no + " ";
				data += this.tracks[i].getIndexTimeString(t) + "\n";
				t++;
			}
			i++;
		}
		if(comment != null) data += "REM " + comment;
		js_node_Fs.writeFileSync(output,data,"utf8");
	}
	,createFromImage: function(filename) {
		this.tracks = [];
		this.tracks_total = 0;
		var rtitle = new EReg("([^/\\\\]*)\\.(?:bin|iso|img)$","i");
		if(rtitle.match(filename)) this.TITLE = rtitle.matched(1);
		djNode_tools_LOG.log("createFromImage() - Guessed cd title = " + this.TITLE,null,{ fileName : "CDInfo.hx", lineNumber : 448, className : "djNode.tools.CDInfo", methodName : "createFromImage"});
		this.image_path = filename;
		var imext = djNode_tools_FileTool.getFileExt(this.image_path);
		if(HxOverrides.indexOf(["bin","img","iso"],imext,0) < 0) throw new js__$Boot_HaxeError("createFromImage, unsupported Image Extension");
		if(!djNode_tools_FileTool.pathExists(this.image_path)) throw new js__$Boot_HaxeError("createFromImage(), " + this.image_path + " - does not exist");
		var size = js_node_Fs.statSync(this.image_path).size;
		var sectors = size / this.SECTORSIZE;
		if(sectors % this.SECTORSIZE > 0) throw new js__$Boot_HaxeError("Size mismatch error, \"" + this.image_path + "\" should be of size multiple of " + this.SECTORSIZE);
		var tr = new djNode_tools_CueTrack(1,"MODE2/2352");
		tr.filename = tr.getFilenameRaw();
		tr.addIndex(1,0,0,0);
		this.tracks.push(tr);
		this.tracks_total++;
		this._getCDTypeFromTracks();
	}
	,self_save: function(filename) {
		if(this.tracks_total == 0) throw new js__$Boot_HaxeError("Warning , No tracks to save");
		var _g = 0;
		var _g1 = this.tracks;
		while(_g < _g1.length) {
			var i = _g1[_g];
			++_g;
			if(i.filename == null) throw new js__$Boot_HaxeError("Track " + i.trackNo + " should have a filename set");
		}
		var o = { cdTitle : this.TITLE, sectorSize : this.SECTORSIZE, imageSize : this.total_size, tracks : this.tracks};
		js_node_Fs.writeFileSync(filename,JSON.stringify(o,null,"\t"),"utf8");
	}
	,loadSettingsFile: function(filename) {
		if(djNode_tools_FileTool.pathExists(filename) == false) throw new js__$Boot_HaxeError("CDInfo file \"" + filename + "\" does not exist");
		djNode_tools_LOG.log("CDInfo restoring data - " + filename,null,{ fileName : "CDInfo.hx", lineNumber : 502, className : "djNode.tools.CDInfo", methodName : "loadSettingsFile"});
		var obj = JSON.parse(js_node_Fs.readFileSync(filename,{ encoding : "utf8"}));
		this.tracks = [];
		this.tracks_total = Reflect.fields(obj.tracks).length;
		var i = 0;
		while(i < this.tracks_total) {
			var tr = new djNode_tools_CueTrack();
			var _g = 0;
			var _g1 = Reflect.fields(obj.tracks[i]);
			while(_g < _g1.length) {
				var a = _g1[_g];
				++_g;
				Reflect.setField(tr,a,Reflect.getProperty(obj.tracks[i],a));
			}
			this.tracks.push(tr);
			tr.debugInfo();
			i++;
		}
		var cc = 0;
		var _g2 = 0;
		var _g11 = this.tracks;
		while(_g2 < _g11.length) {
			var i1 = _g11[_g2];
			++_g2;
			if(i1.diskFile != null) cc++;
		}
		this.isMultiImage = cc > 1;
		this.TITLE = obj.cdTitle;
		this.total_size = obj.imageSize;
		this._getCDTypeFromTracks();
		if(!this.isMultiImage) {
			if(this.tracks[0].diskFile == null) this.tracks[0].diskFile = this.TITLE + ".bin";
		}
		djNode_tools_LOG.log("Title = " + this.TITLE,null,{ fileName : "CDInfo.hx", lineNumber : 552, className : "djNode.tools.CDInfo", methodName : "loadSettingsFile"});
		djNode_tools_LOG.log("Tracks Total = " + Std.string(this.tracks_total),null,{ fileName : "CDInfo.hx", lineNumber : 553, className : "djNode.tools.CDInfo", methodName : "loadSettingsFile"});
		djNode_tools_LOG.log("SectorSize = " + Std.string(this.SECTORSIZE),null,{ fileName : "CDInfo.hx", lineNumber : 554, className : "djNode.tools.CDInfo", methodName : "loadSettingsFile"});
	}
	,_getCDTypeFromTracks: function() {
		this.TYPE = null;
		var _g = 0;
		var _g1 = this.tracks;
		while(_g < _g1.length) {
			var i = _g1[_g];
			++_g;
			if(i.isData) {
				this.TYPE = i.type;
				break;
			}
		}
		if(this.TYPE == null) this.TYPE = "AUDIO";
		this.SECTORSIZE = this.getSectorsByDataType(this.TYPE);
	}
	,__class__: djNode_tools_CDInfo
};
var djNode_tools_CDParser = function(input) {
	var fileContent = js_node_Fs.readFileSync(input,{ encoding : "utf8"});
	this.file = fileContent.split("\n");
	this.c = 0;
	this.maxLines = this.file.length;
};
djNode_tools_CDParser.__name__ = ["djNode","tools","CDParser"];
djNode_tools_CDParser.prototype = {
	parseWith: function(fn) {
		do {
			if(this.file[this.c] == null) continue;
			this.file[this.c] = new EReg("^\\s+","").replace(this.file[this.c],"");
			this.file[this.c] = new EReg("\\s+$","").replace(this.file[this.c],"");
			if(this.file[this.c].length == 0) continue;
			try {
				fn(this.file[this.c]);
			} catch( e ) {
				if (e instanceof js__$Boot_HaxeError) e = e.val;
				if( js_Boot.__instanceof(e,String) ) {
					throw new js__$Boot_HaxeError("Parse Error - Line " + this.c + " \n - " + e);
				} else throw(e);
			}
		} while(++this.c < this.maxLines);
	}
	,__class__: djNode_tools_CDParser
};
var djNode_tools_CueIndex = function() {
};
djNode_tools_CueIndex.__name__ = ["djNode","tools","CueIndex"];
djNode_tools_CueIndex.prototype = {
	__class__: djNode_tools_CueIndex
};
var djNode_tools_CueTrack = function(trackNo,type) {
	this.diskFileSize = 0;
	this.diskFile = null;
	this.filename = null;
	this.pregapMillisecs = 0;
	this.pregapSeconds = 0;
	this.pregapMinutes = 0;
	this.sectorStart = 0;
	this.sectorSize = 0;
	this.indexTotal = 0;
	this.trackNo = Std.parseInt(trackNo);
	if(type != null) this.type = type.toUpperCase();
	this.indexAr = [];
	if(type != "AUDIO") this.isData = true; else this.isData = false;
};
djNode_tools_CueTrack.__name__ = ["djNode","tools","CueTrack"];
djNode_tools_CueTrack.prototype = {
	indexExists: function(indexNo) {
		var _g = 0;
		var _g1 = this.indexAr;
		while(_g < _g1.length) {
			var i = _g1[_g];
			++_g;
			if(i.no == indexNo) return true;
		}
		return false;
	}
	,calculateStart: function() {
		if(this.indexTotal == 0) throw new js__$Boot_HaxeError("Track-" + this.trackNo + " has no index defined");
		this.sectorStart = this.indexAr[0].minutes * 4500;
		this.sectorStart += this.indexAr[0].seconds * 75;
		this.sectorStart += this.indexAr[0].millisecs;
	}
	,addIndex: function(index,minutes,seconds,millisecs) {
		var i = new djNode_tools_CueIndex();
		i.no = index;
		i.minutes = minutes;
		i.seconds = seconds;
		i.millisecs = millisecs;
		this.indexAr[this.indexTotal++] = i;
	}
	,addIndexBySector: function(index,size) {
		var mm = Math.floor(size / 4500);
		var ss = Math.floor(size % 4500 / 75);
		var ms = size % 4500 % 75;
		this.addIndex(index,mm,ss,ms);
	}
	,setGap: function(mm,ss,ms) {
		this.pregapMinutes = Std.parseInt(mm);
		this.pregapSeconds = Std.parseInt(ss);
		this.pregapMillisecs = Std.parseInt(ms);
	}
	,getTrackName: function() {
		return "Track" + this.getTrackNoSTR();
	}
	,getTrackNoSTR: function() {
		if(this.trackNo > 9) return Std.string(this.trackNo); else return "0" + this.trackNo;
	}
	,getFilenameRaw: function() {
		var r = this.getTrackName() + ".";
		if(this.isData) r += "bin"; else r += "pcm";
		return r;
	}
	,getIndexTimeString: function(ind) {
		var i = this.indexAr[ind];
		return this.__timedString([i.minutes,i.seconds,i.millisecs]);
	}
	,getPregapString: function() {
		return this.__timedString([this.pregapMinutes,this.pregapSeconds,this.pregapMillisecs]);
	}
	,hasPregap: function() {
		return this.pregapMillisecs > 0 || this.pregapSeconds > 0 || this.pregapMinutes > 0;
	}
	,__timedString: function(ar) {
		var o = "";
		var i = 0;
		while(i < ar.length) {
			if(ar[i] < 10) o += "0";
			o += Std.string(ar[i]) + ":";
			i++;
		}
		return HxOverrides.substr(o,0,-1);
	}
	,debugInfo: function() {
		djNode_tools_LOG.log("-Track:" + this.trackNo + " | diskFile:" + this.diskFile + " | diskFileSize:" + this.diskFileSize + " | ",null,{ fileName : "CDInfo.hx", lineNumber : 729, className : "djNode.tools.CueTrack", methodName : "debugInfo"});
		djNode_tools_LOG.log("- indexTot:" + this.indexTotal + " | sector:" + this.sectorSize + " | sectorStart:" + this.sectorStart + " | isData:" + Std.string(this.isData),null,{ fileName : "CDInfo.hx", lineNumber : 730, className : "djNode.tools.CueTrack", methodName : "debugInfo"});
	}
	,__class__: djNode_tools_CueTrack
};
var djNode_tools_FileTool = function() { };
djNode_tools_FileTool.__name__ = ["djNode","tools","FileTool"];
djNode_tools_FileTool.createRecursiveDir = function(inPath) {
	var paths = js_node_Path.normalize(inPath).split(js_node_Path.sep);
	var cM = paths.length;
	if(cM <= 0) throw new js__$Boot_HaxeError("Path is empty!");
	var c = 0;
	var p1 = "";
	if(paths[0].indexOf(":") > 0) {
		try {
			js_node_Fs.statSync(paths[0]);
		} catch( e ) {
			if (e instanceof js__$Boot_HaxeError) e = e.val;
			if( js_Boot.__instanceof(e,Error) ) {
				throw new js__$Boot_HaxeError("Drive " + paths[0] + " does not exist!!");
			} else throw(e);
		}
		c = 1;
		p1 = paths[0] + js_node_Path.sep;
	}
	while(c < cM) {
		p1 = js_node_Path.join(p1,paths[c]);
		if(djNode_tools_FileTool.pathExists(p1) == false) js_node_Fs.mkdirSync(p1);
		c++;
	}
};
djNode_tools_FileTool.pathExists = function(path) {
	try {
		js_node_Fs.statSync(path);
	} catch( e ) {
		if (e instanceof js__$Boot_HaxeError) e = e.val;
		if( js_Boot.__instanceof(e,Error) ) {
			return false;
		} else throw(e);
	}
	return true;
};
djNode_tools_FileTool.moveFile = function(source,dest,onComplete,onProgress) {
	js_node_Fs.rename(source,dest,function(er) {
		if(er != null) djNode_tools_FileTool.copyFile(source,dest,onComplete,onProgress); else onComplete();
	});
};
djNode_tools_FileTool.copyFile = function(source,dest,onComplete,onProgress) {
	var _in = js_node_Fs.createReadStream(source);
	var _out = js_node_Fs.createWriteStream(dest);
	_in.pipe(_out);
	_in.once("end",function() {
		_in.unpipe();
		_out.end();
		onComplete();
	});
	if(onProgress != null) _out.on("data",function(data) {
		onProgress();
	});
};
djNode_tools_FileTool.getFileListFromDir = function(inPath) {
	var allfiles = js_node_Fs.readdirSync(js_node_Path.normalize(inPath));
	var fileList = [];
	var _g = 0;
	while(_g < allfiles.length) {
		var i = allfiles[_g];
		++_g;
		var stats = js_node_Fs.statSync(js_node_Path.join(inPath,i));
		if(stats.isFile()) fileList.push(i);
	}
	return fileList;
};
djNode_tools_FileTool.getFileListFromAsterisk = function(path) {
	var fileList = [];
	var basePath = js_node_Path.dirname(path);
	var extToGet = djNode_tools_FileTool.getFileExt(path).toLowerCase();
	var baseToGet;
	var exp = new EReg("(\\S*)\\.","");
	if(exp.match(js_node_Path.basename(path))) {
		baseToGet = exp.matched(1);
		if(baseToGet.length > 1 && baseToGet.indexOf("*") > 0) throw new js__$Boot_HaxeError("Advanced search is currently unsupported, use basic [*.*] or [*.ext]");
	} else baseToGet = "*";
	var allfiles = js_node_Fs.readdirSync(js_node_Path.normalize(basePath));
	var stats;
	var _g = 0;
	while(_g < allfiles.length) {
		var i = allfiles[_g];
		++_g;
		try {
			stats = js_node_Fs.statSync(js_node_Path.join(basePath,i));
		} catch( e ) {
			if (e instanceof js__$Boot_HaxeError) e = e.val;
			continue;
		}
		if(stats.isFile()) {
			if(baseToGet != "*") {
				if(exp.match(i)) {
					if(baseToGet != exp.matched(1)) continue;
				} else continue;
			}
			if(extToGet == "*") {
				fileList.push(js_node_Path.join(basePath,i));
				continue;
			}
			if(extToGet == ((function($this) {
				var $r;
				var _this = js_node_Path.extname(i);
				$r = HxOverrides.substr(_this,1,null);
				return $r;
			}(this))).toLowerCase()) {
				fileList.push(js_node_Path.join(basePath,i));
				continue;
			}
		}
	}
	return fileList;
};
djNode_tools_FileTool.getFileExt = function(file) {
	return ((function($this) {
		var $r;
		var _this = js_node_Path.extname(file);
		$r = HxOverrides.substr(_this,1,null);
		return $r;
	}(this))).toLowerCase();
};
djNode_tools_FileTool.getPathNoExt = function(file) {
	return js_node_Path.join(js_node_Path.parse(file).dir,js_node_Path.parse(file).name);
};
var djNode_tools_LOG = function() { };
djNode_tools_LOG.__name__ = ["djNode","tools","LOG"];
djNode_tools_LOG.init = function() {
	if(djNode_tools_LOG._isInited) return;
	djNode_tools_LOG._isInited = true;
	djNode_tools_LOG.messages = [];
	djNode_tools_LOG.messageTypes = [];
	djNode_tools_LOG.messageTypes[0] = "DEBUG";
	djNode_tools_LOG.messageTypes[1] = "INFO";
	djNode_tools_LOG.messageTypes[2] = "WARN";
	djNode_tools_LOG.messageTypes[3] = "ERROR";
	djNode_tools_LOG.messageTypes[4] = "FATAL";
	if(djNode_tools_LOG.logFile != null) djNode_tools_LOG.setLogFile(djNode_tools_LOG.logFile);
	if(djNode_tools_LOG.flag_socket_log) djNode_tools_LOG.setSocketLogging();
};
djNode_tools_LOG.getLog = function() {
	return djNode_tools_LOG.messages;
};
djNode_tools_LOG.end = function() {
	if(djNode_tools_LOG.logFile != null && djNode_tools_LOG.flag_realtime_file == false) {
		var _g = 0;
		var _g1 = djNode_tools_LOG.messages;
		while(_g < _g1.length) {
			var i = _g1[_g];
			++_g;
			djNode_tools_LOG.push_File(i);
		}
	}
	if(djNode_tools_LOG.flag_socket_log) djNode_tools_LOG.io.close();
};
djNode_tools_LOG.log = function(message,level,pos) {
	if(level == null) level = 1;
	if(level < djNode_tools_LOG.logLevel) return;
	var logmsg = { pos : pos, log : message, level : level};
	if(djNode_tools_LOG.flag_keep_in_memory) {
		if(djNode_tools_LOG.messages.length == djNode_tools_LOG.param_memory_buffer) djNode_tools_LOG.messages.shift();
		djNode_tools_LOG.messages.push(logmsg);
	}
	if(djNode_tools_LOG.flag_socket_log) djNode_tools_LOG.io.sockets.emit("logText",{ data : logmsg.log, pos : logmsg.pos, level : logmsg.level});
	if(djNode_tools_LOG.flag_realtime_file && djNode_tools_LOG.logFile != null) djNode_tools_LOG.push_File(logmsg);
	if(djNode_tools_LOG.onLog != null) djNode_tools_LOG.onLog(logmsg);
};
djNode_tools_LOG.logObj = function(obj,level,pos) {
	if(level == null) level = 1;
	if(level < djNode_tools_LOG.logLevel) return;
	if(djNode_tools_LOG.flag_socket_log) djNode_tools_LOG.io.sockets.emit("logObj",{ data : obj, pos : pos, level : level});
	if(djNode_tools_LOG.flag_realtime_file && djNode_tools_LOG.logFile != null) djNode_tools_LOG.push_File({ level : level, pos : pos, log : "---- OBJECT ----\n" + Std.string(obj)});
	if(djNode_tools_LOG.onLog != null) djNode_tools_LOG.onLog({ pos : pos, level : level, log : "Logged an object"});
};
djNode_tools_LOG.log_ = function(text,level) {
	if(level == null) level = 1;
};
djNode_tools_LOG.setSocketLogging = function(port) {
	if(port == null) port = 80;
	if(djNode_tools_LOG.io != null) return;
	djNode_tools_LOG.io = require("socket.io").listen(port);
	djNode_tools_LOG.log("Socket, Listening to port " + port,null,{ fileName : "LOG.hx", lineNumber : 183, className : "djNode.tools.LOG", methodName : "setSocketLogging"});
	djNode_tools_LOG.io.sockets.on("connection",function(socket) {
		djNode_tools_LOG.log("Socket, Connected to client",null,{ fileName : "LOG.hx", lineNumber : 186, className : "djNode.tools.LOG", methodName : "setSocketLogging"});
		socket.on("disconnect",function() {
			djNode_tools_LOG.log("Socket, Disconnected from client",null,{ fileName : "LOG.hx", lineNumber : 189, className : "djNode.tools.LOG", methodName : "setSocketLogging"});
		});
		socket.emit("maxLines",djNode_tools_LOG.param_memory_buffer);
		if(djNode_tools_LOG.messages.length > 0) {
			var _g = 0;
			var _g1 = djNode_tools_LOG.messages;
			while(_g < _g1.length) {
				var i = _g1[_g];
				++_g;
				djNode_tools_LOG.io.sockets.emit("logText",{ data : i.log, pos : i.pos, level : i.level});
			}
		}
	});
};
djNode_tools_LOG.push_SocketText = function(l) {
	djNode_tools_LOG.io.sockets.emit("logText",{ data : l.log, pos : l.pos, level : l.level});
};
djNode_tools_LOG.push_SocketObj = function(data,level,pos) {
	if(level == null) level = 0;
	djNode_tools_LOG.io.sockets.emit("logObj",{ data : data, pos : pos, level : level});
};
djNode_tools_LOG.push_File = function(log) {
	var m = "(" + djNode_tools_LOG.messageTypes[log.level] + ") " + log.pos.lineNumber + ":" + log.pos.fileName + " [ " + log.pos.className + " ]" + " - " + log.log + "\n";
	js_node_Fs.appendFileSync(djNode_tools_LOG.logFile,m,"utf8");
};
djNode_tools_LOG.setLogFile = function(filename,realtime_update) {
	djNode_tools_LOG.logFile = filename;
	if(realtime_update != null) djNode_tools_LOG.flag_realtime_file = realtime_update;
	try {
		var fileHeader;
		fileHeader = " - LOG -\n" + " -------\n" + " - " + djNode_tools_LOG.logFile + "\n" + " - Created: " + (function($this) {
			var $r;
			var _this = new Date();
			$r = HxOverrides.dateStr(_this);
			return $r;
		}(this)) + "\n" + " - App: " + js_node_Path.basename(process.argv[1]) + "\n" + " ---------------------------------------------------\n\n";
		js_node_Fs.writeFileSync(djNode_tools_LOG.logFile,fileHeader,"utf8");
	} catch( e ) {
		if (e instanceof js__$Boot_HaxeError) e = e.val;
		djNode_tools_LOG.log("Could not create logfile - " + djNode_tools_LOG.logFile,3,{ fileName : "LOG.hx", lineNumber : 257, className : "djNode.tools.LOG", methodName : "setLogFile"});
		djNode_tools_LOG.logFile = null;
	}
	if(djNode_tools_LOG.flag_realtime_file) {
		if(djNode_tools_LOG.messages.length > 0 && djNode_tools_LOG.logFile != null) {
			var _g = 0;
			var _g1 = djNode_tools_LOG.messages;
			while(_g < _g1.length) {
				var i = _g1[_g];
				++_g;
				djNode_tools_LOG.push_File(i);
			}
		}
	}
};
djNode_tools_LOG.timeStart = function() {
	djNode_tools_LOG._t = new Date().getTime();
};
djNode_tools_LOG.timeGet = function() {
	return Std["int"](new Date().getTime() - djNode_tools_LOG._t);
};
var djNode_tools_Sequencer = function(_callback) {
	this.currentStep = 0;
	this.timerInt = null;
	this.timer = null;
	this.callback = null;
	this.callback = _callback;
};
djNode_tools_Sequencer.__name__ = ["djNode","tools","Sequencer"];
djNode_tools_Sequencer.prototype = {
	stop: function() {
		this.currentStep = 0;
		global.clearTimeout(this.timer);
		this.timer = null;
	}
	,next: function(seconds) {
		this.nextMS(seconds * 1000 | 0);
	}
	,nextMS: function(msDelay) {
		if(msDelay > 0) {
			if(this.timer != null) {
				global.clearTimeout(this.timer);
				this.timer = null;
			}
			this.timer = global.setTimeout($bind(this,this.onTimer),msDelay);
		} else this.onTimer();
	}
	,onTimer: function() {
		global.clearTimeout(this.timer);
		this.timer = null;
		this.currentStep++;
		this.callback(this.currentStep);
	}
	,doXTimes: function(times,delay,callbackEnd) {
		var _g = this;
		var currentStep = 0;
		this.timerInt = global.setInterval(function() {
			currentStep++;
			if(currentStep > times) {
				global.clearInterval(_g.timerInt);
				_g.timerInt = null;
				if(callbackEnd != null) callbackEnd();
				return;
			}
			_g.callback(currentStep);
		},delay);
	}
	,__class__: djNode_tools_Sequencer
};
var djNode_tools_StrTool = function() { };
djNode_tools_StrTool.__name__ = ["djNode","tools","StrTool"];
djNode_tools_StrTool.bytesToMBStr = function(bytes) {
	return Std.string(Math.ceil(bytes / 1048576));
};
djNode_tools_StrTool.padString = function(str,length,align) {
	if(align == null) align = "left";
	var b = length - str.length;
	if(b == 0) return str;
	if(b < 0) return str.substring(0,length - 1) + "~";
	if(align != null) switch(align) {
	case "left":
		str = StringTools.rpad(str," ",length);
		break;
	case "right":
		str = StringTools.lpad(str," ",length);
		break;
	case "center":
		var _l = Math.ceil(b / 2);
		var _r = Math.floor(b / 2);
		str = StringTools.rpad(""," ",_l) + str + StringTools.rpad(""," ",_r);
		break;
	}
	return str;
};
djNode_tools_StrTool.splitToLines = function(str,width) {
	str = new EReg("(\n)","g").replace(str," #nl# ");
	str = new EReg("(\\s|\t)","g").replace(str," ");
	var ar = str.split(" ");
	var result = [];
	var f = 0;
	var fmax = ar.length;
	var clen = 0;
	var line = "";
	var _ll = 0;
	var ___ffpush = function(s) {
		result.push(s);
		clen = 0;
		line = "";
	};
	do {
		if(ar[f] == "#nl#") {
			___ffpush(line);
			continue;
		}
		_ll = ar[f].length;
		if(_ll + clen < width) {
			line += ar[f] + " ";
			clen += _ll + 1;
		} else if(_ll + clen > width) {
			if(clen > 0) {
				result.push(line);
				line = ar[f] + " ";
				clen = _ll + 1;
			} else {
				line = ar[f].substring(0,width - 1) + "~";
				___ffpush(line);
			}
		} else ___ffpush(line + ar[f]);
	} while(++f < fmax);
	if(clen > 0) ___ffpush(line);
	return result;
};
djNode_tools_StrTool.repeatStr = function(length,$char) {
	var ar = [];
	while(length-- > 0) ar.push($char);
	return ar.join("");
};
djNode_tools_StrTool.loopString = function(source,length,offset) {
	var str = "";
	var _loopCounter = 0;
	while(_loopCounter < length) {
		str += source.charAt((_loopCounter + offset) % source.length);
		_loopCounter++;
	}
	return str;
};
var haxe_IMap = function() { };
haxe_IMap.__name__ = ["haxe","IMap"];
var haxe__$Int64__$_$_$Int64 = function(high,low) {
	this.high = high;
	this.low = low;
};
haxe__$Int64__$_$_$Int64.__name__ = ["haxe","_Int64","___Int64"];
haxe__$Int64__$_$_$Int64.prototype = {
	__class__: haxe__$Int64__$_$_$Int64
};
var haxe_ds__$StringMap_StringMapIterator = function(map,keys) {
	this.map = map;
	this.keys = keys;
	this.index = 0;
	this.count = keys.length;
};
haxe_ds__$StringMap_StringMapIterator.__name__ = ["haxe","ds","_StringMap","StringMapIterator"];
haxe_ds__$StringMap_StringMapIterator.prototype = {
	hasNext: function() {
		return this.index < this.count;
	}
	,next: function() {
		return this.map.get(this.keys[this.index++]);
	}
	,__class__: haxe_ds__$StringMap_StringMapIterator
};
var haxe_ds_StringMap = function() {
	this.h = { };
};
haxe_ds_StringMap.__name__ = ["haxe","ds","StringMap"];
haxe_ds_StringMap.__interfaces__ = [haxe_IMap];
haxe_ds_StringMap.prototype = {
	set: function(key,value) {
		if(__map_reserved[key] != null) this.setReserved(key,value); else this.h[key] = value;
	}
	,get: function(key) {
		if(__map_reserved[key] != null) return this.getReserved(key);
		return this.h[key];
	}
	,exists: function(key) {
		if(__map_reserved[key] != null) return this.existsReserved(key);
		return this.h.hasOwnProperty(key);
	}
	,setReserved: function(key,value) {
		if(this.rh == null) this.rh = { };
		this.rh["$" + key] = value;
	}
	,getReserved: function(key) {
		if(this.rh == null) return null; else return this.rh["$" + key];
	}
	,existsReserved: function(key) {
		if(this.rh == null) return false;
		return this.rh.hasOwnProperty("$" + key);
	}
	,remove: function(key) {
		if(__map_reserved[key] != null) {
			key = "$" + key;
			if(this.rh == null || !this.rh.hasOwnProperty(key)) return false;
			delete(this.rh[key]);
			return true;
		} else {
			if(!this.h.hasOwnProperty(key)) return false;
			delete(this.h[key]);
			return true;
		}
	}
	,arrayKeys: function() {
		var out = [];
		for( var key in this.h ) {
		if(this.h.hasOwnProperty(key)) out.push(key);
		}
		if(this.rh != null) {
			for( var key in this.rh ) {
			if(key.charCodeAt(0) == 36) out.push(key.substr(1));
			}
		}
		return out;
	}
	,iterator: function() {
		return new haxe_ds__$StringMap_StringMapIterator(this,this.arrayKeys());
	}
	,__class__: haxe_ds_StringMap
};
var haxe_io_Error = { __ename__ : true, __constructs__ : ["Blocked","Overflow","OutsideBounds","Custom"] };
haxe_io_Error.Blocked = ["Blocked",0];
haxe_io_Error.Blocked.toString = $estr;
haxe_io_Error.Blocked.__enum__ = haxe_io_Error;
haxe_io_Error.Overflow = ["Overflow",1];
haxe_io_Error.Overflow.toString = $estr;
haxe_io_Error.Overflow.__enum__ = haxe_io_Error;
haxe_io_Error.OutsideBounds = ["OutsideBounds",2];
haxe_io_Error.OutsideBounds.toString = $estr;
haxe_io_Error.OutsideBounds.__enum__ = haxe_io_Error;
haxe_io_Error.Custom = function(e) { var $x = ["Custom",3,e]; $x.__enum__ = haxe_io_Error; $x.toString = $estr; return $x; };
var haxe_io_FPHelper = function() { };
haxe_io_FPHelper.__name__ = ["haxe","io","FPHelper"];
haxe_io_FPHelper.i32ToFloat = function(i) {
	var sign = 1 - (i >>> 31 << 1);
	var exp = i >>> 23 & 255;
	var sig = i & 8388607;
	if(sig == 0 && exp == 0) return 0.0;
	return sign * (1 + Math.pow(2,-23) * sig) * Math.pow(2,exp - 127);
};
haxe_io_FPHelper.floatToI32 = function(f) {
	if(f == 0) return 0;
	var af;
	if(f < 0) af = -f; else af = f;
	var exp = Math.floor(Math.log(af) / 0.6931471805599453);
	if(exp < -127) exp = -127; else if(exp > 128) exp = 128;
	var sig = Math.round((af / Math.pow(2,exp) - 1) * 8388608) & 8388607;
	return (f < 0?-2147483648:0) | exp + 127 << 23 | sig;
};
haxe_io_FPHelper.i64ToDouble = function(low,high) {
	var sign = 1 - (high >>> 31 << 1);
	var exp = (high >> 20 & 2047) - 1023;
	var sig = (high & 1048575) * 4294967296. + (low >>> 31) * 2147483648. + (low & 2147483647);
	if(sig == 0 && exp == -1023) return 0.0;
	return sign * (1.0 + Math.pow(2,-52) * sig) * Math.pow(2,exp);
};
haxe_io_FPHelper.doubleToI64 = function(v) {
	var i64 = haxe_io_FPHelper.i64tmp;
	if(v == 0) {
		i64.low = 0;
		i64.high = 0;
	} else {
		var av;
		if(v < 0) av = -v; else av = v;
		var exp = Math.floor(Math.log(av) / 0.6931471805599453);
		var sig;
		var v1 = (av / Math.pow(2,exp) - 1) * 4503599627370496.;
		sig = Math.round(v1);
		var sig_l = sig | 0;
		var sig_h = sig / 4294967296.0 | 0;
		i64.low = sig_l;
		i64.high = (v < 0?-2147483648:0) | exp + 1023 << 20 | sig_h;
	}
	return i64;
};
var js__$Boot_HaxeError = function(val) {
	Error.call(this);
	this.val = val;
	this.message = String(val);
	if(Error.captureStackTrace) Error.captureStackTrace(this,js__$Boot_HaxeError);
};
js__$Boot_HaxeError.__name__ = ["js","_Boot","HaxeError"];
js__$Boot_HaxeError.__super__ = Error;
js__$Boot_HaxeError.prototype = $extend(Error.prototype,{
	__class__: js__$Boot_HaxeError
});
var js_Boot = function() { };
js_Boot.__name__ = ["js","Boot"];
js_Boot.getClass = function(o) {
	if((o instanceof Array) && o.__enum__ == null) return Array; else {
		var cl = o.__class__;
		if(cl != null) return cl;
		var name = js_Boot.__nativeClassName(o);
		if(name != null) return js_Boot.__resolveNativeClass(name);
		return null;
	}
};
js_Boot.__string_rec = function(o,s) {
	if(o == null) return "null";
	if(s.length >= 5) return "<...>";
	var t = typeof(o);
	if(t == "function" && (o.__name__ || o.__ename__)) t = "object";
	switch(t) {
	case "object":
		if(o instanceof Array) {
			if(o.__enum__) {
				if(o.length == 2) return o[0];
				var str2 = o[0] + "(";
				s += "\t";
				var _g1 = 2;
				var _g = o.length;
				while(_g1 < _g) {
					var i1 = _g1++;
					if(i1 != 2) str2 += "," + js_Boot.__string_rec(o[i1],s); else str2 += js_Boot.__string_rec(o[i1],s);
				}
				return str2 + ")";
			}
			var l = o.length;
			var i;
			var str1 = "[";
			s += "\t";
			var _g2 = 0;
			while(_g2 < l) {
				var i2 = _g2++;
				str1 += (i2 > 0?",":"") + js_Boot.__string_rec(o[i2],s);
			}
			str1 += "]";
			return str1;
		}
		var tostr;
		try {
			tostr = o.toString;
		} catch( e ) {
			if (e instanceof js__$Boot_HaxeError) e = e.val;
			return "???";
		}
		if(tostr != null && tostr != Object.toString && typeof(tostr) == "function") {
			var s2 = o.toString();
			if(s2 != "[object Object]") return s2;
		}
		var k = null;
		var str = "{\n";
		s += "\t";
		var hasp = o.hasOwnProperty != null;
		for( var k in o ) {
		if(hasp && !o.hasOwnProperty(k)) {
			continue;
		}
		if(k == "prototype" || k == "__class__" || k == "__super__" || k == "__interfaces__" || k == "__properties__") {
			continue;
		}
		if(str.length != 2) str += ", \n";
		str += s + k + " : " + js_Boot.__string_rec(o[k],s);
		}
		s = s.substring(1);
		str += "\n" + s + "}";
		return str;
	case "function":
		return "<function>";
	case "string":
		return o;
	default:
		return String(o);
	}
};
js_Boot.__interfLoop = function(cc,cl) {
	if(cc == null) return false;
	if(cc == cl) return true;
	var intf = cc.__interfaces__;
	if(intf != null) {
		var _g1 = 0;
		var _g = intf.length;
		while(_g1 < _g) {
			var i = _g1++;
			var i1 = intf[i];
			if(i1 == cl || js_Boot.__interfLoop(i1,cl)) return true;
		}
	}
	return js_Boot.__interfLoop(cc.__super__,cl);
};
js_Boot.__instanceof = function(o,cl) {
	if(cl == null) return false;
	switch(cl) {
	case Int:
		return (o|0) === o;
	case Float:
		return typeof(o) == "number";
	case Bool:
		return typeof(o) == "boolean";
	case String:
		return typeof(o) == "string";
	case Array:
		return (o instanceof Array) && o.__enum__ == null;
	case Dynamic:
		return true;
	default:
		if(o != null) {
			if(typeof(cl) == "function") {
				if(o instanceof cl) return true;
				if(js_Boot.__interfLoop(js_Boot.getClass(o),cl)) return true;
			} else if(typeof(cl) == "object" && js_Boot.__isNativeObj(cl)) {
				if(o instanceof cl) return true;
			}
		} else return false;
		if(cl == Class && o.__name__ != null) return true;
		if(cl == Enum && o.__ename__ != null) return true;
		return o.__enum__ == cl;
	}
};
js_Boot.__nativeClassName = function(o) {
	var name = js_Boot.__toStr.call(o).slice(8,-1);
	if(name == "Object" || name == "Function" || name == "Math" || name == "JSON") return null;
	return name;
};
js_Boot.__isNativeObj = function(o) {
	return js_Boot.__nativeClassName(o) != null;
};
js_Boot.__resolveNativeClass = function(name) {
	return $global[name];
};
var js_html_compat_ArrayBuffer = function(a) {
	if((a instanceof Array) && a.__enum__ == null) {
		this.a = a;
		this.byteLength = a.length;
	} else {
		var len = a;
		this.a = [];
		var _g = 0;
		while(_g < len) {
			var i = _g++;
			this.a[i] = 0;
		}
		this.byteLength = len;
	}
};
js_html_compat_ArrayBuffer.__name__ = ["js","html","compat","ArrayBuffer"];
js_html_compat_ArrayBuffer.sliceImpl = function(begin,end) {
	var u = new Uint8Array(this,begin,end == null?null:end - begin);
	var result = new ArrayBuffer(u.byteLength);
	var resultArray = new Uint8Array(result);
	resultArray.set(u);
	return result;
};
js_html_compat_ArrayBuffer.prototype = {
	slice: function(begin,end) {
		return new js_html_compat_ArrayBuffer(this.a.slice(begin,end));
	}
	,__class__: js_html_compat_ArrayBuffer
};
var js_html_compat_DataView = function(buffer,byteOffset,byteLength) {
	this.buf = buffer;
	if(byteOffset == null) this.offset = 0; else this.offset = byteOffset;
	if(byteLength == null) this.length = buffer.byteLength - this.offset; else this.length = byteLength;
	if(this.offset < 0 || this.length < 0 || this.offset + this.length > buffer.byteLength) throw new js__$Boot_HaxeError(haxe_io_Error.OutsideBounds);
};
js_html_compat_DataView.__name__ = ["js","html","compat","DataView"];
js_html_compat_DataView.prototype = {
	getInt8: function(byteOffset) {
		var v = this.buf.a[this.offset + byteOffset];
		if(v >= 128) return v - 256; else return v;
	}
	,getUint8: function(byteOffset) {
		return this.buf.a[this.offset + byteOffset];
	}
	,getInt16: function(byteOffset,littleEndian) {
		var v = this.getUint16(byteOffset,littleEndian);
		if(v >= 32768) return v - 65536; else return v;
	}
	,getUint16: function(byteOffset,littleEndian) {
		if(littleEndian) return this.buf.a[this.offset + byteOffset] | this.buf.a[this.offset + byteOffset + 1] << 8; else return this.buf.a[this.offset + byteOffset] << 8 | this.buf.a[this.offset + byteOffset + 1];
	}
	,getInt32: function(byteOffset,littleEndian) {
		var p = this.offset + byteOffset;
		var a = this.buf.a[p++];
		var b = this.buf.a[p++];
		var c = this.buf.a[p++];
		var d = this.buf.a[p++];
		if(littleEndian) return a | b << 8 | c << 16 | d << 24; else return d | c << 8 | b << 16 | a << 24;
	}
	,getUint32: function(byteOffset,littleEndian) {
		var v = this.getInt32(byteOffset,littleEndian);
		if(v < 0) return v + 4294967296.; else return v;
	}
	,getFloat32: function(byteOffset,littleEndian) {
		return haxe_io_FPHelper.i32ToFloat(this.getInt32(byteOffset,littleEndian));
	}
	,getFloat64: function(byteOffset,littleEndian) {
		var a = this.getInt32(byteOffset,littleEndian);
		var b = this.getInt32(byteOffset + 4,littleEndian);
		return haxe_io_FPHelper.i64ToDouble(littleEndian?a:b,littleEndian?b:a);
	}
	,setInt8: function(byteOffset,value) {
		if(value < 0) this.buf.a[byteOffset + this.offset] = value + 128 & 255; else this.buf.a[byteOffset + this.offset] = value & 255;
	}
	,setUint8: function(byteOffset,value) {
		this.buf.a[byteOffset + this.offset] = value & 255;
	}
	,setInt16: function(byteOffset,value,littleEndian) {
		this.setUint16(byteOffset,value < 0?value + 65536:value,littleEndian);
	}
	,setUint16: function(byteOffset,value,littleEndian) {
		var p = byteOffset + this.offset;
		if(littleEndian) {
			this.buf.a[p] = value & 255;
			this.buf.a[p++] = value >> 8 & 255;
		} else {
			this.buf.a[p++] = value >> 8 & 255;
			this.buf.a[p] = value & 255;
		}
	}
	,setInt32: function(byteOffset,value,littleEndian) {
		this.setUint32(byteOffset,value,littleEndian);
	}
	,setUint32: function(byteOffset,value,littleEndian) {
		var p = byteOffset + this.offset;
		if(littleEndian) {
			this.buf.a[p++] = value & 255;
			this.buf.a[p++] = value >> 8 & 255;
			this.buf.a[p++] = value >> 16 & 255;
			this.buf.a[p++] = value >>> 24;
		} else {
			this.buf.a[p++] = value >>> 24;
			this.buf.a[p++] = value >> 16 & 255;
			this.buf.a[p++] = value >> 8 & 255;
			this.buf.a[p++] = value & 255;
		}
	}
	,setFloat32: function(byteOffset,value,littleEndian) {
		this.setUint32(byteOffset,haxe_io_FPHelper.floatToI32(value),littleEndian);
	}
	,setFloat64: function(byteOffset,value,littleEndian) {
		var i64 = haxe_io_FPHelper.doubleToI64(value);
		if(littleEndian) {
			this.setUint32(byteOffset,i64.low);
			this.setUint32(byteOffset,i64.high);
		} else {
			this.setUint32(byteOffset,i64.high);
			this.setUint32(byteOffset,i64.low);
		}
	}
	,__class__: js_html_compat_DataView
};
var js_html_compat_Uint8Array = function() { };
js_html_compat_Uint8Array.__name__ = ["js","html","compat","Uint8Array"];
js_html_compat_Uint8Array._new = function(arg1,offset,length) {
	var arr;
	if(typeof(arg1) == "number") {
		arr = [];
		var _g = 0;
		while(_g < arg1) {
			var i = _g++;
			arr[i] = 0;
		}
		arr.byteLength = arr.length;
		arr.byteOffset = 0;
		arr.buffer = new js_html_compat_ArrayBuffer(arr);
	} else if(js_Boot.__instanceof(arg1,js_html_compat_ArrayBuffer)) {
		var buffer = arg1;
		if(offset == null) offset = 0;
		if(length == null) length = buffer.byteLength - offset;
		if(offset == 0) arr = buffer.a; else arr = buffer.a.slice(offset,offset + length);
		arr.byteLength = arr.length;
		arr.byteOffset = offset;
		arr.buffer = buffer;
	} else if((arg1 instanceof Array) && arg1.__enum__ == null) {
		arr = arg1.slice();
		arr.byteLength = arr.length;
		arr.byteOffset = 0;
		arr.buffer = new js_html_compat_ArrayBuffer(arr);
	} else throw new js__$Boot_HaxeError("TODO " + Std.string(arg1));
	arr.subarray = js_html_compat_Uint8Array._subarray;
	arr.set = js_html_compat_Uint8Array._set;
	return arr;
};
js_html_compat_Uint8Array._set = function(arg,offset) {
	var t = this;
	if(js_Boot.__instanceof(arg.buffer,js_html_compat_ArrayBuffer)) {
		var a = arg;
		if(arg.byteLength + offset > t.byteLength) throw new js__$Boot_HaxeError("set() outside of range");
		var _g1 = 0;
		var _g = arg.byteLength;
		while(_g1 < _g) {
			var i = _g1++;
			t[i + offset] = a[i];
		}
	} else if((arg instanceof Array) && arg.__enum__ == null) {
		var a1 = arg;
		if(a1.length + offset > t.byteLength) throw new js__$Boot_HaxeError("set() outside of range");
		var _g11 = 0;
		var _g2 = a1.length;
		while(_g11 < _g2) {
			var i1 = _g11++;
			t[i1 + offset] = a1[i1];
		}
	} else throw new js__$Boot_HaxeError("TODO");
};
js_html_compat_Uint8Array._subarray = function(start,end) {
	var t = this;
	var a = js_html_compat_Uint8Array._new(t.slice(start,end));
	a.byteOffset = start;
	return a;
};
var js_node_ChildProcess = require("child_process");
var js_node_Fs = require("fs");
var js_node_Path = require("path");
var js_node_events_EventEmitter = require("events").EventEmitter;
var js_node_buffer_Buffer = require("buffer").Buffer;
var $_, $fid = 0;
function $bind(o,m) { if( m == null ) return null; if( m.__id__ == null ) m.__id__ = $fid++; var f; if( o.hx__closures__ == null ) o.hx__closures__ = {}; else f = o.hx__closures__[m.__id__]; if( f == null ) { f = function(){ return f.method.apply(f.scope, arguments); }; f.scope = o; f.method = m; o.hx__closures__[m.__id__] = f; } return f; }
if(Array.prototype.indexOf) HxOverrides.indexOf = function(a,o,i) {
	return Array.prototype.indexOf.call(a,o,i);
};
String.prototype.__class__ = String;
String.__name__ = ["String"];
Array.__name__ = ["Array"];
Date.prototype.__class__ = Date;
Date.__name__ = ["Date"];
var Int = { __name__ : ["Int"]};
var Dynamic = { __name__ : ["Dynamic"]};
var Float = Number;
Float.__name__ = ["Float"];
var Bool = Boolean;
Bool.__ename__ = ["Bool"];
var Class = { __name__ : ["Class"]};
var Enum = { };
if(Array.prototype.map == null) Array.prototype.map = function(f) {
	var a = [];
	var _g1 = 0;
	var _g = this.length;
	while(_g1 < _g) {
		var i = _g1++;
		a[i] = f(this[i]);
	}
	return a;
};
var __map_reserved = {}
var ArrayBuffer = $global.ArrayBuffer || js_html_compat_ArrayBuffer;
if(ArrayBuffer.prototype.slice == null) ArrayBuffer.prototype.slice = js_html_compat_ArrayBuffer.sliceImpl;
var DataView = $global.DataView || js_html_compat_DataView;
var Uint8Array = $global.Uint8Array || js_html_compat_Uint8Array._new;
CDC.AUTHORNAME = "JohnDimi, twitter@jondmt";
CDC.PROGRAM_NAME = "CD Crush";
CDC.PROGRAM_VERSION = "1.1";
CDC.PROGRAM_SHORT_DESC = "Dramatically reduce the filesize of CD image games";
CDC.CDCRUSH_SETTINGS = "crushdata.json";
CDC.CDCRUSH_EXTENSION = "arc";
CDC.QUALITY_DEFAULT = 2;
CDC.audioQualityInfo = ["Ogg Vorbis, 96kbps VBR","Ogg Vorbis, 128kbps VBR","Ogg Vorbis, 196kbps VBR","FLAC, Lossless"];
CDC.simulatedRun = false;
djNode_task_Task.UID_ = 0;
djNode_Graphics._isInited = false;
djNode_Graphics.colorBG = "black";
djNode_Graphics.colorFG = "white";
djNode_Terminal.ESCAPE_SEQ = "\x1B[";
djNode_Terminal._BOLD = "\x1B[1m";
djNode_Terminal._DIM = "\x1B[2m";
djNode_Terminal._UNDERL = "\x1B[4m";
djNode_Terminal._BLINK = "\x1B[5m";
djNode_Terminal._HIDDEN = "\x1B[8m";
djNode_Terminal._RESET_ALL = "\x1B[0m";
djNode_Terminal._RESET_FG = "\x1B[39m";
djNode_Terminal._RESET_BG = "\x1B[49m";
djNode_Terminal._RESET_BOLD = "\x1B[21m";
djNode_Terminal._RESET_DIM = "\x1B[22m";
djNode_Terminal._RESET_UNDERL = "\x1B[24m";
djNode_Terminal._RESET_BLINK = "\x1B[25m";
djNode_Terminal._RESET_HIDDEN = "\x1B[28m";
djNode_Terminal.AVAIL_COLORS = ["black","white","gray","darkgray","red","darkred","green","darkgreen","blue","darkblue","cyan","darkcyan","magenta","darkmagenta","yellow","darkyellow"];
djNode_Terminal.DEFAULT_LINE_WIDTH = 50;
djNode_Terminal.DEFAULT_LINE_SYMBOL = "-";
djNode_Terminal.LIST_SYMBOL = "*";
djNode_Terminal.H1_SYMBOL = "#";
djNode_Terminal.H2_SYMBOL = "+";
djNode_Terminal.H3_SYMBOL = "=";
djNode_app_EcmTools.win32_ecm = "ecm.exe";
djNode_app_EcmTools.win32_unecm = "unecm.exe";
djNode_app_EcmTools.linux_ecm = "ecm-compress";
djNode_app_EcmTools.linux_unecm = "ecm-uncompress";
djNode_file_FileCutter.BUFFERSIZE = 65536;
djNode_file_FileJoiner.BUFFERSIZE = 65536;
djNode_tools_LOG._isInited = false;
djNode_tools_LOG.logLevel = 0;
djNode_tools_LOG.flag_realtime_file = true;
djNode_tools_LOG.flag_socket_log = true;
djNode_tools_LOG.flag_keep_in_memory = true;
djNode_tools_LOG.param_memory_buffer = 8192;
haxe_io_FPHelper.i64tmp = (function($this) {
	var $r;
	var x = new haxe__$Int64__$_$_$Int64(0,0);
	$r = x;
	return $r;
}(this));
js_Boot.__toStr = {}.toString;
js_html_compat_Uint8Array.BYTES_PER_ELEMENT = 1;
Main.main();
})(typeof console != "undefined" ? console : {log:function(){}}, typeof window != "undefined" ? window : typeof global != "undefined" ? global : typeof self != "undefined" ? self : this);

//# sourceMappingURL=app.js.map