# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = "dorian-eval"
  s.version = File.read("VERSION").strip
  s.summary = "evaluates ruby"
  s.description = "Helpers and executable for evaluating Ruby snippets."
  s.authors = ["Dorian Marié"]
  s.email = "dorian@dorianmarie.com"
  s.files = %w[lib/dorian-eval.rb lib/dorian/eval.rb bin/eval VERSION]
  s.executables << "eval"
  s.homepage = "https://github.com/dorianmariecom/dorian-eval"
  s.license = "MIT"
  s.metadata = { "rubygems_mfa_required" => "true" }
  s.required_ruby_version = ">= 4.0"
  s.add_dependency "yaml", ">= 0.3", "< 1"
end
