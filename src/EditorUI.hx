class EditorUI extends SiteProcess {
	var ace : aceEditor.AceEditor;

	public function new() {
		super("editor");

		ace = aceEditor.AceEditor.edit("ace");
		ace.setTheme("ace/theme/solarized-light");
		ace.session.setMode("ace/mode/randomizer");
		ace.on("change", ()->onChange());
		ace.commands.addCommand({
			name: "Save",
			bindKey: { win:"Ctrl-s", mac:"Command-s" },
			exec: (e)->save(),
		});
		ace.focus();

		setContent(app.getCurrentFileContent());

		jRoot.find(".close").click(_->app.closeEditor());
		jRoot.find(".save").click(_->save());
		updateToolbar();

		markSaved();
	}

	function updateToolbar() {
		var jDelete = jRoot.find(".delete");
		jDelete.off();
		if( app.isInternal(curFileId) )
			jDelete.hide();
		else
			jDelete.show().click(_->{
				if( js.Browser.window.confirm("This will delete the file from browser storage!\nTHERE IS NO TURNING BACK!") )
					app.deleteFile(curFileId);
			});

	}

	override function onDispose() {
		super.onDispose();
		ace.destroy();
		jRoot.find("#ace").off().remove();
		ace = null;
	}

	function markSaved() {
		jRoot.find(".save").prop("disabled", true).text("Saved.");
	}

	function markUnsaved() {
		jRoot.find(".save").prop("disabled", false).text("Save");
	}

	function onChange() {
		markUnsaved();
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
		markSaved();
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
		var cursor = ace.getCursorPosition();
		ace.setValue(raw, -1);
		ace.moveCursorTo(cursor.row, cursor.column);
		delayer.cancelById("autoSave");
		ace.session.getUndoManager().reset();
		markSaved();
	}

	override function onFileChanged(raw:String) {
		super.onFileChanged(raw);
		if( !ignoreNextChangeEvent)
			setContent(raw);
		updateToolbar();
		ignoreNextChangeEvent = false;
	}
}