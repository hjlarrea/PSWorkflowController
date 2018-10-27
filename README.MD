[![Build Status](https://hjlarrea.visualstudio.com/PSWorkflowController/_apis/build/status/PSWorkflowController)](https://hjlarrea.visualstudio.com/PSWorkflowController/_build/latest?definitionId=1)

# Introduction

This script allows the administrator to execute PowerShell workflows under the context of SYSTEM.

For more information visit: [PowerShell Workflow Controller](http://hernanjlarrea.com/index.php/powershell-workflow-controller/)

# How to use

To start a workflow under the SYSTEM context: `.\Invoke-WorkflowController.ps1 -Start -WorkflowScript <workflowScript> -Workflow <workflowName>`, where `WorkflowScript` is the ps1 file containing the workflow and the call to the workflow, for example:

```powershell
workflow Test-Workflow {

    Do-Stuff

}

Test-Workflow
```

And `workflowName` would be the name of the workflow within the script (for the example case `Test-Workflow`). This is mandatory, as it is used to teack the workflow through the whole lifecycle (Start, Resume, Delete). Whomever or whatever triggers this action (Start) should be external to the workflow itself.

While resuming and garbage collecting should be executed from withing the workflow. Your workflow should include the following calls to the Workflow Controller when appropiate:

- To schedule a workflow to resume after a reboot under the SYSTEM context: `.\Invoke-WorkflowController.ps1 -ScheduleResume -Workflow <workflowName>`
- To schedule a workflow to cleanup after the execution is compelted: `.\Invoke-WorkflowController.ps1 -ScheduleCleanup -Workflow <workflowName>`

# Improvements (TODO)
- [ ] Logging, improved information delivery to the user
- [X] Documentation in powershell format.
- [ ] Write integration tests
