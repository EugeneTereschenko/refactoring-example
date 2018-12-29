class Console
  attr_reader :card, :console, :money
  attr_accessor :account
  attr_accessor :cards

  VALID_TYPES = %w[
    usual
    capitalist
    virtual
  ].freeze

  MENU_COMMANDS = %w[
    SC
    CC
    DC
    PM
    WM
    SM
    DA
    exit
  ].freeze

  def initialize
    @account = Account.new
    @validator = Validators::Account.new
  end

  def console
    message(:hello_message)
    command = gets.chomp

    case command
    when 'create'
      create
    when 'load'
      load
    else
      exit
    end
  end

  def create
    loop do
      @account.name = name_input
      @account.age = age_input
      @account.login = login_input
      @account.password = password_input
      @validator.validate(@account)

      puts_errors(@validator.errors)

      break if @validator.valid?
    end

    @account.create
    main_menu
  end

  def load
    loop do
      return create_the_first_account if accounts.none?

      puts 'Enter your login'
      login = gets.chomp
      puts 'Enter your password'
      password = gets.chomp
      if accounts.map { |acc| { login: acc.login, password: acc.password } }.include?(login: login, password: password)
        acc_temp = accounts.select { |a| login == a.login }.first
        @account.cards = acc_temp.cards
        @account.login = acc_temp.login
        @account.current_account = acc_temp
        break
      else
        puts 'There is no account with given credentials'
        next
      end
    end
    main_menu
  end

  def create_the_first_account
    puts 'There is no active accounts, do you want to be the first?[y/n]'
    if gets.chomp == 'y'
      return create
    else
      return console
    end
  end

  def show_cards
    if @account.cards.any?
      @account.cards.each do |card|
        puts "- #{card.number}, #{card.type}"
        #  puts "- #{card[:number]}, #{card[:type]}"
      end
    else
      puts "There is no active cards!\n"
    end
    main_menu
  end

  def accounts
    @account.accounts
  end

  def main_menu
    main_menu_message
    loop do
      command = gets.chomp

      puts "Wrong command. Try again\n" unless MENU_COMMANDS.include?(command)
      case command
      when 'SC'
        show_cards
      when 'CC'
        create_card
      when 'DC'
        destroy_card
      when 'PM'
        put_money
      when 'WM'
        withdraw_money
      when 'SM'
        send_money
      when 'DA'
        destroy_account
        exit
      when 'exit'
        exit
        break
      end
    end
  end

  def create_card
    type = credit_card_type
    return main_menu unless VALID_TYPES.include?(type)

    create_card_type(type)
    new_accounts = []
    accounts.each do |ac|
      if ac.login == @login
        new_accounts.push(self)
      else
        new_accounts.push(ac)
      end
    end
    @account.store_accounts(new_accounts)
    main_menu
  end

  def create_card_type(type)
    case type
    when 'usual'
      @account.cards << CreditCardsTypes::Usual.new
    when 'capitalist'
      @account.cards << CreditCardsTypes::Capitalist.new
    when 'virtual'
      @account.cards << CreditCardsTypes::Virtual.new
    end
  end

  def send_money
    puts 'Choose the card for sending:'

    return puts "There is no active cards!\n" unless @account.cards.any?

    @account.cards.each_with_index do |c, i|
      puts "- #{c.number}, #{c.type}, press #{i + 1}"
    end
    puts "press `exit` to exit\n"
    answer = gets.chomp
    exit if answer == 'exit'
    return puts 'Choose correct card' unless answer&.to_i.to_i <= @account.cards.length && answer&.to_i.to_i > 0

    sender_card = @account.cards[answer&.to_i.to_i - 1]

    puts 'Enter the recipient card:'
    user_answer = gets.chomp
    return puts 'Please, input correct number of card' unless user_answer.length > 15 && user_answer.length < 17
    return puts "There is no card with number #{user_answer}\n" unless @account.cards.select { |card| card.number == user_answer }.any?

    recipient_card = @account.cards.select { |card| card.number == user_answer }.first

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
          @account.cards[answer&.to_i.to_i - 1] = sender_card

          recipient_card.balance = recipient_balance if @account.cards.select { |card| card.number == user_answer }.any?

          new_accounts = []
          accounts.each do |ac|
            if ac.login == @login
              new_accounts.push(self)
            else
              new_accounts.push(ac)
            end
          end
          @account.store_accounts(new_accounts)
          puts "Money #{money_withdraw&.to_i.to_i}$ was put on #{sender_card.number}. Balance: #{sender_balance}. Tax: #{sender_card.put_tax(money_withdraw&.to_i.to_i)}$\n"
          puts "Money #{money_withdraw&.to_i.to_i}$ was put on #{user_answer}. Balance: #{recipient_balance}. Tax: #{recipient_card.sender_tax(money_withdraw&.to_i.to_i)}$\n"
          main_menu
        end
      else
        puts 'You entered wrong number!\n'
      end
    end
  end

  def put_money
    puts 'Choose the card for putting:'

    if @account.cards.any?
      @account.cards.each_with_index do |c, i|
        puts "- #{c.number}, #{c.type}, press #{i + 1}"
      end
      puts "press `exit` to exit\n"
      loop do
        answer = gets.chomp
        return puts "There is no active cards!\n" if answer == 'exit'
        return puts "You entered wrong number!\n" unless answer&.to_i.to_i <= @account.cards.length && answer&.to_i.to_i > 0

        current_card = @account.cards[answer&.to_i.to_i - 1]
        loop do
          puts 'Input the amount of money you want to put on your card'
          user_answer = gets.chomp
          return puts 'You must input correct amount of money' unless user_answer&.to_i.to_i > 0

          if current_card.put_tax(user_answer&.to_i.to_i) >= user_answer&.to_i.to_i
            puts 'Your tax is higher than input amount'
            return
          else
            new_money_amount = current_card.balance + user_answer&.to_i.to_i - current_card.put_tax(user_answer&.to_i.to_i)
            current_card.balance = new_money_amount
            @account.cards[answer&.to_i.to_i - 1] = current_card
            new_accounts = []
            accounts.each do |ac|
              if ac.login == @login
                new_accounts.push(self)
              else
                new_accounts.push(ac)
              end
            end
            @account.store_accounts(new_accounts)
            puts "Money #{user_answer&.to_i.to_i} was put on #{current_card.number}. Balance: #{current_card.balance}. Tax: #{current_card.put_tax(user_answer&.to_i.to_i)}"
            main_menu
          end
        end
      end
    end
  end

  def withdraw_money
    puts 'Choose the card for withdrawing:'
    answer, user_answer, money_withdraw = nil # answers for gets.chomp
    puts "There is no active cards!\n" unless @account.cards.any?

    @account.cards.each_with_index do |c, i|
      puts "- #{c.number}, #{c.type}, press #{i + 1}"
    end
    puts "press `exit` to exit\n"

    loop do
      answer = gets.chomp
      break if answer == 'exit'
      return puts "You entered wrong number!\n" unless answer&.to_i.to_i <= @account.cards.length && answer&.to_i.to_i > 0

      current_card = @account.cards[answer&.to_i.to_i - 1]
      loop do
        puts 'Input the amount of money you want to withdraw'
        user_answer = gets.chomp
        return puts 'You must input correct amount of $' unless user_answer&.to_i.to_i > 0

        money_left = current_card.balance - user_answer&.to_i.to_i - current_card.withdraw_tax(user_answer&.to_i.to_i)
        if money_left > 0
          current_card.balance = money_left
          @account.cards[answer&.to_i.to_i - 1] = current_card
          new_accounts = []
          accounts.each do |ac|
            if ac.login == @login
              new_accounts.push(self)
            else
              new_accounts.push(ac)
            end
          end
          @account.store_accounts(new_accounts)
          puts "Money #{user_answer&.to_i.to_i} withdrawed from #{current_card.number}$. Money left: #{current_card.balance}$. Tax: #{current_card.withdraw_tax(user_answer&.to_i.to_i)}$"
          main_menu
        else
          return puts "You don't have enough money on card for such operation"
        end
      end
    end
  end

  def destroy_card
    loop do
      next unless @account.cards.any?

      puts 'If you want to delete:'

      @account.cards.each_with_index do |c, i|
        puts "- #{c.number}, #{c.type}, press #{i + 1}"
      end
      puts "press `exit` to exit\n"
      answer = gets.chomp
      return puts "There is no active cards!\n" if answer == 'exit'
      return puts "You entered wrong number!\n" unless answer&.to_i.to_i <= @account.cards.length && answer&.to_i.to_i > 0

      puts "Are you sure you want to delete #{@account.cards[answer&.to_i.to_i - 1].number}?[y/n]"
      user_answer = gets.chomp
      if user_answer == 'y'
        @account.cards.delete_at(answer&.to_i.to_i - 1)
        new_accounts = []
        accounts.each do |ac|
          if ac.login == @login
            new_accounts.push(self)
          else
            new_accounts.push(ac)
          end
        end
        @account.store_accounts(new_accounts)
        main_menu
      else
        return
        end
    end
  end

  def destroy_account
    puts 'Are you sure want to destroy account?[y/n]'
    command = gets.chomp
    @account.destroy(command)
  end

  def name_input
    puts 'Enter your name'
    read_from_console
  end

  def age_input
    puts 'Enter your age'
    read_from_console.to_i
  end

  def login_input
    puts 'Enter your login'
    read_from_console
  end

  def password_input
    puts 'Enter your password'
    read_from_console
  end

  def credit_card_type
    # puts create_card_message
    puts 'You could create one of 3 card types'
    puts '- Usual card. 2% tax on card INCOME. 20$ tax on SENDING money from this card. 5% tax on WITHDRAWING money. For creation this card - press `usual`'
    puts '- Capitalist card. 10$ tax on card INCOME. 10% tax on SENDING money from this card. 4$ tax on WITHDRAWING money. For creation this card - press `capitalist`'
    puts '- Virtual card. 1$ tax on card INCOME. 1$ tax on SENDING money from this card. 12% tax on WITHDRAWING money. For creation this card - press `virtual`'
    puts '- For exit - press `exit`'
    read_from_console
  end

  def puts_errors(errors)
    errors.each { |error| puts error }
  end

  def message(msg, params = {})
    puts I18n.t(msg, params)
  end

  private

  def read_from_console
    gets.chomp
  end

  def main_menu_message
    #    <<~MAIN_MENU_MESSAGE
    #      \nWelcome, #{@account.name}
    #      If you want to:
    #      - show all cards - press SC
    #      - create card - press CC
    #      - destroy card - press DC
    #      - put money on card - press PM
    #      - withdraw money on card - press WM
    #      - send money to another card - press SM
    #      - destroy account - press 'DA'
    #      - exit from account - press 'exit'
    #    MAIN_MENU_MESSAGE
    #puts "\nWelcome, #{@account.name}"
    #puts 'If you want to:'
    #puts '- show all cards - press SC'
    #puts '- create card - press CC'
   # puts '- destroy card - press DC'
    #puts '- put money on card - press PM'
   # puts '- withdraw money on card - press WM'
   # puts '- send money to another card  - press SM'
   # puts '- destroy account - press DA'
   # puts '- exit from account - press exit'
    message(:main_menu_message, name: @account.name)
  end

  def create_card_message
    <<~CREATE_CARD_MESSAGE
      You could create one of 3 card types
      - Usual card. 2% tax on card INCOME. 20$ tax on SENDING money from this card. 5% tax on WITHDRAWING money. For creation this card - press `usual`
      - Capitalist card. 10$ tax on card INCOME. 10% tax on SENDING money from this card. 4$ tax on WITHDRAWING money. For creation this card - press `capitalist`
      - Virtual card. 1$ tax on card INCOME. 1$ tax on SENDING money from this card. 12% tax on WITHDRAWING money. For creation this card - press `virtual`
      - For exit - press `exit`
    CREATE_CARD_MESSAGE
  end
end
