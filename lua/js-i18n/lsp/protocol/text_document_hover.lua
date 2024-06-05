local utils = require("js-i18n.utils")
local lsp_utils = require("js-i18n.lsp.utils")

--- @class Hover
--- @field contents lsp.MarkedString | lsp.MarkedString[] | lsp.MarkupContent
--- @field range? lsp.Range

--- ハンドラ
--- @param params lsp.HoverParams
--- @param client I18n.Client
--- @return string | nil error
--- @return Hover | nil
local function handler(params, client)
  local bufnr = vim.uri_to_bufnr(params.textDocument.uri)

  local workspace_dir = utils.get_workspace_root(bufnr)
  local t_source = client.t_source_by_workspace[workspace_dir]

  local ok, key_node = lsp_utils.check_cursor_in_t_argument(bufnr, params.position)
  if not ok or not key_node then
    return nil, nil
  end
  local key = vim.treesitter.get_node_text(key_node, bufnr)
  local keys = vim.split(key, ".", { plain = true })

  -- 各言語の翻訳を表示
  local contents = {}
  for _, lang in ipairs(t_source:get_available_languages()) do
    local translation = t_source:get_translation(lang, keys)
    if translation then
      if type(translation) == "string" then
        table.insert(contents, lang .. ": " .. translation)
      else
        table.insert(contents, lang .. ": " .. vim.inspect(translation))
      end
    else
      table.insert(contents, lang .. ": -")
    end
  end

  --- @type Hover
  local result = {
    contents = contents,
  }

  return nil, result
end

--- @type I18n.lsp.ProtocolModule
local M = {
  handler = handler,
}
return M
