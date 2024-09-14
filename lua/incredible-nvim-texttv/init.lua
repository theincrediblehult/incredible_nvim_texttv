local html_parser = require('lua.incredible-nvim-texttv.html_parsing')
local buf = nil

local function fetchHtml(url)
  local command = 'curl -s "' .. url .. '"'
  local handle = io.popen(command)
  if not handle then
    return nil
  end
  local result = handle:read("*a")
  handle:close()
  return result
end

function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k, v in pairs(o) do
      if type(k) ~= 'number' then k = '"' .. k .. '"' end
      s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

local function getBody(url)
  local html_content = fetchHtml(url)
  return html_parser.get_content(html_content)
end

local link = 0;
local function onTab()
  link = html_parser.next_link()
end

M = {}
function M.show_page(page_number)
  print("Show page \n", page_number)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_get_current_buf()
    vim.keymap.set('n', '<Tab>', onTab)
    vim.keymap.set('n', '<CR>', function() M.show_page(link) end)
  end
  if page_number == 0 then page_number = 100 end
  local div_content = getBody("https://www.svt.se/text-tv/webb/" .. page_number)
  if div_content then
    vim.api.nvim_buf_set_lines(buf, 0, -3, false, vim.split(div_content, '\n'))
  else
    vim.api.nvim_buf_set_lines(buf, 0, -3, false, { "Sidan ej i sändning" })
  end
  -- Move the cursor to the top of the buffer
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
end

return M
