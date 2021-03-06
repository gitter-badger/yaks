require 'spec_helper'

RSpec.describe Yaks::CollectionMapper do
  include_context 'fixtures'

  subject(:mapper) { mapper_class.new(context) }
  let(:mapper_class) { described_class }

  let(:context) {
    { item_mapper: item_mapper,
      policy: policy,
      env: {},
      mapper_stack: [] }
  }

  let(:collection) { [] }
  let(:item_mapper) { Class.new(Yaks::Mapper) { type 'the_type' } }
  let(:policy) { Yaks::DefaultPolicy.new }

  it 'should map the collection' do
    expect(mapper.call(collection)).to eql Yaks::CollectionResource.new(
      type: 'the_type',
      links: [],
      attributes: {},
      members: [],
      collection_rel: 'rel:the_types'
    )
  end

  context 'with members' do
    let(:collection) { [boingboing, wassup]}
    let(:item_mapper) { PetMapper }

    it 'should map the members' do
      stub(policy).derive_mapper_from_object(any_args) do
        raise ":item_mapper was specified explicitly, should not be derived from object"
      end

      expect(mapper.call(collection)).to eql Yaks::CollectionResource.new(
        type: 'pet',
        links: [],
        attributes: {},
        members: [
          Yaks::Resource.new(type: 'pet', attributes: {:id => 2, :species => "dog", :name => "boingboing"}),
          Yaks::Resource.new(type: 'pet', attributes: {:id => 3, :species => "cat", :name => "wassup"})
        ],
        collection_rel: 'rel:pets'
      )
    end
  end

  context 'without an item_mapper in the context' do
    let(:context) {
      {
        policy: policy,
        env: {},
        mapper_stack: []
      }
    }
    let(:collection) { [boingboing, wassup]}

    it 'should infer the item mapper' do
      expect(mapper.call(collection)).to eql Yaks::CollectionResource.new(
        type: 'pet',
        links: [],
        attributes: {},
        members: [
          Yaks::Resource.new(type: 'pet', attributes: {:id => 2, :species => "dog", :name => "boingboing"}),
          Yaks::Resource.new(type: 'pet', attributes: {:id => 3, :species => "cat", :name => "wassup"})
        ],
        collection_rel: 'rel:pets'
      )
    end
  end

  context 'with collection attributes' do
    subject(:mapper) {
      Class.new(Yaks::CollectionMapper) do
        attributes :foo, :bar
      end.new(context)
    }

    let(:collection) {
      Class.new(SimpleDelegator) do
        def foo ; 123 ; end
        def bar ; 'pi la~~~' ; end
      end.new([])
    }

    it 'should map the attributes' do
      expect(mapper.call(collection)).to eql Yaks::CollectionResource.new(
        type: 'the_type',
        links: [],
        attributes: { foo: 123, bar: 'pi la~~~' },
        members: [],
        collection_rel: 'rel:the_types'
      )
    end
  end

  context 'with collection links' do
    subject(:mapper) {
      Class.new(Yaks::CollectionMapper) do
        link :self, 'http://api.example.com/orders'
      end.new(context)
    }

    it 'should map the links' do
      expect(mapper.call(collection)).to eql Yaks::CollectionResource.new(
        type: 'the_type',
        links: [ Yaks::Resource::Link.new(:self, 'http://api.example.com/orders', {}) ],
        attributes: { },
        members: [],
        collection_rel: 'rel:the_types'
      )
    end
  end

  describe 'overriding #collection' do
    let(:mapper_class) do
      Class.new(described_class) do
        type 'pet'

        def collection
          super.drop(1)
        end
      end
    end

    let(:collection) { [boingboing, wassup]}
    let(:item_mapper) { PetMapper }

    it 'should use the redefined collection method' do
      expect(mapper.call(collection)).to eql Yaks::CollectionResource.new(
        type: 'pet',
        links: [],
        attributes: {},
        members: [
          Yaks::Resource.new(type: 'pet', attributes: {:id => 3, :species => "cat", :name => "wassup"})
        ],
        collection_rel: 'rel:pets'
      )
    end
  end

  context 'with an empty collection' do

    context 'without an item_mapper specified' do
      let(:context) { Yaks::Util.slice_hash(super(), :policy, :env) }

      it 'should use a rel of "collection"' do
        expect(mapper.([]).collection_rel).to eq 'collection'
      end
    end

    context 'with an item_mapper specified' do
      let(:context) { Yaks::Util.slice_hash(super(), :policy, :env, :item_mapper) }

      it 'should derive the collection rel from the item mapper' do
        expect(mapper.([]).collection_rel).to eq 'rel:the_types'
      end
    end

  end
end
