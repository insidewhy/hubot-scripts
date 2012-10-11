# Description:
#   Allows Hubot to talk to mpd
#
# Dependencies:
#   "mpdsocket": "0.1.0"
#
# Commands:
#   hubot song - Get current song.
#   !this - Get current song.
#   !c - Get current song.

mpdsocket = require 'mpdsocket'
mpd = new mpdsocket 'localhost', 6600

getSong = (msg) ->
  mpd.send 'status', (r) ->
    mpd.send 'playlistinfo ' + r.song, (r) ->
      response = r.Artist or "Unknown artist"
      response += " - #{r.Album}" if r.Album
      response += " - #{r.Track}" if r.Track
      response += " - #{r.Title}" if r.Title
      msg.send response

module.exports = (robot) ->
  robot.respond /song/i, getSong
  robot.hear /^!(?:this|c) *$/i, getSong
