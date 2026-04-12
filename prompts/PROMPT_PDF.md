> rm -f SEMINAR.pdf && pandoc SEMINAR.md -o SEMINAR.pdf --pdf-engine=/opt/homebrew/bin/weasyprint; echo "exit:$?"; ls -lhT SEMINAR.pdf
