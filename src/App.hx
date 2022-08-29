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
		var allFiles = FileManager.getAllFiles();

		// Init select
		var jSelect = jBody.find("#files");
		jSelect.append('<option value=""/>');
		for(f in allFiles.keys())
			jSelect.append('<option value="${f}">${dn.FilePath.extractFileName(f)}</option>');
		jSelect.change( _->{
			var f = jSelect.val();
			useFile( f=="" ? null : f, allFiles.get(f) );
		});

		// Reload last file
		if( settings.lastFile!=null ) {
			if( !allFiles.exists(settings.lastFile) ) {
				settings.lastFile = curFile = null;
				saveSettings();
			}
			else {
				jSelect.val(settings.lastFile);
				useFile( settings.lastFile, allFiles.get(settings.lastFile) );
			}
	}

		// Edit button
		jToolbar.find("#edit").click(_->{
			var jEditor = jBody.find("#editor");
			if( curEditor==null ) {
				jEditor.text(allFiles.get(curFile));
				jBody.find("#site").addClass("editing");
				curEditor = AceEditor.edit("editor");
				curEditor.setTheme("ace/theme/solarized-light");
				curEditor.session.setMode("ace/mode/randomizer");
			}
			else {
				jBody.find("#site").removeClass("editing");
				curEditor.destroy();
				curEditor = null;
				jEditor.empty();
			}
		});

	}

	function saveSettings() {
		storage.writeObject(settings);
	}

	function useFile(f:String, raw:String) {
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