module GitlabResponseHelpers
  def self.parsed_response
    Hashie::Mash.new(:message => 'test')
  end

  def self.code
  end

  def self.request
    Hashie::Mash.new(:base_uri => 'test')
  end
end
