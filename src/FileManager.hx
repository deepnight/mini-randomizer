import haxe.macro.Context;
import haxe.macro.Expr;

class FileManager {
	static var DATA_FILES_DIR = "dataFiles";

	#if macro
	static function listAllFilesStr() : Array<String> {
		var all = sys.FileSystem.readDirectory(DATA_FILES_DIR);
		var out = [];
		for(f in all)
			if( dn.FilePath.extractExtension(f)=="txt" )
				out.push(DATA_FILES_DIR+"/"+f);
		return out;
	}
	#end

	public static macro function getAllFiles() {
		Context.registerModuleDependency( Context.getLocalModule(), DATA_FILES_DIR );

		var out = new Map();
		for( f in listAllFilesStr() ) {
			Context.registerModuleDependency( Context.getLocalModule(), f );
			out.set(f, sys.io.File.getContent(f));
		}

		return macro $v{out};
	}
}