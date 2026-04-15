ffmpeg -loop 1 -framerate 50 -t 12 -i "RetroHD mit marquisor Socials Beta.png" -f lavfi -t 12 -i anullsrc=channel_layout=stereo:sample_rate=48000 -filter_complex "[0:v]format=rgba,fade=t=in:st=0:d=1,fade=t=out:st=11:d=1,format=yuv420p[vid]" -map '[vid]' -c:v libx265 -crf 16 -preset medium bildsegment_hevc.mkv

