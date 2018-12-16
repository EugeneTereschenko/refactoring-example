require_relative 'credits_cards/credit_cards_types'

class Card

  attr_reader :card, :account

  VALID_TYPES = %w[
    usual
    capitalist
    virtual
  ]

  def initialize(account)
    @account = account
    @console = Console.new(account)
  end

  def cards(type)
    case type
    when 'usual'
      @card = CreditCardsTypes::Usual.new
    when 'capitalist'
      @card = CreditCardsTypes::Capitalist.new
    when 'virtual'
      @card = CreditCardsTypes::Virtual.new
    end
  end

  def create
    type = @console.credit_card_type
    return @console.main_menu unless VALID_TYPES.include?(type)
    @card = cards(type)
    cards = @account.cards << card
    @account.cards = cards #important!!!
    new_accounts = []
    @account.accounts.each do |ac|
      if ac.login == @account.login
        new_accounts.push(@account)
      else
        new_accounts.push(ac)
      end
    end
    @account.store_accounts(new_accounts)
    @console.main_menu
  end

  def destroy

    loop do
      if @account.cards.any?
        puts 'If you want to delete:'

        @account.cards.each_with_index do |c, i|
          puts "- #{c.number}, #{c.type}, press #{i + 1}"
        end
        puts "press `exit` to exit\n"
        answer = gets.chomp
        break if answer == 'exit'
        if answer&.to_i.to_i <= @account.cards.length && answer&.to_i.to_i > 0
          puts "Are you sure you want to delete #{@account.cards[answer&.to_i.to_i - 1].number}?[y/n]"
          user_answer = gets.chomp
          if user_answer == 'y'
            puts @account.cards
            @account.cards.delete_at(answer&.to_i.to_i - 1)
            puts @account.cards
            new_accounts = []
            @account.accounts.each do |ac|
              if ac.login == @account.login
                new_accounts.push(@account)
              else
                new_accounts.push(ac)
              end
            end
            @account.store_accounts(new_accounts)
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
