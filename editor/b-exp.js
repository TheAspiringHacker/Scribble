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
        SVGSprite.Stage.call(this);
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
        this.scriptArea.appendChild(this.graphics);
        this.graphics.setAttributeNS(null, 'id', 'main-svg');
        this.graphics.setAttributeNS(null, 'width', '100%');
        this.graphics.setAttributeNS(null, 'height', '100%');
        this.spec = spec;
        this.scripts = new Set();
    };
    Editor.prototype = Object.create(SVGSprite.Stage.prototype);
    Editor.prototype.newBlock = function(opcode, children) {
        var b = new Bexp.BlockExpr(this, opcode, children);
        return b;
    };
    Editor.prototype.addScript = function(script, x, y) {
        script.transform.translation.x = x;
        script.transform.translation.y = y;
        this.appendChild(script);
        script.render();
    };
    Editor.prototype.removeScript = function(block) {
        return this.removeChild(block);
    };
    Editor.prototype.mouseEvent = function() {
    };
    Hole = function(stage) {
        SVGSprite.Sprite.call(this, stage,
                              document.createElementNS(Bexp.svgNS, 'g'));
        this.rect = document.createElementNS(Bexp.svgNS, 'rect');
        this.rect.setAttributeNS(null, 'width', 20);
        this.rect.setAttributeNS(null, 'height', editor.BLOCK_HEIGHT);
        this.graphics.setAttributeNS(null, 'width', 20);
    };
    Hole.prototype = Object.create(SVGSprite.Sprite.prototype);
    Hole.prototype.render = function() {
    };

    BlockExpr = function(editor, opcode, children) {
        SVGSprite.Sprite.call(this, editor.stage,
                              document.createElementNS(Bexp.svgNS, 'g'));
        this.editor = editor;
        this.opcode = opcode;
        this.op = editor.spec.blocks[opcode];
        this.children = children;
        this.rect = document.createElementNS(Bexp.svgNS, 'rect');
        this.rect.setAttributeNS(null, 'height', editor.BLOCK_HEIGHT);
        this.rect.setAttributeNS(null, 'fill', '#0000ff');
        this.graphics.append(this.rect);
        this.clicked = false;
        this.mouseEscaped = false;
        this.dirty = true;

        (function(self) {
            var childIdx = 0;
            for(var i = 0; i < self.op.grammar.length; ++i) {
                switch(self.op.grammar[i].type) {
                case 'token':
                    self.appendChild(
                        new SVGSprite.Text(self.stage, self.op.grammar[i].text)
                    );
                    break;
                case 'nonterminal':
                    if(childIdx < self.children.length) {
                        self.appendChild(self.children[childIdx]);
                    } else {
                        self.children.push(null);
                        self.appendChild(new Hole(self.stage));
                    }
                    ++childIdx;
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
    BlockExpr.prototype.updateSVG = function() {
        if(!this.dirty) return;
        this.dirty = false;
        var childIdx = 0;
        this.graphics.setAttributeNS(null, 'width', this.editor.SPACING);
        var was_modified_past_here = false;
        var width = this.editor.SPACING;
        var iter = this.childNodes.keys();
        for(var i = 0; i < this.op.grammar.length; ++i) {
            var child = iter.next().value;
            var is_nonterminal
                = (this.op.grammar[i].type == 'nonterminal');
            if(is_nonterminal) {
                ++childIdx;
            }
            if(true) {
                var foo = -1;
                if(this.op.grammar[i].type == 'token') {
                    foo = child.text.getComputedTextLength();
                    child.transform.translation = {x: width, y: 17};
                } else if(this.op.grammar[i].type == 'nonterminal') {
                    child.transform.x = width;
                    foo = parseInt(child.graphics.getAttribute('width'));
                } else if(this.op.grammar[i].type == 'variadic') {
                }
                width += foo + this.editor.SPACING;
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

    BlockExpr.prototype.handleEvent = function(event) {
        switch(event.type) {
        case 'mousedown':
            this.stage.dragged = this;
            event.preventDefault();
            this.startDrag(event.pageX, event.pageY);
            break;
        }
    };
    BlockExpr.prototype.mouseEvent = function(mouse) {
        if(mouse.down) {
	    this.updateDrag(mouse.x, mouse.y);
	    this.render();
        } else {
	    this.stopDrag();
        }
    };
    BlockExpr.prototype.emit = function() {
        return {
            opcode : this.opcode,
            children : this.children.map(x => x == null ? null : x.emit())
        };
    };

    return {
        svgNS : 'http://www.w3.org/2000/svg',
        Editor : Editor,
        BlockExpr : BlockExpr
    };
})(window, document);