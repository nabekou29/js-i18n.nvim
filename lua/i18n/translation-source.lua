local Path = require("plenary.path")
local scan = require("plenary.scandir")

local M = {}

local default_pattern = "**/locales/*/translation.json"

--- ファイルパスから言語を検出する
--- @param path string ファイルパス
function M.detect_language(path)
	local abs_path = vim.fn.fnamemodify(path, ":p")
	local split = vim.split(abs_path, "/")
	local lang = split[#split - 1]
	return lang
end

--- 文言ファイルの一覧を取得する
--- @param dir string ディレクトリ
--- @return string[]
function M.get_translation_files(dir)
	local regexp = vim.regex(vim.fn.glob2regpat(default_pattern))
	local result = {}
	scan.scan_dir(dir, {
		search_pattern = "%.json$",
		on_insert = function(path)
			local match_s = regexp:match_str(path)
			if match_s then
				table.insert(result, path)
			end
		end,
	})

	return result
end

---- TranslationSource

--- @class TranslationSource
--- @field translations table<string, table<string, table>> 言語とファイルごとの翻訳リソース. 形式: { [lang: string]: { [file_name: string]: JSON } }
--- @field watch_handlers unknown[] ファイル監視ハンドラ
--- @field workspace_dir string ワークスペースディレクトリ
local TranslationSource = {}
TranslationSource.__index = TranslationSource

--- コンストラクタ
--- @param workspace_dir string ワークスペースディレクトリ
--- @return TranslationSource
function TranslationSource.new(workspace_dir)
	local self = setmetatable({}, TranslationSource)

	self.translations = {}
	self.watch_handlers = {}
	self.workspace_dir = workspace_dir
	return self
end

--- 文言ファイルの監視を開始する
function TranslationSource:start_watch()
	local files = M.get_translation_files(self.workspace_dir)

	local interval = 1000
	for _, file in ipairs(files) do
		-- 開始時に読み込む
		self:update_translation(file)

		local handler = vim.uv.new_fs_poll()
		table.insert(self.watch_handlers, handler)
		vim.uv.fs_poll_start(handler, file, interval, function(err, _)
			if err then
				print("Error watching translation file: ", err)
				return
			end

			---@diagnostic disable-next-line: redefined-local
			self:update_translation(file, function(err)
				if err then
					print("Error updating translation file: ", err)
				end
			end)
		end)
	end
end

--- 文言ファイルの監視を停止する
function TranslationSource:stop_watch()
	for _, handler in ipairs(self.watch_handlers) do
		---@diagnostic disable-next-line: undefined-field
		vim.uv.fs_poll_stop(handler)
	end
	self.watch_handles = {}
end

--- 文言ファイルの読み取り
--- @param file string ファイルパス
--- @param callback fun(err: string | nil, json: table | nil) コールバック
function TranslationSource:read_translation_file(file, callback)
	local path = Path:new(file)

	if not path:exists() then
		vim.schedule(function()
			callback("File not found", nil)
		end)
		return
	end

	local json, err = path:read()
	if err or not json then
		vim.schedule(function()
			callback("Cloud not read file" .. err, nil)
		end)
	end

	vim.schedule(function()
		local ok, result = pcall(vim.fn.json_decode, json)
		if not ok then
			callback("Cloud not decode json:" .. result, nil)
		else
			callback(nil, result)
		end
	end)
end

--- 文言ファイルの更新
--- @param file string ファイルパス
--- @param callback? fun(err: string | nil) コールバック
function TranslationSource:update_translation(file, callback)
	self:read_translation_file(file, function(err, json)
		if err then
			if callback then
				callback("Error reading translation file: " .. err)
			end
			return
		end

		local lang = M.detect_language(file)
		if self.translations[lang] == nil then
			self.translations[lang] = {}
		end
		self.translations[lang][file] = json

		if callback then
			callback()
		end
	end)
end

--- 文言の取得
--- @param lang string 言語
--- @param key string | string[] キー
--- @return string | nil
function TranslationSource:get_translation(lang, key)
	if self.translations[lang] == nil then
		return nil
	end

	--- @type string[]
	local key_array = {}
	if type(key) == "string" then
		key_array = { key }
	else
		key_array = key
	end

	for _, json in pairs(self.translations[lang]) do
		local text = vim.tbl_get(json, unpack(key_array))
		if text then
			return text
		end
	end
end

M.TranslationSource = TranslationSource

return M
