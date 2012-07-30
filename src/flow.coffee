define [
    "revigred.models.NodeModel"
,   "revigred.models.GraphModel"
],
-> 
    models = namespace 'revigred.models'
    flow = namespace 'revigred.flow'

    class flow.FlowNode extends models.NodeModel
        inputs: {}
        outputs: {}

        constructor: (options) ->
            super(options)
            for name of @inputs
                data = 
                    name: name
                _.extend(data, @inputs[name])
                @add(new models.LeftConnectorModel(data))

            for name of @outputs
                data = 
                    name: name
                _.extend(data, @outputs[name])
                @add(new models.RightConnectorModel(data))

    class flow.SumNode extends flow.FlowNode
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

    class flow.FlowGraph extends models.GraphModel