require 'rails_helper'

describe QueryParser do

  context 'simple text' do
    subject{ QueryParser.new 'hello "quoted text:x" world' }

    its(:text){    should == 'hello quoted text:x world' }
    its(:options){ should == {} }
  end

  context 'simple options' do
    subject{ QueryParser.new 'hello world foo:123 bar:>3g' }

    its(:text){ should == 'hello world' }
    it{ expect(subject['foo']).to eq "123" }
    it{ expect(subject['bar']).to eq ">3g" }
  end

  context 'quoted option value' do
    subject{ QueryParser.new 'folder:"/foo/with space" some text' }

    its(:text){ should == 'some text' }
    it{ expect(subject['folder']).to eq "/foo/with space" }
  end

end
