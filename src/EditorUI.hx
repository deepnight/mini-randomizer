class EditorUI extends SiteProcess {
	var ace : aceEditor.AceEditor;

	public function new() {
		super("editor");
		ace = aceEditor.AceEditor.edit("ace");
		ace.setTheme("ace/theme/solarized-light");
		ace.session.setMode("ace/mode/randomizer");
		ace.on("change", ()->onChange());
		setContent(app.getCurrentFileContent());

		jRoot.find(".close").click(_->app.closeEditor());
		jRoot.find(".reload").click(_->clearSave());
	}

	override function onDispose() {
		super.onDispose();
		ace.destroy();
	}

	function onChange() {
		delayer.cancelById("autoSave");
		delayer.addS("autoSave", save, 0.3);
	}

	public function checkAutoSave() {
		if( delayer.hasId("autoSave") ) {
			save();
			return true;
		}
		else
			return false;
	}

	var ignoreNextChangeEvent = false;
	function save() {
		trace("save");
		delayer.cancelById("autoSave");
		var raw = ace.getValue();
		if( raw!=app.internalFiles.get(curFileId) ) {
			ignoreNextChangeEvent = true;
			app.saveFile(curFileId, raw);
		}
	}

	function clearSave() {
		for(f in app.settings.savedFiles)
			if( f.id==curFileId ) {
				app.settings.savedFiles.remove(f);
				break;
			}
		app.setActiveFile(curFileId);
	}

	function setContent(raw:String) {
		trace("setContent");
		var cursor = ace.getCursorPosition();
		ace.setValue(raw, -1);
		ace.moveCursorTo(cursor.row, cursor.column);
		delayer.cancelById("autoSave");
		ace.session.getUndoManager().reset();
	}

	override function onFileChanged(raw:String) {
		super.onFileChanged(raw);
		if( !ignoreNextChangeEvent)
			setContent(raw);
		ignoreNextChangeEvent = false;
	}
}