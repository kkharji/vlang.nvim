let g:vlang_nvim_check_on_write = get(g:, "vlang_check_on_write", 1)
let g:vlang_nvim_format_on_write = get(g:, "vlang_format_on_write", 1)
let g:vlang_nvim_compile_on_write =  get(g:, "vlang_compile_on_write", 1)

command! -buffer -bang -nargs=0 Vfmt lua require'vlang'.fmt()
command! -buffer -bang -nargs=0 Vtest lua require'vlang'.test()
command! -buffer -bang -nargs=0 Vrun lua require'vlang'.run_file()
command! -buffer -bang -nargs=0 Vvet lua require'vlang'.vet()

" TODO: fixme
nnoremap <Plug>VlangRunCurrent :lua require'vlang'.run_file()<CR>
nnoremap <Plug>VlangTesCurrent :lua require'vlang'.test()<CR>

if get(g:, "vlang_nvim_autocmds", 1) == 1
  augroup vlang_nvim
    au! * <buffer>
    autocmd BufWritePost <buffer> lua require'vlang'.write_post()
  augroup END
endif

if get(g:, "vlang_nvim_mappings", 1) == 1
  " nmap <buffer> <leader>ef <Plug>(VlangRunCurrent)
  " nmap <buffer> <leader>et <Plug>(VlangTestCurrent)
  nmap <buffer> <silent> <leader>ef :lua require'vlang'.run_file()<CR>
  nmap <buffer> <silent> <leader>et :lua require'vlang'.test()<CR>
endif

