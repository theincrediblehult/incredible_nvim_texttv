describe("Html parser", function()
  local function read_html_file(html_file)
    local file = io.open("spec/html_files/" .. html_file, "r")
    if file then
      local content = file:read("*all")
      file:close()
      return content
    else
      print("Could not open the file!")
    end
    return nil
  end

  local function normalize_whitespace(str)
    return (str:gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1"))
  end

  local function get_content(html_file)
    local html = read_html_file(html_file)
    return require('lua.incredible-nvim-texttv.html_parsing').get_content(html)
  end

  local function verify_content(expected, html_file)
    local parsed_content = get_content(html_file)
    assert.are.same(normalize_whitespace(expected), normalize_whitespace(parsed_content))
  end

  it("successfully parses page_100.html", function()
    verify_content(
      [[100 SVT Text torsdag 05 sep 2024 ------------------------------------- Sverige fritt från afrikansk svinpest Har ansökt till EU om friskförklaring 106 Skattesänkning för löntagare och pensionärer i budget 109 Dömd ledare i Dödspatrullen frisläppt Överklagade morddom till Svea hovrätt 114 Isak bakom seger i NL-premiären - 300 Inrikes 101 Utrikes 104 Innehåll 700 -------------------------------------]],
      "page_100.html"
    )
  end)

  it("should find the links in footer in page_rain_east_europe.html", function()
    local vim_mock = spy.new(function() end)
    _G.vim = { api = { nvim_win_set_cursor = vim_mock } }

    local html = read_html_file("page_rain_east_europe.html")
    local html_parsing = require('lua.incredible-nvim-texttv.html_parsing')
    html_parsing.get_content(html)

    html_parsing.next_link()

    assert.spy(vim_mock).was_called_with(0, { 26, 12 })
  end)

  it("should find the links in page_100.html", function()
    local vim_mock = spy.new(function() end)
    _G.vim = { api = { nvim_win_set_cursor = vim_mock } }

    local html = read_html_file("page_100.html")
    local html_parsing = require('lua.incredible-nvim-texttv.html_parsing')
    html_parsing.get_content(html)

    html_parsing.next_link()

    assert.spy(vim_mock).was_called_with(0, { 7, 3 })
  end)

  it("should parse a single link from a simple HTML string", function()
    local vim_mock = spy.new(function() end)
    _G.vim = { api = { nvim_win_set_cursor = vim_mock } }

    local simple_html = [[
      <div>
        Nyheter nyheter <a href="123" title="Sidan 123">123</a> nyheter
      </div>
    ]]

    local html_parsing = require('lua.incredible-nvim-texttv.html_parsing')
    html_parsing.get_content(simple_html)

    local href = html_parsing.next_link()
    assert.are.equal("123", href)

    local href = html_parsing.next_link()
    assert.are.equal("123", href)

    local href = html_parsing.next_link()
    assert.are.equal("123", href)

    assert.spy(vim_mock).was_called_with(0, { 4, 17 })
  end)

  it("should process all links in page_100.html", function()
    local vim_mock = spy.new(function() end)
    _G.vim = { api = { nvim_win_set_cursor = vim_mock } }

    local html = read_html_file("page_100.html")
    local html_parsing = require('lua.incredible-nvim-texttv.html_parsing')
    html_parsing.get_content(html)

    local expected_links = {
      { row = 7,  col = 3,  href = "106" },
      { row = 10, col = 33, href = "109" },
      { row = 16, col = 3,  href = "114" },
      { row = 18, col = 38, href = "300" },
      { row = 20, col = 13, href = "101" },
      { row = 20, col = 25, href = "104" },
    }

    for i, expected in ipairs(expected_links) do
      local href = html_parsing.next_link()
      assert.are.equal(expected.href, href)
      assert.spy(vim_mock).was_called_with(0, { expected.row, expected.col })
    end
  end)
end)
