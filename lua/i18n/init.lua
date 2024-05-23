local translation_source = require("i18n.translation-source")
local extmark = require("i18n.extmark")

local i18n = {}

--- @class i18n.Opts
--- @field default_locale string

--- プロジェクトのルートディレクトリを取得する
--- @param bufnr number
--- @return string プロジェクトのルートディレクトリ
local function get_root(bufnr)
	local root = vim.fs.root(bufnr, "package.json")
	if root == nil then
		return vim.fn.getcwd()
	else
		return root
	end
end

--- attach
--- @param client vim.lsp.Client
--- @param bufnr number
function i18n.attach(client, bufnr)
	--
end

vim.g.i18n_lang = "ja"

--- setup
--- @param _opts i18n.Opts
i18n.setup = function(_opts)
	local t_source_by_workspace = {}

	local group = vim.api.nvim_create_augroup("i18n_tools", {})
	vim.api.nvim_create_autocmd({
		"BufEnter",
		"TextChanged",
		"TextChangedI",
		"TextChangedP",
	}, {
		pattern = "*.{ts,js,tsx,jsx}",
		group = group,
		callback = function()
			local bufnr = vim.api.nvim_get_current_buf()
			local workspace_dir = get_root(bufnr)
			if t_source_by_workspace[workspace_dir] == nil then
				t_source_by_workspace[workspace_dir] = translation_source.TranslationSource.new(workspace_dir)
				t_source_by_workspace[workspace_dir]:start_watch()
			end

			extmark.set_extmark(vim.g.i18n_lang, t_source_by_workspace[workspace_dir])
		end,
	})

	vim.api.nvim_create_user_command("I18nSetLang", function(opts)
		local lang = opts.args
		vim.g.i18n_lang = lang
		i18n.set_extmark(lang)
	end, {
		nargs = 1,
		-- TODO: 補完出るようにしたい
	})
end

return i18n
