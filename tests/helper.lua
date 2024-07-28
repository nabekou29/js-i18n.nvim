local M = {}

M.setup = function()
  _G._TEST = true
  _G._test_async_ui = {
    ---@diagnostic disable-next-line: unused-vararg
    input = function(...)
      error("_test_async_ui.input should be stubbed")
      return ""
    end,
    ---@diagnostic disable-next-line: unused-vararg
    select = function(...)
      error("_test_async_ui.input should be stubbed")
      return ""
    end,
  }
end

M.teardown = function()
  _G._TEST = nil
end

local test_template_project_root_path = "tests/projects"
local test_project_root_path = "tests/.tmp_projects"

-- テスト用のプロジェクトのパス
M.project_path = {
  i18next = test_project_root_path .. "/i18next",
}

M.projects = {
  i18next = "i18next",
}

--- @class test.Project
--- @field path string

--- テスト用のプロジェクトをコピーして使う
--- @param project_name string
--- @return test.Project
M.use_project = function(project_name)
  -- テスト用のプロジェクトをコピー
  local template_project_path = test_template_project_root_path .. "/" .. project_name
  local project_path = test_project_root_path .. "/" .. project_name

  os.execute("rm -rf " .. project_path)
  os.execute("mkdir -p " .. test_project_root_path)
  os.execute("cp -r " .. template_project_path .. " " .. project_path)

  return {
    path = project_path,
  }
end

return M
