const SVGSprite = (function(window, document) {
    var translationToAttribute = function(translation) {
        return 'translate(' + translation.x + ', ' + translation.y + ')';
    };
    var rotationToAttribute = function(rotation) {
        return 'rotate(' + rotation.radians + ', ' + rotation.position.x
            + ', ' + rotation.position.y + ')';
    };
    var scaleToAttribute = function(scale) {
        return 'scale(' + scale.x + ', ' + scale.y + ')';
    };
    var Sprite = function(svg, transform) {
        this.graphics = svg;
        this.childNodes = new Set();
        this.parentNode = null;
        this.transform = {
            translation: {x: 0, y : 0},
            rotation: {radians: 0, position: {x: 0, y: 0}},
            scale: {x: 1, y: 1}
        };
        if(transform !== undefined) {
            this.transform = transform;
        }
    };
    Sprite.prototype.appendChild = function(child) {
        this.graphics.appendChild(child.graphics);
        child.index = this.childNodes.length;
        this.childNodes.add(child);
        child.parentNode = this;
    };
    Sprite.prototype.removeChild = function(child) {
        this.graphics.removeChild(child.graphics);
        this.childNodes.delete(child);
        child.parentNode = null;
        return child;
    };
    Sprite.prototype.updateSVG = function() {
    };
    Sprite.prototype.render = function() {
        this.updateSVG();
        this.graphics.setAttributeNS(null, 'transform',
            translationToAttribute(this.transform.translation) + ' '
            + rotationToAttribute(this.transform.rotation) + ' '
            + scaleToAttribute(this.transform.scale)
        );
        this.childNodes.forEach(x => x.render());
    };
    return {Sprite : Sprite};
})(window, document);
