local analyzer = require("js-i18n.analyzer")
local c = require("js-i18n.config")
local lsp_config = require("js-i18n.lsp.config")
local utils = require("js-i18n.utils")

--- ハンドラ
--- @param params lsp.ReferenceParams
--- @param _client I18n.Client
--- @return string | nil error
--- @return lsp.Location[] | nil result
local function handler(params, _client)
  local bufnr = vim.uri_to_bufnr(params.textDocument.uri)

  local workspace_dir = utils.get_workspace_root(bufnr)
  local keys = analyzer.get_key_at_cursor(bufnr, params.position)

  if not keys or #keys == 0 then
    return nil, {}
  end

  local key = table.concat(keys, c.config.key_separator)
  local refs = lsp_config.ref_table_by_workspace[workspace_dir]:find_by_key(key)

  local result = {}
  for _, ref in ipairs(refs) do
    table.insert(result, {
      uri = ref.uri,
      range = ref.range,
    })
  end

  return nil, result
end

--- @type I18n.lsp.ProtocolModule
local M = {
  handler = handler,
}
return M
