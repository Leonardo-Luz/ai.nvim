require("dotenv").load()

local fetch = require("http").fetch

local M = {}

local sanitized_prompt

local state = {
  ai = nil,
  API_KEY = nil,
  API_URL = nil,
  API_MODEL = nil,
  other_body = {},
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
--- @param prompt string -- User prompt
--- @param system string|nil -- A default prompt with rules for the system follow
--- @return string
M.generate_text = function(prompt, system)
  if state.API_KEY == nil then
    return "AI key not set properly"
  end
  if state.API_URL == nil then
    return "AI url not set properly"
  end

  sanitized_prompt = sanitizeString(prompt)

  local gemini_body = {
    contents = {
      { parts = { { text = sanitized_prompt } } },
    },
  }

  local deepseek_body = {
    model = "deepseek-chat",
    messages = {
      { role = "system", content = system or "Follow the user's instructions precisely." },
      { role = "user", content = sanitized_prompt },
    },
    stream = false,
  }

  local openrouter_body = {
    model = state.API_MODEL,
    messages = {
      { role = "system", content = system or "" },
      { role = "user", content = sanitized_prompt },
    },
  }

  local body = (
    ((state.ai and "gemini") and gemini_body)
    or ((state.ai and "deepseek") and deepseek_body)
    or ((state.ai and "other") and state.other_body)
    or ((state.ai and "openrouter") and openrouter_body)
  ) or {}

  local response = fetch(state.API_URL, {
    headers = {
      "Content-Type: application/json",
      ((state.ai and "gemini") and "x-goog-api-key: " .. state.API_KEY)
        or ((state.ai and "deepseek") and "Authorization: Bearer " .. state.API_KEY),
    },
    method = "POST",
    body = body,
  })

  if response.err then
    return response.err
  end

  local generated_text = response.response.candidates[1].content.parts[1].text or ""
  return generated_text
end

---setup ai plugin
---@param opts { ai:"gemini"|"deepseek"|"openrouter"|"other", model:string }
M.setup = function(opts)
  state.ai = opts.ai

  local GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
  local DEEPSEEK_API_URL = "https://api.deepseek.com/chat/completions"
  local OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions"
  local OTHER_API_URL = vim.env.OTHER_API_URL or os.getenv("OTHER_API_URL")

  local GEMINI_API_KEY = vim.env.GEMINI_API_KEY or os.getenv("GEMINI_API_KEY")
  local DEEPSEEK_API_KEY = vim.env.DEEPSEEK_API_KEY or os.getenv("DEEPSEEK_API_KEY")
  local OPENROUTER_API_KEY = vim.env.OPENROUTER_API_KEY or os.getenv("OPENROUTER_API_KEY")
  local OTHER_API_KEY = vim.env.OTHER_API_KEY or os.getenv("OTHER_API_KEY")

  state.API_MODEL = opts.model

  state.API_URL = ((opts.ai and "gemini") and GEMINI_API_URL)
    or ((opts.ai and "deepseek") and DEEPSEEK_API_URL)
    or ((opts.ai and "openrouter") and OPENROUTER_API_URL)
    or ((opts.ai and "other") and OTHER_API_URL)

  state.API_KEY = ((opts.ai and "gemini") and GEMINI_API_KEY)
    or ((opts.ai and "deepseek") and DEEPSEEK_API_KEY)
    or ((opts.ai and "openrouter") and OPENROUTER_API_KEY)
    or ((opts.ai and "other") and OTHER_API_KEY)
end

--- Takes user input
--- @param opts { args: string }
local function print_ai(opts)
  vim.print(M.generate_text(opts.args))
end

-- Create command
vim.api.nvim_create_user_command("Ai", print_ai, { nargs = 1 })

return M
