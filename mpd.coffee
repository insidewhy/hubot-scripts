# Description:
#   Allows Hubot to talk to mpd
#
# Dependencies:
#   "mpdsocket": "0.1.0"
#
# Commands:
#   hubot song - Get current song.
#   hubot skip - Skip current song.

host = 'localhost'
port = 6600

mpdsocket = require 'mpdsocket'
mpd = new mpdsocket host, port

send = (cmd, handler, attempt = 0) ->
  try
    mpd.send cmd, handler
  catch e
    if attempt is 5
      handler "Could not connect to mpd, tried 5 times"
    else
      # responding to the connect like this doesn't work, need to add
      # another event to mpdsocket
      mpd.on 'connect', () -> send(cmd, handler, attempt + 1)
      mpd.open host, port
  return

getSong = (handler) ->
  send 'status', (r) ->
    send 'playlistinfo ' + r.song, (r) ->
      response = "Hark! #{r.Artist or "Unknown artist"}"
      response += " - #{r.Album}" if r.Album
      response += " - #{r.Track}" if r.Track
      response += " - #{r.Title}" if r.Title
      handler response

skipTrack = (handler) ->
  getSong (r) ->
    handler "skipping: #{r}"
    send 'next', (r) ->
      getSong (r) -> handler "skipped to: #{r}"

respondTo = (msg) -> (arg) -> msg.send arg

module.exports = (robot) ->
  robot.respond /song/i, (msg) ->
    getSong respondTo(msg)

  robot.respond /skip/i, (msg) ->
    skipTrack respondTo(msg)

# vim:ts=2 sw=2
