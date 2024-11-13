local lsp_config = require("js-i18n.lsp.config")

--- ハンドラ
--- @param params lsp.InitializeParams
--- @param _client I18n.Client
--- @return string | nil error
--- @return lsp.InitializeResult | nil result
local function handler(params, _client)
  if params.capabilities.textDocument.publishDiagnostics then
    lsp_config.publishDiagnosticsCapable = true
  end

  --- @type lsp.InitializeResult
  local server_capabilities = {
    capabilities = {
      textDocumentSync = 1,
      definitionProvider = true,
      referencesProvider = true,
      hoverProvider = true,
      completionProvider = {},
      codeActionProvider = {},
      executeCommandProvider = {
        commands = {
          "i18n.editTranslation",
        },
      },
    },
  }
  return nil, server_capabilities
end

--- @type I18n.lsp.ProtocolModule
local M = {
  handler = handler,
}
return M
