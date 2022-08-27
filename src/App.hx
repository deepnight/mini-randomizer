class App extends dn.Process {
	public static var ME : App;

	public var jBody : J;
	public var jButtons : J;
	public var jOutput : J;

	public function new() {
		super();

		ME = this;

		jBody = new J("body");
		jButtons = jBody.find("#buttons");
		jOutput = jBody.find("#output");

		hxd.Res.initEmbed();
		var rdata = RandomParser.run( hxd.Res.test.entry.getText() );
		var r = new Randomizer(rdata);
		trace(r.draw("test"));
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