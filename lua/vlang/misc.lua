local misc = {}

misc.get_tmp_filename = function(path, prefix)
  local parts = vim.split(path, "/")
  local filename = { "/tmp/", parts[#parts], "", prefix } -- TODO: use current instance pid
  return table.concat(filename)
end

misc.get_buf_info = function()
  local pos = vim.fn.winsaveview()
  local winnr = vim.fn.winnr()
  return winnr, pos
end

misc.get_job_output = function(j)
  local results = j:result()
  local stderr = j:stderr_result()
  return vim.tbl_isempty(results) and stderr or results
end

misc.update_buffer = function(pos)
  vim.cmd("e")
  vim.fn.winrestview(pos)
  vim.cmd("cclose")
end

return misc
