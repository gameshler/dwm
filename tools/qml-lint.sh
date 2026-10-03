#!/bin/sh
# Quickshell resolves `import qs.core` through a module tree it generates at
# runtime under $XDG_RUNTIME_DIR, so bare qmllint reports every local type as
# unresolved. This rebuilds the same tree in a temp directory, which needs no
# running shell and no X server.
set -eu

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
qml_dir="$repo_dir/config/quickshell"

qmllint="${QMLLINT:-}"
if [ -z "$qmllint" ]; then
	for candidate in qmllint /usr/lib/qt6/bin/qmllint /usr/lib/qt6/qmllint; do
		if command -v "$candidate" >/dev/null 2>&1; then
			qmllint="$candidate"
			break
		fi
	done
fi
[ -n "$qmllint" ] || {
	printf 'qmllint not found - install qt6-declarative\n' >&2
	exit 1
}

import_path="${QML_IMPORT_PATH:-/usr/lib/qt6/qml}"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

mkdir -p "$work/qs"
printf 'module qs\n' >"$work/qs/qmldir"
ln -s "$qml_dir/shell.qml" "$work/qs/shell.qml"

for dir in "$qml_dir"/*/; do
	[ -d "$dir" ] || continue
	module="$(basename "$dir")"
	mkdir -p "$work/qs/$module"
	printf 'module qs.%s\n' "$module" >"$work/qs/$module/qmldir"

	for file in "$dir"*.qml; do
		[ -f "$file" ] || continue
		type_name="$(basename "$file" .qml)"
		ln -s "$file" "$work/qs/$module/$type_name.qml"
		# Undeclared singletons read as unqualified lookups to qmllint.
		if grep -q '^pragma Singleton' "$file"; then
			printf 'singleton %s 1.0 %s.qml\n' "$type_name" "$type_name" \
				>>"$work/qs/$module/qmldir"
		else
			printf '%s 1.0 %s.qml\n' "$type_name" "$type_name" \
				>>"$work/qs/$module/qmldir"
		fi
	done
done

set -- "$qml_dir/shell.qml"
for dir in "$qml_dir"/*/; do
	[ -d "$dir" ] || continue
	for file in "$dir"*.qml; do
		[ -f "$file" ] || continue
		set -- "$@" "$file"
	done
done

exec "$qmllint" --max-warnings "${QMLLINT_MAX_WARNINGS:-0}" \
	-I "$work" -I "$import_path" "$@"
