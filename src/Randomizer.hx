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

		// Quick draw lists, eg. [red,blue]
		var entry = rlist.draw();
		var out = entry.raw;
		var quickListReg = new EReg(RandomParser.QUICK_LIST_REG, "");
		while( quickListReg.match(out) ) {
			var list = quickListReg.matched(1);
			var sep = list.indexOf("|")>=0 ? "|" : ",";
			var all = list.split(sep);
			var e = StringTools.trim( R.pick(all) );
			out = quickListReg.matchedLeft() + e + quickListReg.matchedRight();
		}

		// Random numbers
		var countReg = new EReg(RandomParser.COUNT_REG, "");
		while( countReg.match(out) ) {
			var min = Std.parseInt( countReg.matched(1) );
			var max = Std.parseInt( countReg.matched(2) );
			out = countReg.matchedLeft() + R.irnd(min,max) + countReg.matchedRight();
		}

		// Key references
		var refReg = new EReg(RandomParser.KEY_REFERENCE_REG, "");
		while( refReg.match(out) ) {
			var k = refReg.matched(1);
			out = refReg.matchedLeft() + draw(k) + refReg.matchedRight();
		}

		if( out=="-" )
			out = "";

		return out;
	}
}