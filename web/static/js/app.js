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
, initialState = {runtimeStats: {ramFree: 0, ramUsed: 0, swapFree: 0, swapUsed: 0}}
, elmApp = Elm.embed(Elm.Ev3Dashboard, elmDiv, initialState);

// Now that you are connected, you can join channels with a topic:
let rt_channel = socket.channel("ev3:runtime", {})
rt_channel.join()
  .receive("ok", resp => { console.log("ev3:runtime channel joined succesffuly", resp) })
  .receive("error", resp => { console.log("Unabled to join channel ev3:runtime", resp) })

rt_channel.on('runtime_stats', data => {
    console.log('Runtime stats', data)
    elmApp.ports.runtimeStats.send(data)
})

