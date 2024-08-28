# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = "dorian-eval"
  s.version = File.read("VERSION").strip
  s.summary = "evaluates ruby"
  s.description = s.summary
  s.authors = ["Dorian Marié"]
  s.email = "dorian@dorianmarie.com"
  s.files = %w[lib/dorian-eval.rb lib/dorian/eval.rb bin/eval VERSION]
  s.executables << "eval"
  s.homepage = "https://github.com/dorianmariecom/dorian-eval"
  s.license = "MIT"
  s.metadata = { "rubygems_mfa_required" => "true" }
  s.required_ruby_version = "3.3.4"
end
