# Java Runner

> This plugin started as part of my personal Neovim configuration that I used for a long time. After seeing interest from my friends. I decided to package it as a standalone plugin to make it easier for others to use and customize.

A Neovim plugin for running Java applications and tests directly from Neovim. This plugin aims to implement some of the functionality and UI features found in modern IDEs like IntelliJ.

## Features

- Run Java applications with main method detection
- Execute JUnit tests (single test or all tests in file)
- Support for Maven and Gradle projects
- Spring Boot application detection and execution
- Build tool wrapper support (mvnw, gradlew)
- Terminal integration with customizable size
- Visual indicators for runnable methods
- Automatic project structure detection

## Requirements

- Neovim >= 0.8.0
- Java Development Kit (JDK) installed and in PATH
- Maven and/or Gradle (optional - for build tool support)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "slobodanzivanovic/java-runner.nvim",
    config = function()
        require("java-runner").setup({
            -- opts
        })
    end,
}
```

## Configuration

Default configuration:

```lua
require("java-runner").setup({
    icons = {
        run = "",   -- icon for main method
        test = "", -- icon for test methods
    },
    terminal = {
        size = 10, -- terminal window height
    },
    keymaps = {
        run = "<leader>jr",      -- run main method
        test = "<leader>jt",     -- run test under cursor
        test_all = "<leader>je", -- run all tests in file
    },
})
```

By default, the plugin uses highlight groups linked to `Statement` for run icons and `Special` for test icons. You can override these colors in your configuration:

```lua
-- Optional: Override default colors
require("java-runner").setup({
    -- ... other config options
    colors = {
        run = "#00FF00",  -- custom color for run icon
        test = "#FF00FF", -- custom color for test icon
    },
})
```

## Usage

1. **Running Main Method**
   - Place cursor anywhere in a Java file with a main method
   - Press `<leader>jr` (or your configured keymap)
   - The application will run in a terminal window below

2. **Running Tests**
   - In a test file, place cursor on a test method
   - Press `<leader>jt` to run the test under cursor
   - Press `<leader>je` to run all tests in the file

## Commands

The plugin automatically sets up the following keymaps:

| Keymap         | Description                |
|----------------|----------------------------|
| `<leader>jr`   | Run Java main method      |
| `<leader>jt`   | Run test under cursor     |
| `<leader>je`   | Run all tests in file     |

## Project Detection

The plugin automatically detects:
- Project root directory (Maven/Gradle)
- Source root directory
- Package structure
- Spring Boot applications
- Test files and methods

## Screenshots

Here are some images showing the plugin in action:

![Java Runner 1](https://i.imgur.com/C3neUTD.png)
*Main Method Detection*

![Java Runner 2](https://i.imgur.com/S32gubm.png)
*Single Test Execution*