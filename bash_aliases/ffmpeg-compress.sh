#!/usr/bin/env bash
# FFmpeg compress tools
# ffmpeg-compress       — 1080p cap, 30fps, standard GPU encode
# ffmpeg-compress-hard  — 720p, 1.1x speed, hard GPU compress, auto-rotate

ffmpeg-compress() {
  local in="$1"
  [ -z "$in" ] && {
    echo "usage: ffmpeg-compress <input-file>"
    return 1
  }

  local out="${in%.*}_compressed.mp4"

  ffmpeg -hide_banner -y -i "$in" \
    -map_metadata 0 \
    -vf "scale='min(1920,iw)':'min(1920,ih)':force_original_aspect_ratio=decrease:force_divisible_by=2,fps=30,format=yuv420p" \
    -c:v h264_nvenc -preset p5 -b:v 2000k \
    -c:a aac -b:a 128k \
    -movflags +faststart \
    "$out"
}
ffmpeg-compress-hard() {
  local in="$1"
  [ -z "$in" ] && {
    echo "usage: ffmpeg-compress-hard <input-file>"
    return 1
  }

  local base out rotate width height vfilter
  base="${in%.*}"
  out="${base}_720p_1.1x.mp4"

  rotate="$(ffprobe -v error -select_streams v:0 -show_entries side_data=rotation -of default=nw=1:nk=1 "$in" 2>/dev/null | head -n1)"
  width="$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=nw=1:nk=1 "$in" 2>/dev/null | head -n1)"
  height="$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=nw=1:nk=1 "$in" 2>/dev/null | head -n1)"

  if [ "$rotate" = "-90" ] || [ "$rotate" = "90" ] || [ "${width:-0}" -lt "${height:-1}" ]; then
    echo "[ffmpeg-compress-hard] vertical/rotated video detected — applying transpose"
    vfilter="hwdownload,format=nv12,transpose=1,scale=-2:720,fps=30,setpts=PTS/1.1"
  else
    echo "[ffmpeg-compress-hard] landscape video — skipping transpose"
    vfilter="hwdownload,format=nv12,scale=-2:720,fps=30,setpts=PTS/1.1"
  fi

  ffmpeg -hide_banner -y -noautorotate \
    -hwaccel cuda -hwaccel_output_format cuda \
    -i "$in" \
    -filter_complex "[0:v]${vfilter}[v];[0:a]atempo=1.1[a]" \
    -map "[v]" -map "[a]" \
    -c:v h264_nvenc -preset p5 -rc vbr -cq 30 -b:v 0 -maxrate 2M -bufsize 4M \
    -pix_fmt yuv420p \
    -c:a aac -b:a 96k \
    -movflags +faststart \
    "$out"
}
