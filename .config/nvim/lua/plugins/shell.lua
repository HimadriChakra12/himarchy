-- pwsh
vim.opt.shell = "powershell.exe"
vim.opt.shellcmdflag = "-NoLogo -ExecutionPolicy Bypass -Command"
vim.opt.shellredir = ">%s 2>&1"
vim.opt.shellpipe = "| pwsh.exe -NoLogo -ExecutionPolicy Bypass -Command"
vim.opt.shellquote = "\""
vim.opt.shellxquote = "\""
