#!/usr/bin/env bash
# รัน local web server สำหรับทดสอบหน้ารายงาน
#
# จำเป็นต้องเปิดผ่าน web server เพราะ index.html โหลด reports.json ด้วย fetch()
# ซึ่งเบราว์เซอร์จะบล็อกเมื่อเปิดไฟล์แบบ file:// โดยตรง
#
# วิธีใช้:
#   ./serve.sh              # ใช้ port 8891 (ถ้าไม่ว่างจะขยับไป port ถัดไปให้เอง)
#   ./serve.sh 9000         # ระบุ port เอง
#   NO_OPEN=1 ./serve.sh    # ไม่ต้องเปิดเบราว์เซอร์ให้อัตโนมัติ

set -euo pipefail

HOST=127.0.0.1
PORT="${1:-${PORT:-8891}}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v python3 >/dev/null 2>&1; then
    echo "ไม่พบ python3 — ต้องติดตั้ง python3 ก่อน" >&2
    exit 1
fi

port_busy() {
    lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1
}

# ขยับหา port ว่าง เผื่อมี server อื่นค้างอยู่
attempts=0
while port_busy "$PORT"; do
    echo "port $PORT ถูกใช้งานอยู่แล้ว — ลอง $((PORT + 1))"
    PORT=$((PORT + 1))
    attempts=$((attempts + 1))
    if [ "$attempts" -ge 20 ]; then
        echo "หา port ว่างไม่เจอ ลองระบุเอง เช่น ./serve.sh 9000" >&2
        exit 1
    fi
done

URL="http://$HOST:$PORT/index.html"

echo "โฟลเดอร์ : $DIR"
echo "เปิดที่   : $URL"
echo "กด Ctrl+C เพื่อหยุด server"
echo

if [ "${NO_OPEN:-}" != "1" ] && command -v open >/dev/null 2>&1; then
    (sleep 1 && open "$URL") &
fi

# exec เพื่อให้ Ctrl+C ส่งถึง python ตรง ๆ และหยุดได้ทันที
exec python3 -m http.server "$PORT" --bind "$HOST" --directory "$DIR"
