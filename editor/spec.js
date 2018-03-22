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

const SPEC = {
    'categories' : [
        {
            'id' : 'Expression'
        },
        {
            'id' : 'Pattern'
        },
        {
            'id' : 'Type'
        }
    ],
    'nonterminals' : {
        'expr' : {
            'apply' : [
                {
                    'type' : 'nonterminal',
                    'nonterminal' : 'expr'
                },
                {
                    'type' : 'nonterminal',
                    'nonterminal' : 'expr'
                }
            ],
            'if' : [
                {'type' : 'token', 'text' : 'if'},
                {
                    'type' : 'nonterminal',
                    'nonterminal' : 'expr'
                },
                {'type' : 'token', 'text' : 'then'},
                {'type' : 'newline'},
                {'type' : 'tab'},
                {
                    'type' : 'nonterminal',
                    'nonterminal' : 'expr'
                },
                {'type' : 'newline'},
                {'type' : 'token', 'text' : 'else'},
                {'type' : 'newline'},
                {'type' : 'tab'},
                {
                    'type' : 'nonterminal',
                    'nonterminal' : 'expr'
                }
            ],
            'let' : [
                {'type' : 'token', 'text' : 'let'},
                {
                    'type' : 'nonterminal',
                    'nonterminal' : 'pattern'
                },
                {'type' : 'token', 'text' : 'in'},
                {'type' : 'newline'},
                {
                    'type' : 'nonterminal',
                    'nonterminal' : 'expr'
                }
            ],
            'letRec' : [
                {'type' : 'token', 'text' : 'let rec'},
                {
                    'type' : 'nonterminal',
                    'nonterminal' : 'pattern'
                },
                {'type' : 'token', 'text' : 'in'},
                {'type' : 'newline'},
                {
                    'type' : 'nonterminal',
                    'nonterminal' : 'expr'
                }
            ],
            'match' : [
                {'type' : 'token', 'text' : 'switch'},
                {
                    'type' : 'nonterminal',
                    'nonterminal' : 'expr'
                },
                {'type' : 'token', 'text' : 'with'},
                {'type' : 'newline'},
                {
                    'type' : 'nonterminal',
                    'nonterminal' : 'case'
                }
            ],
            'seq' : [
                {
                    'type' : 'nonterminal',
                    'nonterminal' : 'expr'
                },
                {'type' : 'token', 'text' : ';'},
                {'type' : 'newline'},
                {
                    'type' : 'nonterminal',
                    'nonterminal' : 'expr'
                }
            ]
        },
        'bindingList' : {
            'cons' : [
                {
                    'type' : 'nonterminal',
                    'nonterminal' : 'pattern'
                },
                {'type' : 'token', 'text' : '='},
                {
                    'type' : 'nonterminal',
                    'nonterminal' : 'expr'
                },
                {'type' : 'token', 'text' : 'and'},
                {'type' : 'newline'},
                {
                    'type' : 'nonterminal',
                    'nonterminal' : 'bindingList'
                }
            ],
            'nil' : [
                {'type' : 'token', 'text' : 'end defs'}
            ]
        },
        'case' : {
            'case' : [
                {'type' : 'token', 'text' : 'case'},
                {
                    'type' : 'nonterminal',
                    'nonterminal' : 'pattern'
                },
                {'type' : 'token', 'text' : ':'},
                {'type' : 'newline'},
                {'type' : 'tab'},
                {
                    'type' : 'nonterminal',
                    'nonterminal' : 'expr'
                }
            ],
            'caseIf' : [
                {'type' : 'token', 'text' : 'case'},
                {
                    'type' : 'nonterminal',
                    'nonterminal' : 'pattern'
                },
                {'type' : 'token', 'text' : 'if'},
                {
                    'type' : 'nonterminal',
                    'nonterminal' : 'expr'
                },
                {'type' : 'token', 'text' : ':'},
                {'type' : 'newline'},
                {'type' : 'tab'},
                {
                    'type' : 'nonterminal',
                    'nonterminal' : 'expr'
                }
            ],
        },
        'caseList' : {
            'cons' : [
                {'type' : 'token', 'text' : '|'},
                {
                    'type' : 'nonterminal',
                    'nonterminal' : 'case'
                },
                {'type' : 'newline'},
                {
                    'type' : 'nonterminal',
                    'nonterminal' : 'caseList'
                }
            ],
            'nil' : [
                {'type' : 'token', 'text' : 'end switch'}
            ]
        }
    }
};
