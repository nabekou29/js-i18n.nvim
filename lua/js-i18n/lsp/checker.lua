local analyzer = require("js-i18n.analyzer")
local c = require("js-i18n.config")
local utils = require("js-i18n.utils")

local M = {}

--- @param client I18n.Client
--- @param uri string
function M.check(client, uri)
  local bufnr = vim.uri_to_bufnr(uri)
  local workspace_dir = utils.get_workspace_root(bufnr)
  local t_source = client.t_source_by_workspace[workspace_dir]
  local library = utils.detect_library(workspace_dir)

  local dispatchers = require("js-i18n.lsp.config").dispatchers
  if not dispatchers then
    return
  end

  if not c.config.diagnostic.enabled then
    dispatchers.notification("textDocument/publishDiagnostics", {
      uri = uri,
      diagnostics = {},
    })
    return
  end

  --- @type lsp.Diagnostic[]
  local diagnostics = {}

  local t_calls = analyzer.find_call_t_expressions_from_buf(bufnr)
  for _, t_call in ipairs(t_calls) do
    local key = t_call.key
    local keys = vim.split(key, c.config.key_separator, { plain = true })

    local namespace = nil

    if c.config.namespace_separator ~= nil then
      local split_first_key = vim.split(keys[1], c.config.namespace_separator, { plain = true })
      namespace = split_first_key[1]
      keys[1] = split_first_key[2]
    end

    local missing_languages = {}
    local available_languages = t_source:get_available_languages()
    for _, lang in ipairs(available_languages) do
      local translation = t_source:get_translation(lang, keys, library, namespace)
      if not translation then
        table.insert(missing_languages, lang)
      end
    end

    if #missing_languages > 0 then
      local row_start, col_start, row_end, col_end = t_call.key_node:range()
      --- @type lsp.Diagnostic
      local diagnostic = {
        range = {
          start = { line = row_start, character = col_start },
          ["end"] = { line = row_end, character = col_end },
        },
        message = "Missing translation for " .. table.concat(missing_languages, ", "),
        severity = c.config.diagnostic.severity,
        source = "js-i18n",
        code = "missing-translation",
        data = {
          key = key,
          missing_languages = missing_languages,
        },
      }
      table.insert(diagnostics, diagnostic)
    end
  end

  dispatchers.notification("textDocument/publishDiagnostics", {
    uri = uri,
    diagnostics = diagnostics,
  })
end

return M
