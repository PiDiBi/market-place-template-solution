<# Custom Script for Windows #>

#rskeymgmt -a -f c:\enckeys.bak -pI-Urad123
#cmd /c "rskeymgmt -a -f c:\enckeys.bak -pI-Urad123" `>log.txt 2`>`&1

try
{

	$scriptName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Definition)
	$currentScriptFolder = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)
	"Current folder $currentScriptFolder" | Out-File "c:\$scriptName.txt"
	
    #$rskeymgmttool = ' rskeymgmt -a -f c:\enckeys.bak -pI-Urad123'
    #Invoke-Command -ScriptBlock { & cmd /c $rskeymgmttool } | Out-File "c:\$scriptName.txt" -Append

    Start-Transcript -Path c:\$scriptName.txt
    &cmd /c rskeymgmt -a -f c:\enckeys.bak -pI-Urad123
    Stop-Transcript

}
catch
{
	"An error ocurred: $_" | Out-File "c:\$scriptName.txt" -Append
}