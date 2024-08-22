-- Ensure package.path is correctly set for Neovim plugin directory
package.path = package.path .. ";./lua/incredible-nvim-texttv/?.lua"

-- Require JSON module (ensure `json_decode.lua` is correctly placed)
local JSON = require("json_decode")

-- Clear screen function for Neovim
local function clearScreen()
  -- vim.cmd("silent !clear") -- This works in terminal mode
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "" })
end

-- Function to move cursor to (x, y) position (not necessary for Neovim)
local function moveTo(x, y)
  -- You can use vim API for cursor positioning if needed
end

-- Validate page number
local function isValidNumber(pageNumber)
  local num = tonumber(pageNumber)
  return num and num >= 100 and num <= 999
end

-- Strip HTML-like tags from a string
local function stripTags(s)
  return s:gsub("<.->", "")
end

-- Render page content in Neovim
local function renderPage(pagedata)
  local firstPage = pagedata[1]
  local firstPageFirstContent = stripTags(firstPage.content[1])
  clearScreen()
  -- print(firstPageFirstContent) -- Print to Neovim buffer or use vim.api.nvim_out_write
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(firstPageFirstContent, "\n"))
end

-- Fetch page data from API and display it
local function fetchAndDisplayPage(pageNumber)
  local apiUrl = "http://api.texttv.nu/api/get/" .. pageNumber .. "?app=lokaltprogram"

  -- Use Neovim's system function to fetch the data
  local body = vim.fn.system('curl -s "' .. apiUrl .. '"')

  local pagedata, _, err = JSON:decode(body)
  if err then
    -- print("Error parsing the page data. Please try again.")
    vim.api.nvim_out_write("Error parsing the page data. Please try again.\n")
  elseif pagedata then
    renderPage(pagedata)
  else
    -- print("Error fetching the page. Please try again.")
    vim.api.nvim_out_write("Error fetching the page. Please try again.\n")
  end
end

-- Main function to handle user input and interactions
local function main()
  clearScreen()
  print([[ Ange nummer på sida att visa: (t.ex. 100 eller 377) ]])

  while true do
    local cmd = vim.fn.input("Ange nummer på sida att visa: ")
    cmd = cmd:gsub("%s+", "") -- Remove any whitespace

    if cmd == "q" then
      break
    elseif isValidNumber(cmd) then
      fetchAndDisplayPage(cmd)
    else
      print("Invalid page number. Please try again.")
    end
  end
end

-- main()
local function handleInput()
  vim.cmd("enew") -- Open a new buffer
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, "TextTV Interactive")
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile') -- Buffer won't be associated with a file
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'hide') -- Buffer is hidden
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)   -- Disable swapfile

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Enter page number (e.g., 100 or 377):" })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '<Cmd>lua require("incredible-nvim-texttv").exit()<CR>',
    { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>', '<Cmd>lua require("incredible-nvim-texttv").handle_command()<CR>',
    { noremap = true, silent = true })

  vim.cmd("startinsert")
end

local function exit()
  vim.cmd("bw") -- Close the buffer
end

local function handle_command()
  local buf = vim.api.nvim_get_current_buf()
  local cmd = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
  cmd = cmd:gsub("%s+", "") -- Remove any whitespace
  print(cmd)

  if cmd == "q" then
    exit()
  elseif isValidNumber(cmd) then
    fetchAndDisplayPage(cmd)
  else
    vim.api.nvim_buf_set_lines(buf, 1, -1, false, { "Invalid page number. Please try again." })
  end
end

-- Define your module
local M = {}

-- Utility function to clear the screen and set up the buffer
function M.start()
  -- Create a new buffer
  local buf = vim.api.nvim_create_buf(false, true) -- false: no swap file, true: scratch buffer (not listed)

  -- Create a new window for the buffer
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = 80,
    height = 20,
    col = 0,
    row = 0,
    anchor = 'NW',
    border = 'single',
  })

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile') -- buffer type is 'nofile'
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe') -- automatically delete buffer when hidden
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)   -- disable swapfile
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)  -- allow modifications for user input
  vim.api.nvim_buf_set_option(buf, 'readonly', false)   -- not readonly, allow input

  -- Set up fixed content
  local fixed_lines = {
    "Welcome to Text TV!",
    "",
    "Enter page number (e.g., 100 or 377):", -- Prompt for the user
    "",                                      -- Empty line to separate the input line
    "",                                      -- Empty line to separate the input line
    "",                                      -- Empty line to separate the input line
    "",                                      -- Empty line to separate the input line
    "",                                      -- Empty line to separate the input line
    "",                                      -- Empty line to separate the input line
    "",                                      -- Empty line to separate the input line
    "",                                      -- Empty line to separate the input line
    "",                                      -- Empty line to separate the input line
  }
  vim.api.nvim_buf_set_lines(buf, 0, #fixed_lines, false, fixed_lines)

  -- Set up the input line
  vim.api.nvim_buf_set_lines(buf, #fixed_lines, #fixed_lines + 1, false, { "" })
  vim.api.nvim_win_set_cursor(win, { #fixed_lines + 1, 0 }) -- Move cursor to input line

  -- Set up key mappings
  vim.api.nvim_buf_set_keymap(buf, 'i', '<CR>', '<Cmd>lua require("incredible-nvim-texttv").handle_command()<CR>',
    { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '<Cmd>lua require("incredible-nvim-texttv").exit()<CR>',
    { noremap = true, silent = true })

  -- Enter insert mode
  vim.cmd("startinsert")
end

-- Handle user input
function M.handle_command()
  local buf = vim.api.nvim_get_current_buf()

  -- Read the input line
  local input_line = vim.api.nvim_buf_get_lines(buf, 4, 5, false) -- Adjust line index as needed
  local cmd = input_line[1] or ""
  cmd = cmd:gsub("%s+", "")                                       -- Remove any whitespace

  if cmd == "q" then
    M.exit()
  elseif isValidNumber(cmd) then
    fetchAndDisplayPage(cmd)
  else
    -- Clear the input line and show an error message
    vim.api.nvim_buf_set_lines(buf, 4, 5, false, { "" }) -- Clear the input line
    vim.api.nvim_buf_set_lines(buf, 6, -1, false, { "Invalid page number. Please try again." })
  end

  -- Move cursor back to the input line
  vim.api.nvim_win_set_cursor(0, { 5, 0 }) -- Adjust line index to match the input line
end

-- Exit function
function M.exit()
  vim.cmd("bw") -- Close the buffer
end

-- Define isValidNumber and fetchAndDisplayPage for full functionality
-- Example: assuming these functions are defined elsewhere in your code
-- ...

return M
