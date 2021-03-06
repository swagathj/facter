test_name "Fact directory precedence and resolution order for facts"

confine :except, :platform => 'windows' # windows only supports 1 directory instead of 3 on unix

# TestRail: C59201

require 'facter/acceptance/user_fact_utils'
extend Facter::Acceptance::UserFactUtils

# Generate an external fact dynamically
def ext_fact(value='BASIC')
  "test: '#{value}'"
end

agents.each do |agent|
  # The directories that facter processes facts
  os_version = on(agent, facter('kernelmajversion')).stdout.chomp.to_f
  factsd_dir = get_factsd_dir(agent['platform'], os_version)
  etc_factsd_dir = get_etc_factsd_dir(agent['platform'])
  etc_puppetlabs_factsd_dir = get_etc_puppetlabs_factsd_dir(agent['platform'])
  factsd_path = "#{factsd_dir}/test.yaml"
  etc_factsd_path = "#{etc_factsd_dir}/test.yaml"
  etc_puppetlabs_factsd_path = "#{etc_puppetlabs_factsd_dir}/test.yaml"

  # ensure the fact directory we want to use exists
  step "Agent #{agent}: create facts directory (#{etc_puppetlabs_factsd_dir})"
  on(agent, "rm -rf #{etc_puppetlabs_factsd_dir}")
  on(agent, "mkdir -p #{etc_puppetlabs_factsd_dir}")

  # A fact in the etc_puppetlabs_factsd_dir directory should resolve to the fact
  step "Agent #{agent}: create and resolve a custom fact in #{etc_puppetlabs_factsd_dir}"
  create_remote_file(agent, etc_puppetlabs_factsd_path, ext_fact('etc_puppetlabs_path'))
  on(agent, facter("test")) do
    assert_match(/etc_puppetlabs_path/, stdout, "Fact from #{etc_puppetlabs_factsd_dir} did not resolve correctly")
  end

  # remove the fact
  step "Agent #{agent}: remove the fact in #{etc_puppetlabs_factsd_dir}"
  on(agent, "rm -f #{etc_puppetlabs_factsd_path}")

  # ensure the fact directory we want to use exists
  step "Agent #{agent}: create facts directory (#{etc_factsd_dir})"
  on(agent, "rm -rf #{etc_factsd_dir}")
  on(agent, "mkdir -p #{etc_factsd_dir}")

  # A fact in the etc_factsd_dir directory should resolve to the fact
  step "Agent #{agent}: create and resolve a custom fact in #{etc_factsd_dir}"
  create_remote_file(agent, etc_factsd_path, ext_fact('etc_path'))
  on(agent, facter("test")) do
    assert_match(/etc_path/, stdout, "Fact from #{etc_factsd_dir} did not resolve correctly")
  end

  # remove the fact
  step "Agent #{agent}: remove the fact in #{etc_factsd_dir}"
  on(agent, "rm -f #{etc_factsd_path}")

  # ensure the fact directory we want to use exists
  step "Agent #{agent}: create facts directory (#{factsd_dir})"
  on(agent, "rm -rf #{factsd_dir}")
  on(agent, "mkdir -p #{factsd_dir}")

  # A fact in the factsd_dir directory should resolve to the fact
  step "Agent #{agent}: create and resolve a custom fact in #{factsd_dir}"
  create_remote_file(agent, factsd_path, ext_fact('default_factsd'))
  on(agent, facter("test")) do
    assert_match(/default_factsd/, stdout, "Fact from #{factsd_dir} did not resolve correctly")
  end

  # remove the fact
  step "Agent #{agent}: remove the fact in #{factsd_dir}"
  on(agent, "rm -f #{factsd_path}")

  # A fact in the etc_factsd_dir directory should take precedence over the same fact in factsd_dir
  step "Agent #{agent}: create and resolve 2 facts of the same name between #{factsd_dir} and #{etc_factsd_dir}"
  create_remote_file(agent, factsd_path, ext_fact('BASE'))
  create_remote_file(agent, etc_factsd_path, ext_fact('ETC_FACTS'))
  on(agent, facter("test")) do
    assert_match(/ETC_FACTS/, stdout, "Fact from #{etc_factsd_dir} should take precedence over #{factsd_dir}")
  end

  # A fact in the etc_puppetlabs_factsd_dir should take precedence over the same fact in etc_factsd_dir
  step "Agent #{agent}: create and resolve 2 facts of the same name between #{etc_factsd_dir} and #{etc_puppetlabs_factsd_dir}"
  create_remote_file(agent, etc_factsd_path, ext_fact('ETC_FACTS'))
  create_remote_file(agent, etc_puppetlabs_factsd_path, ext_fact('ETC_PUPPETLABS_FACTS'))
  on(agent, facter("test")) do
    assert_match(/ETC_PUPPETLABS_FACTS/, stdout, "Fact from #{etc_puppetlabs_factsd_dir} should take precedence over #{etc_factsd_dir}")
  end

  teardown do
    on(agent, "rm -rf #{factsd_dir}")
    on(agent, "rm -rf #{etc_factsd_dir}")
    on(agent, "rm -rf #{etc_puppetlabs_factsd_dir}")
  end
end
