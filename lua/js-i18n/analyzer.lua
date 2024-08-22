local c = require("js-i18n.config")
local utils = require("js-i18n.utils")

local M = {}

local query_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h") .. "/queries"

local library_query = {
  [utils.Library.I18Next] = {
    typescript = { query_dir .. "/i18next.scm" },
    ["*"] = { query_dir .. "/i18next.scm", query_dir .. "/react-i18next.scm" },
  },
  [utils.Library.NextIntl] = {
    ["*"] = { query_dir .. "/next-intl.scm" },
  },
}

--- ファイルからクエリを読み込む
--- @param file string ファイルパス
--- @return string|nil クエリ
function M.load_query_from_file(file)
  local cache = {}

  local function load_query_from_file(file)
    if cache[file] ~= nil then
      return cache[file]
    end

    local f = io.open(file, "r")
    if f == nil then
      return nil
    end

    local query = f:read("*a")
    f:close()

    cache[file] = query
    return query
  end

  M.load_query_from_file = load_query_from_file
  return load_query_from_file(file)
end

--- ノードから最も近い親ノードを取得する
--- @param node TSNode
--- @param types string[]
--- @return TSNode|nil
function M.find_closest_node(node, types)
  local parent = node:parent()
  while parent ~= nil do
    if vim.tbl_contains(types, parent:type()) then
      return parent
    end
    parent = parent:parent()
  end
  return nil
end

--- ノードの深さを計算する関数
--- @param node TSNode
local function calculate_node_depth(node)
  local depth = 0
  local parent = node:parent()
  while parent ~= nil do
    depth = depth + 1
    parent = parent:parent()
  end

  return depth
end

--- Treesitterパーサーをセットアップしてキーにマッチするノードを取得する関数
--- @param bufnr number 文言ファイルのバッファ番号
--- @param keys string[] キー
--- @param start? integer 開始位置
--- @param stop? integer 終了位置
--- @return TSNode | nil, string | nil
function M.get_node_for_key(bufnr, keys, start, stop)
  local key = table.concat(keys, c.config.key_separator)
  local ts = vim.treesitter

  local parser = ts.get_parser(bufnr, "json")
  local tree = parser:parse()[1]
  local root = tree:root()

  local query =
    ts.query.parse("json", '(pair key: (string) @key (#eq? @key "\\"' .. keys[1] .. '\\""))')

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

--- @class GetTDetail
--- @field namespace string
--- @field key_prefix string
--- @field scope_node TSNode|nil

--- t関数の取得に関する情報を解析する
--- @param target_node TSNode t関数取得のノード
--- @param bufnr integer バッファ番号
--- @param query vim.treesitter.Query クエリ
--- @return GetTDetail|nil
local function parse_get_t(target_node, bufnr, query)
  local namespace = ""
  local key_prefix = ""

  for id, node, _ in query:iter_captures(target_node, bufnr, 0, -1) do
    local name = query.captures[id]

    if name == "i18n.namespace" then
      namespace = vim.treesitter.get_node_text(node, bufnr)
    elseif name == "i18n.key_prefix" then
      key_prefix = vim.treesitter.get_node_text(node, bufnr)
    end
  end

  local scope_node = M.find_closest_node(target_node, { "statement_block", "jsx_element" })

  return {
    namespace = namespace,
    key_prefix = key_prefix,
    scope_node = scope_node,
  }
end

--- @class CallTDetail
--- @field key string
--- @field key_node TSNode
--- @field key_arg_node TSNode
--- @field namespace? string
--- @field key_prefix? string

--- t関数の呼び出しに関する情報を解析する
--- @param target_node TSNode t関数呼び出しのノード
--- @param bufnr integer バッファ番号
--- @param query vim.treesitter.Query クエリ
--- @return CallTDetail|nil
local function parse_call_t(target_node, bufnr, query)
  local key = nil
  local key_node = nil
  local key_arg_node = nil
  local namespace = nil
  local key_prefix = nil

  for id, node, _ in query:iter_captures(target_node, bufnr, 0, -1) do
    local name = query.captures[id]

    if name == "i18n.key" then
      key = vim.treesitter.get_node_text(node, bufnr)
      key_node = node
    elseif name == "i18n.key_arg" then
      key_arg_node = node
    elseif name == "i18n.namespace" then
      namespace = vim.treesitter.get_node_text(node, bufnr)
    elseif name == "i18n.key_prefix" then
      key_prefix = vim.treesitter.get_node_text(node, bufnr)
    end
  end

  if key == nil or key_node == nil then
    return nil
  end

  return {
    key = key,
    key_node = key_node,
    key_arg_node = key_arg_node,
    namespace = namespace,
    key_prefix = key_prefix,
  }
