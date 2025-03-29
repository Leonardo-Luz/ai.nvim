-- Fetch the Google Gemini API key from environment variables
local M = {}

local GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
local GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"

--- Take a string and remove special characters
--- @deprecated
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
  if GEMINI_API_KEY == nil then
    return { generated_text = "GEMINI_API_KEY not properly set" }
  end

  local sanitized_prompt = sanitizeString(opts.prompt)

  local httpRequest = string.format(
    "curl -s '%s' --max-time 60 -H 'Content-Type: application/json' -H 'x-goog-api-key: %s' -X POST -d '{\"contents\": [{\"parts\": [{\"text\": \"%s\"}]}]}'",
    GEMINI_API_URL,
    GEMINI_API_KEY,
    sanitized_prompt
  )

  local handle = io.popen(httpRequest)
  if handle == nil then
    print("Error: Could not execute curl command.")
    return { generated_text = "curl execution failed" }
  end

  local data, err = handle:read("*a")
  handle:close()

  if err then
    print("Error reading curl response: " .. err)
    return { generated_text = "curl read failed" }
  end

  local decoded_data = vim.json.decode(data)
  if not decoded_data then
    print("Error decoding JSON response. " .. "\nResponse: " .. data)
    return { generated_text = "JSON decoding failed" }
  end

  if not decoded_data.candidates or #decoded_data.candidates == 0 then
    print("Error: Gemini API returned unexpected data: " .. vim.inspect(decoded_data))
    return { generated_text = "Unexpected API response" }
  end

  local generated_text = decoded_data.candidates[1].content.parts[1].text or ""
  return { generated_text = generated_text }
end

return M
