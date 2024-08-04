--- ハンドラ
--- @param params lsp.DidChangeTextDocumentParams
--- @param client I18n.Client
local function handler(params, client)
  if #params.contentChanges ~= 0 then
    local uri = params.textDocument.uri
    vim.schedule(function()
      require("js-i18n.lsp.checker").check(client, uri)
    end)
  end
end

--- @type I18n.lsp.NotifyProtocolModule
local M = {
  handler = handler,
}

return M
