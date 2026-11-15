# frozen_string_literal: true

ChinaSMS.use :luosimao,
              username: Rails.application.credentials.dig(:staging, :luosimao, :username),
              password: Rails.application.credentials.dig(:staging, :luosimao, :password)
