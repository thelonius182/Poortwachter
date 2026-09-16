$anyDeskLog = 'C:\ProgramData\AnyDesk\ad_svc.trace'
$teamViewerLog = 'C:\Program Files (x86)\TeamViewer\TeamViewer15_Logfile.log'
$claimFile = 'C:\ProgramData\NipperClaim\claim.json'

$active = @{
    AnyDesk    = @{}
    TeamViewer = @{}
    Splashtop  = @{}
}

$lastStateKey = $null


function Get-ClaimStatus {

    if (-not (Test-Path $claimFile)) {
        return [pscustomobject]@{
            Exists    = $false
            Valid     = $false
            Error     = $false
            User      = $null
            ClaimedAt = $null
            ExpiresAt = $null
        }
    }

    try {
        $claim = Get-Content $claimFile -Raw |
            ConvertFrom-Json

        if (
            [string]::IsNullOrWhiteSpace($claim.user) -or
            [string]::IsNullOrWhiteSpace($claim.claimed_at) -or
            [string]::IsNullOrWhiteSpace($claim.expires_at)
        ) {
            throw 'Claim bevat niet alle verplichte velden.'
        }

        $claimedAt = [datetimeoffset]::Parse($claim.claimed_at)
        $expiresAt = [datetimeoffset]::Parse($claim.expires_at)

        return [pscustomobject]@{
            Exists    = $true
            Valid     = ($expiresAt -gt [datetimeoffset]::Now)
            Error     = $false
            User      = $claim.user
            ClaimedAt = $claimedAt
            ExpiresAt = $expiresAt
        }
    }
    catch {
        return [pscustomobject]@{
            Exists    = $true
            Valid     = $false
            Error     = $true
            User      = $null
            ClaimedAt = $null
            ExpiresAt = $null
        }
    }
}


function Show-SystemState {

    $claim = Get-ClaimStatus

    $ad = $active.AnyDesk.Count
    $tv = $active.TeamViewer.Count
    $sp = $active.Splashtop.Count

    $total = $ad + $tv + $sp

    $tools = @()

    if ($ad -gt 0) {
        $tools += "AnyDesk($ad)"
    }

    if ($tv -gt 0) {
        $tools += "TeamViewer($tv)"
    }

    if ($sp -gt 0) {
        $tools += "Splashtop($sp)"
    }

    $toolText = $tools -join ','


    if ($claim.Error) {

        $state = 'FOUT_CLAIMBESTAND'

        $stateKey = "$state|$total|$toolText"

        if ($stateKey -ne $script:lastStateKey) {

            Write-Host (
                '{0}  STATE {1} sessions={2} tools={3}' -f
                (Get-Date -Format 'HH:mm:ss'),
                $state,
                $total,
                $toolText
            )

            $script:lastStateKey = $stateKey
        }

        return
    }


    if ($total -gt 1) {

        $state = 'FOUT_MEERDERE_SESSIES'

        $stateKey = "$state|$total|$toolText|$($claim.User)"

        if ($stateKey -ne $script:lastStateKey) {

            Write-Host (
                '{0}  STATE {1} sessions={2} tools={3} claim={4}' -f
                (Get-Date -Format 'HH:mm:ss'),
                $state,
                $total,
                $toolText,
                $claim.User
            )

            $script:lastStateKey = $stateKey
        }

        return
    }


    if (-not $claim.Valid) {

        if ($total -eq 0) {

            $state = 'VRIJ'

            $stateKey = $state

            if ($stateKey -ne $script:lastStateKey) {

                Write-Host (
                    '{0}  STATE VRIJ' -f
                    (Get-Date -Format 'HH:mm:ss')
                )

                $script:lastStateKey = $stateKey
            }
        }
        else {

            $state = 'FOUT_SESSIE_ZONDER_CLAIM'

            $stateKey = "$state|$toolText"

            if ($stateKey -ne $script:lastStateKey) {

                Write-Host (
                    '{0}  STATE {1} tool={2}' -f
                    (Get-Date -Format 'HH:mm:ss'),
                    $state,
                    $toolText
                )

                $script:lastStateKey = $stateKey
            }
        }

        return
    }


    if ($total -eq 0) {

        $state = 'WACHT_OP_VERBINDING'

        $stateKey = "$state|$($claim.User)|$($claim.ExpiresAt)"

        if ($stateKey -ne $script:lastStateKey) {

            Write-Host (
                '{0}  STATE {1} user={2} expires={3}' -f
                (Get-Date -Format 'HH:mm:ss'),
                $state,
                $claim.User,
                $claim.ExpiresAt.ToString('HH:mm:ss')
            )

            $script:lastStateKey = $stateKey
        }

        return
    }


    $state = 'IN_GEBRUIK'

    $stateKey = "$state|$($claim.User)|$toolText"

    if ($stateKey -ne $script:lastStateKey) {

        Write-Host (
            '{0}  STATE {1} user={2} tool={3}' -f
            (Get-Date -Format 'HH:mm:ss'),
            $state,
            $claim.User,
            $toolText
        )

        $script:lastStateKey = $stateKey
    }
}


