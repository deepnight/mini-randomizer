import haxe.macro.Context;
import haxe.macro.Expr;

class FileManager {
	static var DATA_FILES_DIR = dn.FilePath.fromDir("embed");

	#if macro
	static function listAllFilesStr(ext:String, ?subDir:String) : Array<String> {
		var fp = DATA_FILES_DIR.clone();
		if( subDir!=null )
			fp.appendDirectory(subDir);
		var all = sys.FileSystem.readDirectory(fp.full);
		var out = [];
		for(f in all)
			if( dn.FilePath.extractExtension(f)==ext )
				out.push(fp.full+"/"+f);
		return out;
	}
	#end

	public static macro function getAllFiles(ext:String, ?subDir:String) {
		Context.registerModuleDependency( Context.getLocalModule(), DATA_FILES_DIR.full );

		var out = new Map();
		for( path in listAllFilesStr(ext,subDir) ) {
			Context.registerModuleDependency( Context.getLocalModule(), path );
			out.set(path, sys.io.File.getContent(path));
		}

		return macro $v{out};
	}
}