class Randomizer {
	var data : RandomParser.RandData;

	public function new(data:RandomParser.RandData) {
		this.data = data;
	}

	static function error(msg:String) {
		trace('ERROR: $msg');
	}

	public function draw(key:String) {
		if( !data.tables.exists(key) )
			return '<ERR: $key>';

		var table = data.tables.get(key);

		var rlist = new dn.struct.RandList();
		for(e in table)
			rlist.add(e, M.ceil(e.probaMul*100));

		var entry = rlist.draw();
		var out = entry.raw;
		var refReg = ~/:([a-z0-9_-]+):/i;
		var numberReg = ~/^([0-9]+)-([0-9]+)$/i;
		while( refReg.match(out) ) {
			var k = refReg.matched(1);
			if( numberReg.match(k) ) {
				// Random number
				var min = Std.parseInt( numberReg.matched(1) );
				var max = Std.parseInt( numberReg.matched(2) );
				out = refReg.matchedLeft() + R.irnd(min,max) + refReg.matchedRight();
			}
			else {
				// Key reference
				out = refReg.matchedLeft() + draw(k) + refReg.matchedRight();
			}
		}

		if( out=="-" )
			out = "";

		return out;
	}
}