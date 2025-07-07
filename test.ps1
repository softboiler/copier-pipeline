$InstallationPolicy = Get-PSRepository 'PSGallery' |
    Select-Object -ExpandProperty 'InstallationPolicy'
try {
    Set-PSRepository 'PSGallery' -InstallationPolicy 'Trusted'
    Install-Module 'powershell-yaml'
}
finally {
    Set-PSRepository 'PSGallery' -InstallationPolicy $InstallationPolicy
}
