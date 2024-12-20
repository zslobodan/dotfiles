---@class Runner
local M = {}

local logger = require("java-runner.logger")
local utils = require("java-runner.utils")
local config = require("java-runner.config")

local terminal_win = nil
local terminal_buf = nil

---Helper function
---Sets default terminal options
local function setup_terminal_window()
  if terminal_win and vim.api.nvim_win_is_valid(terminal_win) then
    vim.api.nvim_set_current_win(terminal_win)
    vim.cmd("startinsert!")
    return
  end

  vim.cmd.new()
  terminal_win = vim.api.nvim_get_current_win()
  terminal_buf = vim.api.nvim_get_current_buf()

  vim.cmd.wincmd("J")
  vim.api.nvim_win_set_height(terminal_win, config.options.terminal.size)
  vim.wo.winfixheight = true

  vim.bo[terminal_buf].filetype = "terminal"
  vim.wo[terminal_win].number = false
  vim.wo[terminal_win].relativenumber = false
  vim.wo[terminal_win].scrolloff = 0

  vim.keymap.set("n", "i", "i", { buffer = terminal_buf, noremap = true })
  vim.keymap.set("n", "<ESC>", function()
    utils.restore_code_focus()
  end, { buffer = terminal_buf, noremap = true })

  vim.keymap.set("n", "q", function()
    if terminal_win and vim.api.nvim_win_is_valid(terminal_win) then
      vim.api.nvim_win_close(terminal_win, true)
      vim.schedule(function()
        utils.restore_code_focus()
      end)
    end
  end, { buffer = terminal_buf, noremap = true })
end

---Run the current Java file
function M.run_java_file()
  if utils.is_test_file() then
    logger.warn("Cannot run test files with this command. Use test runners instead.")
    return
  end

  utils.code_win = vim.api.nvim_get_current_win()
  utils.code_buf = vim.api.nvim_get_current_buf()
  vim.cmd("silent! write")

  local project_root = utils.find_project_root()
  local source_root = utils.get_source_root()
  local output_dir = project_root .. "/output"
  local fully_qualified_name = utils.get_fully_qualified_class_name()
  local package_path = utils.get_package_name() and utils.get_package_name():gsub("%.", "/") or ""
  local is_spring_boot = utils.find_spring_boot_class()

  M.ensure_directory(output_dir)
  if package_path ~= "" then
    M.ensure_directory(output_dir .. "/" .. package_path)
  end

  logger.debug("Running Java file", {
    project_root = project_root,
    source_root = source_root,
    output_dir = output_dir,
    class_name = fully_qualified_name,
    package_path = package_path,
    is_spring_boot = is_spring_boot,
  })

  vim.schedule(function()
    setup_terminal_window()

    local cmd

    if is_spring_boot then
      logger.debug("Detected Spring Boot application")
      if utils.is_maven_project(project_root) then
        logger.debug("Detected Maven project")
        if vim.fn.filereadable(project_root .. "/mvnw") == 1 then
          if vim.fn.has("win32") == 1 then
            cmd = string.format('cd "%s" && ./mvnw.cmd spring-boot:run', project_root)
          else
            cmd = string.format('cd "%s" && ./mvnw spring-boot:run', project_root)
          end
        else
          cmd = string.format('cd "%s" && mvn spring-boot:run', project_root)
        end
      elseif utils.is_gradle_project(project_root) then
        logger.debug("Detected Gradle project")
        if vim.fn.filereadable(project_root .. "/gradlew") == 1 then
          cmd = string.format('cd "%s" && ./gradlew bootRun', project_root)
        else
          cmd = string.format('cd "%s" && gradle bootRun', project_root)
        end
      end
    else
      local use_build_tool = false
      local build_cmd = nil

      if utils.is_gradle_project(project_root) then
        if utils.check_gradle_run_task(project_root) then
          use_build_tool = true
          logger.debug("Using Gradle as build tool")
          if vim.fn.filereadable(project_root .. "/gradlew") == 1 then
            build_cmd = string.format('cd "%s" && ./gradlew run', project_root)
          else
            build_cmd = string.format('cd "%s" && gradle run', project_root)
          end
        end
      elseif utils.is_maven_project(project_root) then
        if utils.check_maven_run_task(project_root) then
          use_build_tool = true
          logger.debug("Using Maven as build tool")
          if vim.fn.filereadable(project_root .. "/mvnw") == 1 then
            if vim.fn.has("win32") == 1 then
              build_cmd = string.format(
                'cd "%s" && ./mvnw.cmd exec:java -Dexec.mainClass="%s"',
                project_root,
                fully_qualified_name
              )
            else
              build_cmd =
                string.format('cd "%s" && ./mvnw exec:java -Dexec.mainClass="%s"', project_root, fully_qualified_name)
            end
          else
            build_cmd =
              string.format('cd "%s" && mvn exec:java -Dexec.mainClass="%s"', project_root, fully_qualified_name)
          end
        end
      end

      if use_build_tool and build_cmd then
        cmd = build_cmd
        logger.info("Using build tool to run the application")
      else
        if use_build_tool == false then
          logger.info("No build tool run task found, falling back to javac")
        end
        local java_files = utils.get_project_java_files(source_root)
        local compile_cmd =
          string.format('javac -d "%s" -cp "%s" %s', output_dir, output_dir, table.concat(java_files, " "))
        local run_cmd = string.format('java -cp "%s" %s', output_dir, fully_qualified_name)
        cmd = string.format('cd "%s" && %s && %s', project_root, compile_cmd, run_cmd)
      end
    end

    vim.fn.termopen(cmd, {
      on_exit = function(_, exit_code)
        if exit_code ~= 0 then
          ---@diagnostic disable-next-line: param-type-mismatch
          local output = vim.api.nvim_buf_get_lines(terminal_buf, 0, -1, false)
          local has_error = false
          for _, line in ipairs(output) do
            if line:match("error:") then
              has_error = true
              break
            end
          end
          if has_error then
            vim.schedule(function()
              logger.error("Compilation failed", {
                has_error = has_error,
              })
            end)
          end
        end
      end,
    })

    vim.schedule(function()
      vim.cmd("startinsert!")
    end)
  end)
