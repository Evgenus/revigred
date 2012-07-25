class FlowNode extends NodeModel
    inputs: {}
    outputs: {}

    constructor: (options) ->
        super(options)
        for name of @inputs
            data = 
                name: name
            _.extend(data, @inputs[name])
            @add(new LeftConnectorModel(data))

        for name of @outputs
            data = 
                name: name
            _.extend(data, @outputs[name])
            @add(new RightConnectorModel(data))

class root.SumNode extends FlowNode
    defaults:
        title: "Sum"

    inputs:
        a: 
            title: "A"
        b:
            title: "B"
    outputs:
        result:
            title: "A+B"

class root.FlowGraph extends GraphModel