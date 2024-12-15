# frozen_string_literal: true

namespace :rspec do
  desc 'Open the coverage report to be reviewed'
  task review: :environment do
    exec "open #{Rails.root.join('coverage/index.html')}"
  end
end
