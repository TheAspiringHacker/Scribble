/**
    svg.js - SVG sprite library
    Copyright (C) 2017-2018 TheAspiringHacker

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
;'use strict';

var Bexp = Bexp || {};

Bexp.Svg = (function(window, document) {
    const NS = 'http://www.w3.org/2000/svg';
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
        this.childNodes = new Bexp.Util.List();
        this.linkedListNode = null;
        this.parentNode = null;
        this.prev = null;
        this.next = null;
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
    Sprite.prototype.x = function() {
        return this.transform.translation.x;
    };
    Sprite.prototype.y = function() {
        return this.transform.translation.y;
    };
    Sprite.prototype.width = function() {
        return parseInt(this.graphics.getAttributeNS(null, 'width'));
    };
    Sprite.prototype.height = function() {
        return parseInt(this.graphics.getAttributeNS(null, 'height'));
    };
    Sprite.prototype.appendChild = function(child) {
        this.graphics.appendChild(child.graphics);
        this.childNodes.push(child);
        child.linkedListNode = this.childNodes.back;
        child.parentNode = this;
    };
    Sprite.prototype.insertChild = function(newChild, oldChild) {
        this.graphics.insertBefore(newChild.graphics, oldChild.graphics);
        const node = this.childNodes.insert(newChild, oldChild.linkedListNode);
        newChild.parentNode = this;
        newChild.linkedListNode = node;
    };
    Sprite.prototype.removeChild = function(child) {
        this.graphics.removeChild(child.graphics);
        this.childNodes.remove(child.linkedListNode);
        child.linkedListNode = null;
        child.parentNode = null;
        return child;
    };
    Sprite.prototype.updateSVG = function() {
    };
    Sprite.prototype.render = function() {
        this.childNodes.forEach(x => x.render());
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
        this.drag.offset = {x: x, y: y};
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

    var Text = function(str) {
        Bexp.Svg.Sprite.call(this, document.createElementNS(NS, 'g'));
        this.text = document.createElementNS(NS, 'text');
        this.text.textContent = str;
        this.text.setAttributeNS(null, 'font-size', 12);
        this.graphics.appendChild(this.text);
    };
    Text.prototype = Object.create(Sprite.prototype);
    Text.prototype.setFill = function(fill) {
        this.text.setAttributeNS(null, 'fill', fill);
    };
    Text.prototype.width = function() {
        return this.text.getComputedTextLength();
    };
    Text.prototype.updateSVG = function() {
    };
    return {
        NS: NS,
        Sprite: Sprite,
        Text: Text
    };
})(window, document);
