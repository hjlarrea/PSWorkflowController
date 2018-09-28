<#PSScriptInfo

.VERSION 1.0.1.0

.GUID db5f2e89-88da-46e8-a464-40e959dabc81

.AUTHOR Hernan J. Larrea (hjlarrea@hotmail.com)

.COMPANYNAME Hernan J. Larrea

.COPYRIGHT

.TAGS PowerShell WorkFlows SYSTEM Reboot Restart Resume

.LICENSEURI

.PROJECTURI https://www.hernanjlarrea.com/index.php/powershell-workflow-controller/

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

#>

<#
    .SYNOPSIS
    This script allows the administrator to execute PowerShell workflows under the context of SYSTEM.
    .DESCRIPTION
    Workflows provide a set of features to the administrator to resolve complex issues when automating
    complex tasks. Such as running parallel activities or recoverting jobs after a reboot. In the later
    case, resuming a job after a reboot can be challenging if the system where the workflow is running
    is the same system that initiated the workflow. This script allows the administrator to execute
    PowerShell workflows under the context of SYSTEM, giving the administrator the chance to 'teach' his
    workflows to resume themselves after a reboot by using the task scheduling capabilities of the operating
    system.
    .PARAMETER Start
    Used to start a workflow under the context of SYSTEM. Will instruct the Workflow Controller to create
    a scheduled task to invoke the workflow the Administrator has authored.
    .PARAMETER WorkflowScript
    Represents the absolute path to the script file that contains the workflow. The script should contain
    the definition of the workflow, and a call to the workflow itself (required by the Start operation).
    .PARAMETER ScheduleResume
    The Workflow Controller should be executed with this parameter as part of the workflow that's intended
    to be resumed right before the operation that might / will suspend the workflow execution.
    .PARAMETER Resume
    This parameter is alien to the Administrator. It is used for internal operations.
    .PARAMETER ScheduleCleanup
    The Workflow Controller should be executed with this parameter as part of the workflow that might have
    left breadcrumbs behind. The call to the Workflow Controller using this parameter should be one of the
    last actions that the workflow performs.
    .PARAMETER CleanUp
    This parameter is alien to the Administrator. It is used for internal operations.
    .PARAMETER Workflow
    This parameter is valid for all parameter sets. The value provided using this parameter
    is used to name all the scheduled tasks related to a given workflow and in the resume and
    cleanup activities to ensure tracebility across tasks and contexts.
    .EXAMPLE
    Invoke-PSWorkflowController -Start -WorkflowScript C:\MyDirectory\workflowscript.ps1 -Workflow Test-Workflow

    The initial execution should be external to the workflow itself. The administrator runs this line, and by doing
    so he is instructing the Workflow Controller to create a Scheduled Task, which will execute the PowerShell script
    specified under 'WorkfloScript' as SYSTEM.
    .EXAMPLE
    Invoke-PSWorkflowController -ScheduleResume -Workflow Test-Workflow

    This line should be used within your workflow (in this case Test-Workflow) right before rebooting the system.
    In essence the workflow is calling the workflow controller and instructing the workflow controller to schedule
    a secheduled task to be ran on next system start up and resume the workflow execution.
    .EXAMPLE
    Invoke-PSWorkflowController -Resume -Workflow Test-Workflow

    This operation is alien to the Administrator. Whenever the workflow executed the ScheduleResume operation
    a new scheduled task will be created instructing the Windows Scheduler to invoke the Workflow Controller
    with these parameters.
    .EXAMPLE
    Invoke-PSWorkflowController -ScheduleCleanup -Workflow Test-Workflow

    This line should be used within your workflow (in this case Test-Workflow) when you are ready to collect the
    garbage left behind. In essence the workflow is calling the workflow controller and instructing it to schedule
    a secheduled task to be ran immidiatly.
    .EXAMPLE
    Invoke-PSWorkflowController -CleanUp -Workflow Test-Workflow

    This operation is alien to the Administrator. Whenever the workflow executed the ScheduleCleanup operation
    a new scheduled task will be created instructing the Windows Scheduler to invoke the Workflow Controller
    with these parameters.
    .INPUTS
    N/A
    .OUTPUTS
    N/A
    .LINK
    Project website: https://www.hernanjlarrea.com/index.php/powershell-workflow-controller/
    GitHub repository: https://github.com/hjlarrea/PSWorkflowController
    PowerShell Gallery: https://www.powershellgallery.com/packages/Invoke-PSWorkflowController
