local c = require("js-i18n.config")
local utils = require("js-i18n.utils")

local ns_id = vim.api.nvim_create_namespace("I18n")

local M = {}

--- 翻訳を取得する
--- @param lang string 言語
--- @param key string キー
--- @param t_source I18n.TranslationSource 翻訳ソース
--- @return string | nil 翻訳, string | nil 言語
local function get_translation(lang, key, t_source)
	local langs = { lang }
	if c.config.virt_text.fallback then
		langs = vim
			.iter({ { lang }, c.config.primary_language, t_source:get_available_languages() })
			:flatten()
			-- unique
			:fold({}, function(acc, v)
				if not vim.tbl_contains(acc, v) then
					table.insert(acc, v)
				end
				return acc
			end)
	end

	for _, l in ipairs(langs) do
		local text = t_source:get_translation(l, vim.split(key, "%."))
		if text ~= nil and type(text) == "string" then
			return text, l
		end
	end

	return nil, nil
end

--- バーチャルテキストのフォーマット関数
--- @param text string
--- @param opts default_virt_text_format_opts
--- @return string|string[][]
---
--- @class default_virt_text_format_opts
--- @field key string キー
--- @field lang string 言語
--- @field current_language string 選択中の言語
---
local function default_virt_text_format(text, opts)
	local prefix = ""
	local suffix = ""
	if not c.config.virt_text.conceal_key then
		prefix = " : "
	end

	if c.config.virt_text.max_length > 0 then
		text = utils.utf_truncate(text, c.config.virt_text.max_length, "...")
	end

	-- fallback
	if opts.current_language ~= opts.lang then
		return { { prefix .. text .. suffix, "WarningMsg" } }
	end

	return prefix .. text .. suffix
end

--- t関数を含むノードを検索する
--- @param bufnr integer バッファ番号
--- @param start? integer 開始行
--- @param stop? integer 終了行
--- @return TSNode[][]
local function find_call_t_expressions(bufnr, start, stop)
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok then
		return {}
	end
	local tree = parser:parse()[1]
	local root_node = tree:root()
	local language = parser:lang()

	if not vim.tbl_contains({ "javascript", "typescript", "jsx", "tsx" }, language) then
		return {}
	end

	local query = vim.treesitter.query.parse(
		language,
		[[
      (call_expression
        function: [
          (identifier)
          (member_expression)
        ] @t_func (#match? @t_func "^(i18next\.)?t$")
        arguments: (arguments
          (string
            (string_fragment) @str_frag
          )
        )
      )
    ]]
	)

	local t_nodes = {}
	for _, match in query:iter_matches(root_node, bufnr, start, stop) do
		local func = match[1]
		local args = match[2]
		table.insert(t_nodes, { func, args })
	end

	return t_nodes
end

--- バーチャルテキストを表示する
--- @param bufnr integer バッファ番号
--- @param current_language string 言語
--- @param t_source I18n.TranslationSource 翻訳ソース
function M.set_extmark(bufnr, current_language, t_source)
	if not c.config.virt_text.enabled then
		return
	end

	M.clear_extmarks(bufnr)

	local t_nodes = find_call_t_expressions(bufnr)
	for _, t_node in ipairs(t_nodes) do
		local key_node = t_node[2]

		local key = vim.treesitter.get_node_text(key_node, bufnr)

		local text, lang = get_translation(current_language, key, t_source)
		if text == nil or lang == nil then
			goto continue
		end

		local key_row_start, key_col_start, key_row_end, key_col_end = key_node:range()
		local virt_text = default_virt_text_format(text, {
			key = key,
			lang = lang,
			current_language = current_language,
		})
		if type(virt_text) == "string" then
			virt_text = { { virt_text, "Comment" } }
		end

		if c.config.virt_text.conceal_key then
			local conceallevel = vim.opt_local.conceallevel:get()
			if conceallevel < 1 or conceallevel > 2 then
				vim.notify_once("To use virt_text.conceal_key, conceallevel must be 1 or 2.", vim.log.levels.WARN)
			end
			vim.api.nvim_buf_set_extmark(bufnr, ns_id, key_row_start, key_col_start - 1, {
				end_row = key_row_end,
				end_col = key_col_end + 1,
				conceal = "",
			})
		end

		vim.api.nvim_buf_set_extmark(bufnr, ns_id, key_row_start, key_col_start + #key + 1, {
			virt_text = virt_text,
			virt_text_pos = "inline",
		})

		::continue::
	end
end

--- バーチャルテキストを削除する
--- @param bufnr integer バッファ番号
function M.clear_extmarks(bufnr)
	local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, ns_id, 0, -1, {})
	for _, extmark in ipairs(extmarks) do
		local id = extmark[1]
		vim.api.nvim_buf_del_extmark(bufnr, ns_id, id)
	end
end

return M
