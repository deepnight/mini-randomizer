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

		var data = RandomParser.run(raw);
		randomizer = new Randomizer(data);

		// Add buttons
		for(o in data.options)
			switch o.opt {
				case "button":
					var jBt = new J('<button>${o.args[0]}</button>');
					jBt.click( (ev:js.jquery.Event)->{
						if( app.editor!=null && app.editor.checkAutoSave() )
							return;

						var count = o.args[2]==null ? 1 : Std.parseInt(o.args[2]);
						if( ev.shiftKey )
							count = 10;
						for(i in 0...count)
							output( randomizer.draw(o.args[1]) );
					});
					jRandButtons.append(jBt);

				case _: notify('Unknown option: ${o.opt}');
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