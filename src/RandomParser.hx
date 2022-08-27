typedef RandData = {
	var tables: Map<String, Array<RandTableEntry>>;
	var options: Array<{ opt:String, args:Array<String> }>;
}
typedef RandTableEntry = {
	var raw : String;
	var probaMul : Float;
}

/**
	Inspired by RandomGen from Orteil (https://orteil.dashnet.org/randomgen/)
**/
class RandomParser {
	public static var OPTION_REG = ~/^#([a-z0-9_-]+)([ \t]+(.+)|)/i;
	public static var KEY_REG = ~/^[ \t]*>[ \t]*([a-z0-9_-]+)[ \t]*/i;
	public static var REF_REG = ~/:([a-z0-9_-]+):/i;
	public static var PROBA_MUL_REG = ~/[ \t]+x([0-9.]+)[ \t]*$/i;

	public static function run(raw:String) : Null<RandData> {
		if( raw==null )
			return null;

		var rdata : RandData = {
			tables: new Map(),
			options: [],
		}

		var lines = raw.split("\n");
		var curKey : Null<String> = null;

		for( l in lines ) {
			l = cleanUp(l);
			if( l.length==0 )
				continue;

			// Option
			if( OPTION_REG.match(l) ) {
				var o = OPTION_REG.matched(1);
				var rawArgs = OPTION_REG.matched(3);
				var args = [];
				if( rawArgs!=null )
					for(a in rawArgs.split("|"))
						args.push( cleanUp(a) );

				rdata.options.push({
					opt: o,
					args: args,
				});
				continue;
			}

			if( KEY_REG.match(l) ) {
				// New table key
				curKey = KEY_REG.matched(1);
				if( !rdata.tables.exists(curKey) )
					rdata.tables.set(curKey, []);
			}
			else if( curKey!=null ) {
				var probaMul = 1.;
				if( PROBA_MUL_REG.match(l) ) {
					// Custom probability
					probaMul = Std.parseFloat( PROBA_MUL_REG.matched(1) );
					if( !M.isValidNumber(probaMul) )
						probaMul = 1;
					l = PROBA_MUL_REG.matchedLeft();
				}
				// Store table entry
				rdata.tables.get(curKey).push({
					raw: l,
					probaMul: probaMul,
				});
			}
		}

		// TODO check data: invalid keys
		debugRandData(rdata);

		return rdata;
	}

	public static function debugRandData(rdata:RandData) {
		trace("OPTIONS:");
		for(o in rdata.options)
			trace("  "+o.opt+" => "+o.args);
		trace("TABLES:");
		for(t in rdata.tables.keyValueIterator())
			trace("  "+t.key+" => "+t.value.map(e->e.raw+"["+M.round(e.probaMul*100)+"%]").join(", "));
	}

	static function cleanUp(str:String) {
		str = StringTools.replace(str, "\r", "");
		str = StringTools.trim(str);
		return str;
	}

	static function error(msg:String) {
		trace('ERROR: $msg');
	}
}