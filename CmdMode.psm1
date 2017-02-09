function Enter-CmdMode
{
    $script:oldPSConsoleHostReadline = $function:global:PSConsoleHostReadline
    $script:oldTabExpansion2 = $function:global:TabExpansion2
    if(Get-Module PSReadline)
    {
        $script:oldPSReadlineOptions = Get-PSReadlineOptionsHashtable
        Set-PSReadlineOptionsForCmd
    }

    $function:global:PSConsoleHostReadline = 
        {
            $line = & $script:oldPSConsoleHostReadline
            switch($line)
            {
                "psmode" { "Enter-PSMode" }
                default  { Get-CmdWrappedCommand $line }
            }
        }
        
    $function:global:TabExpansion2 = 
        {
            [CmdletBinding(DefaultParameterSetName = 'ScriptInputSet')]
            Param(
                [Parameter(ParameterSetName = 'ScriptInputSet', Mandatory = $true, Position = 0)]
                [string] $inputScript,

                [Parameter(ParameterSetName = 'ScriptInputSet', Mandatory = $true, Position = 1)]
                [int] $cursorColumn,

                [Parameter(ParameterSetName = 'AstInputSet', Mandatory = $true, Position = 0)]
                [System.Management.Automation.Language.Ast] $ast,

                [Parameter(ParameterSetName = 'AstInputSet', Mandatory = $true, Position = 1)]
                [System.Management.Automation.Language.Token[]] $tokens,

                [Parameter(ParameterSetName = 'AstInputSet', Mandatory = $true, Position = 2)]
                [System.Management.Automation.Language.IScriptPosition] $positionOfCursor,

                [Parameter(ParameterSetName = 'ScriptInputSet', Position = 2)]
                [Parameter(ParameterSetName = 'AstInputSet', Position = 3)]
                [Hashtable] $options = $null
            )

            $results = & $script:oldTabExpansion2 @PSBoundParameters
            [System.Management.Automation.CompletionResult[]]$realMatches = @()
            foreach($result in $results.CompletionMatches)
            {
                $isRealMatch = $false;
                if($result.ResultType -eq [System.Management.Automation.CompletionResultType]::Command)
                {
                    if((Test-Path $result.ToolTip))
                    {
                        $isRealMatch = $true;
                    }
                }
                elseif($result.ResultType -eq [System.Management.Automation.CompletionResultType]::ProviderItem -or 
                    $result.ResultType -eq [System.Management.Automation.CompletionResultType]::ProviderContainer)
                {
                    try
                    {
                        $item = (Get-Item $result.ToolTip -Force -ErrorAction SilentlyContinue)
                        if($item.PSProvider.Name -eq "FileSystem")
                        {
                            $isRealMatch = $true
                        }
                    }
                    catch { }
                }

                if($isRealMatch)
                {
                    if($result.CompletionText.Substring(0,2) -eq "& ")
                    {
                        $result = New-Object System.Management.Automation.CompletionResult $result.CompletionText.Substring(2), $result.ListItemText, $result.ResultType, $result.ToolTip
                    }

                    if($result.CompletionText[0] -eq "'" -and $result.CompletionText[($result.CompletionText.Length)-1] -eq "'")
                    {
                        [string]$newCompletionText = $result.CompletionText.SubString(1,($result.CompletionText.Length)-2)
                        [string]$newCompletionText = Get-EscapedString $newCompletionText
                        [string]$newCompletionText = "`"$newCompletionText`""
                        $result = New-Object System.Management.Automation.CompletionResult $newCompletionText, $result.ListItemText, $result.ResultType, $result.ToolTip
                    }

                    $realMatches += $result
                }
            }

            if($realMatches.Count -eq 0)
            {
                $null
                return
            }

            $results.CompletionMatches = $realMatches
            $results
        }
}
Set-Alias cmdmode Enter-CmdMode

function Get-PSReadlineOptionsHashtable
{
    param(
        [Parameter(Mandatory=$false, Position=0)]
        [Microsoft.PowerShell.PSConsoleReadlineOptions]$psreadlineOptions = (Get-PSReadlineOption)
    )

    $psreadlineOptionsHash = @{}
    foreach($prop in $psreadlineOptions.psobject.Properties)
    {
        $psreadlineOptionsHash[$prop.Name] = $prop.Value
    }

    $psreadlineOptionsHash
}

function Set-PSReadlineOptionsForPS
{
    foreach($tk in "Comment","Keyword","Operator","Variable","Member")
    {
        Set-PSReadlineOption -TokenKind $tk -ForegroundColor $script:oldPSReadlineOptions["$($tk)ForegroundColor"].ToString()
        Set-PSReadlineOption -TokenKind $tk -BackgroundColor $script:oldPSReadlineOptions["$($tk)BackgroundColor"].ToString()
    }
}

function Set-PSReadlineOptionsForCmd
{
    $psreadlineOptions = Get-PSReadlineOption
    $defaultTokenForegroundColor = $psreadlineOptions.DefaultTokenForegroundColor.ToString()
    $defaultTokenBackgroundColor = $psreadlineOptions.DefaultTokenBackgroundColor.ToString()
    foreach($tk in "Comment","Keyword","Operator","Variable","Member")
    {
        Set-PSReadlineOption -TokenKind $tk -ForegroundColor $defaultTokenForegroundColor
        Set-PSReadlineOption -TokenKind $tk -BackgroundColor $defaultTokenBackgroundColor
    }
}

function Enter-PSMode
{
    $function:global:PSConsoleHostReadline = $script:oldPSConsoleHostReadline
    $function:global:TabExpansion2 = $script:oldTabExpansion2
    if(Get-Module PSReadline)
    {
        Set-PSReadlineOptionsForPS
    }
}

function Get-EscapedString
{
    param(
        [string]$str
    )

    #Note: Backtick must be first in this list
    [string[]]$specialChars = '`','"','$','@','[',']'

    foreach($specialChar in $specialChars)
    {
        [string]$str = $str -replace "\$specialChar","``$specialChar"
    }

    $str
}

function Get-CmdWrappedCommand
{
    param(
        [string]$line
    )

    [string]$line = $line -replace "`n"," "

    if([string]::IsNullOrWhiteSpace($line))
    {
        ""
        return
    }

    [string]$line = Get-EscapedString $line

    $wrappedCommand += "cmd /s /c `" $line & set > $($script:setOutTmpFile.FullName) & cd > $($script:cdOutTmpFile.FullName) `";"
    $wrappedCommand += "foreach(`$line in (Get-Content `"$($script:setOutTmpFile.FullName)`")){ `$spl = (`$line -split `"=`"); Set-Item -Path `"env:`$(`$spl[0])`" -Value `$spl[1] };"
    $wrappedCommand += "try{ Set-Location (Get-Content `"$($script:cdOutTmpFile.FullName)`") }catch{};"
    $wrappedCommand
}

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Remove-Item $script:setOutTmpFile
    Remove-Item $script:cdOutTmpFile
}

$script:oldPSConsoleHostReadline = $function:global:PSConsoleHostReadline
$script:oldTabExpansion2 = $function:global:TabExpansion2
$script:setOutTmpFile = New-TemporaryFile
$script:cdOutTmpFile = New-TemporaryFile

Export-ModuleMember -Function @("Enter-CmdMode","Enter-PSMode") -Alias @("cmdmode")
