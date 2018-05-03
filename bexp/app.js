var Bexp = Bexp || {};

(function(window, document) {

Bexp.App = function(element) {
    this.translations = {};
    this.element = element;
    this.editor = null;
};

Bexp.App.prototype.exec = function() {
    this.editor = this.editor === null
        ? new Bexp.Block.Editor(this, this.element)
        : this.editor;
}

})(window, document);
