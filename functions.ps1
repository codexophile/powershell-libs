Add-Type -AssemblyName PresentationCore, PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

function GuiFromXaml {
    param ( $XamlTextOrXamlFile )

    if ( Test-Path $XamlTextOrXamlFile ) {
        $XamlContent = Get-Content -Path $XamlTextOrXamlFile -Raw
    }
    else {
        $XamlContent = $XamlTextOrXamlFile
    }

    # Add the required assemblies
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase

    # Clean up XAML content - doing each replacement separately
    $XamlContent = $XamlContent -replace 'x:Class="[^"]*"', ''
    $XamlContent = $XamlContent -replace 'mc:Ignorable="d"', ''
    $XamlContent = $XamlContent -replace "x:N", 'N'
    $XamlContent = $XamlContent -replace 'xmlns:mc="[^"]*"', ''
    $XamlContent = $XamlContent -replace 'xmlns:d="[^"]*"', ''
    $XamlContent = $XamlContent -replace 'xmlns:x="[^"]*"', ''
    $XamlContent = $XamlContent -replace 'SelectionChanged="[^"]*"', ''
    $XamlContent = $XamlContent -replace 'Click="[^"]*"', ''

    # Ensure there's only one xmlns declaration
    if ($XamlContent -notmatch 'xmlns=') {
        $XamlContent = $XamlContent -replace '<Window', '<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"'
    }

    [XML]$XAML = $XamlContent

    $reader = New-Object System.Xml.XmlNodeReader $XAML
    try {
        $psForm = [Windows.Markup.XamlReader]::Load($reader)
    }
    catch {
        Write-Host "Error loading XAML: $_"
        throw
    }

    # Create variables for named controls
    $XAML.SelectNodes("//*[@Name]") | ForEach-Object {
        try {
            $name = "wpf_$($_.Name)"
            $value = $psForm.FindName($_.Name)
            Set-Variable -Name $name -Value $value -Scope Global
            Write-Verbose "Created variable '$name'"
        }
        catch {
            Write-Warning "Failed to process element '$($_.Name)': $_"
        }
    }

    return $psForm
}

#* String functions

function Get-UniqueId {
    <#
    .SYNOPSIS
    Generates a unique alphanumeric identifier (UID) of a specified length.

    .DESCRIPTION
    This function generates a random alphanumeric string of a specified length.
    Optionally, a prefix can be added to the ID.

    .PARAMETER Length
    The length of the unique alphanumeric ID. Default is 10.

    .PARAMETER Prefix
    An optional prefix to add to the beginning of the ID.

    .EXAMPLE
    Get-UniqueId
    Outputs: "a7B9c3E8dF" (Default length: 10)

    .EXAMPLE
    Get-UniqueId -Length 15 -Prefix "App"
    Outputs: "App-a7B9c3E8dF2GhY"

    .NOTES
    Author: Your Name
    Date: 24-Nov-2024
    #>

    param (
        [int]$Length = 10, # Default length of 10
        [string]$Prefix = '' # Optional prefix
    )

    # Validate that the length is a positive integer
    if ($Length -le 0) {
        throw "Length must be a positive integer."
    }

    # Define characters to use for the unique ID
    $characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'

    # Generate the random alphanumeric ID
    $randomId = -join ((1..$Length) | ForEach-Object { $characters[(Get-Random -Minimum 0 -Maximum $characters.Length)] })

    # Add prefix if provided
    if ($Prefix -ne '') {
        return "$Prefix$randomId"
    }
    else {
        return $randomId
    }
}

function ConvertTo-Seconds {
    param (
        [string]$Time # input time in the format of HH:MM:SS
    )
    $null = $Time -match '^(\d+?):(\d+?):(\d+?)($|-)'
    [int]$HoursInSeconds = [int]$Matches[1] * 60 * 60
    [int]$MinutesInSeconds = [int]$Matches[2] * 60
    [int]$SecondsInSeconds = [int]$Matches[3]
    [int]$TotalSeconds = $HoursInSeconds + $MinutesInSeconds + $SecondsInSeconds
    return $TotalSeconds
}

function Get-UniqueTags {
    param (
        [string[]]$FilePaths
    )

    # Create an empty array to store all tags
    $allTags = @()

    foreach ($filePath in $FilePaths) {
        # Use regex to find all tags in the format [tag-name]
        $TagsMatches = [regex]::Matches($filePath, "\[\w+\]")

        foreach ($match in $TagsMatches) {
            # Add the tag to the array
            $allTags += $match.Value
        }
    }

    # Get unique tags and join them into a single string
    $uniqueTags = $allTags | Sort-Object -Unique

    return ($uniqueTags -join '')
}

