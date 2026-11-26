#!/usr/bin/env bash
# The selected Runner configuration must agree with the explicit native stage.
set -euo pipefail

if [[ ${DPIP_EQR_PROFILE:-production} == qa ]]; then
  [[ -z ${DPIP_EQR_PRODUCTION_ROOT:-} && -n ${DPIP_EQR_QA_ROOT:-} ]] || {
    printf 'error: Story QA requires a verified QA native stage. Use tool/dev/run_report_sharing.sh.\n' >&2
    exit 1
  }
  [[ -s "$DPIP_EQR_QA_ROOT/ios/EqReportPicStoryQA.xcframework/$DPIP_EQR_SLICE/libeq_report_pic_story_qa.a" ]]
else
  [[ -z ${DPIP_EQR_QA_ROOT:-} ]] || {
    printf 'error: The production configuration rejects the Story QA native stage.\n' >&2
    exit 1
  }
  if [[ -n ${DPIP_EQR_PRODUCTION_ROOT:-} ]]; then
    [[ -s "$DPIP_EQR_PRODUCTION_ROOT/ios/EqReportPic.xcframework/$DPIP_EQR_SLICE/libeq_report_pic.a" ]]
  fi
fi
