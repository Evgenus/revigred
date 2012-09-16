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

    Function::property = (prop, desc) ->
        Object.defineProperty @prototype, prop, desc

# ____________________________________________________________________________ #

    class root.Diff
        constructor: (@old=[], @new) ->
            @new ?= @old

        @property 'removed',
            get: -> @_removed ?= _.difference(@old, @new)

        @property 'unchanged',
            get: -> @_unchanged ?= _.intersect(@old, @new)

        @property 'added',
            get: -> @_added ?= _.difference(@new, @old)

        clear: ->
            delete @_removed
            delete @_unchanged
            delete @_added

        update: (current) ->
            @old = @new
            @new = current
            @clear()

# ____________________________________________________________________________ #

    class root.DiffWithBase
        clear: ->
            delete @_remain
            delete @_unset
            delete @_common
            delete @_added
            delete @_removed
            delete @_result

        update: (@current=[]) ->
            @diff.update(@current)
            @clear()

# ____________________________________________________________________________ #

    class root.UnionDiff extends root.DiffWithBase
        name: "Union"

        constructor: (@base) ->
            @diff = new root.Diff()

        @property 'remain', # grey
            get: -> @_remain ?= _.intersect(@diff.removed, @base)

        @property 'unset', # clear
            get: -> @_unset ?= _.difference(@diff.removed, @base)

        @property 'common', # yellow
            get: -> @_common ?= _.intersect(@diff.added, @base)

        @property 'added', # green
            get: -> @_added ?= _.difference(@diff.added, @base)

        @property 'removed', # red
            get: -> @_removed ?= []

        @property 'result',
            get: -> @_result ?= new root.Diff(@base, _.union(@base, @current))

# ____________________________________________________________________________ #

    class root.ReplaceDiff extends root.DiffWithBase
        name: "Replace"

        constructor: (@base) ->
            @diff = new root.Diff(@base)

        @property 'remain', # grey
            get: -> @_remain ?= [] 

        @property 'unset', # clear
            get: -> @_unset ?= _.difference(@diff.removed, @base)

        @property 'common', # yellow
            get: -> @_common ?= _.intersect(@diff.added, @base)

        @property 'added', # green
            get: -> @_added ?= _.difference(@diff.added, @base)

        @property 'removed', # red
            get: -> @_removed ?= _.intersect(@base, @diff.removed)

        @property 'result',
            get: -> @_result ?= new root.Diff(@base, @current)

# ____________________________________________________________________________ #

    class root.IntersectDiff extends root.DiffWithBase
        name: "Intersect"

        constructor: (@base) ->
            @diff = new root.Diff(@base)

        @property 'remain', # grey
            get: -> @_remain ?= [] 

        @property 'unset', # clear
            get: -> @_unset ?= _.difference(@diff.removed, @base)

        @property 'common', # yellow
            get: -> @_common ?= _.intersect(@diff.added, @base)

        @property 'added', # green
            get: -> @_added ?= []

        @property 'removed', # red
            get: -> @_removed ?= _.intersect(@base, @diff.removed)

        @property 'result',
            get: -> @_result ?= new root.Diff(@base, _.intersect(@base, @current))

# ____________________________________________________________________________ #

    class root.DifferenceDiff extends root.DiffWithBase
        name: "Difference"

        constructor: (@base) ->
            @diff = new root.Diff()

        @property 'remain', # grey
            get: -> @_remain ?= _.intersect(@base, @diff.removed)

        @property 'unset', # clear
            get: -> @_unset ?= []

        @property 'common', # yellow
            get: -> @_common ?= []

        @property 'added', # green
            get: -> @_added ?= []

        @property 'removed', # red
            get: -> @_removed ?= _.intersect(@base, @diff.added)

        @property 'result',
            get: -> @_result ?= new root.Diff(@base, _.difference(@base, @current))
