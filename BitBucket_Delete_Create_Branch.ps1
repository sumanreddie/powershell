### this function will invoke git.exe
Function RunProcess(
    [string]$procPath,
    [string]$procArgs,
    [string]$procWorkingDir)
{
	$pinfo = New-Object System.Diagnostics.ProcessStartInfo
	#$pinfo.FileName = $procPath
    $pinfo.FileName = "C:\Program Files\Git\bin\git.exe"
	$pinfo.RedirectStandardError = $true
	$pinfo.RedirectStandardOutput = $true
	$pinfo.UseShellExecute = $false
	$pinfo.Arguments = $procArgs
	$pinfo.WorkingDirectory  = $procWorkingDir

	try {
		$p = New-Object System.Diagnostics.Process
		$p.StartInfo = $pinfo
        #Write-Host "Debug info staring info with arguments $procArgs and $procPath"
		$p.Start() | Out-Null
		if ($p.StandardOutput -ne $null) {
			$stdout = $p.StandardOutput.ReadToEnd()
		}
		if ($p.StandardError -ne $null) {
			$stderr = $p.StandardError.ReadToEnd()
		}
		$p.WaitForExit()
		$exitCode = $p.ExitCode

		if ($exitCode -eq 0) {
			$success = $true
			Write-Host "Done running git.exe as a process and the Result is Success."
		}
		else {
			$success = $false
			
			Write-Host "StdErr for process: $stderr"
			Write-Host "StdOut for process: $stdout"
			
			Write-Error "Done running git.exe as a process. Result Error, exitcode $exitCode."
		}
	}
	catch {
		Write-Host ("##vso[task.complete result=Failed;]ERROR")
		Write-Error $_.Exception.Message		
		Write-Error "Exception encountered!"

		Throw $_
		Exit 1
	}
	Write-Host "StdOut for process: $stdout"
	Write-Host "ExitCode: $exitCode"
	Return $stdout
}

### this script will delete branch
Function DeleteBranch(
	$RepoFolderpath,
	#$PBC_PAT,
	$Reponame,
	$BranchToDelete
)
{
	Write-Host "-----------------------------------------------------"
	Write-Host "Deleteion of Localbranch for $Reponame Repository: Started" -ForegroundColor Cyan
	Write-Host "-----------------------------------------------------"
    Write-Host "Repofolder path is $RepoFolderpath"
    if(!(Test-Path -Path "$RepoFolderpath\$Reponame" -PathType Container))
    {
        new-item -type directory -path "$RepoFolderpath\$Reponame"
		Write-Host "$RepoFolderpath\$Reponame"
    }
        cd "$RepoFolderpath\$Reponame"
		Write-Host "$RepoFolderpath\$Reponame"
	
	$Reponame= [uri]::EscapeDataString("$Reponame")
    $RepoURL = "https://sathish2029:5TaJJ2RvxPEwcE2vRUVF@bitbucket.org/sathish2029/$Reponame.git"
	Write-Host "Repo URL is $RepoURL"
    RunProcess -procPath $git -procArgs "clone $RepoURL -v" -procWorkingDir "$RepoFolderpath"
    RunProcess -procPath $git -procArgs "fetch" -procWorkingDir "$RepoFolderpath\$Reponame"
    RunProcess -procPath $git -procArgs "status" -procWorkingDir "$RepoFolderpath\$Reponame"
    RunProcess -procPath $git -procArgs "checkout" -procWorkingDir "$RepoFolderpath\$Reponame"
    RunProcess -procPath $git -procArgs "push origin --delete $BranchToDelete" -procWorkingDir "$RepoFolderpath\$Reponame"

	Write-Host "Deleted $BranchToDelete from $Reponame Repository:Completed"
}

DeleteBranch -RepoFolderPath "C:\Apps\Code\Test" -Reponame "testproject" -BranchToDelete "Test1"

### this script will create branch
Function CreateNewBranch(
[string]$newbranch,
[string]$RepoFolderpath,
#[string]$PBC_PAT,
[string]$Reponame,
[string]$DefaultBranch)
{
    # Create a local branch 
	Write-Host "-----------------------------------------------------"
	Write-Host "Creation of Localbranch for $Reponame Repo: Started" -ForegroundColor Cyan
	Write-Host "-----------------------------------------------------"
	Write-Host "Repofolder path is $RepoFolderpath"
    if(!(Test-Path -Path"$RepoFolderpath\$Reponame" -PathType Container))
    {
        new-item -type directory -path "$RepoFolderpath\$Reponame"
		Write-Host "$RepoFolderpath\$Reponame"
    }
        cd "$RepoFolderpath\$Reponame"
		Write-Host "$RepoFolderpath\$Reponame"
    
    ###################### Running git clone by calling the function ##########################
    $Reponame= [uri]::EscapeDataString("$Reponame")
    $RepoURL = "https://sathish2029:5TaJJ2RvxPEwcE2vRUVF@bitbucket.org/sathish2029/$Reponame.git"
    Write-Host "Repo URL is $RepoURL"
    RunProcess -procPath $git -procArgs "clone $RepoURL -b $DefaultBranch -v" -procWorkingDir "$RepoFolderpath"
    Write-Host "Git Clone activity of $Reponame -- $DefaultBranch branch to $RepoFolderpath is Successfull....."
    RunProcess -procPath $git -procArgs "fetch" -procWorkingDir "$RepoFolderpath\$Reponame"
    RunProcess -procPath $git -procArgs "status" -procWorkingDir "$RepoFolderpath\$Reponame"
    RunProcess -procPath $git -procArgs "checkout -b $NewBranch" -procWorkingDir "$RepoFolderpath\$Reponame"
    Write-Host "Local branch $NewBranch created" 
    
    # Save token in local .git config file
    RunProcess -procPath $git -procArgs "remote set-url origin $RepoURL" -procWorkingDir "$RepoFolderpath\$Reponame"
    Write-Host "Remote URL changed" 
}

### this script will push branch to repo
Function PushBranch(
[string]$newbranch,
[string]$RepoFolderpath,
#[string]$PBC_PAT,
[string]$Reponame
)
{
    cd "$RepoFolderpath\$Reponame"
    $Reponame= [uri]::EscapeDataString("$Reponame")
    $RepoURL = "https://sathish2029:5TaJJ2RvxPEwcE2vRUVF@bitbucket.org/sathish2029/$Reponame.git"
    Write-Host "Repo URL is $RepoURL"
    
    RunProcess -procPath $git -procArgs "status -v" -procWorkingDir "$RepoFolderpath\$Reponame"
    RunProcess -procPath $git -procArgs "add . -v" -procWorkingDir "$RepoFolderpath\$Reponame"

    RunProcess -procPath $git -procArgs "remote set-url --push origin $RepoURL" -procWorkingDir "$RepoFolderpath\$Reponame"
    Write-Host "Remote Push-URL changed poinig to $NewBranch branch"
    # Push the branch upstream
    RunProcess -procPath $git -procArgs "push --set-upstream origin $NewBranch" -procWorkingDir "$RepoFolderpath\$Reponame"
    Write-Host "Remote branch $NewBranch pushed into $Reponame Repository with the changes" 
}

CreateNewBranch -newbranch "Test3" -RepoFolderpath "C:\Apps\Code\Test" -Reponame "testproject" -DefaultBranch "main"
PushBranch -newbranch "Test3" -RepoFolderpath "C:\Apps\Code\Test" -Reponame "testproject"








