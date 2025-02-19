# typed: strict
# frozen_string_literal: true

require "spec_helper"
require "yaml"

module Tapioca
  class ConfigureSpec < SpecWithProject
    describe "cli::configure" do
      before(:all) do
        project.bundle_install
      end

      after do
        @project.remove("sorbet/config")
        @project.remove("sorbet/tapioca")
        @project.remove("bin/tapioca")
      end

      it "must create proper files" do
        result = @project.tapioca("configure")

        assert_includes(result.out, "create  sorbet/config")
        assert_includes(result.out, "create  sorbet/tapioca/config.yml")
        assert_includes(result.out, "create  sorbet/tapioca/require.rb")
        assert_includes(result.out, "create  bin/tapioca")

        assert_equal(<<~CONFIG, @project.read("sorbet/config"))
          --dir
          .
          --ignore=vendor/
        CONFIG

        assert_project_file_equal("sorbet/tapioca/require.rb", <<~RB)
          # typed: true
          # frozen_string_literal: true

          # Add your extra requires here (`bin/tapioca require` can be used to boostrap this list)
        RB

        assert_project_file_exist("bin/tapioca")

        tapioca_config = YAML.load(@project.read("sorbet/tapioca/config.yml"))
        assert_equal(["gem", "dsl"], tapioca_config.keys)
        assert_nil(tapioca_config["gem"])
        assert_nil(tapioca_config["dsl"])

        assert_empty_stderr(result)
        assert_success_status(result)
      end

      it "must not overwrite files" do
        @project.write("bin/tapioca")
        @project.write("sorbet/config")
        @project.write("sorbet/tapioca/require.rb")
        @project.write("sorbet/tapioca/config.yml")

        result = @project.tapioca("configure")

        assert_includes(result.out, "skip  sorbet/config")
        assert_includes(result.out, "skip  sorbet/tapioca/config.yml")
        assert_includes(result.out, "skip  sorbet/tapioca/require.rb")
        assert_includes(result.out, "force  bin/tapioca")

        assert_empty(@project.read("sorbet/config"))
        assert_empty(@project.read("sorbet/tapioca/require.rb"))

        assert_empty_stderr(result)
        assert_success_status(result)
      end

      it "creates the Tapioca config file in a custom location" do
        result = @project.tapioca("configure --config sorbet/tapioca/custom_config.yml")
        assert_includes(result.out, "create  sorbet/tapioca/custom_config.yml")
        assert_project_file_exist("sorbet/tapioca/custom_config.yml")
        assert_empty_stderr(result)
        assert_success_status(result)
      end

      it "creates the Tapioca post-require file in a custom location" do
        result = @project.tapioca("configure --postrequire sorbet/tapioca/custom_require.rb")
        assert_includes(result.out, "create  sorbet/tapioca/custom_require.rb")
        assert_project_file_exist("sorbet/tapioca/custom_require.rb")
        assert_empty_stderr(result)
        assert_success_status(result)
      end
    end
  end
end
