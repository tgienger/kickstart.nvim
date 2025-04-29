vim.api.nvim_create_user_command('MakeExecutable', function()
  vim.cmd '!chmod +x %'
end, {
  nargs = 0,
  bang = true,
})
