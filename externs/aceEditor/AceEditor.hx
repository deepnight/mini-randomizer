package aceEditor;

/**
	Ref: https://ajaxorg.github.io/ace-api-docs/classes/Ace.Editor.html
**/
@:native("ace") extern class AceEditor {
	public static function edit(id:String) : AceEditor;

	public var session : AceEditorSession;
	public var commands : AceEditorCommands;
	public var selection : AceSelection;

	public function setTheme(id:String) : Void;
	public function destroy() : Void;
	public function getValue() : String;
	public function setValue(v:String, ?cursorPos:Int) : Void;
	public function blur() : Void;
	public function focus() : Void;
	public function on(eventId:String, cb:Void->Void) : Void;
	public function execCommand(cmd:String) : Void;

	public function isFocused() : Bool;

	public function getCursorPosition() : { row:Int, column:Int }
	public function moveCursorTo(row:Int, column:Int) : Void;
	public function gotoLine(lineNumber:Int, column:Int, animate:Bool) : Void;
	public function getSelectionRange() : AceRange;
}

extern class AceEditorSession {
	public function setMode(id:String) : Void;
	public function getUndoManager() : AceUndoManager;
	public function clearAnnotations() : Void;
	public function setAnnotations(annotations:Array<AceAnnotation>) : Void;
	public function setUseWrapMode(wrap:Bool) : Void;

	public function addMarker(range:AceRange, className:String, type:String, ?inFront:Bool) : Int;
	public function getMarkers() : Dynamic;
	public function removeMarker(id:Int) : Void;
}

typedef AceAnnotation = {
	var row: Int;
	var ?column: Int;
	var text: String;
	var type: String; // error, warning or info
}

extern class AceEditorCommands {
	public function addCommand(cmd:{ ?name:String, bindKey:{win:String, ?mac:String }, exec:AceEditor->Void }) : Void;
	public function removeCommand(cmd:String, ?keep:Bool) : Void;
}

extern class AceUndoManager {
	public function reset():Void;
}

extern class AceSelection {
	public function selectLine():Void;
}

@:native("ace.Range")
extern class AceRange {
	public var start : { row:Int, column:Int }
	public var end : { row:Int, column:Int }
	public function new(startRow:Int, startCol:Int, endRow:Int, endCol:Int);
}

extern class MarkerLike {
	public var id: Int;
	public var clazz: String;
	public var type: String;
}