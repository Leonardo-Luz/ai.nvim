# ai.nvim

*A Neovim plugin integrating Google Gemini AI for code fix, refactoring, and text generation.*

## Features

* **AI-powered text generation:**  Generate code, documentation, or any text based on prompts.
* **Code refactoring and fixing:**  Improve code quality with AI refactor.
* **Flexible interaction:**  Use commands, key mappings, or Lua functions.
* **Prompt interface:** Easily input prompts for text generation.
* **Contextual generation:** Generate text based on the current buffer's content or selection.

## Dependencies

* `leonardo-luz/dotenv`
* `leonardo-luz/floatwindow`
* `curl` (system package)

## Installation

1. **Set your API Key:** Obtain a Gemini API key and set the environment variable `GEMINI_API_KEY`.  There are two methods:

   * **Option 1:** Add this line to your shell configuration file (e.g., `~/.bashrc`, `~/.zshrc`):
     ```bash
     export GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
     ```

   * **Option 2:** Create a `.env` file in the same directory as your `init.lua` and add:
     ```env
     GEMINI_API_KEY=YOUR_GEMINI_API_KEY
     ```

2. **Install the plugin:** Add `leonardo-luz/ai.nvim` to your Neovim plugin manager (e.g., using packer.nvim, lazy.nvim, etc.):

   ```lua
   { "leonardo-luz/ai.nvim", opts = {
     ai = "gemini" -- deepseek option isn't avaliable yet
   } }
   ```

## Usage

**Commands:**

* `:Ai <arg>`: Generate AI text based on the provided argument.
* `:AiBuffer <arg>`: Generate AI text based on the provided argument and the current buffer's content.
* `:AiPrompt`: Open a prompt interface to input text for AI generation.
* `:AiBufferPrompt`: Open a prompt interface and generate text using user input and the current buffer's content or selection.

**Key Mappings (Example):**

Configure your leader key (`<leader>`) in your `init.lua` if needed (e.g., `let mapleader = " "`). Then add these mappings:

```lua
vim.keymap.set({ 'n', 'v' }, '<leader>ab', '<cmd>AiBufferPrompt<cr>', { desc = '[A]I [B]uffer Prompt' }),
vim.keymap.set('v', '<leader>ar', '<cmd>AiBufferRefactor<cr>', { desc = '[A]I Code [R]efactor' }),
```

**Lua Functions:**

```lua
local ai = require("ai")
local generated_text = ai.generate_text("Your prompt here")
print(generated_text)
```
