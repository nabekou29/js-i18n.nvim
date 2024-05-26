local translation_source = require("i18n.translation-source")
local virt_text = require("i18n.virt_text")
local c = require("i18n.config")
local utils = require("i18n.utils")

--- 選択中の言語
--- バーチャルテキストの表示や定義ジャンプの際に使用する
--- @type string|nil
local current_language = nil

local i18n = {}

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

--- ワークスペース内の TypeScript/JavaScript ファイルのバッファ番号を取得する
local function get_workspace_bufs(workspace_dir)
	local bufs = {}
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		local filename = vim.api.nvim_buf_get_name(bufnr)
		local ptn = vim.fn.glob2regpat("*.{ts,js,tsx,jsx}")
		if filename:sub(1, #workspace_dir) == workspace_dir and vim.fn.match(filename, ptn) > 0 then
			table.insert(bufs, bufnr)
		end
	end
	return bufs
end

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
--- @param opts i18n.Config
i18n.setup = function(opts)
	-- 設定の初期化
	c.setup(opts)

	-- ワークスペースごとに翻訳ソースを管理する（モノレポ対応）
	local t_source_by_workspace = {}

	local group = vim.api.nvim_create_augroup("i18n_tools", {})

	-- JavaScript/TypeScript ファイルの更新時の処理
	local handle_update_js_file = function(bufnr)
		local workspace_dir = get_root(bufnr)

		if t_source_by_workspace[workspace_dir] == nil then
			t_source_by_workspace[workspace_dir] = translation_source.TranslationSource.new({
				workspace_dir = workspace_dir,
				-- 翻訳リソース更新時の処理
				on_update = function()
					for _, bufnr in ipairs(get_workspace_bufs(workspace_dir)) do
						local ws_t_source = t_source_by_workspace[workspace_dir]
						virt_text.set_extmark(
							bufnr,
							utils.get_language(
								current_language,
								c.config.primary_language,
								ws_t_source:get_available_languages()
							),
							ws_t_source
						)
					end
				end,
			})
			t_source_by_workspace[workspace_dir]:start_watch()
		else
			local ws_t_source = t_source_by_workspace[workspace_dir]
			virt_text.set_extmark(
				bufnr,
				utils.get_language(current_language, c.config.primary_language, ws_t_source:get_available_languages()),
				t_source_by_workspace[workspace_dir]
			)
		end
	end

	local apply_translation_all_bufs = function()
		for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
			local filename = vim.api.nvim_buf_get_name(bufnr)
			local ptn = vim.fn.glob2regpat("*.{ts,js,tsx,jsx}")
			if vim.fn.match(filename, ptn) > 0 then
				handle_update_js_file(bufnr)
			end
		end
	end

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
			handle_update_js_file(bufnr)
		end,
	})

	-- 読み込み済みのすべてのバッファに対して処理を行う
	apply_translation_all_bufs()

	vim.api.nvim_create_user_command("I18nSetLang", function(opts)
		local lang = opts.args
		current_language = lang
		apply_translation_all_bufs()
	end, {
		nargs = 1,
		complete = function(arg_lead, cmd_line, cursor_pos)
			return get_completion_available_languages(vim.tbl_values(t_source_by_workspace))(
				arg_lead,
				cmd_line,
				cursor_pos
			)
		end,
	})
end

return i18n
