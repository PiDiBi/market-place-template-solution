# market-place-template-solution
Create VM for transfer image from other storage and create VM from this image.
This tempalte solution is ready for Azure Market Place (AMP)

## files
1. Deploy-AzureResourceGroup.ps1 - edit parmeters inside or pass them - for testing deployment
* copy files from Scripts and Templates directory to _publish directory
* copy files frim _publish directory to storage specified - this storage must have public read access 
2. mainTemplate.json
3. mainTemplate.parameters.json - contains passwords, user names, storage name, vnet config, etc. - not needed for AMP but needed for testing
4. createUiDefinition.json - UI definition for AMP
5. vnet-[new|existing].json - subtemplate for vnet creation 
6. storageAccount-[new|existing].json - not used - was problem with prevalidating of custom etension - tried to use non created storage, if creating started in subtemplate
 