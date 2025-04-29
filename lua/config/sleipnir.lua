local state = {
  floating = {
    buf = -1,
    win = -1,
    job = nil,
    opts = nil,
  },
}

-- Define sleipnir_path (Windows format)
local sleipnir_win_path = 'C:\\Users\\Tj Gienger\\dev\\odin\\SleipnirEngine' -- Adjust if different
local sleipnir_wsl_path = '/mnt/c/Users/Tj Gienger/dev/odin/SleipnirEngine'

local function output_scratch_log(output)
  local unique_name = 'Build Logs ' .. os.date '%Y-%m-%d %H:%M:%S'
  scratch = Snacks.scratch.open {
    name = unique_name,
    ft = 'log',
    filekey = {
      cwd = true, -- use current working directory
      branch = true, -- use current branch name
      count = true, -- use vim.v.count1
    },
    autowrite = true,
    win = { style = 'float', width = 100, height = 30 },
  }
  vim.api.nvim_buf_set_lines(scratch.buf, 0, -1, false, output)
end

local function create_terminal(opts)
  opts = opts or {}
  local width = math.floor(vim.o.columns * 0.5)
  local height = math.floor(vim.o.lines * 0.25)
  local row = math.floor((vim.o.lines - height))
  local col = 0

  local buf = vim.api.nvim_create_buf(false, true)
  -- vim.api.nvim_buf_set_option(buf, 'buflisted', false)
  -- vim.api.nvim_buf_set_option(buf, 'bufhidden', 'hide')

  local win_opts = {
    relative = 'editor',
    row = row,
    col = col,
    width = width,
    height = height,
    style = 'minimal',
    border = 'rounded',
  }

  local win = vim.api.nvim_open_win(buf, true, win_opts)

  -- Set keymaps and autocommands for the new buffer

  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>lua vim.api.nvim_win_close(' .. win .. ', true)<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 't', '<Esc>', '<cmd>lua vim.api.nvim_win_close(' .. win .. ', true)<CR>', { noremap = true, silent = true })

  vim.api.nvim_create_autocmd('WinLeave', {
    buffer = buf,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
    once = false,
  })

  return { buf = buf, win = win }
end

-- Create or reuse a terminal popup window
local function open_terminal_popup(cmd, on_exit)
  if not vim.api.nvim_win_is_valid(state.floating.win) then
    state.floating = create_terminal { buf = state.floating.buf }
  end

  -- Check if a job is running in the terminal
  if state.floating.job and vim.fn.jobwait({ state.floating.job }, 0)[1] == -1 then
    vim.notify('Stopping existing sleipnir.exe process', vim.log.levels.INFO)
    vim.fn.jobstop(state.floating.job)
  end

  -- Run the command in the terminal
  local job_id = vim.fn.termopen(cmd, {
    on_exit = function(_, code, _)
      state.floating.job = nil
      if on_exit then
        on_exit(_, code, _)
      end
    end,
  })
  state.floating.job = job_id
  vim.cmd 'startinsert'
end

-- Track active shader compilations
vim.g.shader_compile_in_progress = 0
local shader_tasks = {} -- Table to store fidget tasks per buffer

-- Trigger shader compilation on saving .slang files
vim.api.nvim_create_autocmd('BufWritePre', {
  callback = function()
    local file_path = vim.fn.expand '%:p'
    local buf = vim.api.nvim_get_current_buf()

    -- Increment global counter
    vim.g.shader_compile_in_progress = vim.g.shader_compile_in_progress + 1
    -- vim.notify('BufWritePre: Shader compilation started for ' .. file_path .. ', counter: ' .. vim.g.shader_compile_in_progress, vim.log.levels.DEBUG)

    -- Create a fidget progress task for this shader
    local task = require('fidget').progress.handle.create {
      title = 'Compiling shader',
      message = 'Compiling ' .. vim.fn.fnamemodify(file_path, ':t'),
      percentage = 0,
    }

    -- Store the task in a buffer-local table
    shader_tasks[buf] = task
  end,
  pattern = '*.slang',
})

vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = '*.slang',
  callback = function()
    local file_path = vim.fn.expand '%:p'
    local output_path = vim.fn.expand '%:p:r' .. '.spv'
    local buf = vim.api.nvim_get_current_buf()
    local task = shader_tasks[buf]

    -- Ensure counter is decremented even if errors occur
    local function decrement_counter()
      vim.g.shader_compile_in_progress = math.max(0, vim.g.shader_compile_in_progress - 1)
      -- vim.notify('BufWritePost: Counter decremented to ' .. vim.g.shader_compile_in_progress, vim.log.levels.DEBUG)
    end

    if not task then
      -- vim.notify('Shader compilation task not found for buffer ' .. buf, vim.log.levels.ERROR)
      decrement_counter()
      return
    end

    -- Update fidget task to show compilation in progress
    task:report { message = 'Compiling ' .. vim.fn.fnamemodify(file_path, ':t'), percentage = 50 }

    -- Execute the compilation command
    local command = string.format('slangc "%s" -profile glsl_460 -target spirv -o "%s"', file_path, output_path)
    -- vim.notify('Executing: ' .. command, vim.log.levels.DEBUG)
    local success, result = pcall(vim.fn.system, command)

    -- Check for errors and update fidget task
    if not success or vim.v.shell_error ~= 0 then
      task:report { status = 'error', message = 'Shader compilation failed', percentage = 100 }
      -- vim.notify('Error compiling shader: ' .. (result or 'Unknown error'), vim.log.levels.ERROR)
    else
      task:report { status = 'success', message = 'Shader compiled: ' .. vim.fn.fnamemodify(output_path, ':t'), percentage = 100 }
      -- vim.notify('Shader compiled successfully: ' .. output_path, vim.log.levels.INFO)
    end

    -- Finish the task and clean up
    task:finish()
    shader_tasks[buf] = nil
    decrement_counter()
  end,
})

vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
  pattern = '*.slang',
  command = 'set filetype=hlsl',
})

local function is_wsl()
  return vim.fn.has 'wsl' == 1
end

