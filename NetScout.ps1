<#   
.SYNOPSIS   
<Estre script foi criado para encontrar o IPV4, Marca, Modelo , RAM, CPU, Numero de Serie, Utilizador Corrente e Estatísticas de Disco, de uma maquina através do seu nome. 
Também limpará o disco de ficheiros de lixo caso o utilizador o considere necessário>  
.DESCRIPTION 
<O Script através do nome da maquina irá pingar a maquina e depois irá recolher a informação da maquina e depois apresenta-a. A informação que este Script dará é:  
O nome do utilizador ligado na altura da verificação.  
O Nome do Fabricante.  
O Modelo da Maquina.  
O IPV4  
O Nome do CPU  
O Nome do Sistema Operativo  
O Numero de Serie  
O Utilizador Currente  
O Tamanho dos discos C e D  
O Espaço Ocupado dos discos C e D  
O Espaço Livre dos discos C e D 
Após isso ele dará ao utilizador a escolha de correr uma função de limpeza baseada num script por Nuno Almeida>  
.PARAMETER <Nome do PC>  
.INPUTS  
<Nome do pc que será perguntado pelo script. Este script não tem argumentos>  
.OUTPUTS  
<Output aparece na consola:   
   IPv4  
   Numero de Serie  
   Nome do CPU  
   Nome do Sistema Operativo  
   Fabricante  
   Modelo  
   Utilizador currente  
   RAM  
   Tamanho de C e D  
   Espaço Ocupado e Livre de C e D>  
.NOTES  
Version: 3  
Author: <João Aelxandre Garica Correia>  
Creation Date: <15/04/2017>  
Purpose/Change: Network Scouting and Remote Disk Cleaning 
#>  
 
function RDiskCleanCmd #disk cleaning script
{ cmd.exe /c "C:\Windows\System32\CleanPC.cmd" 
#second scan of disks and compatrison with the first
$diskscan = Get-WmiObject Win32_logicaldisk -ComputerName $pcname
foreach ($dskobj in $diskscan) {  
if ($dskobj.VolumeName -eq $null ) {}  
else {Write-Host $dskobj.deviceid 
$max2 = [math]::round($dskobj.Size/1024/1024/1024, 0)        
$free2 = [math]::round($dskobj.FreeSpace/1024/1024/1024, 0)         
$full2 = $max2 - $free2    
Write-Host "Espaço Total em Disco"$dskobj.deviceid":" $max2 "GB"   
Write-Host "Espaço Ocupado em Disco"$dskobj.deviceid":" $full2 "GB"   
Write-Host "Espaço Livre em Disco"$dskobj.deviceid":" $free2 "GB"   
Write-Host
foreach ($diskitem in $diskspace) {
$dif = $free2 - $free 
Write-Host $dskitem.deviceid
Write-Host "Recovered Space"$dif "GB"}
 }} #end of disk info
}#end disk cleaning script

function main { #core of the script
While (!$pcname){      
$pcname = Read-Host -Prompt "Insira o nome do pc para obter informaão"}   
   
$contest = Test-Connection -ComputerName $pcname -count 1 -Quiet #ver se está ligado 
if ($contest -eq 1 ) {   
$iv4 = Test-Connection -ComputerName $pcname -count 1 -ErrorAction Stop| select-object IPV4Address # IPv4  
Write-Host "IPv4: "$iv4.Ipv4address   
Write-Host   } 
if ($contest -eq 1 ) {       
Try { 
$colItems = Get-wmiobject -ErrorAction Stop -class Win32_ComputerSystem -namespace "root\CIMV2" -computername $pcname     
$osname = Get-WmiObject -ComputerName $pcname -Class Win32_OperatingSystem | Select-Object caption  #sistema operativo 
$cpuname = Get-WmiObject Win32_processor -ComputerName $pcname | Select-Object name #CPU   
$serial = Get-WmiObject win32_bios -ComputerName $pcname | Select-Object SerialNumber  #numero de serie 
Write-Host "Numero de Serie:" $serial.SerialNumber   
Write-Host "CPU: " $cpuname.name    
Write-Host "OS: " $osname.caption  
   
foreach ($objItem in $colItems){  #PC iinfo   
Write-Host "Fabricante: " $objItem.Manufacturer #Nome de Fabricante     
write-host "Modelo: " $objItem.Model #Nome de Modelo     
Write-Host "Username: " $objItem.UserName #username     
$displayGB = [math]::round($objItem.TotalPhysicalMemory/1024/1024/1024, 0) #Formatação do output da quantidade de RAM para GB     
write-host "RAM: " $displayGB "GB" } #output da quantidade de RAM em GB  
    
$diskspace = Get-WmiObject Win32_logicaldisk -ComputerName $pcname #disk info
foreach ($dskitem in $diskspace) {  
if ($dskitem.VolumeName -eq $null ) {}  
else {Write-Host $dskitem.deviceid 
$max = [math]::round($dskitem.Size/1024/1024/1024, 0)        
$free = [math]::round($dskitem.FreeSpace/1024/1024/1024, 0)         
$full = $max - $free    
Write-Host "Espaço Total em Disco"$dskitem.deviceid":" $max "GB"   
Write-Host "Espaço Ocupado em Disco"$dskitem.deviceid":" $full "GB"   
Write-Host "Espaço Livre em Disco"$dskitem.deviceid":" $free "GB"   
Write-Host }} #end of disk info
#$yn = Read-Host -Prompt "Deseja Fazer a limpeza remota de disco (S/N or Y/N)"  #cleaning pompt
if ($yn -ne $null -Or "n") {
switch ($yn) { 
"y"{RDiskCleanCmd} 
"s"{RDiskCleanCmd} 
}} #cleaning call if imput is Y or S
else{}
}
#exeption handelling
catch [System.Runtime.InteropServices.COMException] { Write-Host "Servidor RPC não disponivel" }  
catch [System.Net.NetworkInformation.PingException] { Write-Host "Servidor RPC não disponivel" }     
Catch [System.UnauthorizedAccessException] { Write-Host "Acesso Negado à recolha de informação do PC"}     
Finally { try { Remove-Variable -ErrorAction Stop pcname , colItems, displayGB, objItem, iv4, osname, cpuname, serial, max, free, full, yn } 
catch [System.Management.Automation.ItemNotFoundException] {} }
}
#in case the pc doesn't ping
Else { Write-Host "Computador desligado ou não existente"  
try { Remove-Variable -ErrorAction Stop pcname , contest}   
catch [System.Management.Automation.ItemNotFoundException] {} }
}
main #call of scritpt