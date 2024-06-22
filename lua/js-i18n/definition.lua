local utils = require("js-i18n.utils")
local c = require("js-i18n.config")
local Path = require("plenary.path")

local M = {}

-- ノードの深さを計算する関数
local function calculate_node_depth(node)
  local depth = 0
  while node:parent() do
    node = node:parent()
    depth = depth + 1
  end
  return depth
end

--- Treesitterパーサーをセットアップしてキーにマッチするノードを取得する関数
--- @param bufnr number
--- @param key string
--- @param start? integer
--- @param stop? integer
--- @return TSNode | nil, string | nil
local function get_node_for_key(bufnr, key, start, stop)
  local ts = vim.treesitter

  local parser = ts.get_parser(bufnr, "json")
  local tree = parser:parse()[1]
  local root = tree:root()

  local keys = vim.split(key, c.config.key_separator, { plain = true })
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
  else
    table.remove(keys, 1)
    local parent = node:parent()
    if parent ~= nil then
      return get_node_for_key(
        bufnr,
        table.concat(keys, c.config.key_separator),
        parent:start(),
        parent:end_()
      )
    end
  end

  return nil, "Key not found: " .. key
end

--- @param node TSNode
--- @param type_ string
local function find_parent_by_type(node, type_)
  if node:type() == type_ then
    return node
  end

  local parent = node:parent()
  while parent ~= nil do
    if parent:type() == type_ then
      return parent
    end
    parent = parent:parent()
  end
  return nil
end

--- ハンドラ
--- @param params lsp.DefinitionParams
--- @param callback fun(err: string | nil, result: any)
--- @param current_language string | nil
--- @param t_source_by_workspace table<string, I18n.TranslationSource>
-- - @return lsp.Location | lsp.Location[] | nil
function M.handler(params, callback, current_language, t_source_by_workspace)
  local textDocument = params.textDocument
  local position = params.position

  local bufnr = vim.uri_to_bufnr(textDocument.uri)

  local workspace_dir = utils.get_workspace_root(bufnr)
  local t_source = t_source_by_workspace[workspace_dir]
  local lang = utils.get_language(
    current_language,
    c.config.primary_language,
    t_source:get_available_languages()
  )

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
  if node == nil or node:type() ~= "string_fragment" then
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
            (string_fragment) @str_frag
          )
        )
      )
    ]]
  )

  local call_exp_node = find_parent_by_type(node, "call_expression")
  if call_exp_node == nil then
    return false
  end

  local key_node = nil
  for _, match in query:iter_matches(call_exp_node, bufnr) do
    key_node = match[2]
  end
  if key_node == nil then
    return false
  end

  local key = (vim.treesitter.get_node_text(key_node, bufnr))

  for file, _ in pairs(t_source:get_translation_source_by_lang(lang)) do
    local bufnr = vim.api.nvim_create_buf(false, true)
    local content = Path:new(file):read()
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(content, "\n"))

    local node = get_node_for_key(bufnr, key)
    if node ~= nil then
      local row_start, col_start, row_end, col_end = node:range()
      callback(nil, {
        uri = vim.uri_from_fname(file),
        range = {
          start = { line = row_start, character = col_start },
          ["end"] = { line = row_end, character = col_end },
        },
      })
      vim.api.nvim_buf_delete(bufnr, { force = true })
      return true
    end

    vim.api.nvim_buf_delete(bufnr, { force = true })
    return false
  end

  return false
end

return M
