-- JavaScript/TypeScript や 文言リソースの解析用のユーティリティ関数を提供するモジュール

local utils = require("js-i18n.utils")

local M = {}

--- ノードの深さを計算する関数
local function calculate_node_depth(node)
	local depth = 0
	while node:parent() do
		node = node:parent()
		depth = depth + 1
	end
	return depth
end

--- Treesitterパーサーをセットアップしてキーにマッチするノードを取得する関数
--- @param bufnr number 反訳リソースのバッファ番号
--- @param keys string[] キー
--- @param start? integer 開始位置
--- @param stop? integer 終了位置
--- @return TSNode | nil, string | nil
function M.get_node_for_key(bufnr, keys, start, stop)
	local key = table.concat(keys, ".")
	vim.print("key: " .. key .. " bufnr: " .. bufnr)
	local ts = vim.treesitter

	local parser = ts.get_parser(bufnr, "json")
	local tree = parser:parse()[1]
	local root = tree:root()

	local query = ts.query.parse("json", '(pair key: (string) @key (#eq? @key "\\"' .. keys[1] .. '\\""))')

	--- @type TSNode[]
	local match_nodes = {}

	for _, match, _ in query:iter_matches(root, bufnr, start, stop) do
		for _, node in ipairs(match) do
			table.insert(match_nodes, node)
		end
	end

	--- @type TSNode
	local node = vim
		.iter(match_nodes)
		-- find min depth
		:fold(match_nodes[1], function(acc, node)
			if calculate_node_depth(node) < calculate_node_depth(acc) then
				return node
			else
				return acc
			end
		end)

	if #keys == 1 then
		return node, nil
	elseif node ~= nil then
		table.remove(keys, 1)
		local parent = node:parent()
		if parent ~= nil then
			return M.get_node_for_key(bufnr, keys, parent:start(), parent:end_())
		end
	end

	return nil, "Key not found: " .. key
end

--- カーソルの位置が t 関数の引数内にあるかどうかを判定する関数
--- @param bufnr number バッファ番号
--- @param position lsp.Position カーソルの位置
--- @return boolean result カーソルが t 関数の引数内にあるかどうか
--- @return TSNode | nil key_node カーソルが t 関数の引数内にある場合は引数のノード
function M.check_cursor_in_t_argument(bufnr, position)
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok then
		return false
	end

	local tree = parser:parse()[1]
	local root = tree:root()
	local language = parser:lang()

	if not vim.tbl_contains({ "javascript", "typescript", "jsx", "tsx" }, language) then
		return false
	end

	local line = position.line
	local character = position.character
	local node = root:named_descendant_for_range(line, character, line, character)
	if node == nil or vim.tbl_contains({ "string", "string_fragment" }, node:type()) == false then
		return false
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
            (string_fragment)? @str_frag
          ) @str
        )
      )
    ]]
	)

	local call_exp_node = utils.find_parent_by_type(node, "call_expression")
	if call_exp_node == nil then
		return false
	end

	local key_node = nil
	for _, match in query:iter_matches(call_exp_node, bufnr) do
		key_node = match[2]
	end

	return true, key_node
end

return M
