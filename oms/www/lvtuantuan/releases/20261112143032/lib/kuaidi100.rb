# frozen_string_literal: true

class Kuaidi100
  include HTTParty

  KEY = Rails.application.credentials.dig(Rails.env.to_sym, :kuaidi100, :key)
  CUSTOMER = Rails.application.credentials.dig(Rails.env.to_sym, :kuaidi100, :customer)

  base_uri "https://poll.kuaidi100.com".freeze

  attr_reader :com, :num, :from , :to

  def initialize(company, number, from = "", to = "")
    company_code = MagicBean::KuaidiCompanyMapping.find_by!(cn_name: company).code
    @com, @num, @from, @to = company_code, number, from, to
  end

  # 实时查询API: https://www.kuaidi100.com/openapi/api_post.shtml
  def poll_query
    param = {
      com: com,
      num: num,
      from: from,
      to: to
    }

    JSON.parse(self.class.get("/poll/query.do",
      query: {
        customer: CUSTOMER,
        sign: generate_sign(param),
        param: param.to_json
      },
      headers: { "Content-Type" => "application/x-www-form-urlencoded" }
    ))
  end

  def generate_sign(param)
    Digest::MD5.hexdigest(param.to_json + KEY + CUSTOMER).upcase
  end
end
