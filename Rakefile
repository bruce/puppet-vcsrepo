require 'puppetlabs_spec_helper/rake_tasks'
require 'rake'

task 'beaker:test',[:host,:type] => :set_beaker_variables do |t,args|

  Rake::Task['beaker-rspec:test'].invoke(args)

  if File.exists?('./acceptance')
    Dir.chdir('./acceptance')
    exec(build_beaker_command args)
    Dir.chdir('../')
  else
    puts "No acceptance directory found, not running beaker tests"
  end

end

desc "Run beaker rspec tasks against pe"
RSpec::Core::RakeTask.new('beaker-rspec:test',[:host,:type]=>:set_beaker_variables) do |t,args|
  t.pattern     = 'spec/acceptance'
  t.rspec_opts  = '--color'
  t.verbose     = true
end

desc "Run beaker and beaker-rspec tasks"
task 'beaker:test:pe',:host do |t,args|
  args.with_defaults(:type=> 'pe')
  Rake::Task['beaker:test'].invoke(args[:host],args[:type])
end

task 'beaker:test:git',:host do |t,args|
  args.with_defaults({:type=> 'git'})
  Rake::Task['beaker:test'].invoke(args[:host],args[:type])
end

task :set_beaker_variables do |t,args|
  puts 'Setting environment variables for testing'
  if args[:host]
    ENV['BEAKER_set'] = args[:host]
    puts "Host to test #{ENV['BEAKER_set']}"
  end
  ENV['BEAKER_IS_PE'] = args[:type] == 'pe'? "true": "false"
end

def build_beaker_command(args)
  cmd = ["beaker"]
  cmd << "--type #{args[:type]}" unless !args[:type]
  if File.exists?("./.beaker-#{args[:type]}.cfg")
    cmd << "--options-file ./.beaker-#{args[:type]}.cfg"
  end
  if File.exists?("config/#{args[:host]}.cfg")
    cmd << "--hosts config/#{args[:host]}.cfg"
  end
  if File.exists?("./tests")
    cmd << "--tests ./tests"
  end
  cmd.join(" ")
end
