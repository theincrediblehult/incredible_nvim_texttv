HtmlParsing = {}

local Links = {}

local function replace_substring(str, start_pos, end_pos, replacement)
  local before = str:sub(1, start_pos - 1)
  local after = str:sub(end_pos + 1)
  return before .. replacement .. after
end

local function calculate_position(content, pos)
  local row, col = 1, 0
  for i = 1, pos do
    local char = content:sub(i, i)
    if char == '\n' then
      row = row + 1
      col = 0
    else
      col = col + 1
    end
  end
  return { row, col }
end

local function dump(o)
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

local function process_anchors(content)
  local pattern = '<a href="%d+" title="Sidan (%d+)">%d+</a>'
  local start_pos, end_pos, href = content:find(pattern)
  SelectedLink = 0
  if start_pos then
    local position = calculate_position(content, start_pos)
    table.insert(Links, { row = position[1], col = position[2], href = href })
    content = replace_substring(content, start_pos, end_pos, href)
    return process_anchors(content)
  end
  return content
end

local function extract_body(html)
  local first_newline_pos = html:find("\n")
  local content_without_first_line = html:sub(first_newline_pos + 1):gsub("^%s+", "")

  local where_closing_div_is = content_without_first_line:find("</div")
  return content_without_first_line:sub(1, where_closing_div_is - 1)
end

local function extract_footer(html)
  local pattern = 'TextContent_footer__.....">'
  local start_index = html:find(pattern)
  if not start_index then return "" end
  local at_start = html:sub(start_index + #pattern)
  local end_index = at_start:find('</div>')
  local footer = at_start:sub(1, end_index - 1)
  return footer
end

local function extract_header(html)
  local pattern = 'TextContent_header__.....">'
  local start_index = html:find(pattern)
  if not start_index then return "" end
  local at_start = html:sub(start_index + #pattern)
  local end_index = at_start:find('</div>')
  local header = at_start:sub(1, end_index - 1)
  return header
end

function HtmlParsing.get_content(html)
  Links = {}
  local header = extract_header(html)
  local body = extract_body(html)
  local footer = extract_footer(html)
  local delim = '\n\n-------------------------------------\n'
  return process_anchors(header .. delim .. body .. delim .. footer)
end

function HtmlParsing.next_link()
  if #Links == 0 then return end
  local l = Links[SelectedLink + 1]
  SelectedLink = (SelectedLink + 1) % #Links
  vim.api.nvim_win_set_cursor(0, { l.row, l.col })
  return l.href
end

return HtmlParsing
