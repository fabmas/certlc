function ConvertFrom-EmlToHtml
{
    [CmdletBinding()]

    Param
    (
        [Parameter(ParameterSetName="Path", Position=0, Mandatory=$True)]
        [String]$Path,

        [Parameter(ParameterSetName="LiteralPath", Mandatory=$True)]
        [String]$LiteralPath,

        [Parameter(ParameterSetName="FileInfo", Mandatory=$True, ValueFromPipeline=$True)]
        [System.IO.FileInfo]$Item
    )

    Process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            "Path"        { $files = Get-ChildItem -Path $Path }
            "LiteralPath" { $files = Get-ChildItem -LiteralPath $LiteralPath }
            "FileInfo"    { $files = $Item }
        }

        $files | % {
            # Work out file names
            $emlFn  = $_.FullName
            $htmlFn = $emlFn -replace '\.eml$', '.html'

            # Skip non-.msg files
            if ($emlFn -notlike "*.eml") {
                Write-Verbose "Skipping $_ (not an .eml file)..."
                return
            }

            # Do not try to overwrite existing files
            if (Test-Path -LiteralPath $htmlFn) {
                Write-Verbose "Skipping $_ (.html already exists)..."
                return
            }

            # Read EML
            Write-Verbose "Reading $_..."
            $adoDbStream = New-Object -ComObject ADODB.Stream
            $adoDbStream.Open()
            $adoDbStream.LoadFromFile($emlFn)
            $cdoMessage = New-Object -ComObject CDO.Message
            $cdoMessage.DataSource.OpenObject($adoDbStream, "_Stream")

            # Generate HTML
            Write-Verbose "Generating HTML..."
            $html = "<!DOCTYPE html>`r`n"
            $html += "<html>`r`n"
            $html += "<head>`r`n"
            $html += "<meta charset=`"utf-8`">`r`n"
            $html += "<title>" + $cdoMessage.Subject + "</title>`r`n"
            $html += "</head>`r`n"
            $html += "<body style=`"font-family: sans-serif; font-size: 11pt`">`r`n"
            $html += "<div style=`"margin-bottom: 1em;`">`r`n"
            $html += "<strong>From: </strong>" + $cdoMessage.From + "<br>`r`n"
            $html += "<strong>Sent: </strong>" + $cdoMessage.SentOn + "<br>`r`n"
            $html += "<strong>To: </strong>" + $cdoMessage.To + "<br>`r`n"
            if ($cdoMessage.CC -ne "") {
                $html += "<strong>Cc: </strong>" + $cdoMessage.CC + "<br>`r`n"
            }
            if ($cdoMessage.BCC -ne "") {
                $html += "<strong>Bcc: </strong>" + $cdoMessage.BCC + "<br>`r`n"
            }
            $html += "<strong>Subject: </strong>" + $cdoMessage.Subject + "<br>`r`n"
            $html += "</div>`r`n"
            if ($cdoMessage.HTMLBody -ne "") {
                $html += "<div>`r`n"
                $html += $cdoMessage.HTMLBody + "`r`n"
                $html += "</div>`r`n"
            } else {
                $html += "<div><pre>"
                $html += $cdoMessage.TextBody
                $html += "</pre></div>`r`n"
            }
            $html += "</body>`r`n"
            $html += "</html>`r`n"

            # Write HTML
            Write-Verbose "Saving HTML..."
            Add-Content -LiteralPath $htmlFn $html

            # Output to pipeline
            Get-ChildItem -LiteralPath $htmlFn
        }
    }

    End
    {
        Write-Verbose "Done."
    }
}