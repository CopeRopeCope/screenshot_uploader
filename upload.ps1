
### Sample showing a PowerShell GUI with drag-and-drop ###

param (
    [string]$bucket = "s3://",
	[string]$bucketlocation = "https://it.s3.crater.studio",
    [string]$prefix = "/screenshots/"

 )

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")



### Create form ###

$form = New-Object System.Windows.Forms.Form
$form.Text = "PowerShell GUI"
$form.Size = '260,320'
$form.StartPosition = "CenterScreen"
$form.MinimumSize = $form.Size
$form.MaximizeBox = $False
$form.Topmost = $True


### Define controls ###

$button = New-Object System.Windows.Forms.Button
$button.Location = '5,5'
$button.Size = '75,23'
$button.Width = 120
$button.Text = "Upload"


$label = New-Object Windows.Forms.Label
$label.Location = '5,40'
$label.AutoSize = $True
$label.Text = "Drop files or folders here:"

$listBox = New-Object Windows.Forms.ListBox
$listBox.Location = '5,60'
$listBox.Height = 200
$listBox.Width = 240
$listBox.Anchor = ([System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Top)
$listBox.IntegralHeight = $False
$listBox.AllowDrop = $True

$statusBar = New-Object System.Windows.Forms.StatusBar
$statusBar.Text = "Ready"


### Add controls to form ###

$form.SuspendLayout()
$form.Controls.Add($button)
$form.Controls.Add($label)
$form.Controls.Add($listBox)
$form.Controls.Add($statusBar)
$form.ResumeLayout()




### Write event handlers ###

$button_Click = {
    write-host "Listbox contains:" -ForegroundColor Yellow

	foreach ($item in $listBox.Items)
    {
           
        $i = Get-Item -LiteralPath $item
        $filename = $i

        if($i -is [System.IO.DirectoryInfo])
        {
            write-host ("`t" + $i.Name + " [Directory]")
        }
        else
        {

        if ($bucket.EndsWith("/"))
        {
            $bucket=$bucket.Substring(0,$bucket.Length-1)
        }

        if (!$prefix.StartsWith("/"))
        {
            $prefix = "/$prefix"
        }

        if (!$prefix.EndsWith("/"))
        {
            $prefix = "$prefix/"
        }
            $shortfilename=$i.Name

            write-host ("`t" + "$filename" + "`t" +"$bucket$prefix"+"`t"+ "$shortfilename")
            python.exe "C:\Install\s3cmd-2.0.2\s3cmd" "put" "$filename" "$bucket$prefix$shortfilename"
            write-host ("`t" + $i.Name +" "+"$bucketlocation$prefix$shortfilename")
            Set-Clipboard -Value "$bucketlocation$prefix$shortfilename"
        }
	}

    $listBox.Items.Clear()


    $statusBar.Text = ("List contains $($listBox.Items.Count) items")
}

$listBox_DragOver = [System.Windows.Forms.DragEventHandler]{
	if ($_.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) # $_ = [System.Windows.Forms.DragEventArgs]
	{
	    $_.Effect = 'Copy'
	}
	else
	{
	    $_.Effect = 'None'
	}
}
	
$listBox_DragDrop = [System.Windows.Forms.DragEventHandler]{
	foreach ($filename in $_.Data.GetData([Windows.Forms.DataFormats]::FileDrop)) # $_ = [System.Windows.Forms.DragEventArgs]
    {
		$listBox.Items.Add($filename)
	}
    $statusBar.Text = ("List contains $($listBox.Items.Count) items")
}

$form_FormClosed = {
	try
    {
        $listBox.remove_Click($button_Click)
		$listBox.remove_DragOver($listBox_DragOver)
		$listBox.remove_DragDrop($listBox_DragDrop)
        $listBox.remove_DragDrop($listBox_DragDrop)
		$form.remove_FormClosed($Form_Cleanup_FormClosed)
	}
	catch [Exception]
    { }
}


### Wire up events ###

$button.Add_Click($button_Click)
$listBox.Add_DragOver($listBox_DragOver)
$listBox.Add_DragDrop($listBox_DragDrop)
$form.Add_FormClosed($form_FormClosed)


#### Show form ###

[void] $form.ShowDialog()