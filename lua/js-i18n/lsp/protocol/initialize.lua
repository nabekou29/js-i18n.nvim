--- ハンドラ
--- @param _params lsp.InitializeParams
--- @param _client I18n.Client
--- @return string | nil error
--- @return lsp.InitializeResult | nil result
local function handler(_params, _client)
	--- @type lsp.InitializeResult
	local server_capabilities = {
		capabilities = {
			definitionProvider = true,
			hoverProvider = true,
			completionProvider = {},
		},
	}
	return nil, server_capabilities
end

--- @type I18n.lsp.ProtocolModule
local M = {
	handler = handler,
}
return M
