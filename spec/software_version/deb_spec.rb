require 'spec_helper'

module SoftwareVersion
  describe Version, type: :model do

    it 'checks versions' do
      a = Version.new('3.4.2-0ubuntu1.3.1')
      b = Version.new('3.4.2-0ubuntu1.3')
      expect(a > b).to be true
      a = Version.new('1.0.1e-2+deb7u7')
      b = Version.new('1.0.1e-2+deb7u17')
      expect(a < b).to be true
      a = Version.new('2.13-38+deb7u6')
      b = Version.new('2.13-38+deb7u8')
      expect(a < b).to be true
      a = Version.new('2.0.0~beta9+dfsg-2')
      b = Version.new('2.0.0~beta11+git20121024-1')
      expect(a < b).to be true
      a = Version.new('2:4.3.11+dfsg-0ubuntu0.14.04.13')
      b = Version.new('2:4.1.6+dfsg-1ubuntu2')
      expect(a > b).to be_truthy
      a = Version.new('1.12.1+g01b65bf-4+deb8u1')
      b = Version.new('1.12.1+g01b65bf-4+deb8u2')
      expect(a < b).to be true
      a = Version.new('1.2.44-1+squeeze3')
      b = Version.new('1.2.44-1+squeeze4')
      expect(a < b).to be true
      a = Version.new('7.26.0-1+wheezy9')
      b = Version.new('7.26.0-1+wheezy13')
      expect(a < b).to be true
      a = Version.new('2.7.15-4ubuntu4~18.04')
      b = Version.new('2.7.15~rc1-1ubuntu0.1 ')
      expect(a > b).to be true
      a = Version.new('1:1.10')
      b = Version.new('5.36')
      expect(a > b).to be true
      a = Version.new('3.15-3.0.1.module+el8.8.0+21045+adcb6a64')
      b = Version.new('3.15-3.module+el8.8.0+21045+adcb6a64')
      expect(a > b).to be true
      a = Version.new('7.0.1-5000')
      b = Version.new('7.0.1-r1000')
      expect(a > b).to be true
    end

    context 'Sort file test' do
      before(:all) do
        @version_array = fixture('deb_version_sort.txt').split("\n")
      end

      @version_array = fixture('deb_version_sort.txt').split("\n")
      @version_array.each_index do |k|
        it "compare #{@version_array[k]} <= #{@version_array[k + 1]}" do
          next if @version_array[k + 1].nil? || @version_array[k + 1] == ''

          a = Version.new(@version_array[k])
          b = Version.new(@version_array[k + 1])
          expect(a <= b).to be true
        end
      end
    end
  end
end
