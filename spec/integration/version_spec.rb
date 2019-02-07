require 'spec_helper'
require 'docker-sync/upgrade_check'
require 'rspec/bash'

RSpec.describe '--version', command_execution: :allowed do
  include Rspec::Bash

  let(:env) { create_stubbed_env }

  subject { 'bin/docker-sync --version' }

  it 'outputs the version' do
    stdout, _stderr, _status = env.execute_inline(subject)
    # puts will always add a newline, so we have to compare against that
    expect(stdout).to eq UpgradeChecker.get_current_version
  end

  it 'is successful' do
    _stdout, _stderr, status = env.execute_inline(subject)
    expect(status).to be_success
  end
end
