require 'yaml'
require 'pry'

require_relative 'console'
require_relative 'validators/validators'
require_relative 'card'

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

  def create_card_type(type)
    case type
    when 'usual'
      @cards << CreditCardsTypes::Usual.new
    when 'capitalist'
      @cards << CreditCardsTypes::Capitalist.new
    when 'virtual'
      @cards << CreditCardsTypes::Virtual.new
    end
  end

  def withdraw_card
    puts 'Choose the card for withdrawing:'
    answer, user_answer, money_withdraw = nil #answers for gets.chomp
    if @cards.any?
      @cards.each_with_index do |c, i|
        puts "- #{c.number}, #{c.type}, press #{i + 1}"
      end
      puts "press `exit` to exit\n"
      loop do
        answer = gets.chomp
        break if answer == 'exit'
        if answer&.to_i.to_i <= @cards.length && answer&.to_i.to_i > 0
          current_card = @cards[answer&.to_i.to_i - 1]
          loop do
            puts 'Input the amount of money you want to withdraw'
            user_answer = gets.chomp
            if user_answer&.to_i.to_i > 0
              money_left = current_card.balance - user_answer&.to_i.to_i - current_card.withdraw_tax(user_answer&.to_i.to_i)
              if money_left > 0
                current_card.balance = money_left
                @cards[answer&.to_i.to_i - 1] = current_card
                new_accounts = []
                accounts.each do |ac|
                  if ac.login == @login
                    new_accounts.push(self)
                  else
                    new_accounts.push(ac)
                  end
                end
                store_accounts(new_accounts)
                puts "Money #{user_answer&.to_i.to_i} withdrawed from #{current_card.number}$. Money left: #{current_card.balance}$. Tax: #{current_card.withdraw_tax(user_answer&.to_i.to_i)}$"
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

  def put_card
    puts 'Choose the card for putting:'

    if @cards.any?
      @cards.each_with_index do |c, i|
        puts "- #{c.number}, #{c.type}, press #{i + 1}"
      end
      puts "press `exit` to exit\n"
      loop do
        answer = gets.chomp
        break if answer == 'exit'
        if answer&.to_i.to_i <= @cards.length && answer&.to_i.to_i > 0
          current_card = @cards[answer&.to_i.to_i - 1]
          loop do
            puts 'Input the amount of money you want to put on your card'
            user_answer = gets.chomp
            if user_answer&.to_i.to_i > 0
              if current_card.put_tax(user_answer&.to_i.to_i) >= user_answer&.to_i.to_i
                puts 'Your tax is higher than input amount'
                return
              else
                new_money_amount = current_card.balance + user_answer&.to_i.to_i - current_card.put_tax(user_answer&.to_i.to_i)
                current_card.balance = new_money_amount
                @cards[answer&.to_i.to_i - 1] = current_card
                new_accounts = []
                accounts.each do |ac|
                  if ac.login == @login
                    new_accounts.push(self)
                  else
                    new_accounts.push(ac)
                  end
                end
                store_accounts(new_accounts)
                puts "Money #{user_answer&.to_i.to_i} was put on #{current_card.number}. Balance: #{current_card.balance}. Tax: #{current_card.put_tax(user_answer&.to_i.to_i)}"
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

  def send_card
    puts 'Choose the card for sending:'

    if @cards.any?
      @cards.each_with_index do |c, i|
        puts "- #{c.number}, #{c.type}, press #{i + 1}"
      end
      puts "press `exit` to exit\n"
      answer = gets.chomp
      exit if answer == 'exit'
      if answer&.to_i.to_i <= @cards.length && answer&.to_i.to_i > 0
        sender_card = @cards[answer&.to_i.to_i - 1]
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
      if @cards.select { |card| card.number == user_answer}.any?
        recipient_card = @cards.select { |card| card.number == user_answer}.first
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
        sender_balance = sender_card.balance - money_withdraw&.to_i.to_i - sender_card.sender_tax(money_withdraw&.to_i.to_i)
        recipient_balance = recipient_card.balance + money_withdraw&.to_i.to_i - recipient_card.put_tax(money_withdraw&.to_i.to_i)

        if sender_balance < 0
          puts "You don't have enough money on card for such operation"
        elsif recipient_card.put_tax(money_withdraw&.to_i.to_i) >= money_withdraw&.to_i.to_i
          puts 'There is no enough money on sender card'
        else
          sender_card.balance = sender_balance
          @cards[answer&.to_i.to_i - 1] = sender_card

          if @cards.select { |card| card.number == user_answer}.any?
            recipient_card.balance = recipient_balance
          end

          new_accounts = []
          accounts.each do |ac|
            if ac.login == @login
              new_accounts.push(self)
            else
              new_accounts.push(ac)
            end
          end
          store_accounts(new_accounts)
          puts "Money #{money_withdraw&.to_i.to_i}$ was put on #{sender_card.number}. Balance: #{sender_balance}. Tax: #{sender_card.put_tax(money_withdraw&.to_i.to_i)}$\n"
          puts "Money #{money_withdraw&.to_i.to_i}$ was put on #{user_answer}. Balance: #{recipient_balance}. Tax: #{recipient_card.sender_tax(money_withdraw&.to_i.to_i)}$\n"
          @console.main_menu
        end
      else
        puts 'You entered wrong number!\n'
      end
    end
  end

  def create_card(type)
    create_card_type(type)
    new_accounts = []
    accounts.each do |ac|
      if ac.login == @login
        new_accounts.push(self)
      else
        new_accounts.push(ac)
      end
    end
    store_accounts(new_accounts)
    @console.main_menu
  end

  def destroy_card

    loop do
      if @cards.any?
        puts 'If you want to delete:'

        @cards.each_with_index do |c, i|
          puts "- #{c.number}, #{c.type}, press #{i + 1}"
        end
        puts "press `exit` to exit\n"
        answer = gets.chomp
        break if answer == 'exit'
        if answer&.to_i.to_i <= @cards.length && answer&.to_i.to_i > 0
          puts "Are you sure you want to delete #{@cards[answer&.to_i.to_i - 1].number}?[y/n]"
          user_answer = gets.chomp
          if user_answer == 'y'
            @cards.delete_at(answer&.to_i.to_i - 1)
            new_accounts = []
            accounts.each do |ac|
              if ac.login == @login
                new_accounts.push(self)
              else
                new_accounts.push(ac)
              end
            end
            store_accounts(new_accounts)
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

end
