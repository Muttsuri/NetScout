# NetScout
A Poweshell script to get information about computers in your network

### Objective
To have an IT user be able to scan a pc by it's name and have the script ping and search for information about the pc in question.

### Infromation retieved
The scirpt retrieves information about the pc these are:
* Serial Number
* CPU Name
* Manufacturer
* Model
* Domain and Current loged on user
* RAM ( In GB )
* Disk Information

#### Notes
Like any PowerShell script it does require **ExecutionPolicy** to be set to **Unrestricted** with the command:
```powershell
Set-ExecutionPolicy Unrestriced
```
It can be set back with:
```powershell
Set-ExecutionPolicy Restricted
```

### To be done
* Turn the disk scanning part of the code into a self contained function. (DRY) 
* Convert _CleanPC.cmd_ to Powershell or introduce it into the script itself(depends on _CleanPC.cmd_'s author Nuno Almeida).
* Have the script not only ping for the computer but have it check if the computer active in the Active Directory (If possible)

##### Dreams
* Have this be converted to a C# program with GUI banking on the ability to call Powershell Scripts in C#
