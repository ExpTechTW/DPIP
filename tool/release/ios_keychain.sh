#!/usr/bin/env bash
# Hands the runner this team's Apple Development identity, in a throwaway keychain.
#
#     APPLE_DEV_CERT_BASE64=… APPLE_DEV_CERT_PASSWORD=… tool/release/ios_keychain.sh
#
# Called once by .github/workflows/release.yml, before the iOS build. Nothing
# local needs it: a developer's Mac already has the identity in its login
# keychain, which is precisely the thing a GitHub runner does not.
#
# Why this exists
# ───────────────
# The Apple Developer account was filling up with identical certificates —
# TYPE "Development", NAME "Created via API", one or two per push to main —
# and every one of them was already useless the moment it was created.
#
# `-allowProvisioningUpdates` does exactly what its man page promises: "for
# automatically signed targets, xcodebuild will create and update profiles,
# app IDs, and certificates". The runner is ephemeral and its keychain is
# empty, so on every run xcodebuild looks for a signing identity, finds none,
# and creates one. The private key it generates lives on that runner and dies
# with it, so the row left behind in the account can never be used by anything
# ever again. It is not a certificate; it is a tombstone.
#
# The obvious fix — drop `-allowProvisioningUpdates` — does not work. The
# archive still needs a provisioning profile it does not have, and without the
# flag it fails outright with "No profiles for 'com.exptech.dpip.dpip' were
# found". Profile management is the part of that flag we want; certificate
# creation is the part we do not, and there is no way to ask for one without
# the other. The whole man page has two provisioning options and neither of
# them splits it.
#
# Nor can the runner fetch an existing certificate. Apple never held the
# private key: `CertificateCreateRequest` takes a `csrContent`, meaning the
# caller generated the keypair locally and sent Apple only the public half, and
# the `Certificate` resource it hands back has no key attribute at all. A
# certificate downloaded from the portal is, in fastlane's words, "pretty
# useless without a private key".
#
# So the key has to be carried there, and this is what carries it.
#
# Only the *development* half needs this. The export step's distribution
# signing is already solved by Apple's cloud-managed certificates, which keep
# the distribution certificate and its private key server-side — that is what
# `signingStyle: automatic` in ios/ExportOptions.plist plus an Admin API key
# buy. Cloud signing has no development counterpart, and that asymmetry is why
# one half of this pipeline was quietly fine and the other half was not.
#
# What actually proves it worked
# ──────────────────────────────
# Not that the release goes green. It went green before, by minting. The test
# is the certificate count in the account staying flat across a run, and the
# nearest thing this script can check on its own is the assertion at the
# bottom: at least one *valid* identity in the keychain afterwards.
#
# That one check is load-bearing, because every likely way to get the secret
# wrong fails silently otherwise — the release still succeeds, still by
# minting, and nothing anywhere says so. A .p12 exported from Keychain Access's
# "Certificates" category carries the certificate without the private key; an
# expired certificate imports perfectly; a chain that will not validate on a
# fresh keychain imports perfectly too. `security find-identity` reports all
# three as "0 valid identities found" and exits 0, so `set -e` sails past it.
set -euo pipefail

# `:?` rather than a default: an absent secret must stop here, where the
# message says which secret, and not four steps later inside xcodebuild. An
# unset GitHub secret arrives as the empty string, which `:?` also catches.
: "${APPLE_DEV_CERT_BASE64:?set the APPLE_DEV_CERT_BASE64 repository secret}"
: "${APPLE_DEV_CERT_PASSWORD:?set the APPLE_DEV_CERT_PASSWORD repository secret}"
: "${RUNNER_TEMP:?this runs on a GitHub runner}"

keychain="$RUNNER_TEMP/dpip-signing.keychain-db"
# Random, and never leaves this process. It guards a keychain that exists for
# one job on a VM nobody else can reach, so its only real job is to not be a
# constant somebody later decides to reuse somewhere it matters.
keychain_password="$(uuidgen)"
p12="$RUNNER_TEMP/dpip-ios-dev.p12"

