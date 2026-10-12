# Runs the Phase 0 benchmark matrix and appends result lines to build/bench-results.txt
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root 'build\bench-results.txt'
New-Item -ItemType Directory -Force (Split-Path $out) | Out-Null
Remove-Item $out -ErrorAction SilentlyContinue
function Run($mode, $w, $h, $d, $g, $t = 900) {
    $r = & "$PSScriptRoot\run-bench.ps1" -Mode $mode -Width $w -Height $h -Density $d -Gens $g -TimeoutSec $t
    $r | Out-File $out -Append -Encoding ascii
}
foreach ($d in 0.01, 0.1, 0.3) {
    foreach ($m in 'ext', 'extf', 'mem', 'memf', 'tt', 'sparse') { Run $m 100 100 $d 20 }
}
Run rowclear 10 20 0 2000
foreach ($m in 'mem', 'memf') { Run $m 1000 1000 0.1 3 }
foreach ($d in 0.01, 0.1, 0.3) { Run sparse 1000 1000 $d 2 }
Run tt 1000 1000 0.1 2
'DONE' | Out-File $out -Append -Encoding ascii
