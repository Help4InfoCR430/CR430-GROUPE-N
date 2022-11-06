<#
.Synopsis 
    Le présent document constitue une étude de cas de PowerShell dans le but de réaliser un déploiement d'une machine virtuelle dans l'environnement Microsoft Azure tout en s'assurant d'appliquer les meilleures pratiques de sécurité telles que son endurcissement selon les recommandations de CIS. à‰galement procéder à  l'accessibilité à  distance de la machine virtuelle d'une maniére sécuritaire.

    Aspects ou éléments inclus

    Les éléments suivants font partie de la conception technologique :
        -	Analyse de la mise en place de l'environnement;
        -	Configuration des composantes pré-requises;
        -	Création et configuration de la machine virtuelle;
        -	Installation du OS Windows Serveur 2019;
        -	Considérations de gestion opérationnelle ;
        -	Aspects de sécurité et de conformité.


.Description 
    Les étapes suivantes nous guideront tout au long du processus de création d'une machine virtuelle Windows Server 2019 sur Microsoft Azure avec PowerShell :
    - Groupe de ressources 
        - Dans ce cas, nous allons placer tous les composants de la machine dans le màªme groupe de ressources. 
    - Composants réseau 
        - Nous allons vous montrer comment vous pouvez créer des sous-réseaux, des interfaces réseau et des régles de sécurité.
    - Storage account
        - Créer un compte de stockage sur Microsoft Azure dans lequel vous pouvez stocker votre disque dur virtuel. 
    - Configuration de la machine virtuelle 
        - Cette configuration est nécessaire pour créer la machine virtuelle, la configuration des composants réseau, des images, du dimensionnement des machines virtuelles, etc.

.Parameter InputObject  
    
.Parameter Arguments
   
.Parameter OutDir
   
.Parameter Location

.Parameter CSV
    
.Inputs
    
.Outputs
   
.Example
    
.Notes
Written by: Anass Kamouni, Alaa-Eddine BOUBAKRI, Daha BASSOUM, Cristian Vasile & Daniel Benjamin Mvogo

#>
##### Fonction coloriage du text en CYAN
function Write-Before($text) {
    Write-Host $text -ForegroundColor Cyan
}
##### Fonction coloriage du text en ROUGE
 function Write-backmenu($text) {
    Write-Host $text -ForegroundColor RED
}

##### Fonction coloriage du text en vert
function Write-After($text) {
    Write-Host $text -ForegroundColor Green
}

##### Fonction creation du MENU Utilisateur interactif
function DisplayMenu {
Clear-Host
Write-after @"
+=================================================+
|  CR430 POWERSHELL CONSOLE -  MENU INTERACTIF    | 
+=================================================+
|    0) Validation des  prerequis                 |
|    1) Creation de la Machine Virtuelle          |
|    2) Afficher Information de la RGNAME         |
|    3) Ouvrir une session PSSESSION              |
|    4) Connect with RDP to the VM                |
|    5) Nmap Scan la VM                           |
|    6) Durecissement CIS                         | 
|    7) Suppression des Ressources                | 
|    8) Exit                                      |
+=================================================+

