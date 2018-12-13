require_relative 'credits_cards/credit_cards_types'

class CreditCard

  attr_reader :card

  def initialize(type)
    case type
    when 'usual'
      @card = CreditCardsTypes::Usual.new
    when 'capitalist'
      @card = CreditCardsTypes::Capitalist.new
    when 'virtual'
      @card = CreditCardsTypes::Virtual.new
    end
  end


  
end
