#Requires -Modules Pester
# Pester 5.x tests for gitalias.ps1
# Requires git in PATH. Integration tests run real git commands in temp repos.

# Evaluated at discovery time — must be outside BeforeAll for -Skip to work
$script:gitAvailable = [bool](Get-Command git -ErrorAction SilentlyContinue)

BeforeAll {
    Set-StrictMode -Version Latest
    . (Join-Path $PSScriptRoot "../gitalias.ps1")
}

Describe "_GitDefaultBranch" -Skip:(-not $script:gitAvailable) {
    BeforeAll {
        $script:tmpRepo = Join-Path ([System.IO.Path]::GetTempPath()) "gittest_$(Get-Random)"
        New-Item $script:tmpRepo -ItemType Directory | Out-Null
        Push-Location $script:tmpRepo
        git init -b main 2>$null | Out-Null
        git commit --allow-empty -m "init" 2>$null | Out-Null
    }
    AfterAll {
        Pop-Location
        Remove-Item $script:tmpRepo -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "detects main branch" {
        _GitDefaultBranch | Should -Be "main"
    }
}

Describe "standard git alias wrappers" -Skip:(-not $script:gitAvailable) {
    BeforeAll {
        $script:tmpRepo2 = Join-Path ([System.IO.Path]::GetTempPath()) "gittest2_$(Get-Random)"
        New-Item $script:tmpRepo2 -ItemType Directory | Out-Null
        Push-Location $script:tmpRepo2
        git init -b main 2>$null | Out-Null
    }
    AfterAll {
        Pop-Location
        Remove-Item $script:tmpRepo2 -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "gi runs git init (repo already exists — exits 128 or 0)" {
        gi 2>$null
        $LASTEXITCODE | Should -BeIn @(0, 128)
    }

    It "gb lists branches without error" {
        git commit --allow-empty -m "init" 2>$null | Out-Null
        { gb 2>$null } | Should -Not -Throw
    }

    It "glo runs git log --oneline without error" {
        { glo 2>$null } | Should -Not -Throw
    }

    It "gdi runs git diff without error" {
        { gdi 2>$null } | Should -Not -Throw
    }

    It "gdin runs git diff --name-only without error" {
        { gdin 2>$null } | Should -Not -Throw
    }

    It "gr shows remote -v (empty is fine)" {
        { gr 2>$null } | Should -Not -Throw
    }
}

Describe "gstrip" -Skip:(-not $script:gitAvailable) {
    BeforeAll {
        $script:tmpRepo3 = Join-Path ([System.IO.Path]::GetTempPath()) "gittest3_$(Get-Random)"
        New-Item $script:tmpRepo3 -ItemType Directory | Out-Null
        Push-Location $script:tmpRepo3
        git init -b main 2>$null | Out-Null
        Set-Content "file.txt" "hello"
        git add . 2>$null | Out-Null
        git commit -m "first" 2>$null | Out-Null
        Set-Content "file.txt" "world"
        git add . 2>$null | Out-Null
        git commit -m "second" 2>$null | Out-Null
    }
    AfterAll {
        Pop-Location
        Remove-Item $script:tmpRepo3 -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "gstrip collapses history to single commit" {
        gstrip 2>$null
        $count = (git log --oneline 2>$null | Measure-Object).Count
        $count | Should -Be 1
    }

    It "gstrip preserves file content" {
        Get-Content "file.txt" | Should -Be "world"
    }
}
