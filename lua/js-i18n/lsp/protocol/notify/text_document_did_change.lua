local lsp_config = require("js-i18n.lsp.config")
local reference_table = require("js-i18n.reference_table")
local translation_source = require("js-i18n.translation_source")

--- ハンドラ
--- @param params lsp.DidChangeTextDocumentParams
--- @param client I18n.Client
local function handler(params, client)
  if #params.contentChanges ~= 0 then
    local uri = params.textDocument.uri

    local bufnr = vim.uri_to_bufnr(uri)
    local workspace_dir = require("js-i18n.utils").get_workspace_root(bufnr)

    -- 文言ファイル以外の JSON ファイルは無視する
    local file_name = vim.uri_to_fname(uri)
    if file_name:match("%.json$") and not translation_source.is_translation_file(file_name) then
      return
    end

    local ref_table = lsp_config.ref_table_by_workspace[workspace_dir]
    if lsp_config.ref_table_by_workspace[workspace_dir] == nil then
      local ref_table = reference_table.ReferenceTable.new({
        workspace_dir = workspace_dir,
      })
      lsp_config.ref_table_by_workspace[workspace_dir] = ref_table
      ref_table:load_all()
    else
      ref_table:load_path(vim.uri_to_fname(uri), params.contentChanges[1].text)
    end

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
