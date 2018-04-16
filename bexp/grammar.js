/**
   This is a DSL for specifying block grammars. The block grammar is decoupled
   from the grammar specification so that different translations (English,
   Spanish, Chinese, etc.) can be written for the same abstract syntax tree.

   When writing this DSL, I experience a sense of deja-vu from my parser
   generator project...
 */

;'use strict';

var Bexp = Bexp || {};

Bexp.Grammar = (function(window, document) {
    var Grammar = function() {
        this.nonterminals = {};
        this.orderedNonterminals = [];
    };

    Grammar.prototype.addNonterminal = function(id, name) {
        var nonterminal = new Bexp.Grammar.Nonterminal(id, name);
        this.nonterminals[id] = nonterminal;
        this.orderedNonterminals.push(id);
        return nonterminal;
    };

    var Nonterminal = function(id, name) {
        this.id = id;
        this.name = name;
        this.productions = {};
        this.orderedProductions = [];
    };

    Nonterminal.prototype.addProduction = function(op) {
        var production = new Bexp.Grammar.Production(this, op, []);
        this.productions[op] = production;
        this.orderedProductions.push(op);
        return production;
    };

    var Production = function(nonterminal, op, symbols) {
        this.nonterminal = nonterminal;
        this.id = op;
        this.symbols = [];
        this.dsl = new Bexp.Grammar.ProductionEditor(this);
    };

    Production.prototype.addToken = function(text) {
        this.symbols.push({type: 'token', text: text});
    };

    Production.prototype.addNonterminal = function(type, id) {
        this.symbols.push({type: 'nonterminal', nonterminal: id});
    };

    Production.prototype.addNewline = function() {
        this.symbols.push({type: 'newline'});
    };

    Production.prototype.addTab = function() {
        this.symbols.push({type: 'tab'});
    };

    var ProductionEditor = function(production) {
        this.raw = production;
        this.indentation = 0;
    };

    ProductionEditor.prototype.tok = function(text) {
        this.raw.addToken(text);
        return this;
    };

    ProductionEditor.prototype.nt = function(type, id) {
        this.raw.addNonterminal(type, id);
        return this;
    };

    ProductionEditor.prototype.endl = function() {
        this.raw.addNewline();
        return this;
    };

    ProductionEditor.prototype.tab = function() {
        this.raw.addTab();
        return this;
    };

    ProductionEditor.prototype.indent = function() {
        ++this.indentation;
        this.raw.addNewline();
        for(var i = 0; i < this.indentation; ++i) {
            this.raw.addTab();
        }
        return this;
    };

    ProductionEditor.prototype.outdent = function() {
        --this.indentation;
        this.raw.addNewline();
        for(var i = 0; i < this.indentation; ++i) {
            this.raw.addTab();
        }
        return this;
    };

    ProductionEditor.prototype.end = function() {
        return this.raw.nonterminal;
    };

    return {
        Grammar: Grammar,
        Nonterminal: Nonterminal,
        Production: Production,
        ProductionEditor: ProductionEditor
    };
})(window, document);
