local floatwindow = require("floatwindow")
local textgen = require("textgen")
local buffer = require("buffer")

local M = {}

local state = {
  floating = {
    buf = -1,
    win = -1,
  },
}

---@type window.Opts[]
local window_style = {
  background = {
    floating = {
      buf = -1,
      win = -1,
    },
    opts = {},
  },
  header = {
    floating = {
      buf = -1,
      win = -1,
    },
    opts = {},
  },
  main = {
    floating = {
      buf = -1,
      win = -1,
    },
    opts = {},
  },
}

M.create_prompt = function()
  -- Get current window size
  local width = vim.api.nvim_win_get_width(0) -- Current window width
  local height = vim.api.nvim_win_get_height(0) -- Current window height

  local title = " AI Input "

  -- Set up the floating window options
  window_style.header.opts = {
    relative = "editor",
    width = string.len(title), -- Set the width of the window to 50% of the screen
    height = 1,
    col = math.floor((width * 0.5) / 2) + math.floor(width * 0.2), -- Center the window horizontally
    row = math.floor((height * 0.5)) - 0, -- Center the window vertically
    style = "minimal",
    zindex = 3,
    border = "none",
  }

  window_style.main.opts = {
    relative = "editor",
    width = math.floor(width * 0.4), -- Set the width of the window to 50% of the screen
    height = 1,
    col = math.floor((width * 0.5) / 2) + 3, -- Center the window horizontally
    row = math.floor((height * 0.5)) + 1, -- Center the window vertically
    style = "minimal",
    border = { " ", " ", " ", " ", " ", " ", " ", "" },
    zindex = 2,
  }

  window_style.background.opts = {
    relative = "editor",
    width = math.floor(width * 0.5), -- Set the width of the window to 50% of the screen
    height = 3,
    col = math.floor((width * 0.5) / 2), -- Center the window horizontally
    row = math.floor((height * 0.5)), -- Center the window vertically
    style = "minimal",
    border = "rounded",
    zindex = 1,
  }

  -- Create a buffer for the input
  window_style.header.floating.buf = vim.api.nvim_create_buf(false, true) -- Create a new empty buffer
  window_style.background.floating.buf = vim.api.nvim_create_buf(false, true) -- Create a new empty buffer
  window_style.main.floating.buf = vim.api.nvim_create_buf(false, true) -- Create a new empty buffer

  -- Open the floating window
  window_style.header.floating.win =
    vim.api.nvim_open_win(window_style.header.floating.buf, true, window_style.header.opts)

  window_style.background.floating.win =
    vim.api.nvim_open_win(window_style.background.floating.buf, true, window_style.background.opts)

  window_style.main.floating.win = vim.api.nvim_open_win(window_style.main.floating.buf, true, window_style.main.opts)

  vim.api.nvim_buf_set_lines(window_style.header.floating.buf, 0, -1, false, { title })

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(window_style.main.floating.win, true)
  end, {
    buffer = window_style.main.floating.buf,
  })

  vim.keymap.set("i", "<Esc>", function()
    vim.api.nvim_win_close(window_style.main.floating.win, true)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, true, true), "n", true)
  end, {
    buffer = window_style.main.floating.buf,
  })

  return { buf = window_style.main.floating.buf, win = window_style.main.floating.win }
end

local handle_input = function(buf, input)
  vim.keymap.set("i", "<CR>", function()
    local prompt = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")

    local generated_text = textgen.generate_text({ prompt = prompt .. (input or "") }).generated_text

    -- FIX: vim.o.lines/columns are getting the window size that is closing, so 0 of size
    local height = 40 --vim.o.lines
    local width = 160 --vim.o.columns

    ---@type vim.api.keyset.win_config
    local opts = {
      relative = "editor",
      style = "minimal",
      height = height * 0.8,
      width = width * 0.8,
      col = (width - width * 0.8) / 2,
      row = (height - height * 0.8) / 2,
      border = "rounded",
      zindex = 111,
    }

    local float = floatwindow.create_floating_window({ floating = state.floating, opts = opts })

    vim.bo[float.buf].filetype = "markdown"

    local lines = vim.split(generated_text, "\n")

    -- Clear the buffer first
    vim.api.nvim_buf_set_lines(float.buf, 0, -1, false, {})

    vim.api.nvim_buf_set_lines(float.buf, 0, #lines, false, lines)

    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, true, true), "n", true)

    vim.keymap.set("n", "<Esc><Esc>", function()
      vim.api.nvim_win_close(float.win, true)
    end, {
      buffer = float.buf,
    })
  end, {
    buffer = buf,
    silent = true,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = buf,
    callback = function()
      pcall(vim.api.nvim_win_close, window_style.main.floating.win, true)
      pcall(vim.api.nvim_win_close, window_style.header.floating.win, true)
      pcall(vim.api.nvim_win_close, window_style.background.floating.win, true)
    end,
  })
end

local function toggle_prompt()
  M.create_prompt()

  vim.cmd("startinsert")

  handle_input(window_style.main.floating.buf)
end

local function toggle_buffer_prompt()
  local buf_text = buffer.get_text_from_buffer()

  vim.cmd("startinsert")

  M.create_prompt()

  handle_input(window_style.main.floating.buf, buf_text)
end

vim.api.nvim_create_user_command("AiPrompt", toggle_prompt, {})

vim.api.nvim_create_user_command("AiBufferPrompt", toggle_buffer_prompt, {})

vim.keymap.set({ "n", "v" }, "<leader>ab", toggle_buffer_prompt, { desc = "[A]I [B]uffer Prompt" })

return M
