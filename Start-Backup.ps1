function Start-Backup {
    [CmdletBinding()]

    param (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Sources = @("D:\Dropbox", "D:\Images", "D:\Recovery", "D:\Software", "D:\VM",
                     "E:\Battle.net", "E:\Galaxy", "E:\Origin", "E:\Steam", "E:\Uplay"),

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Target = "Backup"
    )

    function GetTargetDrive ($label) {
        $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Description -eq $label }
        if ($drives.Count -eq 1) {
            return $drives[0].Root
        } else {
            throw "Need exactly one drive called $label"
        }
    }

    function GetHostName {
        return (Get-Culture).TextInfo.ToTitleCase($env:COMPUTERNAME.ToLower())
    }

    function GetTargetLocation ($label) {
        return Join-Path (GetTargetDrive $label) (GetHostName)
    }

    function MustBeDir ($path) {
        if ((Get-Item $path) -is [System.IO.DirectoryInfo]) {
            return $path
        } else {
            throw "$path is not a directory"
        }
    }

    function NormalizeDriveLetter ($path) {
        return $path.Substring(0, 1).ToUpper() + $path.Substring(1)
    }

    function GetSources ($sources) {
        return $sources |
            Where-Object { Test-Path $_ } |
            ForEach-Object { MustBeDir $_ } |
            ForEach-Object { NormalizeDriveLetter $_ }
    }

    function ConvertToMap ($source, $targetLocation) {
        $to = Join-Path `
            (Join-Path $targetLocation $source[0]) `
            ([IO.Path]::GetFullPath($source)).Replace([IO.Path]::GetPathRoot($source), "")
        return @{
            from = $source
            to = $to
            log = $to + ".log"
        }
    }

    function GetMaps ($sources, $targetLocation) {
        return GetSources $sources | ForEach-Object { ConvertToMap $_ $targetLocation }
    }

    function StartTimer {
        return [Diagnostics.Stopwatch]::StartNew()
    }

    function StopTimer ($timer, $message) {
        $timer.Stop()
        Write-Host "$message in $($timer.Elapsed.ToString("mm\:ss\.fff"))" -ForegroundColor DarkGray
    }

    function Log ($map) {
        Write-Host "Mirror " -NoNewLine
        Write-Host $map.from -NoNewLine -ForegroundColor DarkCyan
        Write-Host " to " -NoNewLine
        Write-Host $map.to -ForegroundColor DarkCyan
    }

    function Prepare ($map) {
        if (Test-Path $map.to) { return }
        New-Item $map.to -ItemType Directory | Out-Null
    }

    function Mirror ($map) {
        robocopy $map.from $map.to /MIR /R:3 /W:5 /NP /NDL "/UNILOG:$($map.log)" | Out-Null
    }

    $allTime = StartTimer

    foreach ($map in (GetMaps $Sources (GetTargetLocation $Target))) {
        $time = StartTimer
        Log $map
        Prepare $map
        Mirror $map
        StopTimer $time "Done"
    }

    StopTimer $allTime "All done"
}

Set-Alias backup Start-Backup
