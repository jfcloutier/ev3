// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "deps/phoenix_html/web/static/js/phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

import socket from "./socket"

// ELM
var elmDiv = document.getElementById('elm-main')
, initialState = {runtimeStatsPort: {ramFree: 0, ramUsed: 0, swapFree: 0, swapUsed: 0},
                  activeStatePort: {active: true},
                  perceptPort: {about: "", value: ""},
                  motivePort: {about: "", on: false, inhibited: false},
                  behaviorPort: {name: "", reflex: false, event: "", value: ""},
                  intentPort: {actuator: "", about: "", value: "", strong: false}
                 }
, elmApp = Elm.embed(Elm.RobotDashboard, elmDiv, initialState);

// Now that you are connected, you can join channels with a topic:
let robot_channel = socket.channel("ev3:dashboard", {})
robot_channel.join()
  .receive("ok", resp => { console.log("ev3:dashboard channel joined succesffuly", resp) })
  .receive("error", resp => { console.log("Unabled to join channel ev3:dashboard", resp) })


robot_channel.on('runtime_stats', data => {
    console.log('Runtime stats', data)
    elmApp.ports.runtimeStatsPort.send(data)
})
robot_channel.on('active_state', data => {
    console.log('Active state', data)
    elmApp.ports.activeStatePort.send(data)
})

robot_channel.on('percept', data => {
    console.log('Percept', data)
    elmApp.ports.perceptPort.send(data)
})

robot_channel.on('motive', data => {
    console.log('motive', data)
    elmApp.ports.motivePort.send(data)
})

robot_channel.on('behavior', data => {
    console.log('behavior', data)
    elmApp.ports.behaviorPort.send(data)
})

robot_channel.on('intent', data => {
    console.log('intent', data)
    elmApp.ports.intentPort.send(data)
})
