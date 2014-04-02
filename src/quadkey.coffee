define [
],
->
    root = this

    class root.QuadKey
        constructor: (@code) ->
            @code ?= ""
        
        decode: (code) ->
            seq = []
            for char in code 
                switch char
                    when "@" then seq.push(0)       #00000 0
                    when "D" then seq.push(0, 0)    #00100 4
                    when "E" then seq.push(0, 1)    #00101 5
                    when "F" then seq.push(0, 2)    #00110 6
                    when "G" then seq.push(0, 3)    #00111 7
                    when "H" then seq.push(1)       #01000 8
                    when "L" then seq.push(1, 0)    #01100 12
                    when "M" then seq.push(1, 1)    #01101 13
                    when "N" then seq.push(1, 2)    #01110 14
                    when "O" then seq.push(1, 3)    #01111 15
                    when "P" then seq.push(2)       #10000 16
                    when "T" then seq.push(2, 0)    #10100 20
                    when "U" then seq.push(2, 1)    #10101 21
                    when "V" then seq.push(2, 2)    #10110 22
                    when "W" then seq.push(2, 3)    #10111 23
                    when "X" then seq.push(3)       #11000 24 
                    when "\\" then seq.push(3, 0)   #11100 28
                    when "]" then seq.push(3, 1)    #11101 29
                    when "^" then seq.push(3, 2)    #11110 30
                    when "_" then seq.push(3, 3)    #11111 31

            return seq

        encode: (seq) ->
            result = ""
            len = seq.length
            index = 0
            while true
                break if index >= len
                first = seq[index++]
                if index >= len
                    switch first
                        when 0 then result += "@"
                        when 1 then result += "H"
                        when 2 then result += "P"
                        when 3 then result += "X"
                else
                    second = seq[index++]
                    switch first
                        when 0 then switch second
                            when 0 then result += "D"
                            when 1 then result += "E"
                            when 2 then result += "F"
                            when 3 then result += "G"
                        when 1 then switch second
                            when 0 then result += "L"
                            when 1 then result += "M"
                            when 2 then result += "N"
                            when 3 then result += "O"
                        when 2 then switch second
                            when 0 then result += "T"
                            when 1 then result += "U"
                            when 2 then result += "V"
                            when 3 then result += "W"
                        when 3 then switch second
                            when 0 then result += "\\"
                            when 1 then result += "]"
                            when 2 then result += "^"
                            when 3 then result += "_"

            return result

        tl: ->
            seq = @decode(@code)
            seq.push(0)
            return new @constructor(@encode(seq))

        tr: ->
            seq = @decode(@code)
            seq.push(1)
            return new @constructor(@encode(seq))
        bl: ->
            seq = @decode(@code)
            seq.push(3)
            return new @constructor(@encode(seq))

        br: ->
            seq = @decode(@code)
            seq.push(2)
            return new @constructor(@encode(seq))
