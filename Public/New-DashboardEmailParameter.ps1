function New-DashboardEmailParameter {
    <#
    .SYNOPSIS
    Creates a legacy email-configuration record.

    .DESCRIPTION
    Returns the supplied transport settings without connecting or sending mail.
    Start-TheDashboard does not support email or notification elements and rejects
    this record. The function remains available for existing callers that inspect
    configuration; its presence does not enable email delivery.

    .PARAMETER Server
    SMTP server name stored in the record. SmtpServer is an alias.

    .PARAMETER Port
    SMTP port stored in the record.

    .PARAMETER From
    Sender address or sender object to store.

    .PARAMETER ReplyTo
    Reply-to address to store.

    .PARAMETER Priority
    Message priority: Low, Normal, or High. Importance is an alias.

    .PARAMETER DeliveryNotificationOption
    Legacy SMTP delivery-notification options to store.

    .PARAMETER DeliveryStatusNotificationType
    Transport-specific delivery-status value to store without requiring a mail library.

    .PARAMETER Credential
    Credential object stored for the selected transport. No authentication is attempted.

    .PARAMETER Username
    Username for the legacy username/password parameter set.

    .PARAMETER Password
    Plain-text password for the legacy username/password parameter set. Prefer Credential
    when the consuming code supports it. Avoid persisting secrets in configuration files.

    .PARAMETER SecureSocketOptions
    Transport-specific socket-security value to store.

    .PARAMETER UseSsl
    Stores the legacy SSL setting.

    .PARAMETER SkipCertificateRevocation
    Stores a request to skip certificate-revocation checks; no connection is made here.

    .PARAMETER SkipCertificateValidation
    Stores a request to skip certificate validation; no connection is made here.

    .PARAMETER Timeout
    Transport timeout value to store. This function does not enforce a timeout.

    .PARAMETER oAuth2
    Selects the legacy OAuth configuration parameter set.

    .PARAMETER RequestReadReceipt
    Stores the read-receipt preference for Graph configuration.

    .PARAMETER RequestDeliveryReceipt
    Stores the delivery-receipt preference for Graph configuration.

    .PARAMETER Graph
    Stores the legacy Graph transport selection.

    .PARAMETER MgGraphRequest
    Selects and stores the MgGraphRequest transport option.

    .PARAMETER AsSecureString
    Stores the legacy AsSecureString flag. It does not convert Password to a SecureString.

    .PARAMETER SendGrid
    Selects and stores the SendGrid transport option.

    .PARAMETER SeparateTo
    Stores the separate-recipient preference for SendGrid configuration.

    .PARAMETER DoNotSaveToSentItems
    Stores the sent-items preference for Graph configuration.

    .PARAMETER LocalDomain
    SMTP client domain value to store.

    .EXAMPLE
    $Settings = New-DashboardEmailParameter -From 'reports@example.test' -Server 'smtp.example.test' -Port 587 -UseSsl
    $Settings.Type

    Creates a configuration record for inspection. It does not send a message and
    cannot be passed as a supported Start-TheDashboard element.

    .OUTPUTS
    An ordered dictionary with Type and Settings entries.
    #>
    [cmdletBinding(DefaultParameterSetName = 'Compatibility', SupportsShouldProcess)]
    param(
        [Parameter(ParameterSetName = 'SecureString')]

        [Parameter(ParameterSetName = 'oAuth')]
        [Parameter(ParameterSetName = 'Compatibility')]
        [alias('SmtpServer')][string] $Server,

        [Parameter(ParameterSetName = 'SecureString')]

        [Parameter(ParameterSetName = 'oAuth')]
        [Parameter(ParameterSetName = 'Compatibility')]
        [int] $Port,

        [Parameter(Mandatory, ParameterSetName = 'SecureString')]
        [Parameter(Mandatory, ParameterSetName = 'oAuth')]
        [Parameter(Mandatory, ParameterSetName = 'Graph')]
        [Parameter(Mandatory, ParameterSetName = 'MgGraphRequest')]
        [Parameter(Mandatory, ParameterSetName = 'Compatibility')]
        [Parameter(Mandatory, ParameterSetName = 'SendGrid')]
        [object] $From,

        [Parameter(ParameterSetName = 'SecureString')]
        [Parameter(ParameterSetName = 'oAuth')]
        [Parameter(ParameterSetName = 'Graph')]
        [Parameter(ParameterSetName = 'MgGraphRequest')]
        [Parameter(ParameterSetName = 'Compatibility')]
        [Parameter(ParameterSetName = 'SendGrid')]
        [string] $ReplyTo,


        [Parameter(ParameterSetName = 'SecureString')]
        [Parameter(ParameterSetName = 'oAuth')]
        [Parameter(ParameterSetName = 'Graph')]
        [Parameter(ParameterSetName = 'MgGraphRequest')]
        [Parameter(ParameterSetName = 'Compatibility')]
        [Parameter(ParameterSetName = 'SendGrid')]
        [alias('Importance')][ValidateSet('Low', 'Normal', 'High')][string] $Priority,

        [Parameter(ParameterSetName = 'SecureString')]
        [Parameter(ParameterSetName = 'oAuth')]
        [Parameter(ParameterSetName = 'Compatibility')]
        [ValidateSet('None', 'OnSuccess', 'OnFailure', 'Delay', 'Never')][string[]] $DeliveryNotificationOption,

        [Parameter(ParameterSetName = 'SecureString')]
        [Parameter(ParameterSetName = 'oAuth')]
        [Parameter(ParameterSetName = 'Compatibility')]
        [object] $DeliveryStatusNotificationType,

        [Parameter(ParameterSetName = 'oAuth')]
        [Parameter(Mandatory, ParameterSetName = 'Graph')]
        [Parameter(ParameterSetName = 'Compatibility')]
        [Parameter(Mandatory, ParameterSetName = 'SendGrid')]
        [pscredential] $Credential,

        [Parameter(ParameterSetName = 'SecureString')]
        [string] $Username,

        [Parameter(ParameterSetName = 'SecureString')]
        [string] $Password,

        [Parameter(ParameterSetName = 'SecureString')]
        [Parameter(ParameterSetName = 'oAuth')]
        [Parameter(ParameterSetName = 'Compatibility')]
        [object] $SecureSocketOptions,

        [Parameter(ParameterSetName = 'SecureString')]
        [Parameter(ParameterSetName = 'oAuth')]
        [Parameter(ParameterSetName = 'Compatibility')]
        [switch] $UseSsl,

        [Parameter(ParameterSetName = 'SecureString')]
        [Parameter(ParameterSetName = 'oAuth')]
        [Parameter(ParameterSetName = 'Compatibility')]
        [switch] $SkipCertificateRevocation,

        [Parameter(ParameterSetName = 'SecureString')]
        [Parameter(ParameterSetName = 'oAuth')]
        [Parameter(ParameterSetName = 'Compatibility')]
        [alias('SkipCertificateValidatation')][switch] $SkipCertificateValidation,

        [Parameter(ParameterSetName = 'SecureString')]
        [Parameter(ParameterSetName = 'oAuth')]
        [Parameter(ParameterSetName = 'Compatibility')]
        [int] $Timeout,

        [Parameter(ParameterSetName = 'oAuth')]
        [alias('oAuth')][switch] $oAuth2,

        [Parameter(ParameterSetName = 'Graph')]
        [Parameter(ParameterSetName = 'MgGraphRequest')]
        [switch] $RequestReadReceipt,

        [Parameter(ParameterSetName = 'Graph')]
        [Parameter(ParameterSetName = 'MgGraphRequest')]
        [switch] $RequestDeliveryReceipt,

        [Parameter(ParameterSetName = 'Graph')]
        [Parameter(ParameterSetName = 'MgGraphRequest')]
        [switch] $Graph,

        [Parameter(ParameterSetName = 'MgGraphRequest')]
        [switch] $MgGraphRequest,

        [Parameter(ParameterSetName = 'SecureString')]
        [switch] $AsSecureString,

        [Parameter(ParameterSetName = 'SendGrid')]
        [switch] $SendGrid,

        [Parameter(ParameterSetName = 'SendGrid')]
        [switch] $SeparateTo,

        [Parameter(ParameterSetName = 'Graph')]
        [Parameter(ParameterSetName = 'MgGraphRequest')]
        [switch] $DoNotSaveToSentItems,

        [Parameter(ParameterSetName = 'SecureString')]
        [Parameter(ParameterSetName = 'oAuth')]
        [Parameter(ParameterSetName = 'Compatibility')]
        [string] $LocalDomain
    )

    $Output = [ordered] @{
        Type     = 'DashboardConfigurationEmail'
        Settings = [ordered] @{
            Server                         = if ($PSBoundParameters.ContainsKey('Server')) {
                $Server
            } else {
                $null
            }
            Port                           = if ($PSBoundParameters.ContainsKey('Port')) {
                $Port
            } else {
                $null
            }
            From                           = if ($PSBoundParameters.ContainsKey('From')) {
                $From
            } else {
                $null
            }
            ReplyTo                        = if ($PSBoundParameters.ContainsKey('ReplyTo')) {
                $ReplyTo
            } else {
                $null
            }
            Priority                       = if ($PSBoundParameters.ContainsKey('Priority')) {
                $Priority
            } else {
                $null
            }
            DeliveryNotificationOption     = if ($PSBoundParameters.ContainsKey('DeliveryNotificationOption')) {
                $DeliveryNotificationOption
            } else {
                $null
            }
            DeliveryStatusNotificationType = if ($PSBoundParameters.ContainsKey('DeliveryStatusNotificationType')) {
                $DeliveryStatusNotificationType
            } else {
                $null
            }
            Credential                     = if ($PSBoundParameters.ContainsKey('Credential')) {
                $Credential
            } else {
                $null
            }
            Username                       = if ($PSBoundParameters.ContainsKey('Username')) {
                $Username
            } else {
                $null
            }
            Password                       = if ($PSBoundParameters.ContainsKey('Password')) {
                $Password
            } else {
                $null
            }
            SecureSocketOptions            = if ($PSBoundParameters.ContainsKey('SecureSocketOptions')) {
                $SecureSocketOptions
            } else {
                $null
            }
            UseSsl                         = if ($PSBoundParameters.ContainsKey('UseSsl')) {
                $UseSsl
            } else {
                $null
            }
            SkipCertificateRevocation      = if ($PSBoundParameters.ContainsKey('SkipCertificateRevocation')) {
                $SkipCertificateRevocation
            } else {
                $null
            }
            SkipCertificateValidation      = if ($PSBoundParameters.ContainsKey('SkipCertificateValidation')) {
                $SkipCertificateValidation
            } else {
                $null
            }
            Timeout                        = if ($PSBoundParameters.ContainsKey('Timeout')) {
                $Timeout
            } else {
                $null
            }
            oAuth2                         = if ($PSBoundParameters.ContainsKey('oAuth2')) {
                $oAuth2
            } else {
                $null
            }
            RequestReadReceipt             = if ($PSBoundParameters.ContainsKey('RequestReadReceipt')) {
                $RequestReadReceipt
            } else {
                $null
            }
            RequestDeliveryReceipt         = if ($PSBoundParameters.ContainsKey('RequestDeliveryReceipt')) {
                $RequestDeliveryReceipt
            } else {
                $null
            }
            Graph                          = if ($PSBoundParameters.ContainsKey('Graph')) {
                $Graph
            } else {
                $null
            }
            MgGraphRequest                 = if ($PSBoundParameters.ContainsKey('MgGraphRequest')) {
                $MgGraphRequest
            } else {
                $null
            }
            AsSecureString                 = if ($PSBoundParameters.ContainsKey('AsSecureString')) {
                $AsSecureString
            } else {
                $null
            }
            SendGrid                       = if ($PSBoundParameters.ContainsKey('SendGrid')) {
                $SendGrid
            } else {
                $null
            }
            SeparateTo                     = if ($PSBoundParameters.ContainsKey('SeparateTo')) {
                $SeparateTo
            } else {
                $null
            }
            DoNotSaveToSentItems           = if ($PSBoundParameters.ContainsKey('DoNotSaveToSentItems')) {
                $DoNotSaveToSentItems
            } else {
                $null
            }
            LocalDomain                    = if ($PSBoundParameters.ContainsKey('LocalDomain')) {
                $LocalDomain
            } else {
                $null
            }
            WhatIf                         = $WhatIfPreference
        }
    }
    Remove-EmptyValue -Hashtable $Output.Settings
    $Output
}
