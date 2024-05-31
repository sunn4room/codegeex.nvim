# codegeex.nvim

Neovim plugin for CodegeeX v3

```lua
-- lazy.nvim spec
{
  "sunn4room/codegeex.nvim",
  -- url = "https://gitee.com/sunn4room/codegeex.nvim",
  keys = {
    {
      "<F1>",
      function()
        if require("codegeex").visible() then
          require("codegeex").confirm()
        else
          require("codegeex").complete()
        end
      end,
      mode = "i",
    },
    {
      "<F2>",
      function()
        require("codegeex").cancel()
      end,
      mode = "i",
    },
  },
  opts = {
    timeout = 5000, -- request timeout
    highlight = "NonText", -- highlight group for suggestions
    ft2lang = { -- filetype to lang for codegeex request
      python = "Python",
      -- ...
    },
  },
}
```
