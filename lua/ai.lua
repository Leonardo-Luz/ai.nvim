require("dotenv").load()

local fetch = require("http").fetch

local M = {}

local state = {
  API_KEY = nil,
  API_URL = nil,
}

--- Take a string and remove special characters
--- @param input string
--- @return string: Sanitized string
local function sanitizeString(input)
  input = input:gsub("'", "")
  input = input:gsub('"', "")
  input = input:gsub("\\", "")
  input = input:gsub("\n", "")
  input = input:gsub("\r", "")
  input = input:gsub("%%", "")

  return input
end

--- Takes some text and use it as AI prompt
--- @param prompt string
--- @return string
M.generate_text = function(prompt)
  if state.API_KEY == nil then
    return "AI key not properly set"
  end

  local response = fetch(state.API_URL, {
    headers = {
      "Content-Type: application/json",
      "x-goog-api-key: " .. state.API_KEY,
    },
    method = "POST",
    body = {
      contents = {
        { parts = { { text = sanitizeString(prompt) } } },
      },
    },
  })

  if response.err then
    return response.err
  end

  local generated_text = response.response.candidates[1].content.parts[1].text or ""
  return generated_text
end

---setup ai plugin
---@param opts { ai:"gemini"|"deepseek" }
M.setup = function(opts)
  local GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
  local DEEPSEEK_API_URL = ""

  local GEMINI_API_KEY = vim.env.GEMINI_API_KEY or os.getenv("GEMINI_API_KEY")
  local DEEPSEEK_API_KEY = vim.env.DEEPSEEK_API_KEY or os.getenv("DEEPSEEK_API_KEY")

  state.API_URL = ((opts.ai and "gemini") and GEMINI_API_URL) or ((opts.ai and "deepseek") and DEEPSEEK_API_URL)
  state.API_KEY = ((opts.ai and "gemini") and GEMINI_API_KEY) or ((opts.ai and "deepseek") and DEEPSEEK_API_KEY)
end

--- Takes user input
--- @param opts { args: string }
local function print_ai(opts)
  vim.print(M.generate_text(opts.args))
end

-- Create command
vim.api.nvim_create_user_command("Ai", print_ai, { nargs = 1 })

return M
