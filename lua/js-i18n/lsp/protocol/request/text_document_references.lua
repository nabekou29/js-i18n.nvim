local analyzer = require("js-i18n.analyzer")
local c = require("js-i18n.config")
local reference_table = require("js-i18n.reference_table")
local utils = require("js-i18n.utils")

--- ハンドラ
--- @param params lsp.ReferenceParams
--- @param client I18n.Client
--- @return string | nil error
--- @return lsp.Location[] | nil result
local function handler(params, client)
  local bufnr = vim.uri_to_bufnr(params.textDocument.uri)

  local workspace_dir = utils.get_workspace_root(bufnr)
  local keys = analyzer.get_key_at_cursor(bufnr, params.position)

  if not keys or #keys == 0 then
    return nil, {}
  end

  local key = table.concat(keys, c.config.key_separator)

  local ref_table = reference_table.ReferenceTable.new({ workspace_dir = workspace_dir })
  ref_table:load_all()
  ref_table:wait_processed()
  local refs = ref_table:find_by_key(key)

  local result = {}
  for _, ref in ipairs(refs) do
    local path = ref.path
    local t_call = ref.t_call
    local row_start, col_start, row_end, col_end = t_call.node:range()
    table.insert(result, {
      uri = vim.uri_from_fname(path),
      range = {
        start = { line = row_start, character = col_start },
        ["end"] = { line = row_end, character = col_end },
      },
    })
  end

  return nil, result
end

--- @type I18n.lsp.ProtocolModule
local M = {
  handler = handler,
}
return M
