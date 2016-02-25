require 'spec_helper'
require 'pry'

describe HappyMapper do

  context ".parse" do

    context "on a single root node" do

      subject { described_class.parse fixture_file('address.xml') }

      it "should parse child elements" do
        subject.street.should == "Milchstrasse"
        subject.housenumber.should == "23"
        subject.postcode.should == "26131"
        subject.city.should == "Oldenburg"
      end

      it "should parse camelCased elements" do
        expect(subject.mobile_phone.content).to eql('89473928231')
      end

      it "should return nil for missing elements" do
        expect(subject.home_phone).to_not be
      end

      it "should not create a content entry when the xml contents no text content" do
        subject.should_not respond_to :content
      end

      context "child elements with attributes" do

        it "should parse the attributes" do
          subject.country.code.should == "de"
        end

        it "should parse camelCased attributes" do
          subject.mobile_phone.operator_name.should == "vodafone"
        end

        it "should parse the content" do
          subject.country.content.should == "Germany"
        end

      end

    end

    context "element names with special characters" do
      subject { described_class.parse fixture_file('ambigous_items.xml') }

      it "should create accessor methods with similar names" do
        subject.my_items.item.should be_kind_of Array
      end
    end

    context "element names with camelCased elements and Capital Letters" do

      subject { described_class.parse fixture_file('subclass_namespace.xml') }

      it "should parse the elements and values correctly" do
        subject.title.should == "article title"
        subject.photo.publish_options.author.should == "Stephanie"
        subject.gallery.photo.title.should == "photo title"
      end
    end

    context "several elements nested deep" do
      subject { described_class.parse fixture_file('ambigous_items.xml') }

      it "should parse the entire relationship" do
        subject.my_items.first.name.should == "My first item"
      end

      it 'should allow to call array methods even on has_one relationships' do
        subject.my_items.first.item.first.name.should == "My first internal item"
        subject.my_items.first.nested_relationships.first.name.should == "Content"
      end

      it 'should allow pluralized names of relationships' do
        subject.my_items.first.items.first.name.should == "My first internal item"
      end
    end

    context "several elements nested deep with missing attributes" do
      subject { described_class.parse fixture_file('items_with_missing_attributes.xml') }

      context "if element is present in limited count of collection's items" do
        it "should add such an element accessor in all elements of the collection" do
          expect(subject.my_items.items[1].nested_element).to be
        end
      end

      context "if there is has_many relation on ony one of collection elements" do
        it 'should use has_many on on other elements even if they contain only one element' do
          expect(subject.my_items.items[1].nested_element.nested_attributes.size).to eql(2)
          expect(subject.my_items.items[2].nested_element.nested_attributes.size).to eql(1)
        end
      end
    end

    context "xml that contains multiple entries" do

      subject { described_class.parse fixture_file('multiple_primitives.xml') }

      it "should parse the elements as it would a 'has_many'" do

        subject.name.should == "value"
        subject.image.should == [ "image1", "image2" ]

      end

    end

    context "xml with multiple namespaces" do

      subject { described_class.parse fixture_file('subclass_namespace.xml') }

      it "should parse the elements an values correctly" do
        subject.title.should == "article title"
      end
    end

    context "after_parse callbacks" do
      module AfterParseSpec
        class Address
          include HappyMapper
          element :street, String
        end
      end

      after do
        AfterParseSpec::Address.after_parse_callbacks.clear
      end

      it "should callback with the newly created object" do
        from_cb = nil
        called = false
        cb1 = proc { |object| from_cb = object }
        cb2 = proc { called = true }
        AfterParseSpec::Address.after_parse(&cb1)
        AfterParseSpec::Address.after_parse(&cb2)

        object = AfterParseSpec::Address.parse fixture_file('address.xml')
        from_cb.should == object
        called.should == true
      end
    end
  end
end
