-- One shared Gold Coast: a match on the server that everyone logged in joins
-- ("the town"). The game finds it with the "town" function (in gold_coast.lua),
-- which starts it if it isn't running.
--
-- Each player's game sends where she is about 10 times a second: a little JSON
-- (OP_MOVE) with her position, which way she faces, how fast she's walking,
-- and what she's doing. The town passes it on to everyone else, saying whose
-- it is, and keeps the latest one, so a player who joins is told straight
-- away where everyone already is. When someone leaves, Nakama tells the others.
--
-- The town also keeps Gold Coast's clock, so everyone online has the same time
-- of day (OP_CLOCK, with "minutes" since midnight). It goes at one game minute
-- for each real second (a day lasts 24 real minutes), counted from the
-- server's own clock. It's sent to each player who joins, and to everyone
-- every 10 seconds, so their clocks stay together.

local nk = require("nakama")

local OP_MOVE = 1
local OP_CLOCK = 2
local MOST_BYTES = 512 -- a move is about 80; anything bigger isn't a move
local TICKS_PER_SECOND = 10
local CLOCK_EVERY = 10 * TICKS_PER_SECOND -- ticks between telling everyone the time
local MINUTES_PER_DAY = 24 * 60

-- The time of day in Gold Coast, as the message that tells it.
local function clock_message()
  local minutes = (nk.time() / 1000) % MINUTES_PER_DAY -- nk.time() is in milliseconds
  return nk.json_encode({ minutes = minutes })
end

local town = {}

function town.match_init(context, params)
  local state = { presences = {}, moves = {} }
  local label = "town"
  return state, TICKS_PER_SECOND, label
end

function town.match_join_attempt(context, dispatcher, tick, state, presence, metadata)
  return state, true
end

function town.match_join(context, dispatcher, tick, state, presences)
  for _, presence in ipairs(presences) do
    state.presences[presence.session_id] = presence
    dispatcher.broadcast_message(OP_CLOCK, clock_message(), { presence }, nil)
    -- Tell the newcomer where everyone already is.
    for session_id, move in pairs(state.moves) do
      local mover = state.presences[session_id]
      if mover ~= nil and session_id ~= presence.session_id then
        dispatcher.broadcast_message(OP_MOVE, move, { presence }, mover)
      end
    end
  end
  return state
end

function town.match_leave(context, dispatcher, tick, state, presences)
  for _, presence in ipairs(presences) do
    state.presences[presence.session_id] = nil
    state.moves[presence.session_id] = nil
  end
  return state
end

function town.match_loop(context, dispatcher, tick, state, messages)
  for _, message in ipairs(messages) do
    if message.op_code == OP_MOVE and #message.data <= MOST_BYTES then
      local sender = message.sender
      state.moves[sender.session_id] = message.data
      local others = {}
      for session_id, presence in pairs(state.presences) do
        if session_id ~= sender.session_id then
          table.insert(others, presence)
        end
      end
      if #others > 0 then
        dispatcher.broadcast_message(OP_MOVE, message.data, others, sender)
      end
    end
  end
  if tick % CLOCK_EVERY == 0 and next(state.presences) ~= nil then
    dispatcher.broadcast_message(OP_CLOCK, clock_message(), nil, nil)
  end
  return state -- the town keeps running, even when it's empty
end

function town.match_terminate(context, dispatcher, tick, state, grace_seconds)
  return state
end

function town.match_signal(context, dispatcher, tick, state, data)
  return state, data
end

return town
