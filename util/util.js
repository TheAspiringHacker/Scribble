var Util = (function(window, document) {
    const roughlyEquals = function(n, m, range) {
        return Math.abs(n - m) < range;
    };
    const distance = function(p1, p2) {
        return Math.sqrt(Math.pow(p2.x - p1.x, 2) + Math.pow(p2.y - p1.y, 2));
    };
    var List = function(iterable) {
        this.front = null;
        this.back = null;
        this.length = 0;
        iterable = iterable || [];
        for(elem of iterable) {
            var prevBack = this.back;
            this.back = {prev: this.back, val: elem, next: null};
            if(prevBack !== null) {
                prevBack.next = this.back;
            }
            if(this.front === null) {
                this.front = this.back;
            }
            ++this.length;
        }
        this[Symbol.iterator] = function* () {
            var index = this.front;
            while(index !== null) {
                yield index.val;
                index = index.next;
            }
        };
    };
    List.prototype.push = function(elem) {
        var prevBack = this.back;
        this.back = {prev: this.back, val: elem, next: null};
        if(prevBack !== null) {
            prevBack.next = this.back;
        }
        if(this.front === null) {
            this.front = this.back;
        }
        ++this.length;
    };
    List.prototype.pop = function() {
        this.back.prev.next = null;
        this.back = this.back.prev;
        if(this.back === null) {
            this.front = null;
        }
        --this.length;
    };
    List.prototype.insert = function(elem, node) {
        var newNode = {prev: node.prev, val: elem, next: node};
        if(newNode.prev === null) {
            this.front = newNode;
        } else {
            newNode.prev.next = newNode;
        }
        node.prev = newNode;
        ++this.length;
        return newNode;
    };
    List.prototype.remove = function(node) {
        if(node.prev === null) {
            this.front = node.next;
        } else {
            node.prev.next = node.next;
        }
        if(node.next === null) {
            this.back = node.prev;
        } else {
            node.next.prev = node.prev;
        }
        --this.length;
    };
    List.prototype.forEach = function(f) {
        for(x of this) {
            f(x);
        }
    }
    return {
        roughlyEquals: roughlyEquals,
        distance: distance,
        List: List
    }
})(window, document);
