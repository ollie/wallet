desc 'Run console'
task console: :environment do
  require 'pry'
  require 'pry-doc'
  Pry.start
end

desc 'Run console'
task c: :console
