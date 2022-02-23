local run = {}
local compiled_file
local misc = require "vlang.misc"
local Job = require "plenary.job"
local log = require "plenary.log"
local F = require "plenary.functional"

-- TODO: change border, make center
local create_float = function(opts)
  local w = require("plenary.window.float").percentage_range_window(0.7, 0.65, opts.winopts)
  local a = vim.api
  a.nvim_buf_set_keymap(w.bufnr, "n", "q", ":q<CR>", {})
  a.nvim_buf_set_keymap(w.bufnr, "n", "sd", ":q<CR>", {})
  a.nvim_buf_set_option(w.bufnr, "filetype", "terminal")
  a.nvim_win_set_option(w.win_id, "winhl", "Normal:Normal")
  a.nvim_win_set_option(w.win_id, "conceallevel", 3)
  a.nvim_win_set_option(w.win_id, "concealcursor", "n")
  if w.border_win_id then
    a.nvim_win_set_option(w.border_win_id, "winhl", "Normal:Normal")
  end
  vim.cmd "mode"
  return w
end

local outputter = vim.schedule_wrap(function(bufnr, ...)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  for _, v in ipairs { ... } do
    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { v })
  end
end)

run._run_path = function(path, bufnr, istest, len, run_args)
  local args
  local stat = vim.loop.fs_stat(path)
  local cmd = "v" -- not sure if this would even work
  local subcommand = istest and "test" or "run"

  if stat and stat.type == "file" then
    local precomiled = compiled_file and compiled_file == misc.get_tmp_filename(vim.fn.expand "%:p", "c")
    path = precomiled and compiled_file or path
    cmd = precomiled and "sh" or "v" -- not sure if this would even work
    args = precomiled and { "./", compiled_file } or { subcommand, path }
  elseif stat and stat.type == "directory" then
    args = { subcommand, "." }
  end

  local out = function(_, data)
    if len == 1 then
      outputter(bufnr, data)
    end
  end

  local exit = vim.schedule_wrap(function(j_self, _, _)
    if len ~= 1 then
      outputter(bufnr, unpack(misc.get_job_output(j_self)))
    end
    vim.cmd "mode"
  end)

  return Job:new {
    command = cmd,
    args = vim.tbl_flatten { args, run_args },
    on_stdout = out,
    on_stderr = out,
    on_exit = exit,
  }
end

run.float = function(opts)
  -- print("Starting...")

  opts = vim.tbl_deep_extend("force", {
    winopts = {
      winblend = 3,
      percentage = 0.6,
    },
  }, opts or {})

  local float = create_float(opts)
  local paths = type(opts.target) == "string" and { opts.target } or opts.target
  local len = #paths

  for _, path in ipairs(paths) do
    outputter(float.bufnr, "Scheduling: " .. path)
  end

  local jobs = vim.tbl_map(function(path)
    return run._run_path(path, float.bufnr, opts.test, len, opts.run_args)
  end, paths)

  log.debug "Running..."

  for i, j in ipairs(jobs) do
    j:start()
    log.debug("... Completed job number", i)
  end

  return true
end

run.job = function(opts)
  opts = opts or {}
  local winnr, pos = misc.get_buf_info()
  return Job
    :new({
      command = "v",
      args = opts.args,
      on_exit = vim.schedule_wrap(function(j, c)
        local succ = c == 0
        local lines = misc.get_job_output(j)
        return opts.on_exit(lines, succ, winnr, pos)
      end),
    })
    :start()
end

return run
