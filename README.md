# Library Database Project

This project contains a SQLite database (`library.db`) for managing a library's inventory and user information. The database schema is defined in `library.sql`.

## Project Structure

-   `library.db`: The SQLite database file containing all the library's data.
-   `library.sql`: The SQL script that defines the schema for `library.db`, including tables for books, magazines, DVDs, CDs, users, staff, video games, and checkout/reshelving records.
-   `display_tables.sql`: A SQL script containing `SELECT *` statements for all tables in `library.db`, allowing for a quick overview of their contents.
-   `import_data.sh`: A shell script likely used for importing data into the database.
-   `import_errors.log`: A log file that would contain any errors encountered during data import.
-   `notes.txt`: A text file for miscellaneous notes related to the project.
-   `README.md`: This file, providing an overview of the project.
-   `csvs/`: A directory containing CSV files used for populating the database.
    -   `csvs/library_users.csv`: Contains data for library users.
    -   `csvs/library_staff.csv`: Contains data for library staff.
    -   `csvs/staff_reshelves.csv`: Contains data related to staff reshelving actions.

## How to Use

To view the contents of the database tables, you can use the `display_tables.sql` file with a SQLite client. For example, using the `sqlite3` command-line tool:

```bash
sqlite3 library.db < display_tables.sql
