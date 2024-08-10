--- ハンドラ
--- @param _params lsp.ExecuteCommandParams``
--- @param _client I18n.Client
--- @return string | nil error
--- @return any result
local function handler(_params, _client)
  return nil, nil
end

--- @type I18n.lsp.ProtocolModule
local M = {
  handler = handler,
}
return M
