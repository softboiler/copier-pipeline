#* Settings
set unstable
set working-directory :=\
  '..'

#* Imports
import 'common.just'

#* Shells
set shell :=\
  ['pwsh', '-NonInteractive', '-NoProfile', '-CommandWithArgs']
set script-interpreter :=\
  ['pwsh', '-NonInteractive', '-NoProfile']
