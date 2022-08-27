import haxe.macro.Context;
import haxe.macro.Expr;

class FileManager {
	public static macro function read(epath:ExprOf<String>) {
		var path = switch epath.expr {
			case EConst(CString(v,_)): v;
			case _: Context.fatalError("Constant String required", epath.pos);
		}
		if( !sys.FileSystem.exists(path) )
			Context.fatalError("File not found "+path, epath.pos);

		Context.registerModuleDependency( Context.getLocalModule(), path );
		var raw = sys.io.File.getContent(path);
		return macro $v{raw};
	}
}