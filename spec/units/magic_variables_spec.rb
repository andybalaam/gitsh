require 'spec_helper'
require 'gitsh/magic_variables'

describe Gitsh::MagicVariables do
  describe '#fetch' do
    context 'with an unknown variable name and a block' do
      it 'yields to the block' do
        repo = double('GitRepository')
        magic_variables = described_class.new(repo)

        result = magic_variables.fetch(:_not_a_real_variable) { 'default' }

        expect(result).to eq 'default'
      end
    end

    context 'with _prior' do
      it 'returns the name of the previous branch' do
        repo = double('GitRepository', revision_name: 'a-branch-name')
        magic_variables = described_class.new(repo)

        expect(magic_variables.fetch(:_prior)).to eq 'a-branch-name'
        expect(repo).to have_received(:revision_name).with('@{-1}')
      end
    end

    context 'with _merge_base' do
      it 'returns the SHA of the base commit for an in-progress merge' do
        repo = double('GitRepository', merge_base: 'abc124567890')
        magic_variables = described_class.new(repo)

        expect(magic_variables.fetch(:_merge_base)).to eq 'abc124567890'
        expect(repo).to have_received(:merge_base).with('HEAD', 'MERGE_HEAD')
      end
    end

    context 'with _rebase_base' do
      context 'when there is a .git/rebase-apply/onto file' do
        it 'returns the value stored in that file' do
          Dir.mktmpdir do |tmpdir_path|
            rebase_path = Pathname.new(tmpdir_path).join('rebase-apply')
            rebase_path.mkpath
            write_file(rebase_path.join('onto'), 'abc123')
            repo = double('GitRepository', git_dir: tmpdir_path)
            magic_variables = described_class.new(repo)

            expect(magic_variables.fetch(:_rebase_base)).to eq 'abc123'
          end
        end
      end

      context 'when there is a .git/rebase-merge/onto file' do
        it 'returns the value stored in that file' do
          Dir.mktmpdir do |tmpdir_path|
            rebase_path = Pathname.new(tmpdir_path).join('rebase-merge')
            rebase_path.mkpath
            write_file(rebase_path.join('onto'), 'def456')
            repo = double('GitRepository', git_dir: tmpdir_path)
            magic_variables = described_class.new(repo)

            expect(magic_variables.fetch(:_rebase_base)).to eq 'def456'
          end
        end
      end

      context 'when there is no rebase in progress' do
        it 'returns nil' do
          Dir.mktmpdir do |tmpdir_path|
            repo = double('GitRepository', git_dir: tmpdir_path)
            magic_variables = described_class.new(repo)

            expect(magic_variables.fetch(:_rebase_base)).to be_nil
          end
        end
      end
    end
  end
end
