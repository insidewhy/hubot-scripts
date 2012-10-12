# Description:
#   Allows Hubot to talk to mpd
#
# Dependencies:
#   "mpdsocket": "0.1.0"
#
# Commands:
#   hubot song - Get current song.
#   hubot skip - Skip current song.

mpdsocket = require 'mpdsocket'
mpd = new mpdsocket 'localhost', 6600

getSong = (handler) ->
  mpd.send 'status', (r) ->
    mpd.send 'playlistinfo ' + r.song, (r) ->
      response = "Hark! #{r.Artist or "Unknown artist"}"
      response += " - #{r.Album}" if r.Album
      response += " - #{r.Track}" if r.Track
      response += " - #{r.Title}" if r.Title
      handler response

skipTrack = (handler) ->
  getSong (r) ->
    handler "skipping: #{r}"
    mpd.send 'next', (r) ->
      getSong (r) -> handler "skipped to: #{r}"

respondTo = (msg) -> (arg) -> msg.send arg

module.exports = (robot) ->
  robot.respond /song/i, (msg) ->
    getSong respondTo(msg)

  robot.respond /skip/i, (msg) ->
    skipTrack respondTo(msg)

# vim:ts=2 sw=2
