class EditorUI extends SiteProcess {
	var ace : aceEditor.AceEditor;
	var jLog : J;

	public function new() {
		super("editor");

		jLog = jRoot.find(".log");

		ace = aceEditor.AceEditor.edit("ace");
		ace.setTheme("ace/theme/randomizer");
		ace.session.setMode("ace/mode/randomizer");

		ace.on("change", ()->onChange());

		ace.commands.removeCommand("removeline",true);
		ace.commands.removeCommand("duplicateSelection",true);
		ace.commands.addCommand({ bindKey:{ win:"Ctrl-s", mac:"Command-s" }, exec: _->save() });
		ace.commands.addCommand({ bindKey:{ win:"F3" }, exec: _->ace.execCommand("find") });
		ace.commands.addCommand({ name:"Duplicate", bindKey:{ win:"ctrl-D"}, exec: _->ace.execCommand("duplicateSelection") });
		ace.commands.addCommand({ name:"Remove line", bindKey:{ win:"ctrl-shift-D"}, exec: _->ace.execCommand("removeline") });
		ace.focus();

		setContent(app.getCurrentFileContent());

		jRoot.find(".close").click(_->app.closeEditor());
		jRoot.find(".save").click(_->save());
		jRoot.find(".download").click(_->download());
		jRoot.find(".upload").click(_->notify("Not implemented yet"));
		jRoot.find(".copy").click(_->copy());
		updateToolbar();

		markSaved();
	}

	public function addLineMark(line:Int, className:String) {
		ace.session.addMarker( new aceEditor.AceEditor.AceRange(line-1, 1, line-1, 1000), "cust-"+className, "fullLine" );
	}

	public function addLog(str:String, line:Int, className:String) {
		var jLine = new J('<pre>Line ${line} -- <strong>${str}</strong></pre>');
		jLine.addClass(className);
		jLine.click(_->{
			app.openEditor();
			app.editor.gotoLine(line);
		});
		jLog.append(jLine);
	}

	public function addErrors(errors:Array<RandomParser.Error>) {
		// Show in editor
		ace.session.setAnnotations(
			errors.map( e->{ row:e.line-1, text:e.err, type:"error", column:0 })
		);
		for(e in errors)
			addLineMark(e.line, "error");

		// Errors listing
		for(e in errors) {
			addLog(e.err, e.line, "error");
			jLog.addClass("errors");
		}
	}

	public function clearLog() {
		jLog.removeClass("errors");
		jLog.empty();

		ace.session.clearAnnotations();

		var markers = ace.session.getMarkers();
		for( k in Reflect.fields(markers) ) {
			var m : aceEditor.AceEditor.MarkerLike = Reflect.field(markers, k);
			if( m.clazz.indexOf("cust-")==0 )
				ace.session.removeMarker(m.id);
		}

		jRoot.find(".errors").empty();
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
		jRoot.find(".save").prop("disabled", true).text("✔️ Saved.");
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