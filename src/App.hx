typedef Settings = {
	var lastFile: String;
}

class App extends dn.Process {
	public static var ME : App;

	public var jBody : J;
	public var jButtons : J;
	public var jOutput : J;
	var storage : dn.data.LocalStorage;
	var settings : Settings;

	public function new() {
		super();

		ME = this;
		jBody = new J("body");
		jButtons = jBody.find("#buttons");
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
				settings.lastFile = null;
				saveSettings();
			}
			else {
				jSelect.val(settings.lastFile);
				useFile( settings.lastFile, allFiles.get(settings.lastFile) );
			}
		}
	}

	function saveSettings() {
		storage.writeObject(settings);
	}

	function useFile(f:String, raw:String) {
		clearOutput();
		jButtons.empty();

		settings.lastFile = f;
		saveSettings();

		if( raw==null )
			return;

		var rdata = RandomParser.run(raw);
		new Randomizer(rdata);
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

	function notify(str:String) {
		var jNotif = jBody.find("#notif");
		jNotif.text(str);
		jNotif.stop(true).hide().slideDown(200).delay(1400).fadeOut(200);
	}

	override function update() {
		super.update();
	}
}