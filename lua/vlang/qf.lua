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

local get_issues = function(lines)
  local issues = {}
  local i = 0
  for _, line in ipairs(lines) do
    if line:match("^[^.]+.v:%d+:%d:%s.*") ~= nil then
      i = i + 1
      issues[i] = { line }
    else
      table.insert(issues[i], line)
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
  for _, issue in pairs(issues) do
    vim.fn.setqflist(issue, "a")
  end
  vim.cmd("copen")
  if winnr ~= vim.fn.winnr() then vim.cmd("wincmd p") end
end

return qf
