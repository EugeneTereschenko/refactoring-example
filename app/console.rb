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

  def initialize(account)
    @account = account
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

      break if @validator.valid?

      puts_errors(@validator.errors)
    end

    @account.create
    main_menu
  end

  def load
    loop do
      return create_the_first_account if accounts.none?

      message(:put_login)
      login = gets.chomp
      message(:put_passw)
      password = gets.chomp
      if accounts.map { |acc| { login: acc.login, password: acc.password } }.include?(login: login, password: password)
        acc_temp = accounts.select { |a| login == a.login }.first
        @account.cards = acc_temp.cards
        @account.login = acc_temp.login
        @account.current_account = acc_temp
        break
      else
        message(:credentials)
        next
      end
    end
    main_menu
  end

  def create_the_first_account
    message(:first_account)
    return create if gets.chomp == 'y'

    console
  end

  def show_cards
    if @account.cards.any?
      @account.cards.each do |card|
        puts "- #{card.number}, #{card.type}"
      end
    else
      message(:active_cards)
    end
    main_menu
  end

  def accounts
    @account.accounts
  end

  def main_menu
    loop do
      main_menu_message

      command = gets.chomp

      message(:wrong_command) unless MENU_COMMANDS.include?(command)
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
      if ac.login == @account.login
        new_accounts.push(@account)
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
    message(:choose_card)

    return message(:active_cards) unless @account.cards.any?

    @account.cards.each_with_index do |c, i|
      puts "- #{c.number}, #{c.type}, press #{i + 1}"
    end
    message(:press_exit)
    answer = gets.chomp
    exit if answer == 'exit'
    return message(:correct_card) unless answer&.to_i.to_i <= @account.cards.length && answer&.to_i.to_i > 0

    sender_card = @account.cards[answer&.to_i.to_i - 1]

    message(:recipient_card)
    user_answer = gets.chomp
    return message(:correct_number) unless user_answer.length > 15 && user_answer.length < 17
    return message(:card_number, user_answer: user_answer) unless @account.cards.select { |card| card.number == user_answer }.any?

    recipient_card = @account.cards.select { |card| card.number == user_answer }.first

    loop do
      message(:money_withdraw)
      money_withdraw = gets.chomp
      if money_withdraw&.to_i.to_i > 0
        sender_balance = sender_card.balance - money_withdraw&.to_i.to_i - sender_card.sender_tax(money_withdraw&.to_i.to_i)
        recipient_balance = recipient_card.balance + money_withdraw&.to_i.to_i - recipient_card.put_tax(money_withdraw&.to_i.to_i)

        if sender_balance < 0
          message(:money_on_card)
        elsif recipient_card.put_tax(money_withdraw&.to_i.to_i) >= money_withdraw&.to_i.to_i
          message(:no_money)
        else
          sender_card.balance = sender_balance
          @account.cards[answer&.to_i.to_i - 1] = sender_card

          recipient_card.balance = recipient_balance if @account.cards.select { |card| card.number == user_answer }.any?

          new_accounts = []
          accounts.each do |ac|
            if ac.login == @account.login
              new_accounts.push(@account)
            else
              new_accounts.push(ac)
            end
          end
          @account.store_accounts(new_accounts)
          message(:money_was_put, put: money_withdraw&.to_i.to_i, number: sender_card.number, balance: sender_balance, put_tax: sender_card.put_tax(money_withdraw&.to_i.to_i))
          message(:money_was_put, put: money_withdraw&.to_i.to_i, number: user_answer, balance: recipient_balance, put_tax: recipient_card.sender_tax(money_withdraw&.to_i.to_i))
          main_menu
        end
      else
        message(:wrong_number)
      end
    end
  end

  def put_money
    message(:choose_card)

    if @account.cards.any?
      @account.cards.each_with_index do |c, i|
        puts "- #{c.number}, #{c.type}, press #{i + 1}"
      end
      message(:press_exit)
      loop do
        answer = gets.chomp
        return message(:active_cards) if answer == 'exit'
        return message(:wrong_number) unless answer&.to_i.to_i <= @account.cards.length && answer&.to_i.to_i > 0

        current_card = @account.cards[answer&.to_i.to_i - 1]
        loop do
          message(:amount_of_money)
          user_answer = gets.chomp
          return message(:correct_amount) unless user_answer&.to_i.to_i > 0

          if current_card.put_tax(user_answer&.to_i.to_i) >= user_answer&.to_i.to_i
            message(:tax_amount)
            return
          else
            new_money_amount = current_card.balance + user_answer&.to_i.to_i - current_card.put_tax(user_answer&.to_i.to_i)
            current_card.balance = new_money_amount
            @account.cards[answer&.to_i.to_i - 1] = current_card
            new_accounts = []
            accounts.each do |ac|
              if ac.login == @account.login
                new_accounts.push(@account)
              else
                new_accounts.push(ac)
              end
            end
            @account.store_accounts(new_accounts)
            message(:money_was_put, put: user_answer&.to_i.to_i, number: current_card.number, balance: current_card.balance, put_tax: current_card.put_tax(user_answer&.to_i.to_i))
            main_menu
          end
        end
      end
    end
  end

  def withdraw_money
    message(:choose_card_for_withdrawing)
    answer, user_answer, money_withdraw = nil # answers for gets.chomp
    message(:active_cards) unless @account.cards.any?

    @account.cards.each_with_index do |c, i|
      puts "- #{c.number}, #{c.type}, press #{i + 1}"
    end
    message(:press_exit)

    loop do
      answer = gets.chomp
      break if answer == 'exit'
      return message(:wrong_number) unless answer&.to_i.to_i <= @account.cards.length && answer&.to_i.to_i > 0

      current_card = @account.cards[answer&.to_i.to_i - 1]
      loop do
        message(:money_withdraw)
        user_answer = gets.chomp
        return message(:correct_amount) unless user_answer&.to_i.to_i > 0

        money_left = current_card.balance - user_answer&.to_i.to_i - current_card.withdraw_tax(user_answer&.to_i.to_i)
        if money_left > 0
          current_card.balance = money_left
          @account.cards[answer&.to_i.to_i - 1] = current_card
          new_accounts = []
          accounts.each do |ac|
            if ac.login == @account.login
              new_accounts.push(@account)
            else
              new_accounts.push(ac)
            end
          end
          @account.store_accounts(new_accounts)
          message(:money_was_withdraw, withdraw: user_answer&.to_i.to_i, number: current_card.number, balance: current_card.balance, withdraw_tax: current_card.withdraw_tax(user_answer&.to_i.to_i))
          main_menu
        else
          return message(:enough_money)
        end
      end
    end
  end

  def destroy_card
    loop do
      break message(:active_cards) unless @account.cards.any?

      message(:delete_card)

      @account.cards.each_with_index do |c, i|
        puts "- #{c.number}, #{c.type}, press #{i + 1}"
      end
      message(:press_exit)
      answer = gets.chomp
      break if answer == 'exit'
      return message(:wrong_number) unless answer&.to_i.to_i <= @account.cards.length && answer&.to_i.to_i.positive?

      message(:delete_card_sure, cards: @account.cards[answer&.to_i.to_i - 1].number)
      user_answer = gets.chomp
      next unless user_answer == 'y'

      @account.cards.delete_at(answer&.to_i.to_i - 1)
      new_accounts = []
      accounts.each do |ac|
        if ac.login == @account.login
          new_accounts.push(@account)
        else
          new_accounts.push(ac)
        end
      end
      @account.store_accounts(new_accounts)
      break
      #main_menu
    end
  end

  def destroy_account
    message(:destroy_account)
    command = gets.chomp
    @account.destroy(command)
  end

  def name_input
    message(:put_name)
    read_from_console
  end

  def age_input
    message(:put_age)
    read_from_console.to_i
  end

  def login_input
    message(:put_login)
    read_from_console
  end

  def password_input
    message(:put_passw)
    read_from_console
  end

  def credit_card_type
    message(:could_create_one)
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
    message(:main_menu_message_welcome, name: @account.name)
    message(:main_menu_message)
  end
end
