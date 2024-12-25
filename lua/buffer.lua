local textgen = require("textgen")
local floatwindow = require("floatwindow")

local M = {}

M.get_text_from_buffer = function()
  local mode = vim.fn.mode()
  local buffer = vim.api.nvim_get_current_buf()

  local text = {}
  local buffer_content = ""

  local regex = "[Vv]"

  if mode:find(regex) then
    local start_pos = vim.fn.getpos("v") -- Start of visual selection
    local end_pos = vim.fn.getpos(".") -- End of visual selection (cursor position)

    -- Ensure we have the correct positions (start <= end)
    local start_line = math.min(start_pos[2], end_pos[2])
    local end_line = math.max(start_pos[2], end_pos[2])

    -- Get the lines within the visual selection
    text = vim.api.nvim_buf_get_lines(buffer, start_line - 1, end_line, false)

    -- Join the selected lines into a single string
    buffer_content = table.concat(text, "\n")
  else
    -- If not in visual mode, get the entire buffer
    text = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    buffer_content = table.concat(text, "\n")
  end

  return { buffer_content = buffer_content }
end

local state = {
  floating = {
    buf = -1,
    win = -1,
  },
}

local function toggle_ai(opts)
  local buffer_content = M.get_text_from_buffer().buffer_content

  -- Generate text from the entire buffer or visual selection
  local generated_text = textgen.generate_text({ args = opts.args, prompt = buffer_content }).generated_text

  floatwindow.create_floating_text_window({ state = state, text = generated_text })
end

local function gemini_code()
  local buf = vim.api.nvim_get_current_buf()

  local start_pos = vim.fn.getpos("v") -- Start of visual selection
  local end_pos = vim.fn.getpos(".") -- End of visual selection (cursor position)

  -- Ensure we have the correct positions (start <= end)
  local start_line = math.min(start_pos[2], end_pos[2])
  local end_line = math.max(start_pos[2], end_pos[2])

  -- Get the lines within the visual selection
  local selected_lines = vim.api.nvim_buf_get_lines(buf, start_line - 1, end_line, false)

  local selected_text = table.concat(selected_lines, "\n")

  -- Get the file extension of the current buffer
  local file_extension = vim.fn.expand("%:e") -- Get the file extension (e.g., 'lua', 'py', 'js')

  -- AI prompt
  local prompt = string.format(
    [[Refactor and fix the provided code in the given file extension format. You are not allowed to generate markdown code blocks, comments, or explanations, keep the previous comments in the code if there's some. Focus solely on improving the codes efficiency, readability, and correctness while preserving its functionality. Ensure the output is clean and well-structured according to the syntax of the file extension. The code needs to stay with almost the same size, keeping its logic and basic structure. The file extension for this code is %s. Maintain the exact formatting for the code, including indentation and line breaks, without introducing any extraneous text or explanations. Do not add any markdown code block or add any comments. Just provide the improved code directly (with the previous comments on its places and lightly revised) in the appropriate format. THE CODE PROVIDED IS THIS: %s]],
    file_extension,
    selected_text
  )

  local generated_text = nil
  local success, err = pcall(function()
    -- Call AI to generate text
    local result = textgen.generate_text({ prompt = prompt })
    if not result then
      return
    end
    generated_text = result.generated_text
  end)

  if not success then
    print("Error generating text: " .. err)
    return
  end

  if not generated_text then
    return
  end

  -- Ensure generated text is a table with each line as a separate element
  local lines = vim.fn.split(generated_text, "\n")

  -- Clear the selected text
  vim.api.nvim_buf_set_lines(buf, start_line - 1, end_line, false, {})

  -- Paste the generated text in place of the selection
  vim.api.nvim_buf_set_lines(buf, start_line - 1, start_line - 1, false, lines)

  -- Ensure the screen refreshes to show the changes
  vim.cmd("redraw")

  -- Exit visual mode
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
end

vim.api.nvim_create_user_command("GeminiBuffer", toggle_ai, { nargs = 1 })

vim.keymap.set("v", "<leader>gc", gemini_code, { desc = "[G]emini [C]ode Fix", silent = false })

return M
