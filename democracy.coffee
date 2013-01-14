# Description:
#   Allows users to create and participate in voting polls.
#
# Commands:
#   hubot question add <question> - add a question and respond with its ID.
#   hubot question remove <id> - remove a question.
#   hubot question <id> - show a question.
#   hubot answer add <id> <answer> - add an answer to a question.
#   hubot answer remove <question id> <answer id> - remove an answer from a question.
#   hubot vote <question id> <answer id> - vote for a particular answer.
#   hubot questions - show all questions.
hubot = require 'hubot'

module.exports = (robot) ->
  questions = null
  ignoring  = null # people not to send messages to

  robot.respond /question add +(.+)[\s\?]*$/, (r) ->
    q = r.match[1]
    questions.push { text: "#{q}", answers: [] }
    robot.brain.save()
    r.send "added questionnaire ##{questions.length}"

  getQuestion = (r, qId, callback) ->
    if qId < questions.length
      callback(questions[qId])
    else
      r.send "invalid question id"

  robot.respond /question remove (\d+)/, (r) ->
    qId = r.match[1] - 1
    getQuestion r, qId, ->
      questions.splice qId, 1
      robot.brain.save()
      r.send "removed question #{qId + 1}"

  robot.respond /question (\d+)/, (r) ->
    qId = r.match[1] - 1
    getQuestion r, qId, (q) ->
      r.send "#{qId + 1}: #{q.text}"
      for answer, aId in q.answers
        r.send "  #{aId + 1}: #{answer.text} - " +
               "#{answer.votedBy.length} (#{answer.votedBy.join ', '})"

  robot.respond /questions/, (r) ->
    if not questions.length
      r.send "no questions available"
    else
      for q, i in questions
        r.send "#{i + 1}: #{q.text}"

  robot.respond /answer add (\d+) (.+) *$/, (r) ->
    qId = r.match[1] - 1
    getQuestion r, qId, (q) ->
      q.answers.push { text: r.match[2], votedBy: [] }
      robot.brain.save()
      r.send "added answer"

  robot.respond /answer remove (\d+) (\d+) *$/, (r) ->
    qId = r.match[1] - 1
    getQuestion r, qId, (q) ->
      aId = r.match[2] - 1
      if aId >= q.answers.length
        r.send "invalid answer id"
      else
        q.answers.splice aId, 1
        r.send "deleted answer"
      return

  robot.respond /vote (\d+) (\d+) *$/, (r) ->
    qId = r.match[1] - 1
    getQuestion r, qId, (q) ->
      aId = r.match[2] - 1
      if aId >= q.answers.length
        r.send "invalid answer id"
        return

      userId = r.message.user.id

      # remove existing vote if there is one
      changed = do ->
        for answer in q.answers
          for v, i in answer.votedBy
            if v is userId
              answer.votedBy.splice i, 1
              return true
        return false

      if changed
        r.send "changed vote"
      else
        r.send "registered vote"

      q.answers[aId].votedBy.push userId

  robot.respond /ignore (\w+) *$/, (r) ->
    toIgnore = r.match[1]
    if ignoring
      already = ignoring[toIgnore]
      if already
        r.send "already ignoring #{toIgnore}"
      else
        ignoring[toIgnore] = 1
        r.send "now ignoring #{toIgnore}"
    return

  robot.respond /unignore (\w+) *$/, (r) ->
    toIgnore = r.match[1]
    if ignoring
      already = ignoring[toIgnore]
      if already
        delete ignoring[toIgnore]
        r.send "no longer ignoring #{toIgnore}"
      else
        r.send "already not ignoring #{toIgnore}"
    return

  robot.enter (r) ->
    userId = r.message.user.id
    return if ignoring[userId]

    for q, qId in questions
      answered = do ->
        for answer in q.answers
          for v, i in answer.votedBy
            if v is userId
              return true
        return false
      if not answered
        r.send "#{userId}: unvoted question, please see !question #{qId + 1}"

  robot.brain.on 'loaded', ->
    questions = robot.brain.data.questions
    if not questions
      questions = robot.brain.data.questions = []

    ignoring = robot.brain.data.ignoring
    if not ignoring
      ignoring = robot.brain.data.ignoring = {}

# vim:ts=2 sw=2
