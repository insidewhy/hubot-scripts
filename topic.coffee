# Description:
#   Allows Hubot to change the topic via a command
#
# Commands:
#   hubot topic <new topic> - Set the new topic.

module.exports = (robot) ->
  robot.respond /topic +(.*) *$/i, (r) ->
    r.topic r.match[1]
