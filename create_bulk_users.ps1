# PowerShell script to create bulk users in Microsoft Graph from a CSV file.
# Ensure you have the Microsoft Graph PowerShell SDK installed and authenticated.
# This script requires the following permissions: User.ReadWrite.All, Group.ReadWrite.All
# To run this script, save it as create_bulk_users.ps1 and ensure you have a CSV file named CreateBulkUsers.csv in the same directory.
# Import the Microsoft Graph module
try {
    Connect-MgGraph -Scopes "User.ReadWrite.All", "Group.ReadWrite.All"
    Write-Host "Successfully connected to Microsoft Graph" -ForegroundColor Green
}
catch {
    Write-Host "Failed to connect to Microsoft Graph: $_" -ForegroundColor Red
    exit 1
}

$csvPath = Resolve-Path ".\CreateBulkUsers.csv"

$csvDirectory = Split-Path -Path $csvPath

$resultsPath = Join-Path -Path $csvDirectory -ChildPath "NewAccountResults.csv"

# Import the CSV file.
$users = Import-Csv -Path $csvPath


# Process each user and collect the results in an array.
$results = foreach ($user in $users) {
    # Build the password profile object
    $PasswordProfile = @{
        Password                      = $user.PasswordProfile
        ForceChangePasswordNextSignIn = $true
    }
    

    try {
        # Create the user in Microsoft Graph
        New-MgUser `
            -UserPrincipalName $user.UserPrincipalName `
            -MailNickname $user.MailNickname `
            -DisplayName $user.DisplayName `
            -PasswordProfile $PasswordProfile `
            -AccountEnabled: $true `
            -ErrorAction Stop

        # Optionally, collect success info
        [PSCustomObject]@{
            UserPrincipalName = $user.UserPrincipalName
            Status            = "Success"
            Error             = $null
        }
    }
    catch {
        # Collect error info
        [PSCustomObject]@{
            UserPrincipalName = $user.UserPrincipalName
            Status            = "Failed"
            Error             = $_.Exception.Message
        }
    }
}

# Export the results to a CSV file. Use -NoTypeInformation to avoid an extra column.
$results | Export-Csv -Path $resultsPath -NoTypeInformation

Disconnect-MgGraph
Write-Host "Script completed successfully." -ForegroundColor Green