const SVGSprite = (function(window, document) {
    const svgNS = 'http://www.w3.org/2000/svg';
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
        this.drag = {
            start: {x: 0, y: 0},
            offset: {x: 0, y: 0},
            dragged: false
        };
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
    Sprite.prototype.handleEvent = function(event) {
    };
    Sprite.prototype.startDrag = function(x, y) {
        this.drag.start = {
            x: this.transform.translation.x,
            y: this.transform.translation.y
        };
        this.drag.offset = { x: x, y: y };
        this.drag.dragged = true;
    };
    Sprite.prototype.updateDrag = function(x, y) {
        if(this.drag.dragged) {
            this.transform.translation.x
              = this.drag.start.x + x - this.drag.offset.x;
            this.transform.translation.y
              = this.drag.start.y + y - this.drag.offset.y;
        }
    };
    Sprite.prototype.stopDrag = function() {
        this.drag.dragged = false;
    };
    Stage = function() {
        Sprite.call(this, document.createElementNS(svgNS, 'svg'));
        this.mouse = {pos: {x: 0, y: 0}, down: false};
        this.graphics.addEventListener('mousemove', this);
        this.graphics.addEventListener('mousedown', this);
        this.graphics.addEventListener('mouseup', this);
    };
    Stage.prototype = Object.create(Sprite.prototype);
    Stage.prototype.handleEvent = function(event) {
        switch(event.type) {
        case 'mousemove':
            this.mouse.x = event.clientX;
            this.mouse.y = event.clientY;
        case 'mousedown':
            this.mouse.down = true;
        case 'mouseup':
            this.mouse.down = false;
        }
    };
    Text = function(str) {
        Sprite.call(this, document.createElementNS(svgNS, 'g'));
        this.text = document.createElementNS(svgNS, 'text');
        this.text.textContent = str;
        this.text.setAttributeNS(null, 'font-size', 12);
        this.graphics.appendChild(this.text);
    };
    Text.prototype = Object.create(Sprite.prototype);
    Text.updateSVG = function() {
    };
    return {
        svgNS: svgNS,
        Sprite: Sprite,
        Stage: Stage,
        Text: Text
    };
})(window, document);