vim.keymap.set('n', '<leader>sr', function()
  local fidget = require 'fidget'
  local job = require 'plenary.job'

  local function update_fidget(task, stdout, is_stderr)
    if is_stderr then
      -- vim.notify('STDERR: ' .. stdout, vim.log.levels.WARN)
      return
    end
    local progress = string.match(stdout, 'Progress: (%d+%%)')
    if progress then
      local percentage = tonumber(progress:match '%d+')
      task:report { status = 'Building Sleipnir', message = 'Compiling Sleipnir...', percentage = percentage }
    end
  end

  -- Detect if running in WSL2
  local is_wsl = is_wsl()

  -- Get current working directory
  local cwd = vim.fn.getcwd()

  -- Convert cwd to Windows path if in WSL2
  local win_cwd = cwd
  if is_wsl then
    win_cwd = vim.fn.substitute(cwd, '^/mnt/c', 'C:', 'g')
    win_cwd = vim.fn.substitute(win_cwd, '/', '\\\\', 'g')
  end

  -- Check if cwd matches sleipnir_path
  local expected_path = is_wsl and sleipnir_wsl_path or sleipnir_win_path
  if cwd ~= expected_path then
    -- vim.notify('Error: Wrong directory (for SleipnirEngine)', vim.log.levels.ERROR)
    return
  end

  local task = fidget.progress.handle.create {
    title = 'Building Sleipnir',
    message = 'Compiling shaders...',
    percentage = 0,
  }

  -- Save all files
  vim.cmd 'wa'

  -- Wait for shader compilation to complete with timeout
  local start_time = vim.loop.now()
  local timeout_ms = 10000 -- 10 seconds
  while vim.g.shader_compile_in_progress > 0 do
    if vim.loop.now() - start_time > timeout_ms then
      vim.notify('Timeout waiting for shader compilation. Counter: ' .. vim.g.shader_compile_in_progress, vim.log.levels.ERROR)
      vim.g.shader_compile_in_progress = 0
      break
    end
    vim.loop.sleep(100)
  end

  task:report { message = 'Shader compilation complete' }
  task:report { message = 'Compiling Sleipnir...', percentage = 0 }

  -- Build command (only build_editor.bat)
  local build_cmd
  if is_wsl then
    build_cmd = '/mnt/c/Windows/System32/cmd.exe /C "cd /d ' .. win_cwd .. ' && build_editor.bat"'
  else
    build_cmd = 'cd ' .. win_cwd .. ' && build_editor.bat'
  end

  -- Terminal command (sleipnir.exe)
  local term_cmd
  if is_wsl then
    term_cmd = '/mnt/c/Windows/System32/cmd.exe /C "cd /d ' .. win_cwd .. ' && sleipnir.exe"'
  else
    term_cmd = 'cd ' .. win_cwd .. ' && sleipnir.exe'
  end

  vim.g.sleipnir_term_cmd = term_cmd

  -- Capture build output
  local build_output = {}

  job
    :new({
      command = 'bash',
      args = { '-c', build_cmd },
      cwd = cwd,
      env = {
        WSLENV = 'PWD/p',
      },
      on_stdout = function(_, data)
        table.insert(build_output, data)
        update_fidget(task, data, false)
      end,
      on_stderr = function(_, data)
        table.insert(build_output, 'STDERR: ' .. data)
        update_fidget(task, data, true)
      end,
      on_exit = function(_, exit_code, _)
        local is_success = exit_code == 0 or (exit_code == 127 and task.percentage == 100)
        vim.schedule(function()
          if not is_success then
            task:report { status = 'error', message = 'Build failed' }

            output_scratch_log(build_output)

            -- -- Function to highlight STDERR lines
            -- local function highlight_stderr(buf)
            --   vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1) -- Clear previous highlights
            --   for i, line in ipairs(build_output) do
            --     local start_idx, end_idx = line:find 'STDERR'
            --     if start_idx then
            --       vim.api.nvim_buf_add_highlight(buf, -1, 'Error', i - 1, start_idx - 1, end_idx)
            --     end
            --   end
            -- end
            --
            -- -- Apply highlights initially
            -- highlight_stderr(scratch.buf)
            --
            -- -- Set up an autocommand to reapply highlights whenever the buffer is read or reopened
            -- vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWinEnter' }, {
            --   buffer = scratch.buf,
            --   callback = function()
            --     highlight_stderr(scratch.buf)
            --   end,
            -- })
          else
            task:report { status = 'success', message = 'Build completed successfully' }
            -- open_terminal_popup(term_cmd)
            Snacks.terminal.open(term_cmd, {
              auto_close = false,
              win = {
                style = 'split', -- Options: "float" (default), "split", or "tab"
                position = 'bottom', -- For "split" windows, specify position: "bottom" or "top"
                width = 80, -- Width of the terminal window (for "float" style)
                height = 20, -- Height of the terminal window (for "float" style)
                on_win = function(term)
                  -- Optional callback when the window is created
                  print 'Terminal window opened!'
                end,
              },
            })
          end
          task:finish()
        end)
      end,
    })
    :start()
end, { desc = 'Save all, Build and Run Sleipnir editor (WSL2/Windows)' })

vim.keymap.set('n', '<leader>bg', function()
  local cwd = vim.fn.getcwd()
  if cwd ~= sleipnir_wsl_path then
    return
  end
  vim.notify 'build game not yet implemented'
  -- vim.cmd(':! cd ' .. cwd .. ' && build_game_dll.bat')
end, { desc = 'Build game DLL' })

vim.keymap.set('n', '<leader>re', function()
  local cwd = vim.fn.getcwd()
  if cwd ~= sleipnir_wsl_path then
    return
  end

  local win_cwd = cwd
  if is_wsl then
    win_cwd = vim.fn.substitute(cwd, '^/mnt/c', 'C:', 'g')
    win_cwd = vim.fn.substitute(win_cwd, '/', '\\\\', 'g')
  end

  local term_cmd
  if is_wsl then
    term_cmd = '/mnt/c/Windows/System32/cmd.exe /C "cd /d ' .. win_cwd .. ' && sleipnir.exe"'
  else
    term_cmd = 'cd ' .. win_cwd .. ' && sleipnir.exe'
  end

  -- Check if cwd matches sleipnir_path
  local expected_path = is_wsl and sleipnir_wsl_path or sleipnir_win_path
  if cwd ~= expected_path then
    -- vim.notify('Error: Wrong directory (for SleipnirEngine)', vim.log.levels.ERROR)
    return
  end

  Snacks.terminal.open(term_cmd, {
    auto_close = false,
    win = {
      style = 'split', -- Options: "float" (default), "split", or "tab"
      position = 'bottom', -- For "split" windows, specify position: "bottom" or "top"
      width = 80, -- Width of the terminal window (for "float" style)
      height = 20, -- Height of the terminal window (for "float" style)
      on_win = function(term) end,
    },
  })
end, { desc = 'Run editor' })

