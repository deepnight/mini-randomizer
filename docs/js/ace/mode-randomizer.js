ace.define("ace/mode/randomizer_highlight_rules",["require","exports","module","ace/lib/oop","ace/mode/text_highlight_rules"], function(require, exports, module){"use strict";
var oop = require("../lib/oop");
var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;
var RandomizerHighlightRules = function () {
    this.$rules = {
        "start": [
            {
                token: "option",
                regex: '^#[a-zA-Z0-9]+'
                // next: "optionArg"
            }, {
                token: "keyDef",
                regex: '^>[a-zA-Z0-9_-]+$'
            }, {
                token: "keyRef",
                regex: '@([a-zA-Z0-9_-]+)'
            }, {
                token: "count",
                regex: ':[0-9]+-[0-9]+:'
            }, {
                token: "mul",
                regex: 'x[0-9.]+'
            }, {
                token: "constant.numeric",
                regex: "[+-]?\\d+(?:(?:\\.\\d*)?(?:[eE][+-]?\\d+)?)?\\b"
            }
        ],
        "optionArg": [
            {
                token: "optionArg",
                regex: '$',
                next: "start"
            }, {
                defaultToken : "optionArg"
            }
        ]
    };
};
oop.inherits(RandomizerHighlightRules, TextHighlightRules);
exports.RandomizerHighlightRules = RandomizerHighlightRules;

});


ace.define("ace/mode/randomizer",["require","exports","module","ace/lib/oop","ace/mode/text","ace/mode/randomizer_highlight_rules","ace/mode/matching_brace_outdent","ace/mode/behaviour/cstyle","ace/mode/folding/cstyle","ace/worker/worker_client"], function(require, exports, module){"use strict";
var oop = require("../lib/oop");
var TextMode = require("./text").Mode;
var HighlightRules = require("./randomizer_highlight_rules").RandomizerHighlightRules;
var Mode = function () {
    this.HighlightRules = HighlightRules;
};
oop.inherits(Mode, TextMode);
exports.Mode = Mode;

});

(function() {
    ace.require(["ace/mode/randomizer"], function(m) {
        if (typeof module == "object" && typeof exports == "object" && module) {
            module.exports = m;
        }
    });
})();
