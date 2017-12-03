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
                {'type' : 'token', 'text' : 'then'},
                {
                    'type' : 'nonterminal',
                    'id' : 'cons',
                    'nonterminal' : 'expr'
                },
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
