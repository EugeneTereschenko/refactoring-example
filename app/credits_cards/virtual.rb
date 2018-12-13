class CreditCardsTypes::Virtual
  attr_reader :number, :type
  attr_accessor :balance
  def initialize
    @balance = 150.0
    @number = generate_card_number
    @type = 'virtual'
  end

  def withdraw_tax(amount)
    amount * 0.88
  end

  def put_tax(amount)
    1
  end

  def sender_tax(amount)
    1
  end

  private
  
  def generate_card_number
    16.times.map { rand(10) }.join # TODO: optimize?
  end

end