function Get-LongestCommonSubstring {
    param (
        [string[]]$arr
    )

    $commonSubstrings = $arr | ForEach-Object {
        $substrings = @()
        for ($s = 0; $s -lt $_.Length; $s++) {
            for ($l = 1; $l -le ($_.Length - $s); $l++) {
                $substrings += $_.Substring($s, $l)
            }
        }
        $substrings | ForEach-Object { $_.ToLower() } | Select-Object -Unique
    }

    $commonSubstrings | Group-Object | Where-Object { $_.Count -eq $arr.Length } |
    Sort-Object { $_.Name.Length } -Descending |
    Select-Object -ExpandProperty Name -First 1
}

function cleanString {
    param( [string] $string )
    $out = $string -replace ( "https\:\/\/t\.co\/", ', ' )
    $out = $out -replace ( '&amp;' , '&' )
    $out = $out -replace ( '/' , ' ' )
    $out = $out -replace ( '\n'    , ' ' )
    $out = $out -replace ( '\s{2,}', ' ' )
    return $out
}

#* Rest

function show-notification {
    param (
        $IconPath = ( Get-Process -Id $PID ).Path,
        $NotificationType = 'Info',
        $BodyText = ' ',
        $TitleText = '',
        $Duration = 5000 )
    
    $global:Notification = New-Object -TypeName System.Windows.Forms.NotifyIcon -Property @{
        Icon            = [System.Drawing.Icon]::ExtractAssociatedIcon( $IconPath )
        BalloonTipIcon  = [System.Windows.Forms.ToolTipIcon]::$NotificationType
        BalloonTipText  = $BodyText
        BalloonTipTitle = $TitleText
        Visible         = $true
    }
    $Notification.ShowBalloonTip( $Duration )
}

function MessageBox {
    param ( $body, $title = '', $buttons = 'Ok', $type = 'None' )
    return [System.Windows.MessageBox]::Show( $body, $title, $buttons, $type )
}

function animation {
    param ( $frames, $loops = -1, $speed = 250 )

    # $loops = -1 makes this run infinitely 

    $i = 0
    do {

        foreach ($frame in $frames) {
            Write-Host -NoNewline  "`r$frame  "
            Start-Sleep -Milliseconds $speed
        }

        $i++
      
    } until ( $i -eq $loops )

}

function ListJoin {
    param ( $ListItems )
  
    $NewList = @()
  
    foreach ($currentItemName in $ListItems) {
  
        if ( $currentItemName ) {
            $NewList += $currentItemName 
        }

    }
  
    return $NewList

}

function beep {
    [console]::beep(1500, 50)
    [console]::beep(2000, 50)
    [console]::beep(2500, 50)
}

function activate {
    $null = (New-Object -ComObject WScript.Shell).AppActivate((get-process -id $pid).MainWindowTitle)
}