end

--- @class FindTExpressionResultItem
--- @field node TSNode t関数のノード
--- @field key_node TSNode t関数のキーのノード
--- @field key_arg_node TSNode t関数の引数のノード
--- @field key string キー
--- @field key_prefix? string キーのプレフィックス
--- @field key_arg string t 関数の元のキー
--- @field namespace? string t 関数の namespace

--- t関数を含むノードを検索する
--- @param bufnr integer バッファ番号
--- @return FindTExpressionResultItem[]
function M.find_call_t_expressions(bufnr)
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

  local library = utils.detect_library(bufnr) or utils.Library.I18Next
  local query_str = ""
  for _, query_file in ipairs(library_query[library][language] or library_query[library]["*"]) do
    local str = M.load_query_from_file(query_file)
    if str and type(str) == "string" and str ~= "" then
      query_str = query_str .. "\n" .. str
    end
  end

  if query_str == "" then
    return {}
  end

  local query = vim.treesitter.query.parse(language, query_str)

  --- @type GetTDetail[]
  local scope_stack = {}

  --- @param value GetTDetail
  local function enter_scope(value)
    table.insert(scope_stack, value)
  end

  local function leave_scope()
    table.remove(scope_stack)
  end

  local function current_scope()
    return scope_stack[#scope_stack]
      or {
        namespace = "",
        key_prefix = "",
        scope_node = root_node,
      }
  end

  --- @type FindTExpressionResultItem[]
  local result = {}

  for id, node, _ in query:iter_captures(root_node, bufnr) do
    local name = query.captures[id]

    -- 現在のスコープから抜けたかどうかを判定する
    local current_scope_node = current_scope().scope_node or root_node
    if node:start() > current_scope_node:end_() or node:end_() < current_scope_node:start() then
      leave_scope()
    end

    if name == "i18n.get_t" then
      local get_t_detail = parse_get_t(node, bufnr, query)
      if get_t_detail then
        -- 同一のスコープ内で get_t が呼ばれた場合はスコープを上書きする形になるように、一度 leave_scope してから enter_scope する
        if get_t_detail.scope_node == current_scope().scope_node then
          leave_scope()
        end
        enter_scope(get_t_detail)
      end
    elseif name == "i18n.call_t" then
      local scope = current_scope()
      local call_t_detail = parse_call_t(node, bufnr, query)

      if call_t_detail == nil then
        goto continue
      end

      local key_prefix = call_t_detail.key_prefix or scope.key_prefix
      local key = call_t_detail.key
      if key_prefix ~= "" then
        key = key_prefix .. c.config.key_separator .. key
      end

      table.insert(result, {
        node = node,
        key_node = call_t_detail.key_node,
        key_arg_node = call_t_detail.key_arg_node,
        key = key,
        key_prefix = key_prefix,
        key_arg = call_t_detail.key,
        namespace = call_t_detail.namespace or scope.namespace,
      })
    end
    ::continue::
  end

  return result
end

--- カーソルの位置が t 関数の引数内にあるかどうかを判定する関数
--- @param bufnr number バッファ番号
--- @param position lsp.Position カーソルの位置
--- @return boolean ok カーソルが t 関数の引数内にあるかどうか
--- @return FindTExpressionResultItem | nil result カーソルが t 関数の引数内にある場合は t 関数の情報
function M.check_cursor_in_t_argument(bufnr, position)
  local t_calls = M.find_call_t_expressions(bufnr)

  for _, t_call in ipairs(t_calls) do
    local key_arg_node = t_call.key_arg_node
    if vim.treesitter.is_in_node_range(key_arg_node, position.line, position.character) then
      return true, t_call
    end
  end

  return false, nil
end

return M
