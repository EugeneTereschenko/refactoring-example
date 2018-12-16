require 'yaml'
require 'pry'

require_relative 'console'
require_relative 'validators/validators'
require_relative 'card'
require_relative 'money'

class Account
  attr_reader :card, :console, :money
  attr_reader :current_account, :name, :password, :login, :age
  attr_accessor :cards

  def initialize(file_path = 'accounts.yml')
    @errors = []
    @file_path = file_path
    @console = Console.new(self)
    @card = Card.new(self)
    @money = Money.new(self)
    @validator = Validators::Account.new
  end

  def hello
    @console.hello
  end

  def create
    loop do
      @name = @console.name_input
      @age = @console.age_input
      @login = @console.login_input
      @password = @console.password_input

      @validator.validate(self)

      break if @validator.valid?

      @validator.puts_errors
    end

    @cards = []
    new_accounts = accounts << self
    @current_account = self
    store_accounts(new_accounts)
    @console.main_menu
  end

  def load
    loop do
      if !accounts.any?
        return create_the_first_account
      end

      puts 'Enter your login'
      login = gets.chomp
      puts 'Enter your password'
      password = gets.chomp

      if accounts.map { |a| { login: a.login, password: a.password } }.include?({ login: login, password: password})
        a = accounts.select { |a| login == a.login }.first
        @cards = a.cards
        @current_account = a
        @login = a.login
        break
      else
        puts 'There is no account with given credentials'
        next
      end
    end
    @console.main_menu
  end

  def create_the_first_account
    puts 'There is no active accounts, do you want to be the first?[y/n]'
    if gets.chomp == 'y'
      return create
    else
      return console
    end
  end

  def destroy
    puts 'Are you sure want to destroy account?[y/n]'
    a = gets.chomp
    if a == 'y'
      new_accounts = []
      accounts.each do |ac|
        if ac.login == @current_account.login
        else
          new_accounts.push(ac)
        end
      end
      store_accounts(new_accounts)
    end
  end

  def accounts
    return [] unless File.exists?('accounts.yml')

    YAML.load_file('accounts.yml') || []
  end

  def show_cards
    if @current_account.cards.any?
      @current_account.cards.each do |c|
        puts "- #{c.number}, #{c.type}"
      end
    else
      puts "There is no active cards!\n"
    end
    @console.main_menu
  end

  def store_accounts(new_accounts)
    File.open(@file_path, 'w') { |f| f.write new_accounts.to_yaml }
  end
end
