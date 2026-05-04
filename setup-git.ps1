# =====================================================
#  INFOSOLUTION 사이트 — Git 셋업 & 원격 업로드 스크립트
#  사용법:
#    1) infosolution-site 폴더에서 Shift+우클릭 -> "여기에서 PowerShell 창 열기"
#    2) 아래 명령으로 한 줄 실행:
#         powershell -ExecutionPolicy Bypass -File .\setup-git.ps1
#  필요한 사전 작업:
#    - GitHub(또는 사내 Git) 계정 보유
#    - 빈 원격 저장소 미리 생성 (README/.gitignore 체크박스 모두 해제)
#    - Windows에 Git for Windows 설치 (https://git-scm.com/download/win)
# =====================================================

$ErrorActionPreference = 'Stop'

function Section($title) {
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor DarkCyan
    Write-Host $title -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor DarkCyan
}

# 0) 위치/도구 사전 점검 -----------------------------------------------------
Section "0. 사전 점검"
Set-Location -LiteralPath $PSScriptRoot
Write-Host "현재 폴더: $((Get-Location).Path)"

try {
    $gv = (& git --version) 2>$null
    Write-Host "Git: $gv"
} catch {
    Write-Host "[X] Git이 설치되어 있지 않습니다. https://git-scm.com/download/win 에서 설치 후 재실행하세요." -ForegroundColor Red
    exit 1
}

# 1) 손상된 .git 폴더 정리 ---------------------------------------------------
Section "1. 기존 .git 폴더 정리"
if (Test-Path '.git') {
    Write-Host "기존 .git 폴더 발견 — 강제 삭제합니다..."
    try {
        # 읽기 전용 / 시스템 속성 해제 후 삭제
        Get-ChildItem -Path '.git' -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
            try { $_.Attributes = 'Normal' } catch {}
        }
        Remove-Item -Path '.git' -Recurse -Force
        Write-Host "  완료" -ForegroundColor Green
    } catch {
        Write-Host "  자동 삭제 실패. 수동으로 .git 폴더를 지운 뒤 다시 실행하세요." -ForegroundColor Red
        Write-Host "    cmd 명령: rmdir /s /q .git" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "  기존 .git 없음 — 진행"
}

# 2) Git 사용자 정보 ---------------------------------------------------------
Section "2. Git 사용자 정보 확인"
$gitName  = (& git config --global user.name)  2>$null
$gitEmail = (& git config --global user.email) 2>$null

if (-not $gitName) {
    $gitName = Read-Host "Git 사용자 이름을 입력하세요 (예: TaeJoon Kim)"
    if ($gitName) { & git config --global user.name $gitName }
}
if (-not $gitEmail) {
    $gitEmail = Read-Host "Git 이메일을 입력하세요 (예: tjkim4247@gmail.com)"
    if ($gitEmail) { & git config --global user.email $gitEmail }
}
Write-Host "user.name : $((git config --global user.name))"
Write-Host "user.email: $((git config --global user.email))"

# 3) 원격 저장소 URL ---------------------------------------------------------
Section "3. 원격 저장소 URL"
Write-Host "사전 준비:" -ForegroundColor Yellow
Write-Host "  - GitHub에서 빈 저장소를 만들고 (Initialize 옵션 모두 해제)"
Write-Host "  - URL을 복사한 뒤 아래에 붙여넣으세요."
Write-Host "  예) https://github.com/USERNAME/infosolution-site.git"
Write-Host ""
$remoteUrl = Read-Host "원격 저장소 URL"
if (-not $remoteUrl) {
    Write-Host "URL이 필요합니다. 종료합니다." -ForegroundColor Red
    exit 1
}

# 4) 초기화 / 커밋 / push ----------------------------------------------------
Section "4. git init / add / commit"
& git init -b main | Out-Host

# 줄끝 처리 권장 설정 (Windows 환경)
& git config core.autocrlf true | Out-Null
& git config core.safecrlf warn | Out-Null

& git add . | Out-Host
& git status --short | Out-Host

$commitMsg = @"
feat: initial commit — INFOSOLUTION 회사 소개 페이지

- 라이트톤 Linear 스타일 단일 HTML 페이지
- 7대 솔루션(ERP/MES/POP/WMS/SPC/MPS-MRP/CMMS) + 컨설팅/운영
- 모바일 반응형 (980/600 두 단계 브레이크포인트)
- 햄버거 드로어 메뉴 (click/touch 동시 지원, ESC/백드롭 닫기)
- IntersectionObserver 기반 reveal 애니메이션 + 안전장치
- CI 로고 흰 배경 투명 처리 (1x/2x Retina 대응)
"@

& git commit -m $commitMsg | Out-Host

Section "5. 원격 연결 & push"
& git remote add origin $remoteUrl | Out-Host
Write-Host "현재 remotes:"
& git remote -v | Out-Host

Write-Host ""
Write-Host "push 시작 — GitHub 인증 창이 뜨면 로그인하세요" -ForegroundColor Yellow
& git push -u origin main

Section "완료!"
Write-Host "원격 저장소 URL: $remoteUrl" -ForegroundColor Green
Write-Host "이후 변경 사항은 다음과 같이 push:" -ForegroundColor Gray
Write-Host "  git add ."
Write-Host "  git commit -m '메시지'"
Write-Host "  git push"
Write-Host ""
