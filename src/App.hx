import aceEditor.AceEditor;

typedef Settings = {
	var curFile: String;
}

class App extends dn.Process {
	public static var ME : App;

	public var jBody : J;
	public var jMainToolbar : J;
	public var jRandButtons : J;
	public var jOutput : J;
	var storage : dn.data.LocalStorage;
	var settings : Settings;
	var curEditor : Null<AceEditor>;
	var allFiles : Map<String,String>;

	public function new() {
		super();

		ME = this;
		jBody = new J("body");
		jMainToolbar = jBody.find("#mainToolbar");
		jRandButtons = jBody.find("#randButtons");
		jOutput = jBody.find("#output");

		// Init cookie
		storage = dn.data.LocalStorage.createJsonStorage("settings");
		settings = storage.readObject({
			curFile: null,
		});
		saveSettings();

		// Load all files content
		allFiles = FileManager.getAllFiles();

		// Init select
		var jSelect = jBody.find("#files");
		jSelect.append('<option value=""/>');
		for(f in allFiles.keys())
			jSelect.append('<option value="${f}">${dn.FilePath.extractFileName(f)}</option>');
		jSelect.change( _->{
			var f = jSelect.val();
			setEditor(false);
			useFile( f=="" ? null : f );
		});

		// Reload last file
		if( settings.curFile!=null ) {
			if( !allFiles.exists(settings.curFile) ) {
				settings.curFile = null;
				saveSettings();
			}
			else {
				jSelect.val(settings.curFile);
				useFile( settings.curFile );
			}
		}

		// Edit button
		jMainToolbar.find(".edit").click( _->setEditor( !jBody.hasClass("editing") ) );

		// Clear button
		jMainToolbar.find(".clear").click( _->clearOutput() );
	}


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

	function saveSettings() {
		storage.writeObject(settings);
	}

	function useFile(f:String) {
		var raw = allFiles.get(f);
		clearOutput();
		jRandButtons.empty();

		if( raw==null )
			return;

		var rdata = RandomParser.run(raw);
		new Randomizer(rdata);

		settings.curFile = f;
		saveSettings();
	}

	public function clearOutput() {
		jOutput.empty();
	}

	public function output(str:String) {
		str = StringTools.htmlEscape(str);
		str = "<pre>" + str.split("\\n").join("</pre><pre>") + "</pre>";
		jOutput.prepend('<div class="entry">$str</div>');
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

	override function update() {
		super.update();
	}
}