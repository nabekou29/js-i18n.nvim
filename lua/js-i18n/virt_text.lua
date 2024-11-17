local analyzer = require("js-i18n.analyzer")
local c = require("js-i18n.config")
local utils = require("js-i18n.utils")

local ns_id = vim.api.nvim_create_namespace("I18n")

local M = {}

--- フォーマットのオプション
--- @class I18n.VirtText.FormatOpts
--- @field key string キー
--- @field lang string 言語
--- @field current_language string 選択中の言語
--- @field config I18n.Config 設定

--- 翻訳を取得する
--- @param lang string 言語
--- @param key string キー
--- @param t_source I18n.TranslationSource 翻訳ソース
--- @param library? string ライブラリ
--- @return string | nil 翻訳, string | nil 言語
local function get_translation(lang, key, t_source, library)
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
    local split_key = vim.split(key, c.config.key_separator, { plain = true })

    local namespace = nil
    if c.config.namespace_separator ~= nil then
      local split_first_key = vim.split(split_key[1], c.config.namespace_separator, { plain = true })
      namespace = split_first_key[1]
      split_key[1] = split_first_key[2]
    end

    local text = t_source:get_translation(l, split_key, library, namespace)
    if text ~= nil and type(text) == "string" then
      return text, l
    end
  end

  return nil, nil
end

--- バーチャルテキストを表示する
--- @param bufnr integer バッファ番号
--- @param current_language string 言語
--- @param t_source I18n.TranslationSource 翻訳ソース
function M.set_extmark(bufnr, current_language, t_source)
  if not c.config.virt_text.enabled then
    return
  end

  local workspace_dir = utils.get_workspace_root(bufnr)
  local library = utils.detect_library(workspace_dir)

  M.clear_extmarks(bufnr)

  local t_calls = analyzer.find_call_t_expressions_from_buf(bufnr)

  for _, t_call in ipairs(t_calls) do
    local key_node = t_call.key_node

    local text, lang = get_translation(current_language, t_call.key, t_source, library)
    if text == nil or lang == nil then
      goto continue
    end

    local key_row_start, key_col_start, key_row_end, key_col_end = key_node:range()
    local virt_text = c.config.virt_text.format(text, {
      key = t_call.key,
      lang = lang,
      current_language = current_language,
      config = c.config,
    })
    if type(virt_text) == "string" then
      virt_text = { { virt_text, "@i18n.translation" } }
    end

    if c.config.virt_text.conceal_key then
      local conceallevel = vim.opt_local.conceallevel:get()
      if conceallevel < 1 or conceallevel > 2 then
        vim.notify_once(
          "To use virt_text.conceal_key, conceallevel must be 1 or 2.",
          vim.log.levels.WARN
        )
      end
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, key_row_start, key_col_start - 1, {
        end_row = key_row_end,
        end_col = key_col_end + 1,
        conceal = "",
      })
    end

    vim.api.nvim_buf_set_extmark(bufnr, ns_id, key_row_start, key_col_start + #t_call.key_arg + 1, {
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
