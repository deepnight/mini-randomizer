class Main extends dn.Process {
	var jBody : J;
	var jSource : J;
	var jResult : J;
	public function new() {
		super();

		jBody = new J("body");
		hxd.Res.initEmbed();
		new RandomParser( hxd.Res.test.entry.getText() );
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