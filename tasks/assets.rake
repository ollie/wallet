namespace :assets do
  desc 'Compile assets'
  task :compile do
    cd 'public' do
      sh 'coffeebar -so     js/app.js     coffee/app.coffee'
      # sh 'coffeebar -mso    js/app.min.js coffee/app.coffee' # Minified
    end
  end

  desc 'Compile and watch assets'
  task watch: :compile do
    require 'listen'

    def target_file_path(source_file_path)
      source_file_path = Pathname.new(source_file_path)
      public_dir       = source_file_path.dirname.dirname
      target_file_name = "#{source_file_path.basename('.coffee')}.js"
      public_dir.join('js', target_file_name)
    end

    listener = Listen.to('public/coffee') do |modified, added, removed|
      (modified + added).each do |source_file_path|
        target_file_path = target_file_path(source_file_path)
        sh "coffeebar -so #{target_file_path} #{source_file_path}"
      end

      removed.each do |source_file_path|
        target_file_path = target_file_path(source_file_path)
        rm target_file_path
      end
    end

    puts 'Listening for changes.'
    listener.start

    trap('INT') do
      puts
      puts "Alright, I'm done here."
      exit
    end

    sleep
  end
end
