local M = {}

--- プロジェクトのルートディレクトリを取得する
--- @param bufnr number
--- @return string プロジェクトのルートディレクトリ
function M.get_workspace_root(bufnr)
  local root = vim.fs.root(bufnr, "package.json")
  if root == nil then
    return vim.fn.getcwd()
  else
    return root
  end
end

--- 使用すべき言語を取得する
--- @param current_language string | nil 選択中の言語
--- @param primary_language string[] 優先表示する言語
--- @param available_languages string[] 利用可能な言語
function M.get_language(current_language, primary_language, available_languages)
  -- 選択中の言語があればそれを返す
  if current_language ~= nil then
    return current_language
  end
  -- 優先表示する言語が利用可能な言語に含まれていればそれを返す
  -- 先頭の要素がより優先される
  for _, lang in ipairs(primary_language) do
    if vim.tbl_contains(available_languages, lang) then
      return lang
    end
  end

  return available_languages[1]
end

--- マルチバイト文字を考慮して文字列を切り詰める
--- @param str string 文字列
--- @param max_length number 最大長
--- @param ellipsis_char? string 省略記号
function M.utf_truncate(str, max_length, ellipsis_char)
  ellipsis_char = ellipsis_char or ""
  local pos = vim.str_utf_pos(str)
  if #pos <= max_length then
    return str
  end
  return str:sub(1, pos[max_length + 1] - 1) .. ellipsis_char
end

--- Treesitter のノードから指定したタイプの親ノードを取得する
--- @param node TSNode
--- @param type_ string
function M.find_parent_by_type(node, type_)
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

--- テーブルに値をセットする
--- @param tbl table テーブル
--- @param value any 値
--- @param ... string キー
--- @return string|nil error
function M.tbl_set(tbl, value, ...)
  local keys = { ... }

  local tmp = tbl
  for i, key in ipairs(keys) do
    if i == #keys then
      tmp[key] = value
    else
      if tmp[key] == nil then
        tmp[key] = {}
      elseif type(tmp[key]) ~= "table" then
        local key_path = vim.fn.join(vim.list_slice(keys, 1, i), ".")
        return "failed to set value (" .. key_path .. " is not a table)"
      end
      tmp = tmp[key]
    end
  end
end

return M
