Write-Output " Welcome to GO lang portable installation script"
Write-Output " Written by: Hasan A Yousef, Aug 2020"
Write-Output " =============================================="
Write-Output " GO lang SDK will be installed at C:\go\bin"
Write-Output " GO lang (GOPATH) will be set as 'Documents\GoWorkPlace'"
Write-Output ""

#Here is the installation function, at the bottom of the file are the check for update process
function InstallGo {
    param (
        $latest_version,
        $workDir
    )
        # The download location of the latest version zip file
        $file = 'go' + $latest_version + '.windows-amd64.zip'

        # set defaults
        $path = 'C:\go'
        $url = 'https://golang.org/dl/' + $file
        $dest = [io.path]::combine($Home, 'Downloads', $file)

        If(test-path $path)
        {
            $pathAll = $path + "*"
            Write-Output " Removing the currently installed Go from $path"
            Remove-Item $pathAll -recurse
        } else {
           # New-Item -ItemType Directory -Force -Path $path
           Write-Output " Creating the directory required for GO installation: $path"
           mkdir $path
        }
        # Download the zip file at the defined destination
        Write-Output " Downloading $url"
        #Invoke-WebRequest $url -OutFile $dest
        Write-Output " $url downloaded as $dest"

        # Unzip the file
        Write-Output " Extracting $file to $path"
        Expand-Archive -Force -Path $dest -DestinationPath $path\..
        Write-Output " Extraction completed, Adding GO SDK to path"
        # Add GO to the Path (if not exisiting)
        $addPath = 'C:\go\bin'
        # Iterate through all the existing paths to check if the new path is already included with or without a '\' on the end:
        $env = [Environment]::GetEnvironmentVariable("PATH",1)
        $regexAddPath = [regex]::Escape($addPath)
        $arrPath = $env -split ';' | Where-Object {$_ -notMatch "^$regexAddPath\\?"}
        $env = ($arrPath + $addPath) -join ';'
        [Environment]::SetEnvironmentVariable("PATH", $env, "USER")
        Write-Output " $addPath had been added to path."

        Write-Output " GO SDK is ready in the path, setting up Environment Variables"
        #Setting up variables
        # set the $GOROOT (Aka $GOBIN), GOROOT is a variable that defines where your Go SDK is located
        $goroot = Join-Path $path "bin"
        [Environment]::SetEnvironmentVariable( "GOROOT", $goroot, [System.EnvironmentVariableTarget]::User)
        # set the $GOPATH; GOPATH is a variable that defines the root of your workspace
        $gopath = Join-Path $Home $workDir
        [Environment]::SetEnvironmentVariable( "GOPATH", $gopath, [System.EnvironmentVariableTarget]::User)
        # Setup the Go workspace; if it doesn't exist.
        If (!(Test-Path $workDir)) {
            New-Item -path $workDir -type directory
            Write-Output " Go work space had been created: $gopath"
        } else {
            Write-Output " Go work space already exist: $gopath"
        }
        Write-Output " =============================================="
        Write-Output " GO is ready, Below you'll see list of GO command"
        go
  }

############################################################################
# Here is the check process, based on which the above function may be called.

$workDir = 'Documents\GoWorkPlace'
# Get latest Go lang version
# Parse the remote repository with ls-remote, and get release branches
# The regex matches refs/heads/release-branch.go, so rc and beta won't be mached
$release_branches=$(git ls-remote --heads https://github.com/golang/go/ | 
ConvertFrom-String | Where-Object {$_."P2" -Match 'refs/heads/release-branch.go'})

# Define utility for nat sort (see http://stackoverflow.com/a/5429048/2796058)
$ToNatural = { [regex]::Replace($_, '\d+', { $args[0].Value.PadLeft(20) }) }

# Extract actual tag versions, sort and get latest
$latest_version=$($release_branches.P2 | Select-String -Pattern '(\d+\.\d+)').Matches.Groups.Value |
 Sort-Object $ToNatural | Select-Object -Last 1

 Write-Output " Latest GO lang version is: $latest_version"

# Check installed version of GO lang 
$cmdName = 'go'
Try{
    Get-Command $cmdName -ErrorAction stop
    $goversioncheck = go version
    $goversion = [regex]::Match($goversioncheck, '((\d+\.\d+))').captures.groups[1].value

    if ($goversion -eq $latest_version) {
        Write-Output " You already have latest GO lang version installed, version: $goversion"
    } else {
        Write-Host " Upgrade Install of GO lang will start now"
        InstallGo -latest_version $latest_version -workDir $workDir
    }
  } Catch{
    Write-Host " Fresh Install of GO lang will start now"
    InstallGo -latest_version $latest_version -workDir $workDir
  }
