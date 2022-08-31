import aceEditor.AceEditor;

typedef Settings = {
	var curFileId: String;
	var savedFiles: Array<{id:String, raw:String}>;
}

class App extends dn.Process {
	public static var ME : App;

	public var jDoc : J;
	public var jSite : J;
	public var jBody : J;
	public var jSelect : J;
	// public var jMainToolbar : J;
	// public var jRandButtons : J;
	// public var jOutput : J;
	var storage : dn.data.LocalStorage;
	public var settings : Settings;
	// var curEditor : Null<AceEditor>;
	var internalFiles : Map<String,String>;

	public function new() {
		super();

		ME = this;
		jDoc = new J( js.Browser.document );
		jBody = new J("body");
		jSite = jBody.find("#site");

		// jMainToolbar = jBody.find("#mainToolbar");
		// jRandButtons = jBody.find("#randButtons");
		// jOutput = jBody.find("#output");

		// Load all files content from last compilation
		internalFiles = FileManager.getAllFiles();

		// Init cookie
		storage = dn.data.LocalStorage.createJsonStorage("settings");
		settings = storage.readObject({
			curFileId: null,
			savedFiles: [],
		});
		saveSettings();

		// Init select
		jSelect = jBody.find("#files");
		jSelect.append('<option value=""/>');
		for(fid in getAllFileIds())
			jSelect.append('<option value="${fid}">${dn.FilePath.extractFileName(fid)} ${isSavedLocally(fid)?"*":""}</option>');
		jSelect.change( _->{
			var fid = jSelect.val();
			useFile( fid=="" ? null : fid );
		});
		
		new RandomUI();

		// Reload last file
		if( settings.curFileId!=null ) {
			if( getFile(settings.curFileId)==null ) {
				settings.curFileId = null;
				saveSettings();
			}
			else
				useFile( settings.curFileId );
		}


		// Edit button
		// jMainToolbar.find(".edit").click( _->setEditor( !jBody.hasClass("editing") ) );

		// Clear button
		// jMainToolbar.find(".clear").click( _->clearOutput() );
	}

	public function saveFile(fileId:String, raw:String) {
		for(f in settings.savedFiles)
			if( f.id==fileId ) {
				f.raw = raw;
				saveSettings();
				break;
			}

		settings.savedFiles.push({ id:fileId, raw:raw });
		saveSettings();
	}

	public function getAllFileIds() {
		var dones = new Map();
		var all = [];
		for(f in settings.savedFiles) {
			dones.set(f.id,true);
			all.push(f.id);
		}

		for(fid in internalFiles.keys())
			if( !dones.exists(fid) )
				all.push(fid);

		return all;
	}

	public function isSavedLocally(fileId:String) {
		for(f in settings.savedFiles)
			if( f.id==fileId )
				return true;
		return false;
	}

	function getFile(fileId:String) : Null<String> {
		var raw : String = null;
		for(f in settings.savedFiles)
			if( f.id==fileId )
				return f.raw;

		return internalFiles.get(fileId);
	}

	/*
	function setEditor(active:Bool) {
		// Kill existing editor
		if( curEditor!=null ) {
			saveEditor();

			jBody.removeClass("editing");
			curEditor.destroy();
			curEditor = null;
			jBody.find("#editor").empty();
		}

		// Create editor
		if( active ) {
			jBody.find("#editor").text( allFiles.get(settings.curFile) );
			jBody.addClass("editing");
			curEditor = AceEditor.edit("editor");
			curEditor.setTheme("ace/theme/monokai");
			curEditor.session.setMode("ace/mode/randomizer");
			curEditor.on("change", ()->saveEditor());
			curEditor.commands.addCommand({
				name: "Save",
				bindKey: { win:"Ctrl-s", mac:"Command-s" },
				exec: (e)->saveEditor(),
			});

			var jBar = jBody.find(".column.editor .toolbar");
			jBar.find(".close").click(_->setEditor(false));
			jBar.find(".reload").click(_->{
				setEditor(false);
				allFiles = FileManager.getAllFiles();
				useFile(settings.curFile);
			});
		}
	}

	function saveEditor() {
		if( curEditor!=null ) {
			allFiles.set(settings.curFile, curEditor.getValue());
			useFile(settings.curFile);
			notify("Saved.");
		}
	}
	*/

	public function saveSettings() {
		storage.writeObject(settings);
	}

	function useFile(fileId:String) {
		var raw = getFile(fileId);
		if( raw==null ) {
			notify("Failed to load "+fileId);
			return;
		}

		settings.curFileId = fileId;
		saveSettings();
		jSelect.val(settings.curFileId);

		for(p in SiteProcess.ALL)
			p.onFileChanged(raw);
		// clearOutput();
		// jRandButtons.empty();

		// if( raw==null )
		// 	return;

		// var rdata = RandomParser.run(raw);
		// new Randomizer(rdata);

	}

	/*
	public function clearOutput() {
		jOutput.empty();
	}

	public function output(str:String) {
		str = StringTools.htmlEscape(str);
		str = "<pre>" + str.split("\\n").join("</pre><pre>") + "</pre>";
		jOutput.prepend('<div class="entry">$str</div>');
	}
	*/

	override function onDispose() {
		super.onDispose();
		if( ME==this )
			ME = null;
	}


	public function notify(str:String) {
		var jNotif = jBody.find("#notif");
		jNotif.text(str);
		jNotif.stop(true).hide().slideDown(200).delay(1400).fadeOut(200);
	}
}