end

---Run Java tests
---@param method_name string|nil Optional specific test method to run
---@param run_all boolean Whether to run all tests in the file
function M.run_java_tests(method_name, run_all)
  utils.code_win = vim.api.nvim_get_current_win()
  utils.code_buf = vim.api.nvim_get_current_buf()
  vim.cmd("silent! write")

  local project_root = utils.find_project_root()
  local class_name = utils.get_fully_qualified_class_name()

  logger.info("Running tests", {
    project_root = project_root,
    class_name = class_name,
    method = method_name,
    run_all = run_all,
  })

  if not run_all and not method_name then
    local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
    local test_methods = utils.find_test_methods()

    for _, test in ipairs(test_methods) do
      if cursor_line >= test.line and cursor_line <= test.method_line + 1 then
        method_name = test.name
        break
      end
    end

    if not method_name then
      logger.warn("No test method found at cursor position")
      return
    end
  end

  vim.schedule(function()
    setup_terminal_window()

    local cmd
    if utils.is_gradle_project(project_root) then
      cmd = M.run_gradle_tests(project_root, method_name, class_name)
    else
      cmd = M.run_maven_tests(project_root, method_name)
    end

    vim.fn.termopen(cmd, {
      on_exit = function(_, exit_code)
        if exit_code ~= 0 then
          ---@diagnostic disable-next-line: param-type-mismatch
          local output = vim.api.nvim_buf_get_lines(terminal_buf, 0, -1, false)
          local has_error = false
          for _, line in ipairs(output) do
            if line:match("error:") or line:match("FAILURES") then
              has_error = true
              break
            end
          end
          if has_error then
            vim.schedule(function()
              local message = method_name and string.format("Test failed: %s#%s", class_name, method_name)
                or string.format("Tests failed in class: %s", class_name)
              logger.error(message)
            end)
          end
        else
          vim.schedule(function()
            local message = method_name and string.format("Test passed: %s#%s", class_name, method_name)
              or string.format("All tests passed in class: %s", class_name)
            logger.info(message)
          end)
        end
      end,
    })

    vim.schedule(function()
      vim.cmd("startinsert!")
    end)
  end)
end

---Ensure directory exists, create if it doesn't
---@param dir string Directory path to ensure
function M.ensure_directory(dir)
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
end

---Get the Gradle command for the project
---@param project_root string Project root directory path
---@return string Gradle command to use
function M.get_gradle_command(project_root)
  if vim.fn.has("win32") == 1 then
    if vim.fn.filereadable(project_root .. "/gradlew.bat") == 1 then
      return project_root .. "/gradlew.bat"
    end
  else
    if vim.fn.filereadable(project_root .. "/gradlew") == 1 then
      if vim.fn.executable(project_root .. "/gradlew") == 0 then
        vim.fn.system("chmod +x " .. project_root .. "/gradlew")
      end
      return "./gradlew"
    end
  end

  if vim.fn.executable("gradle") == 1 then
    return "gradle"
  end

  error("No Gradle installation found. Please install Gradle or use the wrapper.")
end

---Get the Maven command for the project
---@param project_root string Project root directory path
---@return string Maven command to use
function M.get_maven_command(project_root)
  if vim.fn.has("win32") == 1 then
    if vim.fn.filereadable(project_root .. "/mvnw.cmd") == 1 then
      return project_root .. "/mvnw.cmd"
    end
  else
    if vim.fn.filereadable(project_root .. "/mvnw") == 1 then
      if vim.fn.executable(project_root .. "/mvnw") == 0 then
        vim.fn.system("chmod +x " .. project_root .. "/mvnw")
      end
      return "./mvnw"
    end
  end

  if vim.fn.executable("mvn") == 1 then
    return "mvn"
  end

  error("No Maven installation found. Please install Maven or use the wrapper.")
end

---Run Gradle tests
---@param project_root string Project root directory path
---@param method_name string|nil Optional specific test method to run
---@param class_name string|nil Optional specific test class to run
---@return string Command to run the tests
function M.run_gradle_tests(project_root, method_name, class_name)
  local gradle_cmd = M.get_gradle_command(project_root)
  local cmd

  if method_name then
    cmd = string.format('cd "%s" && %s test --tests "%s.%s"', project_root, gradle_cmd, class_name, method_name)
  elseif class_name then
    cmd = string.format('cd "%s" && %s test --tests "%s"', project_root, gradle_cmd, class_name)
  else
    cmd = string.format('cd "%s" && %s test', project_root, gradle_cmd)
  end

  return cmd
end

---Run Maven tests
---@param project_root string Project root directory path
---@param method_name string|nil Optional specific test method to run
---@return string Command to run the tests
function M.run_maven_tests(project_root, method_name)
  local maven_cmd = M.get_maven_command(project_root)
  local cmd

  if method_name then
    cmd = string.format(
      'cd "%s" && %s test -Dtest=%s#%s',
      project_root,
      maven_cmd,
      utils.get_fully_qualified_class_name(),
      method_name
    )
  else
    cmd = string.format('cd "%s" && %s test -Dtest=%s', project_root, maven_cmd, utils.get_fully_qualified_class_name())
  end

  return cmd
end

return M
