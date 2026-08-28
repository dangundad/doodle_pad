#!/bin/sh
# 스토어 배포 헬퍼 (macOS / Linux) — Windows 의 play.cmd 와 같은 역할.
#
# 실제 로직은 _automation/fastlane/Fastfile 에 있다. 이 파일은 프로젝트 경로만
# 넘기는 얇은 래퍼라, lane 을 고칠 때 50개 사본을 편집할 일이 없다.
#
#   Android
#     ./play validate                 Play 에 반영하지 않고 검증만
#     ./play metadata                 등록정보 반영
#     ./play internal                 빌드 + 내부 테스트
#     ./play production               빌드 + 프로덕션 (기본 draft)
#     ./play promote to:production    재빌드 없이 트랙 승격
#
#   iOS
#     ./play ios info                 ASC API 키·권한 확인
#     ./play ios beta                 빌드 + TestFlight
#     ./play ios release              빌드 + App Store (심사 제출은 콘솔에서)
#
#   iOS 빌드 번호는 자동이다. TestFlight 에 이미 올라간 번호를 확인해 필요하면
#   하나 올린다(pubspec.yaml 은 고치지 않는다). 같은 마케팅 버전에서 번호를
#   재사용하면 Apple 이 거부하는데, 그 실패는 10분짜리 빌드가 끝난 뒤에야
#   나오기 때문이다. 직접 정하려면 build_number:N 으로 덮어쓴다.
#
#   공통 옵션: dry_run:true / build_number:N
#     Android  aab:<절대경로> / status:completed / rollout:0.1 / name:<트랙>
#     iOS      ipa:<절대경로> / build_args:"--dart-define=K=V"
#
#   ⚠️ 경로 인자는 절대경로로 준다. fastlane 은 _automation 에서 실행되므로
#      상대경로는 프로젝트가 아니라 _automation 기준으로 해석된다.

set -eu

# fastlane 은 로케일이 UTF-8 이 아니면 경고를 내고 한글 출력이 깨진다.
LANG=${LANG:-en_US.UTF-8}
LC_ALL=en_US.UTF-8
FASTLANE_SKIP_UPDATE_CHECK=1
FASTLANE_OPT_OUT_USAGE=1
export LANG LC_ALL FASTLANE_SKIP_UPDATE_CHECK FASTLANE_OPT_OUT_USAGE

# 이 스크립트가 있는 곳이 프로젝트. 심볼릭 링크로 호출돼도 실제 위치를 찾는다.
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

# _automation 위치. 한 경로를 박아두면 폴더를 옮기거나 다른 곳에 클론했을 때
# 깨지므로 가까운 곳부터 찾는다.
AUTO=""
if [ -n "${PLAY_AUTOMATION:-}" ] && [ -f "$PLAY_AUTOMATION/fastlane/Fastfile" ]; then
  AUTO=$PLAY_AUTOMATION
elif [ -f "$ROOT/_automation/fastlane/Fastfile" ]; then
  AUTO=$ROOT/_automation
fi

if [ -z "$AUTO" ]; then
  echo "[!] _automation/fastlane/Fastfile 을 찾을 수 없습니다. 확인한 위치:" >&2
  echo "      $ROOT/_automation" >&2
  echo "" >&2
  echo "    다른 곳에 두셨다면 PLAY_AUTOMATION 환경변수로 지정하세요." >&2
  exit 1
fi

cd "$AUTO"

if [ $# -eq 0 ]; then
  echo "사용법: ./play.sh <lane> [옵션]"
  echo "  앱    : $APP"
  echo "  경로  : $PLAY_APP_DIR"
  echo "  도구  : $AUTO"
  echo ""
  exec bundle exec fastlane lanes
fi

exec bundle exec fastlane "$@"
