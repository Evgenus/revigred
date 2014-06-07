fs = require "fs"

{exec} = require 'child_process'

source_dir = "./src"
output_dir = "lib"
project_name = "revigred.js"

task "build", "compile all coffeescript files to javascript", ->
  cmd = ["coffee", "--join", project_name, "--compile", "--output", output_dir, source_dir].join(" ")
  console.log(cmd)
  exec cmd, (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr

task "sbuild", "build routine for sublime", ->
  invoke 'build'

