#Requires -Modules Pester
# Pester 5.x test suite for alias.ps1
# Run: Invoke-Pester ./tests/alias.Tests.ps1 -Output Detailed

BeforeAll {
    . (Join-Path $PSScriptRoot "../alias.ps1")
}

# ── _PsHumanSize ─────────────────────────────────────────────────────────────

Describe "_PsHumanSize" {
    It "formats bytes" {
        _PsHumanSize 512     | Should -Be "512B"
    }
    It "formats kilobytes" {
        _PsHumanSize 2048    | Should -Be "2.0K"
    }
    It "formats megabytes" {
        _PsHumanSize 1572864 | Should -Be "1.5M"  # 1.5 * 1MB
    }
    It "formats gigabytes" {
        _PsHumanSize 2147483648 | Should -Be "2.0G"
    }
}

# ── tree ─────────────────────────────────────────────────────────────────────

Describe "tree" {
    BeforeAll {
        $script:tmp = Join-Path ([System.IO.Path]::GetTempPath()) "alias_tree_test_$(Get-Random)"
        New-Item $tmp -ItemType Directory | Out-Null
        New-Item "$tmp/file1.txt"   -ItemType File    | Out-Null
        New-Item "$tmp/subdir"      -ItemType Directory | Out-Null
        New-Item "$tmp/subdir/nested.txt" -ItemType File | Out-Null
        Set-Content "$tmp/file1.txt" "hello"
        Set-Content "$tmp/subdir/nested.txt" "world"
        New-Item "$tmp/.hidden"     -ItemType File    | Out-Null
    }
    AfterAll {
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "prints the root path" {
        $out = tree $tmp | Out-String
        $pat = [regex]::Escape($tmp)
        $out | Should -Match $pat
    }

    It "uses box-drawing connectors" {
        $out = tree $tmp | Out-String
        $out | Should -Match "├── |└── "
    }

    It "shows files and directories" {
        $out = tree $tmp | Out-String
        $out | Should -Match "file1\.txt"
        $out | Should -Match "subdir"
        $out | Should -Match "nested\.txt"
    }

    It "excludes hidden files by default" {
        $out = tree $tmp | Out-String
        $out | Should -Not -Match "\.hidden"
    }

    It "-h shows hidden files" {
        $out = tree $tmp -h | Out-String
        $out | Should -Match "\.hidden"
    }

    It "-u annotates sizes" {
        $out = tree $tmp -u | Out-String
        $out | Should -Match "\[\d"
    }

    It "-t shows only top-level dirs with sizes" {
        $out = tree $tmp -t | Out-String
        $out | Should -Match "subdir"
        $out | Should -Not -Match "nested\.txt"
        $out | Should -Match "\["
    }
}

# ── treed ────────────────────────────────────────────────────────────────────

Describe "treed" {
    BeforeAll {
        $script:tmp2 = Join-Path ([System.IO.Path]::GetTempPath()) "alias_treed_test_$(Get-Random)"
        New-Item $tmp2 -ItemType Directory | Out-Null
        New-Item "$tmp2/a"       -ItemType Directory | Out-Null
        New-Item "$tmp2/b"       -ItemType Directory | Out-Null
        New-Item "$tmp2/a/sub"   -ItemType Directory | Out-Null
        New-Item "$tmp2/file.txt" -ItemType File     | Out-Null
    }
    AfterAll {
        Remove-Item $tmp2 -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "prints root path" {
        $out = treed $tmp2 | Out-String
        $pat = [regex]::Escape($tmp2)
        $out | Should -Match $pat
    }

    It "shows directories" {
        $out = treed $tmp2 | Out-String
        $out | Should -Match "a"
        $out | Should -Match "b"
        $out | Should -Match "sub"
    }

    It "excludes files" {
        $out = treed $tmp2 | Out-String
        $out | Should -Not -Match "file\.txt"
    }

    It "uses box-drawing connectors" {
        $out = treed $tmp2 | Out-String
        $out | Should -Match "├── |└── "
    }
}

# ── d ────────────────────────────────────────────────────────────────────────

Describe "d" {
    BeforeAll {
        $script:tmp3 = Join-Path ([System.IO.Path]::GetTempPath()) "alias_d_test_$(Get-Random)"
        New-Item $tmp3 -ItemType Directory | Out-Null
        New-Item "$tmp3/alpha.txt" -ItemType File | Out-Null
        New-Item "$tmp3/beta.log"  -ItemType File | Out-Null
        New-Item "$tmp3/subdir"    -ItemType Directory | Out-Null
        $script:origLoc = Get-Location
        Set-Location $tmp3
    }
    AfterAll {
        Set-Location $script:origLoc
        Remove-Item $tmp3 -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "lists files, not directories" {
        $out = d | Out-String
        $out | Should -Match "alpha\.txt"
        $out | Should -Not -Match "subdir"
    }

    It "filters by glob" {
        $out = d "*.txt" | Out-String
        $out | Should -Match "alpha\.txt"
        $out | Should -Not -Match "beta\.log"
    }
}

# ── dd ───────────────────────────────────────────────────────────────────────

Describe "dd" {
    BeforeAll {
        $script:tmp4 = Join-Path ([System.IO.Path]::GetTempPath()) "alias_dd_test_$(Get-Random)"
        New-Item $tmp4 -ItemType Directory | Out-Null
        New-Item "$tmp4/dira" -ItemType Directory | Out-Null
        New-Item "$tmp4/dirb" -ItemType Directory | Out-Null
        New-Item "$tmp4/file.txt" -ItemType File | Out-Null
        $script:origLoc4 = Get-Location
        Set-Location $tmp4
    }
    AfterAll {
        Set-Location $script:origLoc4
        Remove-Item $tmp4 -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "lists directories, not files" {
        $out = dd | Out-String
        $out | Should -Match "dira"
        $out | Should -Match "dirb"
        $out | Should -Not -Match "file\.txt"
    }

    It "filters by glob" {
        $out = dd "dira" | Out-String
        $out | Should -Match "dira"
        $out | Should -Not -Match "dirb"
    }
}

# ── dt ───────────────────────────────────────────────────────────────────────

Describe "dt" {
    BeforeAll {
        $script:tmp5 = Join-Path ([System.IO.Path]::GetTempPath()) "alias_dt_test_$(Get-Random)"
        New-Item $tmp5 -ItemType Directory | Out-Null
        New-Item "$tmp5/today.txt" -ItemType File | Out-Null
        $old = New-Item "$tmp5/old.txt" -ItemType File
        $old.LastWriteTime = (Get-Date).AddDays(-5)
        $script:origLoc5 = Get-Location
        Set-Location $tmp5
    }
    AfterAll {
        Set-Location $script:origLoc5
        Remove-Item $tmp5 -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "shows only today's files" {
        $out = dt | Out-String
        $out | Should -Match "today\.txt"
        $out | Should -Not -Match "old\.txt"
    }
}

# ── fr ───────────────────────────────────────────────────────────────────────

Describe "fr" {
    It "returns a string with Free/Used/Total" {
        $out = fr
        $out | Should -Match "Free:"
        $out | Should -Match "Used:"
        $out | Should -Match "Total:"
    }
}

# ── ff / fff ─────────────────────────────────────────────────────────────────

Describe "ff and fff" {
    BeforeAll {
        $script:tmp6 = Join-Path ([System.IO.Path]::GetTempPath()) "alias_ff_test_$(Get-Random)"
        New-Item $tmp6 -ItemType Directory | Out-Null
        New-Item "$tmp6/visible.txt"    -ItemType File | Out-Null
        New-Item "$tmp6/.hidden_file"   -ItemType File | Out-Null
        New-Item "$tmp6/sub"            -ItemType Directory | Out-Null
        New-Item "$tmp6/sub/deep.txt"   -ItemType File | Out-Null
    }
    AfterAll {
        Remove-Item $tmp6 -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "ff finds files recursively" {
        $out = ff "deep" $tmp6
        $out | Should -Not -BeNullOrEmpty
        $out | Should -Match "deep\.txt"
    }

    It "fff finds hidden files" {
        $out = fff "hidden" $tmp6
        $out | Should -Not -BeNullOrEmpty
        $out | Should -Match "hidden_file"
    }
}

# ── psfe ─────────────────────────────────────────────────────────────────────

Describe "psfe" {
    BeforeAll {
        $script:tmp7 = Join-Path ([System.IO.Path]::GetTempPath()) "alias_psfe_test_$(Get-Random)"
        New-Item $tmp7 -ItemType Directory | Out-Null
        1..3 | ForEach-Object { New-Item "$tmp7/f$_.txt" -ItemType File | Out-Null }
        1..2 | ForEach-Object { New-Item "$tmp7/f$_.log" -ItemType File | Out-Null }
    }
    AfterAll {
        Remove-Item $tmp7 -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "groups files by extension" {
        $out = psfe $tmp7 | Out-String
        $out | Should -Match "\.txt"
        $out | Should -Match "\.log"
    }

    It "sorts by count descending (.txt=3 before .log=2)" {
        $lines = psfe $tmp7
        $first = ($lines[0] -split '\s+').Where({ $_ -ne '' })[-1]
        $first | Should -Be "3"
    }
}

# ── loop / loopk (smoke test — just verify they run one iteration) ────────────

Describe "loop / loopk smoke" {
    It "loop runs the command at least once" {
        $ran = $false
        # Run loop with 0s wait and interrupt after first iteration via flag file
        $flag = Join-Path ([System.IO.Path]::GetTempPath()) "loop_test_$(Get-Random).flag"
        $job = Start-Job {
            param($f, $src)
            . $src
            loop 1s "New-Item '$f' -ItemType File -Force | Out-Null"
        } -ArgumentList $flag, (Join-Path $PSScriptRoot "../alias.ps1")
        Start-Sleep -Seconds 2
        Stop-Job $job -ErrorAction SilentlyContinue
        Remove-Job $job -Force -ErrorAction SilentlyContinue
        Test-Path $flag | Should -Be $true
        Remove-Item $flag -Force -ErrorAction SilentlyContinue
    }
}
