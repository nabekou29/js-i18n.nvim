local M = {}

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
--- @param type_ string
--- @return TSNode|nil
function M.find_closest_node(node, type_)
  local parent = node:parent()
  while parent ~= nil do
    if parent:type() == type_ then
      return parent
    end
    parent = parent:parent()
  end
  return nil
end

--- @class GetTDetail
--- @field namespace string
--- @field key_prefix string
--- @field scope_node TSNode

--- t関数の取得に関する情報を解析する
--- @param target_node TSNode t関数取得のノード
--- @param bufnr integer バッファ番号
--- @param query vim.treesitter.Query クエリ
--- @return GetTDetail
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

  local scope_node = M.find_closest_node(target_node, "statement_block")

  return {
    namespace = namespace,
    key_prefix = key_prefix,
    scope_node = scope_node,
  }
end

--- @class CallTDetail
--- @field key string
--- @field namespace? string
--- @field key_prefix? string

--- t関数の呼び出しに関する情報を解析する
--- @param target_node TSNode t関数呼び出しのノード
--- @param bufnr integer バッファ番号
--- @param query vim.treesitter.Query クエリ
--- @return CallTDetail
local function parse_call_t(target_node, bufnr, query)
  local key = nil
  local namespace = nil
  local key_prefix = nil

  for id, node, _ in query:iter_captures(target_node, bufnr, 0, -1) do
    local name = query.captures[id]

    if name == "i18n.key" then
      key = vim.treesitter.get_node_text(node, bufnr)
    elseif name == "i18n.namespace" then
      namespace = vim.treesitter.get_node_text(node, bufnr)
    elseif name == "i18n.key_prefix" then
      key_prefix = vim.treesitter.get_node_text(node, bufnr)
    end
  end

  return {
    key = key,
    namespace = namespace,
    key_prefix = key_prefix,
  }
end

--- @class FindTExpressionResultItem
--- @field node TSNode
--- @field key string
--- @field namespace? string
--- @field key_prefix? string

--- t関数を含むノードを検索する
--- @param bufnr integer バッファ番号
--- @param query_file string クエリファイル
--- @param start? integer 開始行
--- @param stop? integer 終了行
--- @return FindTExpressionResultItem[]
function M.find_call_t_expressions(bufnr, query_file, start, stop)
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

  local query_str = M.load_query_from_file(query_file)

  if type(query_str) ~= "string" then
    return {}
  end

  local query = vim.treesitter.query.parse(language, query_str)

  --- @type GetTDetail[]
  local scope_stack = {}

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

  for id, node, _ in query:iter_captures(root_node, bufnr, start, stop) do
    local name = query.captures[id]

    if name == "i18n.get_t" then
      local get_t_detail = parse_get_t(node, bufnr, query)
      enter_scope(get_t_detail)
    else
      -- 現在のスコープから抜けたかどうかを判定する
      local current_scope_node = current_scope().scope_node
      if node:start() > current_scope_node:end_() or node:end_() < current_scope_node:start() then
        leave_scope()
      end

      if name == "i18n.call_t" then
        local scope = current_scope()
        local call_t_detail = parse_call_t(node, bufnr, query)

        table.insert(result, {
          node = node,
          key = call_t_detail.key,
          namespace = call_t_detail.namespace or scope.namespace,
          key_prefix = call_t_detail.key_prefix or scope.key_prefix,
        })
      end
    end
  end

  return result
end

return M
