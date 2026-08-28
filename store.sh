#!/bin/sh
# 스토어 등록정보 헬퍼 (macOS / Linux) — Windows 의 store.cmd 와 같은 역할.
#
# 등록정보(제목·설명·키워드)만 다룬다. 빌드·업로드는 ./play 다.
#
#   iOS
#     ./store ios status            정본 문서 / 로컬 metadata / App Store 상태
#     ./store ios from-docs         docs/store/apple-store.md -> ios/fastlane/metadata
#     ./store ios from-docs -Force  기존 metadata 를 문서 내용으로 덮어씀
#     ./store ios pull              App Store Connect -> metadata (텍스트만)
#     ./store ios push -DryRun      App Store 에 쓰지 않고 변환까지만 확인
#     ./store ios push              App Store Connect 에 반영
#
#   Android (PowerShell 필요)
#     ./store status / from-docs / pull / push
#
# 정본은 문서다. ios/fastlane/metadata 는 생성물이므로 직접 고치지 말 것 —
# 다음 from-docs 에서 덮어써진다.
#
# ⚠️ App Store 등록정보는 앱 버전에 묶인다. 이름·부제·키워드·설명은 심사 중이거나
#    이미 출시된 버전에서 잠긴다. promotional_text 만 상시 교체 가능하다.

set -eu

LANG=${LANG:-en_US.UTF-8}
LC_ALL=en_US.UTF-8
FASTLANE_SKIP_UPDATE_CHECK=1
FASTLANE_OPT_OUT_USAGE=1
export LANG LC_ALL FASTLANE_SKIP_UPDATE_CHECK FASTLANE_OPT_OUT_USAGE

script=$0
while [ -L "$script" ]; do
  link=$(readlink "$script")
  case $link in
    /*) script=$link ;;
    *)  script=$(dirname "$script")/$link ;;
  esac
done

PLAY_APP_DIR=$(cd "$(dirname "$script")" && pwd)
export PLAY_APP_DIR
APP=$(basename "$PLAY_APP_DIR")
ROOT=$(dirname "$PLAY_APP_DIR")

AUTO=""
if [ -n "${STORE_AUTOMATION:-}" ] && [ -f "$STORE_AUTOMATION/fastlane/Fastfile" ]; then
  AUTO=$STORE_AUTOMATION
elif [ -f "$ROOT/_automation/fastlane/Fastfile" ]; then
  AUTO=$ROOT/_automation
fi

if [ -z "$AUTO" ]; then
  echo "[!] _automation 을 찾을 수 없습니다. 확인한 위치: $ROOT/_automation" >&2
  echo "    다른 곳에 두셨다면 STORE_AUTOMATION 환경변수로 지정하세요." >&2
  exit 1
fi

usage() {
  echo "사용법: ./store.sh ios <status|from-docs|pull|push> [-Force|-DryRun]"
  echo "        ./store.sh <status|from-docs|pull|push>        (Android, PowerShell 필요)"
  echo "  앱    : $APP"
  echo "  경로  : $PLAY_APP_DIR"
  echo "  도구  : $AUTO"
}

[ $# -eq 0 ] && { usage; exit 1; }

if [ "$1" != "ios" ]; then
  # Android 경로는 PowerShell 스크립트가 전담한다(맥에서는 pwsh 설치 필요).
  if ! command -v pwsh >/dev/null 2>&1; then
    echo "[!] Android 등록정보는 store_listing.ps1(PowerShell)이 처리합니다." >&2
    echo "    맥에서 쓰려면: brew install --cask powershell" >&2
    echo "    iOS 는 PowerShell 없이 동작합니다: ./store.sh ios $1" >&2
    exit 1
  fi
  exec pwsh -NoProfile -File "$AUTO/store_listing.ps1" "$@" -Apps "$APP" -Root "$ROOT"
fi

shift
[ $# -eq 0 ] && { usage; exit 1; }

cmd=$1
shift

case $cmd in
  status)    lane=status ;;
  from-docs) lane=from_docs ;;
  init|init-docs|init_docs) lane=init_docs ;;
  pull)      lane=pull ;;
  push)      lane=push ;;
  iaps|iap)  lane=iaps ;;
  *) echo "[!] 알 수 없는 명령: $cmd" >&2; usage; exit 1 ;;
esac

# store.cmd 의 PowerShell 스타일 플래그를 fastlane 옵션으로 옮긴다.
opts=""
for arg in "$@"; do
  case $arg in
    -Force|--force|-f)     opts="$opts force:true" ;;
    -DryRun|--dry-run|-n)  opts="$opts dry_run:true" ;;
    *) echo "[!] 알 수 없는 옵션: $arg" >&2; exit 1 ;;
  esac
done

cd "$AUTO"
# shellcheck disable=SC2086
exec bundle exec fastlane ios "$lane" $opts
