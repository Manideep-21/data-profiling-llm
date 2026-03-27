Rscript main.R

$env:GEMINI_API_KEY = "your_key_here"; Invoke-RestMethod -Uri "https://generativelanguage.googleapis.com/v1beta/models?key=$env:GEMINI_API_KEY" -Method Get
