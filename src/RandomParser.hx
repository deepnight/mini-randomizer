typedef RandData = {
	var rawFile: String;
	var keys: Array<{ key:String, line:Int }>;
	var tables: Map<String, Array<RandTableEntry>>;
	var options: Array<Option>;
	var markedLines: Array<{ parentKey:String, line:Int, className:String }>;
	var errors: Array<Error>;
}
typedef Option = {
	var id: String;
	var line: Int;
	var args: Map<String, String>;
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
	public static var DEBUG_MARK = "<<<";
	public static var KEY_DEFINITION_REG = "^[ \t]*>[ \t]*([a-zA-Z0-9_-]+)[\\s<]*$";
	public static var KEY_REFERENCE_REG = "@([a-zA-Z0-9_-]+)";
	public static var QUICK_LIST_REG = "\\[(.*?)\\]";
	public static var COUNT_REG = "([0-9]+)-([0-9]+)";
	public static var OPTION_REG = "^#([a-zA-Z0-9_-]+)([ \t]+(.+)|)";
	public static var PROBA_MUL_REG = "[ \t]+x([0-9.]+)[ \t]*$";

	public static function run(raw:String) : RandData {
		var rdata : RandData = {
			rawFile: raw,
			keys: [],
			tables: new Map(),
			options: [],
			markedLines: [],
			errors: [],
		}

		if( raw==null )
			return rdata;

		function _err(e:Dynamic, line:Int) rdata.errors.push({ err:Std.string(e), line:line });

		var lines = raw.split("\n");
		var curKey : Null<String> = null;

		var optionReg = new EReg(OPTION_REG,"");
		var keyDefinionReg = new EReg(KEY_DEFINITION_REG,"");
		var keyReferenceReg = new EReg(KEY_REFERENCE_REG,"");
		var probaMulReg = new EReg(PROBA_MUL_REG,"");
		// var countReg = new EReg(COUNT_REG,"");

		var quickDebugs = [];

		var lineIdx = 0;
		for( l in lines ) {
			lineIdx++;
			var lineIdx = lineIdx; // local copy
			l = cleanUp(l);
			if( l.length==0 )
				continue;

			// Option
			if( optionReg.match(l) ) {
				var o = parseOption(l, lineIdx, _err);
				if( o!=null ) {
					rdata.options.push(o);
					continue;
				}
				else
					_err('Cannot parse this option', lineIdx);
			}

			if( keyDefinionReg.match(l) ) {
				// New table key
				curKey = keyDefinionReg.matched(1);
				rdata.keys.push({ key:curKey, line:lineIdx });
				if( !rdata.tables.exists(curKey) )
					rdata.tables.set(curKey, []);

				// Quick debug table
				if( l.indexOf(DEBUG_MARK)>=0 ) {
					l = StringTools.replace(l,DEBUG_MARK,"");
					rdata.markedLines.push({ parentKey:curKey, line:lineIdx, className:"debug" });
					quickDebugs.push(l);
				}
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
				// Quick debug test
				if( l.indexOf(DEBUG_MARK)>=0 ) {
					l = StringTools.replace(l,DEBUG_MARK,"");
					rdata.markedLines.push({ parentKey:curKey, line:lineIdx, className:"debug" });
					quickDebugs.push(l);
				}
				// Store table entry
				rdata.tables.get(curKey).push({
					line: lineIdx,
					raw: l,
					probaMul: probaMul,
				});
			}
		}


		// Add custom test entries
		var i = 0;
		for(d in quickDebugs) {
			if( keyDefinionReg.match(d) ) {
				// Debug a full table
				var k = keyDefinionReg.matched(1);
				rdata.options.push( parseOption('#button @$k', -1, _err) );
			}
			else {
				// Debug a single entry
				var k = "customTest"+i;
				rdata.tables.set(k, [{
					raw: d,
					line: -1,
					probaMul: 1,
				}]);
				var label = removeSpecialChars( '"' + d.substr(0,12) + (d.length>12?"...":"") + '"' );
				rdata.options.push( parseOption('#button $label @$k', -1, _err) );
			}
			i++;
		}


		// Add some default button
		var hasAnyButton = false;
		for(o in rdata.options)
			if( o.id=="button" ) {
				hasAnyButton = true;
				break;
			}
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

		// Finalize
		rdata.keys.sort( (a,b)->Reflect.compare(a.key,b.key) );
		for(o in rdata.options) {
			switch o.id {
				case "button":
					// Add button marker
					rdata.markedLines.push({ parentKey:o.args.get("key"), line:o.line, className:"button" });

					// Check key refs in button
					var k = o.args.get("key");
					if( k!=null && !rdata.tables.exists(k) )
						_err('Unknown key "@$k" in #button', o.line);
			}
		}

		return rdata;
	}

	static function parseOption(raw:String, lineIdx:Int, onError:(err:Dynamic,line:Int)->Void) : Null<Option> {
		var keyReferenceReg = new EReg(KEY_REFERENCE_REG,"");
		var probaMulReg = new EReg(PROBA_MUL_REG,"");
		var optionReg = new EReg(OPTION_REG,"");

		optionReg.match(raw);

		var o = optionReg.matched(1);
		var rawArgs = optionReg.matched(3);
		var args = new Map();

		switch o {
			case "button":
				args.set("label", "???");
				if( rawArgs==null )
					onError('Missing argument for #$o', lineIdx);
				else {
					if( keyReferenceReg.match(rawArgs) ) {
						args.set("key", keyReferenceReg.matched(1));
						rawArgs = keyReferenceReg.matchedLeft() + keyReferenceReg.matchedRight();
					}
					else
						onError('Missing key name (ex: "@myKey") in #button', lineIdx);
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
				}

			case _: onError('Unknown option: #$o', lineIdx);
		}

		return {
			id: o,
			line: lineIdx,
			args: args,
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

	static function removeSpecialChars(str:String) {
		var r = ~/[^a-z0-9-_.:,;!?'"]/gim;
		return r.replace(str," ");
	}

	static function error(msg:String) {
		trace('ERROR: $msg');
	}
}