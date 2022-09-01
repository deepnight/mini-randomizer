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
	public var templates : Map<String,String>;
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

		// Load embed files
		internalFiles = FileManager.getAllFiles("txt");
		templates = FileManager.getAllFiles("html", "tpl");

		// Init local storage
		storage = dn.data.LocalStorage.createJsonStorage("settings");
		loadSettings();
		saveSettings();

		// Init select
		jSelect = jBody.find("#files");
		updateSelect();

		// Menu buttons
		jMenu.find(".edit").click( _->toggleEditor() );
		jMenu.find(".new").click( _->{
			closeEditor();
			var name = js.Browser.window.prompt("Enter new file name:");
			if( name==null )
				return;
			var reg = ~/[^a-z0-9_-]/gim;
			name = reg.replace(name, "_");
			notify("New file: "+name);
			settings.savedFiles.push({ id:name, raw:"" });
			setActiveFile(name);
			openEditor();
		} );

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
	}

	public function getTemplate(name:String) : Null<String> {
		for(t in templates.keyValueIterator()) {
			var fp = dn.FilePath.fromFile(t.key);
			if( fp.fileName==name )
				return t.value;
		}
		return null;
	}

	public function updateSelect() {
		jSelect.empty().off();
		if( settings.curFileId==null )
			jSelect.append('<option value="">-- Pick one --</option>');

		for(fid in getAllFileIds()) {
			var fp = dn.FilePath.fromFile(fid);
			var prefix = isInternal(fid) ? "[internal] " : "";
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
				f.raw = raw;
				found = true;
				break;
			}

		// New save
		if( !found )
			settings.savedFiles.push({ id:fileId, raw:raw });

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

	public function isInternal(fileId:String) {
		return dn.FilePath.extractDirectoryWithoutSlash(fileId, true) == "embed";
	}

	public function isSavedLocally(fileId:String) {
		for(f in settings.savedFiles)
			if( f.id==fileId )
				return true;
		return false;
	}

	public function deleteFile(fileId:String) {
		if( isInternal(fileId) )
			return false;

		for(f in settings.savedFiles)
			if( f.id==fileId ) {
				settings.savedFiles.remove(f);
				if( settings.curFileId==fileId )
					setActiveFile(null);
				return true;
			}

		return false;
	}

	public function getFile(fileId:String) : Null<String> {
		var raw : String = null;
		for(f in settings.savedFiles)
			if( f.id==fileId )
				return f.raw;

		return internalFiles.get(fileId);
	}

	public function getCurrentFileContent() {
		return getFile(settings.curFileId);
	}

	public function loadSettings() {
		var def : Settings = {
			curFileId: null,
			savedFiles: [],
		}
		settings = storage.readObject(def);

		for(f in settings.savedFiles)
			f.raw = unescape(f.raw);
	}

	public function saveSettings() {
		var copy : Settings = haxe.Unserializer.run( haxe.Serializer.run(settings) );
		for(f in copy.savedFiles)
			f.raw = escape(f.raw);

		storage.writeObject(copy);
	}

	public function setActiveFile(fileId:String) {
		if( fileId==null )
			closeEditor();

		var raw = getFile(fileId);

		settings.curFileId = fileId;
		saveSettings();
		updateSelect();

		for(p in SiteProcess.ALL)
			p.onFileChanged(raw);
	}

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