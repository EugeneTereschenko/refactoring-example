require 'pry'

require_relative 'validators/validators'


class Account
  attr_reader :card, :console, :money
  attr_accessor :current_account, :name, :password, :login, :age
  attr_accessor :cards

  def initialize(file_path = 'accounts.yml')
    @file_path = file_path
    #@console = Console.new(self)
    @validator = Validators::Account.new
    @current_account = self
  end
  
  def create
    @cards = []
    new_accounts = accounts << self
    @current_account = self
    store_accounts(new_accounts)
  end

  def destroy(command)
    if command == 'y'
      new_accounts = []
      accounts.each do |ac|
        if ac.login == @login
        else
          new_accounts.push(ac)
        end
      end
      store_accounts(new_accounts)
    end
  end

  def accounts
    return [] unless File.exist?('accounts.yml')

    YAML.load_file('accounts.yml') || []
  end

  def store_accounts(new_accounts)
    File.open(@file_path, 'w') { |f| f.write new_accounts.to_yaml }
  end

end
