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
  if not t_source then
    return "Translation source not found", nil
  end

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
  local library = utils.detect_library(workspace_dir)

  for file, _ in pairs(t_source:get_translation_source_by_lang(lang)) do
    local content = Path:new(file):read()

    --- @type lsp.Location[]
    local result = {}

    local keys = vim.split(key, c.config.key_separator, { plain = true })
    local node = analyzer.get_node_for_key(content, keys)
    if node ~= nil then
      local row_start, col_start, row_end, col_end = node:range()
      table.insert(result, {
        uri = vim.uri_from_fname(file),
        range = {
          start = { line = row_start, character = col_start },
          ["end"] = { line = row_end, character = col_end },
        },
      })
    end

    if library == utils.Library.I18Next then
      for _, suffix in ipairs(c.config.libraries.i18next.plural_suffixes) do
        local key_with_suffix = { unpack(keys) }
        key_with_suffix[#key_with_suffix] = key_with_suffix[#key_with_suffix] .. suffix

        local node = analyzer.get_node_for_key(content, key_with_suffix)
        if node ~= nil then
          local row_start, col_start, row_end, col_end = node:range()
          table.insert(result, {
            uri = vim.uri_from_fname(file),
            range = {
              start = { line = row_start, character = col_start },
              ["end"] = { line = row_end, character = col_end },
            },
          })
        end
      end
    end

    if #result > 0 then
      return nil, result
    end
  end

  return nil, nil
end

--- @type I18n.lsp.ProtocolModule
local M = {
  handler = handler,
}
return M
