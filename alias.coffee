# Description:
#   Allows user to create command aliases for Hubot
#
# Commands:
#   hubot alias <alias> <cmd> - Alias cmd to alias
hubot = require 'hubot'

module.exports = (robot) ->
  # global for stopping alias infinite alias recursion
  recursionCount = 0
  aliases = null

  makeAlias = (from, to) ->
    from = from.trim()
    to = to.trim()
    aliases[from] = to
    robot.brain.save()
    robot.commands.push "#{from} - alias for `#{to}'"

    re = new RegExp("^" + from + "( .+)?$")
    robot.hear re, (response) ->
      if ++recursionCount is 100
        response.send 'hit recursion depth of 100'
        return

      msg = new hubot.TextMessage(
        response.message.user, to + (response.match[1] or ''))
      robot.receive msg

      --recursionCount

  robot.respond /alias (\S+)\s+(.*)/, (response) ->
    match = response.match
    makeAlias match[1], match[2]
    response.send "made alias from `#{match[1]}' to `#{match[2]}'"

  # setup
  robot.brain.on 'loaded', ->
    aliases = robot.brain.data.aliases
    if aliases
      for from, to of aliases
        makeAlias from, to
    else
      aliases = robot.brain.data.aliases = {}

# vim:ts=2 sw=2
