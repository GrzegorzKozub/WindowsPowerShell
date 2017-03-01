function Build-Vim {
    [CmdletBinding()]

    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateScript({ Test-Path $_ })]
        [string]
        $Path
    )

    Push-Location
    Set-Location $Path
    $cloneDir = "Build-Vim"

    if (Test-Path $cloneDir -PathType Container) {
        Set-Location $cloneDir
        git clean -fd
        git pull
    } else {
        git clone https://github.com/vim/vim.git $cloneDir
        Set-Location $cloneDir
    }

    $archivePath = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($PROFILE.CurrentUserAllHosts), "Build-Vim.zip")
    7z x -y $archivePath *.diff | Out-Null

    foreach ($patch in Get-ChildItem -Filter *.diff) {
        git apply $patch
    }

    Set-Location "src"
    7z x -y $archivePath | Out-Null

    foreach ($gui in "no", "yes") {
        mingw32-make -j2 -f make_ming.mak `
            FEATURES=HUGE MBYTE=yes IME=yes GIME=yes CSCOPE=yes GUI=$gui OLE=$gui DIRECTX=$gui `
            PYTHON3=c:/Apps/Python DYNAMIC_PYTHON3=yes PYTHON3_VER=35 `
            PERL=c:/Apps/Perl DYNAMIC_PERL=yes PERL_VER=524 `
            RUBY=c:/Apps/Ruby DYNAMIC_RUBY=yes RUBY_VER=23 RUBY_VER_LONG=2.3.0 `
            #LUA=c:/Apps/Lua DYNAMIC_LUA=yes LUA_VER=52
    }

    Copy-Item -Path "vim.exe", "gvim.exe", "vimrun.exe" -Destination $Path -Force
    Pop-Location
}

