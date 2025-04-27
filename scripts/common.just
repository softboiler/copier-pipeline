# * Versions
just_version :=\
  env('JUST_VERSION', empty)
python_version :=\
  env('PYTHON_VERSION', empty)
uv_version :=\
  env('UV_VERSION', empty)
ci :=\
  env('CI', empty)

# Binaries
_uv :=\
  if ci==empty { './uv' } else { 'uv' }
_uvx :=\
  if ci==empty { './uvx' } else { 'uvx' }
_just :=\
  _uvx + sp + '--from' + sp + quote(\
    'rust-just' + \
    if just_version==empty { empty } else { '@' + just_version } \
  ) \
  + sp + 'just' \

# * Reusable shell preamble
pwsh_pre := '.' + sp + 'scripts/pre.ps1'

# * File extensions
sh_ext :=\
  if os_family()=='windows' { '.ps1' } else { '.sh' }
bin_ext :=\
  if os_family()=='windows' { '.exe' } else { empty }
cmd_ext :=\
  if os_family()=='windows' { '.cmd' } else { empty }

# * Explicit empty string used whenever `''` is intentional.
# ? Empty strings are important for Just conditionals and coalescing operators like `||`
empty :=\
  ''

# * Single space
sp :=\
  ' '

# * Double quote. Use `quote(...)` instead for single-quotes
dquote :=\
  '"'

# * Messages
_na :=\
  'not applicable for this OS.'

# * Used to represent a null result where Just would otherwise mishandle a ''
null :=\
  RED+'$null'+NORMAL

# * Certain functions return true/false
true :=\
  'true'
false :=\
  'false'
