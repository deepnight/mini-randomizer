package aceEditor;

@:native("ace") extern class AceEditor {
	public static function edit(id:String) : AceEditor;

	public var session : AceEditorSession;
	public var commands : AceEditorCommands;
	public function setTheme(id:String) : Void;
	public function destroy() : Void;
	public function getValue() : String;
	public function blur() : String;
	public function focus() : String;
}

extern class AceEditorSession {
	public function setMode(id:String) : Void;
}
extern class AceEditorCommands {
	public function addCommand(cmd:{ name:String, bindKey:{win:String, mac:String }, exec:AceEditor->Void }) : Void;
}
// editor.commands.addCommand({
// 	name: "showKeyboardShortcuts",
// 	bindKey: {win: "Ctrl-Alt-h", mac: "Command-Alt-h"},
// 	exec: function(editor) {
// 		ace.config.loadModule("ace/ext/keybinding_menu", function(module) {
// 			module.init(editor);
// 			editor.showKeyboardShortcuts()
// 		})
// 	}
// })