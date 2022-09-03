var css = [
    // Layout base
    ".ace-randomizer .ace_gutter {  background: #f6f6f6;  color: #4D4D4C}",
    ".ace-randomizer .ace_print-margin {  width: 1px;  background: #f6f6f6}",
    ".ace-randomizer {  background-color: #FFFFFF;  color: #4D4D4C}",
    ".ace-randomizer .ace_cursor {  color: #AEAFAD}",
    ".ace-randomizer .ace_marker-layer .ace_selection {  background: #D6D6D6}",
    ".ace-randomizer.ace_multiselect .ace_selection.ace_start {  box-shadow: 0 0 3px 0px #FFFFFF;}",
    ".ace-randomizer .ace_marker-layer .ace_step {  background: rgb(255, 255, 0)}",
    ".ace-randomizer .ace_marker-layer .ace_bracket {  margin: -1px 0 0 -1px;  border: 1px solid #D1D1D1}",
    ".ace-randomizer .ace_marker-layer .ace_active-line {  background: #EFEFEF}",
    ".ace-randomizer .ace_gutter-active-line {  background-color : #dcdcdc}",
    ".ace-randomizer .ace_marker-layer .ace_selected-word {  border: 1px solid #D6D6D6}",
    ".ace-randomizer .ace_invisible {  color: #D1D1D1}",

    // Randomizer styling
    ".ace_option { background-color:purple; color:white; }",
    ".ace_optionArg { background-color:#D5D5F5; color:black; font-weight:bold; }",
    ".ace_keyDef { background-color:orange; color:white; border-radius:3px; padding: 0 1px }",
    ".ace_keyRef { color:orange; font-weight:bold; text-decoration:underline }",
    ".ace_mul { color:#779FC5; font-style:italic }",
    ".ace_quickList { color:orange; font-style:italic }",
    ""
];

ace.define("ace/theme/randomizer.css",["require","exports","module"],function(e,t,n){n.exports=css.join("\n")}),ace.define("ace/theme/randomizer",["require","exports","module","ace/theme/randomizer.css","ace/lib/dom"],function(e,t,n){t.isDark=!1,t.cssClass="ace-randomizer",t.cssText=e("./randomizer.css");var r=e("../lib/dom");r.importCssString(t.cssText,t.cssClass,!1)});

(function() {
    ace.require(["ace/theme/randomizer"], function(m) {
        if (typeof module == "object" && typeof exports == "object" && module) {
            module.exports = m;
        }
    });
})();
