package aceEditor;

@:native("ace") extern class AceEditor {
	public static function edit(id:String) : AceEditor;

	public var session : AceEditorSession;
	public function setTheme(id:String) : Void;
	public function destroy() : Void;
}

extern class AceEditorSession {
	public function setMode(id:String) : Void;
}