Gem::Specification.new do |spec|
  spec.name		= "wheelhouse"
  spec.version		= "0.0.1"
  author_list = {
    "Judson Lester" => 'nyarly@gmail.com'
  }
  spec.authors		= author_list.keys
  spec.email		= spec.authors.map {|name| author_list[name]}
  spec.summary		= ""
  spec.description	= <<-EndDescription
  EndDescription

  spec.rubyforge_project= spec.name.downcase
  spec.homepage        = "http://nyarly.github.com/#{spec.name.downcase}"
  spec.required_rubygems_version = Gem::Requirement.new(">= 0") if spec.respond_to? :required_rubygems_version=

  # Do this: y$@"
  # !!find lib bin doc spec spec_help -not -regex '.*\.sw.' -type f 2>/dev/null
  spec.files		= %w[
    lib/wheelhouse/records/server.rb
    lib/wheelhouse/single-command.rb
    lib/wheelhouse/persister.rb
    lib/wheelhouse/queries/server.rb
    lib/wheelhouse/command-config.rb
    lib/wheelhouse/command-definition.rb
    lib/wheelhouse/record.rb
    lib/wheelhouse/cli.rb
    lib/wheelhouse/persisters/server.rb
    lib/wheelhouse/command-runner.rb
    lib/wheelhouse/server-command.rb
    lib/wheelhouse/query.rb
    lib/wheelhouse/application.rb
    lib/wheelhouse.rb
    bin/wheelhouse
    spec_help/gem_test_suite.rb
  ]

  spec.executables << 'wheelhouse'

  spec.test_file        = "spec_help/gem_test_suite.rb"
  spec.licenses = ["MIT"]
  spec.require_paths = %w[lib/]
  spec.rubygems_version = "1.3.5"

  spec.has_rdoc		= true
  spec.extra_rdoc_files = Dir.glob("doc/**/*")
  spec.rdoc_options	= %w{--inline-source }
  spec.rdoc_options	+= %w{--main doc/README }
  spec.rdoc_options	+= ["--title", "#{spec.name}-#{spec.version} Documentation"]

  spec.add_dependency 'thor', "~> 0.18"
  spec.add_dependency 'rake', "~> 10.1.1"
  spec.add_dependency 'sqlite3', "~> 1.3.5"
  spec.add_dependency 'sequel', "~> 4.6.0"
  spec.add_dependency 'caliph', "~> 0.3.1"
  spec.add_dependency 'valise', "~> 1.1.1"

  #spec.post_install_message = "Thanks for installing my gem!"
end
