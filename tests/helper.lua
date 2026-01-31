local M = {}

M.setup = function()
  _G._TEST = true
end

M.teardown = function()
  _G._TEST = nil
end

return M
