local ns_id = vim.api.nvim_create_namespace("I18n")

local M = {}

--- get_t_calls
--- @param bufnr integer バッファ番号
--- @param start integer 開始行
--- @param stop integer 終了行
--- @return TSNode[][]
local function find_call_t_expressions(bufnr, start, stop)
	local language_tree = vim.treesitter.get_parser(bufnr)
	local syntax_tree = language_tree:parse()
	local root = syntax_tree[1]:root()
	local language = language_tree:lang()

	if not vim.tbl_contains({ "javascript", "typescript", "tsx", "jsx" }, language) then
		return {}
	end

	local query = vim.treesitter.query.parse(
		language_tree:lang(),
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
	for _, match in query:iter_matches(root, bufnr, start, stop) do
		local func = match[1]
		local args = match[2]
		table.insert(t_nodes, { func, args })
	end

	return t_nodes
end

--- バーチャルテキストを表示する
--- @param bufnr integer バッファ番号
--- @param lang string 言語
--- @param t_source TranslationSource 翻訳ソース
function M.set_extmark(bufnr, lang, t_source)
	M.clear_extmarks(bufnr)

	local t_nodes = find_call_t_expressions(bufnr, 0, -1)
	for _, t_node in ipairs(t_nodes) do
		local key_node = t_node[2]

		local key = vim.treesitter.get_node_text(key_node, bufnr)

		local text = t_source:get_translation(lang, vim.split(key, "%."))
		if text == nil or text == "" or type(text) ~= "string" then
			goto continue
		end

		local key_row, key_col = key_node:range()
		vim.api.nvim_buf_set_extmark(bufnr, ns_id, key_row, key_col + #key + 1, {
			virt_text = { { " : " .. text, "Comment" } },
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
