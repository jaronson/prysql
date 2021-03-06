prysql
======

Prysql is an extension to [Pry](http://github.com/pry/pry) that provides a SQL interface within
your session. Only Mysql is supported at present. Features include:

* Subcommand shortcuts (search columns by pattern, show counts across all tables, etc.)
* Result formatting ala the mysql console (with colors!)
* Search highlighting
* Table & column completion
* Query editor integration using $EDITOR
* Ability to assign output of queries to local variables
* Toggle-able SQL shell

### Banner

    Usage:
      prysql [COMMAND] [ARGUMENTS] [--vertical]
      prysql [SQL]

    Pass a command name or SQL query (unquoted) directly to prysql.

    Examples:
      `prysql count users`
      `prysql SELECT id, email FROM users`
      `local_variable = prysql count zip_codes`
      `local_variable = prysql SELECT * FROM zip_codes`

    Available commands:
       info             Print the current Mysql2 client info.                e.g.: `prysql info`                                                                                   
       setup            Setup the prysql interface.                          e.g.: `prysql setup { host: "localhost", username: "root", password: "p12345", database: "testdb" }`  
       use              Switch to the given schema.                          e.g.: `prysql use db_name`                                                                            
       edit             Open a temp file with $EDITOR & run query on close.  e.g.: `prysql edit`                                                                                   
       show-columns     Show columns for a given table.                      e.g.: `prysql show-columns users`                                                                     
       search-columns   Search across all tables for a column or substring.  e.g.: `prysql search-columns substr`                                                                  
       count            Print the record count for a given table.            e.g.: `prysql count users`                                                                            
       show-all-counts  Print counts across all tables.                      e.g.: `prysql show-all-counts`                                                                        
       execute          Execute a SQL query.                                 e.g.: `prysql execute SELECT * FROM users`                                                            

    options:

        -v, --vertical      Print output in vertical format.
        -h, --help          Show this message.

### Setup

Put this somewhere in your .pryrc (or you can call `prysql setup` from pry):

    Prysql.setup({
      :username => 'your-username',
      :password => 'your-password',
      :database => 'your-database'
    })

### Subcommands

Excute subcommands within your pry session by using the `prysql` command:

    pry(main)> prysql search-columns user
    +----------------------------+-------------------------------+--------------+--------+-----------+
    | table                      | column                        | type         | null?  | default   |
    +----------------------------+-------------------------------+--------------+--------+-----------+
    | notices                    | user_id                       | int          | YES    | NULL      |
    | accounts                   | username                      | varchar(255) | YES    | 0         |
    +----------------------------+-------------------------------+--------------+--------+-----------+

If we were running in the console, the search string `user` would be highlighted in the results above.

### Querying

Execute SQL statements with the `prysql` command:

    pry(main)> prysql SELECT id, email FROM users LIMIT 1
    +--------+------------------+
    | id     | email            |
    +--------+------------------+
    | 10000  | user@example.com |
    +--------+------------------+

### SQL Mode

Toggle `prysql-mode` (aliased as `sql-mode`) to get a new prompt and run SQL queries directly:

    pry(main)> sql-mode
    prysql root@localhost [app_dev]> DESCRIBE schema_migrations
    +---------+--------------+------+-----+---------+-------+
    | Field   | Type         | Null | Key | Default | Extra |
    +---------+--------------+------+-----+---------+-------+
    | version | varchar(255) | NO   | PRI | NULL    |       |
    +---------+--------------+------+-----+---------+-------+

### TODO

* Add database support (Postgres, sqlite, etc.)
* Allow for color customization
* Automatic setup from ActiveRecord configuration if present
* Increase test coverage
