-- Gold Coast's rules on the server. Nakama runs this file when it starts
-- (it's in server/modules/, which docker-compose.yml shares with Nakama). It
-- checks new accounts, and finds the shared town (town.lua) for the game.
--
-- Making an account: the game sends the player's name, date of birth, and
-- which terms they agreed to (as "vars", next to the email, password, and
-- username), and the server checks them before the account is made:
-- - a username of 3 to 20 small letters, numbers, or underscores
-- - a name
-- - 18 or older
-- - they agreed to the current terms
-- Once it's made, the account keeps the name (as its display name), and the
-- date of birth and agreement in its metadata, which only the server can
-- change.

local nk = require("nakama")

-- The terms players agree to. The game sends the same (Online.TERMS_VERSION).
local TERMS_VERSION = "2026-10-30"
local MIN_AGE = 18

-- gRPC error codes, which the game reads to tell what went wrong.
local INVALID_ARGUMENT = 3
local PERMISSION_DENIED = 7

-- Whole years from a date of birth ("YYYY-MM-DD") to today, or nil.
local function age_of(birthdate)
  local y, m, d = string.match(birthdate or "", "^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
  if not y then
    return nil
  end
  y, m, d = tonumber(y), tonumber(m), tonumber(d)
  local today = os.date("!*t")
  local age = today.year - y
  if today.month < m or (today.month == m and today.day < d) then
    age = age - 1
  end
  return age
end

-- Before an email login: if it's making a new account, check what was sent.
local function check_new_account(context, payload)
  if not payload.create then
    return payload -- logging in to an account that exists
  end
  local vars = (payload.account and payload.account.vars) or {}
  local username = payload.username or ""
  if #username < 3 or #username > 20 or not string.match(username, "^[a-z0-9_]+$") then
    error({ "A username needs 3 to 20 small letters, numbers, or underscores.", INVALID_ARGUMENT })
  end
  if (vars.name or "") == "" then
    error({ "Please give your name.", INVALID_ARGUMENT })
  end
  local age = age_of(vars.birthdate)
  if age == nil then
    error({ "Please give your date of birth.", INVALID_ARGUMENT })
  end
  if age < MIN_AGE then
    error({ "Gold Coast is for players 18 and older.", PERMISSION_DENIED })
  end
  if vars.terms ~= TERMS_VERSION then
    error({ "Please agree to the terms to make an account.", INVALID_ARGUMENT })
  end
  return payload
end
nk.register_req_before(check_new_account, "AuthenticateEmail")

-- After an email login: if it made a new account, keep its name, date of
-- birth, and agreement.
local function keep_new_account(context, session, payload)
  if not session.created then
    return session
  end
  local vars = payload.account.vars
  local users = nk.users_get_username({ payload.username })
  if #users == 1 then
    local metadata = { birthdate = vars.birthdate, terms = vars.terms, agreed_at = os.time() }
    nk.account_update_id(users[1].user_id, metadata, nil, vars.name)
  end
  return session
end
nk.register_req_after(keep_new_account, "AuthenticateEmail")

-- "town": the shared Gold Coast's match ID (see town.lua). It starts the town
-- if it isn't running yet.
local function find_town(context, payload)
  local towns = nk.match_list(1, true, "town", 0, 10000)
  if #towns > 0 then
    return nk.json_encode({ match_id = towns[1].match_id })
  end
  return nk.json_encode({ match_id = nk.match_create("town", {}) })
end
nk.register_rpc(find_town, "town")
