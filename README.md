## ai.nvim [WIP]

*A Neovim plugin that integrates Google's Gemini AI for text generation.*

**Features:**

* Reusable text generation function.
* Code fixing and refactoring capabilities.

**Dependencies:**

* `leonardo-luz/floatwindow`
* `curl` (system package)

**Installation:**

1. **Set your API key:** Add your Gemini API key to your environment variables.  For Ubuntu, add the following line to your shell configuration (e.g., `~/.bashrc` or `~/.zshrc`):

```bash
export GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
```

2. **Plugin Installation:** Add `leonardo-luz/ai.nvim` to your Neovim plugin manager (e.g., in your `init.lua` or `plugins/ai.lua`):

```lua
{
  'leonardo-luz/ai.nvim'
}
```

**Usage:**

*The plugin provides commands and key mappings for AI-assisted text generation:*

**Commands:**

* `:Ai <arg>`: Generate AI text based on the provided argument.
* `:AiBuffer <arg>`: Generate AI text based on the provided argument and the current buffer's content.
* `:AiPrompt`: Open a prompt interface to input text for AI generation.
* `:AiBufferPrompt`: Open a prompt interface and generate text with the user input and the current buffer's content or selection.

**Key Mappings:**

*Configure `<leader>` in your `init.lua` if needed.*

* `<leader>ab`:  Executes `:AiBufferPrompt`.
* `<leader>ar`: Refactors and fixes the currently selected code.
