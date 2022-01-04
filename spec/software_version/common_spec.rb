require 'spec_helper'

module SoftwareVersion
  describe Version, type: :model do
    before :all do
      @v1 = Version.new('1.0.0')
      @v2 = Version.new('1.5.5')
      @v3 = Version.new('1.4.8')
      @v4 = Version.new('1.10.5')
      @v5 = Version.new('1.10')
    end

    it 'check version 1' do
      # 1.0.0 < 1.5.5
      expect(@v1 < @v2).to be true
      # 1.5.5 > 1.4.8
      expect(@v2 > @v3).to be true
      # 1.0.0 < 1.10.5
      expect(@v1 < @v4).to be true
      # 1.0.0 < 1.10
      expect(@v1 < @v5).to be true
    end

    it 'check version 2' do
      # 1.5.5 < 1.10.5
      expect(@v2 < @v4).to be true
      # 1.4.8 < 1.10.5
      expect(@v3 < @v4).to be true
      # 1.10 < 1.10.5
      expect(@v5 < @v4).to be true
    end

    it 'check sorting' do
      list = [@v1, @v2, @v3, @v4, @v5]
      list.sort!
      expect(list).to eq [@v1, @v3, @v2, @v5, @v4]
    end

    it 'check equality' do
      expect(@v1 == Version.new('1.0.0')).to be true
      expect(@v2 == Version.new('1.5.5')).to be true
      expect(@v3 == Version.new('1.4.8')).to be true
      expect(@v4 == Version.new('1.10.5')).to be true
    end

    it 'compare 1.00 < 1.0.0' do
      a = Version.new('1.00')
      b = Version.new('1.0.0')

      expect(a < b).to be true
    end

    it 'compare 1.1-1-3 < 1.1-2' do
      a = Version.new('1.1-1-3')
      b = Version.new('1.1-2')

      expect(a < b).to be true
    end

    it 'define nil version' do
      expect(Version.new(nil).to_s).to eql('')
    end

    it 'define empty version' do
      expect(Version.new('').to_s).to eql('')
    end

    it 'compare nil version with version' do
      a = Version.new('')
      b = Version.new('1.0.0')

      expect(a < b).to be true
    end

    it 'compare version with nil version' do
      a = Version.new('1.0.0')
      b = Version.new('')

      expect(a > b).to be true
    end

    it 'compare nil version with version' do
      a = Version.new(nil)
      b = Version.new('1.0.0')

      expect(a < b).to be true
    end

    it 'compare version with nil version' do
      a = Version.new('1.0.0')
      b = Version.new(nil)

      expect(a > b).to be true
    end

    describe '#major' do
      subject { version.major }

      context 'when Version is nil' do
        let(:version) { Version.new(nil) }

        it 'returns nil' do
          expect(subject).to eq nil
        end
      end

      context 'when Version is empty' do
        let(:version) { Version.new('') }

        it 'returns nil' do
          expect(subject).to eq nil
        end
      end

      context 'when Version exist' do
        context 'with 3 parts' do
          let(:version) { Version.new('11.22.33') }

          it 'returns 11' do
            expect(subject).to eq '11'
          end
        end

        context 'with 2 parts' do
          let(:version) { Version.new('11.22') }

          it 'returns 11' do
            expect(subject).to eq '11'
          end
        end

        context 'with 1 part' do
          let(:version) { Version.new('11') }

          it 'returns 11' do
            expect(subject).to eq '11'
          end
        end
      end
    end

    describe '#minor' do
      subject { version.minor }

      context 'when Version is nil' do
        let(:version) { Version.new(nil) }

        it 'returns nil' do
          expect(subject).to eq nil
        end
      end

      context 'when Version is empty' do
        let(:version) { Version.new('') }

        it 'returns nil' do
          expect(subject).to eq nil
        end
      end

      context 'when Version exist' do
        context 'with 3 parts' do
          let(:version) { Version.new('11.22.33') }

          it 'returns 22' do
            expect(subject).to eq '22'
          end
        end

        context 'with 2 parts' do
          let(:version) { Version.new('11.22') }

          it 'returns 22' do
            expect(subject).to eq '22'
          end
        end

        context 'with 1 part' do
          let(:version) { Version.new('11') }

          it 'returns nil' do
            expect(subject).to eq nil
          end
        end
      end
    end

    describe '#patch' do
      subject { version.patch }

      context 'when Version is nil' do
        let(:version) { Version.new(nil) }

        it 'returns nil' do
          expect(subject).to eq nil
        end
      end

      context 'when Version is empty' do
        let(:version) { Version.new('') }

        it 'returns nil' do
          expect(subject).to eq nil
        end
      end

      context 'when Version exist' do
        context 'with 3 parts' do
          let(:version) { Version.new('11.22.33') }

          it 'returns 33' do
            expect(subject).to eq '33'
          end
        end

        context 'with 2 parts' do
          let(:version) { Version.new('11.22') }

          it 'returns nil' do
            expect(subject).to eq nil
          end
        end

        context 'with 1 part' do
          let(:version) { Version.new('11') }

          it 'returns nil' do
            expect(subject).to eq nil
          end
        end

        context 'with 19.1R2 parts' do
          let(:version) { Version.new('19.1R2') }

          it 'returns R2' do
            expect(subject).to eq 'R2'
          end
        end
      end
    end
  end
end
