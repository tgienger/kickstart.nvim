return {
  'dawsers/file-history.nvim',
  config = function()
    local file_history = require 'file_history'
    file_history.setup {
      -- These are the default values, change them if needed
      -- Location where the plugin will create your file history repository
      backup_dir = '~/.file-history-git',
      -- command line to execute git
      git_cmd = 'git',
      -- If you want to override the automatic query for hostname, change this
      -- option. By default (nil), the plugin gets the host name for the computer
      -- it is running on.
      --
      -- You should only modify this value if you understand the following:
      -- This plugin writes a backup copy of every file you edit in neovim, not
      -- just your coding projects. When copying the file-history repository from
      -- one computer to another, having the hostname added to each file in the
      -- repo prevents you from messing the history of files that should be unique
      -- to that computer (host). For example, configuration and system files
      -- will probably be different in part or fully. So, even though it may
      -- make sense for coding projects to be able to move the database and
      -- disregard the host name, in many cases you will be editing other types
      -- of files, where keeping the correct host name will help you recover
      -- from mistakes.
      hostname = nil,
    }
    -- There are no default key maps, this is an example
    vim.keymap.set('n', '<leader>Bb', function()
      file_history.backup()
    end, { silent = true, desc = 'named backup for file' })
    vim.keymap.set('n', '<leader>Bh', function()
      file_history.history()
    end, { silent = true, desc = 'local history of file' })
    vim.keymap.set('n', '<leader>Bf', function()
      file_history.files()
    end, { silent = true, desc = 'local history files in repo' })
    vim.keymap.set('n', '<leader>Bq', function()
      file_history.query()
    end, { silent = true, desc = 'local history query' })
  end,
}
