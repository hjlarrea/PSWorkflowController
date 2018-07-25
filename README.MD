# Introduction

# How to use

`.\Invoke-WorkflowController.ps1 -Start -WorkflowScript <workflowScript>`
Where `WorkflowScript` is the file containing the workflow and the call to the workflow, for example:

`workflow Test-Workflow {`

`    Do-Stuff`

`}`

` `

`Test-Workflow`

# Improvements (TODO)
- Logging, improved information delivery to the user
- Documentation in powershell format.
