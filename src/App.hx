import aceEditor.AceEditor;

typedef Settings = {
	var lastFile: String;
}

class App extends dn.Process {
	public static var ME : App;

	public var jBody : J;
	public var jToolbar : J;
	public var jRandButtons : J;
	public var jOutput : J;
	var storage : dn.data.LocalStorage;
	var settings : Settings;
	var curFile : Null<String>;
	var curEditor : Null<AceEditor>;
	var allFiles : Map<String,String>;

	public function new() {
		super();

		ME = this;
		jBody = new J("body");
		jToolbar = jBody.find("#toolbar");
		jRandButtons = jBody.find("#randButtons");
		jOutput = jBody.find("#output");

		// Init cookie
		storage = dn.data.LocalStorage.createJsonStorage("settings");
		settings = storage.readObject({
			lastFile: null,
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
			useFile( f=="" ? null : f );
		});

		// Reload last file
		if( settings.lastFile!=null ) {
			if( !allFiles.exists(settings.lastFile) ) {
				settings.lastFile = curFile = null;
				saveSettings();
			}
			else {
				jSelect.val(settings.lastFile);
				useFile( settings.lastFile );
			}
	}

		// Edit button
		jToolbar.find("#edit").click(_->{
			setEditor( !jBody.hasClass("editing") );
		});
	}

	function setEditor(active:Bool) {
		var jEditor = jBody.find("#editor");
		notify("Editor: "+active);

		// Kill existing editor
		if( curEditor!=null ) {
			allFiles.set(curFile, curEditor.getValue());

			jBody.removeClass("editing");
			curEditor.destroy();
			curEditor = null;
			jEditor.empty();

			useFile(curFile);
		}

		// Create editor
		if( active ) {
			jEditor.text(allFiles.get(curFile));
			jBody.addClass("editing");
			curEditor = AceEditor.edit("editor");
			curEditor.setTheme("ace/theme/monokai");
			curEditor.session.setMode("ace/mode/randomizer");
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

		curFile = f;
		saveSettings();
	}

	public function clearOutput() {
		jOutput.empty();
	}

	public function output(str:String) {
		str = StringTools.htmlEscape(str);
		str = "<pre>" + str.split("\\n").join("</pre><pre>") + "</pre>";
		jOutput.append('<div class="entry">$str</div>');
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