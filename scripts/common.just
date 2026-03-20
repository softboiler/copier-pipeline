#* Variables
ci :=\
  env('CI', empty)
python_version :=\
  env('PYTHON_VERSION', empty)

#* Binaries
uv :=\
  if ci!=empty { 'uv' } else { './uv' }
uvx :=\
  if ci!=empty { 'uvx' } else { './uvx' }

#* Shell preamble
pre :=\
  script_pre + ';'
script_pre :=\
  '.' + sp + j
j :=\
  './j.ps1'

#* File extensions
sh_ext :=\
  if os_family()=='windows' { '.ps1' } else { '.sh' }
bin_ext :=\
  if os_family()=='windows' { '.exe' } else { empty }
cmd_ext :=\
  if os_family()=='windows' { '.cmd' } else { empty }

#* Explicit empty string used whenever `''` is intentional.
#? Empty strings are important for Just conditionals and coalescing operators like `||`
empty :=\
  ''

#* Single space
sp :=\
  ' '

#* Double quote. Use `quote(...)` instead for single-quotes
dquote :=\
  '"'

#* Messages
na :=\
  'not applicable for this OS.'

#* Used to represent a null result where Just would otherwise mishandle a ''
null :=\
  RED+'$null'+NORMAL

#* Certain functions return true/false
true :=\
  'true'
false :=\
  'false'
