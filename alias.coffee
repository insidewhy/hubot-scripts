# Description:
#   Allows user to create command aliases for Hubot
#
# Commands:
#   hubot alias <alias> <cmd> - Alias cmd to alias
#   hubot unalias <alias> - Remove an alias
hubot = require 'hubot'

module.exports = (robot) ->
  # global for stopping alias infinite alias recursion
  recursionCount = 0
  aliases = null
  aliasCmds = {}

  makeAlias = (from, to) ->
    replaced = false
    aliases[from] = to
    robot.brain.save()
    removeAlias from
    robot.commands.push "#{from} - alias for `#{to}'"

    re = new RegExp("^" + from + "( .+)?$")
    listenerIdx = robot.hear re, (response) ->
      if ++recursionCount is 100
        response.send 'hit recursion depth of 100'
        return

      msg = new hubot.TextMessage(
        response.message.user, to + (response.match[1] or ''))
      robot.receive msg

      --recursionCount

    aliasCmds[from] = robot.listeners[listenerIdx - 1]
    return

  # remove alias, returning true if it was found.
  removeAlias = (from) ->
    existing = aliasCmds[from]
    if existing
      # TODO: push into after command processing else this will interfere
      #       with it!
      for listener, idx in robot.listeners
        if listener is existing
          robot.listeners.splice idx, 1
          return true
    return false

  robot.respond /alias +(\S+)\s+(.*)\s*$/, (response) ->
    match = response.match
    makeAlias match[1], match[2]
    response.finish() # in case makeAlias spliced the listeners
    response.send "made alias from `#{match[1]}' to `#{match[2]}'"

  robot.respond /unalias +(\S+)\s*$/, (response) ->
    alias = response.match[1]
    if removeAlias alias
      response.finish()
      delete aliases[alias]
      robot.brain.save()
      response.send "removed alias `#{alias}'"
    else
      response.send "alias `#{alias}' was not found"

  # setup
  robot.brain.on 'loaded', ->
    aliases = robot.brain.data.aliases
    if aliases
      for from, to of aliases
        makeAlias from, to
    else
      aliases = robot.brain.data.aliases = {}

# vim:ts=2 sw=2
