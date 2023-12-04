#!/usr/bin/env sh

cd "/Users/gabriel/dcc/informe-memoria" || exit 1

code .
open /Users/gabriel/Library/CloudStorage/GoogleDrive-gabrielrojas@ug.uchile.cl/My\ Drive/uni/10mo\ semestre/CC6907\ -\ Introducción\ al\ Trabajo\ de\ Título/clases/pdfs/02_Entregas.pdf
open /Users/gabriel/Library/CloudStorage/GoogleDrive-gabrielrojas@ug.uchile.cl/My\ Drive/uni/10mo\ semestre/CC6907\ -\ Introducción\ al\ Trabajo\ de\ Título/informe/informe.pdf

tmux new-session -d -s "memoria"
tmux send-keys -t "memoria" "typst watch main.typ" Enter
tmux new-window -t "memoria"
tmux attach -t "memoria"
