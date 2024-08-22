local analyzer = require("js-i18n.analyzer")
local c = require("js-i18n.config")
local utils = require("js-i18n.utils")

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

  local ok, t_call = analyzer.check_cursor_in_t_argument(bufnr, params.position)
  if not ok or not t_call then
    return nil, nil
  end
  local key = t_call.key
  local keys = vim.split(key, c.config.key_separator, { plain = true })

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
