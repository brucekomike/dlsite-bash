
function db_write_info() {
  local work_id="$1"
  local work_name="$2"
  local work_intro="$3"
  local file_count="$4"
  local db_file="$5"

  if [ -z "$db_file" ]; then
    echo "no db file provided"
    return 1
  fi

  # 检查是否提供了所有必需的参数
  if [ -z "$work_id" ] || [ -z "$work_name" ] || [ -z "$work_intro" ] || [ -z "$file_count" ]; then
    echo "missing parameters"
    return 1
  fi

  if ! [[ "$work_id" =~ ^[a-zA-Z0-9]+$ ]]; then
    echo "woring id must be alphanumeric"
    return 1
  fi

  # 确保 file_count 是数字
  if ! [[ "$file_count" =~ ^[0-9]+$ ]]; then
    echo "woring file_count must be a number"
    return 1
  fi

  sqlite3 -batch -bail "$db_file" <<EOF
CREATE TABLE IF NOT EXISTS works (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    intro TEXT,
    file_count INTEGER DEFAULT 0
);

INSERT OR REPLACE INTO works (id, name, intro, file_count) VALUES ('$work_id', '$work_name', '$work_intro', $file_count);
EOF

  if [ $? -eq 0 ]; then
    echo "write '$work_id' into '$db_file'。"
  else
    echo "error writing to database"
    return 1
  fi
}