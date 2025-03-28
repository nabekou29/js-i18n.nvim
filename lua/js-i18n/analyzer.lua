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
  local query_cache = {}

  local function load_query_from_file(file)
    if query_cache[file] ~= nil then
      return query_cache[file]
    end

    local f = io.open(file, "r")
    if f == nil then
      return nil
    end

    local query = f:read("*a")
    f:close()

    query_cache[file] = query
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
--- @param source integer|string バッファ番号 or ソース
--- @param keys string[] キー
--- @return TSNode | nil, string | nil
function M.get_node_for_key(source, keys)
  local ts = vim.treesitter

  local parser = (function()
    if type(source) == "string" then
      return ts.get_string_parser(source, "json")
    else
      return ts.get_parser(source)
    end
  end)()
  local tree = parser:parse()[1]
  local root = tree:root()

  local json_node = root
  for i, k in ipairs(keys) do
    local query = ts.query.parse("json", [[
      (pair
        key: (string) @key (#eq? @key "\"]] .. k .. [[\"")
        value: [(object)(array)(string)] @value
      )
    ]])

    local key_node = nil
    local key_node_depth = 9999
    local value_node = nil
    local value_node_depth = 9999
    for id, node, _ in query:iter_captures(json_node, source) do
      local name = query.captures[id]
      local depth = calculate_node_depth(node)
      if name == "key" and depth < key_node_depth then
        key_node = node
        key_node_depth = depth
      elseif name == "value" and depth < value_node_depth then
        value_node = node
        value_node_depth = depth
      end
    end

    if key_node == nil or value_node == nil then
      break
    end

    if i == #keys then
      return key_node, nil
    end

    json_node = value_node
  end

  local key = table.concat(keys, c.config.key_separator)
  return nil, "Key not found: " .. key
end

--- 文言ファイルのカーソルの位置の key の値を取得する関数
--- @param bufnr number バッファ番号
--- @param position lsp.Position カーソルの位置
--- @return string[] | nil value カーソルの位置の key
function M.get_key_at_cursor(bufnr, position)
  local ts = vim.treesitter
  ts.get_parser(bufnr):parse()

  -- カーソルの位置のノードを取得
  local row = position.line
  local col = position.character
  local cursor_node = ts.get_node({ bufnr = bufnr, pos = { row, col } })

  if cursor_node == nil then
    return nil
  end

  local pair_node = cursor_node:type() == "pair" and cursor_node
    or M.find_closest_node(cursor_node, { "pair" })

  local keys = {}

  -- 親の pair ノードをたどりながらキーを取得
  while pair_node do
    local key_node = pair_node:field("key")[1]:named_child(0)
    if key_node == nil then
      break
    end

    -- 先頭に挿入
    table.insert(keys, 1, ts.get_node_text(key_node, bufnr))

    pair_node = M.find_closest_node(pair_node, { "pair" })
  end

  return keys
end

--- @class GetTDetail
--- @field t_func_name string
--- @field namespace string
--- @field key_prefix string
--- @field scope_node TSNode|nil

--- t関数の取得に関する情報を解析する
--- @param target_node TSNode t関数取得のノード
--- @param source (integer|string) バッファ番号 or ソース
--- @param query vim.treesitter.Query クエリ
--- @return GetTDetail|nil
local function parse_get_t(target_node, source, query)
  local t_func_name = nil
  local namespace = ""
  local key_prefix = ""

  for id, node, _ in query:iter_captures(target_node, source, 0, -1) do
    local name = query.captures[id]

    if name == "i18n.t_func_name" then
      t_func_name = t_func_name or vim.treesitter.get_node_text(node, source)
    elseif name == "i18n.namespace" then
      namespace = vim.treesitter.get_node_text(node, source)
    elseif name == "i18n.key_prefix" then
      key_prefix = vim.treesitter.get_node_text(node, source)
    end
  end

  local scope_node = M.find_closest_node(target_node, { "statement_block", "jsx_element" })

  return {
    t_func_name = t_func_name,
    namespace = namespace,
    key_prefix = key_prefix,
    scope_node = scope_node,
  }
end

--- @class CallTDetail
--- @field t_func_name string
--- @field key string
--- @field key_node TSNode
--- @field key_arg_node TSNode
--- @field namespace? string
--- @field key_prefix? string

--- t関数の呼び出しに関する情報を解析する
--- @param target_node TSNode t関数呼び出しのノード
--- @param source (integer|string) バッファ番号 or ソース
--- @param query vim.treesitter.Query クエリ
--- @return CallTDetail|nil
local function parse_call_t(target_node, source, query)
  local t_func_name = nil
  local key = nil
  local key_node = nil
  local key_arg_node = nil
  local namespace = nil
  local key_prefix = nil

  for id, node, _ in query:iter_captures(target_node, source, 0, -1) do
    local name = query.captures[id]

    -- t関数の呼び出しがネストしている場合があるため、最初に見つかったものを採用する
    -- そのため key = ke or ... のような形にしている
    if name == "i18n.t_func_name" then
      t_func_name = t_func_name or vim.treesitter.get_node_text(node, source)
    elseif name == "i18n.key" then
      key = key or vim.treesitter.get_node_text(node, source)
      key_node = key_node or node
    elseif name == "i18n.key_arg" then
      key_arg_node = key_arg_node or node
    elseif name == "i18n.namespace" then
      namespace = namespace or vim.treesitter.get_node_text(node, source)
    elseif name == "i18n.key_prefix" then
      key_prefix = key_prefix or vim.treesitter.get_node_text(node, source)
    end
  end

  if key == nil or key_node == nil then
    return nil
  end

  return {
    t_func_name = t_func_name,
    key = key,
    key_node = key_node,
    key_arg_node = key_arg_node,
    namespace = namespace,
    key_prefix = key_prefix,
  }
end

--- t関数を含むノードを検索する
--- @param bufnr integer バッファ番号
--- @return FindTExpressionResultItem[]
function M.find_call_t_expressions_from_buf(bufnr)
  local workspace_dir = utils.get_workspace_root(bufnr)
  return M.find_call_t_expressions(bufnr, utils.detect_library(workspace_dir))
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
--- @param source integer|string バッファ番号 or ソース
--- @param lib? string ライブラリ
--- @param lang? string 言語
--- @return FindTExpressionResultItem[]
function M.find_call_t_expressions(source, lib, lang)
  local ok, parser = pcall(function()
    if type(source) == "string" then
      vim.validate({ lang = { lang, "string", true } })
      if lang == nil then
        error("lang is required when source is string")
      end
      return vim.treesitter.get_string_parser(source, lang)
    else
      return vim.treesitter.get_parser(source)
    end
  end)
  if not ok then
    return {}
  end

  local tree = parser:parse()[1]
  local root_node = tree:root()
  local language = lang or parser:lang()

  if not vim.tbl_contains({ "javascript", "typescript", "jsx", "tsx" }, language) then
    return {}
  end

  local query_str = ""
  if type(library_query[lib]) ~= "table" then
    return {}
  end
  for _, query_file in ipairs(library_query[lib][language] or library_query[lib]["*"]) do
    local str = M.load_query_from_file(query_file)
    if str and type(str) == "string" and str ~= "" then
      query_str = query_str .. "\n" .. str
    end
  end

  if query_str == "" then
    return {}
  end

  local query = vim.treesitter.query.parse(language, query_str)

  --- @type table<string, GetTDetail[]>
  local scope_stack = {}

  local function preprocess_t_func_name_for_scope(t_func_name)
    if lib == utils.Library.I18Next then
      return t_func_name
    elseif lib == utils.Library.NextIntl then
      return vim.split(t_func_name, ".", { plain = true })[1]
    end

    return t_func_name
  end

  --- @param value GetTDetail
  local function enter_scope(value)
    local t_func_name = value.t_func_name or "t"
    scope_stack[t_func_name] = scope_stack[t_func_name] or {}
    table.insert(scope_stack[t_func_name], value)
  end

  --- @param t_func_name string
  local function leave_scope(t_func_name)
    table.remove(scope_stack[t_func_name or "t"])
  end

  --- @param t_func_name string
  local function current_scope(t_func_name)
    local t_func_name = preprocess_t_func_name_for_scope(t_func_name)
    local stack = scope_stack[t_func_name or "t"] or {}
    return stack[#stack]
      or {
        namespace = "",
        key_prefix = "",
        scope_node = root_node,
      }
  end

  local function is_t_func(t_func_name)
    if t_func_name == "t" or scope_stack[t_func_name] ~= nil then
      return true
    end

    if lib == utils.Library.I18Next then
      if t_func_name == "i18next.t" then
        return true
      end
    elseif lib == utils.Library.NextIntl then
      -- {t_func_name}.rich や {t_func_name}.markup などの形式も考慮する
      local split = vim.split(t_func_name, ".", { plain = true })
      local name = split[1]
      local member = split[2]

      local allow_members = {
        ["rich"] = true,
        ["markup"] = true,
        ["raw"] = true,
      }
      if (name == "t" or scope_stack[name] ~= nil) and allow_members[member] then
        return true
      end
    end

    return false
  end

  --- @type FindTExpressionResultItem[]
  local result = {}

  for id, node, _ in query:iter_captures(root_node, source) do
    local name = query.captures[id]

    -- 現在のスコープから抜けたかどうかを判定する
    for t_func_name in pairs(scope_stack) do
      local current_scope_node = current_scope(t_func_name).scope_node or root_node
      if node:start() > current_scope_node:end_() or node:end_() < current_scope_node:start() then
        leave_scope(t_func_name)
      end
    end

    if name == "i18n.get_t" then
      local get_t_detail = parse_get_t(node, source, query)
      if get_t_detail then
        -- 同一のスコープ内で get_t が呼ばれた場合はスコープを上書きする形になるように、一度 leave_scope してから enter_scope する
        if get_t_detail.scope_node == current_scope(get_t_detail.t_func_name).scope_node then
          leave_scope(get_t_detail.t_func_name)
        end
        enter_scope(get_t_detail)
      end
    elseif name == "i18n.call_t" then
      local call_t_detail = parse_call_t(node, source, query)

      if call_t_detail == nil or not is_t_func(call_t_detail.t_func_name) then
        goto continue
      end

      local scope = current_scope(call_t_detail.t_func_name)

      local key_prefix = call_t_detail.key_prefix or scope.key_prefix
      local key = call_t_detail.key
      if key_prefix ~= "" then
        key = key_prefix .. c.config.key_separator .. key
      end

      local namespace = nil
      if c.config.namespace_separator ~= nil then
        local split_key = vim.split(key, c.config.namespace_separator, { plain = true })
        namespace = split_key[1]
      end

      table.insert(result, {
        node = node,
        key_node = call_t_detail.key_node,
        key_arg_node = call_t_detail.key_arg_node,
        key = key,
        key_prefix = key_prefix,
        key_arg = call_t_detail.key,
        namespace = call_t_detail.namespace or namespace or scope.namespace,
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
  local t_calls = M.find_call_t_expressions_from_buf(bufnr)

  for _, t_call in ipairs(t_calls) do
    local key_arg_node = t_call.key_arg_node
    if vim.treesitter.is_in_node_range(key_arg_node, position.line, position.character) then
      return true, t_call
    end
  end

  return false, nil
end

return M
