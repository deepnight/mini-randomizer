package aceEditor;

/**
	Ref: https://ajaxorg.github.io/ace-api-docs/classes/Ace.Editor.html
**/
@:native("ace") extern class AceEditor {
	public static function edit(id:String) : AceEditor;

	public var session : AceEditorSession;
	public var commands : AceEditorCommands;
	public function setTheme(id:String) : Void;
	public function destroy() : Void;
	public function getValue() : String;
	public function blur() : String;
	public function focus() : String;
	public function on(eventId:String, cb:Void->Void) : Void;
}

extern class AceEditorSession {
	public function setMode(id:String) : Void;
}
extern class AceEditorCommands {
	public function addCommand(cmd:{ name:String, bindKey:{win:String, mac:String }, exec:AceEditor->Void }) : Void;
}
