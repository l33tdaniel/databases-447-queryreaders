#!/bin/bash
# ============================================================
# Library Database Rebuild + CSV Import Script with Validation
# ============================================================

DB_FILE="library.db"
CSV_DIR="csvs"
LOG_FILE="import_errors.log"

echo "============================================================"
echo "Rebuilding database schema from library.sql..."
echo "============================================================"
rm -f "$DB_FILE"
sqlite3 "$DB_FILE" < library.sql
if [ $? -ne 0 ]; then
  echo "❌ Failed to rebuild schema from library.sql."
  exit 1
fi

# Enable foreign key checking
sqlite3 "$DB_FILE" "PRAGMA foreign_keys = ON;"

# Clear previous logs
> "$LOG_FILE"

# Function to import a CSV file directly into the target table
import_csv_direct() {
    local csv_file="$1"
    local table_name="$2"

    if [ ! -f "$csv_file" ]; then
        echo "⚠️  File not found: $csv_file — skipping $table_name"
        return
    fi

    echo "Importing $table_name from $csv_file (direct)..."
    tmpfile=$(mktemp)
    # Skip header
    tail -n +2 "$csv_file" > "$tmpfile"

    # Try import and capture errors
    sqlite3 "$DB_FILE" <<EOF 2>>"$LOG_FILE"
.mode csv
.separator ,
.import '$tmpfile' $table_name
EOF

    rm -f "$tmpfile"
}

# Function to import a CSV file into a table with an auto-incrementing primary key
import_csv_auto_pk() {
    local csv_file="$1"
    local table_name="$2"
    # The columns in the CSV file (excluding the auto-incrementing PK)
    local csv_columns_str="$3"
    local csv_columns_types=$(echo "$csv_columns_str" | sed 's/[^,]*/& TEXT/g')
    local select_cols=$(echo "$csv_columns_str" | sed "s/[^,]*/NULLIF(&, '')/g")


    if [ ! -f "$csv_file" ]; then
        echo "⚠️  File not found: $csv_file — skipping $table_name"
        return
    fi

    echo "Importing $table_name from $csv_file (auto PK)..."
    tmpfile=$(mktemp)
    # Skip header
    tail -n +2 "$csv_file" > "$tmpfile"
    
    # Use a temporary table for the import
    local temp_table_name="temp_${table_name}"

    sqlite3 "$DB_FILE" <<EOF 2>>"$LOG_FILE"
.mode csv
.separator ,
-- Create a temporary table that matches the CSV structure
CREATE TABLE ${temp_table_name} (${csv_columns_types});
-- Import the CSV data into the temporary table
.import '$tmpfile' ${temp_table_name}
-- Copy data from the temporary table to the final table, using NULLIF to convert empty strings to NULL
INSERT INTO ${table_name} (${csv_columns_str}) SELECT ${select_cols} FROM ${temp_table_name};
-- Clean up the temporary table
DROP TABLE ${temp_table_name};
EOF

    rm -f "$tmpfile"
}


# ------------------------------------------------------------
# Import all tables in the correct dependency order
# ------------------------------------------------------------
import_csv_direct "$CSV_DIR/books.csv" Book
import_csv_direct "$CSV_DIR/magazines.csv" Magazine
import_csv_direct "$CSV_DIR/dvds.csv" DVD
import_csv_direct "$CSV_DIR/cds.csv" CD
import_csv_direct "$CSV_DIR/videogames.csv" VideoGames

# Use the auto_pk function for tables with auto-incrementing primary keys
import_csv_auto_pk "$CSV_DIR/library_users.csv" LibraryUser "FirstName,LastName,Start_date,end_date,ID"
import_csv_auto_pk "$CSV_DIR/library_staff.csv" LibraryStaff "FirstName,LastName,Start_date,end_date,ID,Position"

# Import checkout and reshelve tables directly as they don't have auto-incrementing PKs
import_csv_direct "$CSV_DIR/book_checkouts.csv" Book_Checkout
import_csv_direct "$CSV_DIR/cd_checkouts.csv" CD_Checkout
import_csv_direct "$CSV_DIR/dvd_checkouts.csv" DVD_Checkout
import_csv_direct "$CSV_DIR/videogame_checkouts.csv" VideoGame_Checkout
import_csv_direct "$CSV_DIR/magazine_checkouts.csv" Magazine_Checkout

# Staff_Reshelves has an auto-incrementing PK
import_csv_auto_pk "$CSV_DIR/staff_reshelves.csv" Staff_Reshelves "Staff_UID,Book_ISBN,DVD_ID,CD_ID,Game_Name,Magazine_ISBN,Reshelve_Date"


echo "============================================================"
echo "Import process finished."
echo "============================================================"

# ------------------------------------------------------------
# Foreign key integrity check
# ------------------------------------------------------------
echo "Checking foreign key integrity..."
ERRORS=$(sqlite3 "$DB_FILE" "PRAGMA foreign_key_check;")

if [ -z "$ERRORS" ]; then
    echo "✅ All foreign key constraints are satisfied."
else
    echo "⚠️  Foreign key violations found:"
    echo "$ERRORS" | tee -a "$LOG_FILE"
fi

echo "============================================================"
echo "Import summary:"
echo " - Database: $DB_FILE"
echo " - CSV Directory: $CSV_DIR"
echo " - Log File: $LOG_FILE"
echo "============================================================"
