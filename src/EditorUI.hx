class EditorUI extends SiteProcess {
	var ace : aceEditor.AceEditor;

	public function new() {
		super("editor");

		ace = aceEditor.AceEditor.edit("ace");
		ace.setTheme("ace/theme/randomizer");
		ace.session.setMode("ace/mode/randomizer");

		ace.on("change", ()->onChange());

		ace.commands.addCommand({
			name: "Save",
			bindKey: { win:"Ctrl-s", mac:"Command-s" },
			exec: (e)->save(),
		});
		ace.commands.addCommand({
			name: "Search",
			bindKey: { win:"F3", mac:"" },
			exec: (e)->ace.execCommand("find"),
		});
		ace.focus();

		setContent(app.getCurrentFileContent());

		jRoot.find(".close").click(_->app.closeEditor());
		jRoot.find(".save").click(_->save());
		jRoot.find(".download").click(_->download());
		jRoot.find(".copy").click(_->copy());
		updateToolbar();

		markSaved();
	}

	public function showErrors(errors:Array<RandomParser.Error>) {
		ace.session.clearAnnotations();
		ace.session.setAnnotations(
			errors.map( e->{ row:e.line-1, text:e.err, type:"error", column:0 })
		);
	}

	public function gotoLine(l:Int) {
		ace.gotoLine(l, 0, true);
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
		ace.session.clearAnnotations();
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

	function download() {
		checkAutoSave();
		var name = curFileId+".txt";

		var jDl = new J('<a/>');
		jDl.text("test");
		jDl.attr("download", name);
		jDl.attr("href", 'data:text/plain;charset=utf-8,'+StringTools.urlEncode(app.getCurrentFileContent()));
		jBody.append(jDl);
		jDl.get(0).click();
		jDl.remove();

		notify('Downloading $name...');
	}

	function copy() {
		checkAutoSave();
		js.Browser.navigator.clipboard.writeText( app.getCurrentFileContent() );
		notify('Copied to clipboard');
	}

	override function update() {
		super.update();
		// if( !ace.isFocused() )
			// ace.focus();
	}
}