const SVGSprite = (function(window, document) {
    var Sprite = function(svg) {
        this.graphics = svg;
        this.childNodes = new Set();
        this.parentNode = null;
    };
    Sprite.prototype.appendChild = function(child) {
        this.graphics.appendChild(child.graphics);
        this.childNodes.add(child);
        child.parentNode = this;
    };
    Sprite.prototype.removeChild = function(child) {
        this.graphics.removeChild(child.graphics);
        this.childNodes.delete(child);
        child.parentNode = null;
        return child;
    };
    Sprite.prototype.render = function() {
        this.updateSVG();
    };
    return {Sprite : Sprite};
})(window, document);
