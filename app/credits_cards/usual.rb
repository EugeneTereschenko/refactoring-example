class CreditCardsTypes::Usual < CreditCardsTypes::Base # TODO: refactor to be equal
  attr_reader :number, :type
  attr_accessor :balance
  def initialize
    @balance = 50.0
    @number = generate_card_number
    @type = 'usual'
  end

  def withdraw_tax(amount)
    amount * 0.05
  end

  def put_tax(amount)
    amount * 0.2
  end

  def sender_tax(amount)
    20
  end

  private
  
  def generate_card_number
    16.times.map { rand(10) }.join # TODO: optimize?
  end

end
