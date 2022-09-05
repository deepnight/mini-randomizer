import aceEditor.AceEditor;

class RandomUI extends SiteProcess {
	public var jToolbar : J;
	public var jRandButtons : J;
	public var jOutput : J;
	var randomizer : Null<Randomizer>;

	public function new() {
		super("random");

		jToolbar = jRoot.find(".toolbar");
		jRandButtons = jToolbar.find(".randButtons");
		jOutput = jRoot.find(".output");

		// Clear button
		jToolbar.find(".clear").click( _->clearOutput() );
	}

	override function onFileChanged(raw:String) {
		super.onFileChanged(raw);

		clearOutput();
		jRandButtons.empty();

		var parsed = RandomParser.run(raw);
		randomizer = new Randomizer(parsed.data);

		if( app.editor!=null ) {
			app.editor.clearLog();
			for(m in parsed.data.markedLines) {
				app.editor.addLog(m.label, m.line, m.className);
				app.editor.addLineMark(m.line, m.className);
			}
		}

		if( parsed.errors.length>0 ) {
			app.openEditor();
			app.editor.addErrors(parsed.errors);
		}



		// Add buttons
		for(o in parsed.data.options)
			switch o.id {
				case "button":
					var jBt = new J('<button>🎲 ${o.args.get("label")}</button>');
					jBt.click( (ev:js.jquery.Event)->{
						if( app.editor!=null && app.editor.checkAutoSave() )
							return;

						var count = Std.parseInt( o.args.get("count") );
						if( ev.shiftKey ) {
							clearOutput();
							count = 10;
						}
						for(i in 0...count)
							output( randomizer.draw( o.args.get("key") ) );
					});
					jRandButtons.append(jBt);

				case _: notify('Unknown option: ${o.id}');
			}

		clearOutput();
	}

	public function clearOutput() {
		jOutput.empty();
	}

	public function output(str:String) {
		str = StringTools.htmlEscape(str);
		str = "<pre>" + str.split("\\n").join("</pre><pre>") + "</pre>";
		jOutput.prepend('<div class="entry">$str</div>');
	}

	override function onDispose() {
		super.onDispose();
	}
}