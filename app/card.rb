require_relative 'credits_cards/credit_cards_types'

class Card

  attr_reader :card, :account

  VALID_TYPES = %w[
    usual
    capitalist
    virtual
  ]

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

end
