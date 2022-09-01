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
	public var jMenu : J;
	public var jSelect : J;

	public var internalFiles : Map<String,String>;
	var storage : dn.data.LocalStorage;
	public var settings : Settings;

	public var editor : Null<EditorUI>;


	public function new() {
		super();

		ME = this;
		jDoc = new J( js.Browser.document );
		jBody = new J("body");
		jSite = jBody.find("#site");
		jMenu = jBody.find("#menu");

		// Load all files content from last compilation
		internalFiles = FileManager.getAllFiles("txt");

		// Init cookie
		storage = dn.data.LocalStorage.createJsonStorage("settings");
		settings = storage.readObject({
			curFileId: null,
			savedFiles: [],
		});
		saveSettings();

		// Init select
		jSelect = jBody.find("#files");
		updateSelect();

		// Menu buttons
		jMenu.find(".edit").click( _->toggleEditor() );

		new RandomUI();

		// Reload last file
		if( settings.curFileId!=null ) {
			if( getFile(settings.curFileId)==null ) {
				settings.curFileId = null;
				saveSettings();
			}
			else
				setActiveFile( settings.curFileId );
		}


		// Edit button
		// jMainToolbar.find(".edit").click( _->setEditor( !jBody.hasClass("editing") ) );

		// Clear button
		// jMainToolbar.find(".clear").click( _->clearOutput() );
	}

	public function updateSelect() {
		jSelect.empty();
		if( settings.curFileId==null )
			jSelect.append('<option value="">-- Pick one --</option>');

		for(fid in getAllFileIds()) {
			var fp = dn.FilePath.fromFile(fid);
			var prefix = fp.directory=="embed" ? "[internal] " : "";
			jSelect.append('<option value="${fid}">$prefix ${fp.fileName}</option>');
		}
		jSelect.change( _->{
			var fid = jSelect.val();
			setActiveFile( fid=="" ? null : fid );
		});
		jSelect.val(settings.curFileId);
	}

	public function toggleEditor() {
		if( editor!=null )
			closeEditor();
		else
			openEditor();
	}

	public function openEditor() {
		if( editor==null )
			editor = new EditorUI();
	}

	public function closeEditor() {
		if( editor!=null ) {
			editor.destroy();
			editor = null;
			dn.Process.updateAll(1); // force GC
		}
	}

	public function saveFile(fileId:String, raw:String) {
		fileId = dn.FilePath.extractFileName(fileId); // remove directory

		// Overwrite existing
		var found = false;
		for(f in settings.savedFiles)
			if( f.id==fileId ) {
				f.raw = escape(raw);
				found = true;
				break;
			}

		// New save
		if( !found )
			settings.savedFiles.push({ id:fileId, raw:escape(raw) });

		saveSettings();
		setActiveFile(fileId);
	}

	function escape(raw:String) {
		raw = StringTools.replace(raw, "\\n", "<EOL>");
		raw = StringTools.replace(raw, "\n", "\\n");
		return raw;
	}

	function unescape(raw:String) {
		raw = StringTools.replace(raw, "\\n", "\n");
		raw = StringTools.replace(raw, "<EOL>", "\\n");
		return raw;
	}

	public function getAllFileIds() {
		var dones = new Map();
		var all = [];

		// Internals
		for(fid in internalFiles.keys())
			if( !dones.exists(fid) )
				all.push(fid);

		// Saved locally
		for(f in settings.savedFiles) {
			dones.set(f.id,true);
			all.push(f.id);
		}

		// all.sort( (a,b)->Reflect.compare(a,b) );

		return all;
	}

	public function isSavedLocally(fileId:String) {
		for(f in settings.savedFiles)
			if( f.id==fileId )
				return true;
		return false;
	}

	public function getFile(fileId:String) : Null<String> {
		var raw : String = null;
		for(f in settings.savedFiles)
			if( f.id==fileId )
				return unescape(f.raw);

		return internalFiles.get(fileId);
	}

	public function getCurrentFileContent() {
		return getFile(settings.curFileId);
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
				setActiveFile(settings.curFile);
			});
		}
	}

	function saveEditor() {
		if( curEditor!=null ) {
			allFiles.set(settings.curFile, curEditor.getValue());
			setActiveFile(settings.curFile);
			notify("Saved.");
		}
	}
	*/

	public function saveSettings() {
		storage.writeObject(settings);
	}

	public function setActiveFile(fileId:String) {
		var raw = getFile(fileId);
		if( raw==null ) {
			notify("Failed to load "+fileId);
			return;
		}

		settings.curFileId = fileId;
		saveSettings();
		updateSelect();

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