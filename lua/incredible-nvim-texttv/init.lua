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

local function getDivContent(html)
    local start_pos, end_start_tag = html:find('<div%s+class="%s*Content_screenreaderOnly%s*[^>]*>')
    local end_pos = html:find('</div>', end_start_tag)
    if start_pos and end_pos then
        return html:sub(end_start_tag + 1, end_pos - 1):gsub('\r\n', '\n')
    else
        return nil
    end
end

local function getBody(url)
    local html_content = fetchHtml(url)
    return getDivContent(html_content)
end

M = {}
function M.show_page(page_number)
    if not buf or not vim.api.nvim_buf_is_valid(buf) then
        vim.cmd('vsp')
        vim.cmd('enew')
        buf = vim.api.nvim_get_current_buf()
    end
    -- Default to 100
    if page_number == 0 then page_number = 100 end
    local div_content = getBody("https://www.svt.se/text-tv/" .. page_number)
    if div_content then
        vim.api.nvim_buf_set_lines(buf, 0, -3, false, vim.split(div_content, '\n'))
    else
        vim.api.nvim_buf_set_lines(buf, 0, -3, false, { "Sidan ej i sändning" })
    end
    -- Move the cursor to the top of the buffer
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
end

return M