vim.keymap.set('n', '<leader>be', function()
  local fidget = require 'fidget'
  local job = require 'plenary.job'

  local function update_fidget(task, stdout, is_stderr)
    if is_stderr then
      -- vim.notify('STDERR: ' .. stdout, vim.log.levels.ERROR)
      return
    end
    local progress = string.match(stdout, 'Progress: (%d+%%)')
    if progress then
      local percentage = tonumber(progress:match '%d+')
      task:report { status = 'Building Sleipnir', message = 'Compiling Sleipnir...', percentage = percentage }
    end
  end

  -- Get current working directory
  local cwd = vim.fn.getcwd()

  -- Convert cwd to Windows path if in WSL2
  local win_cwd = cwd
  if is_wsl then
    win_cwd = vim.fn.substitute(cwd, '^/mnt/c', 'C:', 'g')
    win_cwd = vim.fn.substitute(win_cwd, '/', '\\\\', 'g')
  end

  -- Check if cwd matches sleipnir_path
  local expected_path = is_wsl and sleipnir_wsl_path or sleipnir_win_path
  if cwd ~= expected_path then
    -- vim.notify('Error: Wrong directory (for SleipnirEngine)', vim.log.levels.ERROR)
    return
  end

  local task = fidget.progress.handle.create {
    title = 'Building Sleipnir',
    message = 'Compiling shaders...',
    percentage = 0,
  }

  -- Save all files
  vim.cmd 'wa'

  -- Wait for shader compilation to complete with timeout
  local start_time = vim.loop.now()
  local timeout_ms = 10000 -- 10 seconds
  while vim.g.shader_compile_in_progress > 0 do
    if vim.loop.now() - start_time > timeout_ms then
      vim.notify('Timeout waiting for shader compilation. Counter: ' .. vim.g.shader_compile_in_progress, vim.log.levels.ERROR)
      vim.g.shader_compile_in_progress = 0
      break
    end
    vim.loop.sleep(100)
  end

  task:report { message = 'Shader compilation complete' }
  task:report { message = 'Compiling Sleipnir...', percentage = 0 }

  -- Build command (only build_editor.bat)
  local build_cmd
  if is_wsl then
    build_cmd = '/mnt/c/Windows/System32/cmd.exe /C "cd /d ' .. win_cwd .. ' && build_editor.bat"'
  else
    build_cmd = 'cd ' .. win_cwd .. ' && build_editor.bat'
  end

  -- Capture build output
  local build_output = {}

  job
    :new({
      command = 'bash',
      args = { '-c', build_cmd },
      cwd = cwd,
      env = {
        WSLENV = 'PWD/p',
      },
      on_stdout = function(_, data)
        table.insert(build_output, data)
        update_fidget(task, data, false)
      end,
      on_stderr = function(_, data)
        table.insert(build_output, 'STDERR: ' .. data)
        update_fidget(task, data, true)
      end,
      on_exit = function(_, exit_code, _)
        local is_success = exit_code == 0 or (exit_code == 127 and task.percentage == 100)
        vim.schedule(function()
          if not is_success then
            task:report { status = 'error', message = 'Build failed' }
            -- Create a terminal popup to display the captured output
            --
            output_scratch_log(build_output)

            -- vim.api.nvim_buf_set_keymap(term.buf, 'n', 'q', '<cmd>lua vim.api.nvim_win_close(' .. term.win .. ', true)<CR>', { noremap = true, silent = true })
            -- vim.api.nvim_buf_set_keymap(
            --   term.buf,
            --   't',
            --   '<Esc>',
            --   '<cmd>lua vim.api.nvim_win_close(' .. term.win .. ', true)<CR>',
            --   { noremap = true, silent = true }
            -- )
          else
            task:report { status = 'success', message = 'Build completed successfully' }
          end
          task:finish()
        end)
      end,
    })
    :start()
end, { desc = 'Build Sleipnir editor' })
