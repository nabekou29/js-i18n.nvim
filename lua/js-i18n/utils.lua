local M = {}

--- Truncate a string by character count.
--- @param str string
--- @param max_length number
--- @param ellipsis_char? string
--- @return string
function M.utf_truncate(str, max_length, ellipsis_char)
  ellipsis_char = ellipsis_char or ""
  if vim.fn.strchars(str) <= max_length then
    return str
  end
  local max_length_without_ellipsis = max_length - vim.fn.strchars(ellipsis_char)
  return vim.fn.strcharpart(str, 0, max_length_without_ellipsis) .. ellipsis_char
end

--- Truncate a string by display width.
--- @param str string
--- @param max_width number
--- @param ellipsis_char? string
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

--- Escape newlines and special characters in translation text.
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

return M
