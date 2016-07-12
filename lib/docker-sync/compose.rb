require 'docker/compose'

class ComposeManager
  include Thor::Shell
  @compose_session
  def initialize
    @compose_session = Docker::Compose::Session.new(dir:'./')
  end

  def run
    say_status 'ok','starting compose',:white
    @compose_session.up
    say_status 'success','started compose',:green
  end

  def stop
    @compose_session.stop
  end

  def clean
    @compose_session.down
  end
end