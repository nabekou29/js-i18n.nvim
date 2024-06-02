local c = require("js-i18n.config")
local Client = require("js-i18n.client")

local i18n = {}

--- コマンド用の言語の補完関数を取得する
--- @param translation_sources I18n.TranslationSource[]
--- @return fun(string, string, number): string[]
local function get_completion_available_languages(translation_sources)
	return function(arg_lead, _cmd_line, _cursor_pos)
		local matches = {}

		local available_languages = {}
		for _, source in ipairs(translation_sources) do
			for _, lang in ipairs(source:get_available_languages()) do
				available_languages[lang] = true
			end
		end

		for lang, _ in pairs(available_languages) do
			if lang:match(arg_lead) then
				table.insert(matches, lang)
			end
		end
		return matches
	end
end

--- setup
--- @param opts I18n.Config
i18n.setup = function(opts)
	local group = vim.api.nvim_create_augroup("js-i18n", {})
	-- 設定の初期化
	c.setup(opts)

	local client = Client.new()

	-- ファイルの変更などがあれば、バーチャルテキストを更新する
	vim.api.nvim_create_autocmd({
		"BufEnter",
		"TextChanged",
		"TextChangedI",
		"TextChangedP",
	}, {
		pattern = "*.{ts,js,tsx,jsx}",
		group = group,
		callback = function(ev)
			local bufnr = ev.buf
			client:update_js_file_handler(bufnr)
		end,
	})

	vim.api.nvim_create_user_command("I18nSetLang", function(opts)
		local lang = opts.args
		client:change_language(lang)
	end, {
		nargs = 1,
		complete = function(arg_lead, cmd_line, cursor_pos)
			return get_completion_available_languages(vim.tbl_values(client.t_source_by_workspace))(
				arg_lead,
				cmd_line,
				cursor_pos
			)
		end,
	})

	local lspconfig = require("lspconfig")
	local lsp_configs = require("lspconfig.configs")

	if not lsp_configs.i18n_lsp then
		lsp_configs.i18n_lsp = {
			default_config = {
				--- @param _dispatchers vim.lsp.rpc.Dispatchers
				--- @return vim.lsp.rpc.PublicClient
				cmd = function(_dispatchers)
					return require("js-i18n.lsp").create_rpc(client)
				end,
				filetypes = {
					"javascript",
					"typescript",
					"javascriptreact",
					"typescriptreact",
					"javascript.jsx",
					"typescript.tsx",
				},
				single_file_support = true,
			},
		}
	end
	lspconfig.i18n_lsp.setup({})
end

return i18n
