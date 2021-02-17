local qf = {}

local get_preview = function(items, lines)
  local numlen
  for _, line in ipairs(lines) do
    if line ~= "" and line:find("|") then
      line = line:gsub('%s+', ' ')

      local num = line:match("[0-9]+ |")
      if num then
        numlen = num:len()
      else
        local ws = {}
        for i=1, numlen do ws[i] = " " end
        line = table.concat(ws) .. line:gsub("(%s)|", "" .. "|")
      end

      table.insert(items, { text = line })
    end
  end
  return items
end

local format_issue = function(lines)
  local items = {}
  local info = vim.split(lines[1], ":")
  local lnum, col = info[2], info[3]

  lines[1], info[1], info[2], info[3] = "", nil,nil,nil

  items = {
    [1] = {
      filename = vim.fn.expand("%"),
      lnum = lnum,
      col = col,
      text = table.concat(vim.tbl_flatten(info), ":")
    }
  }
  return get_preview(items, lines)
end

-- Things that skiped the qf and returned empty qf
local bs = {
  "Cannot save output binary in a .v file.",
  "redefinition of function `C.dup2`",
  "/path/vlangplay/gh_notify/gh_notify.v:158: error: Looks like you are using spaces for indentation.",
  "cgen error: could not generate string method void_str for type 'void'",
  "/gh/daemon/main.v:26: warning: A function name is missing from the documentation of pub fn daemonize(pidpath string, run fn ())",
  "/v/vlib/builtin/cfns.c.v:410:1: conflicting declaration: fn C.dup2(oldfd int, newfd int) int",
  "/tmp/v/main.vc.12284744985678515411.tmp.c: In function ‘main__Daemon_stop’:",
  "/tmp/v/main.vc.12284744985678515411.tmp.c:11678:3: error: too few arguments to function ‘kill’"
}

local get_issues = function(lines)
  local issues = {}
  local matcher = "^[^.]+.v:%d+:%d+:%s.*"
  local i = 0
  for _, line in ipairs(lines) do
    if line:match(matcher) ~= nil then
      i = i + 1
      issues[i] = { line }
    else
      if issues[i] == nil then
        vim.fn.writefile(vim.tbl_flatten({
          "Content:", vim.tbl_flatten(lines)
        }), "/tmp/vlang_errors.log", "a")
        print("issues[i] is nil")
      end
      if issues[i] then
        table.insert(issues[i], line)
      end
    end
  end

  local res = {}
  for _, issue in pairs(issues) do
    table.insert(res, format_issue(issue))
  end

  return res
end

qf.open = function(lines, winnr)
  vim.fn.setqflist({}, "r")
  local issues = get_issues(lines)
  if type(issues) == "number" then return end
  for _, issue in pairs(issues) do
    vim.fn.setqflist(issue, "a")
  end
  vim.cmd("copen")
  if winnr ~= vim.fn.winnr() then vim.cmd("wincmd p") end
end

return qf
