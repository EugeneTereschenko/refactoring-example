require_relative 'validators/validators'

class Console
  HELLO_MESSAGE = <<~HELLO_MESSAGE.freeze
    Hello, we are RubyG bank!
    - If you want to create account - press `create`
    - If you want to load account - press `load`
    - If you want to exit - press `exit`
  HELLO_MESSAGE

  def initialize(account)
    @account = account
    @validator = Validators::Account.new
  end

  def console
    #  puts HELLO_MESSAGE
    puts 'Hello, we are RubyG bank!'
    puts '- If you want to create account - press `create`'
    puts '- If you want to load account - press `load`'
    puts '- If you want to exit - press `exit`'

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

      @validator.puts_errors
    end
    @validator.puts_errors

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
      puts accounts
      f = accounts.map { |acc| { login: acc.login, password: acc.password } }
      puts f
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
    if @account.current_account.cards.any?
      @account.current_account.cards.each do |c|
        puts "- #{c.number}, #{c.type}"
      end
    else
      puts "There is no active cards!\n"
    end
    main_menu
  end

  def accounts
    return [] unless File.exist?('accounts.yml')

    YAML.load_file('accounts.yml') || []
  end

  def main_menu
    puts main_menu_message

    loop do
      command = gets.chomp
      case command
      when 'SC'
        show_cards
      when 'CC'
        @account.card.create
      when 'DC'
        @account.card.destroy
      when 'PM'
        @account.money.put
      when 'WM'
        @account.money.withdraw
      when 'SM'
        @account.money.send
      when 'DA'
        @account.destroy
        exit
      when 'exit'
        exit
      else
        puts "Wrong command. Try again\n"
      end
    end
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
    puts create_card_message
    read_from_console
  end

  private

  def read_from_console
    gets.chomp
  end

  def main_menu_message
    <<~MAIN_MENU_MESSAGE
      \nWelcome, #{@account.current_account.name}
      If you want to:
      - show all cards - press SC
      - create card - press CC
      - destroy card - press DC
      - put money on card - press PM
      - withdraw money on card - press WM
      - send money to another card - press SM
      - destroy account - press 'DA'
      - exit from account - press 'exit'
    MAIN_MENU_MESSAGE
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
