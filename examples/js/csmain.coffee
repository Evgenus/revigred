require.config
    paths:
        jQuery: 'js/jquery/jquery-1.7.2.min'
        Underscore: 'js/underscore'
        Backbone: 'js/backbone'
        text: "js/require/text"
        order: "js/require/order"
        Stats: 'js/stats'
    shim:
        'Backbone':
            deps: ['Underscore', 'jQuery']
            exports: 'Backbone'
        'Underscore':
            exports: '_'
        'jQueryUi':
            deps: ['Underscore', 'jQuery']
            exports: 'jQuery'
        'Stats':
            exports: 'Stats'
        'jQuery':
            exports: 'jQuery'


define [
    "jQuery",
    "Stats"
], ($, Stats) -> 
    stats = new Stats()
    $(stats.domElement)
        .css("position", 'absolute')
        .css("right", '0px')
        .css("top", '0px')
        .appendTo("body")

    graph = new FlowGraph().add(
        new SumNode({x:100, y:100}),
        new SumNode({x:250, y:100}),
        new SumNode({x:400, y:100}),
        new SumNode({x:550, y:100}),
        new SumNode({x:700, y:100}),
        new SumNode({x:850, y:100}),

        new SumNode({x:100, y:200}),
        new SumNode({x:250, y:200}),
        new SumNode({x:400, y:200}),
        new SumNode({x:550, y:200}),
        new SumNode({x:700, y:200}),
        new SumNode({x:850, y:200}),

        new SumNode({x:100, y:300}),
        new SumNode({x:250, y:300}),
        new SumNode({x:400, y:300}),
        new SumNode({x:550, y:300}),
        new SumNode({x:700, y:300}),
        new SumNode({x:850, y:300})
        )
    view = new GraphView
        model: graph
        el:"#holder"
    view.render(stats.update)