printf '%s\n' "$APPLE_DEV_CERT_BASE64" | base64 --decode > "$p12"

security create-keychain -p "$keychain_password" "$keychain"
# `-t 21600` is the inactivity timeout. `-l` locks on sleep as well — it is a
# no-op on a runner that never sleeps, and it is here so that a copy of this
# line pasted onto a laptop does the safe thing rather than the convenient one.
security set-keychain-settings -lt 21600 "$keychain"
security unlock-keychain -p "$keychain_password" "$keychain"

# `-A` would let *any* application use the key. Naming the two binaries that
# need it keeps the grant to the job at hand.
security import "$p12" -k "$keychain" -P "$APPLE_DEV_CERT_PASSWORD" \
  -T /usr/bin/codesign -T /usr/bin/security
rm -f "$p12"

# Without this, codesign puts up a GUI authorisation prompt that no one is
# there to answer, and the build hangs until the job times out rather than
# failing. The partition list is the ACL that says "these Apple tools may use
# this key without asking".
security set-key-partition-list -S apple-tool:,apple: \
  -k "$keychain_password" "$keychain" > /dev/null

# `-s` REPLACES the search list, it does not append — so the existing entries
# have to be read and passed back in. Handing it only the new keychain drops
# the login keychain, and the symptom is a later step failing for reasons that
# have nothing to do with signing.
existing="$(security list-keychains -d user | tr -d '"' | tr -d ' ')"
# shellcheck disable=SC2086
security list-keychains -d user -s "$keychain" $existing

# The assertion this whole file is built around. `-v` means valid identities
# only, so an expired certificate, a certificate with no private key and a
# certificate whose chain will not build all count as zero — which is the same
# three failures listed at the top.
identities="$(security find-identity -v -p codesigning "$keychain")"
printf '%s\n' "$identities"
count="$(printf '%s\n' "$identities" | grep -c '^[[:space:]]*[0-9]\{1,\})' || true)"
if [[ $count -lt 1 ]]; then
  printf '::error::no valid signing identity in the keychain — the archive will '
  printf 'mint a new certificate instead of reusing this one.\n'
  printf 'Check APPLE_DEV_CERT_BASE64 holds a .p12 exported from Keychain Access '
  printf '"My Certificates" (certificate AND private key), that it has not expired, '
  printf 'and that APPLE_DEV_CERT_PASSWORD matches it.\n'
  exit 1
fi

# Everything below is advisory and must never fail the job. A release that dies
# because a diagnostic could not parse a date is a worse outcome than the
# problem this script exists to fix — and `openssl x509 -subject` in particular
# formats its output differently across versions, so nothing here may depend on
# that formatting being one shape.
if ! printf '%s\n' "$identities" | grep -q 'Apple Development'; then
  printf '::warning::the imported identity is not an Apple Development one. '
  printf 'The archive signs for development, so it may still mint a certificate.\n'
fi

expiry="$(security find-certificate -c 'Apple Development' -p "$keychain" 2>/dev/null |
  openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2- || true)"
if [[ -n $expiry ]]; then
  # Certificates last a year, so this expires roughly a year after somebody
  # set it up and forgot about it. Nothing goes red on that day: the archive
  # simply starts minting again and the pile comes back. Thirty days is enough
  # notice to export a new .p12 without it being an emergency.
  now="$(date -u +%s)"
  end="$(date -j -f '%b %d %T %Y %Z' "$expiry" +%s 2>/dev/null ||
    date -d "$expiry" +%s 2>/dev/null || echo 0)"
  if [[ $end -gt 0 ]]; then
    days=$(((end - now) / 86400))
    printf 'signing certificate valid for %s more days (%s)\n' "$days" "$expiry"
    if [[ $days -lt 30 ]]; then
      printf '::warning::the iOS signing certificate expires in %s days. ' "$days"
      printf 'Re-export the .p12 and update APPLE_DEV_CERT_BASE64 before it does, '
      printf 'or CI silently goes back to creating a certificate per run.\n'
    fi
  fi
fi