"@
##### Fonction selection des choix 
$MENU = Read-Host "Faites votre choix "
Switch ($MENU)
{
0 {
##### Option 0 verifie si le module AZ est installé dans votre systeme au cas échéant l'installer.
    if (Get-Module -ListAvailable -Name Az.*) {
    Write-Host "Module existant"
    $installed = (Get-Module Az* -ListAvailable)
    Write-after $installed
    # "$installed"
    $Input = Read-Host -Prompt "Appuyez sur une touche pour continuer..."

    }
    else {
    Write-Host "Module non existant"
    $Input = Read-Host -Prompt "Appuyez sur une touche pour installer Module Az" 
    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
    Write-After  "AZ Module installe avec succes...Creation de VM possible..."
    }
    Read-Host -Prompt "Appuyez sur la touche ENTER pour revenir au Menu principal"
    DisplayMenu
  }

1 {
$log = ".\vm.log"
# Recuperation de la date et heure dans le but de calculer pour la duree d'execution du script

Get-Date
#### Connexion au tenant Azure ####
Connect-AzAccount
Start-Sleep -Seconds 2

# Declaration des variables
# choix de la region ou sera heberge notre ressource groupe
$Location =  Read-Host -Prompt 'Entrez le nom de location ou seront heberger vos ressources groupe'
# creation du nom de la ressource groupe
$RGName = Read-Host -Prompt 'Entre le nom de votre ressource groupe'
$SubnetName = $RGName + "SUBNET"
$SubnetRange = "172.150.2.0/24"
$VNetName = $RGName + "VN"
$VNetRange = "172.150.2.0/24"
$PublicIPName = $RGName+ "PIP"
$NSGName = $RGName + "NSG"
$NICName = $RGName + "VNIC"
$SERVICE = Read-Host -Prompt 'Entre le nom du hostname de ta VM'
$ComputerName = $RGName+ $SERVICE
#$ComputerName = "FIREWALL"
$VMName = $RGName + "VM"
$VMSize = "Standard_DS1_v2"
$VMImage = "*/WindowsServer/Skus/2019-Datacenter"

# Fonction pour recuperer de comptes stockages 
Function GetListOfStorageAccounts  
{  
     ## Recupration de storage accounts
    $stList=Get-AzStorageAccount  
    foreach($mystrgAcc in $stList)  
    {  
        write-host -ForegroundColor Green "votre compte stockage est :" $mystrgAcc.StorageAccountName  
    }   
}
# Creation de la Ressource Group dans la region
Write-Before "Creating resource group"
New-AzResourceGroup -Name $RGName -Location $Location
Write-After "Ressource Groupe créée avec succés : $RGName dans la région : $Location "

# Creer un nouveau compte de stockage qui doit etre en miniscule
Write-Before "Création du compte stockage..."
$SAName =  Read-Host -Prompt 'Entrez le nom en miniscule de votre compte Stockage:'
$StorageAccount = New-AzStorageAccount -Location $Location -ResourceGroupName $RGName -Type "Standard_LRS" -Name $SAName
GetListOfStorageAccounts

################ Creation des composantes reseaux ##################################################
#        Creation du sous-reseau avec la plage addresses ip definies par l'utilisateur             #
 Write-Before "Creation du Réseau virtuel $SubnetName dont la plage des addresses IP est : $SubnetRange"
$SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetRange -WarningAction SilentlyContinue
Write-After "Réseau virtuel créé avec succes $SubnetName avec la plage IP : $SubnetRange "
# Creation du reseau virtuel 
$VirtualNetwork = New-AzVirtualNetwork -ResourceGroupName $RGName -Location $Location -Name $VNetName -AddressPrefix $VNetRange -Subnet $SubnetConfig

# Creation de l'addresse IP publique
Write-Before  "Creation de l'addresse IP publique"
$PublicIP = New-AzPublicIpAddress -ResourceGroupName $RGName -Location $Location -AllocationMethod "Dynamic" -Name $PublicIPName -WarningAction SilentlyContinue

# Creation du groupe de securité reseau et les regles du parefeu (WinRM et RDP)
Write-Before  "Creation des regles securite WinRM-HTTPS et RDP dans le groupe"
$SecurityGroupRule = switch ("-Windows") {
    "-Windows" { New-AzNetworkSecurityRuleConfig -Name "RDP-Rule" -Description "Allow RDP" -Access "Allow" -Protocol "TCP" -Direction "Inbound" -Priority 101 -DestinationPortRange 3389 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" }
    "-Windows" { New-AzNetworkSecurityRuleConfig -Name "HTTPS-Rule" -Description "Allow WinRM HTTPS" -Access "Allow" -Protocol "TCP" -Direction "Inbound" -Priority 103 -DestinationPortRange 5986 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" 
}
}
Write-After "les regles securite WinRM-HTTPS et RDP sont cree avec succés"

# Creer un groupe de securité reseau
Write-Before "Creation de groupe de securite Reseaux $NSGName"
$NetworkSG = New-AzNetworkSecurityGroup -ResourceGroupName $RGName -Location $Location -Name $NSGName -SecurityRules $SecurityGroupRule
Write-After "le groupe de securite Reseaux est cree avec succés $NSGName"

# Creation de la carte reseau virtuelle et l'associée a la Machine Virtuelle
Write-Before "Creation de la carte reseau virtuelle : $NICName "
$NetworkInterface = New-AzNetworkInterface -Name $NICName -ResourceGroupName $RGName -Location $Location -SubnetId $VirtualNetwork.Subnets[0].Id -PublicIpAddressId $PublicIP.Id -NetworkSecurityGroupId $NetworkSG.Id
Write-After "la carte reseau virtuelle est cree avec succés: $NICName"

# La commande suivante a été exécutée au préalable pour la création du fichier XML
$user = Read-Host -Prompt 'Entrez le nom utilisateur de la machine virtuelle'
$pass = Read-Host -Prompt 'Entrez le mot de passe de la  machine virtuelle' -AsSecureString

$pscred = New-Object System.Management.Automation.PSCredential -ArgumentList ($user, $pass)
$pscred | Export-Clixml -Path ".\cred.xml"
$cred = import-clixml -Path "cred.xml"
$cred

# Creation de la configuration de machine virtuelle
$VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize

# Definir la taille et l'OS de la machine virtuelle 
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $cred

# Activation du provisionnement de l'Agent de la machine Virtuelle
if ($VirtualMachine.OSProfile.WindowsConfiguration) {
    $VirtualMachine.OSProfile.WindowsConfiguration.ProvisionVMAgent = $true
}

# Obtenir l'image source de la machine virtuelle
$Image = Get-AzVMImagePublisher -Location $Location | Get-AzVMImageOffer | Get-AzVMImageSku | Where-Object -FilterScript { $_.Id -like $VMImage }

# Definir l'image source de la machine virtuelle
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $Image.PublisherName -Offer $Image.Offer -Skus $Image.Skus -Version "latest"

# Ajouter l'interface carte reseau
$VirtualMachine = Add-AzVMNetworkInterface -Id $NetworkInterface.Id -VM $VirtualMachine

# Definir les proprietes du disque systeme 
$OSDiskName = "OsDisk"
$OSDiskUri = "{0}vhds/{1}-{2}.vhd" -f $StorageAccount.PrimaryEndpoints.Blob.ToString(), $VMName.ToLower(), $OSDiskName

# Appliquer les proprietes du disque systeme 
$VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption "FromImage"

# Creation de la machine virtuelle
Write-before "Creation de la  VM "
$NewVM = New-AzVM -ResourceGroupName $RGName -Location $Location -VM $VirtualMachine -WarningAction SilentlyContinue
$NewVM
Write-After "Votre VM est crée avec succés dont le nom est : $VMName "

# Ajout de'une extension de script personnaliseeee la machine virtuelle e partir de notre Repo GitHub
# Execution du script personnalisee apres la creation de la machine virtuelle
Write-before "Veuillez patientez nous executons un script personalise dans la VM "
Set-AzVMCustomScriptExtension -ResourceGroupName $RGName -Location $Location -VMName  $VMNAME -FileUri "https://raw.githubusercontent.com/Help4InfoCR430/AzureDeploy/main/Anass/remote.ps1" -Run 'remote.ps1' -Name EnableWINRMHTTPS

# Attente de 10 secondes 
Start-Sleep -Seconds 10

# Obtenir l'adresse IP Publique de la machine virtuelle
$vmPublicIp = (Get-AzPublicIpAddress -ResourceGroupName $RGName | Where-Object {$_.name -like "$PublicIPName" }).IpAddress

Write-Output -InputObject "Personnalisation de la VM completee!"
# Attente de 10 secondes 
Start-Sleep -Seconds 10; 

# Recuperation de la date et heure de fin d'execution du script
Get-Date

Read-Host -Prompt "Appuyez sur la touche ENTER pour revenir au Menu principal"
DisplayMenu

}

######### AFFICHER LES INFORMATIONS ############# 
2 {
#Connect-AzAccount
$RGName = Read-Host -Prompt 'Entrez le nom de votre ressource groupe que vous voulez consulter'
$PublicIPName = $RGName+ "PIP"
 $SERVICE = Read-Host -Prompt 'Entrez le nom de votre ressource groupe que vous voulez consulter'
#$ComputerName = $RGName + $SERVICE
$VMName = $RGName + "VM"
$vmPublicIp = (Get-AzPublicIpAddress -ResourceGroupName $RGName  | Where-Object {$_.name -like "$PublicIPName"}).IpAddress
Write-After "Le nom de votre machine virtuel est    : $VMNAME"
Write-After "Le nom de votre hostname  virtuel est  : $ComputerName"
Write-After "Le nom de votre Resourse groupe est    : $RGName"
write-after "L'adresse ip publique de votre VM est : $vmPublicIp"
Read-Host -Prompt "Appuyez sur la touche ENTER pour revenir au Menu principal"
DisplayMenu
}

############# Ouvrir une session PSSESSION à  distance ############# 
3 {
Connect-AzAccount
$RGName = Read-Host -Prompt 'Entrez le nom de votre ressource groupe que vous voulez consulter'
$vmPublicIp = (Get-AzPublicIpAddress -ResourceGroupName $RGName  | Where-Object {$_.name -like "$PublicIPName"}).IpAddress
$cred = import-clixml -Path "cred.xml"
 Write-After "L'adresse IP Public est :  $vmPublicIp "
Start-Sleep -Seconds 2
Write-After "Veuillez patienter... Connexion PSSession $VMName $vmPublicIp en cours..."
Enter-PSSession -ComputerName $vmPublicIp -Port 5986 -Credential $cred -UseSSL -SessionOption (New-PSSessionOption -SkipCACheck -SkipCNCheck  -SkipRevocationCheck)
Read-Host -Prompt "Appuyez sur la touche ENTER pour revenir au Menu principal"
DisplayMenu
}

################# RDP ############# 
4 {
$RGName = Read-Host -Prompt 'Entre le nom de votre ressource groupe que vous voulez consulter'
$PublicIPName = $RGName+ "PIP"
$vmPublicIp = (Get-AzPublicIpAddress -ResourceGroupName $RGName  | Where-Object {$_.name -like "$PublicIPName"}).IpAddress
Write-After "Ouverture d'une session RDP... sur $vmPublicIp"
Start-Process "$env:windir\system32\mstsc.exe" -ArgumentList "/v:$vmPublicIp" 
Read-Host -Prompt "Appuyez sur la touche ENTER pour revenir au Menu principal"
DisplayMenu
}

############## NMAP SCAN ############# 
############## NMAP SCAN ############# 
5 {
  start-process powershell  ".\choix_scan.ps1"
  Read-Host -Prompt "Appuyez sur la touche ENTER pour revenir au Menu principal"
  DisplayMenu
   }

############## Durssissement CIS ############# 
6 {
$RGName = Read-Host -Prompt 'Entrez le nom de votre ressource groupe que vous voulez consulter'
Write-Before "Le durecissement de server 2019 selon CIS débutera sous peu dans la $VMName "
$cred = import-clixml -Path "cred.xml"
$vmPublicIp = (Get-AzPublicIpAddress -ResourceGroupName $RGName  | Where-Object {$_.name -like "$PublicIPName"}).IpAddress 
Write-Before "Le durcissement de la VM débutera sous peu: $VMName  $vmPublicIp "
Invoke-Command  -ScriptBlock { .\CIS_WinSrv2019.ps1 }
Write-After "Le durecissement est effectué avec succés sur $VMName...Veuillez consulter le rapport dans le repertoire courant"
Write-After "Consulter les détails de journalisation sur la VM  à  l'emplacement suivant : log %windir%\security\logs\scesrv.lo"
Read-Host -Prompt "Appuyez sur la touche ENTER pour revenir au Menu principal"
DisplayMenu
}

############## Suppression de la ressource Groupe ##############
7 {
$RGName = Read-Host -Prompt 'Entrez le nom de votre ressource groupe à  supprimer'
Write-After "Suppression $RGName dans Azure en cours..."
Remove-AzResourceGroup -name $RGName
Write-After "La ressource Groupe est supprimée avec succés  $RGName "
Read-Host -Prompt "Appuyez sur la touche ENTER pour revenir au Menu principal"
DisplayMenu
}

############## Quitter ##############
8 {
#OPTION3 - EXIT
Write-Host "Fin!"
Break
}
default {
#DEFAULT OPTION
Write-Host "Option non valide"
Start-Sleep -Seconds 2
DisplayMenu
}
}
}
DisplayMenu
