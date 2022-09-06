class Randomizer {
	var data : RandomParser.RandData;

	public function new(data:RandomParser.RandData) {
		this.data = data;
	}

	static function error(msg:String) {
		trace('ERROR: $msg');
	}

	public function draw(key:String) : String {
		return drawRec(key, new Map());
	}

	function drawRec(key:String, alreadyDones:Map<Int,Bool>) : String {
		if( !data.tables.exists(key) )
			return '<ERR: $key>';

		var table = data.tables.get(key);
		if( table.length==0 )
			return "";

		// Init rand list
		var rlist = new dn.struct.RandList();
		var count = 0;
		for(e in table)
			if( !alreadyDones.exists(e.line) ) {
				rlist.add(e, M.ceil(e.probaMul*100));
				count++;
			}

		// All values were already used, re-use full list
		if( count==0 )
			for(e in table)
				rlist.add(e, M.ceil(e.probaMul*100));

		// Pick value
		var entry : RandomParser.RandTableEntry = rlist.draw();
		alreadyDones.set(entry.line, true);
		var out = entry.raw;

		// Quick draw lists, eg. [red,blue]
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
			out = refReg.matchedLeft() + drawRec(k,alreadyDones) + refReg.matchedRight();
		}

		if( out=="-" )
			out = "";

		// Remove multiple spaces
		var spaceReg = ~/ {2,}/gim;
		out = spaceReg.replace(out, " ");

		return out;
	}
}