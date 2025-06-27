#* Versions
python_version :=\
  env('PYTHON_VERSION', empty)
ci :=\
  if env('CI', empty)=='1' { true } else { false }

# Binaries
_uv :=\
  if ci==true { './uv' } else { 'uv' }
_uvx :=\
  if ci==true { './uvx' } else { 'uvx' }

#* Reusable shell preamble
pwsh_pre := '.' + sp + 'scripts/pre.ps1'

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
_na :=\
  'not applicable for this OS.'

#* Used to represent a null result where Just would otherwise mishandle a ''
null :=\
  RED+'$null'+NORMAL

#* Certain functions return true/false
true :=\
  'true'
false :=\
  'false'
