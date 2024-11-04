local Path = require("plenary.path")

local analyzer = require("js-i18n.analyzer")
local c = require("js-i18n.config")
local utils = require("js-i18n.utils")

--- ハンドラ
--- @param params lsp.DefinitionParams
--- @param client I18n.Client
--- @return string | nil error
--- @return lsp.Location | lsp.Location[] | nil result
local function handler(params, client)
  local bufnr = vim.uri_to_bufnr(params.textDocument.uri)

  local workspace_dir = utils.get_workspace_root(bufnr)
  local t_source = client.t_source_by_workspace[workspace_dir]
  local lang = utils.get_language(
    client.current_language,
    c.config.primary_language,
    t_source:get_available_languages()
  )

  local ok, t_call = analyzer.check_cursor_in_t_argument(bufnr, params.position)
  if not ok or not t_call then
    return nil, nil
  end

  local key = t_call.key
  local namespace = t_call.namespace

  for file, _ in pairs(t_source:get_translation_source_by_lang(lang, namespace)) do
    local bufnr = vim.api.nvim_create_buf(false, true)
    local content = Path:new(file):read()
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(content, "\n"))

    local keys = vim.split(key, c.config.key_separator, { plain = true })
    local node = analyzer.get_node_for_key(bufnr, keys)
    vim.api.nvim_buf_delete(bufnr, { force = true })

    if node ~= nil then
      local row_start, col_start, row_end, col_end = node:range()
      return nil,
        {
          uri = vim.uri_from_fname(file),
          range = {
            start = { line = row_start, character = col_start },
            ["end"] = { line = row_end, character = col_end },
          },
        }
    end
  end

  return nil, nil
end

--- @type I18n.lsp.ProtocolModule
local M = {
  handler = handler,
}
return M
