### GLG Terminal Server Users Setup

New-LocalGroup -Name GLG_Sales
New-LocalGroup -Name GLG_ExecTeam
New-LocalGroup -Name GLG_Engineers
New-LocalGroup -Name GLG_QuoteWerks

$PASS = Read-Host -AsSecureString

$uNAME="alukan"
$uFULL="Allison Lukan"
New-LocalUser -Name $uNAME -FullName $uFULL -Password $PASS
Add-LocalGroupMember -Group "GLG_Sales" -Member $uNAME
Add-LocalGroupMember -Group "GLG_QuoteWerks" -Member $uNAME
Add-LocalGroupMember -Group "Remote Desktop Users" -Member $uNAME

$uNAME="asroczynski"
$uFULL="Andrew Sroczynski"
New-LocalUser -Name $uNAME -FullName $uFULL -Password $PASS
Add-LocalGroupMember -Group "GLG_Engineers" -Member $uNAME
Add-LocalGroupMember -Group "Remote Desktop Users" -Member $uNAME

$uNAME="bbowden"
$uFULL="Brian Bowden"
New-LocalUser -Name $uNAME -FullName $uFULL -Password $PASS
Add-LocalGroupMember -Group "GLG_Engineers" -Member $uNAME
Add-LocalGroupMember -Group "Remote Desktop Users" -Member $uNAME

$uNAME="bbenally"
$uFULL="Brittani Benally"
New-LocalUser -Name $uNAME -FullName $uFULL -Password $PASS
Add-LocalGroupMember -Group "GLG_Engineers" -Member $uNAME
Add-LocalGroupMember -Group "Remote Desktop Users" -Member $uNAME

$uNAME="cmunro"
$uFULL="Chris Munro"
New-LocalUser -Name $uNAME -FullName $uFULL -Password $PASS
Add-LocalGroupMember -Group "Administrators" -Member $uNAME
Add-LocalGroupMember -Group "GLG_Engineers" -Member $uNAME
Add-LocalGroupMember -Group "GLG_QuoteWerks" -Member $uNAME
Add-LocalGroupMember -Group "Remote Desktop Users" -Member $uNAME

$uNAME="chickman"
$uFULL="Corey Hickman"
New-LocalUser -Name $uNAME -FullName $uFULL -Password $PASS
Add-LocalGroupMember -Group "GLG_Sales" -Member $uNAME
Add-LocalGroupMember -Group "GLG_QuoteWerks" -Member $uNAME
Add-LocalGroupMember -Group "Remote Desktop Users" -Member $uNAME

$uNAME="dcaswell"
$uFULL="Doug Caswell"
New-LocalUser -Name $uNAME -FullName $uFULL -Password $PASS
Add-LocalGroupMember -Group "GLG_Engineers" -Member $uNAME
Add-LocalGroupMember -Group "Remote Desktop Users" -Member $uNAME

$uNAME="ealeshire"
$uFULL="Ethan Aleshire"
New-LocalUser -Name $uNAME -FullName $uFULL -Password $PASS
Add-LocalGroupMember -Group "Administrators" -Member $uNAME
Add-LocalGroupMember -Group "GLG_Engineers" -Member $uNAME
Add-LocalGroupMember -Group "Remote Desktop Users" -Member $uNAME

$uNAME="ipena"
$uFULL="Iden Pena"
New-LocalUser -Name $uNAME -FullName $uFULL -Password $PASS
Add-LocalGroupMember -Group "GLG_QuoteWerks" -Member $uNAME
Add-LocalGroupMember -Group "Remote Desktop Users" -Member $uNAME

$uNAME="jkelley"
$uFULL="James Kelley"
New-LocalUser -Name $uNAME -FullName $uFULL -Password $PASS
Add-LocalGroupMember -Group "GLG_Engineers" -Member $uNAME
Add-LocalGroupMember -Group "Remote Desktop Users" -Member $uNAME

$uNAME="jmadden"
$uFULL="Joe Madden"
New-LocalUser -Name $uNAME -FullName $uFULL -Password $PASS
Add-LocalGroupMember -Group "GLG_Sales" -Member $uNAME
Add-LocalGroupMember -Group "GLG_Engineers" -Member $uNAME
Add-LocalGroupMember -Group "Remote Desktop Users" -Member $uNAME

$uNAME="jsquires"
$uFULL="Julie Squires"
New-LocalUser -Name $uNAME -FullName $uFULL -Password $PASS
Add-LocalGroupMember -Group "GLG_Sales" -Member $uNAME
Add-LocalGroupMember -Group "Remote Desktop Users" -Member $uNAME

$uNAME="kniles"
$uFULL="Karla Niles"
New-LocalUser -Name $uNAME -FullName $uFULL -Password $PASS
Add-LocalGroupMember -Group "GLG_Engineers" -Member $uNAME
Add-LocalGroupMember -Group "Remote Desktop Users" -Member $uNAME

$uNAME="mbrown"
$uFULL="Matt Brown"
New-LocalUser -Name $uNAME -FullName $uFULL -Password $PASS
Add-LocalGroupMember -Group "GLG_Engineers" -Member $uNAME
Add-LocalGroupMember -Group "Remote Desktop Users" -Member $uNAME

$uNAME="mbarillet"
$uFULL="Mike Barillet"
New-LocalUser -Name $uNAME -FullName $uFULL -Password $PASS
Add-LocalGroupMember -Group "GLG_Engineers" -Member $uNAME
Add-LocalGroupMember -Group "Remote Desktop Users" -Member $uNAME

$uNAME="thoffa"
$uFULL="Tom Hoffa"
New-LocalUser -Name $uNAME -FullName $uFULL -Password $PASS
Add-LocalGroupMember -Group "GLG_Engineers" -Member $uNAME
Add-LocalGroupMember -Group "Remote Desktop Users" -Member $uNAME

$uNAME="tjones"
$uFULL="Torrey Jones"
New-LocalUser -Name $uNAME -FullName $uFULL -Password $PASS
Add-LocalGroupMember -Group "GLG_Sales" -Member $uNAME
Add-LocalGroupMember -Group "GLG_QuoteWerks" -Member $uNAME
Add-LocalGroupMember -Group "Remote Desktop Users" -Member $uNAME
