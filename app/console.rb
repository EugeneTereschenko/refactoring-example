class Console
  HELLO_MESSAGE = <<~HELLO_MESSAGE.freeze
    Hello, we are RubyG bank!
    - If you want to create account - press `create`
    - If you want to load account - press `load`
    - If you want to exit - press `exit`
  HELLO_MESSAGE

  def initialize(account)
    @account = account
  end

  def hello
    puts HELLO_MESSAGE

    command = gets.chomp

    case command
    when 'create'
      @account.create
    when 'load'
      @account.load
    else
      exit
    end
  end

  def main_menu
    puts main_menu_message

    loop do
      command = gets.chomp
      case command
      when 'SC'
        @account.show_cards
      when 'CC'
        @account.card.create
      when 'DC'
        @account.card.destroy
      when 'PM'
        @account.card.put_money
      when 'WM'
        @account.card.withdraw_money
      when 'SM'
        @account.card.send_money
      when 'DA'
        @account.destroy
        exit
      when 'exit'
        exit
      else
        puts "Wrong command. Try again!\n"
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
      - send money to another card  - press SM
      - destroy account - press `DA`
      - exit from account - press `exit`
    MAIN_MENU_MESSAGE
  end
end
