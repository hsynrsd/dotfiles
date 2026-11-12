#!/usr/bin/env bash
# Package the Steel color theme as a .vsix and install it into VS Code.
set -eu
cd "$(dirname "$0")"
v=$(python3 -c 'import json;print(json.load(open("package.json"))["version"])')
out=$(mktemp -d)/steel-theme-$v.vsix
python3 - "$out" <<'PY'
import sys, zipfile, json
pkg = json.load(open("package.json"))
manifest = f'''<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Language="en-US" Id="{pkg["name"]}" Version="{pkg["version"]}" Publisher="{pkg["publisher"]}"/>
    <DisplayName>{pkg["displayName"]}</DisplayName>
    <Description xml:space="preserve">{pkg["description"]}</Description>
    <Categories>Themes</Categories>
    <Properties><Property Id="Microsoft.VisualStudio.Code.Engine" Value="{pkg["engines"]["vscode"]}"/></Properties>
  </Metadata>
  <Installation><InstallationTarget Id="Microsoft.VisualStudio.Code"/></Installation>
  <Dependencies/>
  <Assets><Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true"/></Assets>
</PackageManifest>'''
types = '''<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension=".json" ContentType="application/json"/><Default Extension=".vsixmanifest" ContentType="text/xml"/>
</Types>'''
with zipfile.ZipFile(sys.argv[1], "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("[Content_Types].xml", types)
    z.writestr("extension.vsixmanifest", manifest)
    z.write("package.json", "extension/package.json")
    z.write("themes/steel.json", "extension/themes/steel.json")
PY
code --install-extension "$out" --force
echo "✓ Steel theme installed — pick it with Ctrl+K Ctrl+T"
