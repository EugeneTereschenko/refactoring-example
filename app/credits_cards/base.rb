class CreditCards::Base
  def withdraw_tax
    raise NotImplementedError
  end

  def put_tax
    raise NotImplementedError
  end

  def sender_tax
    raise NotImplementedError
  end

  private

  def generate_card_number
    16.times.map{ rand(10) }.join # TODO: optimize?
  end
end
