/**
    spec.js - Language display rules
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

var spec = {
    'categories' : [
        {
            'id' : 'Expression',
            'blocks' : ['apply', 'if', 'let', 'letRec', 'match', 'tuple']
        },
        {
            'id' : 'Pattern',
            'blocks' : []
        },
        {
            'id' : 'Type',
            'blocks' : []
        }
    ],
    'blocks' : {
        'apply' : {
            'grammar' : [
                {
                    'type' : 'nonterminal',
                    'id' : 'fun',
                    'nonterminal' : 'expr'
                },
                {
                    'type' : 'nonterminal',
                    'id' : 'arg',
                    'nonterminal' : 'expr'
                }
            ],
            'category' : 'expr'
        },
        'if' : {
            'grammar' : [
                {'type' : 'token', 'text' : 'if'},
                {
                    'type' : 'nonterminal',
                    'id' : 'pred',
                    'nonterminal' : 'expr'
                },
                {'type' : 'newline'},
                {'type' : 'token', 'text' : 'then'},
                {
                    'type' : 'nonterminal',
                    'id' : 'cons',
                    'nonterminal' : 'expr'
                },
                {'type' : 'newline'},
                {'type' : 'token', 'text' : 'else'},
                {
                    'type' : 'nonterminal',
                    'id' : 'alt',
                    'nonterminal' : 'expr'
                }
            ],
            'nonterminal' : 'expr'
        },
        'let' : {
            'grammar' : [
                {'type' : 'token', 'text' : 'let'},
                {'type' : 'variadic', 'id' : 'bindings', 'grammar' : [
                    {
                        'type' : 'nonterminal',
                        'id' : 'pattern',
                        'nonterminal' : 'pattern'
                    },
                    {'type' : 'token', 'text' : '='},
                    {
                        'type' : 'nonterminal',
                        'id' : 'expr',
                        'nonterminal' : 'expr'
                    }
                ]},
                {'type' : 'token', 'text' : 'in'},
                {
                    'type' : 'nonterminal',
                    'id' : 'body',
                    'nonterminal' : 'expr'
                }
            ],
            'nonterminal' : 'expr'
        },
        'letRec' : {
            'grammar' : [
                {'type' : 'token', 'text' : 'let rec'},
                {'type' : 'variadic', 'grammar' : [
                    {
                        'type' : 'nonterminal',
                        'id' : 'pattern',
                        'nonterminal' : 'pattern'
                    },
                    {'type' : 'token', 'text' : '='},
                    {
                        'type' : 'nonterminal',
                        'id' : 'expr',
                        'nonterminal' : 'expr'
                    }
                ]},
                {'type' : 'token', 'text' : 'in'},
                {
                    'type' : 'nonterminal',
                    'id' : 'body',
                    'nonterminal' : 'expr'
                }
            ],
            'nonterminal' : 'expr'
        },
       'match' : {
            'grammar' : [
                {'type' : 'token', 'text' : 'match'},
                {
                    'type' : 'nonterminal',
                    'id' : 'test',
                    'nonterminal' : 'expr'
                },
                {'type' : 'token', 'text' : 'with'},
                {'type' : 'variadic', 'id' : 'cases', 'grammar' : [
                    {
                        'type' : 'nonterminal',
                        'id' : 'pattern',
                        'nonterminal' : 'pattern'
                    },
                    {'type' : 'token', 'text' : '->'},
                    {
                        'type' : 'nonterminal',
                        'id' : 'cons',
                        'nonterminal' : 'expr'
                    }
                ]}
            ],
            'nonterminal' : 'expr'
        },
        'tuple' : {
            'grammar' : [
                {'type' : 'token', 'text' : '('},
                {'type' : 'variadic', 'grammar' : [
                    {
                        'type' : 'nonterminal',
                        'id' : 'expr',
                        'nonterminal' : 'expr'
                    }
                ]},
                {'type' : 'token', 'text' : ')'}
            ],
            'nonterminal' : 'expr'
        }
    }
};
