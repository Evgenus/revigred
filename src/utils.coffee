define [
],
-> 
    root = this

    _isinstance = (t, types...) ->
        for type in types
            if type is t
                return true
        return _isinstance(t.__proto__, types...) if t.__proto__?
        return false

    root.isinstance = (value, types...) ->
        types = (type.prototype for type in types)
        return _isinstance(value, types...)

    root.requestAnimationFrame = 
        window.requestAnimationFrame       ||
        window.webkitRequestAnimationFrame ||
        window.mozRequestAnimationFrame    ||
        window.oRequestAnimationFrame      ||
        window.msRequestAnimationFrame     ||
        (callback) -> window.setTimeout(callback, 20)