class SiteProcess extends dn.Process {
	public static var ALL : Array<SiteProcess> = [];

	var app(get,never) : App; inline function get_app() return App.ME;
	var jBody(get,never) : js.jquery.JQuery; inline function get_jBody() return App.ME.jBody;
	var jDoc(get,never) : js.jquery.JQuery; inline function get_jDoc() return App.ME.jDoc;
	var jSite(get,never) : js.jquery.JQuery; inline function get_jSite() return App.ME.jSite;

	var jRoot : J;
	var curFileId(get,never) : String; inline function get_curFileId() return app.settings.curFileId;

	public function new(name:String, ?p) {
		super(p==null ? App.ME : p);

		ALL.push(this);
		this.name = name;

		// Init root
		var jColumns = jSite.find(".columns");
		jColumns.remove('.column.$name');
		jRoot = new J('<div class="column $name"/>');
		jColumns.append(jRoot);

		// Load template
		var tpl = app.getTemplate(name);
		if( tpl!=null )
			jRoot.html(tpl);
		else
			jRoot.append("hello "+name);
	}

	public function onFileChanged(raw:String) {}
	inline function notify(str:String) app.notify(str);

	override function onDispose() {
		super.onDispose();
		ALL.remove(this);
		jRoot.empty().remove();
	}
}