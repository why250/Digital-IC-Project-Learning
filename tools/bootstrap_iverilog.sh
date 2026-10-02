#!/usr/bin/env bash
# Extract the public EPEL RPM inside this project; no root/system installation.
set -euo pipefail
project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
install_dir="$project_dir/.tools/iverilog"
package=iverilog-12.0-12.el9.x86_64.rpm
url="https://dl.fedoraproject.org/pub/epel/9/Everything/x86_64/Packages/i/$package"
for tool in curl rpm rpm2cpio cpio; do command -v "$tool" >/dev/null; done
[[ "$(uname -m)" == x86_64 ]] || { echo "This bootstrap targets EL9 x86_64" >&2; exit 2; }
mkdir -p "$install_dir/root"
if [[ ! -f "$install_dir/$package" ]]; then
    curl --fail --location --retry 2 --max-time 120 "$url" -o "$install_dir/$package"
fi
# Check RPM digests. Repository signing key verification is not claimed here.
rpm --checksig --nosignature "$install_dir/$package"
(cd "$install_dir/root" && rpm2cpio "$install_dir/$package" | cpio -idm --quiet)
test -x "$install_dir/root/usr/bin/iverilog"
"$install_dir/root/usr/bin/iverilog" -B "$install_dir/root/usr/lib64/ivl" -V
printf '%s\n' "$url" > "$install_dir/source-url.txt"
sha256sum "$install_dir/$package" > "$install_dir/package-sha256.txt"
echo "IVERILOG_PROJECT_INSTALL_COMPLETE"
