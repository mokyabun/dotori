local frecency = {}

local _db

local TIME_WEIGHTS = {
  { 4  * 86400, 2.0 },
  { 14 * 86400, 1.5 },
  { 31 * 86400, 1.0 },
  { 90 * 86400, 0.5 },
}

local function timeWeight(lastUsed)
  local age = os.time() - (lastUsed or 0)
  for _, tw in ipairs(TIME_WEIGHTS) do
    if age <= tw[1] then return tw[2] end
  end
  return 0.25
end

function frecency.init(db)
  _db = db
end

function frecency.record(bundleId)
  local now  = os.time()
  local stmt = _db:prepare(
    "INSERT INTO app_frecency(bundle_id, launches, last_used) VALUES(?,1,?)"
    .. " ON CONFLICT(bundle_id) DO UPDATE SET launches=launches+1, last_used=?"
  )
  stmt:bind_values(bundleId, now, now)
  stmt:step()
  stmt:finalize()
end

function frecency.sort(appList)
  local ids = {}
  for _, a in ipairs(appList) do
    ids[#ids + 1] = "'" .. a.bundleId .. "'"
  end

  local scores = {}
  if #ids > 0 then
    for row in _db:nrows(
      "SELECT bundle_id, launches, last_used FROM app_frecency"
      .. " WHERE bundle_id IN (" .. table.concat(ids, ",") .. ")"
    ) do
      scores[row.bundle_id] = row.launches * timeWeight(row.last_used)
    end
  end

  table.sort(appList, function(a, b)
    local sa = scores[a.bundleId] or 0
    local sb = scores[b.bundleId] or 0
    if sa ~= sb then return sa > sb end
    return a.name < b.name
  end)
end

return frecency