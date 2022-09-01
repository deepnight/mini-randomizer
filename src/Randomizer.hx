class Randomizer {
	var data : RandomParser.RandData;

	public function new(data:RandomParser.RandData) {
		this.data = data;
	}

	static function error(msg:String) {
		trace('ERROR: $msg');
	}

	public function draw(key:String) : String {
		if( !data.tables.exists(key) )
			return '<ERR: $key>';

		var table = data.tables.get(key);
		if( table.length==0 )
			return "";

		var rlist = new dn.struct.RandList();
		for(e in table)
			rlist.add(e, M.ceil(e.probaMul*100));

		var entry = rlist.draw();
		var out = entry.raw;
		var refReg = new EReg(RandomParser.KEY_REFERENCE_REG, "");
		var countReg = new EReg(RandomParser.COUNT_REG, "");
		while( refReg.match(out) ) {
			var k = refReg.matched(1);
			if( countReg.match(k) ) {
				// Random number
				var min = Std.parseInt( countReg.matched(1) );
				var max = Std.parseInt( countReg.matched(2) );
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