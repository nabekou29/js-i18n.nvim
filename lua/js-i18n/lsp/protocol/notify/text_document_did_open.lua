local lsp_config = require("js-i18n.lsp.config")
local reference_table = require("js-i18n.reference_table")
local utils = require("js-i18n.utils")

--- ハンドラ
--- @param params lsp.DidOpenTextDocumentParams
--- @param client I18n.Client
local function handler(params, client)
  local uri = params.textDocument.uri

  local bufnr = vim.uri_to_bufnr(uri)
  local workspace_dir = require("js-i18n.utils").get_workspace_root(bufnr)
  if lsp_config.ref_table_by_workspace[workspace_dir] == nil then
    local ref_table = reference_table.ReferenceTable.new({
      workspace_dir = workspace_dir,
    })
    lsp_config.ref_table_by_workspace[workspace_dir] = ref_table
    ref_table:load_all()
  end

  vim.schedule(function()
    require("js-i18n.lsp.checker").check(client, uri)
  end)
end

--- @type I18n.lsp.NotifyProtocolModule
local M = {
  handler = handler,
}

return M
