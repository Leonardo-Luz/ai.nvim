local ai = require("ai")

local M = {}

---Takes text from current selection and refactor it with AI
M.ai_code_refactor = function()
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
  local instruction = string.format(
    [[
You are a code improver that strictly follows these rules: Refactor the provided code in the specified file format (%s). Preserve functionality, comments, original formatting (indentation and line breaks), and approximate code size. Focus on improving efficiency, readability, and correctness. Output only the improved code **without using markdown code blocks or triple backticks**. Do not include any comments (except pre-existing ones) or explanations. Never enclose the improved code in a code block.
    ]],
    (file_extension:len() == 0 and ".lua") or file_extension
  )

  vim.print(instruction)

  local generated_text = nil
  local success, err = pcall(function()
    -- Call AI to generate text
    local result = ai.generate_text(selected_text, instruction)

    if result.error then
      vim.print(result.error)
      return
    end

    generated_text = result.response.candidates[1].content.parts[1].text or ""
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

  if lines[1]:match("^```*") then
    table.remove(lines, 1)
  end

  if lines[#lines]:match("^```*") then
    table.remove(lines, #lines)
  end

  -- Clear the selected text
  vim.api.nvim_buf_set_lines(buf, start_line - 1, end_line, false, {})

  -- Paste the generated text in place of the selection
  vim.api.nvim_buf_set_lines(buf, start_line - 1, start_line - 1, false, lines)

  -- Ensure the screen refreshes to show the changes
  vim.cmd("redraw")

  -- Exit visual mode
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
end

vim.api.nvim_create_user_command("AiBufferRefactor", M.ai_code_refactor, {})

return M
