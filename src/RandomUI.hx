import aceEditor.AceEditor;

class RandomUI extends SiteProcess {
	public var jToolbar : J;
	public var jRandButtons : J;
	public var jOutput : J;

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

		jRandButtons.empty();

		var data = RandomParser.run(raw);
		var r = new Randomizer(data);

		// Add buttons
		for(o in data.options)
			switch o.opt {
				case "button":
					var jBt = new J('<button>${o.args[0]}</button>');
					jBt.click( (ev:js.jquery.Event)->{
						var count = o.args[2]==null ? 1 : Std.parseInt(o.args[2]);
						if( ev.shiftKey )
							count = 10;
						for(i in 0...count)
							output( r.draw(o.args[1]) );
					});
					jRandButtons.append(jBt);

				case _: notify('Unknown option: ${o.opt}');
			}
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