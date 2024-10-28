Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# functions

function addButton  { param( $text, $posX = 0, $posY = 0, $w, $h, $dialogRes, $eventClick, $after, $below )

    $button              = New-Object System.Windows.Forms.Button

    if( $posX -ne 0 -or $posY -ne 0 ) { $button.Location = New-Object System.Drawing.Point( $posX , $posY ) }
    if( $after ) { $button.Location = New-Object System.Drawing.Point( $after.right, $after.top ) }
    if( $below ) { $button.Location = New-Object System.Drawing.Point( $below.left, $below.bottom ) }
    
    if( $w ) { $button.width  = $w }
    if( $h ) { $button.height = $h }
    
    $button.Text         = $text
    if( $dialogRes ) { $button.DialogResult = [System.Windows.Forms.DialogResult]::$dialogRes }
    $button.Add_Click( $eventClick )
    return $button

}

function addCheckBox { param( $text, $posX = 0, $posY = 0, $w, $h, $dialogRes, $eventClick, $after, $below )
	    
	$CheckBox = New-Object System.Windows.Forms.CheckBox

    if( $posX -ne 0 -or $posY -ne 0 ) { $CheckBox.Location = New-Object System.Drawing.Point( $posX , $posY ) }
    if( $after ) { $CheckBox.Location = New-Object System.Drawing.Point( $after.right, $after.top ) }
    if( $below ) { $CheckBox.Location = New-Object System.Drawing.Point( $below.left, $below.bottom ) }
    
    if( $w ) { $CheckBox.width  = $w }
    if( $h ) { $CheckBox.height = $h }
    
    $CheckBox.Text         = $text
    $CheckBox.Add_Click( $eventClick )
    return $CheckBox
}

function addForm { param( $text = '', $width, $height, [switch]$NoAutoSize, [string]$startPosition = 'CenterScreen',
                          [switch]$topmost, $controls,  $acceptBt, $cancelBt, [string]$BorderStyle = 'FixedDialog',
                          [switch]$minSize )


	$null = (New-Object -ComObject WScript.Shell).AppActivate((get-process -id $pid).MainWindowTitle)

    $form      = New-Object System.Windows.Forms.Form
    $form.Text = $text
 
    if( $minSize ) { $form.Size = New-Object System.Drawing.Size( 0, 0 ) }
    if( $width  )  { $form.Width  =  $width  }
    if( $height )  { $form.Height =  $height }
    if( $topmost ) { $form.TopMost = $true   }
    $form.AutoSize        = $(-not $NoAutoSize)
 
    $form.StartPosition   = $startPosition
    $form.FormBorderStyle = $BorderStyle
    $form.MaximizeBox     = $false
    
    foreach ($control in $controls) { $form.Controls.Add( $control ) }
    
    if( $acceptBt ) { $form.AcceptButton = $acceptBt }
    if( $cancelBt ) { $form.CancelButton = $cancelBt }
    
    return $form
    
}

function addGroupBox{ param( $text = '', $dock, $autoSize = $true, $controls, $after, $below, $w, $h )

    $Groupbox      = New-Object system.Windows.Forms.Groupbox
    $Groupbox.text = $text
    if( $dock )  { $Groupbox.dock = $dock }
    $Groupbox.AutoSize = $autoSize
    if( $after ) { $Groupbox.Location = New-Object System.Drawing.Point( $after.right, $after.top ) }
    if( $below ) { $Groupbox.Location = New-Object System.Drawing.Point( $below.left, $below.bottom ) }

    if( $w ) { $Groupbox.width = $w }
    if( $h ) { $Groupbox.width = $h }

    $Groupbox.Controls.AddRange( $controls )

    return $Groupbox

}

function addLabel   { param( $text = '', $posX, $posY, $foreColor = '', $autoSize = $true, $below )

    $label           = New-Object System.Windows.Forms.label
    $label.Location  = New-Object System.Drawing.Size( $posX, $posY )
    if( $below ) { $label.Location = New-Object System.Drawing.Point( $below.left, $below.bottom ) }
    $label.AutoSize  = $autoSize
    $label.ForeColor = $foreColor
    $label.Text      = $text
    return $label
    
}


function addListBox { param( $posX, $posY, $w, $h )
    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point( $posX, $posY )
    # $listBox.AutoSize = $true
    if( $w ) { $listBox.Width  = $w }
    if( $h ) { $listBox.Height = $h }
    return $listBox
}

function addUpDown { param ( $width, $posX, $posY, $after, $below )
    
    $UpDown = New-Object System.Windows.Forms.numericUpDown
    $UpDown.AutoSize = $true
    $UpDown.Width = $width
    if( $after ) { $UpDown.Location = New-Object System.Drawing.Point( $after.right, $after.top ) }
    if( $below ) { $UpDown.Location = New-Object System.Drawing.Point( $below.left, $below.bottom ) }

    return $UpDown
    
}

function addTextBox { param( $text = '', $width, $height, $posX, $posY, $foreColor = '', $autoSize = $true, $below, 
                             [switch]$ReadOnly, [switch]$Multiline, [switch]$Wrap )

    $TextBox           = New-Object System.Windows.Forms.TextBox
    $TextBox.Location  = New-Object System.Drawing.Size( $posX, $posY )
    if( $below )   { $TextBox.Location = New-Object System.Drawing.Point( $below.left, $below.bottom ) }
    $TextBox.AutoSize  = $autoSize
    $TextBox.ForeColor = $foreColor
    $TextBox.Text      = $text
    $TextBox.ReadOnly  = $ReadOnly
    $TextBox.Multiline = $Multiline
    if( $wrap ) { $TextBox.WordWrap  = $true }
    if( $width ) { $TextBox.Width = $width }
    if( $height ) { $TextBox.Height = $height }
    $TextBox.ScrollBars = "Vertical"
    return $TextBox
    
}

class Control {
    [String]$Text
	[int]$PosX
	[int]$PosY
	[int]$W
	[int]$H
    [System.Boolean]$AutoSize = $True
    $Object
}

Class Button : Control {
    $DialogResponse
    $OnClick
}

Class Form : Control {

    [String]$BorderStyle
    [Boolean]$MaxButton
    [Boolean]$TopMost

    Form() {

        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        
        $This.Object = New-Object System.Windows.Forms.Form
        If( $This.W ) { $This.Object.Width  = $This.W }
        If( $This.H ) { $This.Object.Height = $This.H }

        $This.Object.ShowDialog()
        
    }

}


if( -not $url ) { # debugging
 
}