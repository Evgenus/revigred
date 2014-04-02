math = Math

$.widget "ui.selector", $.ui.mouse,
    options:
        distance: 0
        tolerance: 'touch'

    _create: ->
        @_mouseInit()
        @tooltip = $("<div class='ui-tooltip ui-widget ui-widget-content'></div>")
        @helper = $("<div class='ui-selectable-helper'></div>")
        @helper.append(@tooltip)
        @anchorX = false
        @anchorY = false

    _destroy: ->
        @_mouseDestroy()

    _mouseStart: (event) ->
        return false if @options.disabled

        @offset = @element.offset()

        @x = event.pageX - @offset.left
        @y = event.pageY - @offset.top

        @shiftKey = event.shiftKey
        @altKey = event.altKey
        @ctrlKey = event.ctrlKey

        @rect = new math.Rect(@x, @y, @x, @y)

        return false if not @_trigger "start", event, this

        $(@element).append(@helper)

        @helper.css
            left: @x
            top: @y
            width: 0
            height: 0

        $(window).on 'keydown.' + @widgetName, (event) =>
            switch event.keyCode
                when 16 then @_setShift(true)
                when 17 then @_setCtrl(true)
                when 18 then @_setAlt(true)
                else return true
            event.preventDefault()
            return false

        $(window).on 'keyup.' + @widgetName, (event) =>
            switch event.keyCode
                when 16 then @_setShift(false)
                when 17 then @_setCtrl(false)
                when 18 then @_setAlt(false)
                else return true
            event.preventDefault()
            return false

    say: (text) ->
        @tooltip.text(text)

    _setAlt: (state) ->
        if @altKey != state
            @altKey = state
            @_trigger "switch", event, this

    _setShift: (state) ->
        if @shiftKey != state
            @shiftKey = state
            @_trigger "switch", event, this

    _setCtrl: (state) ->
        if @ctrlKey != state
            @ctrlKey = state
            @_trigger "switch", event, this

    _mouseDrag: (event) ->
        x = event.pageX - @offset.left
        y = event.pageY - @offset.top        

        anchorX = x > @x
        anchorY = y > @y

        if anchorX != @anchorX
            @anchorX = anchorX
            if anchorX
                @tooltip.css
                    left: "auto"
                    right: 0
            else
                @tooltip.css
                    left: 0
                    right: "auto"

        if anchorY != @anchorY
            @anchorY = anchorY
            if anchorY
                @tooltip.css
                    top: "auto"
                    bottom: 0
            else
                @tooltip.css
                    top: 0
                    bottom: "auto"


        @rect = rect = new math.Rect(@x, @y, x, y)

        @helper.css
            left:   rect.min_x
            top:    rect.min_y
            width:  rect.width
            height: rect.height

        @_trigger "update", event, this

        return false;

    _mouseStop: (event) ->
        $(window).off 'keydown.' + @widgetName
        $(window).off 'keyup.' + @widgetName

        @_trigger "stop", event, this
        @helper.remove()
        return false

    _mouseCapture: (event) -> true