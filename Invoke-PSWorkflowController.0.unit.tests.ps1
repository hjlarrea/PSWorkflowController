$workflowScript="C:\Test\Workflow.ps1"
$workflowName="Test-Workflow"

Describe -Name "start workflow unit testing" {

    Mock -CommandName Register-ScheduledTask
    Mock -CommandName Start-ScheduledTask

    It -name "should create a scheduled task using the name of the worflow" {
        .\Invoke-PSWorkflowController.ps1 -Start -WorkflowScript $workflowScript -Workflow $workflowName
        Assert-MockCalled -CommandName Register-ScheduledTask -Scope "It" -Times 1 -ParameterFilter { $TaskName -eq "Start_$workflowName" }
        Assert-MockCalled -CommandName Register-ScheduledTask -Scope "It" -Times 1 -ParameterFilter { $User -eq "System" }
        Assert-MockCalled -CommandName Register-ScheduledTask -Scope "It" -Times 1 -ParameterFilter { $RunLevel -eq "Highest" }
    }

    It -name "should start the scheduled task named after the workflow" {
        .\Invoke-PSWorkflowController.ps1 -Start -WorkflowScript $workflowScript -Workflow $workflowName
        Assert-MockCalled -CommandName Start-ScheduledTask -Scope "It" -Times 1 -ParameterFilter { $TaskName -eq "Start_$workflowName" }
    }
}

Describe -Name "schedule workflow resume unit testing" {

    Mock -CommandName Register-ScheduledTask

    It -name "should schedule the workflow to be resumed on next start up" {
        .\Invoke-PSWorkflowController.ps1 -ScheduleResume -Workflow $workflowName
        Assert-MockCalled -CommandName Register-ScheduledTask -Scope "It" -Times 1 -ParameterFilter { $TaskName -eq "Resume_$workflowName" }
        Assert-MockCalled -CommandName Register-ScheduledTask -Scope "It" -Times 1 -ParameterFilter { $User -eq "System" }
        Assert-MockCalled -CommandName Register-ScheduledTask -Scope "It" -Times 1 -ParameterFilter { $RunLevel -eq "Highest" }
    }
}

Describe -Name "workflow resume unit testing" {

    Mock -CommandName Get-Job {
        $returnedObjects=@()

        1..5 | ForEach-Object {
            $job = New-Object -TypeName PSCustomObject
            $job | Add-Member -MemberType NoteProperty -Name id -Value $_
            $job | Add-Member -MemberType NoteProperty -Name name -Value "Job$($_)"
            $job | Add-Member -MemberType NoteProperty -Name PSJobTypeName -Value "PSWorkflowJob"
            $job | Add-Member -MemberType NoteProperty -Name State -Value  $(if($_ -eq 1 -or $_ -eq 2) { "Suspended" } else { "Completed" })
            $job | Add-Member -MemberType NoteProperty -Name Command -Value $(if($_ -eq 1 -or $_ -eq 2 ) { "Test-Workflow" } else { "Get-Command" })
            $returnedObjects+=$job
        }

        $returnedObjects

    }

    Mock -CommandName Resume-Job
    Mock -CommandName Start-Sleep

    It -name "should resume 2 out of 5 mocked scheduled tasks named after the workflow." {
        .\Invoke-PSWorkflowController.ps1 -Resume -Workflow $workflowName

        Assert-MockCalled -CommandName Resume-Job -Times 1 -Scope "It" -ParameterFilter { $id -eq 1 }
        Assert-MockCalled -CommandName Resume-Job -Times 1 -Scope "It" -ParameterFilter { $id -eq 2 }
    }
}

Describe -Name "workflow cleanup scheduling unit testing" {

    Mock -CommandName Register-ScheduledTask
    Mock -CommandName Start-ScheduledTask

    It -name "should schedule the workflow to be cleaned up and execute the cleanup" {
        .\Invoke-PSWorkflowController.ps1 -ScheduleCleanup -Workflow $workflowName
        Assert-MockCalled -CommandName Register-ScheduledTask -Scope "It" -Times 1 -ParameterFilter { $TaskName -eq "Cleanup_$workflowName" }
        Assert-MockCalled -CommandName Register-ScheduledTask -Scope "It" -Times 1 -ParameterFilter { $User -eq "System" }
        Assert-MockCalled -CommandName Register-ScheduledTask -Scope "It" -Times 1 -ParameterFilter { $RunLevel -eq "Highest" }
        Assert-MockCalled -CommandName Start-ScheduledTask -Scope "It" -Times 1 -ParameterFilter { $TaskName -eq "Cleanup_$workflowName" }
    }
}

Describe -Name "workflow cleanup execution unit testing" {

    Mock -CommandName Get-Job {
        $returnedObjects=@()

        1..5 | ForEach-Object {
            $job = New-Object -TypeName PSCustomObject
            $job | Add-Member -MemberType NoteProperty -Name id -Value $_
            $job | Add-Member -MemberType NoteProperty -Name name -Value "Job$($_)"
            $job | Add-Member -MemberType NoteProperty -Name PSJobTypeName -Value "PSWorkflowJob"
            $job | Add-Member -MemberType NoteProperty -Name State -Value  $(if($_ -eq 1 -or $_ -eq 2) { "Suspended" } else { "Completed" })
            $job | Add-Member -MemberType NoteProperty -Name Command -Value $(if($_ -eq 1 -or $_ -eq 2 ) { "Test-Workflow" } else { "Get-Command" })
            $returnedObjects+=$job
        }

        $returnedObjects

    }

    Mock -CommandName Stop-Job
    Mock -CommandName Remove-Job
    Mock -CommandName Unregister-ScheduledTask

    It -name "should execute the cleanup activities for 2 out of 5 mocked scheduled jobs" {
        .\Invoke-PSWorkflowController.ps1 -CleanUp -Workflow $workflowName

        Assert-MockCalled -CommandName Stop-Job -Times 2 -Scope "It"
        Assert-MockCalled -CommandName Remove-Job -Times 2 -Scope "It"
    }

    It -name "should remove any scheduled jobs related to the workflow" {
        .\Invoke-PSWorkflowController.ps1 -CleanUp -Workflow $workflowName

        Assert-MockCalled -CommandName Unregister-ScheduledTask -Times 1 -ParameterFilter { $TaskName -eq "Start_$WorkflowName" }
        Assert-MockCalled -CommandName Unregister-ScheduledTask -Times 1 -ParameterFilter { $TaskName -eq "Resume_$WorkflowName" }
        Assert-MockCalled -CommandName Unregister-ScheduledTask -Times 1 -ParameterFilter { $TaskName -eq "Cleanup_$WorkflowName" }
    }
}