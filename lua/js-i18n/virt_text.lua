local c = require("js-i18n.config")

local ns_id = vim.api.nvim_create_namespace("I18n")

local M = {}

--- @type table<integer, uv_timer_t>
local debounce_timers = {}

local DEBOUNCE_MS = 200

--- Get the js_i18n LSP client attached to a buffer.
--- @param bufnr integer
--- @return vim.lsp.Client?
local function get_client(bufnr)
  local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "js_i18n" })
  return clients[1]
end

--- Render decorations received from the server.
--- @param bufnr integer
--- @param decorations table[]
local function render_decorations(bufnr, decorations)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  M.clear_extmarks(bufnr)

  for _, dec in ipairs(decorations) do
    local range = dec.range
    local row = range.start.line
    local col = range["end"].character

    local text = dec.value

    local virt_text = c.config.virt_text.format(text, {
      key = dec.key,
      value = dec.value,
      conceal_key = c.config.virt_text.conceal_key,
      max_length = c.config.virt_text.max_length,
      max_width = c.config.virt_text.max_width,
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
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, row, range.start.character, {
        end_row = range["end"].line,
        end_col = range["end"].character,
        conceal = "",
      })
    end

    vim.api.nvim_buf_set_extmark(bufnr, ns_id, row, col, {
      virt_text = virt_text,
      virt_text_pos = "inline",
    })
  end
end

--- Request decorations from the language server and render them.
--- @param bufnr integer
function M.request_decorations(bufnr)
  if not c.config.virt_text.enabled then
    M.clear_extmarks(bufnr)
    return
  end

  local client = get_client(bufnr)
  if not client then
    return
  end

  local uri = vim.uri_from_bufnr(bufnr)

  client:request("workspace/executeCommand", {
    command = "i18n.getDecorations",
    arguments = { { uri = uri } },
  }, function(err, result)
    if err or not result then
      return
    end
    vim.schedule(function()
      render_decorations(bufnr, result)
    end)
  end, bufnr)
end

--- Request decorations with debounce.
--- @param bufnr integer
function M.request_decorations_debounced(bufnr)
  if debounce_timers[bufnr] then
    debounce_timers[bufnr]:stop()
    debounce_timers[bufnr]:close()
  end

  local timer = vim.uv.new_timer()
  debounce_timers[bufnr] = timer
  timer:start(DEBOUNCE_MS, 0, function()
    timer:stop()
    timer:close()
    debounce_timers[bufnr] = nil
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(bufnr) then
        M.request_decorations(bufnr)
      end
    end)
  end)
end

--- Clear all extmarks in a buffer.
--- @param bufnr integer
function M.clear_extmarks(bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  end
end

--- Clear extmarks on all loaded buffers.
function M.clear_all_extmarks()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      M.clear_extmarks(bufnr)
    end
  end
end

--- Refresh decorations on all loaded buffers that have the client attached.
function M.refresh_all()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and get_client(bufnr) then
      M.request_decorations(bufnr)
    end
  end
end

return M
