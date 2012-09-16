define "revigred.settings", [
],
-> 
    @is_select = (event) ->
        return false if event.which != 1
        return false if event.shiftKey
        return false if event.ctrlKey
        return false if event.altKey
        return true

    @is_join_select = (event) ->
        return false if event.which != 1
        return false if event.shiftKey
        return false if not event.ctrlKey
        return false if event.altKey
        return true

    @get_selection_rule = (ctrl, shift, alt) ->
        return UnionDiff        if     ctrl and not shift and not alt
        return IntersectDiff    if not ctrl and     shift and not alt
        return DifferenceDiff   if not ctrl and not shift and     alt
        return ReplaceDiff      if not ctrl and not shift and not alt
        return null

    null