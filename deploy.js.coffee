sys = require 'sys'
exec = (require 'child_process').exec
five = require 'johnny-five'
board = new five.Board
  # port: "/dev/tty.usbmodemfa141"

board.on 'ready', ->
  # Global variables
  potThresh = 768
  inProgress = false
  environment =
    'current': branch
    'old': branch

  branch =
    'name': 'branch'
    'color':
      'red': 0
      'green': 255
      'blue': 0

  master =
    'name': 'master'
    'color':
      'red': 255
      'green': 0
      'blue': 0

  # Lights
  rgb = new five.Led.RGB [6, 5, 3]
  red = new five.Led { pin: 10 }
  yellow = new five.Led { pin: 9 }

  # Sensors
  potentiometer = new five.Sensor
    pin: "A3"
    freq: 250

  button = new five.Button { pin: 8 }

  # Sensor events
  potentiometer.on 'read', ->
    environment.old = environment.current
    if @.value < potThresh
      environment.current = branch
    else
      environment.current = master

    if environment.current != environment.old
      rgb.color rgbToHex environment.current.color

  button.on 'down', ->
    push()

  # Functions
  push = ->
    if !inProgress
      inProgress = true
      console.log 'Deploying to ' + environment.current.name + '.'
      yellow.strobe 500
      command = ''
      if environment.current == master
        command = 'git push origin masters'
      else
        command = 'git push origin $(git rev-parse --abbrev-ref HEAD)'
      exec command, (error, stdout, stderr) ->
        yellow.stop().off()
        console.log stdout
        console.log 'Finished successfully'
        inProgress = false
    else
      console.log 'Deploy already in progress.'

  compToHex = (comp) ->
    hex = comp.toString 16
    if hex.length == 1 then "0" + hex else hex

  rgbToHex = (color) ->
    (compToHex color.red) + (compToHex color.green) + (compToHex color.blue)
