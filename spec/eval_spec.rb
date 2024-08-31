# frozen_string_literal: true

require "spec_helper"

RSpec.describe "eval" do
  it "works" do
    result = Dorian::Eval.eval(ruby: "puts 1", stdout: false)
    expect(result.stdout).to eq("1\n")
    expect(result.stderr).to eq("")
    expect(result.returned).to be_nil

    result = Dorian::Eval.eval(ruby: "1 + 1", stdout: false, returns: true)
    expect(result.stdout).to eq("--- 2\n")
    expect(result.stderr).to eq("")
    expect(result.returned).to eq(2)

    result = Dorian::Eval.eval(ruby: "", stdout: false, returns: true)
    expect(result.stdout).to eq("---\n")
    expect(result.stderr).to eq("")
    expect(result.returned).to be_nil
  end
end
