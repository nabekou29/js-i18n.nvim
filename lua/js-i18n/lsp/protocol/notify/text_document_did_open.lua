--- ハンドラ
--- @param params lsp.DidOpenTextDocumentParams
--- @param client I18n.Client
local function handler(params, client)
  local uri = params.textDocument.uri
  vim.schedule(function()
    require("js-i18n.lsp.checker").check(client, uri)
  end)
end

--- @type I18n.lsp.NotifyProtocolModule
local M = {
  handler = handler,
}

return M
