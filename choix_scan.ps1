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
 function DisplayMenuNmap {
    Clear-Host
    Write-after @"
+=========================================================+
|  Choisir votre SCAN NMAP À Lancr                        | 
+=========================================================+
|    0) NMAP PING SCAN -sn                                |
|    1) NMAP INTENSE SCAN -T4 -A -v                       |
|    2) NMAP SCAN tous PORT TCP -p 1-65535 -T4 -A -v      |
|    3) à Venir NSE et VULNERS                            |
|    4) Exit                                              |
+=========================================================+

"@
##### Fonction selection des choix 
$MENU = Read-Host "Faites votre choix "
Switch ($MENU)
    {
        0 {
             $RGName = Read-Host -Prompt 'Entrez le nom de votre ressource groupe que vous voulez balayer'
            $PublicIPName = $RGName+ "PIP"
            $vmPublicIp = (Get-AzPublicIpAddress -ResourceGroupName $RGName  | Where-Object {$_.name -like "$PublicIPName"}).IpAddress 
            $ProgramName = "C:\Program Files (x86)\Nmap\nmap.exe"
            $xml = "-oX $($vmPublicIp)_Ping_Scan.xml"
            
            Write-After "Exécution du balayage NMAP PING SCAN sur $VMName"
            Write-After "$ProgramName  -sn $vmPublicIp  $xml"
            
            Write-After "le balayage NMAP débutera sous peu ...:  $vmPublicIp "
            $ArgumentList = "-sn $vmPublicIp  $xml"
            $nmapscan = Start-Process $ProgramName -ArgumentList $ArgumentList -wait -NoNewWindow -PassThru
            #$nmapscan = start-process  -ScriptBlock { $nampc  -Arguments "$arg" $vmPublicIp -oX $OutputFile}
            $nmapscan
            Write-After "$VMName "
            Read-Host -Prompt "Appuyez sur la touche ENTER pour revenir au Menu principal"
            DisplayMenuNmap
           }
           

        1  {
            $RGName = Read-Host -Prompt 'Entrez le nom de votre ressource groupe que vous voulez balayer'
            $PublicIPName = $RGName+ "PIP"
            $vmPublicIp = (Get-AzPublicIpAddress -ResourceGroupName $RGName  | Where-Object {$_.name -like "$PublicIPName"}).IpAddress 
            $ProgramName = "C:\Program Files (x86)\Nmap\nmap.exe"
            $xml = "-oX $($vmPublicIp)_intense.xml"
            Write-After "Exécution du balayage NMAP INTENSE SCAN sur $VMName"
            Write-After "$ProgramName  -T4 -A -v $vmPublicIp  $xml "
            
            Write-After "le balayage NMAP débutera sous peu ...:  $vmPublicIp "
            #$arg = "-T4 -F"
            #$arg = read-Host  -Prompt 'Veuillez entrer le nom du balayage NMAP que vous désirer'
            $ArgumentList = "-T4 -F $vmPublicIp  $xml"
            $nmapscan = Start-Process $ProgramName -ArgumentList $ArgumentList -wait -NoNewWindow -PassThru
            #$nmapscan = start-process  -ScriptBlock { $nampc  -Arguments "$arg" $vmPublicIp -oX $OutputFile}
            $nmapscan
            Write-After "$VMName "
            Read-Host -Prompt "Appuyez sur la touche ENTER pour revenir au Menu principal"
            DisplayMenuNmap
           }
         2 {
             $RGName = Read-Host -Prompt 'Entrez le nom de votre ressource groupe que vous voulez balayer'
            $PublicIPName = $RGName+ "PIP"
            $vmPublicIp = (Get-AzPublicIpAddress -ResourceGroupName $RGName  | Where-Object {$_.name -like "$PublicIPName"}).IpAddress 
            $ProgramName = "C:\Program Files (x86)\Nmap\nmap.exe"
            $xml = "-oX $($vmPublicIp)_intense_allTCPPORT.xml"
            Write-After "Exécution du balayage NMAP SCAN sur pour tous les PORT TCP $VMName"
            Write-After "$ProgramName -p 1-65535 -T4 -A -v $vmPublicIp"
            
            Write-After "le balayage NMAP débutera sous peu ...:  $vmPublicIp "
            $ArgumentList = "-p 1-65535 -T4 -A -v $vmPublicIp  $xml"
            $nmapscan = Start-Process $ProgramName -ArgumentList $ArgumentList -wait -NoNewWindow -PassThru
            $nmapscan
            Write-After "$VMName "
            Read-Host -Prompt "Appuyez sur la touche ENTER pour revenir au Menu principal"
            DisplayMenuNmap
           }
           3 {
           Write-After "pour les scripts NSE et Vulners "
            Write-After "En Cours de Développement "
            Read-Host -Prompt "Appuyez sur la touche ENTER pour revenir au Menu principal"
            DisplayMenuNmap
           }
############## Quitter ##############
       4 {
        #OPTION3 - EXIT
        Write-Host "Fin!"
        Break
        }
        default {
        #DEFAULT OPTION
        Write-Host "Option non valide"
        Start-Sleep -Seconds 2
        DisplayMenuNmap
       }
     }
}

DisplayMenuNmap
