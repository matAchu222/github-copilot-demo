# Overview of scenario
## Opening statement
* Shows the end-to-end flow of a developer who sets up some CI in his IDE to facilitate local development, then continues to create IaC (Infrastructure as Code) to deploy the serverless function code and in the last step prepares a CD automation to get everything up and running.

## Repository state
- A basic structure of the repository is already there
- Some PowerShell scripts are already there to facilitate local development
- An application build on Azure Functions is already there

## What is missing
- More seamless integration of existing tooling is needed for higher code quality & speedy local development
- Infrastructure as Code is needed to deploy the application to Azure
- CI/CD pipeline needs to be created to orchestrate everything

## Your role and knowledge
- You are a developer who is familiar with Azure Functions, Python and PowerShell Core
- You know the basics of Terraform and understand pipelines, but used only Azure DevOps pipelines so far
- You are not familiar with Bash scripting or Git Hooks
- You already used a few times GitHub Copilot

# Demo steps
## Part 1:  CI / Scripting - Git Hooks / Powershell / Bash
###  Benefits to show
- Reduce friction and get started with new topics / development ideas faster
- Quickly create one of a kind scripts to automate repetitive tasks 
- Interactively exchange ideas with an AI pair programmer via chat feature
### Steps
1. Shortly show the existing repository structure, highlight the application and the scripts
2. Open Github Copilot Chat Window and ask the following question:
   - ```I have a few scripts to facilitate local development. How can I run them automatically before I commit code?```
3. Continue asking questions until Copilot suggests to use Git Hooks
4. Paste the following text into the Github Copilot chat window:
   - ```Create a pre-commit git hook, which runs "tools\scripts\powershell\dev_setup\Invoke-HandlerForCI.ps1" and provides any file which was modified within this commit via a parameter called $Files."```
5. Analyze the code and check, otherwise ask Copilot to add it
   - if it uses all modified files or if it accidentally filters to e.g. .ps1 files
      - ```Modify the pre-commit to use all modified files, not only specific file endings, e.g. .ps1```
      - ```The pre-commit should run for any file which was modified within this commit.```
   - if it is for Powershell Core (pwsh.exe)
     - ```Modify the pre-commit to use Powershell Core (pwsh.exe)```
6. Copy the generated code from the chat window into a new file pre-commit in the .git\hooks folder
7. Copilot should have suggested to run the following command to make the file executable:
8. Adjust two different file types, e.g. .ps1 and .py and commit the changes
9. Show the output of the pre-commit hook via the "Git" Output window in VS Code
10. Ask Copilot regarding how to distribute my git hooks to other developers
    - ```How can I distribute my git hooks to other developers?```
11. Create a new folder "git_hooks" under "tools\scripts\bash\" and copy the pre-commit file into it
12. Ask Copilot regarding how to create a script to install the git hooks
    - ```How can I create a pwsh script to install the git hooks which are located at "tools\scripts\bash\git_hooks"?```
    - ```The command shall be used in the readme.md and the devcontainer.json. What should I add in each?```
13. Add a minimalistic script to install the git hooks
    - Add to the readme.md
    - Add to the devcontainer.json

## Part 2: IaC - Terraform
### Benefits to show
- Automate the creation of IaC code, by reducing the time spent on documentation pages and tutorials
- Identify and fix errors in IaC code, which can be difficult to spot manually
- Suggest improvements to IaC code based on best practices and industry standards
### Steps
1. Open your file src\request_handler\function_app.py in editor
2. Ask Copilot
   - ```I have a function app which I want to deploy via terraform. How should I structure my terraform files?```
   - ```What kind of resources do I need in my main.tf?```
3. Create the files mentioned by Copilot, at least "main.tf", "variables.tf", "provider.tf" and "outputs.tf"
4. Go to provider.tf and 
   - ```# Load the Azure provider```
5. Go to variables.tf and paste the following comment at 
```
# Here are the variables that will be used in the Terraform scripts
# placeholder which is used in all names
# location which is used by all resources
```
6. Go to main.tf an paste the following comment at top
```
# This terraform file is used to create the resources in Azure
# The following resources are created:
# azurerm_resource_group: This resource creates an Azure resource group.
# azurerm_storage_account: This resource creates an Azure storage account.
# azurerm_service_plan: This resource creates an Azure App Service plan.
# azurerm_function_app: This resource creates an Azure Function App.
```
5. Dynamically create the main.tf with the help of Copilot
6. Use these info for Azure provider
```
provider "azurerm" {
  features {}
  subscription_id = "1231f5bc-0cfa-4268-aad2-0faa8cb5fbc3"
  client_id       = "020aba5f-f4f4-4ebe-9c50-c743eb86ef27"
  client_secret   = "a3n8Q~e6QHd-6fglK2UcMQeOFueobSwk0wHLUbx"
  tenant_id       = "9910f90d-4eb5-4b74-9c7c-24f0095fd87d"
}
```
6. Use the following Terraform commands to test you code
   - ```terraform init```
   - ```terraform plan```
   - ```terraform apply```

## Part 3: CD / Pipeline - Github Actions
### Benefits to show
- Quickly create complex CI/CD pipelines
- Receive help via chat for runtime errors in the pipeline or the command line
- Get suggestions for improvements to the pipeline
### Steps
1. 
2. 