#>
[cmdletbinding()]
param (
    [parameter (mandatory=$true,parameterSetName="Start")][Switch]$Start,
    [parameter (mandatory=$true,parameterSetName="Start")][String]$WorkflowScript,
    [parameter (mandatory=$true,parameterSetName="ScheduleResume")][Switch]$ScheduleResume,
    [parameter (mandatory=$true,parameterSetName="Resume")][Switch]$Resume,
    [parameter (mandatory=$true,parameterSetName="ScheduleCleanup")][Switch]$ScheduleCleanup,
    [parameter (mandatory=$true,parameterSetName="CleanUp")][Switch]$CleanUp,
    [parameter (mandatory=$true,parameterSetName="Start")]
    [parameter (mandatory=$true,parameterSetName="ScheduleResume")]
    [parameter (mandatory=$true,parameterSetName="Resume")]
    [parameter (mandatory=$true,parameterSetName="ScheduleCleanup")]
    [parameter (mandatory=$true,parameterSetName="CleanUp")][String]$Workflow
)

switch($True) {

    "$Start" {
        #Start Workflow
        #This acticity is to be consumed by the entity starting the workflow, in most of the cases this would be a user script

        #Create scheduled task
        $stAction=New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-File $WorkflowScript"
        $stSettings=New-ScheduledTaskSettingsSet
        Register-ScheduledTask -Action $stAction -TaskName "Start_$WorkFLow" -User System -RunLevel Highest -Settings $stSettings -ErrorAction SilentlyContinue | Out-Null

        #Execute scheduled task
        Start-ScheduledTask -TaskName "Start_$WorkFLow" -ErrorAction Stop | Out-Null
    }

    "$ScheduleResume" {
        #Schedule Workflow Resume
        #This activity is to be consume by the script implementing the workflow

        #Create scheduled task
        $stAction=New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-File $PSScriptRoot\Invoke-WorkflowController.ps1 -Resume -Workflow $Workflow"
        $stSettings=New-ScheduledTaskSettingsSet
        $stTrigger=New-ScheduledTaskTrigger -AtStartup -RandomDelay 00:05:00
        Register-ScheduledTask -Action $stAction -TaskName "Resume_$WorkFLow" -User System -RunLevel Highest -Settings $stSettings -Trigger $stTrigger -ErrorAction SilentlyContinue | Out-Null
    }

    "$Resume" {
        #Resume workflow jobs
        Get-Job -State Suspended | Where-Object -FilterScript { ($_.PSJobTypeName -eq "PSWorkflowJob") -and ( $_.Command -eq $Workflow) } | Resume-Job
        Start-Sleep -Seconds 14400 #Sleeps for 4 hours (idle time for the workflow to complete)
    }

    "$ScheduleCleanup" {
        #Schedule Workflow cleanup activities
        #This activity is to be consume by the script implementing the workflow

        #Create scheduled task
        $stAction=New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-File $PSScriptRoot\Invoke-WorkflowController.ps1 -Cleanup -Workflow $Workflow"
        $stSettings=New-ScheduledTaskSettingsSet
        Register-ScheduledTask -Action $stAction -TaskName "Cleanup_$WorkFLow" -User System -RunLevel Highest -Settings $stSettings -ErrorAction SilentlyContinue | Out-Null

        #Execute scheduled task
        Start-ScheduledTask -TaskName "Cleanup_$WorkFLow" -ErrorAction Stop | Out-Null
    }

    "$CleanUp" {
        #Cleanup workflow jobs
        Get-Job | Where-Object -FilterScript { ($_.PSJobTypeName -eq "PSWorkflowJob") -and ( $_.Command -eq $Workflow) } | Stop-Job
        Get-Job | Where-Object -FilterScript { ($_.PSJobTypeName -eq "PSWorkflowJob") -and ( $_.Command -eq $Workflow) } | Remove-Job
        Unregister-ScheduledTask -TaskName "Start_$Workflow" -Confirm:$false
        Unregister-ScheduledTask -TaskName "Resume_$Workflow" -Confirm:$false
        Unregister-ScheduledTask -TaskName "Cleanup_$Workflow" -Confirm:$false
    }

}
