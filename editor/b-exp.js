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
        this.svg = document.createElementNS(Bexp.svgNS, 'svg');
        this.scriptArea.appendChild(this.svg);
        this.svg.setAttributeNS(null, 'id', 'main-svg');
        this.svg.setAttributeNS(null, 'width', '100%');
        this.svg.setAttributeNS(null, 'height', '100%');
        this.spec = spec;
        this.scripts = new Set();
    };

    Editor.prototype.newBlock = function(opcode, children) {
        var b = new Bexp.BlockExpr(this, opcode, children);
        return b;
    };

    Editor.prototype.addScript = function(script, x, y) {
        script.group.setAttributeNS(null, 'transform',
                                    'translate(' + x + ', ' + y + ')');
        this.scripts.add(script);
        this.svg.appendChild(script.group);
        script.render();
    };

    Editor.prototype.removeScript = function(block) {
        return this.scripts.delete(block);
    };

    BlockExpr = function(editor, opcode, children) {
        this.editor = editor;
        this.opcode = opcode;
        this.op = editor.spec.blocks[opcode];
        this.children = children;
        this.group = document.createElementNS(Bexp.svgNS, 'g');
        this.rect = document.createElementNS(Bexp.svgNS, 'rect');
        this.rect.setAttributeNS(null, 'height', editor.BLOCK_HEIGHT);
        this.rect.setAttributeNS(null, 'fill', '#0000ff');
        this.group.append(this.rect);
        this.dirty = true;

        (function(self) {
            var childIdx = 0;
            for(var i = 0; i < self.op.grammar.length; ++i) {
                switch(self.op.grammar[i].type) {
                case 'token':
                    var text = document.createElementNS(Bexp.svgNS, 'text');
                    text.textContent = self.op.grammar[i].text;
                    text.setAttributeNS(null, 'font-size', 12);
                    self.group.appendChild(text);
                    break;
                case 'nonterminal':
                    if(childIdx < self.children.length) {
                        self.group.appendChild(self.children[childIdx].group);
                    } else {
                        var placeholder
                            = document.createElementNS(Bexp.svgNS, 'rect');
                        placeholder.setAttributeNS(null, 'width', 20);
                        placeholder.setAttributeNS(null, 'height',
                                                   editor.BLOCK_HEIGHT);
                        self.children.push(null);
                        self.group.appendChild(placeholder);
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
    };

    BlockExpr.prototype.getWidth = function() {
        return this.group.getAttribute('width');
    };

    BlockExpr.prototype.render = function() {
        if(!this.dirty) return;
        this.dirty = false;
        var childIdx = 0;
        this.group.setAttributeNS(null, 'width', this.editor.SPACING);
        var was_modified_past_here = false;
        var width = this.editor.SPACING;
        for(var i = 0; i < this.op.grammar.length; ++i) {
            var is_nonterminal
                = (this.op.grammar[i].type == 'nonterminal');
            if(is_nonterminal) {
                ++childIdx;
            }
            if(true) {
                var foo = -1;
                if(this.op.grammar[i].type == 'token') {
                    foo = this.group.childNodes[i + 1].getComputedTextLength();
                    this.group.childNodes[i + 1].setAttributeNS(
                        null, 'transform', 'translate(' + width + ', ' + '17)'
                    );
                } else if(this.op.grammar[i].type == 'nonterminal') {
                    this.group.childNodes[i + 1].setAttributeNS(
                        null, 'transform', 'translate(' + width + ')'
                    );
                    foo = parseInt(this.group.childNodes[i + 1].getAttribute('width'));
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
