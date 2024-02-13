require 'spec_helper'

module SoftwareVersion
  describe Version, type: :model do
    before :all do
      @v1 = Version.new('1.0.0')
      @v2 = Version.new('1.5.5')
      @v3 = Version.new('1.4.8')
      @v4 = Version.new('1.10.5')
      @v5 = Version.new('1.10')
      @v6 = Version.new('1.0')
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
      expect(@v1 == Version.new('1.0')).to be true
      expect(@v1 == Version.new('1.00')).to be true
      expect(@v1 == Version.new('1')).to be true
      expect(@v2 == Version.new('1.5.5')).to be true
      expect(@v3 == Version.new('1.4.8')).to be true
      expect(@v4 == Version.new('1.10.5')).to be true
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

    it 'compare version with caret' do
      a = Version.new('6.0.^')
      b = Version.new('6.0.99999')
      c = Version.new('6.1')

      expect(a > b).to be true
      expect(a < c).to be true
    end

    describe 'conversion' do
      it 'converts its argument to a version' do
        expect(SoftwareVersion::Version('1.0')).to be_a Version
        expect(SoftwareVersion::Version(Version.new('1.0'))).to be_a Version
      end

      it 'is aliased in the main module' do
        expect(SoftwareVersion('1.0')).to be_a Version
        expect(SoftwareVersion(Version.new('1.0'))).to be_a Version
      end
    end

    specify '#epoch' do
      expect(Version.new('').epoch).to eq 0
      expect(Version.new('1.0').epoch).to eq 0
      expect(Version.new('1:1.0').epoch).to eq 1
    end

    specify '#major' do
      expect(Version.new(nil).major).to eq 0
      expect(Version.new('').major).to eq 0
      expect(Version.new('11').major).to eq 11
      expect(Version.new('11.0.0').major).to eq 11
      expect(Version.new('11.22.33').major).to eq 11
      expect(Version.new('0.1').major).to eq 0
    end

    specify '#minor' do
      expect(Version.new(nil).minor).to eq 0
      expect(Version.new('').minor).to eq 0
      expect(Version.new('11').minor).to eq 0
      expect(Version.new('11.0.0').minor).to eq 0
      expect(Version.new('11.22.33').minor).to eq 22
      expect(Version.new('0.1').minor).to eq 1
    end

    specify '#patch' do
      expect(Version.new(nil).patch).to eq 0
      expect(Version.new('').patch).to eq 0
      expect(Version.new('11').patch).to eq 0
      expect(Version.new('11.0.0').patch).to eq 0
      expect(Version.new('11.22.33').patch).to eq 33
      expect(Version.new('0.0.1.0').patch).to eq 1
      expect(Version.new('19.1R2-S8').patch).to eq 2
      expect(Version.new('KB.16.10.0012').patch).to eq 12
    end

    describe '#tokens' do
      it 'handles epoch' do
        expect(described_class.new('1:2.3').send(:tokens)).to eq [
          [described_class::Token::EPOCH, 1],
          [described_class::Token::NUMBER, 2],
          [described_class::Token::NUMBER, 3],
          [described_class::Token::EOV, nil]
        ]
      end

      it 'drops useless zeros' do
        expect(described_class.new('1.0.0beta').send(:tokens)).to eq [
          [described_class::Token::NUMBER, 1],
          [described_class::Token::PREVERSION, 'beta'],
          [described_class::Token::EOV, nil]
        ]
        expect(described_class.new('1.0.0.beta').send(:tokens)).to eq [
          [described_class::Token::NUMBER, 1],
          [described_class::Token::PREVERSION, 'beta'],
          [described_class::Token::EOV, nil]
        ]
        expect(described_class.new('1.0.1').send(:tokens)).to eq [
          [described_class::Token::NUMBER, 1],
          [described_class::Token::NUMBER, 0],
          [described_class::Token::NUMBER, 1],
          [described_class::Token::EOV, nil]
        ]
        expect(described_class.new('1.0u1').send(:tokens)).to eq [
          [described_class::Token::NUMBER, 1],
          [described_class::Token::NUMBER, 0],
          [described_class::Token::NUMBER, 1],
          [described_class::Token::EOV, nil]
        ]
      end

      it 'drops fancy number separators' do
        expect(described_class.new('1u2').send(:tokens)).to eq [
          [described_class::Token::NUMBER, 1],
          [described_class::Token::NUMBER, 2],
          [described_class::Token::EOV, nil]
        ]
        expect(described_class.new('1u').send(:tokens)).to eq [
          [described_class::Token::NUMBER, 1],
          [described_class::Token::WORD, 'u'],
          [described_class::Token::EOV, nil]
        ]
      end

      it 'handles abbreviated pre-versions' do
        expect(described_class.new('1b2').send(:tokens)).to eq [
          [described_class::Token::NUMBER, 1],
          [described_class::Token::PREVERSION, 'b'],
          [described_class::Token::NUMBER, 2],
          [described_class::Token::EOV, nil]
        ]
        expect(described_class.new('1b.2').send(:tokens)).to eq [
          [described_class::Token::NUMBER, 1],
          [described_class::Token::WORD, 'b'],
          [described_class::Token::NUMBER, 2],
          [described_class::Token::EOV, nil]
        ]
        expect(described_class.new('1b').send(:tokens)).to eq [
          [described_class::Token::NUMBER, 1],
          [described_class::Token::WORD, 'b'],
          [described_class::Token::EOV, nil]
        ]
      end

      it 'handles caret character' do
        expect(described_class.new('6.0.^').send(:tokens)).to eq [
          [described_class::Token::NUMBER, 6],
          [described_class::Token::NUMBER, 0],
          [described_class::Token::MAX, '^'],
          [described_class::Token::EOV, nil]
        ]
        expect(described_class.new('6.0.beta^').send(:tokens)).to eq [
          [described_class::Token::NUMBER, 6],
          [described_class::Token::PREVERSION, 'beta'],
          [described_class::Token::MAX, '^'],
          [described_class::Token::EOV, nil]
        ]
        expect(described_class.new('6.0.beta^5').send(:tokens)).to eq [
          [described_class::Token::NUMBER, 6],
          [described_class::Token::PREVERSION, 'beta'],
          [described_class::Token::CARET, '^'],
          [described_class::Token::NUMBER, 5],
          [described_class::Token::EOV, nil]
        ]
        expect(described_class.new('17^2').send(:tokens)).to eq [
          [described_class::Token::NUMBER, 17],
          [described_class::Token::CARET, '^'],
          [described_class::Token::NUMBER, 2],
          [described_class::Token::EOV, nil]
        ]
      end
    end
  end
end