# -------------------------
# AnyDesk watcher
# -------------------------

$anyDeskJob = Start-Job -ArgumentList $anyDeskLog -ScriptBlock {

    param($logFile)

    Get-Content $logFile -Tail 0 -Wait |
        ForEach-Object {

            $line = $_

            if (
                $line -match
                'gsvc\s+\d+\s+\d+\s+(\d+)\s+app\.session\s+- 5: Entering processing loop\.'
            ) {
                [pscustomobject]@{
                    Tool    = 'AnyDesk'
                    Action  = 'START'
                    Session = $Matches[1]
                }
            }

            if (
                $line -match
                'gsvc\s+\d+\s+\d+\s+(\d+)\s+app\.session\s+- 5: Processing done\.'
            ) {
                [pscustomobject]@{
                    Tool    = 'AnyDesk'
                    Action  = 'END'
                    Session = $Matches[1]
                }
            }
        }
}


# -------------------------
# TeamViewer watcher
# -------------------------

$teamViewerJob = Start-Job -ArgumentList $teamViewerLog -ScriptBlock {

    param($logFile)

    Get-Content $logFile -Tail 0 -Wait |
        ForEach-Object {

            $line = $_

            if (
                $line -match
                'StartProcessingCommands Start processing commands for session (-?\d+)'
            ) {
                [pscustomobject]@{
                    Tool    = 'TeamViewer'
                    Action  = 'START'
                    Session = $Matches[1]
                }
            }

            if (
                $line -match
                'WorkstationLocker::OnSessionEnd:.*TVSessionID:\s*(-?\d+)'
            ) {
                [pscustomobject]@{
                    Tool    = 'TeamViewer'
                    Action  = 'END'
                    Session = $Matches[1]
                }
            }
        }
}


# -------------------------
# Splashtop initialisatie
# -------------------------

$splashtopCount = @(
    Get-Process -Name 'SRApp' -ErrorAction SilentlyContinue
).Count

$splashtopInactiveSince = $null

if ($splashtopCount -gt 0) {
    $active.Splashtop['process'] = Get-Date

    Write-Host (
        '{0}  START Splashtop session=process' -f
        (Get-Date -Format 'HH:mm:ss')
    )
}


# Eerste status
Show-SystemState


# -------------------------
# Hoofdloop
# -------------------------

try {

    while ($true) {

        # AnyDesk en TeamViewer events
        foreach ($job in @($anyDeskJob, $teamViewerJob)) {

            $events = @(Receive-Job $job)

            foreach ($event in $events) {

                if ($event.Action -eq 'START') {

                    $active[$event.Tool][$event.Session] = Get-Date

                    Write-Host (
                        '{0}  START {1} session={2}' -f
                        (Get-Date -Format 'HH:mm:ss'),
                        $event.Tool,
                        $event.Session
                    )

                    Show-SystemState
                }


                if ($event.Action -eq 'END') {

                    if (
                        $active[$event.Tool].ContainsKey(
                            $event.Session
                        )
                    ) {

                        $active[$event.Tool].Remove(
                            $event.Session
                        )

                        Write-Host (
                            '{0}  END   {1} session={2}' -f
                            (Get-Date -Format 'HH:mm:ss'),
                            $event.Tool,
                            $event.Session
                        )

                        Show-SystemState
                    }
                }
            }
        }


        # -------------------------
        # Splashtop
        # -------------------------

        $splashtopCount = @(
            Get-Process -Name 'SRApp' -ErrorAction SilentlyContinue
        ).Count


        if ($splashtopCount -gt 0) {

            $splashtopInactiveSince = $null

            if (
                -not $active.Splashtop.ContainsKey('process')
            ) {

                $active.Splashtop['process'] = Get-Date

                Write-Host (
                    '{0}  START Splashtop session=process' -f
                    (Get-Date -Format 'HH:mm:ss')
                )

                Show-SystemState
            }
        }
        else {

            if (
                $active.Splashtop.ContainsKey('process')
            ) {

                if ($null -eq $splashtopInactiveSince) {
                    $splashtopInactiveSince = Get-Date
                }

                if (
                    ((Get-Date) - $splashtopInactiveSince).
                        TotalSeconds -ge 5
                ) {

                    $active.Splashtop.Remove('process')

                    Write-Host (
                        '{0}  END   Splashtop session=process' -f
                        (Get-Date -Format 'HH:mm:ss')
                    )

                    $splashtopInactiveSince = $null

                    Show-SystemState
                }
            }
        }


        # Ook opnieuw evalueren als alleen
        # claim.json verandert of verloopt.
        Show-SystemState

        Start-Sleep -Seconds 1
    }
}
finally {

    Stop-Job `
        $anyDeskJob,
        $teamViewerJob `
        -ErrorAction SilentlyContinue

    Remove-Job `
        $anyDeskJob,
        $teamViewerJob `
        -Force `
        -ErrorAction SilentlyContinue
}
