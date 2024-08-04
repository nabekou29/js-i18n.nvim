local c = require("js-i18n.config")
local utils = require("js-i18n.utils")
local lsp_utils = require("js-i18n.lsp.utils")

local M = {}

--- @param client I18n.Client
--- @param uri string
function M.check(client, uri)
  local bufnr = vim.uri_to_bufnr(uri)
  local workspace_dir = utils.get_workspace_root(bufnr)
  local t_source = client.t_source_by_workspace[workspace_dir]

  if not c.config.diagnostic.enabled then
    require("js-i18n.lsp.config").dispatchers.notification("textDocument/publishDiagnostics", {
      uri = uri,
      diagnostics = {},
    })
    return
  end

  --- @type lsp.Diagnostic[]
  local diagnostics = {}

  local nodes = lsp_utils.find_translation_key_node_list(bufnr)
  for _, key_node in ipairs(nodes) do
    local key = vim.treesitter.get_node_text(key_node, bufnr)
    local keys = vim.split(key, c.config.key_separator, { plain = true })

    local missing_languages = {}
    local available_languages = t_source:get_available_languages()
    for _, lang in ipairs(available_languages) do
      local translation = t_source:get_translation(lang, keys)
      if not translation then
        table.insert(missing_languages, lang)
      end
    end

    if #missing_languages > 0 then
      local row_start, col_start, row_end, col_end = key_node:range()
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
      }
      table.insert(diagnostics, diagnostic)
    end
  end

  require("js-i18n.lsp.config").dispatchers.notification("textDocument/publishDiagnostics", {
    uri = uri,
    diagnostics = diagnostics,
  })
end

return M
