---@class Utils
local M = {}

M.code_win = nil
M.code_buf = nil

---Check if current buffer is a Java file
---@return boolean
function M.is_java_file()
  local file_extension = vim.fn.expand("%:e")
  return file_extension == "java"
end

---Check if the current file is a test file
---@return boolean
function M.is_test_file()
  local filename = vim.fn.expand("%:t")
  if
    filename:match("Test%.java$")
    or filename:match("Tests%.java$")
    or filename:match("IT%.java$")
    or filename:match("ITCase%.java$")
    or filename:match("TestCase%.java$")
    or filename:match("IntegrationTest%.java$")
  then
    return true
  end

  local test_class_line = M.find_test_class()
  return test_class_line ~= nil
end

---Find the main method in the current buffer
---@return number|nil Line number of the main method or nil if not found
function M.find_main_method()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for i, line in ipairs(lines) do
    if line:match("public%s+static%s+void%s+main%s*%(") or line:match("static%s+public%s+void%s+main%s*%(") then
      return i
    end
  end
  return nil
end

---Find the test class in the current buffer
---@return number|nil Line number of the test class or nil if not found
function M.find_test_class()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local class_line = nil
  local in_comment = false

  for i, line in ipairs(lines) do
    if line:match("^%s*$") then
      goto continue
    end

    if line:match("/%*") then
      in_comment = true
    end
    if line:match("%*/") then
      in_comment = false
      goto continue
    end
    if in_comment then
      goto continue
    end

    if line:match("^%s*//") then
      goto continue
    end

    if
      line:match("@Test")
      or line:match("@SpringBootTest")
      or line:match("@WebMvcTest")
      or line:match("@DataJpaTest")
      or line:match("@IntegrationTest")
      or line:match("@RestClientTest")
      or line:match("@WebFluxTest")
      or line:match("@JdbcTest")
    then
      for j = i, math.min(i + 5, #lines) do
        local next_line = lines[j]
        if next_line:match("class%s+[%w_]+") then
          return j
        end
      end
    end

    if not class_line then
      local class_patterns = {
        "class%s+%w+Test%s*[{<]",
        "class%s+%w+Tests%s*[{<]",
        "class%s+%w+IT%s*[{<]",
        "class%s+%w+ITCase%s*[{<]",
        "class%s+Test%w+%s*[{<]",
        "class%s+%w+TestCase%s*[{<]",
        "class%s+%w+IntegrationTest%s*[{<]",
      }

      for _, pattern in ipairs(class_patterns) do
        if line:match(pattern) then
          class_line = i
          break
        end
      end
    end

    ::continue::
  end

  return class_line
end

---Find all test methods in the current buffer
---@return table[] Array of test method information {line: number, method_line: number, name: string, is_parameterized: boolean}
function M.find_test_methods()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local test_methods = {}
  local i = 1

  while i <= #lines do
    local line = lines[i]
    local method_start_line = nil

    if line:match("%s*@Test%s*") or line:match("%s*@ParameterizedTest%s*") then
      local is_parameterized = line:match("%s*@ParameterizedTest%s*") ~= nil
      local method_name = nil
      local annotation_line = i

      for j = i, math.min(i + 10, #lines) do
        if lines[j]:match("%s*@%w+") then
          goto continue
        end

        if lines[j]:match("%s*[%w_]*%s*void%s+%w+%s*%(") then
          method_name = lines[j]:match("void%s+(%w+)%s*%(")
          method_start_line = j
          break
        end

        ::continue::
      end

      if method_name then
        table.insert(test_methods, {
          line = annotation_line,
          method_line = method_start_line,
          name = method_name,
          is_parameterized = is_parameterized,
        })
      end
    end
    i = i + 1
  end
  return test_methods
end

---Find the root directory of the current project
---@return string Project root directory path
function M.find_project_root()
  local current_dir = vim.fn.expand("%:p:h")
  local dir = current_dir
  while dir ~= "/" do
    if M.is_maven_project(dir) or M.is_gradle_project(dir) then
      return dir
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  return current_dir
end

---Get the source root directory of the current Java file
---@return string Source root directory path
function M.get_source_root()
  local current_file = vim.fn.expand("%:p")
  local package_name = M.get_package_name()
  if not package_name then
    return vim.fn.expand("%:p:h")
  end

  local package_path = package_name:gsub("%.", "/")
  local idx = current_file:find(package_path)
  if idx then
    return current_file:sub(1, idx - 1)
  end
  return vim.fn.expand("%:p:h")
end

---Get the package name from the current Java file
---@return string|nil Package name or nil if not found
function M.get_package_name()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for _, line in ipairs(lines) do
    local package = line:match("^%s*package%s+([%w_.]+)%s*;")
    if package then
      return package
    end
  end
  return nil
end

---Get the fully qualified class name of the current Java file
---@return string Fully qualified class name
function M.get_fully_qualified_class_name()
  local package_name = M.get_package_name()
  local class_name = vim.fn.expand("%:t:r")
  if package_name then
    return package_name .. "." .. class_name
  end
  return class_name
end

---Get all Java files in the project
---@param project_root string Project root directory path
---@return string[] Array of Java file paths
function M.get_project_java_files(project_root)
  local java_files = vim.fn.glob(project_root .. "/**/*.java", false, true)
  return java_files
end

---Check if the project at the given root is a Maven project
---@param project_root string Project root directory path
---@return boolean
function M.is_maven_project(project_root)
  return vim.fn.filereadable(project_root .. "/pom.xml") == 1
    or vim.fn.filereadable(project_root .. "/mvnw") == 1
    or vim.fn.filereadable(project_root .. "/mvnw.cmd") == 1
end

---Check if the project at the given root is a Gradle project
---@param project_root string Project root directory path
---@return boolean
function M.is_gradle_project(project_root)
  return vim.fn.filereadable(project_root .. "/build.gradle") == 1
    or vim.fn.filereadable(project_root .. "/gradlew") == 1
    or vim.fn.filereadable(project_root .. "/build.gradle.kts") == 1
end

---Check if the current file is a Spring Boot application
---@return boolean
function M.find_spring_boot_class()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for _, line in ipairs(lines) do
    if line:match("@SpringBootApplication") then
      return true
    end
  end
  return false
end

---Check if Gradle run task exists in the project
---@param project_root string Project root directory path
---@return boolean
function M.check_gradle_run_task(project_root)
  local build_file = vim.fn.filereadable(project_root .. "/build.gradle") == 1 and project_root .. "/build.gradle"
    or project_root .. "/build.gradle.kts"

  if vim.fn.filereadable(build_file) == 1 then
    local content = vim.fn.readfile(build_file)
    local has_application = false
    local has_run_task = false

    for _, line in ipairs(content) do
      if
        line:match("apply%s+plugin:%s*'application'")
        or line:match('id%s*"application"')
        or line:match("plugins%s*{[^}]*application[^}]*}")
      then
        has_application = true
      end
      if line:match("task%s+run%s*{") or line:match("tasks%.register%s*%(") then
        has_run_task = true
      end
    end

    return has_application or has_run_task
  end
  return false
end

---Check if Maven run task exists in the project
---@param project_root string Project root directory path
---@return boolean
function M.check_maven_run_task(project_root)
  if vim.fn.filereadable(project_root .. "/pom.xml") == 1 then
    local content = vim.fn.readfile(project_root .. "/pom.xml")
    for _, line in ipairs(content) do
      if
        line:match("exec%-maven%-plugin")
        or line:match("spring%-boot%-maven%-plugin")
        or line:match("<mainClass>")
      then
        return true
      end
    end
  end
  return false
end

---Restore focus to the code window
function M.restore_code_focus()
  if M.code_win and vim.api.nvim_win_is_valid(M.code_win) then
    if M.code_buf and vim.api.nvim_buf_is_valid(M.code_buf) then
      vim.api.nvim_win_set_buf(M.code_win, M.code_buf)
      vim.api.nvim_set_current_win(M.code_win)
      vim.cmd("stopinsert")
    end
  end
end

return M