function anyKey {
    Write-Host -NoNewLine 'Press any key to continue...'
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

function checkFile {
    param ( [string] $originalFilename, [string] $options )
  
    if ( -not ( Test-Path -LiteralPath $originalFilename ) ) { return $originalFilename }
    
    $ParentPath = Split-Path -Path $originalFilename -Parent
    $LeafBase = Split-Path -Path $originalFilename -LeafBase
    $Extension = Split-Path -Path $originalFilename -Extension
    $pattern = '_(\d+)\s*$'
    if ( $LeafBase -match $pattern ) {
        $Number = [int]$Matches[1]
        $Number++
        $NewLeafBase = $LeafBase -replace $pattern, "_$Number"
        $NewFNWithPath = $ParentPath ? "$ParentPath\$NewLeafBase$Extension" : "$NewLeafBase$Extension"
        return checkFile $NewFNWithPath
    }

    return checkFile "$($ParentPath ? "$ParentPath\" : '' )$($LeafBase)_1$Extension"

}

function Show-JsonTreeView {

    param (
        [Parameter(Mandatory)]
        $Json
    )

    function Show-jsonTreeView_psf {

        #----------------------------------------------
        #region Import the Assemblies
        #----------------------------------------------
        [void][reflection.assembly]::Load('System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
        [void][reflection.assembly]::Load('System.Drawing, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
        #endregion Import Assemblies

        #----------------------------------------------
        #region Generated Form Objects
        #----------------------------------------------
        [System.Windows.Forms.Application]::EnableVisualStyles()
        $formJSONTreeView = New-Object 'System.Windows.Forms.Form'
        $treeview1 = New-Object 'System.Windows.Forms.TreeView'
        $InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
        #endregion Generated Form Objects

        #----------------------------------------------
        # User Generated Script
        #----------------------------------------------

        function Add-JsonToTreeview {
  
            ########################################################################################
            #                                                                                      #
            #    The MIT License                                                                   #
            #                                                                                      #
            #    Copyright (c) 2019 Matt Oestreich. http://mattoestreich.com                       #
            #                                                                                      #
            #    Permission is hereby granted, free of charge, to any person obtaining a copy      #
            #    of this software and associated documentation files (the "Software"), to deal     #
            #    in the Software without restriction, including without limitation the rights      #
            #    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell         #
            #    copies of the Software, and to permit persons to whom the Software is             #
            #    furnished to do so, subject to the following conditions:                          #
            #                                                                                      #
            #    The above copyright notice, accreditation to Matt Oestreich, and this permission  #
            #    notice shall be included in all copies or substantial portions of the Software.   #
            #                                                                                      #
            #    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR        #
            #    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,          #
            #    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE       #
            #    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER            #
            #    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,     #
            #    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN         #
            #    THE SOFTWARE.                                                                     #
            #                                                                                      #
            ########################################################################################
  
            <#
                  .SYNOPSIS
                  Add JSON to TreeView
  
                  .DESCRIPTION
                  Add JSON to TreeView (System.Windows.Forms.TreeView) Component
  
                  .PARAMETER Json
                  JSON data (`-Json` can be a `[String]` or converted JSON string (aka `[PsCustomObject]`) converted using `ConvertFrom-Json`). See examples for more details.
  
                  .PARAMETER TreeView
                  The TreeView (System.Windows.Forms.TreeView) that you want to add JSON to
  
                  .PARAMETER ParentNode
                  This is here for recursion - you will most likely not need to use this Parameter
                  9.99 times out of 10.00 you wil not need to use this Parameter
  
                  .EXAMPLE
                  PS C:\> $SomeTreeView = [System.Windows.Forms.TreeView]::new()
                  PS C:\> $myJsonString = '{ "Root": [{ "Child1": "Value1" }, { "Child2": "Value2" }, { "Child3": "Value3" }] }'
                  PS C:\> $myJsonConverted = $myJsonString | ConvertFrom-Json
                  PS C:\> Add-JsonToTreeview -Json $myJsonConverted -TreeView $SomeTreeView

                  .EXAMPLE
                  PS C:\> $SomeTreeView = [System.Windows.Forms.TreeView]::new()
                  PS C:\> $myJsonString = '{ "Root": [{ "Child1": "Value1" }, { "Child2": "Value2" }, { "Child3": "Value3" }] }'
                  PS C:\> Add-JsonToTreeview -Json $myJsonString -TreeView $SomeTreeView
  
                  .NOTES
                  Matt Oestreich | http://mattoestreich.com | https://github.com/oze4
          #>
  
            param (
                [Parameter(Mandatory)]
                $Json,
    
                [Parameter(Mandatory)]
                [Windows.Forms.TreeView]$TreeView,
    
                [Parameter()]
                [Windows.Forms.TreeNode]$ParentNode
            )
  
            begin {
                function New-TreeViewNode {
                    param (
                        [Parameter(Mandatory)]
                        [string]$Value
                    )
                    $NewNode = [Windows.Forms.TreeNode]::new($Value)
                    $NewNode.Name = $Value
                    return $NewNode
                }
    
                function Add-ObjectToTreeView {
                    param (
                        [Parameter(Mandatory)]
                        [System.Object[]]$Object,
        
                        [Parameter()]
                        [Windows.Forms.TreeNode]$AddToNode,
        
                        [Parameter(Mandatory)]
                        [Windows.Forms.TreeView]$TargetTreeView
                    )
                    $counter = 1
                    foreach ($objectProp in $Object) {
                        if ((($objectProp | Get-Member -Type NoteProperty).Count) -gt 1) {
                            $objectProp = "{ `"$($counter)`": $($objectProp | ConvertTo-Json) }" | ConvertFrom-Json
                            $counter++
                        }
                        Add-JsonToTreeview -Json $objectProp -ParentNode $AddToNode -TreeView $TargetTreeView
                    }
                }
    
                function Find-ParentNode {
                    param (
                        [Parameter(Mandatory)]
                        [Windows.Forms.TreeView]$TreeView,
        
                        [Parameter(Mandatory)]
                        [AllowNull()]
                        [Windows.Forms.TreeNode]$TreeNode
                    )
                    $parent = $TreeView
                    if ($TreeNode) {
                        $parent = $TreeNode
                    }
                    return $parent
                }
            }
            process {
                switch ($Json.GetType().Name) {
                    'PsCustomObject' {
                        foreach ($jsonProperty in $Json.PsObject.Properties) {
                            $node = New-TreeViewNode -Value $jsonProperty.Name
                          (Find-ParentNode -TreeView $TreeView -TreeNode $ParentNode).Nodes.Add($node)
                            if ($jsonProperty.GetType().Name -eq 'Object[]') {
                                Add-ObjectToTreeView -Object $jsonProperty -AddToNode $node -TargetTreeView $TreeView
                            }
                            else {
                                Add-JsonToTreeview -Json $jsonProperty.Value -ParentNode $node -TreeView $TreeView
                            }
                        }
                    }
      
                    'Object[]' {
                        Add-ObjectToTreeView -Object $Json -AddToNode $ParentNode -TargetTreeView $TreeView
                    }
      
                    'String' {
                        try {
                            Add-JsonToTreeview -Json ($Json | ConvertFrom-Json) -ParentNode $ParentNode -TreeView $TreeView
                        }
                        catch {
                          (Find-ParentNode -TreeView $TreeView -TreeNode $ParentNode).Nodes.Add((New-TreeViewNode -Value $Json))
                        }
                    }
                }
    
                if ($Json -is [ValueType]) {
                    try {
                      (Find-ParentNode -TreeView $TreeView -TreeNode $ParentNode).Nodes.Add((New-TreeViewNode -Value $Json.ToString()))
                    }
                    catch {
                    }
                }
            }
        }



        $formJSONTreeView_Load = {
            Add-JsonToTreeview -Json $Json -TreeView $treeview1
        }

        # --End User Generated Script--
        #----------------------------------------------
        #region Generated Events
        #----------------------------------------------

        $Form_StateCorrection_Load =
        {
            #Correct the initial state of the form to prevent the .Net maximized form issue
            $formJSONTreeView.WindowState = $InitialFormWindowState
        }

        $Form_Cleanup_FormClosed =
        {
            #Remove all event handlers from the controls
            try {
                $formJSONTreeView.remove_Load($formJSONTreeView_Load)
                $formJSONTreeView.remove_Load($Form_StateCorrection_Load)
                $formJSONTreeView.remove_FormClosed($Form_Cleanup_FormClosed)
            }
            catch { Out-Null <# Prevent PSScriptAnalyzer warning #> }
        }
        #endregion Generated Events

        #----------------------------------------------
        #region Generated Form Code
        #----------------------------------------------
        $formJSONTreeView.SuspendLayout()
        #
        # formJSONTreeView
        #
        $formJSONTreeView.Controls.Add($treeview1)
        $formJSONTreeView.AutoScaleDimensions = '6, 13'
        $formJSONTreeView.AutoScaleMode = 'Font'
        $formJSONTreeView.ClientSize = '440, 606'
        $formJSONTreeView.MaximizeBox = $False
        $formJSONTreeView.MinimizeBox = $False
        $formJSONTreeView.Name = 'formJSONTreeView'
        $formJSONTreeView.Text = 'JSON TreeView'
        $formJSONTreeView.add_Load($formJSONTreeView_Load)
        #
        # treeview1
        #
        $treeview1.Location = '12, 12'
        $treeview1.Name = 'treeview1'
        $treeview1.Size = '416, 582'
        $treeview1.TabIndex = 0
        $formJSONTreeView.ResumeLayout()
        #endregion Generated Form Code

        #----------------------------------------------

        #Save the initial state of the form
        $InitialFormWindowState = $formJSONTreeView.WindowState
        #Init the OnLoad event to correct the initial state of the form
        $formJSONTreeView.add_Load($Form_StateCorrection_Load)
        #Clean up the control events
        $formJSONTreeView.add_FormClosed($Form_Cleanup_FormClosed)
        #Show the Form
        return $formJSONTreeView.ShowDialog()

    } #End Function

    #Call the form
    Show-jsonTreeView_psf | Out-Null
}