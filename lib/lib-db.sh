
function db_write_info() {
  local work_id="$1"
  local work_name="$2"
  local work_circle="$3"
  local file_count="$4"
  local db_file="$5"
  local purchase_date="$6"

  if [ -z "$db_file" ]; then
    echo "no db file provided"
    return 1
  fi

  # 检查是否提供了所有必需的参数
  if [ -z "$work_id" ] || [ -z "$work_name" ] || [ -z "$work_circle" ] || [ -z "$file_count" ]; then
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

  # Ensure table exists with full schema (including purchase_date)
  sqlite3 -batch -bail "$db_file" "CREATE TABLE IF NOT EXISTS works (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    circle TEXT,
    file_count INTEGER DEFAULT 0,
    purchase_date TEXT
  );"

  # Migrate existing tables that may not yet have the purchase_date column
  col_exists=$(sqlite3 "$db_file" \
    "SELECT COUNT(*) FROM pragma_table_info('works') WHERE name='purchase_date';")
  if [ "$col_exists" = "0" ]; then
    sqlite3 "$db_file" "ALTER TABLE works ADD COLUMN purchase_date TEXT;"
  fi

  # Escape single quotes for safe SQL interpolation
  local safe_name="${work_name//\'/\'\'}"
  local safe_circle="${work_circle//\'/\'\'}"
  local safe_date="${purchase_date//\'/\'\'}"

  sqlite3 -batch -bail "$db_file" \
    "INSERT OR REPLACE INTO works (id, name, circle, file_count, purchase_date) VALUES ('$work_id', '$safe_name', '$safe_circle', $file_count, '$safe_date');"

  if [ $? -eq 0 ]; then
    echo "write '$work_id' into '$db_file'。"
  else
    echo "error writing to database"
    return 1
  fi
}

function db-search-id(){
  local work_id="$1"
  local db_file="$2"

  if [ -z "$db_file" ]; then
    echo "no db file provided"
    return 1
  fi

  if [ -z "$work_id" ]; then
    echo "missing work id"
    return 1
  fi

  sqlite3 -batch -bail "$db_file" << EOF
SELECT id, name, circle, file_count, purchase_date FROM works WHERE id = '$work_id';
EOF

  if [ $? -ne 0 ]; then
    echo "error querying database"
    return 1
  fi
}
