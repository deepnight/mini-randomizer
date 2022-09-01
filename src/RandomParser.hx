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
	public static var KEY_DEFINITION_REG = "^[ \t]*>[ \t]*([a-zA-Z0-9_-]+)\\s*$";
	public static var KEY_REFERENCE_REG = "@([a-zA-Z0-9_-]+)";
	public static var COUNT_REG = "^([0-9]+)-([0-9]+)$";
	public static var OPTION_REG = "^#([a-zA-Z0-9_-]+)([ \t]+(.+)|)";
	public static var PROBA_MUL_REG = "[ \t]+x([0-9.]+)[ \t]*$";

	public static function run(raw:String) : { data:Null<RandData>, errors:Array<String> } {
		if( raw==null )
			return null;

		var rdata : RandData = {
			tables: new Map(),
			options: [],
		}

		var lines = raw.split("\n");
		var curKey : Null<String> = null;

		var optionReg = new EReg(OPTION_REG,"");
		var keyDefinionReg = new EReg(KEY_DEFINITION_REG,"");
		var keyReferenceReg = new EReg(KEY_REFERENCE_REG,"");
		var probaMulReg = new EReg(PROBA_MUL_REG,"");

		for( l in lines ) {
			l = cleanUp(l);
			if( l.length==0 )
				continue;

			// Option
			if( optionReg.match(l) ) {
				var o = optionReg.matched(1);
				var rawArgs = optionReg.matched(3);
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

			if( keyDefinionReg.match(l) ) {
				// New table key
				curKey = keyDefinionReg.matched(1);
				if( !rdata.tables.exists(curKey) )
					rdata.tables.set(curKey, []);
			}
			else if( curKey!=null ) {
				var probaMul = 1.;
				if( probaMulReg.match(l) ) {
					// Custom probability
					probaMul = Std.parseFloat( probaMulReg.matched(1) );
					if( !M.isValidNumber(probaMul) )
						probaMul = 1;
					l = probaMulReg.matchedLeft();
				}
				// Store table entry
				rdata.tables.get(curKey).push({
					raw: l,
					probaMul: probaMul,
				});
			}
		}

		var errors = [];
		inline function _err(e:Dynamic) errors.push( Std.string(e) );

		// Check options errors
		for(o in rdata.options) {
			var k = o.opt;
			switch k {
				case "button":
					if( o.args.length==0 )
						_err('Missing argument in #$k');
				case _: _err('Unknown option: #$k');
			}
		}

		// Check key refs
		var keyRefReg = new EReg(KEY_REFERENCE_REG,"");
		var countReg = new EReg(COUNT_REG,"");
		for(table in rdata.tables.keyValueIterator())
			for(e in table.value) {
				var tmp = e.raw;
				while( keyRefReg.match(tmp) ) {
					var k = keyRefReg.matched(1);
					if( !countReg.match(k) && !rdata.tables.exists(k) )
						_err('Unknown key :$k: in >${table.key}');
					tmp = keyRefReg.matchedRight();
				}
			}

		return {
			data: rdata,
			errors: errors,
		}
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