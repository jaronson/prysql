prysql
======

Prysql is an extension to [Pry](http://github.com/pry/pry) providing a direct SQL interface within
the pry console. Only Mysql is supported at present. Features include:

* Subcommand shortcuts (search columns by pattern, show counts across all databases, etc.)
* Result formatting ala the mysql console (with colors!)
* Search highlighting
* Table & column completion
* Query editor integration using $EDITOR
* Ability to assign output of queries to local variables
* Toggle-able SQL shell

### Querying

Excute subcommands or SQL queries within your pry session by using
the `prysql` command:

    pry(main)> prysql search-columns user
    +----------------------------+-------------------------------+--------------+--------+-----------+
    | table                      | column                        | type         | null?  | default   |
    +----------------------------+-------------------------------+--------------+--------+-----------+
    | notices                    | user_id                       | int          | YES    | NULL      |
    | accounts                   | username                      | varchar(255) | YES    | 0         |
    +----------------------------+-------------------------------+--------------+--------+-----------+

    pry(main)> prysql SELECT id, email FROM users LIMIT 1
    +--------+------------------+
    | id     | email            |
    +--------+------------------+
    | 10000  | user@example.com |
    +--------+------------------+

Toggle `prysql-mode` (aliased as `sql-mode`) to get new prompt and run SQL queries directly:

  pry(main)> sql-mode
  prysql root@localhost [app_dev]> DESCRIBE schema_migrations
  +---------+--------------+------+-----+---------+-------+
  | Field   | Type         | Null | Key | Default | Extra |
  +---------+--------------+------+-----+---------+-------+
  | version | varchar(255) | NO   | PRI | NULL    |       |
  +---------+--------------+------+-----+---------+-------+

### Subcommands
  use              Switch to a new schema.
  edit             Open a new temp file with $EDITOR for query editing to be run on close.
  show-columns     Show columns for a given table (in alphabetical order).
  search-columns   Search across all tables for a column.
  count            Print the record count for a given table.
  show-all-counts  Print counts across all tables.

### TODO
* Add support for more databases (Postgres, sqlite, etc.)
* Setup Prysql from ActiveRecord configuration
* Increase test coverage
