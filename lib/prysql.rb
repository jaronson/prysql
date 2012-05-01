PRYSQL_ROOT = File.dirname(__FILE__)
$LOAD_PATH.unshift(PRYSQL_ROOT)

require 'pry'
require 'thor'
require 'coderay'
require 'mysql2'

class Prysql; end

require 'prysql/shell'
require 'prysql/commands'
require 'prysql/interface'
require 'prysql/base'

Pry::Commands.import Prysql::CommandSet
