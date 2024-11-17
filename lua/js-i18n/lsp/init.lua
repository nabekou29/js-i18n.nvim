local M = {}

local function camel_to_snake_case(camel)
  local snake = camel:gsub("(%u)", function(c)
    return "_" .. c:lower()
  end)
  return snake
end

--- @class I18n.lsp.ProtocolModule
--- @field handler fun(params: any, client: I18n.Client): any , any

--- @class I18n.lsp.NotifyProtocolModule
--- @field handler fun(params: any, client: I18n.Client)

--- Lsp のリクエストを処理するオブジェクトを作成
--- @param dispatchers vim.lsp.rpc.Dispatchers
--- @param client I18n.Client
--- @return vim.lsp.rpc.PublicClient
function M.create_rpc(dispatchers, client)
  local lsp_config = require("js-i18n.lsp.config")
  lsp_config.dispatchers = dispatchers

  require("js-i18n.lsp.autocmd").setup(client)

  --- @type vim.lsp.rpc.PublicClient
  local rpc = {
    request = function(method, params, callback, _notify_reply_callback)
      local protocol = camel_to_snake_case(method):gsub("/", "_")

      local ok, module = pcall(require, "js-i18n.lsp.protocol.request." .. protocol)
      if not ok then
        return false
      end
      --- @type I18n.lsp.ProtocolModule
      local protocol_module = module

      vim.schedule(function()
        local err, result = protocol_module.handler(params, client)
        if err then
          callback(err, nil)
        else
          callback(nil, result)
        end
      end)
      return true
    end,
    notify = function(method, params)
      local protocol = camel_to_snake_case(method):gsub("/", "_")

      local ok, module = pcall(require, "js-i18n.lsp.protocol.notify." .. protocol)
      if not ok then
        return false
      end
      --- @type I18n.lsp.NotifyProtocolModule
      local protocol_module = module

      vim.schedule(function()
        protocol_module.handler(params, client)
      end)
      return true
    end,
    is_closing = function()
      return false
    end,
    terminate = function() end,
  }

  return rpc
end

return M
