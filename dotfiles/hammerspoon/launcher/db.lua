local sqlite3 = require("hs.sqlite3")
local config  = require("launcher.constants")

local launcherDb = {}
local _db

local VERSION = 1

local SCHEMA = [[
  CREATE TABLE IF NOT EXISTS app_frecency (
    bundle_id TEXT PRIMARY KEY,
    launches  INTEGER NOT NULL DEFAULT 0,
    last_used INTEGER NOT NULL DEFAULT 0
  );
]]

function launcherDb.open()
  local dir = config.dbPath:match("^(.*)/[^/]+$")
  if dir then hs.execute("mkdir -p '" .. dir .. "'") end
  _db = sqlite3.open(config.dbPath)
  _db:exec("PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL;")

  local ver = 0
  for row in _db:rows("PRAGMA user_version") do ver = row[1] end
  if ver < VERSION then
    _db:exec(SCHEMA)
    _db:exec("PRAGMA user_version=" .. VERSION)
  end

  return _db
end

function launcherDb.get()   return _db end
function launcherDb.close() if _db then _db:close() end end

return launcherDb