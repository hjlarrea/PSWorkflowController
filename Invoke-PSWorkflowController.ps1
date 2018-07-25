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