# frozen_string_literal: true

namespace :rswag do
  desc 'Generate the swagger.yaml file'
  task generate: :environment do
    exec 'rake rswag:specs:swaggerize PATTERN="spec/swagger/**/*_spec.rb"'
  end
end
