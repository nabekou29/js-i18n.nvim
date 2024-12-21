local M = {}

--- ライブラリの識別子
M.Library = {
  I18Next = "i18next",
  NextIntl = "next-intl",
}

--- プロジェクトのルートディレクトリを取得する
--- @param bufnr number
--- @return string プロジェクトのルートディレクトリ
function M.get_workspace_root(bufnr)
  -- $HOME になった場合は除外する
  local excludes = { vim.env.HOME }
  local root = vim.fs.root(bufnr, { "package.json", ".git" })

  if root and vim.tbl_contains(excludes, root) then
    root = nil
  end

  if root == nil then
    return vim.fn.getcwd()
  else
    return root
  end
end

--- 使用しているライブラリを取得する
--- @param workspace_dir string プロジェクトのルートディレクトリ
--- @return string|nil ライブラリの識別子
function M.detect_library(workspace_dir)
  local ok, package_json = pcall(vim.fn.readfile, workspace_dir .. "/package.json")
  if not ok then
    return nil
  end

  local ok, package = pcall(vim.fn.json_decode, package_json)

  if not ok or package == nil then
    return nil
  end

  local library_names = {
    [M.Library.I18Next] = {
      "i18next",
      "react-i18next",
      "next-i18next",
    },
    [M.Library.NextIntl] = {
      "next-intl",
    },
  }

  for _, dep_key in ipairs({
    "dependencies",
    "devDependencies",
    "peerDependencies",
    "peerDependenciesMeta",
    "bundledDependencies",
    "optionalDependencies",
  }) do
    if package[dep_key] == nil then
      goto continue
    end

    for lib, names in pairs(library_names) do
      for _, name in ipairs(names) do
        if package[dep_key][name] ~= nil then
          return lib
        end
      end
    end

    ::continue::
  end

  return nil
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
--- @return string
function M.utf_truncate(str, max_length, ellipsis_char)
  ellipsis_char = ellipsis_char or ""

  if vim.fn.strchars(str) <= max_length then
    return str
  end

  local max_length_without_ellipsis = max_length - vim.fn.strchars(ellipsis_char)
  return vim.fn.strcharpart(str, 0, max_length_without_ellipsis) .. ellipsis_char
end

--- 文字列を文字幅で切り詰める
--- @param str string 文字列
--- @param max_width number 最大幅
--- @param ellipsis_char? string 省略記号
--- @return string
function M.truncate_display_width(str, max_width, ellipsis_char)
  ellipsis_char = ellipsis_char or ""
  local width = vim.fn.strdisplaywidth(str)
  if width <= max_width then
    return str
  end

  local ellipsis_char_width = vim.fn.strdisplaywidth(ellipsis_char)
  local max_width_without_ellipsis = max_width - ellipsis_char_width

  local truncated = ""
  local current_width = 0
  local i = 1

  while current_width < max_width_without_ellipsis do
    local char = vim.fn.strcharpart(str, i - 1, 1)
    local char_width = vim.fn.strdisplaywidth(char)

    if current_width + char_width > max_width_without_ellipsis then
      break
    end

    truncated = truncated .. char
    current_width = current_width + char_width
    i = i + vim.fn.strchars(char)
  end

  return truncated .. ellipsis_char
end

--- 翻訳文言の中の改行文字などをエスケープする
--- @param str string
--- @return string
function M.escape_translation_text(str)
  local escapes = {
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\t"] = "\\t",
    ['"'] = '\\"',
  }
  return (str:gsub(".", escapes))
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
