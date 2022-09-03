typedef RandData = {
	var keys: Array<{ key:String, line:Int }>;
	var tables: Map<String, Array<RandTableEntry>>;
	var options: Array<{ id:String, line:Int, args:Map<String, String> }>;
}
typedef RandTableEntry = {
	var raw : String;
	var line : Int;
	var probaMul : Float;
}

typedef Error = {
	var line: Int;
	var err: String;
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

	public static function run(raw:String) : { data:Null<RandData>, errors:Array<Error> } {
		if( raw==null )
			return null;


		var rdata : RandData = {
			keys: [],
			tables: new Map(),
			options: [],
		}
		var errors = [];
		inline function _err(e:Dynamic, line:Int) errors.push({ err:Std.string(e), line:line });

		var lines = raw.split("\n");
		var curKey : Null<String> = null;

		var optionReg = new EReg(OPTION_REG,"");
		var keyDefinionReg = new EReg(KEY_DEFINITION_REG,"");
		var keyReferenceReg = new EReg(KEY_REFERENCE_REG,"");
		var probaMulReg = new EReg(PROBA_MUL_REG,"");
		// var countReg = new EReg(COUNT_REG,"");

		var hasAnyButton = false;
		var lineIdx = 0;
		for( l in lines ) {
			lineIdx++;
			var lineIdx = lineIdx; // local copy
			l = cleanUp(l);
			if( l.length==0 )
				continue;

			// Option
			if( optionReg.match(l) ) {
				var o = optionReg.matched(1);
				var rawArgs = optionReg.matched(3);
				var args = new Map();

				switch o {
					case "button":
						args.set("label", "???");
						if( rawArgs==null )
							_err('Missing argument for #$o', lineIdx);
						else {
							if( keyReferenceReg.match(rawArgs) ) {
								args.set("key", keyReferenceReg.matched(1));
								rawArgs = keyReferenceReg.matchedLeft() + keyReferenceReg.matchedRight();
							}
							else
								_err('Missing key name (ex: "@myKey") in #button', lineIdx);
							if( probaMulReg.match(rawArgs) ) {
								args.set( "count", probaMulReg.matched(1) );
								rawArgs = probaMulReg.matchedLeft() + probaMulReg.matchedRight();
							}
							else
								args.set( "count", "1" );

							var label = StringTools.trim(rawArgs);
							if( label.length==0 && args.exists("key") )
								label = args.get("key");
							args.set("label", label);
							hasAnyButton = true;
						}

					case _: _err('Unknown option: #$o', lineIdx);
				}


				rdata.options.push({
					id: o,
					line: lineIdx,
					args: args,
				});
				continue;
			}

			if( keyDefinionReg.match(l) ) {
				// New table key
				curKey = keyDefinionReg.matched(1);
				rdata.keys.push({ key:curKey, line:lineIdx });
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
					line: lineIdx,
					raw: l,
					probaMul: probaMul,
				});
			}
		}


		// Add some default button
		if( !hasAnyButton && rdata.keys.length>0 ) {
			var k = rdata.keys[0].key;
			rdata.options.push({
				id: "button",
				line: 1,
				args: [ "key"=>k, "label"=>k, "count"=>"1" ],
			});
		}

		// Check key refs in tables
		var keyRefReg = new EReg(KEY_REFERENCE_REG,"");
		var countReg = new EReg(COUNT_REG,"");
		for(table in rdata.tables.keyValueIterator())
			for(e in table.value) {
				var tmp = e.raw;
				while( keyRefReg.match(tmp) ) {
					var k = keyRefReg.matched(1);
					if( !countReg.match(k) && !rdata.tables.exists(k) )
						_err('Unknown key "@$k" in ">${table.key}"', e.line);
					tmp = keyRefReg.matchedRight();
				}
			}

		// Check key refs in options
		for(o in rdata.options)
			switch o.id {
				case "button":
					var k = o.args.get("key");
					if( k!=null && !rdata.tables.exists(k) )
						_err('Unknown key "@$k" in #button', o.line);
			}

		return {
			data: rdata,
			errors: errors,
		}
	}

	public static function debugRandData(rdata:RandData) {
		trace("OPTIONS:");
		for(o in rdata.options)
			trace("  "+o.id+" => "+o.args);
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