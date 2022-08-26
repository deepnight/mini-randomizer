class Boot extends hxd.App {
	public static function main() {
		new Boot();
	}
	override function init() {
		super.init();
		new Main();
	}

	override function update(dt:Float) {
		super.update(dt);
		dn.Process.updateAll( hxd.Timer.tmod );
	}
}