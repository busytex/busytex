# Set strict mode
Set-StrictMode -Version Latest

# Set environment variable
$env:SOURCE_DATE_EPOCH="1234567890"

# Read arguments
$ARXIV_ID = $args[0]
$OUT_DIR = if ($args.Count -gt 1) { $args[1] } else { "." }

# Define working directory
$workdir = Join-Path $OUT_DIR $ARXIV_ID
if (Test-Path $workdir) {
    Remove-Item $workdir -Recurse
}
New-Item -Path $workdir -ItemType Directory | Out-Null

Write-Host "Downloading $ARXIV_ID"
Invoke-WebRequest -Uri "https://arxiv.org/src/$ARXIV_ID" -OutFile (Join-Path $workdir "$ARXIV_ID.tar")

# Assuming downloaded files are always tar for simplicity
$downloaded = Get-ChildItem $workdir -File

Write-Host "Unpacking $($downloaded.Name)"
tar xf $downloaded.FullName -C $workdir

$main_file = Get-ChildItem $workdir -File | Where-Object { $_ | Get-Content | Select-String -Pattern '^\\begin{document}' } | Select-Object -First 1
Write-Host "Using the main file: $($main_file.Name)"

$DIST = Join-Path $PWD "dist-native"
$PDFLATEXFMT = Join-Path $DIST "pdflatex.fmt"
$BUSYTEX = Join-Path $DIST "busytex"
$BUSYTEX_EXE = "$BUSYTEX.exe"
if (!(Test-Path $BUSYTEX_EXE)) {
    New-Item -Path $BUSYTEX_EXE -ItemType HardLink -Value $BUSYTEX
}

# Set environment variables
$env:TEXMFDIST = Join-Path $DIST "texlive\texmf-dist"
$env:TEXMFVAR = Join-Path $DIST "texlive\texmf-dist\texmf-var"
$env:TEXMFCNF = Join-Path $env:TEXMFDIST "web2c"
$env:FONTCONFIG_PATH = $DIST

Push-Location
Set-Location $workdir

# Run commands with redirection to null for cleaner output
& $BUSYTEX_EXE pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFLATEXFMT "$($main_file.Name)" *> $null
& $BUSYTEX_EXE bibtex8 --8bit "$($main_file.BaseName).aux" *> $null
& $BUSYTEX_EXE pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFLATEXFMT "$($main_file.Name)" *> $null
& $BUSYTEX_EXE pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFLATEXFMT "$($main_file.Name)" *> $null

Pop-Location