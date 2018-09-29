$scriptToAnalyze=".\Invoke-PSWorkflowController.ps1"
$scriptName="Invoke-PSWorkflowController"

Describe -Name "reposiroty structure tests"{
    It -name "Should have a README.MD file" {
        "README.MD" | Should exist
    }

    try {
        $ScriptFileInfo = Test-ScriptFileInfo -Path $scriptToAnalyze -ErrorAction Stop
    } catch {
        $ScriptFileInfo = "TestFailed"
    }
    It -name "Should meet PowerShell Gallery Requirements" {
        $ScriptFileInfo | Should -Not -Be "TestFailed"
    }

    try {
        $scriptInGallery=Find-Script -Name $scriptName -ErrorAction Stop -WarningAction Stop
    } catch {
        if($error[0].Exception.Message.Contains("No match was found for the specified search criteria and script name")) {
            $scriptInGallery=$null
        } else {
            $scriptInGallery="Gallery failed"
        }
    }
    if($null -ne $scriptInGallery -and $scriptInGallery -ne "Gallery failed") {
        It -name "Should be owned by me" {
            $scriptInGallery.Author | Should -Be $ScriptFileInfo.Author
        }
    } else {
        It -name "Should not have another script in the gallery named the same" {
            $scriptInGallery | Should -BeNullOrEmpty
        }
    }

    It -name "Script Analyzer should not produce any recommendations" {
        Invoke-ScriptAnalyzer -Path $scriptToAnalyze -IncludeRule @('PSUseApprovedVerbs',
            'PSReservedCmdletChar',
            'PSReservedParams',
            'PSShouldProcess',
            'PSUseShouldProcessForStateChangingFunctions',
            'PSUseSingularNouns',
            'PSMissingModuleManifestField',
            'PSAvoidDefaultValueSwitchParameter',
            'PSAvoidUsingCmdletAliases',
            'PSAvoidUsingWMICmdlet',
            'PSAvoidUsingEmptyCatchBlock',
            'PSUseCmdletCorrectly',
            'PSUseShouldProcessForStateChangingFunctions',
            'PSAvoidUsingPositionalParameters',
            'PSAvoidGlobalVars',
            'PSUseDeclaredVarsMoreThanAssignments',
            'PSAvoidUsingInvokeExpression',
            'PSAvoidUsingPlainTextForPassword',
            'PSAvoidUsingComputerNameHardcoded',
            'PSUsePSCredentialType',
            'PSDSC*' ) | Should -BeNullorEmpty
    }
}

Describe -Name "documentation (comment based help) tests" {
    It -name  "Should contain start for the Help block <#" {
        Get-Content -Path $scriptToAnalyze | Should -Contain '<#'
    }

    It -name "Should contain a SYNOPSIS section" {
        Get-Content -Path $scriptToAnalyze | Should -Contain '    .SYNOPSIS'
    }

    It -name "Should contain a DESCRIPTION section" {
        Get-Content -Path $scriptToAnalyze | Should -Contain '    .DESCRIPTION'
    }

    $bindings=@("Verbose","Debug","ErrorAction","WarningAction","InformationAction","ErrorVariable","WarningVariable","InformationVariable","OutVariable","OutBuffer","PipelineVariable")
    $parameters=(Get-Command -Name $scriptToAnalyze | Select-Object -ExpandProperty Parameters).Keys | Where-Object { $_ -notin $bindings }
    foreach ($parameter in $parameters) {
        It -name "Should contain PARAMETER $parameter section" {
            Get-Content -Path $scriptToAnalyze | Should -Contain "    .PARAMETER $parameter"
        }
    }

    It -name "Should contain at least 1 example" {
        Get-Content -Path $scriptToAnalyze | Should -Contain '    .EXAMPLE'
    }

    It -name "Should contain a LINK section" {
        Get-Content -Path $scriptToAnalyze | Should -Contain '    .LINK'
    }

    It -name "Should contain an INPUTS section" {
        Get-Content -Path $scriptToAnalyze | Should -Contain '    .INPUTS'
    }

    It -name "Should contain an OUTPUTS section" {
        Get-Content -Path $scriptToAnalyze | Should -Contain '    .OUTPUTS'
    }

    It -name  "Should contain closure for the Help block #>" {
        Get-Content -Path $scriptToAnalyze | Should -Contain '#>'
    }
}