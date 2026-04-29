<#
.SYNOPSIS
UserPromptSubmit 훅 — 슬래시 커맨드에 따라 ~/.claude/settings.json 의 모델을 자동 전환한다.

/se:plan, /se:critique                    → claude-opus-4-7
/se:confirm, /se:execute, /se:review      → claude-sonnet-4-6
/se:doc                                   → claude-haiku-4-5-20251001
/se:learn sonnet|opus                     → 인자에 따라 모델 결정
/se:learn rollback|audit|cleanup          → claude-sonnet-4-6
/se:backup, /se:summary, /se:note        → claude-sonnet-4-6
/teacher:ask, /teacher:doc               → claude-sonnet-4-6
#>

$SETTINGS_PATH = "$env:USERPROFILE\.claude\settings.json"

$MODEL_MAP = @(
    @{ Pattern = "/se:(plan|critique)";                       Model = "claude-opus-4-7" },
    @{ Pattern = "/se:(confirm|execute|review)";              Model = "claude-sonnet-4-6" },
    @{ Pattern = "/se:doc\b";                                 Model = "claude-haiku-4-5-20251001" },
    @{ Pattern = "/se:learn\s+sonnet\b";                      Model = "claude-sonnet-4-6" },
    @{ Pattern = "/se:learn\s+opus\b";                        Model = "claude-opus-4-7" },
    @{ Pattern = "/se:learn\s+(rollback|audit|cleanup)\b";    Model = "claude-sonnet-4-6" },
    @{ Pattern = "/se:(backup|summary|note)\b";               Model = "claude-sonnet-4-6" },
    @{ Pattern = "/teacher:(ask|doc)";                        Model = "claude-sonnet-4-6" }
)

$LEARN_NO_ARG_MSG = @"
/se:learn 인자가 없습니다. 사용할 모델을 명시해주세요:
  /se:learn sonnet   -- claude-sonnet-4-6 으로 전환 후 quarantine 검토
  /se:learn opus     -- claude-opus-4-7 으로 전환 후 quarantine 검토
  /se:learn rollback <commit-hash>   -- 이전 자동 반영 롤백
  /se:learn audit    -- 최근 1주일 자동 반영 점검
  /se:learn cleanup  -- 30일 만료 quarantine 아카이브
"@

# stdin 에서 JSON 읽기
$inputJson = [Console]::In.ReadToEnd()

try {
    $data = $inputJson | ConvertFrom-Json
} catch {
    Write-Output '{"decision":"continue"}'
    exit 0
}

if (-not $data -or -not $data.PSObject.Properties["prompt"]) {
    Write-Output '{"decision":"continue"}'
    exit 0
}

$prompt = $data.prompt

# /se:learn 인자 누락 감지
if ($prompt -match "/se:learn(\s*$|\s+(?!sonnet|opus|rollback|audit|cleanup)\S)") {
    $response = [ordered]@{
        decision = "block"
        reason   = $LEARN_NO_ARG_MSG
    }
    Write-Output ($response | ConvertTo-Json -Compress)
    exit 0
}

$targetModel = $null
foreach ($entry in $MODEL_MAP) {
    if ($prompt -match $entry.Pattern) {
        $targetModel = $entry.Model
        break
    }
}

if ($targetModel) {
    try {
        if (Test-Path $SETTINGS_PATH) {
            $raw = Get-Content $SETTINGS_PATH -Raw -Encoding UTF8
            $settings = $raw | ConvertFrom-Json
        } else {
            $settings = [PSCustomObject]@{}
        }
    } catch {
        $settings = [PSCustomObject]@{}
    }

    # PSCustomObject → 해시테이블 변환 후 model 키 설정
    $hash = @{}
    if ($settings -and $settings.PSObject.Properties) {
        $settings.PSObject.Properties | ForEach-Object { $hash[$_.Name] = $_.Value }
    }
    $hash["model"] = $targetModel

    $hash | ConvertTo-Json -Depth 10 | Set-Content $SETTINGS_PATH -Encoding UTF8
}

Write-Output '{"decision":"continue"}'
