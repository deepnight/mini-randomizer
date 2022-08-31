class SiteProcess extends dn.Process {
	public static var ALL : Array<SiteProcess> = [];

	var app(get,never) : App; inline function get_app() return App.ME;
	var jBody(get,never) : js.jquery.JQuery; inline function get_jBody() return App.ME.jBody;
	var jDoc(get,never) : js.jquery.JQuery; inline function get_jDoc() return App.ME.jDoc;
	var jSite(get,never) : js.jquery.JQuery; inline function get_jSite() return App.ME.jSite;

	var jRoot : J;
	var curFileId(get,never) : String; inline function get_curFileId() return app.settings.curFileId;

	public function new(blockId:String, ?p) {
		super(p==null ? App.ME : p);

		ALL.push(this);

		jRoot = jSite.find('#$blockId');
		jRoot.off();
		jRoot.addClass("active");
	}

	public function onFileChanged(raw:String) {
	}

	inline function notify(str:String) app.notify(str);

	override function onDispose() {
		super.onDispose();
		ALL.remove(this);
		jRoot.removeClass("active");
	}
}