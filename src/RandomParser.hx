typedef RandTable = Array<RandTableEntry>;
typedef RandTableEntry = {
	var raw : String;
	var probaMul : Float;
}

class RandomParser {
	static var OPTION_REG = ~/^#([a-z0-9_-]+)([ \t]+(.+)|)/i;
	static var KEY_REG = ~/^[ \t]*>[ \t]*([a-z0-9_-]+)[ \t]*/i;
	static var KEYREF_REG = ~/:([a-z0-9_-]+):/i;
	static var PROBA_MUL_REG = ~/[ \t]+x([0-9.]+)[ \t]*$/i;

	public var tables : Map<String, RandTable> = new Map();

	public function new(raw:String) {
		var lines = raw.split("\n");
		var curKey : Null<String> = null;
		for( l in lines ) {
			l = StringTools.replace(l, "\r", "");
			l = StringTools.trim(l);
			if( l.length==0 )
				continue;

			if( OPTION_REG.match(l) )
				setOption( OPTION_REG.matched(1), OPTION_REG.matched(3) );

			if( KEY_REG.match(l) ) {
				curKey = KEY_REG.matched(1);
				if( !tables.exists(curKey) )
					tables.set(curKey, []);
			}
			else if( curKey!=null ) {
				var probaMul = 1.;
				if( PROBA_MUL_REG.match(l) ) {
					probaMul = Std.parseFloat( PROBA_MUL_REG.matched(1) );
					if( !M.isValidNumber(probaMul) )
						probaMul = 1;
					l = PROBA_MUL_REG.matchedLeft();
				}
				tables.get(curKey).push({
					raw: l,
					probaMul: probaMul,
				});
			}
		}

		for(t in tables.keyValueIterator())
			trace(t.key+" => "+t.value.map(e->e.raw+"["+M.round(e.probaMul*100)+"%]").join(", "));
	}

	function setOption(opt:String, ?arg:String) {
		trace('Found option $opt:$arg');
	}
}