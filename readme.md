## What
Application and infrastructure code to showcase web push notifications as described in https://www.rfc-editor.org/rfc/rfc8030 with the Azure Developer CLI.

## Note
### azure.yaml
- There is no host property in services specific for Azure CDN + storage account. Will use appservices on free tier for now.
https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/azd-schema

### docker logs
https://app-api-srct6mmq5nisy.scm.azurewebsites.net/api/logs/docker

### W3C standard
https://www.w3.org/TR/push-api/#:~:text=The%20push%20endpoint%20of%20a,encrypt%20and%20authenticate%20push%20messages


## TODO
- Create a schema
- Check with what these schema's are made https://github.com/Azure-Samples/todo-csharp-cosmos-sql/blob/main/OPTIONAL_FEATURES.md

## Issues
**ERROR: failed restoring service 'frontend': failing invoking action 'restore', failed to install project /Users/krisbulte/Playground/web-push/src/frontend: exit code: 2**

It will fail on an empty folder when the code is not added yet because the azure.yaml says it is of type js. It tries a to execute npm restore. Leave the service out of your azure.yaml until the code is added.
```
frontend:
    project: ./src/frontend
    dist: build
    language: js
    host: staticwebapp
```

**64 Bit worker processes cannot be used for the site as the plan does not allow it.**

A free plan is used for the AppService resources which can not use 64 bit worker processes. When providing an empty site config it automatically tries to use 64 bit worker processes. To solve this add a site config with the setting 'USE_32_BIT_WORKER_PROCESS' to 'true'.

**ERROR: getting target resource: resource not found: unable to find a resource tagged with 'azd-service-name: backend'.**
The service name in the azure.yaml file needs to match the value of the tag with name 'azd-service-name'