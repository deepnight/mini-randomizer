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
		while( refReg.match(out) ) {
			var k = refReg.matched(1);
			out = refReg.matchedLeft() + draw(k) + refReg.matchedRight();
		}
		return out;
	}
}