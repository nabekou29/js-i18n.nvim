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

  local library = utils.detect_library(workspace_dir)

  local namespace = nil

  if c.config.namespace_separator ~= nil then
    local split_first_key = vim.split(keys[1], c.config.namespace_separator, { plain = true })
    namespace = split_first_key[1]
    keys[1] = split_first_key[2]
  end

  -- 各言語の翻訳を表示
  --- @type string[]
  local contents = {}
  for _, lang in ipairs(t_source:get_available_languages()) do
    local translation = t_source:get_translation(lang, keys, library, namespace)
    if translation then
      if type(translation) == "string" then
        table.insert(contents, lang .. ": `" .. translation .. "`")
      else
        local json = vim.fn.system("echo '" .. vim.fn.json_encode(translation) .. "'" .. " | jq .")
        table.insert(contents, lang .. ": \n```json\n" .. json .. "```")
      end
    else
      table.insert(contents, lang .. ": `N/A`")
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
