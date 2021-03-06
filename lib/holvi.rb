require 'json'
require 'mechanize'

class Holvi

  def self.login(*args)
    h = new(*args)
    yield h
    h.logout
  end

  def initialize(email, password)
    @agent = Mechanize.new

    data = {
      client_id: 'yIO3banxfsiuQSMrVg7x2LoKAqYKazRV',
      connection: 'Username-Password-Authentication',
      email: email,
      grant_type: 'password',
      password: password,
    }
    response = @agent.post 'https://holvi.com/api/auth-proxy/login/usernamepassword/', data.to_json, {'Content-Type' => 'application/json'}
    responseObject = JSON.parse response.body, symbolize_names: true

    @authorizationHeader = responseObject[:token_type] + ' ' + responseObject[:id_token]
    @summarylist = api('summarylist/')
  end

  def balance(iban)
    item = summary iban
    return item[:account_balance] if item
  end

  def transactions(iban, from = nil, &block)
    item = summary iban
    return nil unless item

    handle = item[:handle]
    time_from = from && CGI.escape(from)

    items = []
    debt(handle) do |item|
      break if item[:timestamp] <= from
      next if item[:type] == 'invoice' && item[:status] != 'paid'

      entity = item[:receiver]
      entity = item[:sender] if item[:type] == 'iban_payment'

      amount = item[:value]
      amount = '-' + amount if item[:type] == 'outboundpayment'

      timestamp = item[:timestamp]
      message = item[:structured_reference] + item[:unstructured_reference]
      item[:items].each do |item|
        m = /^Payment with message (.*)$/.match(item[:description])
        message = m[1] if m
        timestamp = item[:timestamp] if item[:type] == 'settlement'
      end

      items << {
        uuid: item[:uuid],
        type: item[:type],
        timestamp: timestamp,
        amount: amount,
        name: entity[:name],
        iban: item[:iban] != iban ? item[:iban] : '',
        message: message
      }
    end

    items.sort_by! { |item| item[:timestamp] }
    items.each &block
    items.last && items.last[:timestamp]
  end

  def logout
    @agent.get('https://holvi.com/logout/')
  end

  private

  def summary(iban)
    @summarylist.each do |item|
      return item if item[:iban] == iban
    end
    nil
  end

  def debt(handle, page_size = 25)
    ret = api("#{handle}/debt/?o=-timestamp&page_size=#{page_size}")
    while ret do
      ret[:results].map do |item|
        yield item
      end
      ret = ret[:next] && get(ret[:next])
    end
  end

  def headers
    { 'Authorization' => @authorizationHeader, 'Content-Type' => 'application/json'}
  end

  def get(url)
    JSON.parse @agent.get(url, [], nil, headers).body, symbolize_names: true
  end

  def api(url)
    get("https://holvi.com/api/pool/#{url}")
  end

end
