require 'spec_helper'

RSpec.describe '--version', command_execution: :allowed do
  include Rspec::Bash

  let(:env) { create_stubbed_env }

  subject { 'bin/docker-sync --version' }

  it 'outputs the version' do
    stdout, _stderr, _status = env.execute_inline(subject)
    expect(stdout).to eq `cat VERSION`
  end

  it 'is successful' do
    _stdout, _stderr, status = env.execute_inline(subject)
    expect(status).to be_success
  end
end
