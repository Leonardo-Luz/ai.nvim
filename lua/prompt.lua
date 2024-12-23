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

function Submit_basic_input()
  local buf = vim.api.nvim_get_current_buf()
  local input = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")

  local generated_text = textgen.generate_text({ prompt = input }).generated_text

  -- Optionally, close the window after submission
  vim.api.nvim_win_close(0, true) -- Close the current window

  floatwindow.create_floating_text_window({ state = state, text = generated_text })
end

local function handle_basic_input(buf)
  vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", "<Cmd>lua Submit_basic_input()<CR>", { noremap = true, silent = true })
end

local buf_text = nil

function Submit_buffer_input()
  local buf = vim.api.nvim_get_current_buf()
  local input = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")

  local prompt = string.format("%s %s", input, buf_text)

  local generated_text = textgen.generate_text({ prompt = prompt }).generated_text

  -- Optionally, close the window after submission
  vim.api.nvim_win_close(0, true) -- Close the current window

  floatwindow.create_floating_text_window({ state = state, text = generated_text })
end

local function handle_buffer_input(buf)
  local command = "<Cmd>lua Submit_buffer_input()<CR>"

  vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", command, { noremap = true, silent = true })
end

M.create_prompt = function()
  -- Get current window size
  local width = vim.api.nvim_win_get_width(0) -- Current window width
  local height = vim.api.nvim_win_get_height(0) -- Current window height

  -- Create a buffer for the input
  local buf = vim.api.nvim_create_buf(false, true) -- Create a new empty buffer

  -- Set up the floating window options
  local opts = {
    relative = "editor",
    width = math.floor(width * 0.5), -- Set the width of the window to 50% of the screen
    height = math.floor(height * 0.06), -- Set the height of the window to 20% of the screen
    col = math.floor((width * 0.5) / 2), -- Center the window horizontally
    row = math.floor((height * 0.5)), -- Center the window vertically
    style = "minimal", -- Remove borders, title, etc.
    border = "rounded",
    title = "- AI Prompt  ",
  }

  -- Open the floating window
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- You can also set a default prompt or text in the buffer
  -- vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'Write your question here...' })

  vim.api.nvim_buf_set_keymap(buf, "n", "<ESC><ESC>", "<Cmd>q<CR>", { noremap = true, silent = true })

  return { buf = buf, win = win }
end

local function toggle_prompt()
  local buf = M.create_prompt().buf
  handle_basic_input(buf)
end

local function toggle_buffer_prompt()
  buf_text = buffer.get_text_from_buffer().buffer_content

  local buf = M.create_prompt().buf
  handle_buffer_input(buf)
end

vim.api.nvim_create_user_command("GeminiPrompt", toggle_prompt, {})

vim.api.nvim_create_user_command("GeminiBufferPrompt", toggle_buffer_prompt, {})

vim.keymap.set({ "n", "v" }, "<leader>gb", toggle_buffer_prompt, { desc = "[G]emini [B]uffer Prompt" })

return M
