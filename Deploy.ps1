function SetOwner ($path, $user) {
    $acl = Get-Acl -LiteralPath $path
    $acl.SetOwner($user)
    Set-Acl -LiteralPath $path -AclObject $acl
}

function GetCurrentUser {
    return New-Object System.Security.Principal.NTAccount($env:USERNAME)
}

function SetOwnerToCurrentUser ($path) {
    SetOwner $path (GetCurrentUser)
}

function SetChildrenOwnerToCurrentUser ($path) {
    $user = GetCurrentUser
    foreach ($item in (Get-ChildItem $path -Recurse)) {
        SetOwner $item.FullName $user
    }
}

function Test7z {
    return !!(Get-Command "7z" -ErrorAction SilentlyContinue)
}

function Extract ($from, $to) {
    if (Test7z) {
        7z x $from -y -o"$to" | Out-Null
    } else {
        Expand-Archive $from $to
    }
}

function Pack ($from, $to) {
    if (Test7z) {
        7z a $to $from | Out-Null
    } else {
        Compress-Archive $from $to
    }
}

function CreateDir ($dir) {
    if (Test-Path $dir) { return }
    Write-Host "Create $dir"
    New-Item $dir -ItemType Directory | Out-Null
}

function CreateCopy ($from, $to, $isDir) {
    if ($isDir) {
        robocopy $from $to /NJH /NJS /NFL /NDL /E /COPY:DATO "/MT:$($env:NUMBER_OF_PROCESSORS / 2)" | Out-Null
    } else {
        xcopy $from ([IO.Path]::GetDirectoryName($to)) /YKHRQO | Out-Null
    }
}

function CreateSymlink ($symlink, $path, $isDir = $true) {
    if (Test-Path $symlink) { return }
    Write-Host "Symlink $symlink"
    if ($isDir) {
        New-Item -ItemType Junction -Path $symlink -Target $path | Out-Null
    } else {
        New-Item -ItemType SymbolicLink -Path $symlink -Target $path | Out-Null
    }
    SetOwnerToCurrentUser $symlink
}

function Remove ($path) {
    Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
}

function RemoveSymlink ($symlink) {
    Write-Host "Unlink $symLink"
    Remove $symlink
}

function DeployItems ($switches, $globals, $from, $to, $replace, $createSymlinks) {
    $isC = $to.StartsWith($globals.systemDrive)

    foreach ($itemFrom in Get-ChildItem $from -Force -ErrorAction SilentlyContinue) {
        $itemTo = Join-Path $to $itemFrom.Name
        $isDir = $itemFrom.Attributes.HasFlag([IO.FileAttributes]::Directory)

        if (($isC -and !$switches.skipC) -or (!$isC -and !$switches.skipD)) {
            if (!$switches.pack -and ($switches.remove -or $replace)) {
                Write-Host "Remove $itemTo"
                Remove $itemTo
            }

            if ($switches.pack) {
                Write-Host "Pack $itemTo to $($itemFrom.FullName)"
                Remove $itemFrom.FullName
                CreateCopy $itemTo $itemFrom.FullName $isDir
            }

            if (!$switches.remove -and !$switches.pack) {
                Write-Host "Create $itemTo"
                CreateDir $to
                CreateCopy $itemFrom.FullName $itemTo $isDir
            }
        }

        if (!$switches.skipC -and !$switches.pack -and $createSymlinks) {
            $symlink = Join-Path $globals.systemDrive $itemTo.TrimStart($globals.installDir)
            RemoveSymlink $symlink
            if (!$Remove) {
                CreateDir (Join-Path $globals.systemDrive $to.TrimStart($globals.installDir))
                CreateSymlink $symlink $itemTo $isDir
            }
        }
    }
}
