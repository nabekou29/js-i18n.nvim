local analyzer = require("js-i18n.analyzer")
local utils = require("js-i18n.utils")

--- @class LanguageForCodeAction
--- @field value string
--- @field current boolean
--- @field missing boolean

--- @param params lsp.CodeActionParams
--- @param client I18n.Client
--- @return LanguageForCodeAction[]
local function get_languages(params, client)
  local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
  local current_language = client:get_language(bufnr)

  local t_source = client.t_source_by_workspace[utils.get_workspace_root(bufnr)]
  if t_source == nil then
    return {}
  end

  -- 翻訳不足している言語
  local missing_languages = {}
  for _, diagnostic in ipairs(params.context.diagnostics or {}) do
    if diagnostic.code == "missing-translation" and diagnostic.data then
      missing_languages = diagnostic.data.missing_languages or {}
    end
  end

  --- @type LanguageForCodeAction[]
  local languages = {}
  for _, lang in ipairs(t_source:get_available_languages()) do
    table.insert(languages, {
      value = lang,
      current = lang == current_language,
      missing = vim.tbl_contains(missing_languages, lang),
    })
  end

  return languages
end

--- ハンドラ
--- @param params lsp.CodeActionParams
--- @param client I18n.Client
--- @return string | nil error
--- @return lsp.Command[] | nil result
local function handler(params, client)
  local commands = {}

  local languages = get_languages(params, client)
  table.sort(languages, function(a, b)
    -- 現在の言語を優先
    if a.current and not b.current then
      return true
    end

    -- 翻訳不足の言語を優先
    if a.missing and not b.missing then
      return true
    end

    return false
  end)

  -- カーソル位置にあるキーの翻訳を編集するアクション
  local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
  local ok, t_call = analyzer.check_cursor_in_t_argument(bufnr, {
    line = params.range.start.line,
    character = params.range.start.character,
  })
  if ok and t_call then
    local key = t_call.key
    for _, lang in ipairs(languages) do
      --- @type lsp.Command
      local command = {
        title = "Edit translation for " .. lang.value,
        command = "i18n.editTranslation",
        arguments = { lang.value, key },
      }
      table.insert(commands, command)
    end
  end

  return nil, commands
end

--- @type I18n.lsp.ProtocolModule
local M = {
  handler = handler,
}
return M
