#Requires -Modules Pester
# Pester 5.x tests for jump.ps1

BeforeAll {
    Set-StrictMode -Version Latest
    . (Join-Path $PSScriptRoot "../jump.ps1")

    # Use a temp cache file so tests don't touch the real ~/.jumplocations
    $script:realCache = $script:JumpCache
    $script:JumpCache = Join-Path ([System.IO.Path]::GetTempPath()) "jump_test_$(Get-Random).txt"

    # Create temp dirs for jumping
    $script:dirA = Join-Path ([System.IO.Path]::GetTempPath()) "jumptest_alpha_$(Get-Random)"
    $script:dirB = Join-Path ([System.IO.Path]::GetTempPath()) "jumptest_beta_$(Get-Random)"
    New-Item $script:dirA -ItemType Directory | Out-Null
    New-Item $script:dirB -ItemType Directory | Out-Null
}
AfterAll {
    Remove-Item $script:JumpCache -Force -ErrorAction SilentlyContinue
    Remove-Item $script:dirA -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $script:dirB -Recurse -Force -ErrorAction SilentlyContinue
    $script:JumpCache = $script:realCache
}

Describe "_JumpAdd" {
    It "adds a new path to cache" {
        _JumpAdd $script:dirA
        Get-Content $script:JumpCache | Should -Contain $script:dirA
    }

    It "does not add duplicate" {
        _JumpAdd $script:dirA
        _JumpAdd $script:dirA
        $lines = @(Get-Content $script:JumpCache | Where-Object { $_ -eq $script:dirA })
        $lines.Count | Should -Be 1
    }
}

Describe "j" {
    BeforeAll {
        Set-Content $script:JumpCache "$($script:dirA)`n$($script:dirB)"
    }

    It "jumps to unique partial match" {
        j "alpha"
        (Get-Location).Path | Should -Be $script:dirA
    }

    It "returns no match message for unknown query" {
        $out = j "zzznomatch" | Out-String
        $out | Should -Match "No match"
    }

    It "-d removes current dir from cache" {
        Microsoft.PowerShell.Management\Set-Location $script:dirA
        j "-d"
        $lines = Get-Content $script:JumpCache
        $lines | Should -Not -Contain $script:dirA
    }

    It "shows usage with no args" {
        $out = j "" | Out-String
        $out | Should -Match "Usage"
    }
}

Describe "Set-Location cache integration" {
    It "caches dir after Set-Location" {
        Set-Content $script:JumpCache ""
        Set-Location $script:dirB
        Get-Content $script:JumpCache | Should -Contain $script:dirB
    }
}
