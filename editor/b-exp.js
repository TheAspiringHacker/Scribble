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

'use strict';

const Bexp = (function() {
    return {
        Editor : function(editor, spec) {
            this.editor = editor;
            this.palette = document.createElement('div');
            this.palette.setAttribute('id', 'sidebar');
            this.editor.appendChild(this.palette);

            var list = document.createElement('ul');
            list.setAttribute('id', 'categories');
            for(var i = 0; i < spec.categories.length; ++i) {
                var listDiv = document.createElement('div');
                listDiv.textContent
                    = spec.categories[i].id;
                listDiv.setAttribute('class', 'category');
                var li = document.createElement('li');
                li.appendChild(listDiv);
                list.appendChild(li);
            }
            this.palette.appendChild(list);

            this.scriptArea = document.createElement('div');
            this.scriptArea.setAttribute('id', 'scripts');
            this.editor.appendChild(this.scriptArea);
            this.svg = document.createElement('svg');
            this.svg.setAttribute('id', 'main-svg');
            this.svg.setAttribute('width', this.scriptArea.width);
            this.svg.setAttribute('height', this.scriptArea.height);
            this.scriptArea.appendChild(this.svg);
            this.spec = spec;

            this.createSVGFromSpec = function(op, x, y, children) {
                g = document.createElement('g');
                return g;
            };

            this.newBlock = function(op, x, y) {
                return {
                    'children' : [],
                    'svg' : this.createSVGFromSpec(op, x, y, [])
                };
            };
        }
    };
})();
