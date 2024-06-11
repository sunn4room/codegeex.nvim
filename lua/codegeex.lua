local curl = require("plenary.curl")

local default_options = {
  timeout = 5000,
  highlight = "NonText",
  ft2lang = {
    text = "text",
    python = "Python",
    lua = "Lua",
    sh = "Shell",
    bash = "Shell",
    zsh = "Shell",
    fish = "Shell",
    cpp = "C++",
    c = "C",
    cs = "C#",
    css = "CSS",
    go = "Go",
    html = "HTML",
    java = "Java",
    javascript = "JavaScript",
    javascriptreact = "JavaScript",
    typescript = "TypeScript",
    typescriptreact = "TypeScript",
    objc = "Objective-C",
    php = "PHP",
    r = "R",
    rust = "Rust",
    sql = "SQL",
    tex = "TeX",
    vue = "vue",
    vb = "vb",
    json = "json",
    jsonc = "json",
    json5 = "json",
  },
}
local options = vim.deepcopy(default_options)
local ns = vim.api.nvim_create_namespace("codegeex")

local M = {}

M.setup = function(opts)
  options = vim.tbl_deep_extend("force", default_options, opts or {})
end

M.visible = function()
  local extmark = vim.api.nvim_buf_get_extmark_by_id(0, ns, 1, {})
  return #extmark ~= 0
end

M.complete = function()
  local ft = vim.opt_local.filetype:get()
  local lang = options.ft2lang[ft] or ft
  if #lang == 0 then lang = "text" end
  local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
  if #path == 0 then path = "untitled" end
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]
  local prefix = table.concat(
    vim.api.nvim_buf_get_text(0, 0, 0, row, col, {}),
    "\n"
  )
  local suffix = table.concat(
    vim.api.nvim_buf_get_text(0, row, col, -1, -1, {}),
    "\n"
  )
  local line_prefix = table.concat(
    vim.api.nvim_buf_get_text(0, row, 0, row, col, {}),
    ""
  )
  local line_suffix = table.concat(
    vim.api.nvim_buf_get_text(0, row, col, row, -1, {}),
    ""
  )
  vim.notify("CodegeeX completing ...", vim.log.levels.WARN)
  curl.post("https://codegeex.cn/prod/v3/completions/inline", {
    timeout = options.timeout,
    headers = {
      content_type = "application/json",
    },
    body = vim.fn.json_encode {
      context = { {
        kind = "active_document",
        active_document = {
          lang = lang,
          path = path,
          prefix = prefix,
          suffix = suffix,
        },
      } },
    },
    callback = vim.schedule_wrap(function(response)
      if response.exit ~= 0 then
        vim.notify("CodegeeX failed", vim.log.levels.ERROR)
        return
      end
      if response.status ~= 200 then
        vim.notify(
          "CodegeeX " .. tostring(response.status),
          vim.log.levels.ERROR
        )
        return
      end
      local text = vim.fn.json_decode(response.body).inline_completions[1].text
      local lines = {}
      for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        table.insert(lines, line)
      end
      lines[1] = line_prefix .. lines[1]
      lines[#lines] = lines[#lines] .. line_suffix
      local virt_lines = vim.tbl_map(function(line)
        return { { line, options.highlight } }
      end, lines)
      vim.api.nvim_buf_set_extmark(0, ns, row, col, {
        id = 1,
        virt_lines = virt_lines,
      })
      vim.notify("CodegeeX done")
    end),
  })
end

M.confirm = function()
  local extmark = vim.api.nvim_buf_get_extmark_by_id(
    0, ns, 1,
    { details = true }
  )
  if #extmark == 3 then
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row = cursor[1]
    local lines = vim.tbl_map(function(virt_line)
      return virt_line[1][1]
    end, extmark[3].virt_lines)
    local new_row = row + #lines - 1
    local new_col = #lines[#lines]
    vim.api.nvim_buf_set_lines(
      0,
      extmark[1],
      extmark[1] + 1,
      true,
      vim.tbl_map(function(virt_line)
        return virt_line[1][1]
      end, extmark[3].virt_lines)
    )
    vim.api.nvim_buf_del_extmark(0, ns, 1)
    vim.api.nvim_win_set_cursor(0, { new_row, new_col })
  end
end

M.cancel = function()
  local extmark = vim.api.nvim_buf_get_extmark_by_id(0, ns, 1, {})
  if #extmark ~= 0 then
    vim.api.nvim_buf_del_extmark(0, ns, 1)
  end
end

vim.api.nvim_create_autocmd("InsertLeave", {
  group = vim.api.nvim_create_augroup("codegeex_auto_cancel", {}),
  callback = function()
    M.cancel()
  end,
})

return M
