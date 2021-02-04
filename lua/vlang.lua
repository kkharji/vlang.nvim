local M = {}
local misc = require'vlang.misc'
local qf = require'vlang.qf'
local run = require'vlang.runner'
local vtrue = function (num) return num == 1 end
local on_write = {
  check = (vim.g.vlang_nvim_check_on_write or 1) == 1,
  format = (vim.g.vlang_nvim_fmt_on_write or 1) == 1,
  compile = (vim.g.vlang_nvim_compile_on_write or 1) == 1
}

M.vet = function(cb)
  if type(cb) =="boolean" and cb == false then return end
  return run.job {
    args = { "vet", vim.fn.expand("%:p") },
    on_exit = function(lines, succ, winnr, _)
      if not vim.tbl_isempty(lines) then
        print("vlang.nvim: Found suspicious code constructs")
        qf.open(lines, winnr)
      end
      return cb and cb(vim.tbl_isempty(lines))
    end
  }
end

M.fmt = function(cb)
  if type(cb) == "boolean" and cb == false then return end
  return run.job {
    args = { "fmt", "-w", vim.fn.expand("%:p")},
    on_exit = function(lines, succ, winnr, pos)
      -- fmt return 0 regardless of errors, fixed in vlang/v@1e9ec6a
      succ = type(lines[1]:find("file:")) == "number"
      if not succ then
        print("vlang.nvim: failed to format file.")
        qf.open(lines, winnr)
      else
        misc.update_buffer(pos)
      end
      return cb and cb(succ)
    end,
  }
end

M.compile = function(cb)
  if type(cb) =="boolean" and cb == false then return end

  local path = vim.fn.expand("%:p")
  local tmp = misc.get_tmp_filename(path, "c")
  if vim.loop.fs_stat(tmp) ~= nil then vim.loop.fs_unlink(tmp) end
  return run.job {
    args = { "-o", tmp, path },
    on_exit = function(lines, succ, winnr, _)
      if not succ then
        print("vlang.nvim: Failed to compile")
        qf.open(lines, winnr)
      end
      compiled_file = tmp
      return cb and cb(succ)
    end
  }
end

M.run_file = function()
  return run.float {
    target = vim.fn.expand("%:p"),
    test = false,
  }
end

local vcompile = function(succ)
  if succ and on_write.compile then
    return M.compile()
  end
end

local vformat = function(succ)
  if succ and on_write.format then
    return M.fmt(vcompile)
  else
    return vcompile(succ)
  end
end

M.write_post = function()
  if on_write.check then
    return M.vet(vformat)
  elseif on_write.format then
    return M.fmt(vcompile)
  elseif on_write.compile then
    return vcompile(true)
  end
end

return M
