/**
    b-exp.js - Block-expressions library
    Copyright (C) 2017  TheAspiringHacker

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

const Bexp = (function(window, document) {
    Editor = function(editor, spec) {
        this.BLOCK_HEIGHT = 25;
        this.SPACING = 5;
        this.editor = editor;
        this.palette = document.createElement('div');
        this.palette.setAttribute('id', 'sidebar');
        this.editor.appendChild(this.palette);

        var list = document.createElement('ul');
        list.setAttribute('id', 'categories');
        for(var i = 0; i < spec.categories.length; ++i) {
            var div = document.createElement('div');
            div.textContent = spec.categories[i].id;
            div.setAttribute('class', 'category');
            var li = document.createElement('li');
            li.appendChild(div);
            list.appendChild(li);
        }
        this.palette.appendChild(list);

        this.scriptArea = document.createElement('div');
        this.scriptArea.setAttribute('id', 'scripts');
        this.editor.appendChild(this.scriptArea);
        this.sprite
            = new SVGSprite.Sprite(document.createElementNS(Bexp.svgNS, 'svg'));
        this.scriptLayer
            = new SVGSprite.Sprite(document.createElementNS(Bexp.svgNS, 'g'));
        this.dragLayer
            = new SVGSprite.Sprite(document.createElementNS(Bexp.svgNS, 'g'));
        this.sprite.appendChild(this.scriptLayer);
        this.sprite.appendChild(this.dragLayer);
        this.scriptArea.appendChild(this.sprite.graphics);
        this.sprite.graphics.setAttributeNS(null, 'id', 'main-svg');
        this.sprite.graphics.setAttributeNS(null, 'width', '100%');
        this.sprite.graphics.setAttributeNS(null, 'height', '100%');
        this.spec = spec;
        this.scripts = new Set();
        this.holes = new Set();
        this.dragged = null;
    };
    Editor.prototype.newBlock = function(opcode, children) {
        return new Bexp.BlockExpr(this, opcode, children);
    };
    Editor.prototype.addScript = function(script, x, y) {
        script.transform.translation.x = x;
        script.transform.translation.y = y;
        this.scriptLayer.appendChild(script);
        script.render();
    };
    Editor.prototype.removeScript = function(block) {
        return this.scriptLayer.removeChild(block);
    };
    Hole = function(owner, index) {
        SVGSprite.Sprite.call(this, document.createElementNS(Bexp.svgNS, 'g'));
        this.rect = document.createElementNS(Bexp.svgNS, 'rect');
        this.rect.setAttributeNS(null, 'rx', '10');
        this.rect.setAttributeNS(null, 'ry', '10');
        this.rect.setAttributeNS(null, 'fill', '#ccb71e');
        this.rect.setAttributeNS(null, 'width', '25');
        this.rect.setAttributeNS(null, 'height', editor.BLOCK_HEIGHT);
        this.graphics.setAttributeNS(null, 'width', '25');
        this.graphics.setAttributeNS(null, 'height', editor.BLOCK_HEIGHT);
        this.graphics.appendChild(this.rect);
        this.owner = owner;
        this.index = index;
        this.owner.editor.holes.add(this);
    };
    Hole.prototype = Object.create(SVGSprite.Sprite.prototype);
    Hole.prototype.width = function() {
        return parseInt(this.rect.getAttributeNS(null, 'width'));
    };
    Hole.prototype.updateSVG = function() {
    };
    Hole.prototype.replaceWith = function(block) {
        this.owner[this.index] = block;
        this.owner.insertChild(block, this);
        this.owner.removeChild(this);
        this.owner.editor.holes.delete(this);
    };
    Hole.prototype.highlight = function() {
        this.rect.setAttributeNS(null, 'fill', 'white');
    };
    Hole.prototype.unhighlight = function() {
        this.rect.setAttributeNS(null, 'fill', '#ccb71e');
    };

    BlockExpr = function(editor, opcode, args, index) {
        SVGSprite.Sprite.call(this, document.createElementNS(Bexp.svgNS, 'g'));
        this.editor = editor;
        this.opcode = opcode;
        this.op = editor.spec.blocks[opcode];
        this.args = args;
        this.index = index || -1;
        this.rect = document.createElementNS(Bexp.svgNS, 'rect');
        this.rect.setAttributeNS(null, 'rx', '10');
        this.rect.setAttributeNS(null, 'ry', '10');
        this.rect.setAttributeNS(null, 'stroke', '#ccb71e');
        this.rect.setAttributeNS(null, 'stroke-width', '2');
        this.rect.setAttributeNS(null, 'height', editor.BLOCK_HEIGHT);
        this.rect.setAttributeNS(null, 'fill', '#fcdf05');
        this.graphics.append(this.rect);
        this.dropTarget = null;
        this.dirty = true;

        (function(self) {
            var argIdx = 0;
            for(var i = 0; i < self.op.grammar.length; ++i) {
                switch(self.op.grammar[i].type) {
                case 'token':
                    var text = new SVGSprite.Text(self.op.grammar[i].text);
                    text.setFill('white');
                    self.appendChild(text);
                    break;
                case 'nonterminal':
                    if(argIdx < self.args.length) {
                        self.args[argIdx].index = argIdx;
                        self.appendChild(self.args[argIdx]);
                    } else {
                        self.args.push(null);
                        self.appendChild(new Hole(self, argIdx));
                    }
                    ++argIdx;
                    break;
                case 'variadic':
                    // NOT IMPLEMENTED
                    break;
                default:
                    console.err(self.op.grammar[i].type + ' not a case');
                }
            }
        })(this);
        this.graphics.addEventListener('mousedown', this);
    };

    // BlockExpr extends Sprite
    BlockExpr.prototype = Object.create(SVGSprite.Sprite.prototype);
    BlockExpr.prototype.width = function() {
        return parseInt(this.rect.getAttributeNS(null, 'width'));
    }
    BlockExpr.prototype.updateSVG = function() {
        if(!this.dirty) return;
        //this.dirty = false;
        var childIdx = 0;
        var was_modified_past_here = false;
        var width = this.editor.SPACING;
        var iter = this.childNodes[Symbol.iterator]();
        for(var i = 0; i < this.op.grammar.length; ++i) {
            var child = iter.next().value;
            var is_nonterminal = (this.op.grammar[i].type == 'nonterminal');
            if(is_nonterminal) {
                ++childIdx;
            }
            if(true) {
                if(this.op.grammar[i].type == 'token') {
                    child.transform.translation = {x: width, y: 17};
                } else if(this.op.grammar[i].type == 'nonterminal') {
                    child.transform.translation.x = width;
                    child.transform.translation.y = 0;
                } else if(this.op.grammar[i].type == 'variadic') {
                }
                width += child.width() + this.editor.SPACING;
            } else {
                if(is_nonterminal) {
                    var foo = this.children[childIdx];
                    if(foo != null && foo.dirty) {
                        was_modified_past_here = true;
                    }
                }
            }
        }
        this.rect.setAttributeNS(null, 'width', width);
    };

    BlockExpr.prototype.clearArg = function(block) {
        this.args[block.index] = null;
        this.insertChild(new Hole(this, block.index), block);
        this.removeChild(block);
    };

    BlockExpr.prototype.handleEvent = function(event) {
        switch(event.type) {
        case 'mousedown':
            event.preventDefault();
            event.stopPropagation();
            document.addEventListener('mousemove', this);
            document.addEventListener('mouseup', this);
            var layer = this.parentNode;
            // A sprite's coordinates are relative to its parent's.
            // We need to make it relative to the scripting area.
            while(layer !== this.editor.scriptLayer) {
                this.transform.translation.x += layer.transform.translation.x;
                this.transform.translation.y += layer.transform.translation.y;
                layer = layer.parentNode;
            }
            var oldParent = this.parentNode;
            if(this.parentNode === this.editor.scriptLayer) {
                this.parentNode.removeChild(this);
            } else {
                this.parentNode.clearArg(this);
            }
            this.editor.dragLayer.appendChild(this);
            this.editor.dragged = this;
            this.startDrag(event.pageX, event.pageY);
            this.render();
            oldParent.render();
            break;
        case 'mousemove':
            this.updateDrag(event.pageX, event.pageY);
            var oldHole = this.dropTarget;
            var shortestDist = 20;
            this.dropTarget = null;
            for(hole of this.editor.holes) {
                if(hole.owner !== this) {
                    var pos = {
                        x: hole.transform.translation.x,
                        y: hole.transform.translation.y
                    };
                    var node = hole.owner;
                    // I should probably cache the global pos sometime; this is
                    // O(n)!
                    var doContinue = false;
                    while(node !== this.editor.scriptLayer) {
                        if(node === this.editor.dragLayer) {
                            doContinue = true;
                            break;;
                        }
                        pos.x += node.transform.translation.x;
                        pos.y += node.transform.translation.y;
                        node = node.parentNode;
                    }
                    if(doContinue) {
                        break;
                    }
                    var dist = Util.distance(pos, this.transform.translation);
                    if(dist < shortestDist) {
                        shortestDist = dist;
                        this.dropTarget = hole;
                    }
                }
            }
            if(oldHole !== this.dropTarget) {
                if(oldHole !== null) {
                    oldHole.unhighlight();
                    oldHole.render();
                }
                if(this.dropTarget !== null) {
                    this.dropTarget.highlight();
                    this.dropTarget.render();
                }
            }
            this.render();
            break;
        case 'mouseup':
            document.removeEventListener('mousemove', this);
            document.removeEventListener('mouseup', this);
            this.editor.dragLayer.removeChild(this);
            if(this.dropTarget === null) {
                this.editor.scriptLayer.appendChild(this);
            } else {
                this.dropTarget.replaceWith(this);
                if(this.parentNode !== this.dropTarget.owner) {
                    console.log('Assertion failed!');
                }
                this.parentNode.render();
                this.dropTarget = null;
            }
            this.editor.dragged = null;
            this.stopDrag();
            break;
        }
    };
    BlockExpr.prototype.emit = function() {
        return {
            opcode : this.opcode,
            args : this.args.map(x => x == null ? null : x.emit())
        };
    };

    return {
        svgNS : 'http://www.w3.org/2000/svg',
        Editor : Editor,
        BlockExpr : BlockExpr
    };
})(window, document);
