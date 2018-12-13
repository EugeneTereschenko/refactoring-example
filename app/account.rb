require 'yaml'
require 'pry'

require_relative 'console'
require_relative 'validators/validators'
require_relative 'credit_card'

class Account
  attr_reader :card, :file_path, :console
  attr_reader :current_account, :name, :password, :login, :age
  attr_accessor :cards

  VALID_TYPES = %w[
    usual
    capitalist
    virtual
  ]

  def initialize(file_path = 'accounts.yml')
    @errors = []
    @file_path = file_path
    @console = Console.new(self)
    @validator = Validators::Account.new
  end

  def hello
    @console.hello
  end

  def show_cards
    if @current_account.cards.any?
      @current_account.cards.each do |c|
        puts "- #{c.card.number}, #{c.card.type}"
      end
    else
      puts "There is no active cards!\n"
    end
    @console.main_menu
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

  def create_card
    type = @console.credit_card_type
    return @console.main_menu unless VALID_TYPES.include?(type)
    @card = CreditCard.new(type)
    cards = @current_account.cards << card
    @current_account.cards = cards #important!!!
    new_accounts = []
    accounts.each do |ac|
      if ac.login == @current_account.login
        new_accounts.push(@current_account)
      else
        new_accounts.push(ac)
      end
    end
    File.open(@file_path, 'w') { |f| f.write new_accounts.to_yaml } #Storing
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
        @current_account = a
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

    YAML.load_file('accounts.yml')
  end

  def destroy_card

    loop do
      if @current_account.cards.any?
        puts 'If you want to delete:'

        @current_account.cards.each_with_index do |c, i|
          puts "- #{c.card.number}, #{c.card.type}, press #{i + 1}"
        end
        puts "press `exit` to exit\n"
        answer = gets.chomp
        break if answer == 'exit'
        if answer&.to_i.to_i <= @current_account.cards.length && answer&.to_i.to_i > 0
          puts "Are you sure you want to delete #{@current_account.cards[answer&.to_i.to_i - 1].card.number}?[y/n]"
          user_answer = gets.chomp
          if user_answer == 'y'
            @current_account.cards.delete_at(answer&.to_i.to_i - 1)
            new_accounts = []
            accounts.each do |ac|
              if ac.login == @current_account.login
                new_accounts.push(@current_account)
              else
                new_accounts.push(ac)
              end
            end
            File.open(@file_path, 'w') { |f| f.write new_accounts.to_yaml } #Storing
            @console.main_menu
          else
            return
          end
        else
          puts "You entered wrong number!\n"
        end
      else
        puts "There is no active cards!\n"
        break
      end
    end
  end

  def withdraw_money
    puts 'Choose the card for withdrawing:'
    answer, user_answer, money_withdraw = nil #answers for gets.chomp
    if @current_account.cards.any?
      @current_account.cards.each_with_index do |c, i|
        puts "- #{c.card.number}, #{c.card.type}, press #{i + 1}"
      end
      puts "press `exit` to exit\n"
      loop do
        answer = gets.chomp
        break if answer == 'exit'
        if answer&.to_i.to_i <= @current_account.cards.length && answer&.to_i.to_i > 0
          current_card = @current_account.cards[answer&.to_i.to_i - 1]
          loop do
            puts 'Input the amount of money you want to withdraw'
            user_answer = gets.chomp
            if user_answer&.to_i.to_i > 0
              money_left = current_card.card.balance - user_answer&.to_i.to_i - current_card.card.withdraw_tax(user_answer&.to_i.to_i)
              if money_left > 0
                current_card.card.balance = money_left
                @current_account.cards[answer&.to_i.to_i - 1] = current_card
                new_accounts = []
                accounts.each do |ac|
                  if ac.login == @current_account.login
                    new_accounts.push(@current_account)
                  else
                    new_accounts.push(ac)
                  end
                end
                File.open(@file_path, 'w') { |f| f.write new_accounts.to_yaml } #Storing
                puts "Money #{user_answer&.to_i.to_i} withdrawed from #{current_card.card.number}$. Money left: #{current_card.card.balance}$. Tax: #{current_card.card.withdraw_tax(user_answer&.to_i.to_i)}$"
                @console.main_menu
              else
                puts "You don't have enough money on card for such operation"
                return
              end
            else
              puts 'You must input correct amount of $'
              return
            end
          end
        else
          puts "You entered wrong number!\n"
          return
        end
      end
    else
      puts "There is no active cards!\n"
    end
  end

  def put_money
    puts 'Choose the card for putting:'

    if @current_account.cards.any?
      @current_account.cards.each_with_index do |c, i|
        puts "- #{c.card.number}, #{c.card.type}, press #{i + 1}"
      end
      puts "press `exit` to exit\n"
      loop do
        answer = gets.chomp
        break if answer == 'exit'
        if answer&.to_i.to_i <= @current_account.cards.length && answer&.to_i.to_i > 0
          current_card = @current_account.cards[answer&.to_i.to_i - 1]
          loop do
            puts 'Input the amount of money you want to put on your card'
            user_answer = gets.chomp
            if user_answer&.to_i.to_i > 0
              if current_card.card.put_tax(user_answer&.to_i.to_i) >= user_answer&.to_i.to_i
                puts 'Your tax is higher than input amount'
                return
              else
                new_money_amount = current_card.card.balance + user_answer&.to_i.to_i - current_card.card.put_tax(user_answer&.to_i.to_i)
                current_card.card.balance = new_money_amount
                @current_account.cards[answer&.to_i.to_i - 1] = current_card
                new_accounts = []
                accounts.each do |ac|
                  if ac.login == @current_account.login
                    new_accounts.push(@current_account)
                  else
                    new_accounts.push(ac)
                  end
                end
                File.open(@file_path, 'w') { |f| f.write new_accounts.to_yaml } #Storing
                puts "Money #{user_answer&.to_i.to_i} was put on #{current_card.card.number}. Balance: #{current_card.card.balance}. Tax: #{current_card.card.put_tax(user_answer&.to_i.to_i)}"
                @console.main_menu
              end
            else
              puts 'You must input correct amount of money'
              return
            end
          end
        else
          puts "You entered wrong number!\n"
          return
        end
      end
    else
      puts "There is no active cards!\n"
    end
  end

  def send_money
    puts 'Choose the card for sending:'

    if @current_account.cards.any?
      @current_account.cards.each_with_index do |c, i|
        puts "- #{c.card.number}, #{c.card.type}, press #{i + 1}"
      end
      puts "press `exit` to exit\n"
      answer = gets.chomp
      exit if answer == 'exit'
      if answer&.to_i.to_i <= @current_account.cards.length && answer&.to_i.to_i > 0
        sender_card = @current_account.cards[answer&.to_i.to_i - 1]
      else
        puts 'Choose correct card'
        return
      end
    else
      puts "There is no active cards!\n"
      return
    end

    puts 'Enter the recipient card:'
    user_answer = gets.chomp
    if user_answer.length > 15 && user_answer.length < 17
      if @current_account.cards.select { |card| card.card.number == user_answer}.any?
        recipient_card = @current_account.cards.select { |card| card.card.number == user_answer}.first
      else
        puts "There is no card with number #{user_answer}\n"
        return
      end
    else
      puts 'Please, input correct number of card'
      return
    end

    loop do
      puts 'Input the amount of money you want to withdraw'
      money_withdraw = gets.chomp
      if money_withdraw&.to_i.to_i > 0
        sender_balance = sender_card.card.balance - money_withdraw&.to_i.to_i - sender_card.card.sender_tax(money_withdraw&.to_i.to_i)
        recipient_balance = recipient_card.card.balance + money_withdraw&.to_i.to_i - recipient_card.card.put_tax(money_withdraw&.to_i.to_i)

        if sender_balance < 0
          puts "You don't have enough money on card for such operation"
        elsif recipient_card.card.put_tax(money_withdraw&.to_i.to_i) >= money_withdraw&.to_i.to_i
          puts 'There is no enough money on sender card'
        else
          sender_card.card.balance = sender_balance
          @current_account.cards[answer&.to_i.to_i - 1] = sender_card

          if @current_account.cards.select { |card| card.card.number == user_answer}.any?
            recipient_card.card.balance = recipient_balance
          end

          new_accounts = []
          accounts.each do |ac|
            if ac.login == @current_account.login
              new_accounts.push(@current_account)
            else
              new_accounts.push(ac)
            end
          end
          File.open(@file_path, 'w') { |f| f.write new_accounts.to_yaml } 
          puts "Money #{money_withdraw&.to_i.to_i}$ was put on #{sender_card.card.number}. Balance: #{sender_balance}. Tax: #{sender_card.card.put_tax(money_withdraw&.to_i.to_i)}$\n"
          puts "Money #{money_withdraw&.to_i.to_i}$ was put on #{user_answer}. Balance: #{recipient_balance}. Tax: #{recipient_card.card.sender_tax(money_withdraw&.to_i.to_i)}$\n"
          @console.main_menu
        end
      else
        puts 'You entered wrong number!\n'
      end
    end
  end


  private

  def store_accounts(new_accounts)
    File.open(@file_path, 'w') { |f| f.write new_accounts.to_yaml }
  end
end
