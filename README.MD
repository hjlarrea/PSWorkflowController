# Introduction

# How to use

To start a workflow under the SYSTEM context: `.\Invoke-WorkflowController.ps1 -Start -WorkflowScript <workflowScript> -Workflow <workflowName>`, where `WorkflowScript` is the ps1 file containing the workflow and the call to the workflow, for example:

`workflow Test-Workflow {`

    `Do-Stuff`

`}`

`Test-Workflow`

And `workflowName` would be the name of the workflow within the script (for the example case `Test-Workflow`). This is not mandatory, as the only purpose of this value is to be able to identify the workflow through the whole lifecycle (Start, Resume, Delete). Still it is highly recommended to use the name of the workflow itself as it will be the best reference possible.

To schedule a workflow to resume after a reboot under the SYSTEM context: `.\Invoke-WorkflowController.ps1 -ScheduleResume -Workflow <workflowName>`

To schedule a workflow to cleanup after the execution is compelted: `.\Invoke-WorkflowController.ps1 -ScheduleCleanup -Workflow <workflowName>`

# Improvements (TODO)
- Logging, improved information delivery to the user
- Documentation in powershell format.
