Gem::Specification.new do |spec|
  spec.name		= "helm"
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
    lib/helm/records/server.rb
    lib/helm/persister.rb
    lib/helm/queries/server.rb
    lib/helm/record.rb
    lib/helm/cli.rb
    lib/helm/persisters/server.rb
    lib/helm/command-runner.rb
    lib/helm/server-command.rb
    lib/helm/query.rb
    lib/helm/application.rb
    lib/helm.rb
    bin/helm
    spec_help/gem_test_suite.rb
  ]

  spec.executables << 'helm'

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
