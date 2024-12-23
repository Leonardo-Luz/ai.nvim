-- Fetch the Google Gemini API key from environment variables
local M = {}

local GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
local GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"

-- FIX: Change from delete to escape special chars
-- Change to http specif package

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

---@class generate.Opts
---@field prompt string

---@class generate.Text
---@field generated_text string

--- Takes some text and use it as AI prompt
--- @param opts generate.Opts
--- @return generate.Text
M.generate_text = function(opts)
  local prompt = string.format("%s", opts.prompt)

  -- Remove -s flag to enable curl logs
  local httpRequest = string.format(
    "curl -s '%s' -H 'Content-Type: application/json' -H 'x-goog-api-key: %s' -X POST -d '{\"contents\": [{\"parts\": [{\"text\": \"%s\"}]}]}'",
    GEMINI_API_URL,
    GEMINI_API_KEY,
    sanitizeString(prompt)
  )

  -- Make the HTTP request
  local response = io.popen(httpRequest)

  if not response then
    print("Response error")
    return {}
  end

  local data = response:read("all")
  local decoded_data = vim.json.decode(data)
  local generated_text = decoded_data.candidates[1].content.parts[1].text

  return { generated_text = generated_text }
end

--- @class print.Opts
--- @field args string

--- Takes user input
--- @param opts print.Opts
local function print_ai(opts)
  print(M.generate_text({ prompt = opts.args }).generated_text)
end

-- FIX: CHANGE CODE FROM Gemini to ?

-- Create command
vim.api.nvim_create_user_command("Gemini", print_ai, { nargs = 1 })

return M
