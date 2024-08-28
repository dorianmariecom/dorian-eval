# frozen_string_literal: true

require "spec_helper"

RSpec.describe "eval" do
  it "works" do
    stdout, stderr = Dorian::Eval.eval(ruby: "puts 1", stdout: false)
    expect(stdout).to eq("1\n")
    expect(stderr).to eq("")
  end
end
