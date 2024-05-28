--- ハンドラ
--- @param _params lsp.InitializeParams
--- @param _client I18n.Client
--- @return string | nil error
--- @return lsp.InitializeResult | nil result
local function handler(_params, _client)
	return nil, {
		capabilities = {
			definitionProvider = true,
		},
	}
end

--- @type I18n.lsp.ProtocolModule
local M = {
	handler = handler,
}
return M
