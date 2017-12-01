var spec = {
    'ordered-categories' : ['expr', 'pattern', 'type'],
    'categories' : {
        'expr' : {
            'id' : 'Expression',
            'blocks' : {
                'apply' : {
                    'grammar' : [
                        {
                            'type' : 'nonterminal',
                            'id' : 'fun',
                            'category' : 'expr'
                        },
                        {
                            'type' : 'nonterminal',
                            'id' : 'arg',
                            'category' : 'expr'
                        }
                    ]
                },
                'if' : {
                    'grammar' : [
                        {'type' : 'token', 'text' : 'if'},
                        {
                            'type' : 'nonterminal',
                            'id' : 'pred',
                            'category' : 'expr'
                        },
                        {'type' : 'token', 'text' : 'then'},
                        {
                            'type' : 'nonterminal',
                            'id' : 'cons',
                            'category' : 'expr'
                        },
                        {'type' : 'token', 'text' : 'else'},
                        {
			    'type' : 'nonterminal',
			    'id' : 'alt',
                            'categories' : ['expr']
                        }
                    ]
                },
                'let' : {
                    'grammar' : [
                        {'type' : 'token', 'text' : 'let'},
                        {'type' : 'variadic', 'id' : 'bindings', 'grammar' : [
                            {
                                'type' : 'nonterminal',
                                'id' : 'pattern',
                                'category' : 'pattern'
                            },
                            {'type' : 'token', 'text' : '='},
                            {
                                'type' : 'nonterminal',
                                'id' : 'expr',
                                'category' : 'expr'
                            }
                        ]},
                        {'type' : 'token', 'text' : 'in'},
                        {
                            'type' : 'nonterminal',
                            'id' : 'body',
                            'category' : 'expr'
                        }
                    ]
                },
                'letRec' : {
                    'grammar' : [
                        {'type' : 'token', 'text' : 'let rec'},
                        {'type' : 'variadic', 'grammar' : [
                            {
                                'type' : 'nonterminal',
                                'id' : 'pattern',
                                'category' : 'pattern'
                            },
                            {'type' : 'token', 'text' : '='},
                            {
                                'type' : 'nonterminal',
                                'id' : 'expr',
                                'category' : 'expr'
                            }
                        ]},
                        {'type' : 'token', 'text' : 'in'},
                        {
                            'type' : 'nonterminal',
                            'id' : 'body',
                            'category' : 'expr'
                        }
                    ]
                },
                'match' : {
                    'grammar' : [
                        {'type' : 'token', 'text' : 'match'},
                        {
                            'type' : 'nonterminal',
                            'id' : 'test',
                            'category' : 'expr'
                        },
                        {'type' : 'token', 'text' : 'with'},
                        {'type' : 'variadic', 'id' : 'cases', 'grammar' : [
                            {
                                'type' : 'nonterminal',
                                'id' : 'pattern',
                                'category' : 'pattern'
                            },
                            {'type' : 'token', 'text' : '->'},
                            {
                                'type' : 'nonterminal',
                                'id' : 'cons',
                                'category' : 'expr'
                            }
                        ]}
                    ]
                },
                'tuple' : {
                    'grammar' : [
                        {'type' : 'token', 'text' : '('},
                        {'type' : 'variadic', 'grammar' : [
                            {
                                 'type' : 'nonterminal',
                                 'id' : 'expr',
                                 'category' : 'expr'
                            }
                        ]},
                        {'type' : 'token', 'text' : ')'}
                    ]
                }
	    }
        },
        'pattern' : {
            'id' : 'Pattern',
            'blocks' : {
            }
        },
        'type' : {
            'id' : 'Type',
            'blocks' : {
                "function" : {
                    
                }
            }
        }
    },
};
