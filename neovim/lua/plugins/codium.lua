-- lua/plugins/codeium.lua
return {
  {
    "Exafunction/codeium.nvim",
    cmd = "Codeium",
    event = "InsertEnter",
    build = ":Codeium Auth",
    opts = {
      -- virtual text (existing)
      virtual_text = {
        enabled = true, -- show inline suggestion as virtual text
        hl_group = "Comment", -- highlight group for ghost text
        prefix = "» ", -- visual prefix for ghost text
        key_bindings = {
          accept = false, -- leave accept to completion engine (nvim-cmp etc.)
          toggle = "<M-g>", -- toggle ghost text with Alt+g (change to your liking)
        },
      },

      -- optional extra guard settings (keeps behavior predictable)
      ghost = {
        enabled = true, -- a friendly name for enabling ghost behavior
        max_lines = 1, -- don't span too many lines
      },
    },

    config = function(_, opts)
      -- setup the plugin with the opts
      require("codeium").setup(opts)

      -- safe accept function exposed globally so mappings / other plugins can call it
      _G.ai_accept = function()
        local ok, vt = pcall(require, "codeium.virtual_text")
        if not ok or not vt then
          return false
        end

        if vt.get_current_completion_item and vt.get_current_completion_item() then
          local seq = vt.accept()
          if seq and #seq > 0 then
            seq = vim.api.nvim_replace_termcodes(seq, true, false, true)
            vim.api.nvim_feedkeys(seq, "i", true)
            return true
          end
        end

        return false
      end

      -- toggle function to enable/disable ghost text safely
      _G.ai_toggle_ghost = function()
        local ok, vt = pcall(require, "codeium.virtual_text")
        if not ok or not vt then
          -- fallback to main module if virtual_text module missing
          local ok2, main = pcall(require, "codeium")
          if ok2 and main and main.toggle_virtual_text then
            main.toggle_virtual_text()
          end
          return
        end

        if vt.is_enabled and vt.is_enabled() then
          if vt.disable then
            vt.disable()
          end
        else
          if vt.enable then
            vt.enable()
          end
        end
      end

      -- convenience user commands
      vim.api.nvim_create_user_command("CodeiumAccept", function()
        _G.ai_accept()
      end, {})
      vim.api.nvim_create_user_command("CodeiumToggleGhost", function()
        _G.ai_toggle_ghost()
      end, {})

      -- map Alt+g in insert mode to toggle ghost text (matches your original)
      pcall(function()
        vim.keymap.set("i", "<M-g>", function()
          _G.ai_toggle_ghost()
        end, { silent = true, desc = "Toggle Codeium ghost text" })
      end)
    end,
  },
}
