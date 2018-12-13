class CreditCardsTypes::Capitalist
  attr_reader :number, :type
  attr_accessor :balance
  def initialize
    @balance = 100.0
    @number = generate_card_number
    @type = 'capitalist'
  end

  def withdraw_tax(amount)
    amount * 0.04
  end

  def put_tax(amount)
    10
  end

  def sender_tax(amount)
    amount * 0.1
  end

  private
  
  def generate_card_number
    16.times.map { rand(10) }.join # TODO: optimize?
  end
end
