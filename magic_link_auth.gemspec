require_relative "lib/magic_link_auth/version"

Gem::Specification.new do |spec|
  spec.name = "magic_link_auth"
  spec.version = MagicLinkAuth::VERSION
  spec.authors = ["Melvin"]
  spec.summary = "Mountable Rails engine providing passwordless magic-link authentication (web + API/JWT)."
  spec.description = <<~DESC
    Drop-in Rails engine that adds passwordless magic-link sign-in to any Rails application.
    Supports both a browser cookie-session flow and a stateless JWT flow for mobile/API clients.
    Configurable user model, deep-link (Universal Links / Android App Links) support, and a
    single-use token denylist baked in.
  DESC
  spec.homepage = "https://github.com/traindev/magic_link_auth"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.files = Dir["{app,config,db,lib}/**/*", "LICENSE.txt", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 7.2"
  spec.add_dependency "jwt", "~> 3.1"
end
