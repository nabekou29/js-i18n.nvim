local analyzer = require("js-i18n.analyzer")
local c = require("js-i18n.config")
local utils = require("js-i18n.utils")

--- Get all translations with namespace
--- @param translation I18n.TranslationSource
--- @param prefix? string
--- @param result? table<string, string>
--- @param namespace string
--- @return table<string, string>
local function get_all_translation(translation, prefix, result, namespace)
  result = result or {}
  for key, value in pairs(translation) do
    local full_key = prefix and prefix .. c.config.key_separator .. key or key
    if type(value) == "table" then
      get_all_translation(value, full_key, result, namespace)
    else
      -- Only add keys that contain namespaces
      if full_key:find(namespace, 1, true) == 1 then
        result[full_key] = value
      end
    end
  end
  return result
end

--- Get all completion items based on namespace
--- @param client I18n.Client
--- @param bufnr number
--- @param t_call FindTExpressionResultItem
--- @return lsp.CompletionItem[]
local function get_completion_items(client, bufnr, t_call)
  local lang = client:get_language(bufnr)
  local t_source = client.t_source_by_workspace[utils.get_workspace_root(bufnr)]

  local key_prefix = t_call.key_prefix or ""
  local namespace = t_call.namespace or ""

  local translations = {}
  for _, source in pairs(t_source:get_translation_source_by_lang(lang, namespace)) do
    for key, value in pairs(get_all_translation(source, nil, nil, namespace)) do
      if key_prefix == "" then
        translations[key] = value
      else
        if key:find(key_prefix, 1, true) == 1 then
          translations[key:sub(#key_prefix + 2)] = value
        end
      end
    end
  end

  --- @type lsp.CompletionItem[]
  local items = {}
  for key, value in pairs(translations) do
    table.insert(items, {
      label = key,
      detail = value,
      sortText = key,
    })
  end
  return items
end

--- ハンドラ
--- @param params lsp.CompletionParams
--- @param client I18n.Client
--- @return string | nil error
--- @return lsp.CompletionItem[] | lsp.CompletionList | nil
local function handler(params, client)
  local bufnr = vim.uri_to_bufnr(params.textDocument.uri)

  local ok, t_call = analyzer.check_cursor_in_t_argument(bufnr, params.position)
  if not ok or not t_call then
    return nil, nil
  end

  local items = get_completion_items(client, bufnr, t_call)
  return nil, items
end

--- @type I18n.lsp.ProtocolModule
local M = {
  handler = handler,
}
return M
