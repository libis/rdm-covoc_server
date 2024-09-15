# frozen_string_literal: true
require 'csv'
require 'json'
require 'tty-progressbar'
require 'fileutils'

class Writer
  def initialize
    @data = {}
  end

  def set_data(data:)
    @data = data
  end

  def to_json(file:)
    File.open(file, 'wt') do |f|
      f.puts JSON.pretty_generate(@data)
    end
  end

  def stack_files(glob:, stack_size: 5)
    dir, glob = File.split(glob)
    (stack_size - 1).downto(1).each do |stack|
      stack_dir = File.join(dir, stack.to_s)
      next unless Dir.exist?(stack_dir)
      next_stack_dir = File.join(dir, (stack + 1).to_s)
      FileUtils.rm_f next_stack_dir
      FileUtils.mkdir_p next_stack_dir
      FileUtils.mv Dir.glob(File.join(stack_dir, glob)), next_stack_dir
    end
    stack_dir = File.join(dir, '1')
    FileUtils.rm_f stack_dir
    FileUtils.mkdir_p stack_dir
    FileUtils.mv Dir.glob(File.join(dir, glob)), stack_dir
  end

  def move_files(glob:, target_dir:)
    FileUtils.mkdir_p(target_dir)
    FileUtils.mv Dir.glob(glob), target_dir
  end
end
